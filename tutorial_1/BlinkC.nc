#include "Timer.h"

module BlinkC
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
  uses interface Leds;
  uses interface Boot;
  uses interface Read<uint16_t> as Temp_Sensor;
}
implementation
{

  task void RedLedToggle() {
    call Leds.led0Toggle();
  }

  task void GreenLedToggle() {
    call Leds.led1Toggle();
  }

  task void YellowLedToggle() {
    call Leds.led2Toggle();
  }

  event void Boot.booted()
  {
    call Timer0.startPeriodic( 1024 );
    //call Timer1.startPeriodic( 102 );
    //call Timer2.startPeriodic( 101 );
  }

  event void Timer0.fired()
  {
    post RedLedToggle();
    call Temp_Sensor.read();
  }

  event void Timer1.fired()
  {
    post GreenLedToggle();
  }

  event void Timer2.fired()
  {
  }

  event void Temp_Sensor.readDone(error_t result, uint16_t data)
  {
    post YellowLedToggle();
  }
}

