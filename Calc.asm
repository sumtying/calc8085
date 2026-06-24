; ==============================================================================
; ADVANCED 16-KEY CALCULATOR - MTK-85 (NATIVE MY1SIM85 SYNTAX)
; MODULE: THE "PANIC BUTTON" RST 6.5 INTERRUPT (ANTI-BOUNCE SHIELD)
; ==============================================================================

COMMAND_WRITE:  EQU  50H
COMMAND_READ:   EQU  52H
DATA_WRITE:     EQU  51H
DATA_READ:      EQU  53H
BUSY:           EQU  80H

SYSTEM_PORT_A:  EQU  10H
SYSTEM_PORT_B:  EQU  11H
SYSTEM_PORT_C:  EQU  12H
SYSPORTCTRL:    EQU  13H

    ; --------------------------------------------------------------------------
    ; Interrupt Vector for RST 6.5 (Hardware Button)
    ; --------------------------------------------------------------------------
    ORG  8034H
    JMP  ISR65
    
    ; --------------------------------------------------------------------------
    ; Main Program Start
    ; --------------------------------------------------------------------------
    ORG  8100H
START:
    LXI  SP, 0F000H
    
    ; Enable Hardware Interrupts (Bit 1 MUST be 0 to UNMASK RST 6.5!)
    MVI  A, 00001101B
    SIM
    EI
    
    ; Configure Ports
    MVI  A, 10010000B    
    OUT  SYSPORTCTRL  
    
    ; Initialize System
    CALL INIT_LCD
    LXI  H, 0000H
    CALL GOTO_XY
    LXI  H, MSG_START
    CALL PUT_STR_LCD

    MVI  A, 00H
    OUT  00H           ; Ensure LEDs are OFF on boot
    STA  VAL1
    STA  VAL2
    STA  OPMODE
    STA  DISPVAL
    MVI  A, 0FFH
    STA  KEY

MAIN:    
    CALL  SCAN 
    LDA   KEY  
    CPI   0FFH
    JZ    RENDER
    
    CALL  get_key_code
    CPI   0FFH
    JZ    RENDER
    
    MOV   C, A

WAIT_RELEASE:
    CALL  SCAN
    LDA   KEY
    CPI   0FFH
    JNZ   WAIT_RELEASE

    MOV   A, C
    CPI   0FH
    JZ    FORCE_RESET

    MOV   A, C
    CPI   0EH
    JZ    CALCULATE

    MOV   A, C
    CPI   0AH
    JNC   OPERATOR_SET

NUM_PROC:
    MVI   A, 00H       ; Turn LEDs OFF when typing new number
    OUT   00H
    
    MOV   A, C
    STA   DISPVAL
    
    LDA   OPMODE
    CPI   00H
    JNZ   SAVE_NUM2

SAVE_NUM1:
    MOV   A, C
    STA   VAL1
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_N1
    CALL  PUT_STR_LCD
    JMP   RENDER

SAVE_NUM2:
    MOV   A, C
    STA   VAL2
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_N2
    CALL  PUT_STR_LCD
    JMP   RENDER

OPERATOR_SET:
    MVI   A, 00H       ; Turn LEDs OFF when an operator is pressed
    OUT   00H
    
    MOV   A, C
    STA   OPMODE
    
    CPI   0AH
    JZ    SHOW_ADD
    CPI   0BH
    JZ    SHOW_SUB
    CPI   0CH
    JZ    SHOW_MUL
    CPI   0DH
    JZ    SHOW_DIV
    JMP   RENDER

SHOW_ADD:
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_ADD
    CALL  PUT_STR_LCD
    JMP   RENDER

SHOW_SUB:
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_SUB
    CALL  PUT_STR_LCD
    JMP   RENDER

SHOW_MUL:
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_MUL
    CALL  PUT_STR_LCD
    JMP   RENDER

