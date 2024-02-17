;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ MIXAGE.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷      º
;            º                                                   º
;            º            --==ðð Mod Master XT ðð==--            º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteurúúúúúúúúúúúúúúúúúúúúúúúú Freddy Vetele    º
;            º                                                   º
;            º   Last modification              04/08/2021       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

; Mixing Variables

NB_Repetitions EQU 64

M_Mix_Left  Equ 001b
M_Mix_Right Equ 010b
M_Mix_Mono  Equ 100b

Buffer_Current_Mix_Offs DW 0         ;offset de depart du tampon a calculer

Mix_Channels_Cnt DB 0

Mix_Smp_End        DW 0
Mix_Smp_LoopLength DW 0
Mix_Buffer_Offset  DW 0

Buffer_Selected DB 0   ;Select the Output buffer to use
Buffer_Mixed    DB 0   ;Contains 1 for the channel where something was mixed.


Mix_CodeSize_8M   Equ MixCode_8M_End-MixCode_8M        ; 8Bit Move    > 13h
Mix_CodeSize_8M_2 Equ MixCode_8M_2_End-MixCode_8M_2    ; 8Bit Move *2 > 13h
Mix_CodeSize_8    Equ MixCode_8_End-MixCode_8          ; 8Bit         > 16h
Mix_CodeSize_8_2  Equ MixCode_8_2_End-MixCode_8_2      ; 8Bit *2      > 16h

If UseMix16 Eq Yes
Mix_CodeSize_16M  Equ MixCode_16M_End-MixCode_16M
Mix_CodeSize_16   Equ MixCode_16_End-MixCode_16
EndIf

%OUT MixCodeSize: <Mix_CodeSize_8>

PMix8Test PROC FAR     ;Appel du Pascal (Fonction, renvoie l'Erreur )

        PUSH DS BP
        DS_ASM
; For Speed test, use Dumy values: Read and write to the "Seg_Volume" Segment}	

        MOV Mix_Smp_End,1000

        MOV Mix_Loop64_Nb,10  ; Use only the Macro code (Test changing only the macro code)
        MOV Mix_Loop4_Nb,0
        MOV Mix_Loop1_Nb,0

        MOV CX,1000h                  ;-Init CX-   ( Decimal increment    )
		MOV DX,0                      ;-Init DX-   ( Accumulateur decimal )
        MOV AX,1
        MOV BP,AX                     ;-Init BP-   ( Increment entier     )
        MOV BH,0                      ;-Init BH-   ( Volume               )

        MOV DS,CS:Seg_Volume          ; DS:SI Sample Pointer
        MOV SI,0
        
		MOV ES,CS:Seg_Volume		  ; ES:DI Buffer Pointer
		MOV DI,0 ; Don't move 

MOV W CS:Mix_Buffer_Offset,100

Loop_SpeedTest:
        CALL Mixage_8

        DEC CS:Mix_Buffer_Offset
        JNZ Loop_SpeedTest

        MOV AX,ES  ; ES Must be 64*Mix_Loop64_Nb

		XOR AH,AH
        MOV AL,15
		
        POP BP DS
        RET
PMix8Test ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                   Calcul du tampon DMA                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Mix a buffer

Calcul_tampon PROC NEAR

;WriteCh 'b'
;MOV AX, Buffer_Current_Mix_Offs
;CALL WriteWordH
;WriteCh '-'

        CLD

        XOR AX,AX                       ; Use AX=0 for the next CMP
		MOV Nb_Voix_Mixees,AL
        MOV Nb_Voix_Skip_Vol,AL
		
        CMP Utilise_Stereo,AL           ; Set the Mixed flags on to avoid cleaning unused buffers
        JZ  Do_Not_Use_Stereo_Buffer
		MOV Buffer_Mixed,M_Mix_Mono              ; Stereo : Never Clean the Mono Buffer
		JMP Continue_Calcul_Tampon
Do_Not_Use_Stereo_Buffer:
		MOV Buffer_Mixed,M_Mix_Left+M_Mix_Right  ; Mono : Never Clean the Stereo Buffers
Continue_Calcul_Tampon:	
		
;        CMP Utilise_EMS,AL
;        JZ Pas_Utiliser_EMS
;        CALL Sauver_EMS                          ; Save the current EMS Page
;Pas_Utiliser_EMS:                                ; Not needed as "Mono task"

; ** Main Mixing Loop : Read all the channels samples infos and call the Mixing **

        MOV AL,Mix_Channels_Nb
		TEST AL,AL
		JZ Mixing_Finished         ; Nothing to mix ?
		
		MOV Mix_Channels_Cnt,AL
        MOV AX,Offset Mix_Channel_List
		MOV SI,AX

        PUSH SI
        XOR BH,BH
Main_MixingLoop:
        MOV AL,Buffer_Ahead_Cnt
        CMP AL,Buffers_Ahead_Min   ; Only 1 buffer ahead ? (2+ for TDY) > Skip Mixing
		JA Not_Too_Slow            ; Go Directly to Signed / Not Signed mix : Crack with 2 Buffers
; Too Slow, 		
        MOV AL,Nb_Voix_Mixees
        CMP Max_Mixed3,AL          ; Increment the number of channels mixed max for display
		JAE Main_MixingLoop_End
		MOV Max_Mixed3,AL
		JMP Main_MixingLoop_End
Not_Too_Slow:
; Read the Channel number from the list of channels to Mix
		POP SI       
		LODSB
		
		CMP AL,0FFh              ;TEST AL,AL
		JNE CT_Loop_Not_Disabled ;JNS CT_Loop_Not_Disabled
;		Call Write_s
		PUSH SI	                 ; If -1 -> Channel was disabled, Do Not Mix	
        CMP Mix_Channels_Cnt,1
        JE Main_MixingLoop_End
		JMP Main_MixingLoop
