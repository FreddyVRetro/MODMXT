;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º      ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ ADLIB.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷      º
;            º                                                   º
;            º            --==ğğ Mod Master SS ğğ==--            º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteurúúúúúúúúúúúúúúúúúúúúúúúú Freddy Vetele    º
;            º                                                   º
;            º   Start Date  14/08/1995                          º
;            º   Last Update 15/08/2022                          º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

;Sauvegarde des registres pour les voies

Old_KSL_TL_40 DB 9 DUP (0)   ;Niveau total des 9 Modulateurs.
Old_KSL_TL_43 DB 9 DUP (0)   ;Niveau total des 9 Porteuses.
Old_Key_B0    DB 9 DUP (0)   ;Key et valeurs de frequence des 9 Voies
Old_FB        DB 9 DUP (0)   ;Niveau de retroaction et type de synthese.

;Offset des modulateurs pour les 9 Voies (+3 pour les porteuses)

Offset_Op DB 00h,01h,02h,08h,09h,0Ah,10h,11h,12h
;            03h,04h,05h,0Bh,0Ch,0Dh,13h,14h,15h

;Registres Adlib

Reg_AM_VIB EQU 020h
Reg_KSL_TL EQU 040h   ;KSL et Niveau total.
Reg_AR_DR  EQU 060h   ;Vitesse d'attaque et Vitesse de d‚croissance.
Reg_SL_RR  EQU 080h   ;Niveau soutenu et vitesse de relachement.
Reg_WS     EQU 0E0h   ;Waveform Select.
Reg_FB_FM  EQU 0C0h   ;Feed Back et Type de modulation.

Reg_Key    EQU 0B0h

Offset_Modulateur DB 0

OPLPortOffset DB 0   ; 0 : Channels 0-9 2: Channels 10-17
OPLLPTPort DW 0      ; OPLLPT I/O Port
OPL_Delay1 DW 6      ; OPL2 6  OPL3 3
OPL_Delay2 DW 35     ; OPL2 35 OPL3 8-+


Set_OPL2Mode Proc Near
     MOV OPLPortOffset,2
	 MOV AX,0500h        ; Set in OPL2 Mode (OPL3 Mode configured by the Music player)
	 CALL WriteOPL
	 MOV OPLPortOffset,0	 
	 RET
Set_OPL2Mode Endp

Set_OPL3Mode Proc Near
     MOV OPLPortOffset,2
	 MOV AX,0501h        ; Set in OPL2 Mode (OPL3 Mode configured by the Music player)
	 CALL WriteOPL
	 RET
Set_OPL3Mode Endp

Clean_OPLRegs Proc Near
        PUSH CX
        MOV AX,02000h      ; Clean adlib registers from 20h to F5h
@@RADCleanAdlibLoop:
		CALL WriteOPL
		INC AH
		CMP AH,0F6h
		JNE @@RADCleanAdlibLoop
		POP CX
		RET
Clean_OPLRegs Endp

Clean_OPL3Regs Proc Near
        CALL Set_OPL3Mode

	    MOV AX,0400h         ; Clean OPL3 Reg 4
		CALL WriteOPL				
		CALL Clean_OPLRegs   ; Clean OPL3 Regs
        CALL Set_OPL2Mode
		
        RET
Clean_OPL3Regs Endp

Clean_OPL2Regs Proc Near
        CALL Set_OPL2Mode
        CALL Clean_OPLRegs
        RET	 
Clean_OPL2Regs Endp

; Init the Base Ports (OPL / OPLLPT), Delay and Set OPL2 Mode
; Output : OPL2 Mode
Init_OPL Proc Near

     CMP OPL_LPT_Model,0
	 JE Not_Init_OPLLPT

; Define the OPLLPT Port
	 MOV AX,LPT1_Port
	 CMP OPL_LPT_Nb,1
	 JE Save_OPLLPTPort
     MOV AX,LPT2_Port
Save_OPLLPTPort:
     MOV OPLLPTPort,AX
Not_Init_OPLLPT:

; Define the OPL2 or OPL3 Delay
     MOV OPL_Delay1,3
	 MOV OPL_Delay2,8
     CMP OPL_Model,2
	 JE @@InitOPL3
	 CMP OPL_LPT_Model,2
	 JE @@InitOPL3
     MOV OPL_Delay1,6
	 MOV OPL_Delay2,28  ; OPL2 Slow OPL3 Fast
