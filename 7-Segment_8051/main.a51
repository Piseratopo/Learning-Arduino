;------------------------------------------------------------------
; 8051 Assembly for DHT22 + 7-Segment Display
; Hardware:
;   - Sensor Data: P2.6
;   - Sensor VCC:  P2.5 (Held High)
;   - Sensor GND:  P2.7 (Held Low)
;   - 74HC138 (Digits): A=P2.2, B=P2.3, C=P2.4
;   - 74HC245 (Segments): P0
;------------------------------------------------------------------

DHT_IO      BIT P2.6        ; Sensor Data Pin

; --- FIXED VARIABLE SECTION (Use EQU to force RAM addresses) ---
RH_HIGH     EQU 30H         ; Humidity High Byte
RH_LOW      EQU 31H         ; Humidity Low Byte
T_HIGH      EQU 32H         ; Temp High Byte
T_LOW       EQU 33H         ; Temp Low Byte
MY_CHECKSUM EQU 34H         ; Checksum (Renamed to avoid conflicts)
TEMP_INT    EQU 35H         ; Integer Temperature
HUM_INT     EQU 36H         ; Integer Humidity
DISP_BUF    EQU 37H         ; Buffer Start (Occupies 37H, 38H, 39H, 3AH)

; Start of Code Memory
ORG 0000H
LJMP MAIN

;------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------
ORG 0040H
MAIN:
    ; 1. Hardware Initialization
    CLR P2.7                ; Sensor GND
    SETB P2.5               ; Sensor VCC
    
    ; Wait for sensor to stabilize (approx 1 sec)
    MOV R5, #20
START_WAIT:
    ACALL DELAY_50MS
    DJNZ R5, START_WAIT

LOOP:
    ; 2. Read DHT22
    ACALL READ_DHT
    JC SENSOR_ERROR         ; Jump if Read Failed (Carry Set)

    ; 3. Checksum Verification
    ; Sum = RH_H + RH_L + T_H + T_L
    MOV A, RH_HIGH
    ADD A, RH_LOW
    ADD A, T_HIGH
    ADD A, T_LOW
    CJNE A, MY_CHECKSUM, SENSOR_ERROR

    ; 4. Process Data (DHT22 returns value * 10)
    ; We need to divide by 10 to get the integer part.
    
    ; -- Process Temperature --
    MOV DPH, T_HIGH
    MOV DPL, T_LOW
    ACALL DIV_BY_10         ; Result in A
    MOV TEMP_INT, A
    
    ; -- Process Humidity --
    MOV DPH, RH_HIGH
    MOV DPL, RH_LOW
    ACALL DIV_BY_10         ; Result in A
    MOV HUM_INT, A
    
    ; 5. Update Display Buffer (Split into Tens and Ones)
    ; Digit 1 (Temp Tens) - Offset 0
    MOV A, TEMP_INT
    MOV B, #10
    DIV AB
    MOV R0, #DISP_BUF       ; Indirect addressing for buffer
    MOV @R0, A              ; Store Tens
    
    ; Digit 2 (Temp Ones) - Offset 1
    INC R0
    MOV A, B                ; Remainder
    MOV @R0, A
    
    ; Digit 3 (Hum Tens) - Offset 2
    INC R0
    MOV A, HUM_INT
    MOV B, #10
    DIV AB
    MOV @R0, A
    
    ; Digit 4 (Hum Ones) - Offset 3
    INC R0
    MOV A, B
    MOV @R0, A

    SJMP REFRESH_DISPLAY

SENSOR_ERROR:
    ; On error, fill buffer with 0s
    MOV R0, #DISP_BUF
    MOV @R0, #0
    INC R0
    MOV @R0, #0
    INC R0
    MOV @R0, #0
    INC R0
    MOV @R0, #0

REFRESH_DISPLAY:
    ; 6. Refresh Display Loop (Keep digits on for ~1 second)
    MOV R6, #100            ; Outer Loop
DISP_OUTER:
    MOV R7, #50             ; Inner Loop
DISP_INNER:
    ACALL DISPLAY_SCAN
    DJNZ R7, DISP_INNER
    DJNZ R6, DISP_OUTER
    
    SJMP LOOP               ; Read sensor again

;------------------------------------------------------------------
; SUBROUTINE: READ_DHT
; Returns: Data in RAM. Carry=1 if Timeout.
;------------------------------------------------------------------
READ_DHT:
    ; Start Signal
    CLR DHT_IO
    ACALL DELAY_2MS
    SETB DHT_IO
    
    ; Wait for Sensor Response (Low 80us)
    MOV R0, #100
WAIT_ACK_LOW:
    JNB DHT_IO, GOT_ACK_LOW
    DJNZ R0, WAIT_ACK_LOW
    SETB C                  ; Timeout
    RET
