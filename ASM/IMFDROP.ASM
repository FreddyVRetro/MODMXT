;            -----------------------------------------------------
;            |                   IMFDROP.ASM                     |
;            |              --== Mod Master XT ==--              |
;            |---------------------------------------------------|
;            |   Written By                     Freddy Vetele    |
;            |                                                   |
;            |   Write Start                    08/05/2020       |
;            |   Last Update                    08/05/2025       |
;            -----------------------------------------------------
INCLUDE TDY.ASM
INCLUDE CMS.ASM
INCLUDE PSG.ASM

; * Define Variables used by the Stream Based Music replay *
; > Equ to reuse existing Mod Master Variables (To Save Size and Debug Display)

OPLStreamSeg  DW 0
OPLStreamOffs DW 0 ;Equ [CH_Per_part]

Tick_Count      DW 0 ;Equ [CH_Per_part+2]        ; The IRQ Counter IRQ_Cnt
Tick_Delay      DW 0 ;                           ; Tick Delay Defined by the Stream
Tick_Delay_IRQ  DW 0                             ; Tick Delay used by the IRQ
Tick_Delay_Sub  DW 0 ; Delay Sub Counter
Tick_Skipcount  DW 0 ; Nb of Skipped Tick during the Stream Read

Tick_FFW_Inc    DW 0  ; Fast Forward increment value

RAWSpeed    DW 0

OPLA0Sav   Equ VPart_decimale2    ; record of A0..A8 register values (*2)
OPLB0Sav   Equ VPart_decimale     ; record of B0..B8 register values (*2)
OPLFreqCh  Equ VPart_entiere      ; 1 if A0 or B0 are changed
CMSRegSav0 Equ VCurrent_CMD
CMSRegSav1 Equ VCurrent_PAR
CMSFreq    Equ VC4Spd   ; SAA1099 Save the Octave/Freq

Cnt50       DW 0  ; Counter for the 50Hz Tick
Period50Hz  Equ 23863

DRODelay257 DB 0  ; Value for a Byte Delay
DRODelayShi DB 0  ; Value for a Word Delay

DRORegsSeg  DW 0
DRORegsOffs DW 0  ; Offset to the registers table (Convert the raw value to resister number) -> Do it as 0

Stream_Processing DB 0

; * Init the Stream Music replay Global variables (Common to all) *
Init_StreamMusic Proc Near

If Mod_Master eq yes
        MOV CS:ScreenPos,0
Endif
        LES DI,OtherMUS_Ptr
		MOV OPLStreamSeg,ES
		MOV OPLStreamOffs,DI
		
        MOV Tick_Delay_IRQ,1
        MOV Tick_Skipcount,0
		MOV Tick_Count,0
        MOV Cnt50,0
		MOV Chrono_50,50
        MOV Stream_Processing,0

If Mod_Master eq yes
        DS_TP
        MOV Center_Display,CD_Bar
	    DS_ASM

        MOV MUS_OPLStream,1

		TEST OtherMUS_Out,M_SN76489
		JNZ IA_No_Disable_Channels
		
        XOR BX,BX  ; Disable all the channels to display only the playing ones.
LoopAdl_Disable_ch:
		OR CH_Control[BX],CM_Disabled
		MOV CH_Panning[BX],40h  ; Center
		INC BX
		CMP BX,17
		JNE LoopAdl_Disable_ch

IA_No_Disable_Channels:
Endif
		
		RET
Init_StreamMusic Endp

; *** Start a VGM Stream Replay ***
If UseVGM Eq Yes
VGM_Start Proc Near

; Test if the sound Output is present / configured
	
        TEST OtherMUS_Out,M_OPL2   ; Test OPL2
		JZ VGM_OPL2Ok
        CMP OPL_Model,1             ; OPL2/3 Present ?
		JAE VGM_OPL2Ok
        CMP OPL_LPT_Model,1
		JAE VGM_OPL2Ok		
        MOV Erreur_Modm,Err_OPL_NotFound ; OPL2 Needed and not found
        JMP VGM_Start_End
VGM_OPL2Ok:
		
		TEST OtherMUS_Out,M_OPL3
		JZ VGM_NoOPL3
        MOV Ch_Number,18            ; OPL3 > 18 Channels (For Display)
        CMP OPL_Model,2             ; OPL3 Present ?
		JE VGM_NoOPL3	
        CMP OPL_LPT_Model,2
		JE VGM_NoOPL3		
        MOV Erreur_Modm,Err_OPL3_NotFound ; OPL3 Needed and not found
        JMP VGM_Start_End		
VGM_NoOPL3:
	
		TEST OtherMUS_Out,M_SN76489
		JZ VGM_NoTDY
        MOV Ch_Number,4            ; Tandy > 4 Channels
        CMP TDY_Type,0             ; TDY Present ?
		JNZ VGM_TDY_Present
        MOV Erreur_Modm,Err_TDY_NotFound ; TDY Needed and not found
        JMP VGM_Start_End
VGM_TDY_Present:
        CALL Init_TDY	
VGM_NoTDY:

		TEST OtherMUS_Out,M_SAA1099
		JZ VGM_NoCMS
        CMP CMS_Type,0             ; CMS Present ?
		JNZ VGM_CMS_Present
        MOV Erreur_Modm,Err_CMS_NotFound ; CMS Needed and not found
        JMP VGM_Start_End
