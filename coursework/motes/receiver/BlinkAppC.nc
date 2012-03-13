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

  BlinkC -> MainC.Boot;

  BlinkC.Leds -> LedsC;

  BlinkC.AMControl -> CC2420ActiveMessageC;
  BlinkC.DataReceive -> DataReceiver;
  BlinkC.DataPacket -> CC2420ActiveMessageC;
  BlinkC.AMDataPacket -> CC2420ActiveMessageC;

  BlinkC.SerialAMControl -> SerialActiveMessageC;
  BlinkC.SerialPacket -> SerialSender;
  BlinkC.SerialSend -> SerialSender;
}

