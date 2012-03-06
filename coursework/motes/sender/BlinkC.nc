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
    SEEN_TEMP     = 1,
    SEEN_LIGHT    = 2,
  };

  message_t datapkt;
  bool AMBusy;

  uint16_t temp_value, light_value;
  uint8_t have_seen;

  /** Init **/

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      AMBusy    = FALSE;
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

      if (AMBusy) {
        // Nothing yet
      } else {
        if (call DataSend.send(RECEIVER_NODE, &datapkt, sizeof(DataMsg)) == SUCCESS) {
          AMBusy = TRUE;
        } else {
          call Leds.led2Off();
        }
      }

      have_seen = temp_value = light_value = 0;
    }
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    temp_value = data;
    have_seen |= SEEN_TEMP;
    doSend();
  }

  event void Light_Sensor.readDone(error_t result, uint16_t data) {
    light_value = data;
    have_seen |= SEEN_LIGHT;
    doSend();
  }

  event void DataSend.sendDone(message_t *msg, error_t error) {
    // TODO: Confirm flash delay time is long enough via this method
    if (&datapkt == msg) {
      AMBusy = FALSE;
      call Leds.led2Off();
    }
  }

  /** Rx Stack **/

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

