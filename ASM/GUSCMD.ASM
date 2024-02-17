;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷ GUSCMD.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷    º
;            º                                                   º
;            º            --==ðð Mod Master  XT ðð==--           º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteur   Freddy Vételé et Joshua C. Jensen)     º
;            º                                                   º
;            º   DerniŠre modificationúúúúúúúúú 01/01/1995       º
;            º   1/7/2019 : Modification for XT computers        º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


; UltraSound Ports

StatusPort      Equ 6h
TimerCtrlPort   Equ 8h
TimerDataPort   Equ 9h
MidiCtrlPort    Equ 100h
MidiDataPort    Equ 101h
ActiveVoicePort Equ 102h
CommandPort     Equ 103h
DataLowPort     Equ 104h
DataHighPort    Equ 105h
DRAMIOPort      Equ 107h

; UltraSound Commands

WriteVoiceMode  Equ 00h
SetVoiceFreq    Equ 01h         ; Value=Freq/Divisor
LoopStartLo     Equ 02h
LoopStartHi     Equ 03h
SampleEndLo     Equ 04h
SampleEndHi     Equ 05h
VolRampRate     Equ 06h
VolRampStart    Equ 07h
VolRampEnd      Equ 08h
SetVolume       Equ 09h
SampleStartLo   Equ 0Ah
SampleStartHi   Equ 0Bh
VoiceBalance    Equ 0Ch
VolumeCtrl      Equ 0Dh
VoicesActive    Equ 0Eh
DMACtrl         Equ 41h
DRAMAddrLo      Equ 43h
DRAMAddrHi      Equ 44h
TimerCtrl       Equ 45h
TimerCount1     Equ 46h
TimerCount2     Equ 47h
SampleFreq      Equ 48h
SampleCtrl      Equ 49h
Initialize      Equ 4Ch
Read            Equ 80h
ReadVolume      Equ Read+SetVolume      ; 89h
VoicePosLo      Equ Read+SampleStartLo  ; 8Ah
VoicePosHi      Equ Read+SampleStartHi  ; 8Bh
ReadVolCtrl     Equ Read+VolumeCtrl     ; 8Dh
IRQStatus       Equ 8Fh

; Divisors

GUS_FDiv DW 44100, 41160, 38587, 36317, 34300, 32494, 30870, 29400, 28063, 26843
         DW 25725, 24696, 23746, 22866, 22050, 21289, 20580, 19916, 19293

; Interwave Panning Table (64 values)
GUSPan dw 00FD0h, 00F70h, 00F20h, 00EC0h, 00E70h, 00E10h, 00DC0h, 00D70h
       dw 00D20h, 00CD0h, 00C70h, 00C30h, 00BE0h, 00B90h, 00B40h, 00AF0h
       dw 00AB0h, 00A60h, 00A20h, 009D0h, 00990h, 00940h, 00900h, 008C0h
       dw 00870h, 00830h, 007F0h, 007B0h, 00770h, 00730h, 006F0h, 006B0h
       dw 00670h, 00640h, 00600h, 005C0h, 00580h, 00550h, 00510h, 004D0h
       dw 004A0h, 00460h, 00430h, 003F0h, 003C0h, 00380h, 00350h, 00320h
       dw 002E0h, 002B0h, 00280h, 00250h, 00210h, 001E0h, 001B0h, 00180h
       dw 00150h, 00120h, 000F0h, 000C0h, 00090h, 00060h, 00030h, 00000h,0

; Number of voices to use

UInit_Play Proc Near

	   MOV Real_Frequency,44100

       CMP GUS_InterWave,1   ; AMD Interwave is always 44KHz
	   JE U_Use44k           ; Interwave mode is configured in GUSUNIT.PAS
	   
       MOV BL,Ch_Number
	   CMP BL,14
       JBE U_Use44k
       XOR BH,BH
       SUB BL,14
	   SHL BX,1
	   MOV AX,GUS_FDiv[BX]
	   MOV Real_Frequency,AX
U_Use44k:
       RET
UInit_Play Endp
  
; Gravis UltraSound Update : Send the command to the GUS.

If UseGUS eq Yes

ALIGN 2
GUS_Channel DB 0
MODE_GUS DB 0

GUS_UpdateOutput Proc Near
        MOV GUS_Channel,-1
        MOV CL,Ch_Number
        XOR CH,CH
        XOR BX,BX
Commander_GUS:
        PUSH CX
        PUSH BX
        CMP M_CH_Type[BX],1
        JE  Voie_Digit_GUS
        JMP Boucler_GUS             ;Si voie Adlib ou non active => Fin
