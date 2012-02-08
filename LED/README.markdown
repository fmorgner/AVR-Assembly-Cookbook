# LED Examples

## Let there be light!

The simplest program doing something: Set a LED under power.

We use Arduino Pin 13, which is PORTB/BIT5 on the MC chip. After starting the programm the LED on Arduino Pin 13 lights up.

If you decide to use the plain MC you need to connect you resistor and LED to pin 19 of your MC chip (PB5).

## Light on, Light off

Shows a simple combination of input and output signals by introducing a button which, if pressed, lets the light turn off.

## Stable Decisions

Enhances the former sample by letting the button turn on and off the light each time it is pressed even after it is released again.

## Light Shift

Here we add som more lights to build a light chain wherein a single ligth moves in one direction, each time the button is pressed

## Instable Elements

To start with real life requirements, we intruduce timers/counters to let time take control over our light chain.