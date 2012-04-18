; stable-decisions-trigger.asm
; -------------------------------------------------------------------------
; begin                 : 2012-04-01
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
; This programm will toggle the light at Arduino LED at Digital Pin 13
; or on your ATmega Micro Controller at PORTB/BIT5 (which is the same)
;
; Furhter it will switch the light to the other state if you pull Arduino
; Digital Pin 2 to ground or - respectively - PORTD/BIT2 on your ATmega MC
;
; Between button pressing the micro controller goes to 'Power Down' sleep
; mode to set it's own power consumption to about 2.5 micro Watt
;
; Enabeling DEBUG mode (in Predefinition Section) will set a LED on
; Arduino Digital Pin 10 to 'ON' if the button is pressed and to 'OFF'
; after the button is released and the main program reaches its end.
;
; The reality is much more complex, but this is how it 'feels'!
;
; DEBUG may assigned TRUE or 1 or FALSE or 0

; This program is for ATmega8 micro controller
.DEVICE atmega8


; PREDEFINITION SECTION

.equ FALSE = 0
.equ TRUE  = 1

.equ DEBUG = TRUE


; MACRO SECTION

.macro DEB_INI ; (ddr,  bit)                               => Set 'bit' on 'ddr' to Output Mode
  .if DEBUG
       sbi        @0,   @1
  .endif
.endmacro

.macro DEB_LOF ; (port, bit)                               => Set LED on 'port/bit' to 'OFF' (sleeping)
  .if DEBUG
       cbi        @0,   @1
  .endif
.endmacro

.macro DEB_LON ; (port, bit)                               => Set LED on 'port/bit' to 'ON' (awake)
  .if DEBUG
       sbi        @0,   @1
  .endif
.endmacro


; DEFINITION SECTION

;aaa nnnnnnnnnnnnnnnnnn = vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv ; ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

.equ ddrOutput          = DDRB                             ; Data Direction Register for the Output Port we use
.equ prtOutput          = PORTB                            ; PORT we use for Output
.equ pinOutput          = PINB                             ; PIN register associated to our Output Port

.equ ddrInput           = DDRD                             ; Data Direction Register for the Input Port we use
.equ prtInput           = PORTD                            ; PORT we us for Input
.equ pinInput           = PIND                             ; PIN register associated to our Input Port

                                                           ; Arduino Pin 13 is BIT 5 of PORTB on the ATmega8 MC chip
.equ bitOutput          = 5                                ; Output bit on prtOutput (Digital Pin 13 on Arduino)
.equ bitDebug           = 2                                ; Debug  bit on prtOutput (Digital Pin 10 on Arduino)
.equ bitINT0            = 2                                ; Input  bit on prtInput  (Digital Pin  2 on Arduino)

; Power Save Mode constants 'mska' = Mask to AND with Register, 'msko' = Mask to OR with Register

; ATmega8 Power Consumption                                => ATmega8 active: 4.35 mA on 8MHz
.equ mskaPowerMode      = 0b00001111                       ; Mask Out Sleep Mode Bits
; Important:                                               => BIT7 (Sleep Enable) has to be ON to sleep
.equ mskoPowerIdle      = 0b10000000                       ; Idle...............: 1 mA on 4 MHz
.equ mskoAdcReduct      = 0b10010000                       ; ADN Noise Reduction: 
.equ mskoPowerDown      = 0b10100000                       ; Power Down.........: down to 0.0005 mA
.equ mskoPowerSave      = 0b10110000                       ; Power Save.........: 
.equ mskoStandyMod      = 0b11100000                       ; Standby............: 

; Interrupt Trigger Mode constants

.equ mskaExtInt0        = 0b11111100                       ; to Mask Out 'External INT0' trigger reason bits
.equ mskoExtInt0LvlLow  = 0b00000000                       ; level low - enables wake up from power down mode
.equ mskoExtInt0LvlChng = 0b00000001                       ; any level change
.equ mskoExtInt0EdgeH2L = 0b00000010                       ; falling edge
.equ mskoExtInt0EdgeL2H = 0b00000011                       ; rising edge

.equ mskaExtInt1        = 0b11110011                       ; to Mask Out 'External INT1' trigger reason bits
.equ mskoExtInt1LvlLow  = 0b00000000                       ; level low - enables wake up from power donw mode
.equ mskoExtInt1LvlChng = 0b00000100                       ; any level change
.equ mskoExtInt1EdgeH2L = 0b00001000                       ; falling edge
.equ mskoExtInt1EdgeL2H = 0b00001100                       ; rising edge

; Names for Registers

.def regTemp            = r16                              ; regTemp has to be a 'high register', r16 is the first one


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
            out     MCUCSR,       regTemp                  ; Rewrite Register Bits