VGM_CMS_Present:
        MOV Ch_Number,12           ; CMS > 12 Channels
        CALL Init_CMS
VGM_NoCMS:		

		TEST OtherMUS_Out,M_PSG
		JZ VGM_NoPSG
        CMP PSG_Type,0             ; PSG Present ?
		JNZ VGM_PSG_Present
        MOV Erreur_Modm,Err_PSG_NotFound ; PSG Needed and not found
        JMP VGM_Start_End
VGM_PSG_Present:
        MOV Ch_Number,6           ; CMS > 6 Channels (Dual PSG)
        CALL Init_PSG
VGM_NoPSG:


		TEST OtherMUS_Out,M_OPL2 ; OPL2 Init ?
		JZ   VGM_NoCleanOPL2
        CALL Clean_OPL2Regs
VGM_NoCleanOPL2:
 
		TEST OtherMUS_Out,M_OPL3  ; OPL3 Init ?
		JZ   VGM_NoSetOPL3
; Need OPL3 > Clean Registers and Set OPL2 Mode
        CALL Clean_OPL2Regs
        CALL Clean_OPL3Regs
VGM_NoSetOPL3:

        CALL Init_StreamMusic
        MOV Tick_Delay_Sub,0
	
        MOV OPL_IRQ_Player,Offset VGM_Play
        MOV DX,OFFSET OPLStreamIRQ
	    CALL Change_Timer_IRQ
		
		MOV BX,300
        CALL Timer_HzToPeriod		
		MOV Periode_timer,AX		
        CALL Set_Timer0_Period        ; Set Timer IRQ to 300Hz

VGM_Start_End:
        RET
VGM_Start EndP
EndIf

; *** Start an IMF Stream Replay *** (OPL2)
If UseIMF Eq Yes
IMF_Start Proc Near

        CALL Init_StreamMusic

        MOV OPL_IRQ_Player,Offset IMF_Play
        MOV DX,OFFSET OPLStreamIRQ
	    CALL Change_Timer_IRQ

		MOV BX,Out_Frequency
        CALL Timer_HzToPeriod		
		MOV Periode_timer,AX		
        CALL Set_Timer0_Period        ; Set Timer IRQ to 570KHz

        RET
IMF_Start EndP
EndIf ;UseIMF

; *** Start an RAW Stream Replay *** (OPL2)
If UseRAW Eq Yes
RAW_Start Proc Near

        CALL Init_StreamMusic
        ADD OPLStreamOffs,10         ; Move to the Stream Data

        MOV AX,ES:[DI+8]
        MOV RAWSpeed,AX
		
        MOV OPL_IRQ_Player,Offset RAW_Play
        MOV DX,OFFSET OPLStreamIRQ
	    CALL Change_Timer_IRQ

        MOV AX,RAWSpeed
		; ADD the value calculation for 50Hz
		MOV Periode_timer,AX		
        CALL Set_Timer0_Period        ; Set Timer IRQ to 570KHz

        RET
RAW_Start EndP
EndIf ;UseRAW

; *** Start an DRO Stream Replay *** (OPL2/OPL3)
If UseDRO Eq Yes
DRO_Start Proc Near

        CALL Init_StreamMusic

; Set all the Adlib registers to 0 (With DRO, Registers with a value of 0 are not exported)

        MOV AX,ES:[DI+8]             ; Read Version Maj
		CMP AX,2
		JNE @@DROInvalid

        MOV AX,ES:[DI+21]
		OR AX,AX
		JNZ @@DROInvalid             ; Data Type and Compression should be 0
 
        CALL Clean_OPL2Regs
 
        MOV AL,ES:[DI+20]            ; Hardware Type OPL2/OPL3...
		CMP AL,0
		JE @@DROOPL2
		CMP OPL_Model,2               ; OPL3 Or OPL3LPT ?
		JE @@DROOPL3
		CMP OPL_LPT_Model,2
		JE @@DROOPL3
        MOV Erreur_Modm,Err_OPL3_NotFound ; OPL3 needed and OPL2 Detected
		RET
@@DROOPL3:		
        MOV Ch_Number,18
		MOV Ch_Number_Adlib,18
; DRO OPL3 and OPL3 Present, Clean OPL3 Registers
        CALL Clean_OPL3Regs
@@DROOPL2:

        MOV AH,ES:[DI+23]
        MOV DRODelay257,AH
        MOV AL,ES:[DI+24]
        MOV DRODelayShi,AL
		
        XOR BX,BX
		MOV BL,ES:[DI+25]   ; Register table size

        MOV AX,DI
		ADD AX,26
		MOV DRORegsOffs,AX  ; Register table Offset is the File Start Offset +26
		MOV DRORegsSeg,ES

		ADD AX,BX           ; Add the Table size for Stream Offset
		MOV OPLStreamOffs,AX

        MOV OPL_IRQ_Player,Offset DRO_Play
		MOV DX,OFFSET OPLStreamIRQ
	    CALL Change_Timer_IRQ

        MOV AX,1193                   ; 1193182/1000 -> 1KHz
		MOV Periode_timer,AX
        CALL Set_Timer0_Period        ; Set Timer IRQ to 1KHz

		RET
