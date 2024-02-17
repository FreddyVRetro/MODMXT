;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º           --==ðð Mod Master v2.2 ðð==--           º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteurúúúúúúúúúúúúúúúúúúúúúúúú Freddy V‚tel‚    º
;            º   Avec l'aide deúúúúúúúúúúúúúúúú Fabrice Couteau  º
;            º                                                   º
;            º   DerniŠre modificationúúúúúúúúú 24/10/1995       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
; routines diverses pour l'affichage dans Mod Master

CGAOnly    Equ Yes
EngOnly    Equ Yes

INCLUDE VGA.INC                ; inclut les constantes de la carte VGA

PUBLIC Affiche_Ecran_Texte
If CGAOnly eq No
PUBLIC Affiche_Ecran_Graphique
EndIf
PUBLIC MM_ASM_UpdateInterface
PUBLIC MMSS_Refresh_Debug

MUL160 MACRO        ;Macro Multiplication par 160
       XOR BX,BX
       MOV BH,AL
       SHR BX,1
       MOV AX,BX
       SHR BX,1
       SHR BX,1
       ADD AX,BX    ;AX=160*AL
ENDM

C_Dark    Equ 0
C_Blue    Equ 1
C_Green   Equ 2
C_Cyan    Equ 3
C_Red     Equ 4
C_Magenta Equ 5
C_Brown   Equ 6
C_LGray   Equ 7
C_Gray    Equ 8
C_LBlue   Equ 9
C_LGreen  Equ 10
C_LCyan   Equ 11
C_LRed    Equ 12
C_LMagenta Equ 13
C_Yellow  Equ 14
C_White   Equ 15

M_BoW Equ 70h
M_WoB Equ 02h
M_hW0B Equ 0Ah

Display_IntroScan DB 0
Display_Shuffle   DB 0
Display_NoteOrBar DB 0  ; Display the note / Sample or the period bar in Channels list view

introscan_msg DB 'IntroScan',0
shuffle_msg   DB 'Shuffle  ',0
;int_msg      DB 'Int',0
pause_msg     DB 'Pause',0
repeat_msg    DB 'Repeat',0

C_MSG_Off      DB 119
C_MSG_On_Intro DB 122+128
C_MSG_On_Shuff DB 126
C_MSG_On_Pause DB 127+128
C_MSG_On_Rep   DB 114
C_Grey_M_Black DB C_Gray

C_Green_M_White DB 2
C_White_M_White DB 15


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Affiche_Fonctions:  Affiche l'‚tat des fonctions          ³
;³                     IntroScan/Shuffle, Int, Pause, Repeat ³
;³     Entr‚e                                                ³
;³     Sortie                                                ³
;³     Change                                                ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If CGAOnly Eq Yes
Dy EQU 1
Else
Dy EQU 0
EndIf

Affiche_Fonctions PROC NEAR

       PUSH AX SI DI ES
       MOV AX,Seg_Video
       MOV ES,AX

       CMP Display_IntroScan,0
	   JE NotDisp_IntroScan
       MOV SI,OFFSET introscan_msg
       MOV DI,2*(3-1)+160*(4-1-Dy)
       MOV AH,C_MSG_On_Intro    ;vert pastel clignotant/blanc
       CALL WriteStrXY          ;affiche "IntroScan"
	   MOV Display_IntroScan,0  ;Display only one time
NotDisp_IntroScan:	   

       CMP Display_Shuffle,0
	   JE NotDisp_Shuffle
       MOV SI,OFFSET shuffle_msg
       MOV DI,2*(15-1)+160*(4-1-Dy)
       MOV AH,C_MSG_On_Shuff    ;jaune/blanc
       CALL WriteStrXY          ;affiche "Shuffle"
NotDisp_Shuffle:

;       MOV SI,OFFSET int_msg
;       MOV DI,2*(62-1)+160*(4-1-Dy)
;       MOV AH,116               ;rouge/blanc
;       CMP Utiliser_Interpol,1
;       JE aff_interpol
;       MOV AH,119               ;blanc/blanc -> invisible
; aff_interpol:
;       CALL WriteStrXY          ;affiche "Int"

       MOV SI,OFFSET pause_msg
       MOV DI,2*(67-1)+160*(4-1-Dy)
       MOV AH,C_MSG_On_Pause    ;blanc brillant/blanc clignotant
	   CMP MMSS_Pause,1   
       JE aff_pause
       MOV AH,C_MSG_Off         ;blanc/blanc -> invisible
	   MOV AL,219               ;Plain char
	   MOV CX,5
	   REP STOSW
	   JMP aff_pause_end
aff_pause:
       CALL WriteStrXY          ;affiche "Pause"
aff_pause_end:

       MOV SI,OFFSET repeat_msg
       MOV DI,2*(74-1)+160*(4-1-Dy)
       MOV AH,C_MSG_On_Rep      ;vert/blanc
       DS_TP
       CMP Boucler_MOD,1        ;fonction Repeat active?
       DS_ASM
       JE aff_repeat            ;oui
       MOV AH,C_MSG_Off         ;blanc/blanc -> invisible
	   MOV AL,219               ;Plain char
	   MOV CX,6
	   REP STOSW
	   JMP aff_repeat_end
aff_repeat:
       CALL WriteStrXY          ;affiche "Repeat"
aff_repeat_end:

       POP ES DI SI AX
       RET
Affiche_Fonctions ENDP


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   MM_ASM_UpdateInterface   Display the Volume / Pitch Lines       ³
;³     Entr‚e                                                ³
;³     Sortie                                                ³
;³     Change                                                ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ancien_aff_centre DB 0

pas DB +1

MM_ASM_UpdateInterface PROC FAR
      PUSH BP
	  PUSH DS
      DS_ASM
      ES_ASM

      CALL Affichage_texte

      CALL Gerer_Touches
  
      POP DS
	  POP BP
      RET
MM_ASM_UpdateInterface ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Affiche_ecran_texte  Initialize the Text Mode           ³
;³   Called by the Turbo Pascal                              ³
;³     Entr‚e: aucune                                        ³
;³     Sortie: aucune                                        ³
;³     Change: AX,CX,SI,DI                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Str_Smp_Chn DB 'samples   -     voices',0

Affiche_ecran_texte PROC FAR
           PUSH BP
           PUSH DS
		   
           DS_ASM

           MOV AX,Seg_Video  ;Segment_texte
           MOV ES,AX

           DS_TP

           MOV SI,OFFSET Nom_fichier     ;chemin+nom fichier au format ASCIIZ (Externe)
           MOV DI,2*(2-1)+160*(2-1)
		   MOV AH,112
		   LODSB
		   CMP AL,0
		   JE Pas_de_Titre
		   XOR CX,CX
		   MOV CL,AL
Loop_Title_Str:
           LODSB
		   STOSW
		   LOOP Loop_Title_Str
Pas_de_Titre:

           MOV AH,Programme
           DS_ASM

           CMP AH,1                 ;y a-t-il un programme?
           JNE pas_programme        ;non
           MOV DI,2*(16-1)+160*(2-1)
           MOV AX,112*256+'('
           STOSW
           DS_TP
           MOV AX,Numero_Module
           DS_ASM
		   MOV BL,112
           CALL BIA16
           MOV AX,112*256+'/'
           STOSW
           DS_TP
           MOV AX,Longueur_prog
           DS_ASM
		   MOV BL,112
           CALL BIA16
           MOV AX,112*256+')'
           STOSW

pas_programme:
affiche_textes:
           DS_ASM

           CALL Affiche_Fonctions

           CMP MUS_OPLStream,1 ; Skip module infos Display if Module
	       JE @@AET_No_MusInfos

           MOV AH,7             ;blanc/noir

If EngOnly Eq No
           MOV SI,OFFSET instr_voies_msg
           DS_TP
           CMP Langue,Francais
           DS_ASM
           JE aff_instr_msg
EndIf		   
           MOV SI,OFFSET Str_Smp_Chn
aff_instr_msg:
           MOV DI,2*(30-1)+160*(6-1-Dy)
           CALL WriteStrXY        ;affiche instr_voies_msg

           MOV AX,256*3+'/'
           MOV DI,2*(39-1)+160*(7-1-Dy)
           STOSW                        ;separation Position XXX/XXX

           MOV BH,1                     ;affiche dizaines nulles
           MOV BL,3                     ;cyan/noir
           MOV AL,Sequence_Len          ;nombre de positions
           ADD DI,2
           CALL BIA8                    ;affiche nombre de positions

           MOV BL,7                     ;blanc/noir
           MOV AL,Nb_Samples_Loaded     ;nombre d'instruments
           MOV AH,Nb_samples            ;nombre d'instruments charg‚s
           CMP AH,AL
           JE samples_tous_charges      ;Nb_samples=Nb_Samples_Loaded
           ADD BL,128                   ;pas tout charg‚ -> clignote
