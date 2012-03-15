; light-shift.asm
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

; choose the device you wish to use:
.DEVICE atmega8
;.DEVICE atmega168
;.DEVICE atmega328


.equ ctlIO         = DDRB                                  ; control register for the port we use
.equ prtIO         = PORTB                                 ; the PORT we us for Input and Output
.equ pinIO         = PINB                                  ; the PINs of the PORT

                                                           ; Arduino Pin 13 is PORTB bit 5 on the ATmega MC
.equ bitSignal     = 5                                     ; signal bit (Pin 13 on Arduino)
.equ bitInput      = 0                                     ; input bit (Pin 8 on Arduino)
.equ bitLightStart = 3                                     ; the start LED for light shifting (Pin 11 on Arduino)

.equ mskLightShift = 0x0E                                  ; = 0b00001110, (Pins 9 to 11 on Arduino)

.equ LOW           = 0                                     ; 0 or "clr register"
.equ HIGH          = 1

.def bStatus       = r16                                   ; input line status accumulator
.def bTemp         = r17                                   ; a temporary local accumulator
.def bData         = r18                                   ; another accumulator, keeping data


.org 0x0000
     rjmp    start                                         ; register 'start' as Programm Start Routine


start:
     ldi     bTemp,        mskLightShift | 1 << bitSignal  ; set PORTB/bits 1,2,3,5 to output rest to input
     out     ctlIO,        bTemp
     ldi     bTemp,        1 << bitInput | 1 << bitSignal  ; enable pullup resistor on PORTB/bit0 and
     out     prtIO,        bTemp                           ; ... set ON LED on PORTB/bit5

     ldi     bStatus,      HIGH                            ; 'last state' will be 'high' to begin with

main:
     sbic    pinIO,        bitInput                        ; skip next command if bit 0 of PORTB is 0
     rjmp    led_keep                                      ; nothings to do, we skip the whole procedure
     tst     bStatus                                       ; find out if bStatus already is NULL
     breq    led_ok                                        ; if so, we already chenged the LED state
     clr     bStatus

     in      bData,        pinIO                           ; read in data of IO Port
     mov     bTemp,        bData                           ; copy data for manipulation
     andi    bData,        0xFF - mskLightShift            ; mask out all bits not used in light shifting (to restore them later)
     ori     bData,        1 << bitInput                   ; ensure 'input bit' keeps his rissitor pulled up

     andi    bTemp,        mskLightShift                   ; mask out all bits used in light shifting (to be sure)
     lsr     bTemp                                         ; shift the active light to the right
     andi    bTemp,        mskLightShift                   ; mask out all bits not used in light shifting
     brne    shift_ok                                      ; if this is not NULL, we are done
     ldi     bTemp,        1 << bitLightStart              ; we have to set the start light to on
shift_ok:
     or      bData,        bTemp                           ; mix previouse data with manipulated bits
     out     prtIO,        bData                           ; output the result

     rjmp    led_ok                                        ; LED handling will end for this sequence
led_keep:
     ldi     bStatus,      HIGH                            ; we are in 'pin high' mode - reset bStatus to 'high'
led_ok:
     rjmp    main                                          ; loop forever