@@DROInvalid:
        MOV Erreur_Modm,Err_Invalid_MOD
        RET		
DRO_Start Endp
EndIf ;UseDRO

; ****** OPL Stream Play Interrupt ******

OPL_IRQ_Player DW Offset IMF_Play     ; Offset of the code to execute

OPLStreamIRQ Proc Near

		PUSH AX
        PUSH DS

        MOV AL,20h       ; IRQ Ack
        OUT 20h,AL
        STI
		
        DS_ASM
        CMP Stop_Output,0
        JE @@OPLStreamIRQNoStop

Stop_Stream_IRQ:

;WriteCh 'E'
        CALL Stop_Timer_50         ; Stop the IRQ

; Clean OPL3 Regs as Mod Master don't init OPL3   ; Try to set OPL2 mode.
		CMP OPL_Model,2
		JE @@IRQEndCleanOPL3
		CMP OPL_LPT_Model,2
		JE @@IRQEndCleanOPL3
		JMP @@IRQEndNoCleanOPL3
@@IRQEndCleanOPL3:	
		CALL Clean_OPL3Regs  ; Clean the OPL3 Regs  (OPL2 Regs will be clean by the Pascal Code)
		MOV OPLPortOffset,0
@@IRQEndNoCleanOPL3:

		TEST OtherMUS_Out,M_SN76489
		JZ @@IRQEndNoCleanTDY
        CALL TDY_Mute     ; Mute Tandy (Vol=0)
@@IRQEndNoCleanTDY:

		TEST OtherMUS_Out,M_PSG
		JZ @@IRQEndNoCleanPSG
        CALL PSG_Mute     ; Mute PSG (Vol=0)
@@IRQEndNoCleanPSG:

		TEST OtherMUS_Out,M_SAA1099
		JZ @@IRQEndNoCleanCMS
; Writech 'M'
; Writech 'C'
        CALL CMS_Reset

@@IRQEndNoCleanCMS:

        MOV Output_Stopped,1
		JMP @@OPLIRQEnd

@@OPLStreamIRQNoStop:
;        Writech 'I'
		
        CMP MMSS_Pause,1
        JE @@OPLIRQEnd

; INC Tick count
        INC Tick_Count
		MOV AX,Tick_Delay_IRQ
		CMP Tick_Count,AX          ; Tick Delay Reached ?
		JB  @@NoPlay

; Tick Delay Expired
		XOR AX,AX
		MOV Tick_Count,AX           ; Clean the tick Counter

        CMP Stream_Processing,1    ; Do not Read the Stream is the Stream Read / play is not completed
		JNE Do_StreamProcessing

        INC Tick_Skipcount         ; Count the Nb of tick the Stream Read is skipped
		MOV Tick_Delay_IRQ,1       ; Wait one more tick
        JMP @@NoPlay
		
; Start the Stream Tick Processing
Do_StreamProcessing:

        MOV Stream_Processing,1    ; Not call again if already processing
        CALL [OPL_IRQ_Player]      ; Proceed the Stream plus replay for the current Tick

        CMP CS:Stop_Output,1       ; check if we need to stop (Security)
		JE Stop_Stream_IRQ       

		MOV AX,Tick_Delay
        CMP AX,Tick_Skipcount
		JA Do_StreamProcessingOk   ; Continue if Skipped < Delay

;PUSH AX
;MOV AX,Tick_Delay
;Call WriteWordH
;WriteCh ','
;MOV AX,Tick_Skipcount
;Call WriteWordH
;POP AX	
		
; Skipped > Wanted	   
		SUB Tick_Skipcount,AX      ; Skip Count reduced  (To avoid having Skip Delay <0)
		
		JMP Do_StreamProcessing   ; Loop Stream Processing until there is enaugh delay

; Skipped < Wanted -> Stream Processing End
Do_StreamProcessingOk:
        SUB AX,Tick_Skipcount     ; Tick_Delay needed - Skipped
		MOV Tick_Skipcount,0
		MOV Tick_Delay_IRQ,AX
		MOV Tick_Delay,0          ; Tick Delay = 0
		
		MOV Stream_Processing,0
		
; If the function above is too long, the Counter continue.		
		
; ** After playing compute the Channels Frequencies if changed (For the Display)
        TEST OtherMUS_Out,M_OPL2   ; Test OPL2
		JNZ Do_Compute_OPLFreq
        TEST OtherMUS_Out,M_OPL3   ; Test OPL2
		JZ @@NoPlay
		
Do_Compute_OPLFreq:
		PUSH BX
		PUSH CX
		PUSH DX
		
		MOV BX,0
Loop_ComputeAdlFreq:

        CMP OPLFreqCh[BX],0
		JE CompAdlFNC
		MOV OPLFreqCh[BX],0

        mov	cl,OPLA0Sav[BX]
		mov	ch,OPLB0Sav[BX]
		and	ch,3		  ; mask to get high frequency
		CMP CX,FreqStart
		JAE OPLFreqInRange
		MOV CX,FreqStart
OPLFreqInRange:		
		SUB	CX,FreqStart  ; Valure defined in DRO Player
		
		mov	al,OPLB0Sav[BX]
		shr	al,1
		shr	al,1
		and	ax,7		 ; mask to get octave
		mov	dx,FreqRange ; Valure defined in DRO Player
		mul	dx
		add	ax,cx        ; Frequency = Adl Freq + Octave*Freq Range