samples_tous_charges:
           MOV DI,2*(27-1)+160*(6-1-Dy)
           MOV BH,0                     ;n'affiche pas dizaines nulles
           CALL BIA8                    ;affiche nombre d'instruments

           MOV BL,7                     ;blanc/noir
           MOV DI,2*(44-1)+160*(6-1-Dy)-2
           MOV AL,Ch_Number
           CALL BIA8                    ;affiche nombre de voies

@@AET_No_MusInfos:

           POP DS
		   POP BP
           RET
Affiche_ecran_texte ENDP

Display_MUS_Infos PROC Near

           RET
Display_MUS_Infos Endp

; Display the Global Volume bar
Display_Volume_Bar Proc
      MOV BL,Volume_total     
	  CMP BL,64
	  JB @@VolOk
	  MOV BL,63
@@VolOk:
	  SHR BL,1
	  SHR BL,1 ; BL=0 to 15
	  
      XOR CX,CX
      MOV CL,BL
      INC CL
      MOV AX,11*256+'Ü'
	  REP STOSW
      MOV CL,15
      SUB CL,BL
      MOV AH,8                ; Change Color
V_Boucle_barre_e:
      OR CL,CL
      JZ V_Fin_boucle_barre_e ; Full First Color
	  REP STOSW
V_Fin_Boucle_barre_e:
      RET
Display_Volume_Bar Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Affichage_texte:  Gere l'affichage en mode texte        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Affichage_texte PROC NEAR
      MOV AX,Seg_Video  ;Segment_texte
      MOV ES,AX

      CALL Display_TopInfos

; *****  Display the Center  *********

      DS_TP
      MOV AL,Center_Display
      DS_ASM
	  CMP AL,CD_Debug
      JE Aff_Debug
      CMP AL,CD_Part
      JE Aff_part   
      OR AL,AL	  
      JE Aff_marques
	  CMP AL,CD_Bar
	  JE Display_MultipleChannels    ; 4 -> Multi Channels Bar View
	  
      JMP DisplayCenter_Help         ; 2 -> Help

Aff_Part:

	  CMP Type_Module,T_MON
	  JE Fin_choix_centre
      JMP DisplayCenter_Partition4  ; 1 -> Partition View
	 
Aff_marques:

	  CMP Type_Module,T_MON
	  JE Fin_choix_centre
      JMP DisplayCenter_Samples     ; 0 -> Samples Name View
	  
Aff_Debug:                          ; 3 -> Debug View
	  CALL DisplayCenter_Debug

Fin_choix_centre:
      RET
Affichage_texte ENDP


; ********************************************************
; ** TOP : Display the Module progress infos (Tempo...) **
; ********************************************************
Display_TopInfos Proc Near

	  CMP Type_Module,T_MON
	  JE Not_Display_Chrono

; Display the Chrono
	  
      DS_TP
      MOV AL,TP_Chrono_min
      MOV DH,TP_Chrono_sec
      DS_ASM
	  
      MOV DI,2*(74-1)+160*(2-1)
      MOV BH,1           ;affiche dizaines nulles
      MOV BL,112         ;noir/blanc
      CALL BIA8
      MOV AX,112*256+':'
      STOSW
      MOV AL,DH
      CALL BIA8
      MOV AL,' '
Not_Display_Chrono:

      CMP MUS_OPLStream,1 ; Skip module infos Display if Stream File (No Pattern/Note infos)
      JE No_Bar_Top

      MOV AL,Mix_ChLimit_Nb
	  CMP AL,32
	  JAE No_Display_Limit
	  CMP AL,2
	  JB No_Display_Limit
      MOV DI,2*(48-1)+160*(25-1)
	  MOV BL,16+4 ; Blue / Red
      CALL BIA8                 ;affiche le volume general	  
No_Display_Limit:

      MOV DI,2*(35-1)+160*(9-1-Dy)
      CALL Display_Volume_Bar

; * Sequence Order / Note
	  
      MOV DI,2*(36-1)+160*(7-1-Dy)
      MOV AX,256*3+' '
      STOSW                     ;efface centaines nøposition
      MOV BL,3                  ;cyan/noir
      MOV AL,C_Sequence
      CALL BIA8                 ;affiche nøposition
      MOV AL,C_Row
      MOV DI,2*(50-1)+160*(7-1-Dy)
      CALL BIA8                 ;affiche nønote

; * Tempo / BPM
      MOV DI,2*(32-1)+160*(8-1-Dy)
      MOV AX,256*3+' '
      STOSW
      MOV AL,Tempo
      CALL BIA8                 ;affiche le tempo
      MOV DI,2*(41-1)+160*(8-1-Dy)
      MOV AL,BPM
      CALL BIA8                 ;affiche les BPM

      MOV DI,2*(50-1)+160*(8-1-Dy)
      MOV AL,Volume_general
      CALL BIA8                 ;affiche le volume general

      DS_TP
      CMP Center_Display,CD_Bar
	  DS_ASM
	  JE No_Bar_Top     

      CALL Barre_Pitch_4
      CALL Barre_Periode

No_Bar_Top:
      RET
Display_TopInfos Endp

; **********************************************************
; ** Center : Display multiple channels bar in the Center **
; **********************************************************
Display_MultipleChannels PROC Near

      DS_TP
      CMP Change_aff_centre,1
      DS_ASM
      JE D_Multi_CleanScreen
      JMP D_Multi_NoCleanScreen
D_Multi_CleanScreen:

      CALL Eff_centre_ecran
	  
	  CALL Display_Names_Top ; Display the samples names in the Top Windows
	  
	  DS_TP
	  MOV Change_aff_centre,0
      DS_ASM
	  
D_Multi_NoCleanScreen:            ; 4 -> Channels List
     
	 CALL Barre_Pitch_18
	 
     RET
Display_MultipleChannels ENDP

Display_Names_Top Proc Near

; Left Part
      MOV DX,4
      MOV DI,2*(3-1)+160*(5-1)
      XOR BX,BX
Display_SampleTop:
;	  CALL Display_SMP_Instr_LoadedDot
	  MOV CX,21
      CALL Display_SMP_Instr_Name
      ADD DI,2*(80-21)
      INC BL
      DEC DX
      JNZ Display_SampleTop

; Right part
      MOV DX,4
      MOV DI,2*(55-1)+160*(5-1)
Display_SampleTop2:
;	  CALL Display_SMP_Instr_LoadedDot
      CALL Display_SMP_Instr_Name24
      ADD DI,2*(80-24)
      INC BL
      DEC DX
      JNZ Display_SampleTop2

     RET
Display_Names_Top EndP

; *************************************************************
; Center: Display the instrument list in the Center (2 columns)
; *************************************************************
Display_Names_Center PROC NEAR  ;Utilise les structures d'instruments

; Left Part
      MOV DX,14
      MOV DI,2*(15-1)+160*(YInst-1)-116
      XOR BX,BX
Display_SampleCenter:
      ADD DI,2*(80-24)
	  CALL Display_SMP_Instr_LoadedDot
      CALL Display_SMP_Instr_Name24	  
      INC BL
      DEC DX
      JNZ Display_SampleCenter

; Right part
      MOV DX,14
      MOV DI,2*(54-1)+160*(YInst-1)-116
Display_SampleCenter2:
      ADD DI,2*(80-24)
	  CALL Display_SMP_Instr_LoadedDot
      CALL Display_SMP_Instr_Name24
      INC BL
      DEC DX
      JNZ Display_SampleCenter2

Fin_Aff_Samp:

; Display the vertical line	  
      MOV AX,7*256+'³'
      MOV DI,2*(40-1)+160*(10-1)
      MOV CX,25-12+1	  
ligne_vert:
      STOSW
      ADD DI,158
      LOOP ligne_vert

      RET
Display_Names_Center ENDP

; Display The Sample or Instrument default sample Load State:
; Nothing   : No Sample
; Green dot : Loaded
; Red dot   : Not Loaded
;  ES:DI Video Address Pointer
;  BX : Sample/Instrument number

Display_SMP_Instr_LoadedDot PROC Near

	  MOV AX,BX	 
      CMP AL,Nb_Sample_Instr
      JAE Display_LoadedDot_End

	  PUSH ES
	  PUSH DI

; Check if there is a sample Loaded
      CMP Type_Module,T_XM          ; If XM, Instrument not sample
      JNE Disp_Dont_Read_XMInstr
	  
	  Get_InstPtr_ESDI

      CMP ES:ISamples_Total[DI],0
	  JE Disp_NoSample

      XOR AX,AX
	  MOV AL,ES:ISample_Nb[DI]  ; BL = Default Instrument sample number	 

