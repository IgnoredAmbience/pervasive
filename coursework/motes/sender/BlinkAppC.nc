#include <message.h>

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as BlinkTimer;

  components new TimerMilliC() as SensorTimer;
  components new TempC() as Temp_Sensor;
  components new PhotoC() as Light_Sensor;

  components ActiveMessageC;
  components new AMSenderC(AM_DATAMSG) as DataSender;
  components new AMReceiverC(AM_DATAMSG) as DataReceiver;

  BlinkC -> MainC.Boot;
  BlinkC.Leds -> LedsC;
  BlinkC.BlinkTimer -> BlinkTimer;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.Light_Sensor -> Light_Sensor;
  BlinkC.Temp_Sensor -> Temp_Sensor;

  BlinkC.AMControl -> ActiveMessageC;
  BlinkC.DataPacket -> DataSender;
  BlinkC.DataSend -> DataSender;
  BlinkC.DataReceive -> DataReceiver;
}

