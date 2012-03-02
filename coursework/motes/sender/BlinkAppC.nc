#include <message.h>

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TempC() as Temp_Sensor;
  components ActiveMessageC;
  components new AMSenderC(AM_DATAMSG) as DataSender;

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;

  BlinkC.AMControl -> ActiveMessageC;
  BlinkC.DataPacket -> DataSender;
  BlinkC.DataSend -> DataSender;
}