CT_Loop_Not_Disabled:
		
		MOV BL,AL
		MOV BP,BX
		SHL BP,1
		PUSH SI

        MOV AL,Ch_Final_Vol[BX]        ; OPT Skip if Volume<Volume_Skip
		CMP AL,Volume_Skip
		JBE Voie_Suivante_8

; Get the Sample Data infos
        XOR AX,AX
        MOV AL,CH_Smp_Pla[BX]
        Get_SMPPtr_ESDI AX            ; Sample Header -> ES:DI

        MOV CL,ES:SNb_Pages_EMS[DI]
		TEST CL,CL                   ; Nb of Pages=0 Not in EMS
		JZ Sample_Not_In_EMS

        MOV DX,ES:SHandle_EMS[DI]	
        CALL Placer_Pages_EMS        ; MAP the EMS Pages

Sample_Not_In_EMS:		
        CALL Calculer_sample

Voie_Suivante_8:
        DEC Mix_Channels_Cnt
		JNZ Main_MixingLoop  ; Mix Channels Loop

Main_MixingLoop_End:
        POP SI
		
; ** Clean the buffers if nothing was mixed inside. Then, convert to unsigned **

Mixing_Finished:
        TEST Buffer_Mixed,M_Mix_Mono
        JNZ Buffer_8_Mono_Mixed
        CMP Mix_Mono_Use_Left,1
        JE Buffer_8_Left_Clean   ; Mono use Left (16Bit) -> Clean Left Buffer
		MOV DI,Buffer_Current_Mix_Offs
		CALL Clean_Buffer        ; Nothing Mixed (Mono): Clean the buffer
        JMP Do_Convert_Unsigned
Buffer_8_Mono_Mixed:
        TEST Buffer_Mixed,M_Mix_Right
        JNZ Buffer_8_Right_Mixed
		MOV DI,Right_Buffer_Offs
		CALL Clean_Buffer        ; Nothing Mixed (Right): Clean the buffer
Buffer_8_Right_Mixed:
        TEST Buffer_Mixed,M_Mix_Left
        JNZ Do_Convert_Unsigned
Buffer_8_Left_Clean:		
		MOV DI,Left_Buffer_Offs
		CALL Clean_Buffer        ; Nothing Mixed (Left): Clean the buffer
		
Do_Convert_Unsigned:		
; ** Convert the Buffer, from signed to unsigned (If Needed)

        CALL [Buffer_Convert_Code]  ; Call the code to finalize the buffer

Fin_Calcul_Tampon:

        ;*** Not continuous DMA  Code Skip (No more supported for the moment) ***

;        CMP Utilise_EMS,0
;        JZ Pas_Utiliser_EMS_FIN
;        CALL Recuperer_EMS             ; Restore the previous EMS Page
;Pas_Utiliser_EMS_FIN:

        RET
Calcul_tampon ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      -= Initialiser les registres pour le mixage =-       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Init_Registres_Mixage PROC Near

        MOV SI,Ch_Mix_Offs[BP]
		
        MOV CH,VPart_Decimale[BX]     ;-Init CX-   ( Decimal increment    )
		MOV CL,VPart_Decimale2[BX]
        MOV DX,VAccumulateur[BP]      ;-Init DX-   ( Accumulateur d‚cimal )
        XOR AX,AX
        MOV AL,VPart_Entiere[BX]
        MOV BP,AX                     ;-Init BP-   ( Incr‚ment entier     )

        MOV BH,Ch_Final_Vol[BX]            ;-Init BH-   ( Volume               )

        MOV DS,ES:SSegment[DI]        ; DS:SI Sample Pointer
        
		MOV ES,CS:Seg_Volume		  ; Don't move
		MOV DI,CS:[Mix_Buffer_Offset] ; Don't move 
	
        RET
Init_Registres_Mixage Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                 -= Mix one sample =-                      ³
;³                                                           ³
;³  Input: ES:DI : Sample Definition                         ³
;³         BX    : Channel number                            ³
;³  Called only if the sample is loaded and the channel is   ³
;³  not stopped                                              ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Calculer_sample Proc Near
; Init the Mix Buffer @ : Buffer_Selected and Mix_Buffer_Offset
        CMP Utilise_Stereo,0         ; Stereo ?
        JZ Mix_In_Mono               ; Mix in Mono, Don't change the mix buffer @
			
        MOV AL,CH_Panning[BX]
        CMP AL,40h
        JB  Mix_Left_Buffer
        MOV AX,Right_Buffer_Offs  ; Use Right Temp Buffer
		MOV Buffer_Selected,M_Mix_Right
        MOV Mix_Buffer_Offset,AX
		JMP Start_Mix_Loop
Mix_Left_Buffer:
        MOV AX,Left_Buffer_Offs   ; Use Left Temp Buffer
		MOV Buffer_Selected,M_Mix_Left
        MOV Mix_Buffer_Offset,AX		
		JMP Start_Mix_Loop

Mix_In_Mono:
        MOV AX,Buffer_Current_Mix_Offs ; Use the Current DMA Buffer Offset
        CMP Mix_Mono_Use_Left,1
		JNE Min_In_Mono_to_Current
		MOV AX,Left_Buffer_Offs       ; Use the Left Buffer for Mono (16 Bit to 8 Bit)
Min_In_Mono_to_Current:
		MOV Buffer_Selected,M_Mix_Mono
        MOV Mix_Buffer_Offset,AX
Start_Mix_Loop:

        TEST ES:SInfo[DI],M_Boucle
		JZ Sample_Sans_Bouclage_8

Sample_Bouclage_8:    ;**** Calcul du sample avec bouclage ****

        MOV AX,w ES:SRep_Len[DI]      ;Initialize the Loop Size
        MOV Mix_Smp_LoopLength,AX
        MOV AX,w ES:SLen[DI]
        MOV Mix_Smp_End,AX         ;Initialize the Sample End (Length)

        PUSH BX BP

        CALL Init_Registres_Mixage
		
        MOV AL,CS:[Buffer_Selected]
		TEST AL,CS:[Buffer_Mixed]    ;The Buffer selected already mixed something ?
		JZ Do_Mixage_B_Move
        
