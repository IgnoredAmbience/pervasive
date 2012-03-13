#include "Timer.h"
#include "../config.h"
#include "../DataMsg.h"

module BlinkC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as BlinkTimer;
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Read<uint16_t> as Temp_Sensor;
  uses interface Read<uint16_t> as Light_Sensor;

  uses interface SplitControl as AMControl;
  uses interface Packet as DataPacket;
  uses interface AMSend as DataSend;
  uses interface Receive as DataReceive;
} implementation {
  enum{
    SAMPLE_PERIOD = 1024,       // Time in ms to samplpe sensors / main work loop
    NEIGHBOUR_TIMEOUT = 10,     // Time at which neighbours considered dead

    RECEIVER_NODE = 28,         // Used for (if there is a) unicast transmissions to sink

    SEEN_TEMP     = 1,          // Bitmask for determining whether both light/temp seen before tx
    SEEN_LIGHT    = 2,          // ditto

    LIGHT         = 100,        // Light/Dark threshold value
    TEMP_CHANGE   = 20,         // Temp change required (raw ADC) for fire reading
    TEMP_READINGS = 30,         // Number of temp readings to check for fire determination
    BLINK_TIME    = 20,         // Length of time to blink dark LED on for (tx LED toggled on tx/done)

    RELAYING      = FALSE,      // Enable flood-routing
  };

  message_t datapkt;
  bool AMBusy;

  uint16_t temp_value, light_value;
  uint8_t have_seen;

  uint8_t temp_reading_idx = 0;
  uint16_t temp_readings[TEMP_READINGS] = { 0 };

  struct neighbour {
    uint8_t last_seen;          // Length of time ago node was last seen
    bool is_dark;
    uint16_t last_synch_seen;   // Last packet rcvd from node
  };

  struct neighbour neighbours[SENDER_NODE_COUNT];

  // Set when a fire is detected, retested at every sample
  bool fire_detected = FALSE;

  void testFire();

  /** Init **/

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      AMBusy = FALSE;
      call SensorTimer.startPeriodic(SAMPLE_PERIOD );
    }
  } 

  /** Sensor Reading / Sending Stack **/

  event void SensorTimer.fired() {
    int i;

    call Leds.led2On();
    call Temp_Sensor.read();
    call Light_Sensor.read();

    // Update our neighbours table
    for(i = 0; i < SENDER_NODE_COUNT; i++) {
      if(neighbours[i].last_seen < UINT8_MAX) {
        neighbours[i].last_seen++;
      }
    }
  }

  // Packs both sensor readings (Temp/Light) into one packet for tx to save power
  void doSend() {
    static uint16_t msg_sync = 0;

    if((have_seen & SEEN_LIGHT) && (have_seen & SEEN_TEMP)) {
      if (!AMBusy) {
        DataMsg * pkt = (DataMsg *)(call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));
        pkt->header = DATAMSG_HEADER;
        pkt->srcid  = TOS_NODE_ID;
        pkt->sync_p = ++msg_sync;
        pkt->temp   = temp_value;
        pkt->light  = light_value;
        pkt->fire   = fire_detected;

        if (call DataSend.send(AM_BROADCAST_ADDR, &datapkt, sizeof(DataMsg)) == SUCCESS) {
          AMBusy = TRUE;
        } else {
          call Leds.led2Off();
        }
      } else { // AMBusy
        // Cache msg if busy, ignore, other?
      }

      testFire();

      have_seen = 0;
    }
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_value = data;

    // Test for fire state, save last n readings
    // On first run, initialise all readings to current
    if(temp_readings[0] == 0) {
      int i;
      for(i = 0; i < TEMP_READINGS; i++) {
        temp_readings[i] = temp_value;
      }
    } else {
      // Round-robin our readings
      temp_reading_idx = (temp_reading_idx + 1) % TEMP_READINGS;
      temp_readings[temp_reading_idx] = temp_value;
    }

    have_seen |= SEEN_TEMP;
    doSend();
  }

  event void Light_Sensor.readDone(error_t result, uint16_t data) {
    light_value = data;
    have_seen |= SEEN_LIGHT;
    doSend();
  }

  event void DataSend.sendDone(message_t *msg, error_t error) {
    if (&datapkt == msg) {
      AMBusy = FALSE;
      call Leds.led2Off();
    }
  }

  // True if neighbour index (0-n) was last seen within timeout
  bool neighbourAlive(int i) {
    return neighbours[i].last_seen < NEIGHBOUR_TIMEOUT;
  }

  // Returns true if all neighbour motes are dark
  bool allNeighboursDark() {
    int i;
    for (i = 0; i < SENDER_NODE_COUNT; i++) {
      if(neighbourAlive(i) && !neighbours[i].is_dark)
       return FALSE;
    }
    return TRUE;
  }

  void testFire() {
    // Current - Previous (Round-robin)
    int16_t dt = temp_readings[temp_reading_idx] - temp_readings[(temp_reading_idx + 1) % TEMP_READINGS];

    if(dt >= TEMP_CHANGE && light_value < LIGHT && allNeighboursDark()) {
      call Leds.led0On();
      fire_detected = TRUE;
    } else {
      call Leds.led0Off();
      fire_detected = FALSE;
    }
  }

  /** Rx Stack **/
  event message_t* DataReceive.receive(message_t *msg, void *payload, uint8_t len) {
    static int synced_with = 0;
    DataMsg* d_pkt;

    if(synced_with == 0) synced_with = TOS_NODE_ID; // (Init)

    if(sizeof(DataMsg) != len) return msg;
    d_pkt = (DataMsg*) payload;

    if(d_pkt->srcid >= MINIMUM_NODEID && d_pkt->srcid < MINIMUM_NODEID + SENDER_NODE_COUNT) {
      // Cache node (meta-)data
      int idx = d_pkt->srcid - MINIMUM_NODEID;
      neighbours[idx].last_seen = 0;
      neighbours[idx].is_dark = (d_pkt->light < LIGHT);


      // Flood-routing
      if(RELAYING && neighbours[idx].last_synch_seen < d_pkt->sync_p) {
        neighbours[idx].last_synch_seen = d_pkt->sync_p;
        if(!AMBusy) {
          DataMsg * pkt = (DataMsg *)(call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));
          pkt->header = d_pkt->header;
          pkt->srcid  = d_pkt->srcid;
          pkt->sync_p = d_pkt->sync_p;
          pkt->temp   = d_pkt->temp;
          pkt->light  = d_pkt->light;
          pkt->fire   = d_pkt->fire;

          if (call DataSend.send(AM_BROADCAST_ADDR, &datapkt, sizeof(DataMsg)) == SUCCESS) {
            AMBusy = TRUE;
          }
        }
      }
    }

    // A simple (rough) synchronisation system, syncs to max node id visible,
    // resyncs to next max on node going offline (NEIGHBOUR_TIMEOUT)
    // Worked quite well under a range of test schemes
    if(d_pkt->srcid > synced_with || !neighbourAlive(synced_with - MINIMUM_NODEID)) {
      call SensorTimer.startPeriodic(SAMPLE_PERIOD);
      synced_with = d_pkt->srcid;
    }

    // Blink green LED if a neighbour is dark (v. useful for testing routing and ranging!)
    if(d_pkt->light < LIGHT) {
      call Leds.led1On();
      call BlinkTimer.startOneShot(BLINK_TIME);
    }

    return msg;
  }

  event void BlinkTimer.fired() {
    // Green LED blink off (triggered from DataReceive.receive)
    call Leds.led1Off();
  }

  /** Cleanup **/

  event void AMControl.stopDone(error_t err) {
    if(err == SUCCESS){
      AMBusy = TRUE;
    }
  }
}