; * for details on the start-up time                       => Refer to “Internal Voltage Reference” on page 42
; The Watchdog Timer should be turned off                  => “Watchdog Timer” on page 43

            in      regTemp,      MCUCSR                   ; MCU Control and Status Register
            andi    regTemp,      ~(1 << WDRF)             ; Switch off WatchDog Reset Flag
            out     MCUCSR,       regTemp                  ; Rewrite Register Bits

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

            DEB_INI ddrOutput,    bitDebug                 ; Set PORTB/BIT2 to output mode
            DEB_LON prtOutput,    bitDebug                 ; Set debug LED to 'on'

            sbi     ddrOutput,    bitOutput                ; Set PORTB/BIT5 to output mode
            sbi     prtOutput,    bitOutput                ; Set LED on bit 5 to 'on' (signal for 'program started')

            cbi     ddrInput,     bitINT0                  ; Set PORTD/bit2 to input mode
            sbi     prtInput,     bitINT0                  ; Enable pullup resistor on PORTD/bit2

; Switch on interrupts from INT0 (PORTD/BIT2)

; 1) Switch on INT0 as Interrupt Source                    => Not here - but before each SLEEP command
;           in      regTemp,      GICR                     ; General Interrupt Control Register
;           ori     regTemp,      1 << INT0                ; Switch on INT0 bit
;           out     GICR,         regTemp                  ; Rewrite Register Bits

; 2) Switch on INT0 as Interrupt Source
            in      regTemp,      GIFR                     ; General Interrupt Flag Register 
            ori     regTemp,      1 << INT0                ; Switch on INT0 bit
            out     GIFR,         regTemp                  ; Rewrite Register Bits

; Set Wakeup Mode
            in      regTemp,      MCUCR                    ; MCU Control Register
            andi    regTemp,      mskaExtInt0              ; Masking out INT0
            ori     regTemp,      mskoExtInt0LvlLow        ; ORing in 'Level Low' pattern as Trigger for Interrupt
            out     MCUCR,        regTemp                  ; Rewrite Register Bits

; Set Sleep Mode to "Power Down Mode"

; In this mode, the External Oscillator is stopped, while the external interrupts, the Two-wire Serial Interface address watch,
; and the Watchdog continue operating (if enabled). Only 
;   * an External Reset,
;   * a  Watchdog Reset,
;   * a  Brown-out Reset,
;   * a  Two-wire Serial Interface address match interrupt, or
;   * an external level interrupt on INT0 or INT1,
; can wake up the MCU. This sleep mode basically halts all generated clocks, allowing operation of asynchronous modules only.

            in      regTemp,      MCUCR                    ; MCU Control Register
            andi    regTemp,      mskaPowerMode            ; Masking out Sleep Mode pattern
            ori     regTemp,      mskoPowerDown            ; ORing in 'Power Down' pattern for Sleep Mode
            out     MCUCR,        regTemp                  ; Rewrite Register Bits

            sei                                            ; Enable interrupts (SREG) after setting up the Micro Controller


; PROGRAM SECTION

main:
; Program loop code here

; Program goes to sleep if INT0 bit is left HIGH (button not pressed)

            sbis    pinInput,     bitINT0                  ; Test if INT0 Button is released yet
            rjmp    no_sleep                               ; Not released => dont SLEEP!

            DEB_LOF prtOutput,    bitDebug                 ; Set debug LED to 'OFF' (sleeping)

            in      regTemp,      GICR                     ; General Interrupt Control Register
            ori     regTemp,      1 << INT0                ; Switch on INT0 bit as Interrupt Source
            cli                                            ; from here on, we must not be interrupted!
            out     GICR,         regTemp                  ; Rewrite Register Bits

            sei                                            ; hopefully, no one interrupts with INT0 before 'sleep'
            sleep                                          ; Sleep as hard as possible (Power Down Mode)

no_sleep:
            rjmp    main                                   ; Start 'main' all over


; INTERRUPT SERVICE SECTION

ext_int0:                                                  ; Interrupt Service Routine (ISR) for INT0
            DEB_LON prtOutput,    bitDebug                 ; Set debug LED to 'on'

            sbis    pinOutput,    bitOutput                ; Is Output LED in state ON?
            jmp     led_on                                 ; NO => jump to 'Switch LED ON'
led_off:
            cbi     prtOutput,    bitOutput                ; Switch Output LED OFF
            jmp     ext_int0_end                           ; Leave Interrupt Service Routine (ISR)
led_on:
            sbi     prtOutput,    bitOutput                ; Switch Output LED ON

ext_int0_end:                                              ; 'leave ISR' subroutine

            push    regTemp                                ; next step we modify regTemp, so we have to keep the content back
; switch off Interrupts for INT0 to forget pending signal
            in      regTemp,      GICR                     ; General Interrupt Control Register
            andi    regTemp,      ~(1 << INT0)             ; switch off INT0 bit
            out     GICR,         regTemp
            pop     regTemp                                ; here es the old regTemp content again

            reti