If UseMix16 Eq Yes		
		CMP CS:[Mix_16Bit],1
		JE Do_Mix_16B
EndIf		
        CALL Mix_8Loop               ;Do 8 Bit Mixing with Loop
        JMP Fin_8B
If UseMix16 Eq Yes
Do_Mix_16B:
        CALL Mixage_16B              ;Do 16 Bit Mixing with Loop
        JMP Fin_8B
EndIf		
Do_Mixage_B_Move:
		
If UseMix16 Eq Yes
		CMP CS:[Mix_16Bit],1
		JE Do_Mix_M_16B
Endif		
        CALL Mix_M_8Loop             ;Do 8 Bit 'Move' with Loop
        JMP Fin_8B
If UseMix16 Eq Yes
Do_Mix_M_16B:
        CALL Mixage_M_16B            ;Do 16 Bit 'Move' with Loop
EndIf		
Fin_8B:
        POP BP BX
        DS_ASM

        MOV AL,Buffer_Selected
		OR Buffer_Mixed,AL           ;Set the Selected buffer bit to 1        
		INC Nb_Voix_Mixees           ;OPT

        ;- Restaurer les valeurs -

        MOV Ch_Mix_Offs[BP],SI
        MOV VAccumulateur[BP],DX
        RET

Sample_Sans_Bouclage_8:   ;**** Calcul du sample sans bouclage ****

        PUSH BX BP

        MOV DX,w ES:SLen[DI]             
        MOV Mix_Smp_End,DX           ;Initialize the Sample End
;        MOV W [OFFSET AM_FiCHU_NSmp_8-2],DX  ;Initialize the Sample End in the code

        CALL Init_Registres_Mixage   ;Initialize the registers for the mixing

        MOV AL,CS:[Buffer_Selected]
		TEST AL,CS:[Buffer_Mixed]    ;The Buffer selected already mixed something ?
		JZ Do_Mixage_Move

If UseMix16 Eq Yes
		CMP CS:[Mix_16Bit],1
		JE Do_Mix_16
Endif
        CALL Mixage_8                ;Mixage 8 bit sans bouclage...
		JMP Fin_8
If UseMix16 Eq Yes
Do_Mix_16:
        CALL Mixage_16
		JMP Fin_8
Endif		
Do_Mixage_Move:
If UseMix16 Eq Yes
		CMP CS:[Mix_16Bit],1
		JE Do_Mix_M_16   
Endif		
        CALL Mixage_M_8
		JMP Fin_8	
If UseMix16 Eq Yes
Do_Mix_M_16:
        CALL Mixage_M_16
Endif		
Fin_8:		
        POP BP BX
        DS_ASM

        MOV AL,Buffer_Selected
		OR Buffer_Mixed,AL           ;Set the Selected buffer bit to 1      
		INC Nb_Voix_Mixees           ;OPT

        ;- Restaurer les valeurs -

        MOV Ch_Mix_Offs[BP],SI
        MOV VAccumulateur[BP],DX
        CMP SI,Mix_Smp_End
        JBE Pas_Desactiver_Voie_8
        OR Ch_Control[BX],CM_Stopped  ;Sample termin‚ => Disable the voie
Pas_Desactiver_Voie_8:
        RET
		
Calculer_sample Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                           ³
;³  Skip the Sample Calculation (Vol =0 or Mixing Too Slow)  ³
;³                                                           ³
;³  Input: ES:DI Pointeur sur le sample.                    ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Skip_Sample Proc Near
        RET
Skip_Sample EndP

Build_MixCode Proc

        MOV CX,32
		PUSH CS
		PUSH CS
		POP DS
		POP ES
		MOV SI,Offset MixCode_8

		RET

Build_MixCode Endp

; Copy a code CX Times
; DS:SI Source of the Mix Code to copy
; ED:DI Destination
; CX : Nb of time it is copied
; BX : Nb of Bytes for 1 or 2 samples Mix.

BuildUnrolledMixCode Proc Near

Copy_MixCode:
        PUSH CX
		PUSH SI       ; Save the Code to copy @
		MOV CX, BX
		REP MOVSB     ; Copy the code one time
		POP SI
		POP CX
		LOOP Copy_MixCode
        RET
BuildUnrolledMixCode Endp

;-------------------------------------------------------------
;³                -= Mix 8 Bits With Loop =-                 ³
;³                                                           ³
;³ Input:   DX:Accumulateur de la partie decimale            ³
;³          CX:Decimal increment                             ³
;³          BP:Integer increment                             ³
;³          DS:Sample Segment                                ³
;³          SI:Sample Offset (Position)                      ³
;³          ES:Buffer and Volume table Segment               ³
;³          DI:Buffer Offset                                 ³
;³          BH:Volume                                        ³
;-------------------------------------------------------------

Mix_Loop_Cnt DW 0


;8Bit mixing, Mix one Sample at a time
M_MixCode_8 Macro
        MOV AL,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        STOSB
        ADD DX,CX
        ADC SI,BP
ENDM

MixCode_8:
       M_MixCode_8
MixCode_8_End:

;8Bit mixing, Mix two Samples at a time
M_MixCode_8_2 Macro
        MOV AX,ES:[DI]
        ADD DX,CX		
        MOV BL,[SI]
        ADC SI,BP
        ADD AL,ES:[BX]
        ADD DX,CX
        MOV BL,[SI]
        ADC SI,BP
        ADD AH,ES:[BX]
        STOSW
ENDM
		
MixCode_8_2:
        M_MixCode_8_2
MixCode_8_2_End:

M_MixCode_8M Macro
        ADD DX,CX
        MOV BL,[SI]
        ADC SI,BP
        MOV AL,ES:[BX]
        STOSB
ENDM

MixCode_8M:
        M_MixCode_8M
MixCode_8M_End:

