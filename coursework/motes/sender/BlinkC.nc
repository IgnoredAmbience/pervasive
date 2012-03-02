#include "Timer.h"
#include "../DataMsg.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;

  uses interface SplitControl as AMControl;
  uses interface Packet as DataPacket;
  uses interface AMSend as DataSend;
}
implementation
{

  enum{
    SAMPLE_PERIOD = 1024,
  };

  uint16_t temperature_value;
  message_t datapkt;
  bool AMBusy;

  int RECEIVER_NODE = 28;

  event void Boot.booted()
  {
    temperature_value = 0;
    call SensorTimer.startPeriodic(SAMPLE_PERIOD );
    call AMControl.start();
  }

  event void SensorTimer.fired()
  {
    call Leds.led0Toggle();
    call Temp_Sensor.read();
  }

  event void AMControl.stopDone(error_t err) {
    if(err == SUCCESS){
    }
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      AMBusy    = FALSE;
    }
  } 

  event void DataSend.sendDone(message_t * msg, error_t error) {
    if (&datapkt == msg) {
      AMBusy = FALSE;
    }
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    DataMsg * pkt = (DataMsg *)(call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));
    pkt->srcid          = TOS_NODE_ID;
    pkt->sync_p         = 255;
    pkt->temp           = data;
    pkt->avg_temp       = 255;

    if (AMBusy) {
    } else {
      if (call DataSend.send(RECEIVER_NODE, &datapkt, sizeof(DataMsg)) == SUCCESS) {
        AMBusy = TRUE;
      }
    } 
  }
}