Voie_Digit_GUS:
        MOV Voie_Reelle,BX          ;Init les voies r‚elles.

        INC GUS_Channel             ;Incrementer la voie Gravis.
        MOV AL,GUS_Channel
        CALL GUS_SetChannel         ;Set the channel Number.

        MOV BX,Voie_Reelle
        TEST Ch_Control[BX],CM_KeyOff     ;KeyOff ?
        JZ GUS_Pas_KeyOff
        AND Ch_Control[BX],Not CM_KeyOff  ;Disable the KeyOff
        OR Ch_Control[BX],CM_Stopped      ;KeyOff > Disable the channel
        CALL GUS_MuteChannel
        JMP Boucler_GUS                   ;KeyOff =>Fin
GUS_Pas_KeyOff:


        MOV BX,Voie_Reelle
        TEST Ch_Control[BX],CM_Disabled
        JZ Pas_stop_GUS_Channel
        JMP Boucler_GUS             ;Si voie stopp‚e =>Fin
Pas_stop_GUS_Channel:

        TEST GUS_Controle[BX],M_ChSample     ;Changer le sample ?
        JZ Pas_Start_Sample_GUS
        AND GUS_Controle[BX],Not M_ChSample  ;Efface le Bit
        OR GUS_Controle[BX],M_ChVolume       ;Modifier le volume !

        CALL GUS_Start_Sample

Pas_Start_Sample_GUS:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChPeriode    ;Changer la periode ?
        JZ Pas_Set_Period_GUS
        AND GUS_Controle[BX],Not M_ChPeriode ;Efface le Bit

        CALL GUS_Set_Period

Pas_Set_Period_GUS:

        MOV BX,Voie_Reelle                   
        TEST GUS_Controle[BX],M_ChVolume     ;Changer le volume ?
        JZ Pas_Set_Ch_Volume_GUS
        AND GUS_Controle[BX],Not M_ChVolume  ;Efface le Bit

        XOR BH,BH
        MOV BL,Ch_Final_Vol[BX]      ;BX Volume
        XOR BH,BH
        CALL GUS_Vol_DoRamp          ;Ramp to the final volume

Pas_Set_Ch_Volume_GUS:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChPanning     ;Changer le Panning ?
        JZ Pas_Changer_Panning_GUS
        AND GUS_Controle[BX],Not M_ChPanning  ;Efface le Bit

        MOV BL,CH_Panning[BX]       ; BX 0 -> 80h               
        CALL U_SetBalance

Pas_Changer_Panning_GUS:
Boucler_GUS:
        POP BX
        INC BX                     ; Incr‚menter l'index des voies "r‚elles"
        POP CX                     ; Fin des commandes pour la voie
        LOOP Boucle_Commander_GUS  ; Boucler Ch_Number fois
        JMP Fin_Commander_GUS
Boucle_Commander_GUS:
        JMP Commander_GUS
Fin_Commander_GUS:
        RET
GUS_UpdateOutput Endp

Mute_GUS Proc Near
       MOV CL,0
       XOR CH,CH
Eff_Voies_GUS:                     ; Boucle de 0 to Ch_Number-1
       PUSH CX
       MOV AX,CX
                                   ; AX Numero de voie
       CALL GUS_SetChannel         ; Choix de la voie...
       XOR BX,BX                   ; BX <= Volume=0
       CALL U_SetVolume            ; *** Regler le volume ***
       POP CX
       INC CX
       CMP CL,Ch_Number
       JNE Eff_Voies_GUS
       RET
Mute_GUS Endp

EndIf

  
;GUSwrite: Write AL value into the BL GUS register. (Data high port)
; In: AL, GUS Register
;     BL, Value
; Destroy DX
GUSwrite Proc
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        OUT DX,AL       ; Select the bl register.
        ADD DX,2        ; Data High port
        MOV AL,BL
        OUT DX,AL       ; Write AL in register BL
        RET
GUSwrite Endp

;GUSwrite: Write AL value into the BL GUS register. (Data high port)
; In: AL, GUS Register
;     CX, Value
; Destroy DX
GUSwriteW Proc
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        OUT DX,AL       ; Select the bl register.
        INC DX          ; Data Low port
        MOV AX,CX
        OUT DX,AX       ; Write AL in register BL
        RET
GUSwriteW Endp

; AL - Channel Number
; Destroy DX 
; Warning: Must not change CX
GUS_SetChannel Proc Near
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,ActiveVoicePort
        OUT  DX,AL
        RET
GUS_SetChannel Endp

UDelay Proc    Near
        PUSH DX
        PUSH AX
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        rept 7
        IN  AL,DX
        endm
        POP AX
        POP DX
        ret
