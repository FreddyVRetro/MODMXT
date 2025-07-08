; PSG / AY-3-8910
; Registers / minimal doc: https://vdsteenoven.com/aquarius/psgprog.html

PSG_PortOffset DB 0  ; 0 First Chip / 2 Second Chip

; Init the TDYLPT Base Ports if Selected.
Init_PSG Proc Near

     CALL PSG_Mute
	 
     RET
Init_PSG Endp

; Set all the channels volume to 0
PSG_Mute Proc Near
        mov cs:PSG_PortOffset,0  ; First chip
        mov ax,070FFh    ; Register 7: Disable all the channels
	call PSG_Out
        
        mov cs:PSG_PortOffset,2  ; Second Chip
        mov ax,070FFh
	call PSG_Out        
	RET
PSG_Mute Endp	

; Set a Tandy Channel to 0
; Input: BX Channel number
PSG_Mute_Channel Proc Near
        
        cmp bx,6
        jae PSG_Mute_Channel_end
        mov cs:PSG_PortOffset,0
        cmp bl,3
        jbe PSG_Mute_2ndChip 
        mov cs:PSG_PortOffset,2
        sub bl,3
PSG_Mute_2ndChip:

        add bl,8        ; Volume are Regs 8 to 10
        mov ah,bl
        mov al,0
 	call PSG_Out    ; Set the channel colume to 0

PSG_Mute_Channel_end:
        RET
PSG_Mute_Channel Endp

; Write to a PSG Register
; Input: AH: Register, AL Value
; Change: ax,dx, flags
PSG_Out Proc Near
        mov dx,cs:PSG_Port
        add dl,cs:PSG_PortOffset
        
        xchg ah,al
        out dx,al       ; Write to Register index port
        xchg ah,ah
        inc dx          ; Move to Data port
        out dx,al       ; Write the Data

        RET
PSG_Out Endp