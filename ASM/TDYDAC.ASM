; Tandy DAC Code

TDYDAC_ClockSpeed  Equ 3579545 ; Not used
TDYDAC_ClockSpeedH Equ 36h
TDYDAC_ClockSpeedL Equ 9E99h

TDYDAC_Frequency DW 0  ; Value to send to the Tandy DAC ( 3.5MHz / Frequency )


; Get the Real DAC Output frequency from the requested frequency
; Input : AX, Output Frequency
; Output: AX, Real Frequency
TDYDAC_ComputeFrequency Proc Near

		MOV BX,Out_Frequency
        MOV AX,TDYDAC_ClockSpeedL
        MOV DX,TDYDAC_ClockSpeedH
        DIV BX
        MOV TDYDAC_Frequency,AX ; Value to be sent to the DAC

		MOV BX,AX
        MOV AX,TDYDAC_ClockSpeedL
        MOV DX,TDYDAC_ClockSpeedH
        DIV BX		
		MOV Real_Frequency,AX   ; Real Frequency (To adjust the buffers size)

        RET
TDYDAC_ComputeFrequency EndP

; Start the Tandy DAC
; DMA and IRQ need to be configured before

;Port 0C4h (1E4h, 304h)          DAC Mode Register
;Bits 0-2 and 4-6 are read/write
;
;  Bit(s)        Meaning
;  ------        -------
;    0-1         DAC function select:  0 = joystick, 1 = sound channel
;                  (fourth tone channel, used with 3-voice chip), 2 = 
;                  successive approximation (sound input), 3 = direct write 
;                  to DAC (sound output).
;    2           DMA enable (if bit 1 = 1).  0 = DMA disabled, 1 = DMA enabled.
;    3 (read)    1 = DMA interrupt has occurred.
;    3 (write)   DMA interrupt clear.  0 = DMA interrupt held clear, 1 = DMA
;                  interrupt allowed.  When DMA interrupt occurs, this bit
;                  must be set low, then set high to allow another interrupt.
;    4           DMA interrupt enable.  0 = DMA EOP interrupt disabled, 1 =
;                  DMA EOP interrupt enabled.
;    5           Sound divider sync enable.  0 = synchronization disabled, 1 =
;                  synchronization enabled.  See below.
;    6           Sound chip extra divide enable.  0 = extra divide disabled
;                  (10-bit dividers for 3-voice tone generator), 1 = extra
;                  divide enabled (11-bit dividers).
;    7 (read)    0 = Successive approximation done.  When polling for input,
;                  indicates that a byte of sound is ready to read at port
;                  0C5h (1E5h, 305h).

				   
TDYDAC_Start Proc Near

; Set DAC Speed
        MOV AX,TDYDAC_Frequency
        MOV DX,TDYDAC_Port
        ADD DX,2        ; program low byte of speed
        OUT DX,AL
        INC DX		    ; program high byte of speed (+ Volume 0)
        MOV AL,AH
        OUT DX,AL

; Start the DAC
	    MOV DX,TDYDAC_Port ; Direct write to DAC, DMA enabled, DMA
	    MOV AL,17h      ;   interrupt enabled, DMA interrupt clear 00010111b
	    OUT DX,AL
	    MOV AL,1Fh		; Direct write to DAC, DMA enabled, DMA
	    OUT DX,AL		; Interrupt enabled, DMA interrupt allowed 00011111b

        MOV AL,7
        CALL TDYDAC_SetVol

        RET
TDYDAC_Start Endp

; Set the Tandy Chip to 3 Channels
; Change AX, DX
TDYDAC_Stop Proc Near

	    MOV DX,TDYDAC_Port
	    MOV AL,00000001b ; DMA Disabled, Sound Channel Mode
	    OUT DX,AL
		
        RET
TDYDAC_Stop Endp

; AL:Volume (0-7)
; Change AX, DX
TDYDAC_SetVol Proc Near
	MOV	DX,TDYDAC_Port	; DX is volume port
	ADD	DX,3

	ROR	AL,1
	ROR	AL,1
	ROR	AL,1
	MOV	AH,AL		; most significant 3 bits of AH = volume
	CLI
	IN	AL,DX		; get DAC amplitude/frequency MSB
	AND	AL,1Fh		; mask out old volume
	OR	AL,AH		; put in new volume
	OUT	DX,AL		; write back DAC amplitude/frequency MSB
	RET
TDYDAC_SetVol Endp