; AX From 156h to ABEh	

        MOV CX,0ABEh     ; Freq to Period that can be displayed in the bar.
        SUB CX,AX        
        SHL CX,1
        SUB CX,64*10
		JG OPL_ReduceDisplayPitchOk
		MOV CX,0
OPL_ReduceDisplayPitchOk:		
;*      SUB CX,1000
	
		SHL BX,1
        MOV CH_Per_part[BX],CX
		SHR BX,1
		
CompAdlFNC:
        INC BX
		CMP BX,17
		JNE Loop_ComputeAdlFreq

        POP DX		
		POP CX
		POP BX

@@NoPlay:

; Generate the 50Hz Tick for the Display
        MOV AX,Periode_timer
		ADD Cnt50,AX
		CMP Cnt50,Period50Hz
@@50HzTickLoop:
		JB @@No50Tick
		SUB Cnt50,Period50Hz
        CALL Chrono_Fading
		DS_TP
		MOV Tick_50Hz,1
		DS_ASM
		CMP Cnt50,Period50Hz
		JAE @@50HzTickLoop   ; If the timer speed is <50Hz
@@No50Tick:

@@OPLIRQEnd:		
		POP DS
        POP AX		
        IRET                       ; Fin de l'IRQ

OPLStreamIRQ Endp

; AH: Register Nb with 0 as first channel
; Output: Carry=Found
; AH, Channel number
;00h,01h,02h,08h,09h,0Ah,10h,11h,12h
GetOPLChann Proc Near
		CMP AH,2
		JA @CRMNotFound1 
		CLC    ; channels 0-2
		RET
@CRMNotFound1:		
		SUB AH,8
		CMP AH,2
		JA @CRMNotFound2
		ADD AH,3		
		CLC   ; channels 3-5
		RET
@CRMNotFound2:
		SUB AH,8
		CMP AH,2
		JA @CRMNotFound3
		ADD AH,6		
		CLC   ; channels 3-5
		RET
@CRMNotFound3:
		STC
		RET
GetOPLChann Endp

;**********************************************************
;* Send the command to the OPL and store the values sent. *
;* Input: AH: Register, AL: Value                         *
;*        OPLPortOffset : 0 First Set, 2 2nd Set             *
;**********************************************************

Write_OPLStream Proc Near
       PUSH AX
       PUSH BX

       CMP AH,43h
       JB WO_DoWrite ; No info to Read
       CMP AH,0C8h
       JA WO_DoWrite ; No info to Read
	   
       CMP AH,55h    ; 43h to 55h : Volume
       JA NoRegVolume
; *** Envelope Volume register

       SUB AH,43h
       CALL GetOPLChann ; Get the Channel number
       JNC WO_VolOk
	   JMP WO_DoWrite
WO_VolOk:
	   XOR BX,BX
	   MOV BL,AH
       CMP OPLPortOffset,0
       JE WO_Vol_OPL2
       ADD BX,9 ; Channels 10 to 18
WO_Vol_OPL2:	   
	   AND AL,3Fh ; Extract the volume
	   MOV AH,64  ; Complement to 64  ; Vol 0 converted to 1
	   SUB AH,AL
	   MOV Ch_Part_Vol[BX],AH
	   MOV Ch_Volume[BX],AH	   
 	   OR  Ch_Control[BX],M_VolChanged  ; Force the Display

       JMP WO_DoWrite
NoRegVolume:

       CMP AH,0A0h
	   JB WO_NoA0
	   CMP AH,0A8h
	   JA WO_NoA0

; ** Frequency Register

	   SUB AH,0A0h
	   XOR BX,BX
	   MOV BL,AH
       CMP OPLPortOffset,0
       JE WO_A0_OPL2
       ADD BX,9 ; Channels 10 to 18
WO_A0_OPL2:
	   MOV OPLA0Sav[BX],AL
	   MOV OPLFreqCh[BX],1

       JMP WO_DoWrite
WO_NoA0:	   
	   
       CMP AH,0B0h
	   JB WO_NoBx
	   CMP AH,0B8h
	   JA WO_NoBx
; ** Key on / Freq Register

	   SUB AH,0B0h
	   XOR BX,BX
	   MOV BL,AH
       CMP OPLPortOffset,0
       JE WO_Key_OPL2
       ADD BX,9 ; Channels 10 to 18
WO_Key_OPL2:
	   MOV AH,AL
	   AND AH,1Fh
	   MOV OPLB0Sav[BX],AL   ; Save Octave and High part of Freq.
	   MOV OPLFreqCh[BX],1
       AND AL,20h ; Key Bit
	   JZ WO_KeyOff
       OR Ch_Control[BX],M_VolChanged        ; Key On
       AND Ch_Control[BX],Not (CM_Stopped+CM_Disabled)
	   JMP WO_DoWrite	   
WO_KeyOff:
       OR Ch_Control[BX],CM_Stopped	         ; Key Off
	   JMP WO_DoWrite
WO_NoBx:
; If OPL3, check if it is the panning/Feedback register
       CMP AH,0C0h
	   JB WO_NoCx
	   CMP AH,0C8h
	   JA WO_NoCx

	   SUB AH,0C0h
	   XOR BX,BX
	   MOV BL,AH
       CMP OPLPortOffset,0	   
       JE WO_Pann_OPL2
       ADD BX,9 ; Channels 10 to 18
