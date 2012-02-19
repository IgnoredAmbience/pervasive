//## Solution code for tutorial 2 and start code of tutorial 3, of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Timer.h"
#include "DataMsg.h"
#include "SerialMsg.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;

  ///* Solution 2, implement the Radio stack*********/.
  uses interface SplitControl as AMControl;
  uses interface Packet as DataPacket;
  uses interface AMSend as DataSend;
  uses interface Receive as DataReceive;

  ///* Solution 3, implement the Serial stack.*************/
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
  ///****Solution 2, implement radio stack.***************************/  
  message_t datapkt;
  bool AMBusy;
  
  ///************ Solution 3, implement serial stack.*****************/
  message_t serialpkt;
  bool SerialAMBusy;

  event void Boot.booted()
  {
    temperature_value = 0;
    call SensorTimer.startPeriodic(SAMPLE_PERIOD );
    ///************** Solution 2. start radio stack******************/
    call AMControl.start();
    // Solution 3. start serial stack.
    call SerialAMControl.start();


  }

  event void SensorTimer.fired()
  {
    call Leds.led0Toggle();
    call Temp_Sensor.read();
   
  }

  
///***** Solution 2. implement radio stack *******************************/

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

    event message_t * DataReceive.receive(message_t * msg, void * payload, uint8_t len) {
    
      SerialMsg * s_pkt = NULL;
      DataMsg * d_pkt = NULL;  

      if(len == sizeof(DataMsg)) {
        d_pkt = (DataMsg *) payload;      
      } 
        
      ///***** Solution 3. implement serial stack****************************/
      s_pkt = (SerialMsg *)(call SerialPacket.getPayload(&serialpkt, sizeof(SerialMsg)));
        
      s_pkt->header      = SERIALMSG_HEADER;
      s_pkt->srcid       = TOS_NODE_ID;
      s_pkt->temperature    = d_pkt->temp;
 
      if(SerialAMBusy) {      
      }
      else {
        if (call SerialSend.send(AM_BROADCAST_ADDR, &serialpkt, sizeof(SerialMsg)) == SUCCESS) {
            SerialAMBusy = TRUE;
        }
      } 
        
      return msg;
    }

  ///*** END Solution 2. *********************************/

 ///********** Solution 3. implement serial stack. ******/

    event void SerialAMControl.stopDone(error_t err) {
        if(err == SUCCESS){
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


  ///*** END Solution 3. **********************************/

  ///******** Sensor Reading code *******************/
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    // Solution 4. Send data to the basestation.
    DataMsg * pkt = (DataMsg *)(call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));
    pkt->srcid          = TOS_NODE_ID;
    pkt->sync_p         = 255;
    pkt->temp           = data;
    pkt->avg_temp       = 255;

    if (AMBusy) {
    }
    else {
        if (call DataSend.send(255, &datapkt, sizeof(DataMsg)) == SUCCESS) {
            AMBusy = TRUE;
        }
    } 
  }
}