GOT_ACK_LOW:
    
    ; Wait for Sensor Release (High 80us)
    MOV R0, #100
WAIT_ACK_HIGH:
    JB DHT_IO, GOT_ACK_HIGH
    DJNZ R0, WAIT_ACK_HIGH
    SETB C                  ; Timeout
    RET
GOT_ACK_HIGH:

    ; Wait for Start of Data
    MOV R0, #100
WAIT_DATA:
    JNB DHT_IO, START_READ
    DJNZ R0, WAIT_DATA
    SETB C
    RET
    
START_READ:
    ACALL READ_BYTE
    MOV RH_HIGH, A
    ACALL READ_BYTE
    MOV RH_LOW, A
    ACALL READ_BYTE
    MOV T_HIGH, A
    ACALL READ_BYTE
    MOV T_LOW, A
    ACALL READ_BYTE
    MOV MY_CHECKSUM, A
    
    CLR C                   ; Success
    RET

; Read 8 bits
READ_BYTE:
    MOV R1, #8
READ_BIT_LOOP:
    ; Wait for start of bit (Pulse goes High)
    JNB DHT_IO, $
    
    ; Delay to sample bit (approx 40us)
    ACALL DELAY_35US
    
    MOV C, DHT_IO           ; Sample pin
    RLC A                   ; Rotate into Accumulator
    
    ; Wait for end of bit (Pulse goes Low)
    JB DHT_IO, $
    
    DJNZ R1, READ_BIT_LOOP
    RET

;------------------------------------------------------------------
; SUBROUTINE: DISPLAY_SCAN
; Maps Buffer data to Digits 1, 2, 3, 4
; Hardware: 74HC138 controls Common lines. 74HC245 controls Segments.
; Base P2 = 0010 0000 (20H) to keep VCC on and GND off
;------------------------------------------------------------------
DISPLAY_SCAN:
    ; Setup R0 to point to Buffer
    MOV R0, #DISP_BUF
    
    ; --- Digit 1 (Temp Tens) ---
    ; 74HC138 Input: Y4 (100) -> P2.4=1, P2.3=0, P2.2=0 -> Val 0x10
    ; Combined with Base 0x20 -> 0x30
    MOV A, @R0
    ACALL GET_SEG
    MOV P2, #30H            
    MOV P0, A
    ACALL DELAY_1MS
    MOV P0, #00H            ; Blank
    INC R0

    ; --- Digit 2 (Temp Ones) ---
    ; 74HC138 Input: Y5 (101) -> Val 0x14 | Base 0x20 -> 0x34
    MOV A, @R0
    ACALL GET_SEG
    MOV P2, #34H
    MOV P0, A
    ACALL DELAY_1MS
    MOV P0, #00H
    INC R0

    ; --- Digit 3 (Hum Tens) ---
    ; 74HC138 Input: Y6 (110) -> Val 0x18 | Base 0x20 -> 0x38
    MOV A, @R0
    ACALL GET_SEG
    MOV P2, #38H
    MOV P0, A
    ACALL DELAY_1MS
    MOV P0, #00H
    INC R0

    ; --- Digit 4 (Hum Ones) ---
    ; 74HC138 Input: Y7 (111) -> Val 0x1C | Base 0x20 -> 0x3C
    MOV A, @R0
    ACALL GET_SEG
    MOV P2, #3CH
    MOV P0, A
    ACALL DELAY_1MS
    MOV P0, #00H
    
    RET

;------------------------------------------------------------------
; UTILITIES
;------------------------------------------------------------------
; Simple Division by Repeated Subtraction (16-bit / 10)
; Input: DPH, DPL. Output: A (Integer result)
DIV_BY_10:
    MOV R4, #0      ; Result Counter
DIV_LOOP:
    CLR C
    MOV A, DPL
    SUBB A, #10
    MOV DPL, A
    MOV A, DPH
    SUBB A, #0
    MOV DPH, A
    JC DIV_DONE     ; If borrow, we passed 0
    INC R4
    SJMP DIV_LOOP
DIV_DONE:
    MOV A, R4
    RET

GET_SEG:
    INC A
    MOVC A, @A+PC
    RET
    DB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH ; 0-9

; Delays (tuned for 12MHz)
DELAY_35US:
    MOV R2, #15
    DJNZ R2, $
    RET

DELAY_1MS:
    MOV R2, #2
    MOV R1, #240
    DJNZ R1, $
    DJNZ R2, $-4
    RET
    
DELAY_2MS:
    MOV R2, #4
    MOV R1, #240
    DJNZ R1, $
    DJNZ R2, $-4
    RET

DELAY_50MS:
    MOV R2, #100
    MOV R1, #240
    DJNZ R1, $
    DJNZ R2, $-4
    RET

END