WO_Pann_OPL2:

       SHR AL,1 ; Extract the panning info (Bit 5:Right 4:Left)
       SHR AL,1
       SHR AL,1
       SHR AL,1	
       AND AL,3

       MOV AH,40h
	   OR AL,AL
	   JZ WO_DoWrite     ; 0: Don't save
	   MOV AH,80h ; Right
       DEC AL
       JZ WO_SavePanning
       XOR AH,AH  ; Left
	   DEC AL
       JZ WO_SavePanning
	   MOV AH,40h ; Center
WO_SavePanning:	   
       MOV CH_Panning[BX],AH
WO_NoCx:

WO_DoWrite:

        POP BX
		POP AX
        CALL WriteOPL
        RET
Write_OPLStream Endp

;**********************************************************
;* Send the command to the CMS and store the values sent. *
;* Input: AH: Register, AL: Value                         *
;*        OPLPortOffset : 0 First Set, 2 2nd Set             *
;**********************************************************
Write_CMSStream Proc Near

;PUSH AX
;PUSH AX
;Writech'-'
;Writech'r'
;MOV AL,AH
;Call WriteByteH
;WriteCh 'v'
;POP AX
;Call WriteByteH
;POP AX

       PUSH AX
	   PUSH CX
	   
; Save the CMS Registgers values and Add 2nd Chip index
	   XOR BX,BX
       MOV BL,AH  ; Register index in BX
       CMP CMSPortOffset,0
       JE CMSChip0
;       MOV CH,CMSRegSav1[BX]
;	   MOV CMSRegSav1[BX],AL
       ADD BL,6 ; Channels 7 to 12
;	   JMP CMSSaveRegEnd
CMSChip0:
;       MOV CH,CMSRegSav0[BX]
;	   MOV CMSRegSav0[BX],AL
;CMSSaveRegEnd:


;Detect Volume Write	   
       CMP AH,5 ; Reg 0 to 5 : Volume
	   JA CMSStream_NoVol
	   MOV AH,AL
	   AND AL,0Fh
	   MOV CL,4
	   SHR AH,CL

; Detect Stereo Position	   
       MOV CL,40h ; Mono
       CMP AH,AL
       JE CMSStream_Panning
       SHL CL,1
       CMP AH,AL
       JB CMSStream_Panning
       XOR CL,CL
CMSStream_Panning:
       MOV CH_Panning[BX],CL
	   
	   ADD AL,AH
	   SHL AL,1
	   SHL AL,1
       CMP AL,64
       JBE VolOkCMS
       MOV AL,64 ; Adjust the Display volume to Max 64
VolOkCMS:
	   MOV Ch_Part_Vol[BX],AL
	   MOV Ch_Volume[BX],AL             ; Save the Volume
 	   OR  Ch_Control[BX],M_VolChanged  ; Force the Display
	   
	   CMP AL,0
	   JNE CMSVolNotNul
       OR  Ch_Control[BX],CM_Stopped
	   JMP CMSStream_Out
	   
CMSVolNotNul:		
       AND Ch_Control[BX],Not (CM_Stopped+CM_Disabled) ; Enable the channel Display Ch_Control if Volume>0
	   JMP CMSStream_Out
	   
CMSStream_NoVol:	   

       CMP AH,08h
	   JB CMSStream_Out
       CMP AH,0Dh ; Reg 08 to 0D : Frequency
	   JA CMSStream_NoFreq	   
	   SUB BX,08h

       SHL BX,1
       MOV DX,CH_Per_part[BX]
	   MOV DL,AL
	   MOV CH_Per_part[BX],DX
	   SHR BX,1

	   JMP CMSStream_Out
	   
CMSStream_NoFreq:

       CMP AH,10h
	   JB CMSStream_Out
       CMP AH,12h ; Reg 10h to 12h : Octave
	   JA CMSStream_NoOctave	   
	   SUB BL,010h

       CMP BL,6
	   JB NotAdjustCMSCh
	   SUB BL,3
NotAdjustCMSCh:	   

       SHL BX,1
	   SHL BX,1   ; Update 2 Octave per register
	   
       MOV DX,CH_Per_part[BX] ; 4 Low Bit : channel+0
	   MOV DH,AL
	   AND DH,0Fh
	   MOV CH_Per_part[BX],DX
	   
	   INC BX
	   INC BX
       MOV DX,CH_Per_part[BX] ; 4 High Bit : channel+1
	   MOV DH,AL
	   SHR DH,1
	   SHR DH,1
	   SHR DH,1
	   SHR DH,1	   
	   MOV CH_Per_part[BX],DX
	   
	   SHR BX,1
	   SHR BX,1
	   JMP CMSStream_Out

CMSStream_NoOctave:

CMSStream_Out:
       POP CX
	   POP AX

;	AH : Register / AL : Data
       CALL CMS_Out
       RET
Write_CMSStream Endp

TDY_PrevChan DB 0