UDelay  EndP

; In: BX:AX  - Number
; Out: AX = BX:AX SHR 7
; Destroys BX
RShift  Proc    Near
        mov cl,7
        shr ax,cl
		mov cl,9
        shl bx,cl
        or  ax,bx
        ret
RShift  EndP

; DX/AX - Frequency
; Destroys CX, DX
U_SetFreq Proc Near     ; Close enough for me...

; SHL DX-AX, 10
        PUSH BX
        MOV BX,AX
		MOV CL,6
		SHR BX,CL
        MOV CL,2
		SHL DL,CL
		MOV DH,DL
		XOR DL,DL
		ADD DX,BX
        POP BX		
		
		SHL AL,CL
		MOV AH,AL
		XOR AL,AL
		
		MOV  CX,Real_Frequency
        DIV  CX
        MOV VPart_decimale[BX],AH   ; Store the value for Debug display
        MOV VPart_decimale2[BX],AL
        PUSH AX
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,SetVoiceFreq
        OUT  DX,AL
        INC  DX              ; DataLowPort
        POP  AX
        OUT  DX,AX
        RET
U_SetFreq       EndP

; BL - Balance (0-80h)
; Destroys DX
U_SetBalance  Proc Near

;WriteCh 'p'
;MOV AX,BX
;CALL WriteWordH


       CMP GUS_InterWave,1
	   JE U_IWBalance
;Writech 'g'

If ModeXT eq yes
		SHR BX,1
		SHR BX,1
		SHR BX,1
Else
        SHR BX,3                  ;    0 -> 16
EndIf
        CMP BX,15
        JBE Pas_Ajuster_Panning
        MOV BX,15
Pas_Ajuster_Panning:              ; BX 0-> 15

; BL - Balance (0-f) 7 is middle

        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VoiceBalance
        OUT  DX,AL
        ADD  DX,2
        MOV  AX,BX
        OUT  DX,AL
        RET
		
U_IWBalance:

;Writech 'i'

        ; BX is from 0 to 128
        PUSH CX
		AND BX,0FEh  ; Clean the last bit to compute the Balance table Address (64 Values)


        MOV CX,CS:GusPan[BX]
;Writech 'r'
;MOV AX,BX
;CALL WriteWordH
;Writech ','
;MOV AX,CX
;CALL WriteWordH	
        MOV AL,0Ch ; Synth Offset Right
        CALL GUSWritew
        MOV AL,1Bh ; Synth Offset Right final
        CALL GUSWritew
        
		MOV AX,128
		SUB AX,BX
		MOV BX,AX
		
        MOV CX,CS:GusPan[BX]
;Writech 'l'
;MOV AX,BX
;CALL WriteWordH
;Writech ','
;MOV AX,CX
;CALL WriteWordH		
        MOV AL,13h ; Synth Offset Left
        CALL GUSWritew
        MOV AL,1Ch ; Synth Offset Left final
        CALL GUSWritew

        POP CX
		RET
U_SetBalance  EndP

; BX - Volume
; Destroys DX,SI

U_SetVolume     Proc    Far
        MOV SI,Offset GUSVOL
        SHL BX,1
        ADD SI,BX
        MOV BX,[SI]             ; Cherche le volume en log...
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        MOV AL,SetVolume
        OUT DX,AL
        INC DX              ; DataLowPort
        MOV AX,BX
        OUT DX,AX
        RET
endp    U_SetVolume

; BX - Volume target

GUS_Vol_DoRamp Proc Near
        PUSH CX

        MOV SI,Offset GUSVOL
        SHL BX,1
        ADD SI,BX
        MOV BX,[SI]             ; Cherche le volume en log...

        MOV  SI,BX
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VolumeCtrl
        OUT  DX,AL
        ADD  DL,2
        MOV  AL,3
        OUT  DX,AL
        SUB  DL,2
        MOV  AL,ReadVolume
        OUT  DX,AL
        INC  DX
        IN   AX,DX
        PUSH SI
        PUSH AX
		MOV CL,8
        SHR  AX,CL
        SHR  SI,CL
        CMP  AX,SI  ; SI Target; AX, Actual
        JZ   @@Done2
        JB   @@OK
;The starting volume must always be less than the ending volume.		
        XCHG SI,AX
@@OK:
        PUSH AX
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VolRampStart
        OUT  DX,AL
        ADD  DX,2
        POP  AX
        OUT  DX,AL
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VolRampEnd
        OUT  DX,AL
        ADD  DX,2
        MOV  AX,SI
        OUT  DX,AL
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VolRampRate
        OUT  DX,AL
        ADD  DX,2
        MOV  AL,00111111b
        OUT  DX,AL
        MOV  BL,00000000b
        POP  AX
        POP  SI
        CMP  AX,SI
        JB   @@OK2
        OR   BL,01000000b
