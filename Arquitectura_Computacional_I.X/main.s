;--------------------------------------------------------------------------------------------------------------------------
;   
;   Archivo: main.s
;   Fecha de creación: 26 Mayo 2026 
;   Autores: Mathew Obando, Josué Garbanzo
;   Dispositivo: PIC16F18877
;   Descripción: Proyecto Dirigido Arquitectura Computacional I
;   Hardware: SW1=RA0 (modo), SW2=RA1 (frecuencia), BOTON=RA2 (pulsos)
;             LED GREEN=RB0, LED RED=RB1
;
;--------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------- 
; Librerias Incluidas  
;--------------------------------------------------------------------------------------------------------------------------
   
PROCESSOR 16F18877
#include <xc.inc>
    
;-------------------------------------------------------------------------------------------------------------------------- 
; Configuracion de Bits  
;--------------------------------------------------------------------------------------------------------------------------
    
; === CONFIG1 ===
    CONFIG  FEXTOSC  = OFF
    CONFIG  RSTOSC   = HFINT32
    CONFIG  CLKOUTEN = OFF
    CONFIG  CSWEN    = ON
    CONFIG  FCMEN    = OFF

; === CONFIG2 ===
    CONFIG  MCLRE    = ON
    CONFIG  PWRTE    = OFF
    CONFIG  LPBOREN  = OFF
    CONFIG  BOREN    = ON
    CONFIG  BORV     = LO
    CONFIG  ZCD      = OFF
    CONFIG  PPS1WAY  = ON
    CONFIG  STVREN   = ON

; === CONFIG3 ===
    CONFIG  WDTCPS   = WDTCPS_31
    CONFIG  WDTE     = OFF
    CONFIG  WDTCWS   = WDTCWS_7

; === CONFIG4 ===
    CONFIG  WRT      = OFF
    CONFIG  SCANE    = available
    CONFIG  LVP      = ON

; === CONFIG5 ===
    CONFIG  CP       = OFF
    CONFIG  CPD      = OFF

;-------------------------------------------------------------------------------------------------------------------------- 
; Variables (RAM compartida, accesible desde cualquier banco)
;--------------------------------------------------------------------------------------------------------------------------
    PSECT udata_shr

w_temp:         DS  1   ; respaldo de W durante la ISR
status_temp:    DS  1   ; respaldo de STATUS durante la ISR

blink_half:     DS  1   ; semiperiodo en ms (250 = 2Hz, 125 = 4Hz)
blink_timer:    DS  1   ; cuenta regresiva hasta el siguiente toggle
led_state:      DS  1   ; 0 = GREEN ON/RED OFF, 1 = al reves

btn_stable:     DS  1   ; ultimo estado estable del boton (bit0)
btn_debounce:   DS  1   ; contador de muestras consecutivas distintas
pulse_count_L:  DS  1   ; contador de pulsos (byte bajo, 16 bits)
pulse_count_H:  DS  1   ; contador de pulsos (byte alto)

; ============================================================
;  RESET VECTOR
; ============================================================
    PSECT resetVec, class=CODE, reloc=2
    goto    main

; ============================================================
;  VECTOR DE INTERRUPCION (dirección 0x0004)
; ============================================================
    PSECT intVec, class=CODE, reloc=2, abs
    ORG     0x0004
    goto    isr

; ============================================================
;  CÓDIGO PRINCIPAL
; ============================================================
    PSECT code

main:
    ; --- Deshabilitar analog en PORTA y PORTB ---
    banksel ANSELA
    clrf    ANSELA          ; RA0, RA1, RA2 como digital

    banksel ANSELB
    clrf    ANSELB          ; RB0, RB1 como digital

    ; --- TRISA: RA0, RA1, RA2 como entradas ---
    banksel TRISA
    movlw   0xFF
    movwf   TRISA           ; todo PORTA entrada (SW1, SW2, BOTON)

    ; --- TRISB: RB0 y RB1 como salidas ---
    banksel TRISB
    bcf     TRISB, 0        ; RB0 salida (LED GREEN)
    bcf     TRISB, 1        ; RB1 salida (LED RED)

    ; --- Apagar LEDs al inicio ---
    banksel LATB
    clrf    LATB

    ; --- Inicializar variables ---
    clrf    led_state
    clrf    pulse_count_L
    clrf    pulse_count_H
    clrf    btn_debounce
    clrf    btn_stable

    movlw   250
    movwf   blink_half      ; arranca asumiendo 2Hz
    movwf   blink_timer

    ; --- Configurar Timer0 para tick de 1ms ---
    ; Fosc=32MHz -> Fcy=8MHz -> 1 ciclo=125ns
    ; Prescaler 1:32 -> 4us/cuenta ; 250 cuentas -> 1ms
    banksel T0CON0
    clrf    T0CON0           ; T0EN=0 mientras configuramos

    movlw   250
    movwf   TMR0H            ; periodo = 1ms

    banksel T0CON1
    movlw   0b01010101       ; CS=Fosc/4 (01), ASYNC=0, CKPS=0101 (1:32)
    movwf   T0CON1

    banksel T0CON0
    movlw   0b10000000       ; T0EN=1, modo 8 bits, OUTPS=1:1
    movwf   T0CON0

    ; --- Habilitar interrupcion de Timer0 ---
    banksel PIE0
    bsf     PIE0, TMR0IE

    banksel PIR0
    bcf     PIR0, TMR0IF

    movlw   0xC0             ; GIE=1, PEIE=1
    movwf   INTCON

; ============================================================
;  LOOP PRINCIPAL
;  El parpadeo y el conteo de pulsos ocurren en la ISR (1ms),
;  asi que aqui se puede hacer "otro trabajo" sin perder pulsos.
; ============================================================
loop:
    ; --- leer SW2 para frecuencia (actualizable en caliente) ---
    banksel PORTA
    btfsc   PORTA, 1         ; SW2 = 1 -> 4Hz
    goto    set_4hz
    goto    set_2hz

set_4hz:
    movlw   125
    goto    set_freq

set_2hz:
    movlw   250

set_freq:
    banksel blink_half
    movwf   blink_half

    ; --- leer SW1 para modo (fijo/parpadeo) ---
    banksel PORTA
    btfss   PORTA, 0         ; SW1 = 0 -> modo fijo
    goto    modo_fijo
    goto    modo_parpadeo

modo_fijo:
    banksel LATB
    bsf     LATB, 0          ; GREEN ON
    bsf     LATB, 1          ; RED ON
    goto    loop

modo_parpadeo:
    banksel led_state
    btfsc   led_state, 0
    goto    estado_b

estado_a:
    banksel LATB
    bsf     LATB, 0          ; GREEN ON
    bcf     LATB, 1          ; RED OFF
    goto    loop

estado_b:
    banksel LATB
    bcf     LATB, 0          ; GREEN OFF
    bsf     LATB, 1          ; RED ON
    goto    loop

END