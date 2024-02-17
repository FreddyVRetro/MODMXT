

CMSPortOffset DB 0  ; 0 First Chip / 2 Second Chip
CMSLPTPort    DW 0

; Init_CMS
; Set the CMSLPT Port and initialize the CMS Chip
Init_CMS Proc Near

	 CMP CMS_Type,0
	 JE Not_Init_CMS
     CMP CMS_Type,2
	 JNE Not_Init_CMSLPT

	 MOV AX,LPT1_Port
	 CMP CMS_LPT_Nb,1
	 JE Save_CMSLPTPort
     MOV AX,LPT2_Port
Save_CMSLPTPort:
     MOV CMSLPTPort,AX

Not_Init_CMSLPT:

	 CALL CMS_Reset

Not_Init_CMS:
	 
     RET
Init_CMS Endp

; Reset the 2 CMS Chip
CMS_Reset Proc Near
      MOV  CMSPortOffset,0
      CALL CMS_Clear
	  
      MOV  CMSPortOffset,2
      CALL CMS_Clear
      RET
CMS_Reset Endp	

; Clear all the register and Reset the Chip
CMS_Clear Proc Near
      MOV CX,20h
      XOR AX,AX
loop_null:           ; null all 20 registers 
      PUSH AX
      CALL CMS_Out
	  POP AX
      INC  AH        ; Next register
      loop  loop_null

      MOV  AX,01C02h ; reset chip 
      CALL CMS_Out

      MOV AX,01C01h ; enable this chip 
      CALL CMS_Out

      RET
CMS_Clear Endp

; Disable all the Channels
CMS_Mute Proc Near

      XOR BX,BX
CMS_MuteLoop:	  
      CALL CMS_Mute_Channel
      INC BX
	  CMP BX,11
	  JBE CMS_MuteLoop ; Loop 0 to 11
	
      RET
CMS_Mute Endp


; Stop a Channel
; Input: BX Channel number
CMS_Mute_Channel Proc Near
      PUSH BX
      MOV  CMSPortOffset,0
      CMP BL,6
      JB CMS_Mutebelow6
	  SUB BL,6
      MOV  CMSPortOffset,2
CMS_Mutebelow6:

      XOR AX,AX
      MOV AH,BL
      CALL CMS_Out  ; Registers 0 to 5 are for the volume
	  
      POP BX
      RET
CMS_Mute_Channel Endp

; Set a CMS Register Value
;	AH : Register
;	AL : Data
; Port @ : CMS_Port+CMSPortOffset
; Destroy AX, DX
CMS_Out Proc Near

        CMP CMS_Type,2 ; 2: CMSLPT
		JE CMSLPT_Out

        MOV DX,CMS_Port
        ADD DL,CMSPortOffset ; First or Second Chip
		
        INC DX
        XCHG AL,AH
        OUT DX,AL
        DEC DX
        XCHG AL,AH
        OUT DX,AL
        RET
CMS_Out EndP

;	AH : Register
;	AL : Data
CMSLPT_Out Proc Near

    MOV DX,CS:CMSLPTPort

    CMP CS:CMSPortOffset,0
    JE CMSLPT_1

;PUSH AX
;push dx
;Writech '1'
;pop dx
;Writech ':'
;MOV AX,DX
;Call WriteWordH
;POP AX

; first chip
    PUSH AX
    MOV AL,AH
    OUT DX,AL  ; LPT Data (Register number)
 
    MOV AL,0Ch ; CMS 0 CS1, A0
    CALL CMSLPT_ToggleWr
    POP AX

    OUT DX,AL  ; LPT Data (Register Value)

    MOV AL,0Dh ; CMS 0 CS1, ~A0
    CALL CMSLPT_ToggleWr
    RET
CMSLPT_1:

;PUSH AX
;push dx
;Writech '2'
;pop dx
;POP AX	

; Second Chip
    PUSH AX
    MOV AL,AH
    OUT DX,AL  ; LPT Data (Register number)
 
	MOV AL,06h ; CMS 1 // CS2, A0
    CALL CMSLPT_ToggleWr
    POP AX
 
    OUT DX,AL  ; LPT Data (Register Value)

	MOV AL,07h ; CMS 1 // CS2, ~A0
    CALL CMSLPT_ToggleWr

    RET		
CMSLPT_Out Endp

; DX : LPT Command Port
; AL : Control Value
CMSLPT_ToggleWr Proc Near

    INC DX
    INC DX     ; LPT Control Port

    OUT DX,AL  ; Write Value
	MOV AH,AL
	XOR AL,04h ; Change Bit 2
	OUT DX,AL

    PUSH CX
    MOV CX,7
CMSToggleLoop:
    IN AL,DX
    LOOP CMSToggleLoop	
	POP CX
	
	MOV AL,AH
	OUT DX,AL ; Write Value again

    DEC DX
    DEC DX    ; LPT Data Port
	
    RET
CMSLPT_ToggleWr Endp