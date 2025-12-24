;----------------------------------------------------------
; CIRCUIT: STC89C52 + DHT11 + LCD I2C (ADDRESS 04EH)
; FREQUENCY: 12 MHZ (1 Machine Cycle = 1 microsecond)
; VERSION: SAFE MODE (Robust timing for reliability)
;----------------------------------------------------------

; --- Pin Definitions ---
SDA     BIT P2.1            ; I2C Data Line
SCL     BIT P2.2            ; I2C Clock Line
DHT_IO  BIT P2.0            ; DHT11 Single-Bus Data Line

; --- I2C Address ---
LCD_ADDR EQU 04EH           ; I2C Address for the LCD Backpack

; --- RAM Memory Allocation ---
HUM_INT  EQU 30H            ; Stores Humidity Integer part
TMP_INT  EQU 31H            ; Stores Temperature Integer part
BL_STATE EQU 32H            ; Stores Backlight state (08H = ON, 00H = OFF)

        ORG 0000H           ; Reset Vector
        LJMP MAIN

        ORG 0030H           ; Main Program Start
MAIN:
        MOV SP, #60H        ; Initialize Stack Pointer
        MOV BL_STATE, #08H  ; Set Backlight to ON by default
        
        LCALL DELAY_100MS   ; Wait for power to stabilize
        LCALL I2C_INIT      ; Initialize I2C lines
        LCALL LCD_INIT      ; Initialize LCD in 4-bit mode via I2C
        
        ; --- Display Static Labels ---
        LCALL LCD_LINE1     ; Move cursor to Line 1
        MOV DPTR, #TXT_TEMP ; Load "Temperature: " string
        LCALL LCD_STR
        
        LCALL LCD_LINE3     ; Move cursor to Line 3
        MOV DPTR, #TXT_HUMI ; Load "Humidity: " string
        LCALL LCD_STR

LOOP:
        ; Reset stored values before reading
        MOV HUM_INT, #0
        MOV TMP_INT, #0

        LCALL READ_DHT_SAFE ; Call DHT11 reading routine
        JC SENSOR_ERR       ; If Carry Flag (C) is set, a timeout occurred

        ; --- Display Data (If Read Success) ---
        ; 1. Display Temperature
        LCALL LCD_LINE2
		MOV A, #' '			; Padding 1 space
		LCALL LCD_DATA_BYTE
        MOV A, TMP_INT      ; Load temperature value
        LCALL SHOW_NUM      ; Convert and display as ASCII
        MOV A, #0DFH        ; ASCII code for the Degree symbol (°)
        LCALL LCD_DATA_BYTE
        MOV A, #'C'         ; Celsius unit
        LCALL LCD_DATA_BYTE
        
        ; 2. Display Humidity
        LCALL LCD_LINE4
		MOV A, #' '
		LCALL LCD_DATA_BYTE
        MOV A, HUM_INT      ; Load humidity value
        LCALL SHOW_NUM
        MOV A, #'%'         ; Percentage unit
        LCALL LCD_DATA_BYTE
        SJMP WAIT_NEXT

SENSOR_ERR:
        ; Display "ER" on the value lines if sensor fails
        LCALL LCD_LINE2
        MOV A, #' '
        LCALL LCD_DATA_BYTE
        MOV A, #'E'
        LCALL LCD_DATA_BYTE
        MOV A, #'R'
        LCALL LCD_DATA_BYTE

        LCALL LCD_LINE4
        MOV A, #' '
        LCALL LCD_DATA_BYTE
        MOV A, #'E'
        LCALL LCD_DATA_BYTE
        MOV A, #'R'
        LCALL LCD_DATA_BYTE

WAIT_NEXT:
        LCALL DELAY_2S      ; Wait 2 seconds (DHT11 needs time between reads)
        LJMP LOOP           ; Repeat

;==========================================================
; DHT11 SENSOR INTERFACE (SAFE MODE)
;==========================================================
READ_DHT_SAFE:
        ; 1. Send Start Signal
        CLR DHT_IO          ; Pull bus LOW
        LCALL DELAY_25MS    ; Stay LOW for >18ms (DHT11 requirement)
        SETB DHT_IO         ; Pull bus HIGH
        
        ; 2. Wait for DHT11 Response (Handshake)
        ; Wait for DHT to pull the bus LOW
        MOV R7, #250        