M_MixCode_8M_2 Macro
        MOV BL,[SI]
        ADD DX,CX		
        MOV AL,ES:[BX]
        ADC SI,BP
        MOV BL,[SI]
        ADD DX,CX		
        MOV AH,ES:[BX]
        ADC SI,BP
        STOSW
ENDM

MixCode_8M_2:
        M_MixCode_8M_2
MixCode_8M_2_End:


EVEN   ; Make the @ even
        NOP ; Faster if ODD :)

Calcul_Rapide8 PROC NEAR   ;**** Fast Mixing Block (ADD)**** 

    REPT Nb_Repetitions/2  ; Copy Nb_Repetitions/2 Times
        M_MixCode_8_2
    ENDM	
        RET
Calcul_Rapide8 Endp

Calcul_M_Rapide8 PROC NEAR   ;**** Fist Mixing Code (MOV) ****

    REPT Nb_Repetitions/2    ; Copy Nb_Repetitions/2 Times
        MOV BL,[SI]
        ADD DX,CX		
        MOV AL,ES:[BX]
        ADC SI,BP
        MOV BL,[SI]
        ADD DX,CX		
        MOV AH,ES:[BX]
        ADC SI,BP
        STOSW
    ENDM
        RET
Calcul_M_Rapide8 Endp

; 8Bit Mixing, Loop Samples
Mix_8Loop Proc Near
        
		MOV AX,CS:[Mix_Loop64_Nb]
		MOV B CS:[Mix_Loop_Cnt],AL
		
; Mix 64 Samples per loop

Boucle_8RapideB:

        CALL Calcul_Rapide8            ;Calcul de 64 Valeurs sans boucle !!!

Test_Pos8B:
        CMP SI,CS:[Mix_Smp_End]        ;Bouclage ?
        JB Boucler_8RapideB
        SUB SI,CS:[Mix_Smp_LoopLength]
        JMP Test_Pos8B
Boucler_8RapideB:
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_8RapideB

; Mix the remaining samples

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
		JZ Test1_Sample_8B
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_8B:          ;Nb de boucles divis‚ par deux
    REPT 2
        MOV AX,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        ADD AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_8B

Test1_Sample_8B:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_8B
		MOV B CS:[Mix_Loop_Cnt],AL
		
Boucle_sample_8B2:          ;Nb de boucles divis‚ par deux
        MOV AL,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        STOSB
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_8B2
		
Mix_Smp_End_8B:
        RET
Mix_8Loop Endp

; 8Bit Mixing, Loop Samples
; Same Mixing but with MOV Instead of ADD (Clear the buffer at the same time)
Mix_M_8Loop Proc Near

; Mix 64 Samples per loop

		MOV AX,CS:[Mix_Loop64_Nb]
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_M_8RapideB:

        CALL Calcul_M_Rapide8           ;Calcul de 64 Valeurs sans boucle !!!

Test_M_Pos8B:
        CMP SI,CS:[Mix_Smp_End]        ;Bouclage ?
        JB Boucler_M_8RapideB
        SUB SI,CS:[Mix_Smp_LoopLength]
        JMP Test_M_Pos8B
Boucler_M_8RapideB:
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_M_8RapideB

; Mix the remaining samples

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample_M_8B
        MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_M_8B:
    REPT 2
        MOV BL,[SI]
        MOV AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        MOV AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_M_8B

Test1_Sample_M_8B:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_M_8B
		MOV B CS:[Mix_Loop_Cnt],AL

Boucle_sample_M_8B2:
        MOV BL,[SI]
        MOV AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        STOSB
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_M_8B2

Mix_Smp_End_M_8B:
        RET
Mix_M_8Loop Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³         -= 8 Bits Mixing, No Loops=-                      ³
;³                                                           ³
;³ Input:   DX:Accumulateur de la partie d‚cimale            ³
;³          CX:Decimal increment                             ³
;³          BP:Integer increment                             ³
;³          DS:Sample Segment                                ³
;³          SI:Sample Offset (Position)                      ³
;³          ES:Buffer and Volume table Segment               ³
;³          DI:Buffer Offset                                 ³
;³          BH:Volume                                        ³
; Mix_Loop64_Nb
; Mix_Loop4_Nb
; Mix_Loop1_Nb
; Mix_Smp_End
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Mixage_8 Proc Near

		MOV AX,CS:[Mix_Loop64_Nb]  ; Nb of 64xLoop to do
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_8Rapide:

        CALL Calcul_Rapide8  ; Mix 64 Samples at a time

        CMP SI,CS:[Mix_Smp_End]
        JAE Mix_Smp_End_8
        DEC B CS:[Mix_Loop_Cnt]
        JNZ	Boucle_8Rapide

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample_8
		
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_8:           ; Diviser le Nb de boucles par deux

    REPT 2
        MOV AX,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        ADD AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM

        CMP SI,CS:[Mix_Smp_End]
        JNB Test1_Sample_8
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_8
		
Test1_Sample_8:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_8
		MOV B CS:[Mix_Loop_Cnt],AL		

Boucle_sample_8_2:           ; Diviser le Nb de boucles par deux
        MOV AX,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        ADD AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP

        CMP SI,CS:[Mix_Smp_End]
        JNB Mix_Smp_End_8
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_8_2
		
Mix_Smp_End_8:
        RET
Mixage_8 Endp

; Same Mixing With MOV Instead of ADD (Clear the buffer as well)

Mixage_M_8 Proc Near

		MOV AX,CS:[Mix_Loop64_Nb] ; Nb of 64xLoop to do
		MOV W CS:[Mix_Loop_Cnt],AX
Boucle_M_8Rapide:

        CALL Calcul_M_Rapide8  ; Mix 64 Samples at a time

        CMP SI,CS:[Mix_Smp_End]
        JAE CleanEnd_Sample_M_8
        DEC B CS:[Mix_Loop_Cnt]
        JNZ	Boucle_M_8Rapide

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample_M_8

		MOV B CS:[Mix_Loop_Cnt],AL		