Disp_Dont_Read_XMInstr:
	  
      Get_SMPPtr_ESDI AX
		
      TEST ES:SInfo[DI],M_Adlib
      JNZ Disp_SmpIsAdlib
	  
      CMP w ES:SLen[DI],0
	  JE Disp_NoSample
	  
      MOV AH,C_green
	  TEST ES:SInfo[DI],M_Charge
	  JNZ  Disp_SmpIsLoaded      ; Loaded > GREEN
      MOV AH,C_red               ; Not Loaded > RED
Disp_SmpIsLoaded:
	  
	  POP DI
	  POP ES

      MOV AL,07h ; Dot Character
      SUB DI,2
      STOSW      ; Display
	  
      RET
	  
Disp_SmpIsAdlib:
Disp_NoSample:

	  POP DI
	  POP ES
Display_LoadedDot_End:
      RET
Display_SMP_Instr_LoadedDot Endp

;  ES:DI Video Address Pointer
;  BX : Sample number
;  Change : DS, SI, CX, AX

; Call Display_SMP_Instr_Name with CX: Nb of Char to display

Display_SMP_Instr_Name24 PROC Near

	  MOV CX,24

Display_SMP_Instr_Name:
      CMP BL,Nb_Sample_Instr
      JAE Display_Sample_End
	  
      MOV AX,CS:W [PtrInstrNameTable+2] ; Read the Instrument names Segment (Offset=0)

      OR AX,AX           ; Pointer 0 > No Sample name
	  JZ Display_Sample_End
      MOV DS,AX

      PUSH BX
	  SHL BX,1
	  SHL BX,1	  
	  SHL BX,1
	  MOV SI,BX
	  SHL BX,1
	  ADD SI,BX         ; Name Offset=Sample number * 24
	  POP BX
      MOV AH,3          ; cyan/noir (instrument)	  
DS_Loop:
      LODSB
      STOSW
	  LOOP DS_Loop
	  
      DS_ASM            ; DS was changed, restore it
      RET

Display_Sample_End:
      ADD DI,24*2
      RET
Display_SMP_Instr_Name24 ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   DisplayCenter_Debug   Affiche les Infos de Debug              ³
;³     Entr‚e: aucune                                        ³
;³     Sortie: aucune                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Debug_msg DB 'DEBUG',0
Debug_msg2 DB 'F:       RF:       SB_F:     BSize:                 SB Type:   CMD:',0
Debug_Msg3 DB 'Channels to Mix:   Max:    MinVol:    / Buffers  ',0
Debug_Msg4 DB 'IRQCnt:      Mixed Buff Cnt:      Cnt1:      Cnt2:      Cnt3:      MixMax3:',0 

Debug_Msg6 DB 'Smp VP  VF  C4Ad  Nt Per    Incr    Vibrato   Rtr Cmp Pan Rel   ',0



MM_Display_Debug Proc Near   ; Force the Debug Display and Display the Debug Screen
      DS_TP
      MOV Change_aff_centre,1
	  MOV Center_Display,3
      DS_ASM

      MOV AX,Seg_Video  ;Segment_texte
      MOV ES,AX
	  CALL DisplayCenter_Debug
	  RET
MM_Display_Debug Endp

MMSS_Refresh_Debug Proc
      PUSH BP
	  PUSH DS
	  
	  CALL DisplayCenter_Debug
	  
      POP DS
	  POP BP
      RET
MMSS_Refresh_Debug Endp

DisplayCenter_Debug PROC NEAR
      DS_TP
      CMP Change_aff_centre,1
      DS_ASM
      JE Debug_Effacer_Centre
      JMP Pas_Effacer_Centre
Debug_Effacer_Centre:

      CALL Eff_centre_ecran

Debug_Affiche_Textes:      
	  MOV AH,C_LCyan                ; jaune/noir
      MOV SI,OFFSET Debug_msg
      MOV DI,2*(36-1)+160*(Ypart-1)
      CALL WriteStrXY

	  MOV AH,C_LCyan                   ; jaune/noir
      MOV SI,OFFSET Debug_msg2
      MOV DI,2*(3-1)+160*(1+Ypart-1)
      CALL WriteStrXY
	  
	  MOV AH,C_LCyan                   ; jaune/noir
      MOV SI,OFFSET Debug_msg3
      MOV DI,2*(3-1)+160*(2+Ypart-1)
      CALL WriteStrXY
	  
	  MOV AH,C_LCyan                   ; jaune/noir
      MOV SI,OFFSET Debug_msg6
      MOV DI,2*(3-1)+160*(5+Ypart-1)
      CALL WriteStrXY
	 
	  MOV AH,C_LCyan                   ; jaune/noir
      MOV SI,OFFSET Debug_msg4
      MOV DI,2*(3-1)+160*(3+Ypart-1)
      CALL WriteStrXY
	 
; Line 1	 
	 
	  MOV DI,2*(10-1)+160*(1+Ypart-1)
      MOV AX,Out_Frequency
      MOV BH,C_White
      CALL WriteXY_Dec16
	  
	  MOV DI,2*(20-1)+160*(1+Ypart-1)
      MOV AX,Real_Frequency
      MOV BH,C_White                   ; Jaune/Noir
      CALL WriteXY_Dec16
	  
	  MOV DI,2*(30-1)+160*(1+Ypart-1)
      XOR AX,AX
	  MOV AL,SB_DMA_Frequency
      MOV BH,C_White                 ;Jaune/Noir
      CALL WriteXY_Dec16	  
	  
      MOV DI,2*(42-1)+160*(1+Ypart-1)
      MOV AX,Buffer_Samples_Nb
      MOV BH,C_White                 ;Jaune/Noir
      CALL WriteXY_Dec16	  

	  MOV DI,2*(63-1)+160*(1+Ypart-1)
      MOV BL,C_White            ;chiffres cyan/noir
      MOV AL,Type_SB
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche

	  MOV DI,2*(70-1)+160*(1+Ypart-1)	  
      MOV AL,Frequence_DSP
      MOV BH,C_White              ;chiffres Blanc
      CALL WriteXY_Hex8           ;affiche

	  MOV DI,2*(74-1)+160*(1+Ypart-1)	  
      MOV AL,Commande_DSP
      MOV BH,C_White              ;chiffres Blanc
      CALL WriteXY_Hex8           ;affiche


Pas_Effacer_Centre:
      DS_TP
      MOV Change_aff_centre,0
      DS_ASM

;* Ligne 2	  

	  MOV DI,2*(19-1)+160*(2+Ypart-1)
      MOV BL,C_White
	  MOV AL,Mix_Channels_Nb
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche
 
 	  MOV DI,2*(19-1)+160*(2+Ypart-1)
      MOV BL,C_Red                  ;chiffres rouge
      MOV AL,Mix_Channels_Nb_MAX	  
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche

      ;MinVol in IRQ

;* Line 3

      MOV DI,2*(14-1)+160*(3+Ypart-1)
      MOV AX,IRQ_Cnt
      MOV BH,C_White
      CALL WriteXY_Dec16

      MOV DI,2*(46-1)+160*(3+Ypart-1)
      MOV AX,Slow_Mix1_Cnt
      MOV BH,C_Green_M_White
      CALL WriteXY_Dec16
	  
   	  MOV DI,2*(78-1)+160*(3+Ypart-1)
      MOV BL,C_Red                  ;chiffres rouge
      MOV AL,Max_Mixed3
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche

;* Line 3

      MOV DI,2*(5-1)+160*(4+Ypart-1)  ; Volume / Buffer 
      MOV AX,Seg_Volume
      MOV BH,C_White
      CALL WriteXY_Hex16
	  
      MOV DI,2*(10-1)+160*(4+Ypart-1)  ; Buffer Offset
      MOV AX,Buffer_Start_Offs
      MOV BH,C_White
      CALL WriteXY_Hex16	  
	  
      MOV DI,2*(16-1)+160*(4+Ypart-1)  ; Buffer End Offset
      MOV AX,Buffers_End_Offs
      MOV BH,C_White
      CALL WriteXY_Hex16	

      MOV DI,2*(22-1)+160*(4+Ypart-1)
      MOV AX,Buffer_Byte_Size
      MOV BH,C_White
      CALL WriteXY_Hex16

      MOV DI,2*(28-1)+160*(4+Ypart-1)
      MOV AX,Buffers_Total_Size_Byte
      MOV BH,C_White
      CALL WriteXY_Hex16

      MOV DI,2*(34-1)+160*(4+Ypart-1)  ; Output Current Offset
      MOV AX,Buffer_Current_Out_Offs	  
      MOV BH,C_White
      CALL WriteXY_Hex16  
	  
      MOV DI,2*(48-1)+160*(4+Ypart-1)  ; Output Current Offset
      MOV AL,DMA_Buffers_Max_NB	  
      MOV BH,C_Red
      CALL WriteXY_Hex8	  