SHOW_DIV:
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_DIV
    CALL  PUT_STR_LCD
    JMP   RENDER

CALCULATE:
    LDA   OPMODE
    CPI   0AH
    JZ    ADD_OP
    CPI   0BH
    JZ    SUB_OP
    CPI   0CH
    JZ    MUL_OP
    CPI   0DH
    JZ    DIV_OP
    JMP   RENDER

ADD_OP:
    LDA   VAL1
    MOV   B, A
    LDA   VAL2
    ADD   B
    JMP   SAVE_RES

SUB_OP:
    LDA   VAL1
    MOV   B, A
    LDA   VAL2
    MOV   C, A
    MOV   A, B
    SUB   C
    JMP   SAVE_RES

MUL_OP:
    LDA   VAL1
    CPI   00H
    JZ    MUL_ZERO
    MOV   B, A
    LDA   VAL2
    CPI   00H
    JZ    MUL_ZERO
    MOV   C, A
    MVI   A, 00H
MUL_LOOP:
    ADD   B
    DCR   C
    JNZ   MUL_LOOP
    JMP   SAVE_RES
MUL_ZERO:
    MVI   A, 00H
    JMP   SAVE_RES

DIV_OP:
    LDA   VAL1
    MOV   B, A
    LDA   VAL2
    MOV   C, A
    MVI   D, 00H
    MOV   A, C
    CPI   00H
    JZ    DIV_ZERO
DIV_LOOP:
    MOV   A, B
    SUB   C
    JC    DIV_END
    MOV   B, A
    INR   D
    JMP   DIV_LOOP
DIV_END:
    MOV   A, D
    JMP   SAVE_RES
DIV_ZERO:
    MVI   A, 00H
    JMP   SAVE_RES

SAVE_RES:
    STA   DISPVAL
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_TOT
    CALL  PUT_STR_LCD
    
    MVI   A, 00001111B ; Turn ALL 4 LEDs ON for TOTAL
    OUT   00H         
    
    JMP   RENDER

FORCE_RESET:
    MVI   A, 00H       ; Turn LEDs OFF
    OUT   00H         
    STA   VAL1
    STA   VAL2
    STA   OPMODE
    STA   DISPVAL      ; Setting this to 00 zeroes out the 7-segments
    CALL  CLEAR_LCD
    LXI   H, 0000H
    CALL  GOTO_XY
    LXI   H, MSG_START
    CALL  PUT_STR_LCD
    EI                 ; CRITICAL: Re-enables interrupts after ISR kill-switch
    JMP   RENDER

; ==============================================================================
; MODULE: DISPLAY MULTIPLEXER (7-SEGMENT)
; ==============================================================================
RENDER:
    LDA   DISPVAL
    MVI   B, 00H
    
DIV_10:
    CPI   0AH
    JC    DIV_END_10
    SUI   0AH
    INR   B
    JMP   DIV_10
    
DIV_END_10:
    MOV   E, A
    MOV   A, B
    STA   TENS
    MOV   A, E
    STA   ONES

    MVI   A, 03H              
    ORI   0F0H
    OUT   SYSTEM_PORT_C        
    LDA   ONES
    LXI   H, DATA_HEX       
    MVI   B, 00H          
    MOV   C, A          
    DAD   B
    MOV   A, M          
    OUT   SYSTEM_PORT_B
    CALL  DLYLAH
    MVI   A, 00H
    OUT   SYSTEM_PORT_B
    CALL  DLYLAH    

    MVI   A, 02H       
    ORI   0F0H
    OUT   SYSTEM_PORT_C           
    LDA   TENS
    LXI   H, DATA_HEX
    MVI   B, 00H
    MOV   C, A
    DAD   B
    MOV   A, M
    OUT   SYSTEM_PORT_B           
    CALL  DLYLAH
    MVI   A, 00H      
    OUT   SYSTEM_PORT_B           
    CALL  DLYLAH  
    JMP   MAIN