@@OK2:
        MOV  DX,CS:[GUS_BasePort]
        ADD  DX,CommandPort
        MOV  AL,VolumeCtrl 
        OUT  DX,AL
        ADD  DX,2
        MOV  AL,BL
        OUT  DX,AL
        JMP  @@Done

@@Done2:
        POP AX
        POP AX
@@Done:
        POP CX
        RET
GUS_Vol_DoRamp  Endp

; BX - Mode
;          bit 0: 0=voice on (along with bit 1)
;          bit 1: 0=voice on (along with bit 0)
;          bit 2: 0=8 bit data, 1=16 bit data
;          bit 3: 0=No loop, 1=Loop
;          bit 4: 0=Go forward, 1=Go backward
U_SetLoopMode   Proc    Far
        MOV     DX,CS:[GUS_BasePort]
        ADD     DX,CommandPort
        MOV     AL,80h
        ADD     DX,2            ; DataHighPort
        IN      AL,DX

        MOV     BH,AL
        SUB     DX,2            ; CommandPort
        XOR     AL,AL
        OUT     DX,AL
        ADD     DX,2            ; DataHighPort
        AND     bh,0E7h
        OR      BH,BL
        MOV     AL,bh
        OUT     DX,AL
        RET
U_SetLoopMode   EndP

; Destroys DX, BX
U_StopVoice     Proc    Far
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        XOR AL,AL
        OUT DX,AL           ; Commande 0 => Write Voice Mode
        ADD DX,2            ; DataHighPort
        MOV AL,2            ; 00000010b =>Stopper la voie
        OUT DX,AL           ; Stop -> Mode de la voie
  
        CALL UDelay
        SUB DX,2            ; CommandPort
        XOR AL,AL
        OUT DX,AL
        ADD DX,2            ; DataHighPort
        MOV AL,2
        OUT DX,AL           ; Ecrire une deuxiŠme fois
        RET
U_StopVoice  EndP

_SampleBegin     dd 0       ; Start location in DRAM
                            ; (apparently 32-byte aligned) NOT!
_SampleLoopStart dd 0       ; Start location of loop
_SampleEnd       dd 0       ; End of sample

; BX - Mode
U_StartVoice    Proc    Near
        PUSH BX
; ***** Send sample begin
        MOV DX,CS:[GUS_BasePort]
        ADD DX,CommandPort
        MOV AL,SampleStartLo
        OUT DX,AL
        INC DX              ; DataLowPort (3x4h)
        MOV AX,Word Ptr cs:[_SampleBegin]
        MOV BX,Word Ptr cs:[_SampleBegin+2]
        CALL RShift
        OUT DX,AX
        DEC DX                  ; CommandPort (3x3h)
        MOV AL,SampleStartHi
        OUT DX,AL
        INC DX                  ; DataLowPort (3x4h)
        MOV AX,Word Ptr CS:[_SampleBegin]
		MOV CL,9
        SHL AX,CL
        OUT     DX,AX
; ***** Send sample Loop start
        DEC DX                  ; CommandPort (3x3h)
        MOV AL,LoopStartLo
        OUT DX,AL               ; Select Register
        INC DX                  ; DataLowPort (3x4h)
        MOV AX,Word Ptr CS:[_SampleLoopStart]
        MOV BX,Word Ptr CS:[_SampleLoopStart+2]
        CALL RShift
        OUT DX,AX
        DEC DX                  ; CommandPort (3x3h)
        MOV AL,LoopStartHi
        OUT DX,AL
        INC DX                  ; DataLowPort (3x4h)
        MOV AX,Word Ptr CS:[_SampleLoopStart]
		MOV CL,9
        SHL AX,CL
        OUT DX,AX
; ***** Send sample end
        DEC DX                  ; CommandPort (3x3h)
        MOV AL,SampleEndLo
        OUT DX,AL
        INC DX                  ; DataLowPort (3x4h)
        MOV AX,Word Ptr CS:[_SampleEnd]
        MOV BX,Word Ptr CS:[_SampleEnd+2]
        CALL RShift
        OUT DX,AX
        DEC DX                  ; CommandPort (3x3h)
        MOV AL,SampleEndHi
        OUT DX,AL
        INC DX              ; DataLowPort 104h
        MOV AX,Word Ptr CS:[_SampleEnd]
		MOV CL,9
        SHL AX,CL
        OUT DX,AX
        DEC DX              ; CommandPort 103h