;      MOV DI,2*(46-1)+160*(4+Ypart-1)  ; Output Current Offset
;      MOV AL,DMA_Buffer_Mixing  
;      MOV BL,C_White
;      MOV BH,15                 ;affiche dizaines nulles
;      CALL BIA8

;      MOV DI,2*(2-1)+160*(4+Ypart-1)  ; Partition Segment
;      MOV AX,C_Pattern_Seg
;      MOV BH,15
;      CALL WriteXY_Hex16

;      MOV DI,2*(10-1)+160*(4+Ypart-1)  ; Compressed Partition Index
;      MOV AX,C_PartIndex
;      MOV BH,15
;      CALL WriteXY_Dec16

 ; C_Pattern_Seg

;	   MOV DI,2*(5-1)+160*(3+Ypart-1)	
;      MOV BL,4                  ;chiffres rouge
;      MOV AL,Cmpt_Tempo
;      MOV BH,15                 ;affiche dizaines nulles
;      CALL BIA8                 ;affiche   

;      MOV DI,2*(6-1)+160*(4+Ypart-1)
;      MOV AX,Offset_Tampon1
;      MOV BH,15                 ;Jaune/Noir
;      CALL WriteXY_Dec16

;      MOV DI,4*(6-1)+160*(4+Ypart-1)
;      MOV AX,BPM_Val
;      MOV BH,15                 ;Jaune/Noir
;      CALL WriteXY_Dec16

;      MOV DI,4*(10-1)+160*(4+Ypart-1)
;      MOV AX,BPM_Cnt
;      MOV BH,15                 ;Jaune/Noir
;      CALL WriteXY_Dec16

;      CALL AffDebug_Tick

; ************ Affiche infos debug Voies **************
	  
	  XOR CX,CX
	  MOV CL,Ch_Number
	  CMP CL,8
	  JBE Nb_Ch_DebugOk
	  MOV CL,8
Nb_Ch_DebugOk:
	  XOR BX,BX
	  MOV BL,N_Voie_Aff
	  XOR BP,BP
  	  MOV DI,2*(3-1)+160*(6+Ypart-1)

