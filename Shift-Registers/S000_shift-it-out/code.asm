; shift-sram.asm
; -------------------------------------------------------------------------
; begin                 : 2012-01-12
; copyright             : Copyright (C) 2012 by Felix Morgner
; email                 : felix.morgner@gmail.com
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

.DEVICE atmega8 ; set controller type

.def temp            = r16 ; Register for temporary storage

.equ strobePin       = 0 ; PORTB0 is connected to the shift registers strobe/latch pin.
.equ outputEnablePin = 1 ; PORTB1 is connected to the shift registers Output Enable pin.

.org 0x0000

setup:
    ldi     temp,   HIGH(RAMEND) ; Stackpointer initialization
    out     SPH,    temp         ; -- " --
    ldi     temp,   LOW (RAMEND) ; -- " --
    out     SPL,    temp         ; -- " --

    ldi     temp,   0b00101111   ; Set PORTB0, PORTB1, PORTB2, PORTB3 and PORTB5 as outputs
    out     DDRB,   temp         ; -- " --

    ldi     temp,   0b01010001   ; Set up SPI: No interrupt, enable SPI, master mode, MSB first, SPI mode 0, clock = sysclock/16
    out     SPCR,   temp         ; -- " --

    ldi     temp,   $aa          ; Fill the "aByte" byte with 10101010
    sts     aByte,  temp         ; Store the byte in SRAM

main:
    lds     temp,   aByte        ; read back the value stored at location "aByte" in SRAM to the temp register
    out     SPDR,   temp         ; shift out the value stored in temp
    
waitForTransfer:
    sbis    SPSR,   SPIF         ; wait for the transfer to finish
    rjmp    waitForTransfer

latchAndOutput:
    sbi     PORTB,  strobePin
    sbi     PORTB,  outputEnablePin

loop:
    rjmp loop

.dseg

aByte:   .byte   1 ; Reserve one byte in SRAM for the storage of the LED status