@@InitOPL3:

     CALL Set_OPL2Mode
	 
     RET
Init_OPL Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;  WriteOPL: Write to an OPL2/3 Register
;  Support the Port 388 or OPL2LPT / OPL3LPT
;Input:  AH, Register
;        AL, Data
;        OPLPortOffset (0 : Channels 0-9 2: Channels 10-17)
;  Warning: DS can be anything
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

WriteOPL Proc Near

    CMP CS:OPL_LPT_Model,0
	JNE WriteOPLLPT
	
    PUSH AX
    PUSH CX
    PUSH DX

;PUSH AX
;CMP CS:OPLPortOffset,0
;JE @@WO2Zero
;Writech 'o'
;@@WO2Zero:
;CALL WriteWordH
;Writech ','
;POP AX

    PUSH AX
    MOV DX,388h
	ADD DL,CS:OPLPortOffset
    MOV AL,AH
    OUT DX,AL
	
    MOV DX,388h
	MOV CX,CS:OPL_Delay1
@@lp1:
    IN AL,DX
    LOOP @@lp1

    POP AX
    MOV DX,389h	
	ADD DL,CS:OPLPortOffset
    OUT DX,AL
	
    MOV DX,388h
    MOV CX,CS:OPL_Delay2
@@lp2:
    IN AL,DX
    LOOP @@lp2
	
    POP DX
    POP CX
	POP AX
    RET
WriteOPL Endp		

WriteOPLLPT Proc Near
 
;    CMP OPLPortOffset,0
;    JE DoWriteOPLLPT
; OPL3 LPT Port (Not supported yet)
;    RET

DoWriteOPLLPT:

    PUSH AX CX DX

;    Writech 'l'
	
    PUSH AX

    MOV DX,CS:OPLLPTPort

    MOV AL,AH
    OUT DX,AL  ; LPT Data (Register number)
 
    INC DX
    INC DX     ; LPT Control Port
    MOV AL,13  ; OPL2 Port
    CMP CS:OPLPortOffset,0
    JE @@OPL2LPT_Port ; Write to the first registers set (OPL2)
	MOV AL,5   ; OPL3 Port
@@OPL2LPT_Port:
    OUT DX,AL
    SUB AL,4
    OUT DX,AL 
    ADD AL,4
    OUT DX,AL

    DEC DX
    DEC DX    ; LPT Data Port
    MOV CX,CS:OPL_Delay1
@@llp1:
    IN AL,DX
    LOOP @@llp1

    POP AX
 
    OUT DX,AL  ; LPT Data (Register Value)

    INC DX
    INC DX     ; LPT Control Port
    MOV AL,12
    CMP CS:OPLPortOffset,0
    JE @@OPL2LPT_Port2 ; Write to the first registers set (OPL2)
	MOV AL,4   ; OPL3 Port
@@OPL2LPT_Port2:	
    OUT DX,AL
    SUB AL,4
    OUT DX,AL 
    ADD AL,4
    OUT DX,AL 

    DEC DX
    DEC DX
    MOV CX,CS:OPL_Delay2
@@llp2:
    IN AL,DX
    LOOP @@llp2

    POP DX CX AX
	
    RET
 WriteOPLLPT Endp
 
Voie_OPL2 DW 0

; Update all the Adlib Channels for S3M/SAT
; Only OPL2 is supported by "tracker" Code

OPL2_Update Proc Near

        MOV Voie_OPL2,0
        MOV CL,9
        XOR CH,CH
Commander_OPL2:
        PUSH CX
        MOV BX,Voie_OPL2
        MOV BL,Voies_Adlib[BX]      ;Chercher la voie reelle
        CMP BL,0
        JNZ OPL_Channel_Allocated
		JMP OPL_Update_Loop         ;Voie non allouee => Fin
OPL_Channel_Allocated:		
        DEC BX
        MOV Voie_Reelle,BX

        MOV BX,Voie_OPL2            ;Calcul de l'offset des operateurs...
        MOV AH,Offset_Op[BX]
        MOV Offset_Modulateur,AH

