#include "Timer.h"
#include "../DataMsg.h"
#include "SerialMsg.h"

module BlinkC
{
  uses interface Leds;
  uses interface Boot;
  uses interface Timer<TMilli> as BlinkTimer;

  uses interface SplitControl as AMControl;
  uses interface CC2420Packet as DataPacket;
  uses interface Receive as DataReceive;

  uses interface SplitControl as SerialAMControl;
  uses interface Packet as SerialPacket;
  uses interface AMSend as SerialSend;
}
implementation
{

  enum{
    SAMPLE_PERIOD = 1024,
  };

  uint16_t temperature_value;
  message_t datapkt;
  bool AMBusy;

  message_t serialpkt;
  bool SerialAMBusy;

  uint8_t blink_delay;

  event void Boot.booted()
  {
    temperature_value = 0;
    call AMControl.start();
    call SerialAMControl.start();
  }

  event void BlinkTimer.fired() {
    call Leds.led0Toggle();
    call BlinkTimer.startOneShot(blink_delay);
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

  event message_t * DataReceive.receive(message_t * msg, void * payload, uint8_t len) {
    SerialMsg * s_pkt;
    DataMsg * d_pkt;

    if(len != sizeof(DataMsg)) return msg;

    d_pkt = (DataMsg *) payload;
    s_pkt = (SerialMsg *)(call SerialPacket.getPayload(&serialpkt, sizeof(SerialMsg)));

    s_pkt->header      = SERIALMSG_HEADER;
    s_pkt->srcid       = d_pkt->srcid;
    s_pkt->temperature = d_pkt->temp;
    s_pkt->light       = d_pkt->light;
    s_pkt->fire        = d_pkt->fire;
    s_pkt->rssi        = call DataPacket.getRssi(msg) - 45;


    if(SerialAMBusy) {
    }
    else {
      if (call SerialSend.send(AM_BROADCAST_ADDR, &serialpkt, sizeof(SerialMsg)) == SUCCESS) {
        SerialAMBusy = TRUE;
      }
    }
    //blink_delay = (0xff - s_pkt->rssi) / 1;
    //call BlinkTimer.startOneShot(blink_delay);
    call Leds.led0Toggle();

    return msg;
  }

  event void SerialAMControl.stopDone(error_t err) {
    if(err == SUCCESS){
      SerialAMBusy    = TRUE;
    }
  }

  event void SerialAMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      SerialAMBusy    = FALSE;
    }
  } 
  event void SerialSend.sendDone(message_t *msg, error_t error) {
    SerialAMBusy = FALSE;
  }
}

