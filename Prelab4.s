; Archivo: labs.S
; Dispositivo: PIC16F887
; Autor: Diana Alvarado
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: Contador de 4 bits con un delay de 100ms
; Hardware: LEDs en el puerto A, push pull down en RB0 y RB1
;
; Creado: 9 ago, 2021
; Última modificación: 18 ag, 2021
; PIC16F887 Configuration Bit Setting
; Assembly source line config statements

#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)4

reinicio_timer macro
 banksel PORTA
  movlw 178
  movwf TMR0
  bcf T0IF
  endm
 
UP EQU 6
DOWN EQU 7
    
;-------variables-------- 
PSECT udata_bank0 ;common memory
  contlab: DS 1
  cont2lab: DS 1
  cont: DS 2
 
PSECT udata_shr ;common memory 
    W_TEMP: DS 1 ; 1 byte
    STATUS_TEMP: DS 1; 1 byte
    
    ;--------vector reset------------
    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h  ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT intVect, class=CODE, abs, delta=2    
ORG 04h
push:
    movwf W_TEMP
    swapf STATUS, W
    movwf STATUS_TEMP

isr:
    btfsc RBIF ;revisat la bnadera
    call int_ioc ;interrupción iocb
    
    btfsc T0IF ;revisar bandera
    call  int_t0 ;interrupcion timer
   
pop:
    swapf STATUS_TEMP, W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie 
    
;-------subrutina interrupcion-----
int_ioc:
    banksel PORTB 
    btfss PORTB, UP ;verifica si esta presionado
    incf PORTB ;incrementa puerto B
    btfsc PORTB, 4 ;verifica si llega a 4 bits
    clrf PORTB ;reinicia
    btfss PORTB, DOWN ; verifica si esta presionado
    call dec_porta ; decrementa los 4 bits
    bcf RBIF ;limpia bandera
    return
    
int_t0:
    reinicio_timer ;reiniciar timer
    incf cont ;incrementar el contador 
    movf cont, W
    sublw 50 ;restar 50 a W
    
    btfss ZERO
    goto return_t0
    clrf cont
    ;call int_t2
    incf PORTA
    btfsc PORTA, 4
    clrf PORTA 
    call displayc
    call display
    
return_t0:
    return
       
PSECT code, delta=2, abs
ORG 100h  ; posición para el código 
;--------- Tabla ------
tabla: 
    clrf PCLATH 
    bsf PCLATH, 0 
    andlw 0x0f
    addwf PCL
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
    
 ; -------configuración---------
 main:
    call    config_io
    call    config_reloj
    call    config_ioc
    call    config_tmr0
    call    config_int_enable
    banksel PORTA
    
;-------loop principal------
loop:
    call display
    goto loop
    
; ------sub rutinas-------
config_reloj:
    banksel OSCCON
    bsf	    IRCF2	; IRCF = 101, 4MHz
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS		;RELOJ INTERNO
    return 

config_io:
    banksel ANSEL	;banco 11
    clrf    ANSEL ;pines digitales
    clrf    ANSELH
    
    banksel TRISA	;banco 01
    clrf    TRISA ; port A como salida
    clrf TRISD ; port D como salida
    clrf TRISC ; port C como salida
    clrf TRISB ; port B como salida

    bsf TRISB, UP ;RB6 como entrada
    bsf TRISB, DOWN ;RB7 como entrada
    
    bcf OPTION_REG, 7 ;Habilitar pull ups
    bsf WPUB, UP ;push up UP
    bsf WPUB, DOWN ;push up DOWN
    bcf WPUB, 0 ;salida
    bcf WPUB, 1 ;salida
    bcf WPUB, 2 ;salida
    bcf WPUB, 3 ;salida
    
    banksel PORTA	;banco 00
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
    return
    
config_ioc:
    banksel TRISA
    bsf IOCB, UP
    bsf IOCB, DOWN
    
    banksel PORTA 
    movf PORTB, W ; al leer temina condicion mismatch
    bcf RBIF
    
    return
 
config_tmr0:
    banksel TRISA
    bCf T0CS
    bCf PSA 
    bsf PS2
    bsf PS1
    bsf PS0
    reinicio_timer
    
    return 
    
config_int_enable:
    bsf GIE
    bsf T0IF
    bsf T0IE
    bsf RBIE
    bcf RBIF
    return

dec_porta:
    btfsc PORTB, DOWN ;verificar si esta presionado el boton
    goto $-1 ;sino se mantiene en constante verifivacion
    decf PORTB ;decrementa el portb
    call cont2 ;llama a la subrutina que verifica que sea de 4 bits
    return
    
cont2: ;subrutina que verifica que sea de 4 bits 
    bcf PORTB, 4
    bcf PORTB, 5
    bcf PORTB, 6
    bcf PORTB, 7
    return

displayc: ;cuenta de forma normal
    incf contlab
    movf contlab, W
    call tabla
    movf PORTC
    return 
    
display: ;es la que se encarga de la condicion
    movf contlab, W
    call tabla
    movwf PORTD
    movwf contlab, W
    sublw 10
    btfsc ZERO
    call int_t2
    return

int_t2: ;
    clrf contlab
    incf cont2lab
    movf cont2lab, W
    call tabla 
    movwf PORTC
    call minutos
    return
    
minutos: ;es el que se encarga de los minutos
    movf cont2lab, W
    call tabla
    movwf PORTC
    movf cont2lab, W
    sublw 6
    btfsc ZERO
    call reinicio2
    return

reinicio2: ;cuando llega a 6, se reincia
    clrf cont2lab
    ;movf cont2lab, W
    ;call tabla 
    ;movwf PORTC
    return    
end

