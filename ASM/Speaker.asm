.MODEL small
.STACK 100h

Yes Equ 0
No  Equ -1

b Equ Byte Ptr
w Equ Word Ptr
d Equ DWord Ptr

HW_NoMODM Equ Yes

.DATA
Msg_Start DB 'Speaker Test Code',13,10,'$'
Msg_CRLF  DB 13,10,'$'


Sample DB 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16

.CODE
Main Proc
     mov ax,@data
     mov ds,ax ;set DS to point to the data segment

     mov dx,OFFSET Msg_Start
	 call PrintStr_DOS

MOV ax,1234

		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		XOR AH,AH
		CALL PrintAX_Dec_DOS
		POP DX
		POP CX
		POP BX
		POP AX

	 
     DOS_Terminate

Main Endp

; CS Data
P_Speed DB 2

DOS_GetVersion Macro
    mov ah,30h
	int 21h
Endm

DOS_Terminate Macro
     mov ah,4ch ;DOS terminate program function
     int 21h ;terminate the program
Endm

Include PrintDOS.asm
Include hardware.asm

;IRQ Timer code, Taken from Mod Master

SampleLength  DW 16
Buffer_Cnt    DW 0

IRQ_Timer_PCS:

        PUSH DS
        PUSH AX
	
; ******  Read the Buffer Data 
        MOV AX,1234h             ; DS=Segment de la table de volume et Tampons
IRQ_PCS_Seg_Volume:
        MOV DS,AX
		MOV AL,Byte Ptr DS:[1234h]
IRQ_PCS_Index:
 		
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		XOR AH,AH
		CALL PrintAX_Dec_DOS
		POP DX
		POP CX
		POP BX
		POP AX
		
        OUT 42h,AL  ; Reset the Timer 2 Value
		
        INC W CS:[Offset IRQ_PCS_Index-2]

        MOV AL,20h
        OUT 20h,AL

        DEC CS:Buffer_Cnt
        JZ IRQ_Timer_PCS_NextBuffer
		
		POP AX	
        POP DS
        IRET

IRQ_Timer_PCS_NextBuffer:		

        PUSH CS
		POP  DS
		
        MOV AX,SampleLength        
        MOV Buffer_Cnt,AX
	
        MOV AX,Offset Sample
        MOV W CS:[Offset IRQ_PCS_Index-2],AX

		POP AX	
        POP DS
        IRET


EnableSpeakerPWM Proc Near
       IN AL,61h                 ; Activate the PC Speaker (Port B Bit 0 and 1)
       OR AL,03h
       OUT 61h,AL

       mov al,TIMER2+LSB+MODE0+BINARY   ; 10010000b
       out 43h,al
       mov al,01h
       out 42h,al  ; Counter 2 count = 1 - terminate count quickly
       
	   ret
EnableSpeakerPWM Endp

DisableSpeaker Proc Near
        IN AL,61h        ; Stopper le H.P. Interne
        AND AL,0FCh
        OUT 61h,AL
		ret
DisableSpeaker Endp

Restore_Timer Proc Near
        CLI
        XOR AX,AX
        CALL Set_Timer0_Period ;(Use AX Only)
        CALL Restore_Timer_IRQ ;(Don't change Regs)
        STI
Restore_timer Endp

TimeAdr dw	06Ch,040h

SpeedTest Proc near
	push ds
	push si

	xor	dx,dx           ; "Speed" Value
	lds	si,cs:[dword ptr TimeAdr]
	mov	bx,[ds:si]
@@EDGE: cmp	bx,[ds:si]  ; Detect the edge of the timer
	je	@@EDGE
	inc	bx

SpeedTestLoop:
    push dx
REPT 32
    NOP
ENDM
    pop dx
	inc	dx
	cmp	bx,[ds:si]
	je	SpeedTestLoop

	mov	ax,dx

	pop	si
	pop	ds
	ret
SpeedTest endp

END