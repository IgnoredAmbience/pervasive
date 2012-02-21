//## Starting code for tutorial 2 of the wireless sensor network
//## programing module of the pervasive systems course.
#include "Timer.h"
#include "Message.h"

module BlinkC
{
  uses interface Timer<TMilli> as SensorTimer;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;

  uses interface Packet as DataPacket;
  uses interface AMSend as DataSender;

  uses interface SplitControl as AMControl;
}
implementation
{

  enum{
    SAMPLE_PERIOD = 1024,
    LED_FLASH_PERIOD = 50,
  };

  uint16_t avg_temperature = 0;
  uint16_t counter = 0;

  bool AMBusy;
  message_t datapkt;


  event void Boot.booted()
  {
    call SensorTimer.startPeriodic(SAMPLE_PERIOD);

    call AMControl.start();
  }

  event void AMControl.startDone(error_t err)
  {
    if (err == SUCCESS) {
      AMBusy = FALSE;
    }
  }

  event void SensorTimer.fired()
  {
    
    call Leds.led0Toggle();
    call Temp_Sensor.read();

  }

  /******** Sensor Reading code *******************/
  event void Temp_Sensor.readDone(error_t result, uint16_t data) {
    uint16_t temperature_value = data;

    DataMsg *pkt = (DataMsg* ) (call DataPacket.getPayload(&datapkt, sizeof(DataMsg)));

    pkt->srcid = TOS_NODE_ID;
    pkt->sync_p = counter++;
    pkt->temp = data;
    pkt->avg_temp = ((counter - 1)*avg_temperature + data) / counter;

    if (call DataSender.send(AM_BROADCAST_ADDR, &datapkt, sizeof(DataMsg)) == SUCCESS)
      AMBusy = TRUE;
    }

  event void DataSender.sendDone(message_t* msg, error_t error) {
    call Leds.led1Toggle();
  }


  event void AMControl.stopDone(error_t error) {
    if (error == SUCCESS)
      AMBusy = TRUE;

  }

}
