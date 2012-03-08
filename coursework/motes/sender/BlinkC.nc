#include "Timer.h"
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
    SAMPLE_PERIOD = 1024,
    RECEIVER_NODE = 28,
    MINIMUM_NODEID = 25,
    SEEN_TEMP     = 1,
    SEEN_LIGHT    = 2,
    LIGHT         = 100,
    TEMP_CHANGE   = 20,
    TEMP_READINGS = 30,
    BLINK_TIME    = 20,
  };

  message_t datapkt;
  bool AMBusy;
uint16_t temp_value, light_value;
  uint8_t have_seen;

  uint8_t temp_reading_idx = 0;
  uint16_t temp_readings[TEMP_READINGS] = { 0 };

  //Could probably pack is_dark and last_seen into a byte
  //With the first bit as is_dark and the last 7 as last_seen (given that
  //last_seen will be capped at around 100 (100 < 2**7)
  struct neighbour {
    uint8_t last_seen;
    bool is_dark;
  };

  struct neighbour neighbours[3];

  // Set when a fire is detected, does not get reset
  bool fire_detected = FALSE;

  task void testFire();

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
    call Leds.led2On();
    call Temp_Sensor.read();
    call Light_Sensor.read();
  }

  void doSend() {
    if((have_seen & SEEN_LIGHT) && (have_seen & SEEN_TEMP)) {
      DataMsg * pkt = (DataMsg *)(call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));
      pkt->header = DATAMSG_HEADER;
      pkt->srcid  = TOS_NODE_ID;
      pkt->sync_p = 255;
      pkt->temp   = temp_value;
      pkt->light  = light_value;
      pkt->fire   = fire_detected;

      if (AMBusy) {
        // Nothing yet
      } else {
        if (call DataSend.send(AM_BROADCAST_ADDR, &datapkt, sizeof(DataMsg)) == SUCCESS) {
          AMBusy = TRUE;
        } else {
          call Leds.led2Off();
        }
      }

      post testFire();

      have_seen = 0;
    }
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_value = data;

    temp_reading_idx = (temp_reading_idx + 1) % TEMP_READINGS;
    temp_readings[temp_reading_idx] = temp_value;

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

  // Returns true if all neighbour motes are dark
  bool neighbourDark() {
// for all neighbours dark && (neighbour.light < LIGHT)
    int i;
    for (i = 0; i < 3 /*neighbours_seen needs implementing */; i++) {
      if(!neighbours[i].is_dark)
       return FALSE;
    }
    return TRUE;
  }

  task void testFire() {
    int16_t d = temp_readings[temp_reading_idx] - temp_readings[(temp_reading_idx + 1) % TEMP_READINGS];
    if(d >= TEMP_CHANGE && light_value < LIGHT && neighbourDark()) {
      call Leds.led0On();
      fire_detected = TRUE;
    }
  }

  /** Rx Stack **/
  event message_t* DataReceive.receive(message_t *msg, void *payload, uint8_t len) {
    DataMsg* d_pkt;
    if(sizeof(DataMsg) != len) return msg;
    d_pkt = (DataMsg*) payload;

    neighbours[d_pkt->srcid - MINIMUM_NODEID].last_seen = 100;
    neighbours[d_pkt->srcid - MINIMUM_NODEID].is_dark = FALSE;

    if(d_pkt->light < LIGHT) {
      neighbours[d_pkt->srcid - MINIMUM_NODEID].is_dark = TRUE;
      call Leds.led1On();
      call BlinkTimer.startOneShot(BLINK_TIME);
    }

    return msg;
  }

  event void BlinkTimer.fired() {
    call Leds.led1Off();
  }

  /** Cleanup **/

  event void AMControl.stopDone(error_t err) {
    if(err == SUCCESS){
      AMBusy = TRUE;
    }
  }
}