Write_TDYStream Proc Near
        PUSH CX

        XOR BX,BX
		MOV BL,AL
		AND BL,01100000b
		MOV CL,5
		SHR BL,CL   ; BL <- Channel Nb

		MOV AH,AL
        TEST AL,10000000b ; Bit 7=0 > High Frequency
		JZ TDYS_SetHighDiv
        TEST AL,00010000b ; Bit 7=1 and 4=0 > Low Frequency
		JZ TDYS_SetLowDiv

; TDY Volume
		MOV CL,16
		AND AH,00001111b
        SUB CL,AH   ; AH <- Tandy Attenuation
		SHL CL,1
 	    OR  Ch_Control[BX],M_VolChanged  ; Force the Display
        AND Ch_Control[BX],Not CM_Stopped

;Volume 0 ?		
		CMP CL,4  ; Vol=4 -> 0
		JA  TDYS_VolNot0
        OR Ch_Control[BX],CM_Stopped
		MOV CL,0
TDYS_VolNot0:

	    MOV Ch_Part_Vol[BX],CL
	    MOV Ch_Volume[BX],CL	   

; Force the Volume to 0 if Disabled.
        TEST Ch_Control[BX],CM_Disabled
		JZ Write_TDYStream_Out

		OR AL,00001111b
		JMP Write_TDYStream_Out

TDYS_SetLowDiv:
; TDY Tone Divisor, Low	
		MOV TDY_PrevChan,BL   ; Save the Previous Low Div Channel Number
        AND AH,00001111b
		SHL BX,1
        MOV b CH_Per_part[BX],AH ; Save the 6 Lower Bit
		SHR BX,1

; Different if Noise channel

		JMP Write_TDYStream_Out

TDYS_SetHighDiv:
; TDY Tone Divisor High

        MOV BL,TDY_PrevChan
		
		PUSH DX

		AND AH,00111111b
		MOV CL,4
        XOR DH,DH
		MOV DL,AH
		SHL DX,CL    ; Place the 6 Upper Bit in DX
		SHL BX,1
		MOV AH,b CH_Per_part[BX]
		OR DL,AH     ; Add the 4 Lower bit previously saved
		MOV CX,DX
		SHL DX,1
		ADD DX,CX
		SHL DX,1	 ; Save TDY Divisor*6
		MOV CH_Per_part[BX],DX
		SHR BX,1
	    POP DX
		
Write_TDYStream_Out:

        CALL TDY_Out

Write_TDYStream_End:
        POP CX
        RET
Write_TDYStream Endp

Write_PSGStream Proc Near
        PUSH CX

        CALL PSG_Out

        POP CX
        RET
Write_PSGStream Endp

; Init_StreamPtr : Update the Address of the current stream data (64K Segments)

Init_StreamPtr Proc Near
		MOV AX,OPLStreamSeg
		MOV SI,OPLStreamOffs
		
        CMP SI,2000h  ; Move the Pointer for files >64Kb
        JB @@InitNoSegMove
        ADD AX,200h
		MOV OPLStreamSeg,AX
        SUB SI,2000h
        SUB w OtherMUS_DataEnd,2000h
		SBB w [OtherMUS_DataEnd+2],0

@@InitNoSegMove:
        MOV ES,AX
		RET
Init_StreamPtr Endp	

;       ***  VGM_Play *** 
; Stream in the VGM format
;
; Input AX:Tick_Delay
;       DS=CS
;
; Supported Commands:
; 0x50  dd  PSG (SN76489/SN76496) write value dd  
; 0x5E  aa dd  YMF262 port 0, write value dd to register aa
; 0x5F  aa dd  YMF262 port 1, write value dd to register aa  
; 0x5A  aa dd  YM3812, write value dd to register aa
; 0xC8  aa dd  SAA1099, write the dd value to the register aa
If UseVGM Eq Yes
VGM_Play Proc Near

        PUSH ES
        PUSH SI
		PUSH BX
		PUSH DX

        CALL Init_StreamPtr ; Init the Stream Data Pointer

VGMLoop:
        MOV AL,ES:[SI]               ; Read the Command
		INC SI

; Tandy/OPL Commands
		CMP AL,50h
		JE VGM_TDY
		MOV OPLPortOffset,0          ; First Set of register / OPL2
		CMP AL,5Eh
		JE VGM_OPL2_1 ; OPL3
		CMP AL,5Ah
		JE VGM_OPL2_1 ; OPL2
		CMP AL,5Fh
		JE VGM_OPL3_2 ; OPL3
        CMP AL,0BDh
        JE VGM_CMS
        CMP AL,0A0h
        JE VGM_PSG
; Check for Delay Commands		
; 0x61  nn nn  Wait n samples, n can range from 0 to 65535 (approx 1.49 seconds).
;              Longer pauses than this are represented by multiple wait commands.
        CMP AL,61h		
		JE VGM_Wait_n
; 0x62   wait 735 samples (60th of a second), a shortcut for 0x61 0xdf 0x02  
        CMP AL,62h		
		JE VGM_Wait_60
; 0x63   wait 882 samples (50th of a second), a shortcut for 0x61 0x72 0x03  
        CMP AL,63h		
		JE VGM_Wait_50
; 0x7n       : wait n+1 samples, n can range from 0 to 15.
        MOV AH,AL
        AND AH,0F0h		
		CMP AH,70h
        JNE @@VGM_No7n
