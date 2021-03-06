; let-there-be-light/code.asm
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
; -------------------------------------------------------------------------
; Schema description
;
; PB5/ATmega8-Pin19/Arduino-dPin13: LED with 330 Ohm to GND


; TEST: 01.08.2012

.DEVICE atmega8


; ADDRESS TABLE

.org 0x0000
;           ddddddd llllllllllllllllllllllllll             ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
            rjmp    start                                  ; register 'start' as Programm Start Point


; MICRO CONTROLLER INITIALISATION SECTION

;llllllllllllllllllllllllll:
start:
;           ddddddd ooooooooooooo rrrrrrrrrrrrrrrrrrrrrrrr ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

                                                           ; ATmega-Pin19/Arduino-dPin13 is PORTB/Bit5
            sbi     DDRB,         5                        ; set PORTB/Bit5 to output mode
            sbi     PORTB,        5                        ; set output Bit to 'on'

; PROGRAM SECTION

main:
            rjmp    main                                   ; loop forever, nothings more to do
