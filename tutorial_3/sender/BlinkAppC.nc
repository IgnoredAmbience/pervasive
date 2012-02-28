//## Solution sheet for tutorial 2 and start code for tutorial 3 of the wireless sensor network
//## programing module of the pervasive systems course.

#include <message.h>

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TempC() as Temp_Sensor;
  ///****** Solution 2. Adding Radio stack components***********/
  components ActiveMessageC;
  ///******** Solution 2. Message type parameters.Note: These parameters are enumerated values defined in the message type header file DataMsg.h********/
  components new AMSenderC(AM_DATAMSG) as DataSender;
  components new AMReceiverC(AM_DATAMSG) as DataReceiver;

  ///*******Solution 3. Adding Serial stack components********************/
  components SerialActiveMessageC;
  ///********* Solution 3. Message type parameters************************/
  ///****Note: These parameters are enumerated values defined in the message type header file SerialMsg.h*********/
  components new SerialAMSenderC(AM_SERIALMSG) as SerialSender;
  components new SerialAMReceiverC(AM_SERIALMSG) as SerialReceiver; 

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;

  ///*********Solution 2. Wiring in Radio stack components*********************/
  BlinkC.AMControl -> ActiveMessageC;
  BlinkC.DataPacket -> DataSender;
  BlinkC.DataSend -> DataSender;
  BlinkC.DataReceive -> DataReceiver;

  ///********* Solution 3. Wiring in Serial stack components**********************/
  BlinkC.SerialAMControl -> SerialActiveMessageC;
  BlinkC.SerialPacket -> SerialSender;
  BlinkC.SerialSend -> SerialSender;
  BlinkC.SerialReceive -> SerialReceiver;
}