;Writech '7'
        XOR AH,AH
		AND AL,0Fh
		ADD Tick_Delay_Sub,AX
		
		CMP Tick_Delay_Sub,147
		JB @@VGM_Continue
        SUB Tick_Delay_Sub,147
        INC Tick_Delay
		JMP @@VGM_End	
@@VGM_No7n:		
        CMP AL,66h		
		JE @@VGM_Stop        ; 0x66        : File End


; Handle some "Not Supported" commands
        CMP AL,4Fh
		JE VGM1Op
        CMP AL,30h
        JB VGM_NotSupported
		CMP AL,3Fh
		JA VGM_Not1Op
VGM1Op:
		INC SI               ; 30h-3Fh: One Operand reserved commands
		JMP @@VGM_Continue
VGM_Not1Op:
        CMP AL,61h
		JA VGM_Not2Op
		INC SI               ; Two Operand commands
		INC SI		
		JMP @@VGM_Continue		
VGM_Not2Op:

; If a code is not supported, display it
;PUSH AX
;CALL WriteByteH
;WriteCh '-'
;POP AX

VGM_NotSupported:
        MOV Erreur_Modm,Err_CMD_NotSupported ; Set Error Code
        JMP @@VGM_Stop              ; Command not supported -> End
VGM_Wait_n:
        MOV AX,ES:[SI] ; Read the Delay
		INC SI
		INC SI

		XOR DX,DX
		MOV BX,147  ; 44100/300
		DIV BX

; If the Delay is below the Timer Speed, increment a Sub Delay variable
        ADD Tick_Delay_Sub,DX
		CMP Tick_Delay_Sub,147
		JB @@VGM_NoINC_OPLDelay
		SUB Tick_Delay_Sub,147
;Writech'i'		
		INC AX
@@VGM_NoINC_OPLDelay:

		ADD Tick_Delay,AX
; Delay not sufficient > Continue to read the Stream
        CMP AX,0
		JE @@VGM_Continue
		
		JMP @@VGM_End
VGM_Wait_60:
		ADD Tick_Delay,5 ; 1/60th
		JMP @@VGM_End
VGM_Wait_50:
		ADD Tick_Delay,6 ; 1/50th
		JMP @@VGM_End
		
VGM_TDY:
        MOV AL,ES:[SI]
		INC SI
		CALL Write_TDYStream
        JMP @@VGM_Continue
		
VGM_OPL3_2:
        MOV OPLPortOffset,2          ; 2nd Set of OPL3 registers
VGM_OPL2_1:
        MOV AH,ES:[SI]
		INC SI
        MOV AL,ES:[SI]
		INC SI
		CALL Write_OPLStream      ; Write to OPL2/3
        JMP @@VGM_Continue

VGM_CMS:
        MOV AH,ES:[SI]            ; Register Adress

        MOV CMSPortOffset,0
		TEST AH,80h               ; Test the Index (Chip Nb)
		JZ VGM_CMS_FirstChip
        MOV CMSPortOffset,2       ; Second Chip		
VGM_CMS_FirstChip:		
        AND AH,01111111b          ; Clean the Index Bit
		INC SI
        MOV AL,ES:[SI]            ; CMS Data
		INC SI
		CALL Write_CMSStream      ; Write to the CMS
        JMP @@VGM_Continue

VGM_PSG:
        MOV AH,ES:[SI]            ; Register Adress

        MOV PSG_PortOffset,0
		TEST AH,80h               ; Test the Index (Chip Nb)
		JZ VGM_PSG_FirstChip
        MOV PSG_PortOffset,2       ; Second Chip		
VGM_PSG_FirstChip:
        AND AH,01111111b          ; Clean the Index Bit
		INC SI
        MOV AL,ES:[SI]            ; PSG Data
		INC SI
		CALL Write_PSGStream      ; Write to the PSG
        JMP @@VGM_Continue

@@VGM_Continue:
		
; Check if it is the End of the Music
        CMP w [OtherMUS_DataEnd+2],0
		JNE @@NotVGM_Stop
		CMP SI,w OtherMUS_DataEnd
		JAE @@VGM_Stop
@@NotVGM_Stop:		
; Not the End -> Loop
		JMP VGMLoop

@@VGM_End:

;Adjust the Offset
		MOV OPLStreamOffs,SI

		POP DX
		POP BX
        POP SI
		POP ES
        RET

@@VGM_Stop:

        MOV Stop_Output,1
		POP DX
		POP BX
        POP SI
		POP ES
        RET
VGM_Play Endp
EndIf

;       *** IMF_Plax *** 
; Stream in the IMF format (OPL2)
;
; Input AX:Tick_Delay
;       DS=CS
If UseIMF Eq Yes
IMF_Play Proc Near

        PUSH ES
        PUSH SI

        CALL Init_StreamPtr ; Init the Stream Data Pointer

IMFLoop:
		 
		MOV AX,ES:[SI]            ; Read the Registry/Value
		XCHG AH,AL
		CALL Write_OPLStream
; Read the Delay
		MOV AX,ES:[SI+2]
		ADD SI,4
; Check if it is the End of the Music
        CMP w [OtherMUS_DataEnd+2],0
		JNE @@NotIMFEnd
		CMP SI,w OtherMUS_DataEnd
		JAE @@IMFEnd