W_L:    JNB DHT_IO, W_OK    ; If pin is LOW, DHT responded
        DJNZ R7, W_L
        SETB C              ; Error: Timeout 1
        RET
W_OK:   
        ; Wait for DHT to pull the bus HIGH
        MOV R7, #250
W_H:    JB DHT_IO, PREP     ; If pin is HIGH, DHT is ready to send data
        DJNZ R7, W_H
        SETB C              ; Error: Timeout 2
        RET
PREP:   
        ; Wait for the first falling edge (start of first bit)
        MOV R7, #250
W_B:    JNB DHT_IO, START_R 
        DJNZ R7, W_B
        SETB C
        RET

START_R:
        ; 3. Read 5 Bytes (40 bits total)
        LCALL RD_BYTE
        MOV HUM_INT, A      ; Byte 1: Humidity Integer
        LCALL RD_BYTE       ; Byte 2: Humidity Decimal (Ignored for DHT11)
        LCALL RD_BYTE
        MOV TMP_INT, A      ; Byte 3: Temperature Integer
        LCALL RD_BYTE       ; Byte 4: Temperature Decimal (Ignored for DHT11)
        LCALL RD_BYTE       ; Byte 5: Checksum (Skipped here for simplicity)
        
        CLR C               ; Success: Clear Carry Flag
        RET

RD_BYTE:
        MOV R5, #8          ; Counter for 8 bits
B_LP:   
        JNB DHT_IO, $       ; Wait for pin to go HIGH (Start of bit)
        
        ; --- BIT SAMPLING MOMENT ---
        ; Logic 0: High for 26-28us
        ; Logic 1: High for 70us
        ; We wait ~45us. If pin is still HIGH, it's a '1'. If LOW, it's a '0'.
        ; At 12MHz, 1 machine cycle = 1us. DJNZ takes 2us.
        MOV R7, #20         ; 20 * 2us = 40us + overhead
        DJNZ R7, $
        
        MOV C, DHT_IO       ; Sample the state of the pin
        RLC A               ; Shift Carry into Accumulator A
        
        JB DHT_IO, $        ; If still HIGH, wait for it to go LOW before next bit
        DJNZ R5, B_LP       ; Repeat for 8 bits
        RET

;==========================================================
; DELAY ROUTINES (CALIBRATED FOR 12MHZ)
;==========================================================
; Delay ~25ms
DELAY_25MS:
        MOV R6, #50
D25_1:  MOV R7, #250        ; 250 * 2us = 500us
D25_2:  DJNZ R7, D25_2      
        DJNZ R6, D25_1
        RET

; Delay ~2s
DELAY_2S:
        MOV R3, #80         ; 80 * 25ms = 2000ms = 2s
D2S_LP: LCALL DELAY_25MS
        DJNZ R3, D2S_LP
        RET

; Delay ~100ms
DELAY_100MS:
        MOV R3, #4
D100_LP: LCALL DELAY_25MS
        DJNZ R3, D100_LP
        RET

; Delay ~5ms
DELAY_5MS:  
        MOV R6, #10
D5_1:   MOV R7, #250
D5_2:   DJNZ R7, D5_2
        DJNZ R6, D5_1
        RET

;==========================================================
; I2C & LCD DRIVERS (Bit-Banging)
;==========================================================
I2C_INIT: 
          SETB SDA
          SETB SCL
          RET

I2C_START: 
           SETB SDA
           SETB SCL
           NOP
           CLR SDA
           NOP
           CLR SCL
           RET

I2C_STOP: 
          CLR SDA
          SETB SCL
          NOP
          SETB SDA
          RET

I2C_WRITE: 
        MOV R7, #8          ; Send 8 bits
W_BIT:  RLC A               ; MSB First
        MOV SDA, C
        SETB SCL
        NOP
        CLR SCL
        DJNZ R7, W_BIT
        SETB SDA            ; Receive ACK (ignored)
        SETB SCL
        NOP
        CLR SCL
        RET

