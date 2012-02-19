#include "Timer.h"

module BlinkC()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
  event void Boot.booted()
  {
    call Timer0.startOneShot( 1000 );
  }

  event void Timer0.fired()
  {
    call Leds.led0Toggle();
  }

}

