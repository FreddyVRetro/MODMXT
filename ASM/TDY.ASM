; Tandy 3 Channels chip Code

TDYLPTPort DW 0

; Init the TDYLPT Base Ports if Selected.
Init_TDY Proc Near

	 CMP TDY_Type,0
	 JE Not_Init_TDY
     CMP TDY_Type,2
	 JNE Not_Init_TDYLPT

	 MOV AX,LPT1_Port
	 CMP TDY_LPT_Nb,1
	 JE Save_TDYLPTPort
     MOV AX,LPT2_Port
Save_TDYLPTPort:
     MOV TDYLPTPort,AX

;Unmute the Tandy LPT
     MOV DX,AX
     INC DX
     INC DX
	 
     MOV AL,07h
	 OUT DX,AL
	 MOV CX,100
TDYLPT_Delay:
	 IN AL,DX
	 LOOP TDYLPT_Delay
     MOV AL,09h	 
     OUT DX,AL

Not_Init_TDYLPT:

	 CALL TDY_Mute

Not_Init_TDY:
	 
     RET
Init_TDY Endp

; Set all the channels volume to 0
TDY_Mute Proc Near
        MOV AL,10011111b   ; Ch1 Off
		CALL TDY_Out
        MOV AL,10111111b   ; Ch2 Off
		CALL TDY_Out
        MOV AL,11011111b   ; Ch3 Off
		CALL TDY_Out
        MOV AL,11111111b   ; Noise Off
		CALL TDY_Out	
		RET
TDY_Mute Endp	

; Set a Tandy Chamnnel to 0
; Input: BX Channel number
TDY_Mute_Channel Proc Near

        CMP BX,4
        JA TDY_Mute_Channel_End
		
        PUSH AX
        PUSH CX
        MOV AX,BX
		AND AL,00000011b
		MOV CL,5
		SHL AL,CL
		XOR AL,10011111b

		CALL TDY_Out	

        POP CX
        POP AX
TDY_Mute_Channel_End:
        RET
TDY_Mute_Channel Endp

; Output a Byte to the Tandy Port
; TDYLPT Code provided by Benedikt
; Input: AL Value
; Change: ax,dx, flags
TDY_Out Proc Near
        CMP TDY_Type,2 ; 2: TDYLPT
		JE TDYLPT_Out

        MOV DX,TDY_Port
		OUT DX,AL
        RET

TDYLPT_Out:

        mov     dx,cs:TDYLPTPort
        out     dx,al   ; Send the Value
        inc     dx
        inc     dx
	   
        mov     al,0Ch  ; Use the LPT Command Line to simulate the IOW
        out     dx,al   ; Out 0Ch
        dec     dx
        mov     ah,24   ; 24 loop max
@l1:    dec     ah
        js      @l2
        in      al,dx
        and     al,40h
        jnz     @l1
@l2:    dec     ah
        js      @l2end
        in      al,dx
        and     al,40h
        jz      @l2
@l2end: inc     dx
        mov     al,9
        out     dx,al  ; Out 09h
	
        RET
TDY_Out Endp