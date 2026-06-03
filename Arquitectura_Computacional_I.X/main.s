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
    
    config LVP = ON	    ; Low Voltage Programming Enable Bit
    config FEXTOSC = OFF    ; External Oscillator Selection bits (OFF)
    config WDTE = OFF       ; Watchdog Timer Enable bit (WDT disabled)
    config PWRTE = OFF      ; Power-up Timer Enable bit (PWRT disabled)
    config MCLRE = ON       ; MCLR Pin Function Select bit (MCLR pin function is MCLR)
    config CP = OFF         ; Code Protection bit (Program memory code protection is disabled)
    config CPD = OFF        ; Data Code Protection bit (Data memory code protection is disabled)
    config BOREN = OFF      ; Brown Out Detect (BOR disabled)
    config FCMEN = OFF      ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)

;-------------------------------------------------------------------------------------------------------------------------- 
; LEDS  
;--------------------------------------------------------------------------------------------------------------------------