Boucle_sample_M_8:             ;Diviser le Nb de boucles par deux

    REPT 2
        MOV BL,[SI]
        MOV AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        MOV AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM

        CMP SI,W CS:[Mix_Smp_End]
        JNB CleanEnd_Sample_M_8
        DEC B CS:[Mix_Loop_Cnt]
		JNZ Boucle_sample_M_8

Test1_Sample_M_8:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_M_8
		MOV B CS:[Mix_Loop_Cnt],AL	

Boucle_sample_M_8_2:
        MOV BL,[SI]
        MOV AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        STOSB
        CMP SI,CS:[Mix_Smp_End]
        JNB CleanEnd_Sample_M_8
        DEC B CS:[Mix_Loop_Cnt]
		JNZ Boucle_sample_M_8_2

Mix_Smp_End_M_8:		
		RET

CleanEnd_Sample_M_8: ; 15/8/22 Optimized : 60 Bytes less

        MOV CX,CS:[Buffer_Samples_Nb]
		MOV AX,DI
		SUB AX,CS:[Mix_Buffer_Offset]
		SUB CX,AX                      ;CX=Buffer_Samples_Nb-(Current Offset-Start Offset)=Remaining Bytes
		JCXZ CS_M_8_End
        INC CX                         ; It is not a problem is we clean 2 Bytes more, as it is the next buffer begining
        SHR CX,1
		XOR AX,AX
        REP STOSW
CS_M_8_End:
        RET

Mixage_M_8 Endp



;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³              -= Mixage 16 Bits with Loop =-               ³
;³                                                           ³
;³ Input:   DX:Accumulateur de la partie d‚cimale            ³
;³          CX:Decimal increment                             ³
;³          BP:Integer increment                             ³
;³          DS:Sample Segment                                ³
;³          SI:Sample Offset (Position)                      ³
;³          ES:Buffer and Volume table Segment               ³
;³          DI:Buffer Offset                                 ³
;³          BH:Volume                                        ³
; 
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseMix16 Eq Yes

M_MixCode_16 Macro
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		ADD ES:[DI],AX
		INC DI
		INC DI
        ADD DX,CX
        ADC SI,BP
ENDM

MixCode_16:
        M_MixCode_16
MixCode_16_End:

M_MixCode_16M Macro
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		STOSW
        ADD DX,CX
        ADC SI,BP
ENDM

MixCode_16M:
        M_MixCode_16M
MixCode_16M_End:

ALIGN 4
Calcul_Rapide16 PROC NEAR   ;**** Fast Mixing Block (ADD)**** 

    REPT Nb_Repetitions    ; Copy Nb_Repetitions Times
     M_MixCode_16
    ENDM	
        RET
Calcul_Rapide16 Endp

ALIGN 4

Calcul_M_Rapide16 PROC NEAR   ;**** Fist Mixing Code (MOV) ****

    REPT Nb_Repetitions    ; Copy Nb_Repetitions Times
     M_MixCode_16M
    ENDM
        RET
Calcul_M_Rapide16 Endp

;16Bit, Looped Sample
Mixage_16B Proc Near
      
		MOV AX,CS:[Mix_Loop64_Nb]
		MOV B CS:[Mix_Loop_Cnt],AL
		
; Mix 64 Samples per loop

Boucle_16RapideB:

        CALL Calcul_Rapide16           ;Calcul de 64 Valeurs sans boucle !!!

Test_Pos16B:
        CMP SI,CS:[Mix_Smp_End]        ;Bouclage ?
        JB Boucler_16RapideB
        SUB SI,CS:[Mix_Smp_LoopLength]
        JMP Test_Pos16B
Boucler_16RapideB:
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_16RapideB

; Mix the remaining samples

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
		JZ Test1_Sample_16B
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_16B:          ;Nb de boucles divis‚ par deux

    REPT 4
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		ADD ES:[DI],AX
		INC DI
		INC DI
        ADD DX,CX
        ADC SI,BP
	ENDM

        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_16B

Test1_Sample_16B:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_16B
		MOV B CS:[Mix_Loop_Cnt],AL

Boucle_sample_16B2:          ;Nb de boucles divis‚ par deux

        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		ADD ES:[DI],AX
		INC DI
		INC DI
        ADD DX,CX
        ADC SI,BP
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_16B2

Mix_Smp_End_16B:
        RET
Mixage_16B Endp

; Same Mixing but with MOV Instead of ADD (Clear the buffer at the same time)

Mixage_M_16B Proc Near
		
; Mix 64 Samples per loop

		MOV AX,CS:[Mix_Loop64_Nb]
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_M_16RapideB:

        CALL Calcul_M_Rapide16           ;Calcul de 64 Valeurs sans boucle !!!

Test_M_Pos16B:
        CMP SI,CS:[Mix_Smp_End]        ;Bouclage ?
        JB Boucler_M_16RapideB
        SUB SI,CS:[Mix_Smp_LoopLength]
        JMP Test_M_Pos16B
Boucler_M_16RapideB:
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_M_16RapideB

; Mix the remaining samples

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample__M_16B
        MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_M_16B:          ;Nb de boucles divis‚ par deux

    REPT 4
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM

        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_M_16B

Test1_Sample__M_16B:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_M_16B
		MOV B CS:[Mix_Loop_Cnt],AL

Boucle_sample_M_16B2:

        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		STOSW
        ADD DX,CX
        ADC SI,BP
		
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_M_16B2

Mix_Smp_End_M_16B:
        RET