; Sends content of R6 to I2C LCD Backpack
SEND_PACKET: 
             ACALL I2C_START
             MOV A, #LCD_ADDR
             ACALL I2C_WRITE
             MOV A, R6
             ACALL I2C_WRITE
             ACALL I2C_STOP
             RET

; Sends a 4-bit nibble to the LCD via PCF8574
; Logic: [D7 D6 D5 D4] [Backlight E RW RS]
SEND_NIBBLE: 
             MOV R2, A           ; Save original A
             ANL A, #0F0H        ; Keep only upper 4 bits
             MOV R3, A           ; Store nibble in R3
             MOV A, BL_STATE     ; Add Backlight bit
             ORL A, R5           ; Add RS bit (R5=1 for data, 0 for cmd)
             ORL A, #04H         ; Set EN (Enable) pin HIGH
             ORL A, R3           ; Combine with data nibble
             MOV R6, A
             ACALL SEND_PACKET   ; Send Nibble with EN=1
             
             MOV A, R6
             ANL A, #0FBH        ; Set EN pin LOW (falling edge triggers LCD)
             MOV R6, A
             ACALL SEND_PACKET
             MOV A, R2           ; Restore A
             RET

LCD_SEND_BYTE: 
               ACALL SEND_NIBBLE  ; Send high nibble
               SWAP A             ; Swap nibbles
               ACALL SEND_NIBBLE  ; Send low nibble
               RET

LCD_CMD: 
         MOV R5, #00H        ; RS = 0 for Command
         ACALL LCD_SEND_BYTE
         RET

LCD_DATA_BYTE: 
               MOV R5, #01H  ; RS = 1 for Data
               ACALL LCD_SEND_BYTE
               RET

LCD_INIT: 
          LCALL DELAY_25MS
          MOV A, #30H         ; 4-bit initialization sequence
          MOV R5, #0
          ACALL SEND_NIBBLE
          LCALL DELAY_5MS
          MOV A, #30H
          ACALL SEND_NIBBLE
          LCALL DELAY_5MS
          MOV A, #30H
          ACALL SEND_NIBBLE
          MOV A, #20H         ; Set to 4-bit mode
          ACALL SEND_NIBBLE
          
          MOV A, #28H         ; Function Set: Enable all available lines.
          ACALL LCD_CMD
          MOV A, #0CH         ; Display ON, Cursor OFF
          ACALL LCD_CMD
          MOV A, #06H         ; Entry Mode: Increment cursor
          ACALL LCD_CMD
          MOV A, #01H         ; Clear Display
          ACALL LCD_CMD
          LCALL DELAY_25MS
          RET

LCD_LINE1: MOV A, #80H        ; Force cursor to beginning of 1st line
           ACALL LCD_CMD
           RET
LCD_LINE2: MOV A, #0C0H       ; Force cursor to beginning of 2nd line
           ACALL LCD_CMD
           RET
LCD_LINE3: MOV A, #94H        ; Start address for Line 3 on 2004 LCD
           ACALL LCD_CMD
           RET
LCD_LINE4: MOV A, #0D4H       ; Start address for Line 4 on 2004 LCD
           ACALL LCD_CMD
           RET

; Routine to print a null-terminated string from DPTR
LCD_STR:   CLR A
           MOVC A, @A+DPTR
           JZ EXT_STR         ; If char is 0, exit
           ACALL LCD_DATA_BYTE
           INC DPTR
           SJMP LCD_STR
EXT_STR:   RET

; Converts 8-bit number in A to 2 ASCII digits and prints
SHOW_NUM:  MOV B, #10
           DIV AB             ; A = Tens, B = Ones
           ADD A, #30H        ; Convert Tens to ASCII
           ACALL LCD_DATA_BYTE
           MOV A, B
           ADD A, #30H        ; Convert Ones to ASCII
           ACALL LCD_DATA_BYTE
           RET

; --- Data Strings ---
TXT_TEMP: DB 'Temperature: ', 0
TXT_HUMI: DB 'Humidity: ', 0
END