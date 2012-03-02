#include <message.h>

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;

  components new TimerMilliC() as BlinkTimer;

  components CC2420ActiveMessageC;
  components new AMReceiverC(AM_DATAMSG) as DataReceiver;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_SERIALMSG) as SerialSender;
  components new SerialAMReceiverC(AM_SERIALMSG) as SerialReceiver; 

  BlinkC -> MainC.Boot;

  BlinkC.Leds -> LedsC;
  BlinkC.BlinkTimer -> BlinkTimer;

  BlinkC.AMControl -> CC2420ActiveMessageC;
  BlinkC.DataReceive -> DataReceiver;
  BlinkC.DataPacket -> CC2420ActiveMessageC;

  BlinkC.SerialAMControl -> SerialActiveMessageC;
  BlinkC.SerialPacket -> SerialSender;
  BlinkC.SerialSend -> SerialSender;
  BlinkC.SerialReceive -> SerialReceiver;
}