; Check Key Off, Disables or Note Cut
        MOV BX,Voie_Reelle
		MOV AL,Ch_Control[BX]
        
		TEST AL,CM_KeyOff+CM_Disabled+CM_NoteCut
		JZ OPL_Not_CheckIfStopped

; NoteCut ?
        TEST AL,CM_NoteCut
        JZ OPL_No_NoteCut

        AND Ch_Control[BX],Not (CM_NoteCut+CM_KeyOff)  ;Stop the KeyOff/NoteCut
        OR Ch_Control[BX],CM_Stopped      ;Stop the Channel
        CALL OPL2_StopChannel
        JMP OPL_Update_Loop
OPL_No_NoteCut:

; KeyOff ?		
        TEST AL,CM_KeyOff
        JZ OPL_No_KeyOff
		
        AND Ch_Control[BX],Not CM_KeyOff  ;Stop the KeyOff
        OR Ch_Control[BX],CM_Stopped      ;Stop the Channel
        CALL OPL2_Do_KeyOff
        JMP OPL_Update_Loop
OPL_No_KeyOff:

        TEST AL,CM_Disabled
        JE OPL_Not_Disabled
		
        JMP OPL_Update_Loop   ; Disabled (Manually) > End
OPL_Not_Disabled:

OPL_Not_CheckIfStopped:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChPeriode    ;Change the Period ?
        JZ OPL_Not_SetPeriod
        AND GUS_Controle[BX],Not M_ChPeriode

        CALL Set_Period_OPL2
OPL_Not_SetPeriod:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChSample     ;Changer the sample ?
        JZ OPL_Not_SetInstr
        AND GUS_Controle[BX],Not M_ChSample
        OR GUS_Controle[BX],M_ChVolume       ;Ask to change the Volume

        CALL Changer_Sample_OPL2
OPL_Not_SetInstr:

        MOV BX,Voie_Reelle                   ;Change the Volume ?
        TEST GUS_Controle[BX],M_ChVolume
        JZ OPL_Update_Loop
        AND GUS_Controle[BX],Not M_ChVolume

        CALL Changer_Volume_OPL2

OPL_Update_Loop:
        INC Voie_OPL2
        POP CX                      ; Fin des commandes pour la voie
        LOOP Boucle_Commander_OPL2  ; Boucler Ch_Number fois
        JMP Fin_Commander_OPL2
Boucle_Commander_OPL2:
        JMP Commander_OPL2
Fin_Commander_OPL2:
        RET
OPL2_Update Endp

; Input : Voie_OPL2
OPL2_Do_KeyOff Proc Near
    
;	WriteCh 'K'
;	WriteCh 'o'
        MOV BX,Voie_OPL2
        MOV AH,BL
        ADD AH,Reg_Key
        MOV AL,Old_Key_B0[BX]
        AND AL,Not 20h                ;Efface le bit Key => Key Off
        CALL WriteOPL
        RET
OPL2_Do_KeyOff Endp

; Input : Voie_OPL2, Offset_Modulateur
OPL2_StopChannel Proc Near

;    WriteCh 'K'
;    WriteCh 'l'
        MOV AH,Offset_Modulateur      ;Couper la voie...
        ADD AH,Reg_KSL_TL
        MOV AL,0FFh                   ;Niveau du modulateur=63 => Volume 0
        CALL WriteOPL

        MOV AH,Offset_Modulateur
        ADD AH,Reg_KSL_TL+3
        MOV AL,0FFh                   ;Niveau de la porteuse=63 => Volume 0
        CALL WriteOPL

        MOV BX,Voie_OPL2
        MOV AH,BL
        ADD AH,Reg_Key
        MOV AL,Old_Key_B0[BX]
        AND AL,Not 20h                ;Efface le bit Key => Key Off
        CALL WriteOPL
        RET
OPL2_StopChannel Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                  Changer_Sample_OPL2                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

AdlDebug Equ No

Changer_Sample_OPL2 Proc Near

        CALL OPL2_StopChannel
    
;	WriteCh 'S'
;	WriteCh 'm'
	
		XOR BX,BX
        MOV BX,Voie_Reelle
        TEST Ch_Control[BX],CM_Disabled ;Voie active ?
        JZ Do_Change_Sample_OPL2
		JMP Fin_Changer_Sample_OPL2
