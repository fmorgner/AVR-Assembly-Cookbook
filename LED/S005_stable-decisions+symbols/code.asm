; stable-decisions+symbols/code.asm
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
; Connector 8 to ground or - respectively - PORTB Bit 0 on your ATmega MC
;
; Which means, we have to manage a state
; -------------------------------------------------------------------------
; Schema description
;
; PB5/ATmega8-Pin19/Arduino-dPin13: LED with 330 Ohm to GND
; PD2/ATmega8-Pin04/Arduino-dPin02: Switch to GND


; TEST: 01.08.2012

.DEVICE atmega8


; DEFINITION SECTION

;aaa nnnnnnnnnnnnnnnnnn = vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

; I/O assignments

.equ ctlInput           = DDRD                             ; control register for the Input Port we use (D)
.equ prtInput           = PORTD                            ; the PORT we use for Input
.equ pinInput           = PIND                             ; the PINset of the Input PORT
.equ bitInput           = 2                                ; Input Bit (digital Pin 2 on Arduino)

.equ ctlOutput          = DDRB                             ; control register for the output port we use (B)
.equ prtOutput          = PORTB                            ; the PORT we us for Output
.equ pinOutput          = PINB                             ; the PINset of the Input PORT
.equ bitOutput          = 5                                ; ATmega-Pin19/Arduino-dPin13 is PORTB/Bit5

.equ LOW                = 0                                ; 0 or "clr register"
.equ HIGH               = 1

.def bStatus            = r16                              ; input signal status accumulator


; ADDRESS TABLE

.org 0x0000
;           ddddddd llllllllllllllllllllllllll             ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
            rjmp    start                                  ; register 'start' as Programm Start Point


; MICRO CONTROLLER INITIALISATION SECTION

;llllllllllllllllllllllllll:
start:

;           ddddddd ooooooooooooo rrrrrrrrrrrrrrrrrrrrrrrr ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

            sbi     ctlOutput,    bitOutput                ; set Output Pin to output mode
            sbi     prtOutput,    bitOutput                ; set Output Pin to 'on'

            cbi     ctlInput,     bitInput                 ; set Input Port at Input Pin to Input Mode
            sbi     prtInput,     bitInput                 ; enable pullup resistor on Input Port at Input Pin

            ldi     bStatus,      HIGH                     ; 'last input state' will be assumded as 'high' to begin with

main:
            sbic    pinInput,     bitInput                 ; skip next command if bit 0 of PORTB is 0
            rjmp    led_keep                               ; nothings to do, we skip the whole procedure
            tst     bStatus                                ; find out if bStatus already is NULL
            breq    led_ok                                 ; if so, we already chenged the LED state
            clr     bStatus                                ; if not, we finally register that input became 'LOW'
            sbis    pinOutput,    bitOutput                ; to change the LED state we have to read it
            rjmp    led_on                                 ; it was set to 'on'
            cbi     prtOutput,    bitOutput                ; set LED on bit 5 to 'off'
            rjmp    led_ok                                 ; LED handling will end for this squence
led_on:
            sbi     prtOutput,    bitOutput                ; set LED on bit 5 to 'on'
            rjmp    led_ok                                 ; LED handling will end for this sequence
led_keep:
            ldi     bStatus,      HIGH                     ; we are in 'pin high' mode - reset bStatus to 'high'
led_ok:
            rjmp    main                                   ; loop forever
