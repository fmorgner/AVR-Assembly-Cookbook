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
; This programm will ...
;
; -------------------------------------------------------------------------
; Schema description
;
; PB5/ATmega8-Pin19/Arduino-dPin13: LED with 330 Ohm to GND
; PB4/ATmega8-Pin18/Arduino-dPin12: LED with 330 Ohm to GND
; PB3/ATmega8-Pin17/Arduino-dPin11: LED with 330 Ohm to GND
; PB2/ATmega8-Pin16/Arduino-dPin10: LED with 330 Ohm to GND
; --- PD2/ATmega8-Pin04/Arduino-dPin02: Switch to GND


.DEVICE atmega8


; DEFINITION SECTION

;aaa nnnnnnnnnnnnnnnnnn = vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

; I/O assignments

.equ ddrInput           = DDRD                             ; control register for the Input Port we use (D)
.equ prtInput           = PORTD                            ; the PORT we use for Input
.equ pinInput           = PIND                             ; the PINset of the Input PORT
.equ bitInput           = 2                                ; Input Bit (digital Pin 2 on Arduino)

.equ ddrOutput          = DDRB                             ; control register for the output port we use (B)
.equ ddrOCR1A           = DDRB
.equ prtOutput          = PORTB                            ; the PORT we us for Output
.equ pinOutput          = PINB                             ; the PINset of the Input PORT
.equ bitSignal          = 5                                ; ATmega-Pin19/Arduino-dPin13 is PORTB/Bit5

.equ bitLightStart      = 4                                ; the start LED for light shifting (digital Pin 12 on Arduino)

.equ mskaLightShift     = 0x1C                             ; = 0b00011100, (digital Pins 10 to 12 on Arduino)

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


.equ LOW                = 0                                ; 0 or "clr register"
.equ HIGH               = 1

; Names for Registers

.def regStatus          = r16                              ; input line status accumulator
.def regTemp            = r17                              ; a temporary local accumulator
.def regData            = r18                              ; another accumulator, keeping data


;  CSn2 CSn1 CSn0   kHz@8MHz     µs@8MHz   ms@8MHz   Comment
;  ------------------------------------------------------------------------------------------
;  *  0    0    0   --                                No clock source (Timer/Counter stopped)
;  *  0    0    1   8'000.0000   0.125     0.000125   clk      (No prescaling)
;     0    1    0   1'000.0000   1         0.001      clk/8    (From prescaler)
;     0    1    1     125.0000   8         0.008      clk/64   (From prescaler)
;     1    0    0      31.2500   32        0.032      clk/256  (From prescaler)
;  *  1    0    1       7.8125   128       0.128      clk/1024 (From prescaler)
;     1    1    0   --           External clock source on T0 pin. Clock on falling edge
;     1    1    1   --           External clock source on T0 pin. Clock on rising edge
;  ------------------------------------------------------------------------------------------
;  equ PULSE, 3906
;  out TCCR0, 1 << CS00 | 1 << CS02 ; prescaler 1024
;  ldi X,     PULSE
;  timer:
;  subi X,    1
;  ...

; INTERRUPT SERVICE ROUTINES - ADDRESS TABLE

.org 0x0000
;           ddddddd llllllllllllllllllllllllll             ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
            rjmp    start                                  ; register 'start' as Programm Start Point
.org OVF1addr
            rjmp    ext_time                               ; timer interrupt to progress


; MICRO CONTROLLER INITIALISATION SECTION

;llllllllllllllllllllllllll:
start:

;           ddddddd ooooooooooooo rrrrrrrrrrrrrrrrrrrrrrrr ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

            cli                                            ; Disable interrupts (SREG) while setting up

            ldi     regTemp,      high(RAMEND)             ; Initialise stack for interrupt handling
            out     SPH,          regTemp                  ; => If we use interrupts, we need to setup the stack pointer!
            ldi     regTemp,      low(RAMEND)              ; => because ISR calls need the stack for 'RETI'
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

            sbi     ddrOutput,    bitSignal                ; set Output Port at Signal Bit to Output Mode
            sbi     prtOutput,    bitSignal                ; set Signal LED at Signal Bit on Output Port to 'on'

; Switch on interrupts from INT0 (Port D pin 2)

; :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;            sbi     DDRB,         1                        ; Set pin OCR1A to output = PB1/Atmega8-Pin15/Arduino-dPin09

; prepair timer interrupt

            ldi     regTemp,      1 << COM1A0              ; Toggle OC1A on Compare Match
            out     TCCR1A,       regTemp                  ; 
;           ldi     regTemp,      1 << CS10                ; Clock Select Bit 1: set timer1 prescaler to 1    ( 8MHz)
;           ldi     regTemp,      1 << CS11                ; Clock Select Bit 1: set timer1 prescaler to 8    ( 1MHz)
            ldi     regTemp,      1 << CS10 | 1 << CS11    ; Clock Select Bit 1: set timer1 prescaler to 64   (125kHz)
;           ldi     regTemp,      1 << CS12                ; Clock Select Bit 1: set timer1 prescaler to 256  (31kHz)
;           ldi     regTemp,      1 << CS10 | 1 << CS12    ; Clock Select Bit 1: set timer1 prescaler to 1024 ( 8kHz)
            out     TCCR1B,       regTemp                  ; 
            ldi     regTemp,      1 << TOIE1               ; Timer/Counter1 Overflow Interrupt Enable
            out     TIMSK,        regTemp                  ; 


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


; ============================================================================================================================
; ============================================================================================================================


; INTERRUPT SERVICE SECTION

ext_time:                                                  ; Interrupt Service Routine (ISR) for the time event
            in      regData,      pinOutput                ; read in data of Output Port
            mov     regTemp,      regData                  ; copy data for manipulation
            andi    regData,      0xFF - mskaLightShift    ; mask out all bits not used in light shifting (to restore them later)

            andi    regTemp,      mskaLightShift           ; mask out all bits used in light shifting (to be sure)
            lsr     regTemp                                ; shift the active light to the right
            andi    regTemp,      mskaLightShift           ; mask out all bits not used in light shifting
            brne    shift_ok                               ; if this is not NULL, we are done
            ldi     regTemp,      1 << bitLightStart       ; we have to set the start light to on
shift_ok:
            or      regData,      regTemp                  ; mix previouse data with manipulated bits
            out     prtOutput,    regData                  ; output the result

ext_time_end:                                              ; 'leave ISR' subroutine
            reti