Do_Change_Sample_OPL2:
		
		MOV BL,CH_Smp_Pla[BX]
        SHL BX,1
        SHL BX,1	  
        LES DI,PtrSamples[BX]
                                      ;* Ecrire l'instrument *
        MOV BX,Voie_OPL2
        MOV AH,Offset_Modulateur
        ADD AH,Reg_AM_VIB
        MOV AL,ES:AM1[DI]	
        CALL WriteOPL
        MOV AH,Offset_Modulateur
        ADD AH,Reg_AM_VIB+3
        MOV AL,ES:AP1[DI]     
		CALL WriteOPL

        MOV AH,Offset_Modulateur
        ADD AH,Reg_KSL_TL
        MOV AL,ES:AM2[DI]
        MOV BX,Voie_OPL2
        MOV Old_KSL_TL_40[BX],AL        ;Sauvegarde le niveau du modulateur
        CALL WriteOPL                   ; Modulator Volume
        MOV AH,Offset_Modulateur
        ADD AH,Reg_KSL_TL+3
        MOV AL,ES:AP2[DI]
        MOV BX,Voie_OPL2
        MOV Old_KSL_TL_43[BX],AL        ;Sauvegarde le niveau de la porteuse		
        CALL WriteOPL                   ; Carrier Volume

        MOV AH,Offset_Modulateur
        ADD AH,Reg_AR_DR
        MOV AL,ES:AM3[DI]
        CALL WriteOPL
        MOV AH,Offset_Modulateur
        ADD AH,Reg_AR_DR+3
        MOV AL,ES:AP3[DI]
        CALL WriteOPL

        MOV AH,Offset_Modulateur
        ADD AH,Reg_SL_RR
        MOV AL,ES:AM4[DI]
        CALL WriteOPL
        MOV AH,Offset_Modulateur
        ADD AH,Reg_SL_RR+3
        MOV AL,ES:AP4[DI]
        CALL WriteOPL

        MOV AH,Offset_Modulateur
        ADD AH,Reg_WS
        MOV AL,ES:AM5[DI]
        CALL WriteOPL
        MOV AH,Offset_Modulateur
        ADD AH,Reg_WS+3
        MOV AL,ES:AP5[DI]
        CALL WriteOPL
                     
        MOV AH,Offset_Modulateur
        ADD AH,Reg_FB_FM
        MOV AL,ES:AFeedBack[DI]
        MOV BX,Voie_OPL2
        MOV Old_FB[BX],AL
        CALL WriteOPL

        MOV BX,Voie_OPL2
        MOV AL,Old_Key_B0[BX]
        MOV AH,BL
        ADD AH,Reg_Key
        OR  AL,20h                ;bit Key … 1 => Key On
        MOV BX,Voie_OPL2          ;Sauver la valeur du registre Key
        MOV Old_Key_B0[BX],AL
        CALL WriteOPL

Fin_Changer_Sample_OPL2:

        RET
Changer_Sample_OPL2 Endp

;Entree EAX,Frequence
Fr   DW 0
FNum DW 0
Bloc DB 0

Chercher_FNum Proc Near    ;Augmenter la precision si necessaire...
        MOV Fr,AX
        MOV FNum,0
        MOV Bloc,0
        CMP AX,0
        JZ Fin_Chercher_FNum
        MOV Bloc,5
        CMP AX,127*32 ;127*32
        JAE Test_Sup_493
Mul2:
        DEC Bloc
        SHL AX,1
        CMP AX,127*32  ;261*32
        JB Mul2
        JMP Calcul_FNum
Test_Sup_493:
        CMP AX,1023*32 ;493*32
        JBE Calcul_FNum
Div2:
        INC Bloc
        SHR AX,1
        CMP AX,1023*32 ;493*32
        JA Div2
Calcul_FNum:
        MOV AX,Fr
		MOV DX,AX
        MOV CL,15      ;20
        SUB CL,Bloc
        SHL AX,CL
		MOV CL,Bloc
		INC CL
		SHR DX,CL		
        MOV CX,49716
        DIV CX
        MOV FNum,AX    ;FNum = Freq SHL (15-Bloc) /49716