Boucle_Aff_Debug_Voies:
      PUSH CX


      MOV AL,CH_Smp_Pla[BX]
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8
      POP BX

      ADD DI,4

      MOV AL,Ch_Part_Vol[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8
      POP BX
	  POP DI

      ADD DI,8

      MOV AL,Ch_Final_Vol[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8
      POP BX
      POP DI

      ADD DI,8

      MOV AX,CH_Per_part[BP]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex16          ;affiche
      POP BX
      POP DI

      ADD DI,6

	  PUSH DI
	  PUSH BX     
      MOV AX,VC4Spd[BP]
      MOV BH,C_White
      CALL WriteXY_Dec16	 
      POP BX
      POP DI
	  
      ADD DI,6

      MOV AL,Ch_Note[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	
	  
	  ADD DI,6
	  
      MOV AX,CH_Per_part[BP]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex16          ;affiche
      POP BX
      POP DI	  

      ADD DI,12

      MOV AL,VPart_entiere[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI

      ADD DI,4
	  
	  MOV AL,VPart_decimale[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI

      ADD DI,4
	  
	  MOV AL,VPart_decimale2[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI
	  
      ADD DI,10

      MOV AL,Vitesse_vib[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI

      ADD DI,6
	  
      MOV AL,Amplitude_vib[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI

      ADD DI,6	  

      MOV AL,Vibr_Index[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI
	  
	  ADD DI,8

      MOV AL,Retrig_V_Tr[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	  

      ADD DI,8
	   
      MOV AL,Cmpt_Commande[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI

      ADD DI,8
	  
      MOV AL,CH_Panning[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	  
	  
	  ADD DI,8

      MOV AL,V_Rel_Note[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI
	 
	  ADD DI,8
	 
      MOV AL,Ch_Smp_Tick_Cnt[BX] 
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	  
	  
	  ADD DI,8
	 
      MOV AL,Ch_Priority[BX] 
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	  
	  
	  ADD DI,8
	  
; Display the On / Off Button

      MOV AX,C_yellow*256+07h
      TEST Ch_Control[BX],CM_FPause ; Forced Pause > Brown
	  JNZ Dbg_DCLoop_ChOnOff
      MOV AH,C_green
      TEST Ch_Control[BX],CM_Stopped
	  JZ Dbg_DCLoop_ChOnOff
      MOV AH,C_Red
      TEST Ch_Control[BX],CM_FStop  ; Forced Stop > Red
	  JNZ Dbg_DCLoop_ChOnOff
	  MOV AL,' '
Dbg_DCLoop_ChOnOff:
      STOSW

	  ADD DI,2
	 
      MOV AL,Mix_Channel_List[BX]
	  PUSH DI
	  PUSH BX
      MOV BH,C_White
      CALL WriteXY_Hex8           ;affiche
      POP BX
      POP DI	
	  
	  
;      MOV AX,Per0_arp[BP]
;	   PUSH DI
;	   PUSH BX
;      MOV BH,15                 ;chiffres Blanc
;      CALL WriteXY_Hex16          ;affiche
;      POP BX
;      POP DI		  

;	   ADD DI,10

;      MOV AX,Per1_arp[BP]
;      PUSH DI
;      PUSH BX
;      MOV BH,15                 ;chiffres Blanc
;      CALL WriteXY_Hex16          ;affiche
;      POP BX
;      POP DI

;      ADD DI,10

;      MOV AX,Per2_arp[BP]
;	   PUSH DI
;	   PUSH BX
;      MOV BH,15                 ;chiffres Blanc
;      CALL WriteXY_Hex16          ;affiche
;      POP BX
;      POP DI
       
      ADD DI,160-16-8-6-6-12-4-4-8-6-6-10-6-8-8-8-8-8-2-10
  
	  POP CX
	  INC BX
	  INC BP
	  INC BP
	  DEC CX
	  JZ Fin_Boucle_Aff_Debug_Voies
	  JMP Boucle_Aff_Debug_Voies
	  
Fin_Boucle_Aff_Debug_Voies:
	  
      RET
DisplayCenter_Debug ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   DisplayCenter_Partition4   Affiche la partition         ³
;³     Entr‚e: aucune                                        ³
;³     Sortie: aucune                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

YPart Equ 10
YInst Equ 10

Position_Centre EQU 6
LigneFin EQU 23

N_Voie_aff DB 0

DP_PrevPattern   DB 0  ; Mettre a FF au depart
Disp_CurrentLine DB 0  ; Screen Line
Disp_CurrentRow  DB 0  ; Pattern Row
CouleurFond      DB 0

; Partition Values to display
Disp_Note     DB 0
Disp_Instr    DB 0
Disp_Command  DB 0
Disp_Param    DB 0

Disp_EmptyChannelCount DB 0

Anc_posit_note DB 0
Disp_LastChannel DB 0

DisplayCenter_Partition4 PROC NEAR

      DS_TP
      CMP Change_aff_centre,1
      DS_ASM
      JNE Pas_aff_Part
      CALL Eff_centre_ecran
      CALL Affiche_tableau_Partition
	  MOV DP_PrevPattern,0FFh
      DS_TP
      MOV Change_aff_centre,0
      DS_ASM
      JMP SHORT Commencer_aff

Pas_aff_Part:
      MOV AL,C_Row
      CMP AL,Anc_posit_note
      JNE Commencer_aff         ; Changer l'affichage si nouvelle note
      RET

Commencer_aff:
      MOV Anc_Posit_note,AL
 
 ;* Display the Pattern Number
      MOV DI,2*(3-1)+160*(YPart-1)
      MOV AX,256*93+' '
      STOSW
      MOV BL,93                 ; Orange/marron fonce
      MOV BH,1                  ; Affiche dizaines nulles
      MOV AL,C_pattern
      CALL BIA8                

      MOV Disp_CurrentLine,YPart
      MOV AL,C_Row
      CMP AL,Position_Centre 
      JAE Pas_Effacer_Debut	  
      MOV DL,Position_Centre
      SUB DL,AL                 ; DL -> Nb of Lines to Clean
	  CALL DP_CleanLine         ; Clean the first lines if nothing to display
      MOV AL,Position_Centre	; Start Display at the Row 0						
Pas_Effacer_Debut:

	  SUB AL,Position_Centre    ; AL, Start Display at Playing Row - Center Position
      MOV Disp_CurrentRow,AL

      CALL Display_Part_Lines

      MOV DL,LigneFin
	  CMP DL,Disp_CurrentLine
	  JBE Pas_Effacer_Fin
	  SUB DL,Disp_CurrentLine
	  CALL DP_CleanLine   ; Cleanup the last lines
Pas_Effacer_Fin:
      MOV AX,Seg_Video  ;Segment_Texte
      MOV ES,AX

      RET
DisplayCenter_Partition4 ENDP

; Disp_CurrentRow    : Row to Display
; Disp_CurrentLine   : Line where we display 

; Disp_PrevRow       : Previously displayed Row
; Disp_PrevRowOffset : Begining of the previous Row Offset

Display_Part_Lines Proc Near
Boucle_Lignes_Partition:
      MOV AX,Seg_Video  ;Segment_Texte
      MOV ES,AX
      MOV DI,2*(2-1)            ;
      MOV AL,Disp_CurrentLine   ;  Calcul de la position actuelle
      MUL160                    ; 
      ADD DI,AX                 ;

      MOV CouleurFond,0*16      ;Black
      CMP Disp_CurrentLine,YPart+Position_Centre     ;ligne du milieu (active) ?      
      JNE pas_changer_couleur
      MOV CouleurFond,5*16      ;Purple

pas_changer_couleur:
; * Display the Row Number 
      MOV AX,256*3+'³'
      OR AH,CouleurFond
      STOSW
      MOV AL,' '
      STOSW

      MOV BL,3                  ;chiffres cyan/noir
      OR BL,CouleurFond
      MOV AL,Disp_CurrentRow
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche le nø de la note

      MOV AX,256*3+' '
      OR AH,CouleurFond
      STOSW
      MOV AL,'³'
      STOSW

; Read the Partition
      	  
	  MOV ES,C_Pattern_Seg
      CALL DP_GetPatternOffset
	  MOV Disp_EmptyChannelCount,0	  
	  
      MOV AL,4
      CMP Ch_Number,4
      JAE Disp_Part_4Channels	  
      MOV AL,Ch_Number
Disp_Part_4Channels:
	  ADD AL,N_Voie_aff
	  MOV Disp_LastChannel,AL

      XOR BX,BX
Boucle_affiche_voies:
      PUSH BX
	  
      CALL Disp_ReadPartChannel
	  
	  CMP BL,N_Voie_aff
	  JB No_Display_Channel_Partition
	  
      CALL Displ_Partition_4
No_Display_Channel_Partition:

      POP BX
	  INC BL
	  CMP BL,Disp_LastChannel 
      JNE Boucle_affiche_voies

      INC Disp_CurrentRow
      INC Disp_CurrentLine
      MOV AL,Disp_CurrentRow
      CMP AL,C_Patt_Length
      JE Fin_Boucle_Lignes_Partition

      CMP Disp_CurrentLine,LigneFin
	  JE  Fin_Boucle_Lignes_Partition
      JMP Boucle_Lignes_Partition

Fin_Boucle_Lignes_Partition:
      RET
Display_Part_Lines ENDP

; ES:[SI] Current Pattern Data Position (Compressed or not)
; BL : Channel Nb (0 to 31)
Disp_ReadPartChannel Proc Near

      MOV W Disp_Note,0     ; Clean Note + Instrument
      MOV W Disp_Command,0  ; Clean Command + Param

      CMP Pattern_Vide,1  ;Pattern vide => Mettre 0 !!!
      JNE Disp_Read_Part
	  
      XOR AH,AH
	  MOV AL,Note_Size
      ADD SI,AX           ;Nouvelle Voie	  
      RET
	  
Disp_Read_Part:

; Test if Compressed
      CMP CP_Pattern,0
      JNE Disp_ReadCompressedPattern

; Read the partition value (Uncompressed)
	  MOV CL,Po_Note       ; ES:[SI]
      MOV Disp_Note,CL
      MOV CL,Po_Instrument
      MOV Disp_Instr,CL
      MOV AL,Po_Command
      MOV AH,Po_Param
      MOV Disp_Command,AL
      MOV Disp_Param,AH
	  
      XOR AH,AH
	  MOV AL,Note_Size
      ADD SI,AX           ;Next Channel
	  RET

Disp_ReadCompressedPattern:
; Read the partition value (Uncompressed)
	  
	   TEST BL,BL
	   JNZ Disp_NotFirstChannel
	   
	   MOV AL,ES:[SI]              ; ** Read the Index Delta to the next channel
	   INC SI
	   TEST AL,AL
	   JNZ Disp_NotFirstChannel    ; If not 0, the value is ignored
	   MOV AL,Ch_Number            ; ** The full Row is empty
	   DEC AL
	   MOV Disp_EmptyChannelCount,AL  ; Index Delta = 0 -> All the Channels are empty
	   RET
	   
Disp_NotFirstChannel:	 

       CMP Disp_EmptyChannelCount,0   ; ** Check if next Channel is empty
	   JE  Disp_NoEmptyChannel        ; Empty channels counter is not 0 -> Skip
	   DEC Disp_EmptyChannelCount     ; Next Channel is empty
	   RET
	   
Disp_NoEmptyChannel:	

	   MOV AL,ES:[SI]            ; ** Read the Compression Mask or Note (Like FT2 Format)
	   TEST AL,80h               ; Check if the values are compressed
	   JZ Disp_AllDataPresent

       MOV DH,AL                 ; Move the Compression Mask to DL
	   SHL DH,1
	   SHL DH,1
	   JNC Disp_ChannelNotEmpty
	   ; Channel Empty -> read the Nb of Empty Channels
	   AND AL,00111111b
	   MOV Disp_EmptyChannelCount,AL
	   INC SI
	   RET
	   
Disp_ChannelNotEmpty:             ; ** Read Compressed Values
       INC SI
       XOR DL,DL                ; Not Empty
; Test Note
       SHL DH,1
	   JNC Disp_TestInstr
	   MOV AL,ES:[SI]
	   MOV Disp_Note,AL
	   INC SI
Disp_TestInstr:
; Test Instrument
       SHL DH,1
	   JNC Disp_TestCmd
	   MOV AL,ES:[SI]
	   MOV Disp_Instr,AL
	   INC SI
Disp_TestCmd:
; Test Command
       SHL DH,1
	   JNC Disp_TestParam
	   MOV AL,ES:[SI]
	   MOV Disp_Command,AL
	   INC SI
Disp_TestParam:
; Test Parameter
       SHL DH,1
	   JNC Disp_TestVol
	   MOV AL,ES:[SI]
	   MOV Disp_Param,AL
	   INC SI
Disp_TestVol:
; Test Volume
       SHL DH,1
	   JNC Disp_TestEnd
;	   MOV AL,ES:[SI]
;	   MOV Disp_Volume,AL
	   INC SI
Disp_TestEnd:

       RET
	   
Disp_AllDataPresent:             ; ** Read Uncompressed values
       MOV AX,W ES:[SI]        ; Read Note + Instrument
	   MOV W Disp_Note,AX
       MOV AX,W ES:[SI+2]      ; Read Command + Param
	   MOV W Disp_Command,AX

       XOR DL,DL               ; Not Empty
	   ADD SI,5

       RET
Disp_ReadPartChannel Endp


	  ; Disp_CurrentRow
	  ; Disp_Prev
DP_GetPatternOffset Proc Near

 	  MOV AL,Disp_CurrentRow
	  TEST AL,AL
      JNZ DP_RowNotNull
      XOR SI,SI
      RET	  
DP_RowNotNull:
; Test if Compressed
      CMP CP_Pattern,0
      JNE Disp_Do_Compressed_Change_Row

; ** Not Compressed **	

      XOR AH,AH
      XOR BH,BH
      MOV BL,Note_Size
      MUL BL
      MOV BL,Ch_Number_patt
      MUL BX             ;Position dans la partition
                         ;=Taille_note*Ch_Number_patt (4/5 octets par voie)
      MOV SI,AX
      RET
	  
Disp_Do_Compressed_Change_Row:
      XOR SI,SI
      XOR AX,AX
      XOR CX,CX

      PUSH DS
      MOV CL,Disp_CurrentRow
      MOV DS,C_Pattern_Seg   ;C_Pattern_Seg Segment du pattern actuel
Disp_Do_Search_RowOffset:
      LODSB                  ; Read the Delta to the next Row-1
      ADD SI,AX
      Loop Disp_Do_Search_RowOffset
      POP DS

      RET
DP_GetPatternOffset Endp

; Display the Instrument Nb, Note, Command, Command Param
; DI : Currect Screen Position
Displ_Partition_4 PROC NEAR
       PUSH SI ES
       MOV AX,Seg_Video  ;Segment_Texte
       MOV ES,AX

       CMP Disp_Instr,0         ;instrument<>0 ?
       JNZ Aff_instru           ;oui
       MOV AX,0*256+' '
       OR AH,CouleurFond
       STOSW
       STOSW
       JMP SHORT Cont_aff_instru
Aff_instru:
       MOV BL,7                 ;blanc/noir
       OR BL,CouleurFond
       MOV AL,Disp_Instr
       CALL BIA8                ;affiche nøinstrument
Cont_aff_instru:
       MOV AX,0*256+' '
       OR AH,CouleurFond
       STOSW
	   
       CALL Display_Note

       MOV AX,0*256+' '
       OR AH,CouleurFond
       STOSW

       CALL Display_Command
	   
Fin_aff_voie:
       MOV AX,256*3+'³'
       OR AH,CouleurFond
       STOSW

       POP ES SI
       RET
Displ_Partition_4 ENDP

; Input: ES:DI Video pointer
;        Disp_Command : The Command to Display
Display_Command PROC Near
       CMP Disp_Command,0
       JNZ Affic_la_com
       CMP Disp_Param,0
       JNZ Affic_la_com
       MOV CX,9
       MOV AX,0*256+' '
       OR AH,CouleurFond
       REP STOSW
       RET
	   
Affic_la_com:
       MOV AL,Disp_Command
       XOR AH,AH
       SHL AX,1
       ADD AL,Disp_Command
       ADC AH,0
       SHL AX,1                 ;AX=6*Disp_Command (offset nom effet)

       MOV SI,OFFSET Caract_com
       ADD SI,AX
       MOV CX,6
       MOV AH,12                ;rouge/noir
       OR AH,CouleurFond
Bo_aff_co:
       LODSB
       STOSW
       LOOP Bo_aff_co

       MOV AX,0*256+' '
       OR AH,CouleurFond
       STOSW

       MOV AL,Disp_Param
       MOV BH,7                ;blanc/noir
       OR BH,CouleurFond
       CALL WriteXY_Hex8

	   
       RET
Display_Command ENDP	   
	   


; Input: ES:DI Video pointer
;        Disp_Note : The Note to Display
Display_Note PROC Near

       XOR DH,DH
	   MOV DL,Disp_Note
       CMP DL,127               ;KeyOff ?
       JE Aff_KeyOff            ;Oui => Affiche KeyOff
       CMP DL,0FFh
       JE Pas_Aff_Periode
	   OR DL,DL
	   JNE Aff_Note
Pas_Aff_Periode:
       MOV AX,0*256+' '         ;Pas de P‚riode
       OR AH,CouleurFond
       STOSW
       STOSW
       STOSW
       STOSW
       RET
	   
Aff_KeyOff:
       MOV SI,Offset Affichage_KeyOff
       MOV AH,7                 ;blanc/noir
       OR AH,CouleurFond
       LODSB
       STOSW
       LODSB
       STOSW
       LODSB
       STOSW
       LODSB
       STOSW
       RET
	   
Aff_Note:                       ;Afficher la Note

       XOR CH,CH
	   MOV CL,Disp_Note
Periode_trouvee:

       MOV AX,CX                  ;AX=nønote absolue
       MOV CL,12
       DIV CL                     ;AL=nøoctave, AH=nønote gamme
       MOV CL,AH
       MOV SI,CX
       SHL SI,1                   ;SI=2*(nønote)

       ADD SI,OFFSET Table_note_Angl
       MOV CL,AL                  ;CL=nøoctave
       MOV AH,7                   ;blanc/noir
       OR AH,CouleurFond
       LODSB
       STOSW ; Note Name
       LODSB ; #
       STOSW 
       MOV AL,CL
       ADD AL,'0'
       STOSW
       MOV AL,' '
       STOSW

	   RET

Display_Note ENDP

; DP_CleanLine : Display Partition Clean Line
; DL : Nb of lines to Clean
; Disp_CurrentLine : Screen Y Position

DP_CleanLine PROC NEAR     ;Effacer une ligne de la partition
      MOV AX,Seg_Video     ;Segment_Texte
      MOV ES,AX
      MOV DI,2*(2-1)
      MOV AL,Disp_CurrentLine
	  ADD Disp_CurrentLine,DL
      MUL160
      ADD DI,AX

Loop_Clean_Lines:
      ;Clean the lines
      PUSH DI
      MOV AX,256*7+' '
      MOV CX,78           ; 78 Column to Clean
	  REP STOSW
	  POP DI
	  ; Draw the vertical lines
      MOV AX,256*3+'³'
	  STOSW
      ADD DI,4*2
	  STOSW
	  ADD DI,17*2
	  STOSW
	  ADD DI,17*2
	  STOSW
	  ADD DI,17*2
	  STOSW
	  ADD DI,17*2
	  STOSW
	  ADD DI,4            ; Skip 2 Char
      DEC DL
      JNZ Loop_Clean_Lines
	  
      RET
DP_CleanLine ENDP


Eff_centre_ecran PROC NEAR
      PUSH ES
	  
      MOV DI,2*(2-1)+160*(YPart-1)
      MOV DL,23-YPart+1             ;Nb of lines to Clean
	  
      CMP MUS_OPLStream,1
	  JNE @@Clean_Screen_Small

      MOV DI,2*(2-1)+160*(YPart-1-4)
      MOV DL,27-YPart+1             ;Nb of lines to Clean
	  
@@Clean_Screen_Small:
      MOV AX,Seg_Video  ;Segment_Texte
      MOV ES,AX
      MOV AX,256*7+' '

efface_ligne:
      MOV CX,79-2+1
      REP STOSW
      ADD DI,4
	  DEC DL
	  JNZ efface_ligne

      POP ES
      RET
Eff_Centre_ecran ENDP

Clean_Rectangle Proc Near

Clean_Rectangle Endp

LigneV MACRO x,yh,yb
 Local boucle
      MOV DI,2*(x-1)+160*(yh-1)
      MOV CX,yb-yh+1
boucle:
      STOSW
      ADD DI,160-2
      LOOP boucle
ENDM

Affiche_tableau_Partition PROC NEAR
      MOV AX,256*3+'³'
      LigneV  2,12,23
      LigneV  7,12,23
      LigneV 25,12,23
      LigneV 43,12,23
      LigneV 61,12,23
      LigneV 79,12,23

	  MOV DI,2*(8-1)+160*(YPart-1)
      MOV DL,4                   ;4 boucles
boucle_aff_voie:
      MOV AX,256*48+' '
      STOSW
      STOSW
      STOSW
      STOSW
      STOSW
      MOV AL,'-'
      STOSW
      MOV AL,' '
      STOSW
      MOV BL,48                  ;noir/cyan
      MOV AL,N_Voie_Aff
      SUB AL,DL                  ;DL=compteur de voie
      ADD AL,5                   ;AL=nøvoie
      CALL BIA8                  ;affiche nøvoie
      MOV AX,256*48+' '
      STOSW
      MOV AL,'-'
      STOSW
      MOV AL,' '
      STOSW
      STOSW
      STOSW
      STOSW
      STOSW
      STOSW
      MOV AL,'³'
      STOSW
      DEC DL
      JNZ boucle_aff_voie
 
      MOV DI,2*(2-1)+160*(YPart-1) 

; Coin sup. gauche (nø pattern)
      STOSW
      STOSW
      STOSW
      STOSW	  
      MOV AX,256*53+'Ý'
      STOSW
  
      MOV WORD PTR ES:[2*(79-1)+160*(YPart-1)],256*48+'Þ'  ;coin sup. droit  
      
      RET
Affiche_tableau_Partition ENDP


; Read the Period to Display for the Bar
Display_ReadPeriod Proc Near
      SHL BX,1     ; car CH_Per_part est un mot!
      MOV DX,CH_Per_part[BX]
      SHR BX,1
      RET
Display_ReadPEriod Endp

; Display the Period line in the Screen Center
; BX : Channel number
; CX : Bar size
; ES:[DI] : Screen Position

BarLength DB 0
 
DisplayLine_PeriodBar PROC NEAR
      MOV AH,C_Grey_M_Black   ; Grey or Black in Monochrome
	  XOR CX,CX
	  MOV CL,BarLength
      REP STOSW
      
      TEST Ch_Control[BX],CM_Disabled
      JE Pas_stop_Per
      RET

Pas_stop_Per:
      CALL Display_ReadPEriod  

      MOV CL,6
      CMP BarLength,31 ; Don't change CX Before
      JA Long_PitchBar
	  MOV CL,7
Long_PitchBar:
      SHR DX,CL
  
      CMP DX,1
      JNB Barre1
      MOV DX,1
Barre1:
      XOR CX,CX
      MOV CL,BarLength
      CMP DX,CX
      JBE Barre
      MOV DX,CX    ; Limit to the Bar Size (24 OR 44)
Barre:
      SHL DX,1

      PUSH DI
      SUB DI,DX    ; DI=DI (fin ligne)-2*(Periode/32 or 16)
      DS_TP
      MOV AH,coul_barre_periode
      DS_ASM
      STOSW
      POP DI
      RET
DisplayLine_PeriodBar ENDP

; Display the Period line in the Screen Top
Barre_Periode PROC NEAR
	    MOV AL,7   ; char to display
        MOV DI,2*(55-1)+160*(6-1-Dy)     ; position premiere barre periode
        MOV BL,N_Voie_Aff
        XOR BH,BH
        MOV CX,4

Boucle_aff_Periode:
        PUSH CX
		MOV BarLength,24
        CALL DisplayLine_PeriodBar
        POP CX
        INC BX
        ADD DI,160-48
        LOOP Boucle_aff_Periode
        RET
Barre_Periode ENDP


Pitch_V1   DB Max_Channels DUP (0)
Anc_vol_V1 DB Max_Channels DUP (0)

; Pitch bar : Volume

; BX <- nø voie
; DI <- position ‚cran

Barre_Pitch_simple PROC NEAR
      MOV AL,254                ;car_barre_pitch
      TEST Ch_Control[BX],CM_Disabled
      JE Pas_stop_pitch_s
      MOV WORD PTR ES:[DI],8*256+16
      MOV AH,8                 
      MOV CX,17
      ADD DI,2
      REP STOSW
      RET
	  
Pas_stop_pitch_s:
      MOV WORD PTR ES:[DI],12*256+16
      MOV DL,Ch_Volume[BX]
      TEST Ch_Control[BX],M_VolChanged   ; Is set to one by the player is the volume was changed
	  JNZ Change_Pitch_s
      CMP Anc_vol_V1[BX],DL
      JNE Change_pitch_s
      DEC Pitch_V1[BX]
      CMP Pitch_V1[BX],64
      JBE Affiche_Pitch_s
      MOV Pitch_V1[BX],0
      JMP SHORT Affiche_pitch_s
Change_pitch_s:
      AND Ch_Control[BX],Not M_VolChanged ; Reset the Value
      MOV Pitch_V1[BX],DL
Affiche_Pitch_s:
      MOV Anc_vol_V1[BX],DL
      MOV DL,Pitch_V1[BX]
If ModeXT eq Yes
      SHR DL,1
      SHR DL,1
Else	  
      SHR DL,2
Endif	  
      ADD DI,2
      DS_TP
      MOV AH,coul_barre_pitch
      STOSW          ;1 Green
      CMP DL,12
      JBE inf_12
      MOV CL,12
      REP STOSW      ;Vol x Green
      MOV AH,coul_bout_pitch
      MOV CL,DL
      SUB CL,12
      REP STOSW      ;(Vol-12) Red
      JMP SHORT aff_gris
 inf_12:
      MOV CL,DL
      JCXZ aff_gris
      REP STOSW      ;DL verts
 aff_gris:
      MOV AH,CS:C_Grey_M_Black
      MOV CL,16
      SUB CL,DL
      JCXZ fin_barre_pitch
      REP STOSW      ;(16-Vol) gray (Black in Monochrome)
 fin_barre_pitch:
      DS_ASM
      RET
Barre_Pitch_simple ENDP

; Display the 4 Pitch bar Top Left Position

Barre_Pitch_4 PROC NEAR
      MOV DI,2*(3-1)+160*(6-1-Dy)  ; position premiŠre barre pitch
      MOV BL,N_Voie_Aff
      XOR BH,BH         ; BX=nøpremiŠre voie (en haut)
      MOV CX,4

Boucle_aff_Pitch:
      PUSH CX
      PUSH BX
      MOV AL,BL
      INC AL                    ; AL=nøvoie
      MOV BL,15                 ; blanc brillant/noir
      CALL BIA8                 ; affiche nøvoie
      POP BX	  
      CALL Barre_Pitch_simple
	  MOV AL,' '
	  STOSW
      POP CX
      INC BX
      ADD DI,2*(80-22)+2
      LOOP Boucle_aff_Pitch
      RET
Barre_Pitch_4 ENDP

; Display the Channels with all the informations

PitchBar_Nb DB 14

Barre_Pitch_18 PROC NEAR

	  MOV DI,2*(3-1)+160*(10-Dy)  ; position premiŠre barre pitch
	  MOV PitchBar_Nb,14

      CMP MUS_OPLStream,1
	  JNE @@BPStart_OPLStr
	  
	  MOV DI,2*(3-1)+160*(6-Dy)  ; position premiŠre barre pitch 
	  MOV PitchBar_Nb,18
@@BPStart_OPLStr:

      XOR CH,CH	  
      MOV CL,Ch_Number
	  CMP CL,PitchBar_Nb
	  JBE Nb_To_Display_Ok
	  MOV CL,PitchBar_Nb
Nb_To_Display_Ok:	  

      MOV BL,N_Voie_Aff
      MOV AL,CL
      ADD AL,BL
	  CMP AL,Ch_Number
	  JBE Aff_Pos_Ok
      MOV BL,Ch_Number          ; Adjust if asked to display too many channels
	  SUB BL,14
	  CMP BL,14
	  JBE Aff_Pos_Ok
	  MOV BL,0
Aff_Pos_Ok:	  
      XOR BH,BH                 ; BX=nøpremiŠre voie (en haut)      

Display_Channels_Loop:
      PUSH CX
      PUSH BX

; 1) Volume Bar

      MOV AL,BL
      INC AL                    ; AL=nøvoie
      MOV BL,15                 ; blanc brillant/noir
      CALL BIA8                 ; affiche nøvoie
      POP BX	  
      CALL Barre_Pitch_simple
	  ADD DI,2

; 2) On/Off Button

      MOV AX,C_yellow*256+07h
      TEST Ch_Control[BX],CM_FPause ; Forced Pause > Brown
	  JNZ DCLoop_ChOnOff
      MOV AH,C_green
      TEST Ch_Control[BX],CM_Stopped
	  JZ DCLoop_ChOnOff
      MOV AH,C_Red
      TEST Ch_Control[BX],CM_FStop  ; Forced Stop > Red
	  JNZ DCLoop_ChOnOff
	  MOV AL,' '
DCLoop_ChOnOff:
      STOSW
      ADD DI,2	  
	  
; 3) Volume Value
  
      MOV AL,Ch_Part_Vol[BX]
	  PUSH DI
	  PUSH BX
      MOV BL,15                ;Blanc/Noir
      CALL bia8                ;affiche
      POP BX
	  POP DI
	  ADD DI,6
	  
; 4) Panning Arrow

      MOV AL,CH_Panning[BX]  
	  CMP AL,30h
	  JB Display_Right_Arrow
	  CMP AL,50h
	  JBE Display_Center_Arrow
	  MOV AL,27 ; Left
	  JMP Display_Arrow
Display_Right_Arrow:	  
	  MOV AL,26 ; Right
	  JMP Display_Arrow      
Display_Center_Arrow:
	  MOV AL,29 ; Center
Display_Arrow:
  
      STOSW
      ADD DI,2

; 5) Note + Command 

      CMP MUS_OPLStream,1
	  JE NoDisplayNoteCommand

      MOV AL,Ch_Note[BX]
      MOV Disp_Note,AL
	  MOV CouleurFond,0
	  
	  CALL Display_Note

      MOV BarLength,44    ; Period Bar Size for Modules
      CMP Display_NoteOrBar,1
      JE  @@DisplayPerBarStr
	  
      MOV AH,VCurrent_CMD[BX]
	  MOV AL,VCurrent_PAR[BX]
	  MOV Disp_Command,AH
	  MOV Disp_Param,AL
	  
	  PUSH BX
	  CALL Display_Command  
	  POP BX

NoDisplayNoteCommand:

; 6 )Sample number

      MOV BarLength,48      ; Period Bar Size for Stream based music
      CMP MUS_OPLStream,1   ; IMF, DRO... Display Period Bar
	  JE @@DisplayPerBarStr

      ADD DI,2

      MOV AL,Ch_Part_I_Smp[BX]
      CMP AL,0FFh
	  JNE No_Display_FFh
	  MOV AH,3          ; cyan/noir
	  MOV AL,'-'
	  STOSW
	  STOSW
	  ADD DI,25*2
	  JMP Do_Display_NoteLoop
No_Display_FFh:	  
	  PUSH BX
      MOV BH,3                  ;cyan/noir
      CALL WriteXY_Hex8         ;affiche
      POP BX

      ADD DI,2

; 7) Sample Name or Note bar

      MOV BarLength,31       ; Period Bar size for DRO
      CMP Type_Module,T_RAD  ; RAD, No Sample name > Display Period Bar
	  JE @@DisplayPerBarDRO

      JMP @@DisplaySmpName  ; Skip the Period Bars Display

; *** Period Bar for Stream based music ( Can't display Note )

@@DisplayPerBarStr:

@@DisplayPerBarDRO:
	  
	  MOV AL,7   ; char to display
	  CALL DisplayLine_PeriodBar
	  SUB DI,6+8
      JMP Do_Display_NoteLoop
	   
@@DisplaySmpName:	  
	  PUSH BX
	  MOV BL,Ch_Part_I_Smp[BX]
	  CALL Display_SMP_Instr_Name24
	  POP BX

Do_Display_NoteLoop:
	  
      POP CX
      INC BX
      ADD DI,2*(80-21)-2-2-2-26*2+2-24-20+4
	  DEC CX
	  JZ End_Display_Channels_Loop
      JMP Display_Channels_Loop

End_Display_Channels_Loop:

	  DS_ASM
      RET
Barre_Pitch_18 ENDP

Old_pos DW Max_Channels DUP(0)

; BX <- nø voie
; DX <- position ‚cran

DisplayCenter_Samples_simple PROC NEAR
        SHL BX,1
        MOV DI,Old_pos[BX]      ; Previously displayed channel Nb Offset
        SHR BX,1
        MOV AX,14*256+13        ; note de musique jaune/noir
        STOSW
        MOV AL,Ch_Part_I_Smp[BX]  ;CH_Smp_Pla[BX]
        CMP AL,14
        JB Sample_Below14
        ADD DX,2*39
        SUB AL,14

Sample_Below14:
        MOV CL,160
        MUL CL
        ADD AX,DX
        MOV DI,AX
        MOV AX,15*256+'1'
        ADD AX,BX
        SHL BX,1
        MOV Old_pos[BX],DI      ; Store the channel Nb Offset
        SHR BX,1
        STOSW
        RET
DisplayCenter_Samples_simple ENDP


DisplayCenter_Samples PROC NEAR
        DS_TP
        CMP Change_aff_centre,1
        DS_ASM
        JNE Pas_aff_liste

        CALL Eff_centre_ecran
        CALL Display_Names_Center
		
        DS_TP
        MOV Change_aff_centre,0
        DS_ASM
Pas_aff_liste:
If CGAOnly Eq No
        MOV DX,2*(4-1)+160*(12-1)      ; position de la premiere marque
Else
        MOV DX,2*(4-1)+160*(10-1)      ; position de la premiere marque
Endif

        XOR BX,BX
        XOR CH,CH
        MOV CL,Ch_Number      ; CX=nombre de voies
        CMP CL,8
        JBE boucle_aff_marques
        MOV CL,8                ; n'affiche que 8 notes de musique
boucle_aff_marques:
        PUSH CX
        PUSH DX
        CMP CH_Smp_Pla[BX],0FFh  ; -1 => Voie pas encore utilisee
        JE Pas_aff_marques
If ModeXT Eq Yes
        CMP CH_Smp_Pla[BX],25     ; Pas plus de 26 instruments affiches !!
Else
        CMP CH_Smp_Pla[BX],30     ; Pas plus de 31 instruments affiches !!
EndIf		
        JA Pas_aff_marques
        CALL DisplayCenter_Samples_simple
Pas_aff_marques:
        POP DX
        ADD DX,2                ; incr‚mente position de la prochaine marque
        INC BX
        POP CX
        LOOP boucle_aff_marques
        RET
DisplayCenter_Samples ENDP

affichages_msg_a DB 'DISPLAY',0
commandes_msg_a  DB 'COMMANDS',0

aide01_msg_a DB '^F1^: Display/Hide this Screen',0
aide02_msg_a DB '^F2^: Samples list',0
aide03_msg_a DB '^F3^: Partition',0
aide04_msg_a DB '^F4^: Display channels infos',0
If ModeXT Eq No
aide05_msg_a DB '^F5^: Interpolation enable/disable',0
EndIf
aide06_msg_a DB '^',24,'^,^',25,'^: Cycle channels display',0
aide07_msg_a DB '^Q^,^W^,^A^,^S^: Change pitch-bar colors',0
aide08_msg_a DB '^O^,^P^: Change period dot color',0
aide09_msg_a DB ' ',0
aide10_msg_a DB ' ',0

aide11_msg_a DB '^-^,^+^: Volume decreased/increased',0
aide12_msg_a DB '^',27,'^,^',26,'^: Fast rewind/forward',0
aide13_msg_a DB '^1^..^8^: Switch on/off a voice',0
aide15_msg_a DB '^Page',24,'^: Previous music (prog.)',0
aide16_msg_a DB '^Page',25,'^: Next music (prog.)',0
aide17_msg_a DB '^R^: Repeat enable/disable',0
aide18_msg_a DB '^I^: IntroScan disabled',0
aide19_msg_a DB '^Space^: Pause enable/disable',0
aide20_msg_a DB '^D^: Dos Shell',0
aide21_msg_a DB '^Esc^: Exit playing',0


DisplayCenter_Help PROC NEAR
      DS_TP
      CMP Change_aff_centre,1
      DS_ASM
      JE affiche_aide
      RET

affiche_aide:
      CALL Eff_centre_ecran

      MOV AX,7*256+'Ä'
      MOV DI,2*(2-1)+160*(YPart+1-1)
      MOV CX,79-2+1
      REP STOSW                 ; ligne horizontale

      MOV AL,'º'
      MOV DI,2*(43-1)+160*(YPart-1)
If CGAOnly Eq Yes
      MOV CL,24-11+1
Else
      MOV CL,27-11+1
EndIf	  
ligne_verticale_double:
      STOSW
      ADD DI,158
      LOOP ligne_verticale_double

If CGAOnly Eq Yes
      MOV WORD PTR ES:[2*(43-1)+160*(11-1)],256*7+'×'
Else
      MOV WORD PTR ES:[2*(43-1)+160*(13-1)],256*7+'×'
EndIf
      MOV AH,14                 ; jaune/noir

If EngOnly Eq No  
      MOV SI,OFFSET affichages_msg
      DS_TP
      CMP Langue,Francais
      DS_ASM
      JE debut_affiche_aide
EndIf

      MOV SI,OFFSET affichages_msg_a
debut_affiche_aide:
      MOV DI,2*(17-1)+160*(Ypart-1)
      CALL WriteStrXY             ; affiche "AFFICHAGES"
      MOV DI,2*(58-1)+160*(YPart-1)
      CALL WriteStrXY             ; affiche "COMMANDES"

      MOV AH,7                  ; blanc/noir
      MOV BH,15                 ; blanc brillant/noir
                                                    
      MOV DI,2*( 4-1)+160*(YPart+2-1)
      CALL WriteStrXY2           ; affiche aide01_msg
      MOV DI,2*( 4-1)+160*(YPart+3-1)
      CALL WriteStrXY2           ; affiche aide02_msg
      MOV DI,2*( 4-1)+160*(YPart+4-1)
      CALL WriteStrXY2           ; affiche aide03_msg
      MOV DI,2*( 4-1)+160*(YPart+5-1)
      CALL WriteStrXY2           ; affiche aide04_msg	
;      MOV DI,2*( 4-1)+160*(YPart+7-1)
;      CALL WriteStrXY2           ; affiche aide05_msg
      MOV DI,2*( 4-1)+160*(YPart+7-1)
      CALL WriteStrXY2           ; affiche aide06_msg	  
      MOV DI,2*( 4-1)+160*(YPart+9-1)
      CALL WriteStrXY2           ; affiche aide07_msg
      MOV DI,2*( 4-1)+160*(YPart+10-1)
      CALL WriteStrXY2           ; affiche aide08_msg
      MOV DI,2*( 4-1)+160*(YPart+11-1)
      CALL WriteStrXY2           ; affiche aide09_msg
      MOV DI,2*( 4-1)+160*(YPart+12-1)
;      CALL WriteStrXY2           ; affiche aide10_msg
;      MOV DI,2*( 4-1)+160*(YPart+13-1)
	  
      CALL WriteStrXY2           ; affiche aide11_msg
      MOV DI,2*(46-1)+160*(YPart+2-1)
      CALL WriteStrXY2           ; affiche aide12_msg
      MOV DI,2*(46-1)+160*(YPart+3-1)
      CALL WriteStrXY2           ; affiche aide13_msg
      MOV DI,2*(46-1)+160*(YPart+4-1)
      CALL WriteStrXY2           ; affiche aide14_msg
      MOV DI,2*(46-1)+160*(YPart+5-1)
      CALL WriteStrXY2           ; affiche aide15_msg
      MOV DI,2*(46-1)+160*(YPart+6-1)
      CALL WriteStrXY2           ; affiche aide16_msg
      MOV DI,2*(46-1)+160*(YPart+8-1)
      CALL WriteStrXY2           ; affiche aide17_msg
      MOV DI,2*(46-1)+160*(YPart+9-1)
      CALL WriteStrXY2           ; affiche aide18_msg
      MOV DI,2*(46-1)+160*(YPart+10-1)
      CALL WriteStrXY2           ; affiche aide19_msg
      MOV DI,2*(46-1)+160*(YPart+11-1)
      CALL WriteStrXY2           ; affiche aide20_msg
      MOV DI,2*(46-1)+160*(YPart+12-1)
      CALL WriteStrXY2           ; affiche aide21_msg

      DS_TP
      MOV Change_aff_centre,0
      DS_ASM
      RET
DisplayCenter_Help ENDP