Mixage_M_16B Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                 -= Mix 16 Bits No Loop =-                 ³
;³                                                           ³
;³ Input:   DX:Accumulateur de la partie d‚cimale            ³
;³          CX:Decimal increment                             ³
;³          BP:Integer increment                             ³
;³          DS:Sample Segment                                ³
;³          SI:Sample Offset (Position)                      ³
;³          ES:Buffer and Volume table Segment               ³
;³          DI:Buffer Offset                                 ³
;³          BH:Volume                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Mixage_16 Proc Near
		
		MOV AX,CS:[Mix_Loop64_Nb]
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_16Rapide:

        CALL Calcul_Rapide16  ;Calcul de 64 Valeurs sans boucle !!!

        CMP SI,CS:[Mix_Smp_End]
        JAE Mix_Smp_End_M_16B  ; Not the same procedure, but doing the same :)
        DEC B CS:[Mix_Loop_Cnt]
        JNZ	Boucle_16Rapide

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample_16
		MOV B CS:[Mix_Loop_Cnt],AL
Boucle_sample_16:             ;Diviser le Nb de boucles par deux

    REPT 4
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		ADD ES:[DI],AX
		INC DI
		INC DI
        ADD DX,CX
        ADC SI,BP
	ENDM

        CMP SI,CS:[Mix_Smp_End]
        JNB Test1_Sample_16
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_16
		
Test1_Sample_16:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_16
		MOV B CS:[Mix_Loop_Cnt],AL		

Boucle_sample_16_2:             ;Diviser le Nb de boucles par deux
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		ADD ES:[DI],AX
		INC DI
		INC DI
        ADD DX,CX
        ADC SI,BP

        CMP SI,CS:[Mix_Smp_End]
        JNB Mix_Smp_End_16
        DEC B CS:[Mix_Loop_Cnt]
        JNZ Boucle_sample_16_2

Mix_Smp_End_16:
        RET
Mixage_16 Endp

;Writech 'C'		
;PUSH AX
;MOV AX,CX
;CALL WriteWordH
;POP AX

; Same Mixing With MOV Instead of ADD (Clear the buffer as well)

; Moved here as too far otherwise.
CleanEnd_Sample_M_16: ; 15/8/22 Optimized : 60 Bytes less

        MOV CX,CS:[Buffer_Samples_Nb]
		SHL CX,1
		MOV AX,DI
		SUB AX,CS:[Mix_Buffer_Offset]
		SUB CX,AX                      ; CX=Buffer_Samples_Nb-(Current Offset-Start Offset)=Remaining Bytes
		JCXZ CS_M_16_End               ; Not Needed !
		INC CX
		SHR CX,1                       ; Word to Clean
		XOR AX,AX
        REP STOSW                      ; Clean the buffer End
CS_M_16_End:
        RET

Mixage_M_16 Proc Near

		MOV AX,CS:[Mix_Loop64_Nb]
		MOV W CS:[Mix_Loop_Cnt],AX
Boucle_M_16Rapide:

        CALL Calcul_M_Rapide16  ;Calcul de 64 Valeurs sans boucle !!!

        CMP SI,CS:[Mix_Smp_End]
        JAE CleanEnd_Sample_M_16
        DEC B CS:[Mix_Loop_Cnt]
        JNZ	Boucle_M_16Rapide

		MOV AX,CS:[Mix_Loop4_Nb]
        OR AL,AL
        JZ Test1_Sample__M_16
		MOV B CS:[Mix_Loop_Cnt],AL		
Boucle_sample_M_16:
    REPT 4
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		STOSW
        ADD DX,CX
        ADC SI,BP
	ENDM
        CMP SI,CS:[Mix_Smp_End]
        JNB CleanEnd_Sample_M_16
        DEC B CS:[Mix_Loop_Cnt]
		JNZ Boucle_sample_M_16
		
Test1_Sample__M_16:
        MOV AL,CS:[Mix_Loop1_Nb]
		OR AL,AL
        JZ Mix_Smp_End_M_16
		MOV B CS:[Mix_Loop_Cnt],AL
		
Boucle_sample_M_16_2:
        MOV BL,[SI]
		SHL BX,1
        MOV AX,ES:[BX]
		SHR BX,1
		STOSW
        ADD DX,CX
        ADC SI,BP

        CMP SI,CS:[Mix_Smp_End]
        JNB CleanEnd_Sample_M_16_2
        DEC B CS:[Mix_Loop_Cnt]
		JNZ Boucle_sample_M_16_2

Mix_Smp_End_M_16:
        RET

CleanEnd_Sample_M_16_2:
        JMP CleanEnd_Sample_M_16
Mixage_M_16 Endp

EndIf

;-------------------------------------------------------------
;!                  -= Clean a Buffer =-                     !
;!  Input : DI: Offset of the buffer to Clean (0)            !
;!  Change: ES,CX,AX   May Clean One byte Further            !
;-------------------------------------------------------------

Clean_Buffer Proc Near
;WriteCh 'C'
        MOV ES,Seg_Volume          ; ES=Volume Table and Buffers Segment
        MOV CX,Buffer_Samples_Nb
        XOR AX,AX
        
If UseMix16 Eq Yes           ; If 16Bit, the Samples_Nb is Word
		CMP Mix_16Bit,1
        JE Clean_Buff_16b
EndIf
		SHR CX,1
Clean_Buff_16b:
        REP STOSW            ; Clean the Buffer, not a problem if going one Byte Above

        ES_ASM
        RET
Clean_Buffer Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                  -= Convert Buffers =-                    ³
;³   Mono : Convert signed to unsigned buffer if Not SB16    ³
;³   Stereo : Combine Left and Right and Convert             ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; *** Convert the Output buffer for the PC Speaker ***
; -> Apply the Log Table  > The table will need to be optimized, for different Output frequency.

Convert_PCSpeaker PROC Near      ; Apply the Log table to the Buffer for PC Speaker output

        MOV CX,Buffer_Samples_Nb
        SHR CX,1
        SHR CX,1                 ;Buffer multiple de 4 -> /4
                                 ;-- Convertir sans mixage --
        MOV DI,Buffer_Current_Mix_Offs
        MOV ES,Seg_Volume        ;DS=Segment de la table de volume
        MOV BX,OFFSET T_bep                 
