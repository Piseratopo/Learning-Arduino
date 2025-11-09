;------------------------------------------------------
; Simple buzzer program for 8051
; Buzzer connected to P2.5
;------------------------------------------------------

ORG 00H          ; Program start address

START:  SETB P2.5          ; Set pin high
        ACALL DELAY        ; Call delay
        CLR P2.5           ; Set pin low
        ACALL DELAY        ; Call delay
        SJMP START         ; Repeat forever

;------------------------------------------------------
; Delay routine (adjust for tone frequency)
;------------------------------------------------------
DELAY:  MOV R2, #31     ; Outer loop counter
D1:     MOV R1, #30     ; Inner loop counter
D2:     DJNZ R1, D2        ; Decrement inner loop
        DJNZ R2, D1        ; Decrement outer loop
        RET

        END