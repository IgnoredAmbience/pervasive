#include "Timer.h"
#include "../DataMsg.h"
#include "SerialMsg.h"

module BlinkC
{
  uses interface Leds;
  uses interface Boot;

  uses interface SplitControl as AMControl;
  uses interface AMPacket as AMDataPacket;
  uses interface CC2420Packet as DataPacket;
  uses interface Receive as DataReceive;

  uses interface SplitControl as SerialAMControl;
  uses interface Packet as SerialPacket;
  uses interface AMSend as SerialSend;
}
implementation
{

  enum{
    SENDER_NODE_COUNT = 3,
    MINIMUM_NODEID = 25,
  };

  message_t datapkt;
  bool AMBusy;

  message_t serialpkt;
  bool SerialAMBusy;

  uint16_t seen_neighbour_packet[SENDER_NODE_COUNT];

  event void Boot.booted()
  {
    call AMControl.start();
    call SerialAMControl.start();
  }

  event void AMControl.stopDone(error_t err) {
    if(err == SUCCESS){
      AMBusy = TRUE;
    }
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      AMBusy = FALSE;
    }
  } 

  event message_t * DataReceive.receive(message_t * msg, void * payload, uint8_t len) {
    SerialMsg * s_pkt;
    DataMsg * d_pkt;
    int8_t id;

    if(len != sizeof(DataMsg)) return msg;

    d_pkt = (DataMsg *) payload;

    id = d_pkt->srcid - MINIMUM_NODEID;
    if(id < 0 || id >= SENDER_NODE_COUNT) return msg;

    if(seen_neighbour_packet[id] < d_pkt->sync_p) {
      s_pkt = (SerialMsg *)(call SerialPacket.getPayload(&serialpkt, sizeof(SerialMsg)));

      s_pkt->header      = SERIALMSG_HEADER;
      s_pkt->srcid       = d_pkt->srcid;
      s_pkt->relayid     = call AMDataPacket.source(msg);
      s_pkt->sync_p      = d_pkt->sync_p;
      s_pkt->temperature = d_pkt->temp;
      s_pkt->light       = d_pkt->light;
      s_pkt->fire        = d_pkt->fire;
      s_pkt->rssi        = call DataPacket.getRssi(msg) - 45;
      seen_neighbour_packet[id] = d_pkt->sync_p;

      if(SerialAMBusy) {
      }
      else {
        if (call SerialSend.send(AM_BROADCAST_ADDR, &serialpkt, sizeof(SerialMsg)) == SUCCESS) {
          SerialAMBusy = TRUE;
        }
      }
      call Leds.led0Toggle();
    }

    return msg;
  }

  event void SerialAMControl.stopDone(error_t err) {
    if(err == SUCCESS){
      SerialAMBusy = TRUE;
    }
  }

  event void SerialAMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      SerialAMBusy = FALSE;
    }
  } 
  event void SerialSend.sendDone(message_t *msg, error_t error) {
    SerialAMBusy = FALSE;
  }
}