@@NotIMFEnd:		
; Check if the Delay is 0		 
		OR AX,AX
		JZ IMFLoop

;Adjust the Counters and Offset
		MOV Tick_Delay,AX
		MOV OPLStreamOffs,SI

        POP SI
		POP ES
        RET

@@IMFEnd:
        MOV Stop_Output,1
        POP SI
		POP ES
        RET
IMF_Play Endp
EndIf

;       *** RAW_Play *** 

;   format:   [0]=db     'RAWADATA'                 ... file identifier
;             [8]=dw     clock                      ... clock (int8) speed
;            [10]=dw     data_size dup (data)       ... adlib data
;            [..]=dw     0ffffh                     ... end of file
;   data: parameter, command.   command==0: data==n ... wait n times.
;                               command==2: data==0 ... set speed (next word)
;                               command==2: data==1 ... set OPL3 port A default
;                               command==2: data==2 ... set OPL3 port B default
If UseRAW Eq Yes
RAW_Play Proc Near

        PUSH ES
        PUSH SI

        CALL Init_StreamPtr ; Init the Stream Data Pointer
		
; Check if it is the End of the Music
        CMP w [OtherMUS_DataEnd+2],0
		JNE @@NoRawEnd
		CMP SI,w OtherMUS_DataEnd     ; Stop the music (Security if no 0FFFFh)
		JAE @@End
@@NoRAWEnd:

RAWLoop:
		 
		MOV AX,ES:[SI]            ; Read the Registry/Value
		ADD SI,2

        TEST AH,AH                ; AH=0 > AL is the Delay
		JNZ @@NotDelay
        XOR AH,AH
		JMP @@QuitLoop
@@NotDelay:                       
        CMP AH,2
		JE @@ProcessCmd
		CMP AX,0FFFFh             ; AX=-1 > End
		JE @@End
		JMP @@SendOPLCmd
@@ProcessCmd:		
		OR AL,AL                  ; AH=2 > Process Command
		JNE @@NoTimerChange
		MOV AX,ES:[SI]            ; 0: change the Timer Value
		ADD SI,2
		MOV RAWSpeed,AX
		MOV Periode_timer,AX		
        CALL Set_Timer0_Period    ; Change the Timer Speed
		JMP RAWLoop
@@NoTimerChange:
        CMP AL,2
		JA RAWLoop                ; >2 Loop
        XOR AH,AH
        CMP AL,1 
        JE @@RAWOPL2
        MOV AH,2
        MOV Ch_Number,18          ; OPL3 > 18 Channels (For Display)		
@@RAWOPL2:
		MOV OPLPortOffset,AH         ; 0 or 2 (Base @ Delta)
        JMP RAWLoop               ; Not supported Command
@@SendOPLCmd:
; ** Send the command to the OPL **
;		MOV OPL_Cmd,AX
		CALL Write_OPLStream
; Check if it is the End of the Music
@@NoOPLCommand:
        JMP RawLoop

;Adjust the Counters and Offset
@@QuitLoop:
		MOV Tick_Delay,AX
		MOV OPLStreamOffs,SI

        POP SI
		POP ES
        RET

@@End:
        MOV Stop_Output,1
        POP SI
		POP ES
        RET
RAW_Play Endp
EndIf

;       *** DRO_Play ***
If UseDRO Eq Yes
DRO_Play Proc Near
        PUSH ES
        PUSH SI
		PUSH BX

        CALL Init_StreamPtr ; Init the Stream Data Pointer

DROLoop:
		 
		MOV AX,ES:[SI]            ; Read the Registry/Value
		ADD SI,2                  
		XCHG AH,AL                ; AH Cmd/Register Offset, AL Value
; * Check if it is a Delay *		
		CMP AH,DRODelay257
		JNE @@NotDRODel1
		XOR AH,AH
		INC AX
;Writech's'		
		JMP @@DROLoopEnd
@@NotDRODel1:
		CMP AH,DRODelay257
		JNE @@NotDRODel2
		XOR AH,AH
		INC AL
		XCHG AH,AL   ; Delay = Value*256
		JMP @@DROLoopEnd
@@NotDRODel2:		

; * Set the Register Set Port *
        MOV OPLPortOffset,0  ; First Set of register / OPL2
		TEST AH,10000000b
		JZ @@DROUseSet1
        MOV OPLPortOffset,2  ; 2nd Set of OPL3 registers
@@DROUseSet1:		
; * Get the Register number *
        PUSH ES
        AND AH,01111111b
		MOV BX,DRORegsOffs
        ADD BL,AH
        MOV ES,DRORegsSeg
		MOV AH,ES:[BX]
		POP ES
; * Send the Command *

;		MOV OPL_Cmd,AX
		CALL Write_OPLStream

; Check if it is the End of the Music
        CMP w [OtherMUS_DataEnd+2],0
		JNE DROLoop
		CMP SI,w OtherMUS_DataEnd
		JAE @@DROEnd
		
		JMP DROLoop

@@DROLoopEnd: ; AX Contains the Delay

;Adjust the Counters and Offset
		MOV Tick_Delay,AX
		MOV OPLStreamOffs,SI

        POP BX
		POP SI
		POP ES
        RET

@@DROEnd:
        MOV Stop_Output,1
		POP BX
        POP SI
		POP ES
        RET
DRO_Play Endp
EndIf