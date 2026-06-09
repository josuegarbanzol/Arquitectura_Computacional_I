# PIC16F18877 – Control de LEDs y Contador de Pulsos (Ensamblador)

> **Curso:** Arquitectura Computacional I · Universidad Latina de Costa Rica  
> **Autores:** Mathew Obando · Josué Garbanzo  
> **Herramientas:** MPLAB X IDE · XC8 (modo ensamblador) · Proteus 8  
> **MCU:** Microchip PIC16F18877 @ 32 MHz (HFINTOSC)

---

## Descripción general

Sistema embebido alimentado por batería programado en **lenguaje ensamblador PIC** que:

1. Controla dos LEDs (verde y rojo) en modo fijo o parpadeo alternado según un interruptor
2. Selecciona la frecuencia de parpadeo (2 Hz ó 4 Hz) con un segundo interruptor
3. Cuenta pulsos de un tercer interruptor con supresión de rebote *(en desarrollo)*
4. Transmite el conteo por RS232 cada 10 segundos *(en desarrollo)*

---

## Estado actual del desarrollo

| Módulo | Estado |
|---|---|
| Control de LEDs (fijo / parpadeo) | ✅ Implementado |
| Selección de frecuencia 2 Hz / 4 Hz | ✅ Implementado |
| Contador de pulsos con anti-rebote | 🔧 Pendiente |
| Reporte RS232 cada 10 segundos | 🔧 Pendiente |

---

## Hardware – Descripción de conexiones

El circuito se alimenta con una batería conectada al rail VDD del PIC16F18877.

**Interruptores de modo y frecuencia (SW1, SW2)**
Los dos interruptores de control están conectados a RA0 y RA1. Cada uno tiene una resistencia de 10kΩ a tierra (R2 y R3) que mantiene el pin en nivel bajo cuando el interruptor está abierto. Al presionar el interruptor, el pin sube a VDD. SW1 en RA0 selecciona si los LEDs están fijos o parpadeando; SW2 en RA1 elige entre 2 Hz y 4 Hz.

**Interruptor contador de pulsos (SW3)**
El tercer interruptor está conectado a RA2 con una resistencia de 10kΩ a VDD (pull-up, R4) y un capacitor de 100nF a tierra (C3). El pull-up mantiene el pin en alto cuando el interruptor está abierto; al presionarlo, el pin baja a tierra. El capacitor ayuda a filtrar el rebote eléctrico de los contactos.

**LEDs y transistores de control**
Los LEDs no se conectan directamente al PIC para no exceder la corriente máxima de los pines. En cambio, RB0 y RB1 controlan la compuerta (gate) de dos transistores MOSFET canal-N 2N7000 (Q1 y Q2). Cada gate tiene una resistencia de 330Ω en serie (R5 y R6) y una resistencia de 100kΩ a tierra (R7 y R8) para garantizar que el transistor apague limpiamente cuando el pin está en bajo. El LED verde (D1) va en el drenador de Q1 y el LED rojo (D2) en el drenador de Q2, ambos con su resistencia limitadora de corriente correspondiente.

**Comunicación RS-232**
El pin RC6 (TX del UART del PIC) se conecta a la entrada T1IN del integrado MAX232 (U3). Este chip convierte los niveles lógicos de 3.3V del PIC a los niveles ±12V que requiere el estándar RS-232. La salida T1OUT del MAX232 va al pin TXD del conector DB9 (P1). El MAX232 necesita cuatro capacitores de 1µF (C4, C5, C6, C7) para su circuito interno de bomba de carga.

**Reset**
El pin MCLR del PIC (RE3) está conectado a VDD a través de una resistencia de 10kΩ (R1) para mantenerlo siempre en nivel alto y evitar resets accidentales por ruido.

---

## Configuración del microcontrolador

| Parámetro | Valor |
|---|---|
| Oscilador | HFINTOSC 32 MHz (`RSTOSC = HFINT32`) |
| Oscilador externo | OFF (`FEXTOSC = OFF`) |
| MCLR | Habilitado (`MCLRE = ON`) |
| Watchdog Timer | Deshabilitado (`WDTE = OFF`) |
| Low-Voltage Programming | ON (`LVP = ON`) |
| Brown-out Reset | Habilitado, nivel bajo (`BOREN = ON, BORV = LO`) |
| Code Protect | OFF |

---

## Estructura del firmware (`main.s`)

### Inicialización

```
ANSELA = 0x00   → RA0, RA1 como pines digitales
ANSELB = 0x00   → RB0, RB1 como pines digitales
TRISA  bit 0,1  → entradas  (SW1, SW2)
TRISB  bit 0,1  → salidas   (LED verde, LED rojo)
LATB   = 0x00   → LEDs apagados al encender
```

### Lógica del loop principal

```
loop:
  ┌─ SW1 (RA0) = 0? ──→ modo_fijo: ambos LEDs ON, sin parpadeo
  │
  └─ SW1 (RA0) = 1? ──→ modo parpadeo
        ┌─ SW2 (RA1) = 0? ──→ parpadeo_2hz (delay 250ms ON / 250ms OFF)
        └─ SW2 (RA1) = 1? ──→ parpadeo_4hz (delay 125ms ON / 125ms OFF)

Patrón de parpadeo alternado:
  GREEN ON  / RED OFF  → delay
  GREEN OFF / RED ON   → delay
  → repeat
```

### Delays por software (base 32 MHz)

Los delays usan tres lazos anidados de decremento. Los valores están calibrados para el oscilador HFINTOSC a 32 MHz:

| Función | Tiempo | Outer | Mid | Inner |
|---|---|---|---|---|
| `delay_250ms` | ~250 ms | 100 | 100 | 200 |
| `delay_125ms` | ~125 ms | 50 | 100 | 200 |

---

## Variables en memoria compartida (`udata_shr`)

```asm
delay_outer   DS 1   ; contador externo del delay
delay_mid     DS 1   ; contador medio del delay
delay_inner   DS 1   ; contador interno del delay
```

---

## Estructura de archivos

```
├── main.s           # Código principal (control LEDs, frecuencia, delays)
├── PIC16F18877.pdsprj  # Proyecto de simulación Proteus
└── README.md
```

---

## Trabajo pendiente

### Contador de pulsos (SW3 en RA2)
- Implementar ISR por **Interrupt-on-Change (IOC)** en RA2
- Debounce por software dentro de la ISR (~5 ms re-muestreo)
- Registros: `PULSE_COUNT` (intervalo) y `TOTAL_COUNT` (desde encendido)

### Reporte RS232
- Configurar UART: 9600 baud, 8N1
  - SPBRG = (`Fosc / (64 × baud)`) - 1 = (32 000 000 / 614 400) - 1 ≈ **51** con BRGH=0
- Transmitir cada 10 s:
  ```
  INTERVAL: XXX  TOTAL: XXXXX\r\n
  ```
- El temporizador de 10 s se implementará con Timer0 y un contador de desbordamientos

### Migración de delays a Timer0
- Reemplazar `delay_250ms` / `delay_125ms` con ISR de Timer0
- Libera al CPU para contar pulsos y procesar UART sin bloqueo

---

## Autores

**Mathew Obando · Josué Garbanzo**  
Ingeniería en Electrónica · Universidad Latina de Costa Rica  
Proyecto Dirigido – Arquitectura Computacional I
