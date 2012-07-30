; get-me-on-get-me-off/code.asm
; -------------------------------------------------------------------------
; begin                 : 2012-01-22
; copyright             : Copyright (C) 2012 by Manfred Morgner
; email                 : manfred.morgner@gmx.net
; =========================================================================
;                                                                         |
;   This program is free software; you can redistribute it and/or modify  |
;   it under the terms of the GNU General Public License as published by  |
;   the Free Software Foundation; either version 2 of the License, or     |
;   (at your option) any later version.                                   |
;                                                                         |
;   This program is distributed in the hope that it will be useful,       |
;   but WITHOUT ANY WARRANTY; without even the implied warranty of        |
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         |
;   GNU General Public License for more details.                          |
;                                                                         |
;   You should have received a copy of the GNU General Public License     |
;   along with this program; if not, write to the                         |
;                                                                         |
;   Free Software Foundation, Inc.,                                       |
;   59 Temple Place Suite 330,                                            |
;   Boston, MA  02111-1307, USA.                                          |
; =========================================================================
;
; This programm will switch on the light on the Arduino LED at Connector 13
; or on your ATmega MC at PORTB Bit 5 (which is the same)
;
; Furhter it will shut off the light as long as you pull Arduino Connector 12
; to ground or - respectively - PORTB Bit 4 on your ATmega MC
; -------------------------------------------------------------------------
; Schema description
;
; PB5/ATmega-Pin19/Arduino-dPin13: LED with 330 Ohm to GND
; PD2/ATmega-Pin04/Arduino-dPin02: Switch to GND
;
.DEVICE atmega8


.org 0x0000
            rjmp    start                                  ; register 'start' as Programm Start Routine


start:
                                                           ; ATmega-Pin19/Arduino-dPin13 is PORTB/Bit5
            sbi     DDRB,         5                        ; set PORTB/Bit5 to output mode
            cbi     DDRD,         2                        ; set PORTD/Bit2 to input mode
            sbi     PORTD,        2                        ; enable pullup resistor on PORTD/Bit2

main:
            sbic    PIND,         2                        ; skip next command if Bit2 of PORTD is 0
            rjmp    led_on                                 ; jump to 'LED ON'
            cbi     PORTB,        5                        ; set LED at PORTB/Bit5 to 'off'
            rjmp    led_ok                                 ; LED handling will end for this sequence
led_on:
            sbi     PORTB,        5                        ; set LED on PORTB/Bit5 to 'on'
led_ok:
            rjmp    main                                   ; loop forever by entering 'main' again
