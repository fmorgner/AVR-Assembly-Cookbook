; light-shift/code.asm
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
; PB5/ATmega-Pin19/Arduino-dPin13: LED with 330 Ohm to GND
; PB4/ATmega-Pin18/Arduino-dPin12: LED with 330 Ohm to GND
; PB3/ATmega-Pin17/Arduino-dPin11: LED with 330 Ohm to GND
; PB2/ATmega-Pin16/Arduino-dPin10: LED with 330 Ohm to GND
; PD2/ATmega-Pin04/Arduino-dPin02: Switch to GND

; TEST: 01.08.2012

.DEVICE atmega8


; DEFINITION SECTION

;aaa nnnnnnnnnnnnnnnnnn = vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

; I/O assignments

.equ ctlInput  = DDRD                                      ; control register for the input port we use (D)
.equ prtInput  = PORTD                                     ; the PORT we use for Input
.equ pinInput  = PIND                                      ; the PINset of the same PORT
.equ bitInput  = 2                                         ; input bit (Pin 8 on Arduino)

.equ ctlOutput = DDRB                                      ; control register for the output port we use (B)
.equ prtOutput = PORTB                                     ; the PORT we us for Output
.equ pinOutput = PINB                                      ; the PINset of the same PORT
.equ bitSignal = 5                                         ; ATmega-Pin19/Arduino-dPin13 is PORTB/Bit5

.equ bitLightStart      = 4                                ; the start LED for light shifting (Pin 12 on Arduino)

.equ mskLightShift      = 0x1C                             ; = 0b00011100, (Pins 10 to 12 on Arduino)

.equ LOW                = 0                                ; 0 or "clr register"
.equ HIGH               = 1

; Names for Registers

.def bStatus            = r16                              ; input line status accumulator
.def bTemp              = r17                              ; a temporary local accumulator
.def bData              = r18                              ; another accumulator, keeping data


; ADDRESS TABLE

.org 0x0000
;    ddddddd llllllllllllllllllllllllll                    ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
     rjmp    start                                         ; register 'start' as Programm Start Routine


; MICRO CONTROLLER INITIALISATION SECTION

;llllllllllllllllllllllllll:
start:

;    ddddddd ooooooooooooo rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

     ldi     bTemp,        mskLightShift | 1 << bitSignal  ; set Output Port to Output Mode
     out     ctlOutput,    bTemp                           ; send configuration to Output Port
     sbi     prtOutput,    bitSignal                       ; switch on Signal LED
     sbi     prtOutput,    bitLightStart                   ; switch on LightShift first LED

     cbi     ctlInput,     bitInput                        ; set Input Port at Input Pin to Input Mode
     sbi     prtInput,     bitInput                        ; enable pullup resistor on Input Port at Input Pin

     ldi     bStatus,      HIGH                            ; 'last state' will be 'high' to begin with

; PROGRAM SECTION

main:
     sbic    pinInput,     bitInput                        ; skip next command if bit 0 of PORTB is 0
     rjmp    led_keep                                      ; nothings to do, we skip the whole procedure
     tst     bStatus                                       ; find out if bStatus already is NULL
     breq    led_ok                                        ; if so, we already chenged the LED state
     clr     bStatus

     in      bData,        pinOutput                       ; read in data of IO Port
     mov     bTemp,        bData                           ; copy data for manipulation
     andi    bData,        0xFF - mskLightShift            ; mask out all bits not used in light shifting (to restore them later)

     andi    bTemp,        mskLightShift                   ; mask out all bits used in light shifting (to be sure)
     lsr     bTemp                                         ; shift the active light to the right
     andi    bTemp,        mskLightShift                   ; mask out all bits not used in light shifting
     brne    shift_ok                                      ; if this is not NULL, we are done
     ldi     bTemp,        1 << bitLightStart              ; we have to set the start light to on
shift_ok:
     or      bData,        bTemp                           ; mix previouse data with manipulated bits
     out     prtOutput,    bData                           ; output the result

     rjmp    led_ok                                        ; LED handling will end for this sequence
led_keep:
     ldi     bStatus,      HIGH                            ; we are in 'pin high' mode - reset bStatus to 'high'
led_ok:
     rjmp    main                                          ; loop forever
