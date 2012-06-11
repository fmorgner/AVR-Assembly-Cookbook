; stable-decisions-trigger.asm
; -------------------------------------------------------------------------
; begin                 : 2012-06-11
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
; Digital Pin 2 to ground or - respectively - PORTD Bit 2 on your ATmega MC
;
; It will use 'high to low' trigger on INT0 interrupt input
;
; Between it actions, the MC will sleep (CPU on hold)

; choose the device you wish to use:
.DEVICE atmega8


; DEFINITION SECTION

;aaa nnnnnnnnnnnnnnnnnn = vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

; I/O assignments

.equ ddrOutput          = DDRB                             ; control register for the output port we use
.equ prtOutput          = PORTB                            ; the PORT we us for Output
.equ pinOutput          = PINB                             ; the PINs of the Input PORT

.equ ddrInput           = DDRD                             ; control register for the input port we use
.equ prtInput           = PORTD                            ; the PORT we us for Input
.equ pinInput           = PIND                             ; the PINs of the Input PORT

                                                           ; Arduino Pin 13 is PORTB bit 5 on the ATmega MC
.equ bitOutput          = 5                                ; output bit for prtOutput (Digital Pin 13 on Arduino)
.equ bitInput           = 2                                ; input bit for prtInput   (Digital Pin  2 on Arduino)
.equ bitLightStart      = 4                                ; the start LED for light shifting (Pin 12 on Arduino)

.equ mskLightShift      = 0x1C                             ; = 0b00011100, (Pins 10 to 12 on Arduino)

; Power Save Mode constants 'mska' = Mask to AND with Register, 'msko' = Mask to OR with Register

; ATmega8 Power Consumption                                => ATmega8 active: 4.35 mA on 8MHz
.equ mskaPowerMode      = 0b00001111                       ; AND Mask: Sleep Modes (bit 7 has to be ON to sleep)
; Important:                                               => BIT7 (Sleep Enable) has to be ON to sleep
.equ mskoPowerIdle      = 0b10000000                       ;  OR Mask: Idle...............: 1 mA on 4 MHz
.equ mskoAdcReduct      = 0b10010000                       ;  OR Mask: ADN Noise Reduction: 
.equ mskoPowerDown      = 0b10100000                       ;  OR Mask: Power Down.........: 0.0005 mA
.equ mskoPowerSave      = 0b10110000                       ;  OR Mask: Power Save.........: 
.equ mskoStandyMod      = 0b11100000                       ;  OR Mask: Standby............:

; Interrupt Trigger Mode constants

.equ mskaExtInt0        = 0b11111100                       ; AND Mask: External INT0
.equ mskoExtInt0LvlLow  = 0b00000000                       ;  OR Mask: level low - enables wake up from power donw mode
.equ mskoExtInt0LvlChng = 0b00000001                       ;  OR Mask: any level change
.equ mskoExtInt0EdgeH2L = 0b00000010                       ;  OR Mask: falling edge
.equ mskoExtInt0EdgeL2H = 0b00000011                       ;  OR Mask: rising edge

.equ mskaExtInt1        = 0b11110011                       ; AND Mask: External INT1
.equ mskoExtInt1LvlLow  = 0b00000000                       ;  OR Mask: level low - enables wake up from power donw mode
.equ mskoExtInt1LvlChng = 0b00000100                       ;  OR Mask: any level change
.equ mskoExtInt1EdgeH2L = 0b00001000                       ;  OR Mask: falling edge
.equ mskoExtInt1EdgeL2H = 0b00001100                       ;  OR Mask: rising edge

; Names for Registers

.def regTemp            = r16                              ; regTemp has to be a 'high register', r16 is the first one
.def regData            = r18                              ; another accumulator, keeping data


; INTERRUPT SERVICE ROUTINES - ADDRESS TABLE

.org 0x0000
            rjmp    start                                  ; register 'start' as Programm Start Routine
            rjmp    ext_int0                               ; INT0 input interrupt


; MICRO CONTROLLER INITIALISATION SECTION

;llllllllllllllllllllllllll:
start:

;           ddddddd ooooooooooooo rrrrrrrrrrrrrrrrrrrrrrrr ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

            cli                                            ; Disable interrupts (SREG) while setting up

            ldi     regTemp,      high(RAMEND)             ; Initialise stack for interrupt handling
            out     SPH,          regTemp
            ldi     regTemp,      low(RAMEND)
            out     SPL,          regTemp

; On power save configuration read: "8-bit AVR with 8KBytes In-System Programmable Flash" page 35

