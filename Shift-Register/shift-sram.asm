; Shift SRAM
;
; Copyright (c) Felix Morgner
;
; This program aims to demonstrate the use of a CD4094BCN shift register to
; expand the number of available pins of an Atmel(r) AVR(tm) microcontroller.
; In particular, this program loads a byte of data received from SRAM into the
; shift register. It does so by loading the byte from SRAM into a temporary
; register and afterwards clocking in the register data into the data register
; of the shift register. When it finishes shifting the data into the shift
; register, it pulses the latch pin to latch the data from the data register
; onto the output register of the shift register. Please note the data loaded
; from SRAM get shifted into the shift register in reverse order, meaning that
; the LSB of the SRAM data becomes the MSB of the shift register data and vice
; versa. The program expects the following connections:
;
; - uC PORTD0 to the DATA of the shift register
; - uC PORTC0 to the CLOCK of the shift register
; - uC PORTC1 to the STROBE/LATCH pin of shift register
;
; This program deliberately doesn't use loop for performace reasons. It also
; shifts out even a zero instead of checking for it since this saves some
; cycles too. The third design consideration worth noting is that it uses
; two ports, eventhough only one shift register is being used. Using two ports
; also saves us some processing time.
;
; At the end one fun fact: This program fits exactly into 100 bytes of program
; memory.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; version 3 of the License.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

.DEVICE atmega164p                      ; set controller type

.def    temp1 = r16                     ; Register for temporary storage
.def    clock = r17                     ; Register for the shift-register clock selection
.def	zero  = r18			; Register representing a 0

.org    0x0000
        rjmp    setup                   ; 'setup' als Start-Routine registrieren

setup:
        ldi     temp1,  HIGH(RAMEND)    ; Stackpointer initialization
        out     SPH,    temp1           ; -- " --
        ldi     temp1,  LOW (RAMEND)    ; -- " --
        out     SPL,    temp1           ; -- " --

	clr	zero
        
        ldi     temp1,  $01             ; Set PORTD0 to output
        out     DDRD,   temp1           ; -- " --

        ldi     temp1,  $03             ; Set PORTC0 and PORTC1 to output
        out     DDRC,   temp1           ; -- " --
        
	ldi	temp1,	$aa		; Fill the "leds" byte with 10101010
	sts	leds,	temp1

	ldi	clock,	$01		; Select data clock mode                       

main:
	lds	temp1,	leds		; Get the LED data from SRAM into the temporary register
	
	out	PORTD,	temp1		; Output the state of the first LED to PORTD
	out	PORTC,	clock		; Clock the first bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the second bit
	out	PORTD,	temp1		; Output the state of the second LED to PORTD
	out	PORTC,	clock		; Clock the second bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the third bit
	out	PORTD,	temp1		; Output the state of the third LED to PORTD
	out	PORTC,	clock		; Clock the third bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the fourth bit
	out	PORTD,	temp1		; Output the state of the fourth LED to PORTD
	out	PORTC,	clock		; Clock the fourth bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the fifth bit
	out	PORTD,	temp1		; Output the state of the fifth LED to PORTD
	out	PORTC,	clock		; Clock the fifth bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the sixth bit
	out	PORTD,	temp1		; Output the state of the sixth LED to PORTD
	out	PORTC,	clock		; Clock the sixth bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the seventh bit
	out	PORTD,	temp1		; Output the state of the seventh LED to PORTD
	out	PORTC,	clock		; Clock the seventh bit into the storage register
	out	PORTC,	zero		; -- " --

	lsr	temp1			; Shift temp1 right so we can output the eighth bit
	out	PORTD,	temp1		; Output the state of the eighth LED to PORTD
	out	PORTC,	clock		; Clock the eighth bit into the storage register
	out	PORTC,	zero		; -- " --

	lsl	clock			; Select latch clock mode
	out	PORTC,	clock		; Latch data into the output register
	out	PORTC,	zero		; -- " --

.dseg

leds:	.byte	1			; Reserve one byte in SRAM for the storage of the LED status