; ==============================================================================
; MODULE: ISR65 - THE "PANIC BUTTON" (ANTI-BOUNCE & RETURN HOME)
; ==============================================================================
ISR65:
    DI                  ; 1. Kill-Switch: Prevent any bounce from triggering again
    LXI   SP, 0F000H    ; 2. Stack Flush: Instantly cure any memory overflows
    
    ; 3. Run the exact LED Pattern requested
    MVI   A, 00001010B  
    OUT   00H
    CALL  DELAY_SW
    
    MVI   A, 00000000B  
    OUT   00H
    CALL  DELAY_SW

    MVI   A, 00000101B  
    OUT   00H
    CALL  DELAY_SW
    
    MVI   A, 00000000B  
    OUT   00H
    CALL  DELAY_SW

    MVI   A, 00001010B  
    OUT   00H
    CALL  DELAY_SW
    
    MVI   A, 00000000B  
    OUT   00H
    CALL  DELAY_SW

    MVI   A, 00000101B  
    OUT   00H
    CALL  DELAY_SW
    
    MVI   A, 00000000B  
    OUT   00H
    CALL  DELAY_SW

    ; 4. Jump directly to Home (Zeroes the 7-segment & re-enables EI)
    JMP   FORCE_RESET

; Software Delay (Safe to run inside an interrupt)
DELAY_SW:
    PUSH  B
    PUSH  D
    MVI   B, 08H        ; Outer Loop counter
DSW_OUT:
    LXI   D, 0FFFFH     ; Inner Loop counter
DSW_IN:
    DCX   D
    MOV   A, D
    ORA   E
    JNZ   DSW_IN
    DCR   B
    JNZ   DSW_OUT
    POP   D
    POP   B
    RET

; ==============================================================================
; MODULE: HARDWARE LCD DRIVERS
; ==============================================================================
LCD_READY:     
    PUSH  PSW
LCD_READY1:    
    IN    COMMAND_READ
    ANI   BUSY
    JNZ   LCD_READY1 
    POP   PSW
    RET

CLEAR_LCD:     
    CALL  LCD_READY
    MVI   A, 01H
    OUT   COMMAND_WRITE
    RET

INIT_LCD:      
    CALL  LCD_READY
    MVI   A, 38H
    OUT   COMMAND_WRITE
    CALL  LCD_READY
    MVI   A, 0CH
    OUT   COMMAND_WRITE
    CALL  CLEAR_LCD
    RET

PUT_STR_LCD:   
    MOV   A, M 
    CPI   00H
    JNZ   PUT_STR_LCD1
    RET
PUT_STR_LCD1:  
    CALL  LCD_READY
    OUT   DATA_WRITE
    INX   H
    JMP   PUT_STR_LCD

GOTO_XY:       
    CALL  LCD_READY
    MOV   A, L 
    CPI   00H
    JNZ   GOTO_XY1
    MOV   A, H
    ADI   80H 
    OUT   COMMAND_WRITE
    RET
GOTO_XY1:      
    CPI   01H
    JNZ   GOTO_XY4
    MOV   A, H
    ADI   0C0H 
    OUT   COMMAND_WRITE
GOTO_XY4:      
    RET

DLYLAH:        
    MVI   C, 044H  
LOOP13:        
    DCR   C
    JNZ   LOOP13
    RET

; ==============================================================================
; MODULE: KEYPAD MATRIX SCANNER
; ==============================================================================
SCAN:
    PUSH  H
    PUSH  B
    PUSH  D
    MVI   C, 06H
    MVI   E, 00H
    MVI   D, 00H
    MVI   A, 0FFH
    STA   KEY
SCAN1:
    MOV   A, E
    ORI   0F0H
    OUT   SYSTEM_PORT_C
    MVI   B, 01H
WAIT1:
    DCR   B
    JNZ   WAIT1
    IN    SYSTEM_PORT_A
    MVI   B, 08H