Loop_Convert_Speaker:
       REPT 2
        MOV AX,ES:[DI]
		XLAT                     ;Read the log Table (DS:BX)
		XCHG AH,AL
		XLAT
		XCHG AH,AL
		STOSW
       ENDM
        LOOP Loop_Convert_Speaker

        XOR CX,CX
		MOV CL,CS:[Mix_Loop1_Nb]
        JCXZ Convert_PCSpeaker_End

Loop_Convert_Speaker2:
        MOV AX,ES:[DI]
		XLAT                     ;Read the log Table (DS:BX)
		STOSB
        LOOP Loop_Convert_Speaker2

Convert_PCSpeaker_End:

        RET
Convert_PCSpeaker EndP

; ** Convert Left/Right Buffers to the current Buffer to Unsigned

Convert_NS_8Stereo Proc Near
;        CMP Utilise_Mixage,1
;        JE Calcul_mixage8

        MOV DX,8080h
        MOV ES,Seg_Volume                
        MOV DI,Buffer_Current_Mix_Offs   ;ES:DI Current Mix Buffer Address


		MOV CX,Mix_Loop64_Nb
		MOV AX,Right_Buffer_Offs
        SUB AX,Left_Buffer_Offs
		MOV BP,AX                        ;BP = Right_Buffer_Offs-Left_Buffer_Offs
        MOV SI,Left_Buffer_Offs
		MOV DS,Seg_Volume                ;DS:SI Right Buffer Address
        CLD
; *** DS Modified ***
Loop_Convert_Stereo64:
       REPT 32
        MOV BX,DS:[SI+BP]  ; Read 2 Bytes from left buffer
		LODSW              ; Read 2 Bytes from Right buffer and move index
		XCHG AH,BL
        XOR AX,DX
		XOR BX,DX
		STOSW
		XCHG AX,BX
		STOSW
       ENDM
	    DEC CX
		JZ Loop_Convert_Stereo64End
		JMP Loop_Convert_Stereo64
Loop_Convert_Stereo64End:
		
		MOV CX,CS:[Mix_Loop4_Nb]
        JCXZ Test1_Convert_Stereo
Loop_Convert_Stereo4:
       REPT 2
        MOV BX,DS:[SI+BP]
		LODSW
		XCHG AH,BL
        XOR AX,DX
		XOR BX,DX
		STOSW
		XCHG AX,BX
		STOSW
       ENDM
		LOOP Loop_Convert_Stereo4

Test1_Convert_Stereo:
        XOR CX,CX
		MOV CL,CS:[Mix_Loop1_Nb]
        JCXZ ConvertNS_End

Loop_Convert_Stereo1:
        MOV AH,DS:[SI+BP]
		LODSB
        XOR AX,DX
		STOSW
		LOOP Loop_Convert_Stereo1		
		
ConvertNS_End:

        DS_ASM
        RET
Convert_NS_8Stereo Endp

; ** Convert the same buffer to Unsigned 
Convert_NS_8Mono Proc Near

        MOV CX,Mix_Loop64_Nb
        MOV SI,Buffer_Current_Mix_Offs
        MOV DS,Seg_Volume        ;DS=Segment de la table de volume
        MOV AX,8080h
		
ConvertNS_Loop64:		
        XOR W [SI],AX
        XOR W [SI+2],AX       
        XOR W [SI+4],AX
        XOR W [SI+6],AX
        XOR W [SI+8],AX	
        XOR W [SI+10],AX
        XOR W [SI+12],AX
        XOR W [SI+14],AX
        XOR W [SI+16],AX
        XOR W [SI+18],AX	
        XOR W [SI+20],AX
        XOR W [SI+22],AX
        XOR W [SI+24],AX
        XOR W [SI+26],AX
        XOR W [SI+28],AX
        XOR W [SI+30],AX
        XOR W [SI+32],AX
        XOR W [SI+34],AX
        XOR W [SI+36],AX
        XOR W [SI+38],AX
        XOR W [SI+40],AX
        XOR W [SI+42],AX
        XOR W [SI+44],AX
        XOR W [SI+46],AX
        XOR W [SI+48],AX
        XOR W [SI+50],AX
        XOR W [SI+52],AX
        XOR W [SI+54],AX
        XOR W [SI+56],AX
        XOR W [SI+58],AX
        XOR W [SI+60],AX
        XOR W [SI+62],AX
		ADD SI,64
        Loop ConvertNS_Loop64
        
		MOV CX,CS:[Mix_Loop4_Nb]
        JCXZ Test1_ConvertNS
ConvertNS_Loop4:
        XOR W [SI],AX             ;Signed => Not Signed
        XOR W [SI+2],AX           ;Signed => Not Signed
		ADD SI,4		
        LOOP ConvertNS_Loop4

Test1_ConvertNS:
        XOR CX,CX
		MOV CL,CS:[Mix_Loop1_Nb]
        JCXZ ConvertNS_End2

ConvertNS_Loop1:
        XOR B [SI],AL             ;Signed => Not Signed
		INC SI
        LOOP ConvertNS_Loop1

ConvertNS_End2:		
		DS_ASM
		
		RET
Convert_NS_8Mono ENDP

If UseMix16 Eq Yes

; Convert Left Buffer (16Bit) to Current Buffer Unsigned (8Bit) (To play a 16Bit Buffer on SB/SBPro... Mono)
; Need speed to mix 16Bit, not a problem if not heavily optimized

Convert_NS_16_8Mono PROC NEAR ; Convert the 16 Bit Buffer Signed to a 8 Bit Unsigned

        MOV CX,Buffer_Samples_Nb
        SHR CX,1
        SHR CX,1                 ;Buffer Size/4

        MOV DX,8080h
        MOV ES,Seg_Volume                
        MOV DI,Buffer_Current_Mix_Offs   ;ES:DI Current Mix Buffer Address

        MOV SI,Left_Buffer_Offs
		MOV DS,Seg_Volume                ;DS:SI Right Buffer Address
		
