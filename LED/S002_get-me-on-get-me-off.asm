; get-me-on-get-me-off.asm
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

; choose the device you wish to use:
.DEVICE atmega8
;.DEVICE atmega168
;.DEVICE atmega328


.org 0x0000
            rjmp    start                                  ; register 'start' as Programm Start Routine


start:
                                                           ; Arduino Pin 13 is PORTB bit 5 on the ATmega MC
            sbi     DDRB,         5                        ; set PORTB/bit5 to output mode
            cbi     DDRB,         4                        ; set PORTB/bit4 to input mode
            sbi     PORTB,        4                        ; enable pullup resistor on PORTB/bit4

main:
            sbic    PINB,         4                        ; skip next command if bit 4 of PORTB is 0
            rjmp    led_on                                 ; jump to LED ON
            cbi     PORTB,        5                        ; set LED on bit 5 to 'off'
            rjmp    led_ok                                 ; LED handling will end for this sequence
led_on:
            sbi     PORTB,        5                        ; set LED on bit 5 to 'on'
led_ok:
            rjmp    main                                   ; loop forever