SHIFT_KEY:
    RAR
    JC    NEXT_KEY
    PUSH  PSW
    MOV   A, D
    STA   KEY
    POP   PSW
NEXT_KEY:
    INR   D
    DCR   B
    JNZ   SHIFT_KEY
    MVI   A, 00H
    INR   E
    DCR   C
    JNZ   SCAN1
    POP   D
    POP   B
    POP   H
    RET

; ==============================================================================
; MODULE: 16-KEY HARDWARE MAPPING
; ==============================================================================
get_key_code:
    CPI   02H 
    JNZ   CODE1 
    MVI   A, 0AH 
    RET
CODE1:
    CPI   0AH 
    JNZ   CODE2 
    MVI   A, 0BH 
    RET
CODE2:
    CPI   12H 
    JNZ   CODE3 
    MVI   A, 0CH 
    RET
CODE3:
    CPI   1AH 
    JNZ   CODE4 
    MVI   A, 0DH 
    RET
CODE4:
    CPI   03H 
    JNZ   CODE5 
    MVI   A, 09H 
    RET
CODE5:
    CPI   0BH 
    JNZ   CODE6 
    MVI   A, 00H 
    RET
CODE6:
    CPI   13H 
    JNZ   CODE7 
    MVI   A, 0EH 
    RET
CODE7:
    CPI   1BH 
    JNZ   CODE8 
    MVI   A, 0FH 
    RET
CODE8:
    CPI   04H 
    JNZ   CODE9 
    MVI   A, 05H 
    RET
CODE9:
    CPI   0CH 
    JNZ   CODE10 
    MVI   A, 06H 
    RET
CODE10:
    CPI   14H 
    JNZ   CODE11 
    MVI   A, 07H 
    RET
CODE11:
    CPI   1CH 
    JNZ   CODE12 
    MVI   A, 08H 
    RET
CODE12:
    CPI   05H 
    JNZ   CODE13 
    MVI   A, 01H 
    RET
CODE13:
    CPI   0DH 
    JNZ   CODE14 
    MVI   A, 02H 
    RET
CODE14:
    CPI   15H 
    JNZ   CODE15 
    MVI   A, 03H 
    RET
CODE15:
    CPI   1DH 
    JNZ   CODE_END 
    MVI   A, 04H 
    RET
CODE_END:
    MVI   A, 0FFH
    RET

; ==============================================================================
; ROM DATA
; ==============================================================================
MSG_START: DFB 43H, 41H, 4CH, 43H, 20H, 52H, 45H, 41H, 44H, 59H, 00H
MSG_N1:    DFB 3EH, 20H, 4EH, 55H, 4DH, 20H, 31H, 3AH, 20H, 00H
MSG_N2:    DFB 3EH, 20H, 4EH, 55H, 4DH, 20H, 32H, 3AH, 20H, 00H
MSG_ADD:   DFB 4FH, 50H, 3AH, 20H, 5BH, 2BH, 5DH, 20H, 00H
MSG_SUB:   DFB 4FH, 50H, 3AH, 20H, 5BH, 2DH, 5DH, 20H, 00H
MSG_MUL:   DFB 4FH, 50H, 3AH, 20H, 5BH, 2AH, 5DH, 20H, 00H
MSG_DIV:   DFB 4FH, 50H, 3AH, 20H, 5BH, 2FH, 5DH, 20H, 00H
MSG_TOT:   DFB 54H, 4FH, 54H, 41H, 4CH, 3AH, 20H, 00H

DATA_HEX:  DFB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH

; ==============================================================================
; SYSTEM MEMORY MAP
; ==============================================================================
    ORG  0E000H
KEY:        DFS 1
VAL1:       DFS 1
VAL2:       DFS 1
OPMODE:     DFS 1
DISPVAL:    DFS 1
ONES:       DFS 1
TENS:       DFS 1