; The ADC should be disabled                               => “Analog-to-Digital Converter” on page 189

            in      regTemp,      ADCSRA                   ; ADC Control and Status Register A
            andi    regTemp,      ~(1 << ADEN)             ; Switch off 'AD Enable' bit
            out     ADCSRA,       regTemp                  ; Rewrite Register Bits

; The Analog Comparator should be disabled                 => “Analog Comparator” on page 186

            ldi     regTemp,      1 << ACD                 ; Analog Comarator Disable bit
            out     ACSR,         regTemp                  ; Analog Comparator Control and Status Register

; The Brown-out Detector should be turned off              => “Brown-out Detection” on page 40

            in      regTemp,      MCUCSR                   ; MCU Control and Status Register
            andi    regTemp,      ~(1 << BORF)             ; Switch off Brown Out Reset Flag
            out     MCUCSR,       regTemp

; * for details on the start-up time                       => Refer to “Internal Voltage Reference” on page 42
; The Watchdog Timer should be turned off                  => “Watchdog Timer” on page 43

            in      regTemp,      MCUCSR                   ; MCU Control and Status Register
            andi    regTemp,      ~(1 << WDRF)             ; Switch off WatchDog Reset Flag
            out     MCUCSR,       regTemp

; All port pins should be configured to use minimum power  => “Digital Input Enable and Sleep Modes” on page 55

            ldi     regTemp,      0xFF                     ; Set all ports to output
            out     DDRB,         regTemp
            out     DDRC,         regTemp
            out     DDRD,         regTemp

            ldi     regTemp,      0x00                     ; Set all pins to LOW 
            out     PORTB,        regTemp
            out     PORTC,        regTemp
            out     PORTD,        regTemp

; Prepair the ports and bits we need for our use

            sbi     ddrOutput,    bitOutput                ; Set PORTB/bit5 to output mode
            sbi     prtOutput,    bitOutput                ; Set LED on bit 5 to 'on'

            cbi     ddrInput,     bitInput                 ; Set PORTD/bit2 to input mode
            sbi     prtInput,     bitInput                 ; Enable pullup resistor on PORTD/bit2

; Switch on interrupts from INT0 (Port D pin 2)

; 1) Switch on INT0 as Interrupt Source
            in      regTemp,      GICR                     ; General Interrupt Control Register
            ori     regTemp,      1 << INT0                ; Switch on INT0 bit
            out     GICR,         regTemp

; 2) Switch on INT0 as Interrupt Source
            in      regTemp,      GIFR                     ; General Interrupt Flag Register 
            ori     regTemp,      1 << INT0                ; Switch on INT0 bit
            out     GIFR,         regTemp

; set wakeup mode
            in      regTemp,      MCUCR                    ; MCU Control Register
            andi    regTemp,      mskaExtInt0              ; Masking out INT0
            ori     regTemp,      mskoExtInt0EdgeH2L       ; ORing in 'High to Low' pattern as Trigger for Interrupt
            out     MCUCR,        regTemp

; set sleep mode
            in      regTemp,      MCUCR                    ; MCU Control Register
            andi    regTemp,      mskaPowerMode            ; Masking out Sleep Mode pattern
            ori     regTemp,      mskoPowerIdle            ; ORing in 'Idle' pattern for Sleep Mode
            out     MCUCR,        regTemp

            sei                                            ; Enable interrupts (SREG) after setting up

; PROGRAM SECTION

main:
; program sleep loop here

            sleep                                          ; Sleep as deep as possible

            rjmp    main                                   ; go to sleep again

; INTERRUPT SERVICE SECTION

ext_int0:                                                  ; Interrupt Service Routine (ISR) for INT0
            in      regData,      pinOutput                ; read in data of Output Port
            mov     regTemp,      regData                  ; copy data for manipulation
            andi    regData,      0xFF - mskLightShift     ; mask out all bits not used in light shifting (to restore them later)

            andi    regTemp,      mskLightShift            ; mask out all bits used in light shifting (to be sure)
            lsr     regTemp                                ; shift the active light to the right
            andi    regTemp,      mskLightShift            ; mask out all bits not used in light shifting
            brne    shift_ok                               ; if this is not NULL, we are done
            ldi     regTemp,      1 << bitLightStart       ; we have to set the start light to on
shift_ok:
            or      regData,      regTemp                  ; mix previouse data with manipulated bits
            out     prtOutput,    regData                  ; output the result

ext_int0_end:                                              ; 'leave ISR' subroutine
            reti