Fin_Chercher_FNum:
        RET
Chercher_FNum Endp


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                 Set_Period_OPL2                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Set_Period_OPL2 Proc Near
;       WriteCh 'P'
;	    WriteCh 'e'
	
        MOV BX,Voie_Reelle
        SHL BX,1                 ;Pointeur Double Mot
        SHL BX,1
        MOV AX,Word Ptr [BX+GUS_Frequency]
        
		SHR BX,1
        SHR BX,1        
		MOV VPart_decimale[BX],AH   ; Store the value for Debug display
        MOV VPart_decimale2[BX],AL

        CALL Chercher_FNum

        MOV AX,FNum
        MOV BX,Voie_OPL2
        MOV AH,BL
        ADD AH,0A0h              ;Registre Nb F
        CALL WriteOPL

        MOV BX,Voie_OPL2
        MOV BL,Old_Key_B0[BX]
        AND BL,11100000b
        MOV AX,FNum
        OR  BL,AH         ;Ajouter la partie haute de F
        MOV AH,Bloc
        AND AH,00000111b
        SHL AH,1
		SHL AH,1
        OR BL,AH          ;Ajouter Bloc
        MOV AL,BL

        MOV BX,Voie_OPL2
        MOV AH,BL
        ADD AH,Reg_Key    ;Registre Key (Bloc et partie haute de F)
        MOV Old_Key_B0[BX],AL
        CALL WriteOPL

        RET
Set_Period_OPL2 Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                 Changer_Volume_OPL2                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; Table de volume...

;Vol_OPL2 DB 63,56,48,43,40,37,35,33,32,31,29,28,27,26,25,25
;         DB 24,23,23,22,21,21,20,20,19,19,18,18,18,17,17,16
;         DB 16,16,15,15,15,14,14,14,13,13,13,13,12,12,12,12
;         DB 11,11,11,11,10,10,10,10,10, 9, 9, 9, 9, 9, 8, 8
;         DB  8, 8, 8, 7, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6, 5
;         DB  5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3
;         DB  3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2
;         DB  1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0

Vol_OPL2 DB 63,48,40,35,32,29,27,25
         DB 24,23,21,20,19,18,18,17
         DB 16,15,15,14,13,13,12,12
         DB 11,11,10,10,10, 9, 9, 8
         DB  8, 8, 7, 7, 7, 6, 6, 6
         DB  5, 5, 5, 4, 4, 4, 4, 3
         DB  3, 3, 3, 3, 2, 2, 2, 2
         DB  1, 1, 1, 1, 1, 0, 0, 0, 0

OldVol DB 0

; AH: Old KSL_TL Register value
Modifier_Vol_OPL2 Proc Near
        AND AH,11000000b     ;Garder KSL seulement
        MOV BX,Voie_Reelle
        MOV BL,Ch_Final_Vol[BX]
        MOV AL,Vol_OPL2[BX]  ;Read the volume (TL)
        OR AL,AH             ;Ajouter KSL … TL
        RET
Modifier_Vol_OPL2 Endp

Changer_Volume_OPL2 Proc Near
    
;	WriteCh 'V'
;	WriteCh 'l'
        MOV BX,Voie_OPL2
        MOV AH,Old_KSL_TL_43[BX] ;Volume de la porteuse
        CALL Modifier_Vol_OPL2   ;Modifier le volume
        MOV AH,Offset_Modulateur
        ADD AH,Reg_KSL_TL+3
        CALL WriteOPL         ;Sauve le volume de la porteuse

        TEST Old_FB[BX],1      ; Feedback / Mode
        JZ Vol_FM              ;Si FM, Ne pas changer le modulateur
;WriteCh 'V'
;Writech 'M'
        MOV BX,Voie_OPL2
        MOV AH,Old_KSL_TL_40[BX]  ;Volume de la 2eme porteuse
        CALL Modifier_Vol_OPL2  ;Modifier le volume
        MOV AH,Offset_Modulateur
        ADD AH,Reg_KSL_TL
        CALL WriteOPL         ;Sauve le volume de la 2eme porteuse

Vol_FM:
        MOV BX,Voie_OPL2

        RET
Changer_Volume_OPL2 Endp