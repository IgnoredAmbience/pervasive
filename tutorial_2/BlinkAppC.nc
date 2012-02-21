//## SStarting code for tutorial2 of the wireless sensor network
//## programing module of the pervasive systems course.

#include "Message.h"

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TempC() as Temp_Sensor;

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;

  components ActiveMessageC;
  components new AMSenderC(AM_DATAMSG) as DataSender;
  components new AMReceiverC(AM_DATAMSG) as DataReceiver;

  BlinkC.DataPacket -> ActiveMessageC;
  BlinkC.AMControl  -> ActiveMessageC;
  BlinkC.DataSender -> DataSender;

}

