; let-there-be-light.asm
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

; choose the device you wish to use:

.DEVICE atmega8
;.DEVICE atmega168
;.DEVICE atmega328


.org 0x0000
           rjmp     start                                  ; register 'start' as Programm Start Routine


start:
                                                           ; Arduino Pin 13 is PORTB Pin 5 on the ATmega MC
            ldi     r16,          1 << 5                   ; so we need to set pin 5 to output mode
            out     DDRB,         r16                      ; and doing so on PORTB

            out     PORTB,        r16                      ; set output pin to 'on'

main:
            rjmp    main                                   ; loop forever, nothings more to do
