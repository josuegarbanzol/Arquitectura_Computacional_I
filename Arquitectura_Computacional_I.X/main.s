;--------------------------------------------------------------------------------------------------------------------------
;   
;   Archivo: main.s
;   Fecha de creación: 26 Mayo 2026 
;   Autores: Mathew Obando, Josué Garbanzo
;   Dispositivo: PIC161887A
;   Descripción: Proyecto Dirigido Arquitectura Computacional I
;   Hardware: Conexiones del PIC
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

; ---------- VARIABLES ----------
    PSECT udata_shr
delay_outer:    DS  1
delay_mid:      DS  1
delay_inner:    DS  1

; ============================================================
;  RESET VECTOR
; ============================================================
    PSECT resetVec, class=CODE, reloc=2
    goto    main

; ============================================================
;  CÓDIGO PRINCIPAL
; ============================================================
    PSECT code

main:
    ; --- Deshabilitar analog en PORTA ---
    banksel ANSELA
    clrf    ANSELA          ; RA0, RA1 como digital

    ; --- Deshabilitar analog en PORTB ---
    banksel ANSELB
    clrf    ANSELB          ; RB0, RB1 como digital

    ; --- TRISA: RA0 y RA1 como entradas ---
    banksel TRISA
    bsf     TRISA, 0        ; RA0 entrada (SW1 modo)
    bsf     TRISA, 1        ; RA1 entrada (SW2 frecuencia)

    ; --- TRISB: RB0 y RB1 como salidas ---
    banksel TRISB
    bcf     TRISB, 0        ; RB0 salida (LED GREEN)
    bcf     TRISB, 1        ; RB1 salida (LED RED)

    ; --- Apagar LEDs al inicio ---
    banksel LATB
    clrf    LATB

; ============================================================
;  LOOP PRINCIPAL
; ============================================================
loop:
    banksel PORTA
    btfss   PORTA, 0        ; SW1 alto = modo parpadeo
    goto    modo_fijo

    banksel PORTA
    btfss   PORTA, 1        ; SW2 alto = 4Hz
    goto    parpadeo_2hz

parpadeo_4hz:
    banksel LATB
    bsf     LATB, 0         ; GREEN ON
    bcf     LATB, 1         ; RED OFF
    call    delay_125ms

    banksel LATB
    bcf     LATB, 0         ; GREEN OFF
    bsf     LATB, 1         ; RED ON
    call    delay_125ms
    goto    loop

parpadeo_2hz:
    banksel LATB
    bsf     LATB, 0         ; GREEN ON
    bcf     LATB, 1         ; RED OFF
    call    delay_250ms

    banksel LATB
    bcf     LATB, 0         ; GREEN OFF
    bsf     LATB, 1         ; RED ON
    call    delay_250ms
    goto    loop

modo_fijo:
    banksel LATB
    bsf     LATB, 0         ; GREEN ON
    bsf     LATB, 1         ; RED ON
    goto    loop

; ============================================================
;  DELAYS para 32 MHz
; ============================================================
delay_250ms:
    movlw   100
    movwf   delay_outer
d250_outer:
    movlw   100
    movwf   delay_mid
d250_mid:
    movlw   200
    movwf   delay_inner
d250_inner:
    decfsz  delay_inner, F
    goto    d250_inner
    decfsz  delay_mid, F
    goto    d250_mid
    decfsz  delay_outer, F
    goto    d250_outer
    return

delay_125ms:
    movlw   50
    movwf   delay_outer
d125_outer:
    movlw   100
    movwf   delay_mid
d125_mid:
    movlw   200
    movwf   delay_inner
d125_inner:
    decfsz  delay_inner, F
    goto    d125_inner
    decfsz  delay_mid, F
    goto    d125_mid
    decfsz  delay_outer, F
    goto    d125_outer
    return

    END