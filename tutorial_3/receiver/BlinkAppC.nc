#include <message.h>

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components CC2420ActiveMessageC;
  components new AMReceiverC(AM_DATAMSG) as DataReceiver;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_SERIALMSG) as SerialSender;
  components new SerialAMReceiverC(AM_SERIALMSG) as SerialReceiver; 

  BlinkC -> MainC.Boot;

  BlinkC.Leds -> LedsC;

  BlinkC.AMControl -> ActiveMessageC;
  BlinkC.DataReceive -> DataReceiver;

  BlinkC.SerialAMControl -> SerialActiveMessageC;
  BlinkC.SerialPacket -> SerialSender;
  BlinkC.SerialSend -> SerialSender;
  BlinkC.SerialReceive -> SerialReceiver;
}

