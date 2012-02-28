#include "Timer.h"
#include "../DataMsg.h"
#include "SerialMsg.h"

module BlinkC
{
  uses interface Leds;
  uses interface Boot;

  uses interface SplitControl as AMControl;
  uses interface Packet as DataPacket;
  uses interface Receive as DataReceive;

  uses interface SplitControl as SerialAMControl;
  uses interface Packet as SerialPacket;
  uses interface AMSend as SerialSend;
  uses interface Receive as SerialReceive;
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

  event void Boot.booted()
  {
    temperature_value = 0;
    call AMControl.start();
    call SerialAMControl.start();
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

    SerialMsg * s_pkt = NULL;
    DataMsg * d_pkt = NULL;  

    if(len == sizeof(DataMsg)) {
      d_pkt = (DataMsg *) payload;      
    } 

    s_pkt = (SerialMsg *)(call SerialPacket.getPayload(&serialpkt, sizeof(SerialMsg)));

    s_pkt->header      = SERIALMSG_HEADER;
    s_pkt->srcid       = d_pkt->srcid;
    s_pkt->temperature = d_pkt->temp;

    if(SerialAMBusy) {      
    }
    else {
      if (call SerialSend.send(AM_BROADCAST_ADDR, &serialpkt, sizeof(SerialMsg)) == SUCCESS) {
        SerialAMBusy = TRUE;
      }
    } 

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

  event message_t * SerialReceive.receive(message_t * msg, void * payload, uint8_t len) {
    return msg; 
  }
}