; ***** Play it!  (I hope)
        MOV AL,0
        OUT DX,AL
        POP AX              ; AL <- Mode
        ADD DX,2            ; DataHighPort 105h
        OUT DX,AL
        RET

endp    U_StartVoice

; AX - Mixer control
;  bit 0: 0=linein on, 1=linein off
;  bit 1: 0=OUTput on, 1=OUTput off
;  bit 2: 0=micin off, 1=micin on

U_ChangeInOUT   Proc    Far
        MOV     DX,CS:[GUS_BasePort]
        OUT     DX,AL
        RET
U_ChangeInOUT   EndP

GUS_Start_Sample Proc Near
DS_ASM
        TEST Ch_Control[BX],CM_Stopped ;Voie active ?
        JZ GUS_Sample_NonVIDE
		JMP GUS_Sample_VIDE
GUS_Sample_NonVIDE:

        MOV BL,CH_Smp_Pla[BX]  ;BL <-Sample
		
        SHL BX,1
		SHL BX,1
        LES DI,PtrSamples[BX]        ;Pointeur sur le sample

        MOV BX,Voie_Reelle
        SHL BX,1                     ;BX <- 2*Voie

        XOR AX,AX
		CMP W ES:SLen[DI+2],AX
		JNE  Do_ReadSampleValues     ; Size always > Start Offset
		CMP W ES:SLen[DI],AX
		JE  GUS_Sample_VIDE
	
        MOV CX,Ch_Mix_Offs[BX]    ; CX <- Start Offset
        CMP CX,W ES:SLen[DI]
        JB Do_ReadSampleValues
		MOV Ch_Mix_Offs[BX],AX    ; Offset Start > Size -> Offset Start=0
Do_ReadSampleValues:

		MOV AX,W ES:SAdresse_GUS[DI] ; Adresse du sample dans la GUS
		MOV DX,W ES:SAdresse_GUS[DI+2]
        
		PUSH AX                      ; Save Start Address
		PUSH DX
        ADD AX,CX                    ; Begining=Sample Offset+Start Offset
		ADC DX,0
        MOV W [_SampleBegin],AX      ; Sample Start Address
		MOV W [_SampleBegin+2],DX

        SHR BX,1
        MOV VPart_decimale[BX],AH    ; Store the value for Debug display
        MOV VPart_decimale2[BX],AL
		MOV VPart_entiere[BX],DL
		SHL BX,1
		
		MOV AX,W ES:SAdresse_GUS[DI]  ; Adresse du sample dans la GUS
		MOV DX,W ES:SAdresse_GUS[DI+2]
		
        ADD AX,W ES:SLen[DI]      ; Fin=Debut+Taille
		ADC DX,W ES:SLen[DI+2]
        MOV W [_SampleEnd],AX     ; Fin du sample        
		MOV W [_SampleEnd+2],DX   ; Fin du sample
		POP DX                    ; Restore Start Address
        POP AX

        ADD AX,W ES:SRep[DI]
		ADC DX,W ES:SRep[DI+2]
        MOV W [_SampleLoopStart],AX   ; Loop Start Offset
		MOV W [_SampleLoopStart+2],DX

                                 ; *** Mode de sortie du sample ***
        MOV AL,ES:SInfo[DI]      ; Lire les Infos du sample
        AND AL,00011100b
        MOV Mode_GUS,AL          ; Mode GUS<-Info AND 00011100b

        XOR BX,BX                ; Volume … z‚ro !!!
        CALL U_SetVolume         ; ( Pour la rampe )
        CALL U_StopVoice         ; Stopper la voie avant modifications

        XOR BX,BX
        MOV BL,Mode_GUS
        CALL U_StartVoice      ; Lancer le sample
        JMP Fin_GUS_Start_Sample
GUS_Sample_Vide:               ; Stopper la voie => Volume 0
        XOR BX,BX              ; BX Volume
        CALL GUS_Vol_DoRamp
Fin_GUS_Start_Sample:
        RET
GUS_Start_Sample Endp

GUS_Set_Period Proc Near

        SHL BX,1                             ; Pointeur Double Mot
		SHL BX,1
        MOV AX,Word Ptr [BX+GUS_Frequency]
        MOV DX,Word Ptr [BX+GUS_Frequency+2]
        SHR BX,1
		SHR BX,1
        CALL U_SetFreq
        RET
GUS_Set_Period EndP

; Ramp down the volume to 0
; The GUS Channel need to be selected first
GUS_MuteChannel PROC NEAR
        XOR BX,BX             ;BX Volume=0
        CALL GUS_Vol_DoRamp
        RET
GUS_MuteChannel ENDP