Convert_NS_16_8Mono_Loop:
       REPT 2
        INC SI                    ; Move to the first Word MSB
        LODSB                     ; Load the First Byte from the Left Buffer
		INC SI                    ; Move to the second Word MSB
		XCHG AH,AL
		LODSB                     ; Load the First Byte from the Left Buffer
		XCHG AH,AL
		XOR AX,DX
		STOSW                     ; Store the 2 Bytes to the Current Mix Buffer
	   ENDM
		LOOP Convert_NS_16_8Mono_Loop

; More Bytes to Add ?
        XOR CX,CX
		MOV CL,B CS:[Mix_Loop1_Nb]
		JCXZ Convert_NS_16_8Mono_End

Convert_NS_16_8Mono_Loop2:
        INC SI                    ; Move to the first Word MSB
        LODSB                     ; Load the First Byte from the Left Buffer
        XOR AL,DL
		STOSB                     ; Store the 2 Bytes to the Current Mix Buffer
		LOOP Convert_NS_16_8Mono_Loop2

Convert_NS_16_8Mono_End:		

		DS_ASM
		RET
Convert_NS_16_8Mono ENDP

; Convert Left Buffer (16Bit) to Current Buffer Signed (8Bit) (To play a 16Bit Buffer on BB 2.5+/SB16 Mono)
; Need speed to mix 16Bit, not a problem if not heavily optimized

Convert_S_16_8Mono PROC NEAR ; Convert the 16 Bit Buffer Signed to a 8 Bit Unsigned

        MOV CX,Buffer_Samples_Nb
        SHR CX,1
        SHR CX,1                 ;Buffer Size/4

        MOV ES,Seg_Volume                
        MOV DI,Buffer_Current_Mix_Offs   ;ES:DI Current Mix Buffer Address

        MOV SI,Left_Buffer_Offs
		MOV DS,Seg_Volume                ;DS:SI Right Buffer Address
		
Convert_S_16_8Mono_Loop:
       REPT 2
        INC SI                    ; Move to the first Word MSB
        LODSB                     ; Load the First Byte from the Left Buffer
		INC SI                    ; Move to the second Word MSB
		XCHG AH,AL
		LODSB                     ; Load the First Byte from the Left Buffer
		XCHG AH,AL
		STOSW                     ; Store the 2 Bytes to the Current Mix Buffer
	   ENDM
		LOOP Convert_S_16_8Mono_Loop

; More Bytes to Add ?
        XOR CX,CX
		MOV CL,B CS:[Mix_Loop1_Nb]
		JCXZ Convert_S_16_8Mono_End

Convert_S_16_8Mono_Loop2:
        INC SI                    ; Move to the first Word MSB
        LODSB                     ; Load the First Byte from the Left Buffer
		STOSB                     ; Store the 2 Bytes to the Current Mix Buffer
		LOOP Convert_S_16_8Mono_Loop2

Convert_S_16_8Mono_End:		

		DS_ASM
		RET
Convert_S_16_8Mono ENDP

; Convert Left/Right Buffer (16Bit) to Current Buffer Unsigned (8Bit) (To play a 16Bit Stereo in 8Bit)
; Need speed to mix 16Bit, not a problem if not heavily optimized

Convert_NS_16_8Stereo PROC NEAR

        MOV DX,8080h
        MOV ES,Seg_Volume                
        MOV DI,Buffer_Current_Mix_Offs   ;ES:DI Current Mix Buffer Address

        MOV CX,Buffer_Samples_Nb
        SHR CX,1
        SHR CX,1                 ;Buffer Size/4
		
		MOV AX,Right_Buffer_Offs
        SUB AX,Left_Buffer_Offs
		MOV BP,AX                        ;BP = Right_Buffer_Offs-Left_Buffer_Offs
        MOV SI,Left_Buffer_Offs
		MOV DS,Seg_Volume                ;DS:SI Right Buffer Address
        CLD
; *** DS Modified ***
Convert_NS_16_8Stereo_Loop_4:
       REPT 4              ; 4 samples per Loop
        INC SI
		MOV AH,DS:[SI+BP]  ; Read 1 Bytes from Left buffer
        LODSB              ; Read 1 Bytes from Right buffer
        XOR AX,DX
		STOSW
       ENDM
		LOOP Convert_NS_16_8Stereo_Loop_4

; More Bytes to Add ?
		MOV CL,B CS:[Mix_Loop1_Nb]
		JCXZ Convert_NS_16_8Stereo_End
		
Convert_NS_16_8Stereo_Loop_1:
        INC SI
		MOV AH,DS:[SI+BP]  ; Read 1 Bytes from Left buffer
        LODSB              ; Read 1 Bytes from Right buffer
        XOR AX,DX
		STOSW
		LOOP Convert_NS_16_8Stereo_Loop_1
		
Convert_NS_16_8Stereo_End:
		DS_ASM
        RET
Convert_NS_16_8Stereo ENDP

EndIf ; Use16Bit

;Calcul_mixage8:
;        MOV CX,Buffer_Samples_Nb     ;-- Convertir (St‚r‚o+Mixage) --
;        SHR CX,1
;        MOV SI,Buffer_Current_Mix_Offs
;        MOV DS,Seg_Volume        ;DS=Segment de la table de volume
;        MOV DX,8080h

;Boucle_Convertir_8StereoMix:
;        MOV BX,W [SI]
;        MOV AX,BX
;        SAR BL,1
;        SAR BH,1
;        ADD AH,BL
;        ADD AL,BH
;        XOR AX,DX                ;Convertir en non sign‚
;        MOV W [SI],AX
;        ADD SI,2
;        MOV BX,W [SI]
;        MOV AX,BX
;        SAR BL,1
;        SAR BH,1
;        ADD AH,BL
;        ADD AL,BH
;        XOR AX,DX                ;Convertir en non sign‚
;        MOV W [SI],AX
;        ADD SI,2
;        LOOP Boucle_Convertir_8StereoMix
;        DS_ASM

;        RET