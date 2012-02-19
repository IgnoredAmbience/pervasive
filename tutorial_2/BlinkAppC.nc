//## SStarting code for tutorial2 of the wireless sensor network
//## programing module of the pervasive systems course.

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TimerMilliC() as LedTimer;
  components new TempC() as Temp_Sensor;

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.LedTimer -> LedTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;
}

