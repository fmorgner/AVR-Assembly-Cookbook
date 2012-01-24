; stable-decisions.asm
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
; Furhter it will switch the light to the other state if you pull Arduino
; Connector 12 to ground or - respectively - PORTB Bit 4 on your ATmega MC
;
; Which means, we have to manage a state

; choose the device you wish to use:
.DEVICE atmega8
;.DEVICE atmega168
;.DEVICE atmega328


.equ ctlIO     = DDRB
.equ prtIO     = PORTB
.equ pinIO     = PINB

.equ bitInput  = 5
.equ bitOutput = 4

.equ FALSE     = 0
.equ TRUE      = 1

.def bStatus   = r16


.org 0x0000
           rjmp     start                                  ; register 'start' as Programm Start Routine


start:
                                                           ; Arduino Pin 13 is PORTB bit 5 on the ATmega MC
            sbi     ctlIO,        bitInput                 ; set PORTB/bit5 to output mode
            cbi     ctlIO,        bitOutput                ; set PORTB/bit4 to input mode
            sbi     prtIO,        bitOutput                ; enable pullup resistor on PORTB/bit4

            ldi     bStatus,      TRUE                     ; 'last state' will be 'high' to begin with

main:
            sbic    pinIO,        bitOutput                ; skip next command if bit 4 of PORTB is 0
            rjmp    led_keep                               ; nothings to do, we skip the whole procedure
            tst     bStatus                                ; find out if bStatus already is NULL
            breq    led_ok                                 ; if so, we already chenged the LED state
            sbis    pinIO,        bitInput                 ; to change the LED state we have to read it
            rjmp    led_on                                 ; it was set to 'on'
            cbi     prtIO,        bitInput                 ; set LED on bit 5 to 'off'
            clr     bStatus                                ; we did it - set 'last state' to 'low = done'
            rjmp    led_ok                                 ; LED handling will end for this squence
led_on:
            sbi     prtIO,        bitInput                 ; set LED on bit 5 to 'on'
            clr     bStatus                                ; we did it - set 'last state' to 'low = done'
            rjmp    led_ok                                 ; LED handling will end for this sequence
led_keep:
            ldi     bStatus,      TRUE                     ; we are in 'pin high' mode - reset bStatus to 'high'
led_ok:
            rjmp    main                                   ; loop forever
