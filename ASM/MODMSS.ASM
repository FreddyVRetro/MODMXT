;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ MODMPAS.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷     º
;            º                                                   º
;            º         --==ğğ Mod Master v2.2 XT ğğ==--          º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteurúúúúúúúúúúúúúúúúúúúúúúúú Freddy V‚tel‚    º
;            º   Avec l'aide deúúúúúúúúúúúúúúúú Fabrice Couteau  º
;            º                                                   º
;            º   Code Start     03/05/1993                       º
;            º   Last Update    --/04/2020                       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


;model large,pascal

Yes Equ 0
No  Equ -1

Mod_Master Equ Yes   ; Yes => Use also Mod Master Interface Display
                     ; No  => Audio Only (MODM_SS)
CGAOnly     Equ Yes
ModeXT      Equ Yes
XMCMD       Equ Yes  ; Fast Tracker 2 Instruments and Commands
UseFineTune Equ No
UsePanning  Equ Yes
UseGUS      Equ Yes  ; Yes to include GUS Code
UseOPL2     Equ Yes  ; Yes to include OPL2/3 Code
UseRAD      Equ Yes
UseMix16    Equ Yes  ; Yes to allow 16Bit Mixing
UseMixSt    Equ Yes  ; Yes to allow Stereo Mixing

UseVolEnv Equ No

DEBUG Equ No

; Pas d'interpolation

writechar MACRO x              ;Macro ?criture
     PUSH AX
	 PUSH BX
	 PUSH CX
     PUSH BP
	 PUSH SI
	 MOV AL,x 
	 MOV BH,0    ; Page 0
	 MOV BL,0Fh  ; White
     MOV AH,0Eh
     INT 10h
	 POP SI
	 POP BP
     POP CX
	 POP BX
     POP AX
ENDM

WRITEL macro x              ;Macro ?criture de chaine
       MOV dx,offset x      ;x, chaine
       MOV ah,9
       INT 21h
       endm
	   
writeln MACRO STRING_
LOCAL TEXT3_S
local skip_wrln
        push ax
        push dx

        jmp skip_wrln

        IFB <STRING_>
TEXT3_S DB 13,10,36
        ELSE
TEXT3_S DB STRING_,13,10,36
        ENDIF
skip_wrln:
        mov DX,offset TEXT3_S
        mov ah,9
        Int 21h
        pop dx
        pop ax
ENDM	   
						   
DS_TP MACRO                 ;pour acc‚der to une variable EXTRN par DS
      MOV DS,CS:DS_TurboPascal
ENDM

;BP_TP MACRO
;      MOV BP,CS:BP_TurboPascal
;ENDM

DS_ASM MACRO                 ;CS -> DS
      PUSH CS
      POP DS
ENDM

ES_ASM MACRO                 ;CS -> ES
      PUSH CS
      POP ES
ENDM

showborder = 0  ; VGA Only
setborder MACRO no
      if showborder
      PUSH dx ax
      MOV  dx,03dah ; Reset the Registry port to write registry
      IN   al,dx
      MOV  dx,03c0h
      MOV  al,31h   
      OUT  dx,al    ; Select register 31h
      MOV  al,no
      OUT  dx,al
      POP  ax dx
      endif
ENDM

C_W MACRO
if showborder
      PUSH AX
      PUSH DX
      mov DX,3C8h
      XOR AL,AL
      out DX,AL           ;charge le nøcouleur
      inc dx
      MOV AL,0FFh
      out DX,AL          ;fixe le rouge
      out DX,AL          ;fixe le vert
      out DX,AL          ;fixe le bleu
      POP DX
      POP AX
endif  
ENDM

C_R MACRO
if showborder
      PUSH AX
      PUSH DX
      mov DX,3C8h
      XOR AL,AL
      out DX,AL           ;charge le nøcouleur
      inc dx
      MOV AL,0FFh
      out DX,AL          ;fixe le rouge
      XOR AL,AL
      out DX,AL          ;fixe le vert
      out DX,AL          ;fixe le bleu
      POP DX
      POP AX
endif  
ENDM

C_G MACRO
if showborder
  PUSH AX
  PUSH DX
  mov DX,3C8h
  XOR AL,AL
  out DX,AL           ;charge le nøcouleur
  inc dx
  out DX,AL          ;fixe le rouge
  MOV AL,0FFh
  out DX,AL          ;fixe le vert
  XOR AL,AL  
  out DX,AL          ;fixe le bleu
  POP DX
  POP AX
endif
ENDM

C_BL MACRO
if showborder
  PUSH AX
  PUSH DX
  mov DX,3C8h
  XOR AL,AL
  out DX,AL           ;charge le nøcouleur
  inc dx
  out DX,AL          ;fixe le rouge
  out DX,AL          ;fixe le vert
  MOV AL,0FFh
  out DX,AL          ;fixe le bleu
  POP DX
  POP AX
endif
ENDM

C_B MACRO
if showborder
  PUSH AX
  PUSH DX
  mov DX,3C8h
  XOR AL,AL
  out DX,AL           ;charge le nøcouleur
  inc dx
  out DX,AL          ;fixe le rouge
  out DX,AL          ;fixe le vert
  out DX,AL          ;fixe le bleu
  POP DX
  POP AX
endif
ENDM

;Donne un pointeur (ES:DI) sur le sample

Pointer_Sample MACRO N_Smp
      PUSH BX
      MOV BX,N_Smp
If ModeXT eq Yes
      SHL BX,1
	  SHL BX,1
Else
      SHL BX,2
EndIf	  
      LES DI,PtrSamples[BX]   ; BX*4
      POP BX
ENDM

If ModeXT eq No
.386
Endif

CODE SEGMENT
     ASSUME CS:CODE, DS:CODE

;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º                    Constantes principales                    º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

Max_Channels EQU 32
Max_Samples  EQU 99
Max_Pattern  EQU 128 ;256 pour ULT, sinon 128 

;touches de fin
Tfin_normale EQU 0
Tfin_Esc     EQU 1
Tfin_PgUp    EQU 2
Tfin_PgDn    EQU 3

;type de notes
Note_Francaise EQU 0
Note_Anglaise  EQU 1

;langue
Anglais  EQU 0
Francais EQU 1


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º                    Variables principales                     º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

Align 2

;Variables used for Mod MAster Only (Display/Other)
If Mod_Master eq yes

Endif

Voie_Reelle    DW 0
DS_TurboPascal DW 0

Min_Period  DW 0    ; Minimal Period
Moyen_Notes DW 0    ; Max Period
Max_Period  DW 0

;Min_Period_Act  DW 0
;Moyen_Notes_Act DW 0
;Max_Period_Act  DW 0

Real_Frequency DW 16000    ; 'Real' Mixing Frequency value
Periode_timer  DW 0
P_Amiga_h DW 0
P_Amiga_l DW 0

Volume_total         DB 0
Sauvegarde_du_volume DB 0

BPM_Val    DW 0 ; Module BPM Increment ( 65000 / Tempo )
;TickCnt   DB 0 ; Tick counter (Between Partition Read)

Chrono_50 DB 0

;****  Variables used for the Mixing ****

; ** For Debug Display
ALIGN 2
IRQ_Cnt          DW 0  ; For Debug Display
Slow_Mix1_Cnt    DW 0  ; For Debug Display
Slow_Mix2_Cnt    DW 0  ; For Debug Display
Slow_Mix3_Cnt    DW 0  ; For Debug Display

Nb_Voix_Mixees   DB 0  ; For Debug Display
Nb_Voix_Skip_Vol DB 0  ; For Debug Display	
Max_Mixed3       DB 0  ; For Debug Display

; Mixing
ALIGN 2
Buffer_Convert_Code DW 0 ; Offset to the buffer conversion Code
Mix_Loop64_Nb       DW 0 ; Number of 64 Byte block to mix each Tick
Mix_Loop4_Nb        DW 0 ; Plus Number of 4 Bytes block to mix
Mix_Loop1_Nb        DB 0 ; Plus Number of Bytes to Mix

Volume_Skip       DB 0
Mix_Mono_Use_Left DB 0 ; Set to one to Mix the mono buffer to the left buffer (16 Bit Mix, Mono to 8 Bit)

VolSkipIncr Equ 8
Vol_Limit2  Equ 16   ; Volume Limit with 2 Buffers Late
Vol_Limit3  Equ 16+8 ; Volume Limit With 3 Buffers Late

;Buffer_Start_Offs : In MMSS_CFG^
;Left_Buffer_Offs  : In MMSS_CFG^
;Right_Buffer_Offs : In MMSS_CFG^

; Buffers management

TDYDAC_Simul DB 0
TDYDAC_Test   DB 0

Max_Buffers_Supported Equ 32   ; Maximum Buffers Supported by the code.
DMA_Max_Buffer_Nb Equ 10       ; Max 1/50s Buffers pre calculated

DMA_Buffer_Size     DW 0
Buffers_Total_Nb    DB 5
DMA_Buffers_NB      DB 5
DMA_Buffers_Max_NB  DB 0   ; Maximum number of Buffer we can allocate

Buffer_Ahead_Cnt     DB 0  ; Number of Buffer Ahead of the replay
Buffers_Ahead_Min    DB 1  ;
Buffers_Ahead_Min3   DB 4  ; Buffers_Ahead_Min+3
Buffers_Ahead_Target DB 5

DMA_Buffer_Playing DB 0
DMA_Buffer_Mixing  DB 0

ALIGN 2

;Buffer_Size             in MMSS_CFG^ (Nb of sample per 1/50s)
Buffer_Real_Size     DW 0  ; Nb of Bytes per 1/50s
;DMA_Buffers_Total_Size  in TP Info 
DMA_Buffers_End_Offs DW 0  ; End Offset of the DMA Buffers

Preprocessing DB 0   ; Tell the mixing code it is a pre processing

; Variables used in the Channel priority algorythm

Ch_Smp_Tick_Cnt  DB Max_Channels DUP (0)  ; Number of Tick*Tempo a sample is playing
Ch_LoopType      DB Max_Channels DUP (0)  ;
Ch_Priority      DB Max_Channels DUP (0)  ; Value for priority

Mix_Channel_List DB Max_Channels DUP (0)
Mix_Channels_Nb  DB 0                  ; Number of channels to mix after "Useless" channels removed
Mix_Channels_Nb_Max  DB 0              ; Max Number of Channels used

Mix_ChLimit_Type   DB 0  ; 0 Off, 1: Auto 2: Manual
Mix_ChLimit_Nb     DB 0  ; FFh Off 0: Auto >0: Limit Value used for Manual Limit
Mix_Channels_Limit DB 0  ; Limit value in the Build List Code

; Variables for Tandy DAC / DMA Progress Read Mode
; A 50Hz timer read the DMA playing Offset vx mixing Offset and start the Mixing

MixDMA_OffsetDelta DW 0 ; Convert DMA Playing Offset to Mix segment Offset (Mic Buff Offs - DMA Buff Offset)
CurrentMix_Delta   DW 0
MixDelta_Slow  DW 0    ; Value to Stop the music
MixDelta_Min  DW 0    ; Buffer_Real_Size * Buffers_Ahead_Min (Buff Min >=2)
MixDelta_2    DW 0    ; MixDelta_Min + Buffer_Real_Size    : Apply VolLimit3
MixDelta_3    DW 0    ; MixDelta_Min + 2*Buffer_Real_Size  : Apply VolLimit2
MixDelta_4    DW 0    ; MixDelta_Min + 3*Buffer_Real_Size
MixDelta_Target DW 0  ; Buffer_Real_Size * (Buffers_Ahead_Target-1)


;Cmpt_Debug  DW 0
;B_Debug     DB 0

If Mod_Master eq yes
 INCLUDE CONSTAFF.INC  ;Tableaux pour l'affichage
 INCLUDE AFFICHE.ASM   ;Inclut les routines d'affichage g‚n‚rales 
EndIf

INCLUDE CONSTMM.INC    ;Les tableaux (Vibrato,Periodes,...)
If UseGUS eq Yes
INCLUDE GUSCMD.ASM     ;Commandes GUS...
EndIf

INCLUDE SBCMD.ASM      ;Commandes pour la Sound Blaster
INCLUDE HARDWARE.ASM   ; EMS, DMA, IRQ

;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º         Variables/Proc‚dures externes ou publiques           º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

; Procedures visible by the Pascal Code 

;PUBLIC Test_vitesse
;PUBLIC Ajuster_Out_Frequency  ;Ajuster les variables utilisant la fr‚quence
PUBLIC PInit_Tables
PUBLIC PStart_Output     ;Lancer la sortie sonore
PUBLIC PStart_Music      ;Lancer la musique

PUBLIC PStart_IRQ ;TEST

If Mod_Master eq yes
EXTRN car_barre_pitch     :BYTE
EXTRN car_barre_periode   :BYTE
EXTRN coul_barre_pitch    :BYTE
EXTRN coul_barre_periode  :BYTE
EXTRN coul_bout_pitch     :BYTE
EXTRN Center_Display      :BYTE
EXTRN Change_aff_centre   :BYTE
EXTRN Shuffle             :BYTE  ;=1 si Shuffle=True
EXTRN Programme           :BYTE  ;=1 si Programme=True
EXTRN Numero_Module       :WORD  ;Num‚ro du module actuel dans le programme
EXTRN Longueur_prog       :WORD  ;Nombre de modules dans le programme
EXTRN TP_Duree_min        :BYTE
EXTRN TP_Duree_sec        :BYTE
EXTRN TP_Duree_50         :BYTE
EXTRN Mode_actuel         :BYTE  ;0 Mode Texte(28l), 1 Mode Graphique, 2 Autre
EXTRN Mode_a_afficher     :BYTE  ;0 Mode Texte(28l), 1 Mode Graphique
EXTRN Nom_Fichier         :BYTE  ;Nom du fichier sans chemin
EXTRN Activer_Shell       :BYTE
EXTRN Key_ScanCode        :BYTE
EndIf

EXTRN Boucler_MOD         :BYTE
EXTRN TP_Fading           :BYTE   ; To use in Sound System
EXTRN TP_Chrono_min       :BYTE   ; To use in Sound System
EXTRN TP_Chrono_sec       :BYTE   ; To use in Sound System
EXTRN Test_Periodique     :BYTE   ; le 50Šme de seconde pour l'affichage

; Structures defined in VAR_MUS.TPU
;*****  MMSS_CFG^ in the Turbo Pascal

TPVariables:
PSortie_sonore      DB HPint         ;Type de sortie sonore (Disney,SB,GUS...)

; 'Synth' Devices Config
OPL_Type            DB 0             ;0:None 1:OPL1 2:OPL2
OPL_LPT_Type        DB 0             ;0:None 1:OPL1 2:OPL2
OPL_LPT_Nb          DB 0             ;0:None 1:LPT1 2:LPT2

TDY_Type            DB 0
TDY_LPT_Nb          DB 0
TDY_Port            DW 0             ;Base Port for the Tandy 3Ch / DAC
TDYDAC_Port         DW 0

LPT1_Port           DW 0
LPT2_Port           DW 0
; 'Wave' Devices Config
; ** Custom DAC
Port_CustomDAC      DW 0
; ** Gravis UltraSound
GUS_InterWave       DB 0             ;0:GF1 1:InterWave
GUS_BasePort        DW 220h          ;Port de base de la GUS
GUS_IRQ             DB 7             ;Gravis Ultrasound IRQ (Not Used)
; ** Sound Blaster
SB_BasePort         DW 220h          ;Port de base de la Sound Blaster
IRQ_SB              DB 7             ;Nø IRQ Sound Blaster
DMA_SB8             DB 1             ;Nø DMA Sound Blaster
DMA_SB16            DB 5             ;Nø DMA Sound Blaster 16  (Sortie 16 Bits)
Type_SB             DB 1             ;Type de Sound Blaster
PUse_DMA            DB 0             ;=1 si sortie SB avec le DMA
PDMA_Continu        DB 0             ;Lecture DMA continue ???
PUse_Stereo         DB 0             ;=1 si sortie SBPro St‚r‚o
Utilise_Filtre      DB 0
; ** Mixing Options
PUtilise_Mixage     DB 0
Utiliser_Interpol   DB 0             ;Utiliser l'interpolation lin‚aire 8 bits?
;If UseMix16 Eq Yes
Mix_16Bit           DB 0             ;Mix in 16 Bit
Out_16Bit           DB 0             ;Initialized in InitDevice 
;EndIf
Out_Signed          DB 0             ;One if the Output is signed (Does not need conversion, No Smp = 0)
Calculer_Panning    DB 0             ;Utiliser le mixage avec Panning ?
PMix_ChLimit_Type   DB 0             ; 0 Off, 1: Auto 2: Manual
PMix_ChLimit_Nb     DB 0             ; FFh Off 0: Auto >0: Limit
Out_Frequency       DW 16000         ;Output Frequency (Hz)
Seg_Volume          DW 0             ;Segment de la table de volume et des tampons DMA
Buffer_Start_Offs   DW 0
Left_Buffer_Offs    DW 0
Right_Buffer_Offs   DW 0

Musique_Terminee    DB 1             ;Activer/Disable the musique
Output_Stopped      DB 1             ;Vrai quand la musique est terminee
Stop_Output         DB 0             ;Pour arreter la sortie sonore

;Pascal_Handle_EMS   DW 0             ;Pour sauver et restaurer l'EMS
;Utilise_EMS         DB 0             ;Indique si un sample est en EMS

;BPM_Base            DB 0

Use_BPM_CMD         DB 1
Use_FineTune_CMD    DB 1             ;Gestion des FineTune ?
Utiliser_Panning    DB 1             ;Executer la commande Panning ?

Duree_intro         DB 0             ;Duree de l'IntroScan
nb_de_boucles       DB 0
Touche_fin          DB Tfin_normale
Seg_Video           DW 0B800h         ; Change to B000 for Hercule
Erreur_Modm         DB 0
OtherMUS_Ptr        DD 0              ; Pointer to the Music if Not MMM (INF, RAD...)
OtherMUS_DataEnd    DD 0              ; Size of the Music Data. (Stream)
OtherMUS_Out        DB 0              ; Mask with the Wave output used
debug1              DW 0
debug2              DW 0
debug3              DW 0
ContrVar            DB 73            ;Variable de Contr“le !!!

;***** fin structure MMSS_CFG^ TP

;***** MMSS_MUS^ in the Turbo Pascal
TPMusique:

Titre               DB 32 DUP (0)
Ch_Number           DB 4    ; de 1 to 32 !!!
Ch_Number_patt      DB 4    ;Nb of channels in the Patterns (Can be > Ch_Number )
Ch_Number_Digit     DB 4
Ch_Number_Adlib     DB 0
Note_Delta          DW 0    ; Delta value in the pattern if different Nb of Channels
CP_Pattern          DB 0    ; 1 If the pattern is compressed
Note_Size           DB 6    ; Nb of Byte per note (5 or 6)
Nb_Instr            DB 0
Nb_Total_Samples    DB 0    ; Total samples count (Empty or not)
Nb_Samples          DB 0    ; Count of Not Empty Samples
Nb_Reel_Samples     DB 0    ; Count of Loaded Samples
Sequence_Len        DB 0
Pos_de_restart      DB 0
Tempo_Start         DB 6
BPM_Start           DB 7Dh
Vol_Gene_depart     DB 40h  ; Music Global Volume
Octave_Min          DB 0
Octave_Max          DB 7
Type_Module         DB 0    ; Type du module (MOD, STM, S3M, MTM ...)
Volume_Sl_Rapide    DB 0
Vitesse_ticks       DB 50   ; Nb de ticks par seconde
Seg_Instr           DW 0    ; Instrument table Segment
PtrInstrNameTable   DD 0    ; Pointer to the Instruments/Samples name table (24 Bytes table)
M_CH_Type           DB Max_Channels DUP (0)   ; Type de la voie (Vide,Nø,Adlib)
M_CH_Panning        DB Max_Channels DUP (0)   ; Default Channles Panning
Voies_Adlib         DB 11 DUP (0)             ; 'Position' des voies adlib.  ;OPT Align !
Table_sequence      DB Max_Pattern DUP (0)
Table_Taille_Patt   DB Max_Pattern DUP (0)
Table_Tempo         DB Max_Pattern DUP (0)     ; Table Tempo (669 ?)
ContrMus            DB 73   ; Variable de Contr“le !!!

;***** fin structure Musique^ TP

;***** d‚but structure MMSS_Table^ TP
Align 2

TPTable:
Seg_Pattern    DW Max_Pattern DUP (0)     ; Segment to the Pattern
PtrSamples     DD Max_Samples DUP (0)     ; Pointeurs to the Sample structure

If UseGUS Eq Yes

;GusVol    DW 00E00h,0B000h,0B800h,0BC00h,0BE00h,0C000h,0C400h,0C800h,0CC00h  ; 65 Values
;          DW 0D000h,0D200h,0D400h,0D600h,0D800h,0DA00h,0DC00h,0DE00h
;          DW 0E000h,0E100h,0E200h,0E300h,0E400h,0E500h,0E600h,0E700h
;          DW 0E800h,0E900h,0EA00h,0EB00h,0EC00h,0ED00h,0EE00h,0EF00h
;          DW 0F080h,0F100h,0F180h,0F200h,0F280h,0F300h,0F380h,0F400h
;          DW 0F480h,0F500h,0F580h,0F600h,0F680h,0F700h,0F780h,0F800h
;          DW 0F880h,0F900h,0F980h,0FA00h,0FA80h,0FB00h,0FB80h,0FC00h
;          DW 0FC80h,0FD00h,0FD80h,0FE00h,0FE80h,0FF00h,0FF80h,0FFF0h
GusVol dw 05000h,08FF0h,09FF0h,0A800h,0AFF0h,0B400h,0B800h,0BC00h
       dw 0BFF0h,0C200h,0C400h,0C600h,0C800h,0CA00h,0CC00h,0CE00h
       dw 0CFF0h,0D100h,0D200h,0D300h,0D400h,0D500h,0D600h,0D700h
       dw 0D800h,0D900h,0DA00h,0DB00h,0DC00h,0DD00h,0DE00h,0DF00h
       dw 0DFF0h,0E080h,0E100h,0E180h,0E200h,0E280h,0E300h,0E380h
       dw 0E400h,0E480h,0E500h,0E580h,0E600h,0E680h,0E700h,0E780h
       dw 0E800h,0E880h,0E900h,0E980h,0EA00h,0EA80h,0EB00h,0EB80h
       dw 0EC00h,0EC80h,0ED00h,0ED80h,0EE00h,0EE80h,0EF00h,0EF80h
       dw 0EF80h
EndIf

;T_Period DW 0
;           C     C#    D     D#    E     F     F#    G     G#    A     A#    B  }  ; Tout x4
T_per0 DW 1AC0h*4,1940h*4,17D0h*4,1680h*4,1530h*4,1400h*4,12E0h*4,11D0h*4,10D0h*4,0FE0h*4,0F00h*4,0E28h*4   ;0 * 0-11  0-B
       DW 1AC0h*2,1940h*2,17D0h*2,1680h*2,1530h*2,1400h*2,12E0h*2,11D0h*2,10D0h*2,0FE0h*2,0F00h*2,0E28h*2   ;1 * 12-23 C-17
       DW 1AC0h,1940h,17D0h,1680h,1530h,1400h,12E0h,11D0h,10D0h,0FE0h,0F00h,0E28h   ;2 24-35 18-23
       DW 0D60h,0CA0h,0BE8h,0B40h,0A98h,0A00h,0970h,08E8h,0868h,07F0h,0780h,0714h   ;3 36-47
       DW 06B0h,0650h,05F4h,05A0h,054Ch,0500h,04B8h,0474h,0434h,03F8h,03C0h,038Ah   ;4 48-59
       DW 0358h,0328h,02FAh,02D0h,02A6h,0280h,025Ch,023Ah,021Ah,01FCh,01E0h,01C5h   ;5 60-71
       DW 01ACh,0194h,017Dh,0168h,0153h,0140h,012Eh,011Dh,010Dh,00FEh,00F0h,00E2h   ;6 72-83
       DW 00D6h,00CAh,00BEh,00B4h,00AAh,00A0h,0097h,008Fh,0087h,007Fh,0078h,0071h   ;7 84-95
       DW 006Bh,0065h,005Fh,005Ah,0055h,0050h,004Bh,0047h,0043h,003Fh,003Ch,0038h   ;8 *
       DW 0035h,0032h,002Fh,002Dh,002Ah,0028h,0025h,0023h,0021h,001Fh,001Eh,001Ch,0 ;9 *
;	   DW 001Ah,0019h,0017h,0016h,0015h,0014h,0012h,0011h,0010h,000Fh,000Fh,000Eh,0 ;8 *

ContrTable DB 73   ; Variable de Contr“le !!!

;***** fin structure MMSS_Table^ TP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Variables de gestion de la musique.                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;*** Bloc d'informations pour le Turbo Pascal ***
TPInfo:

Mix_Buffers_Completed   DB 0
;Current_DMA_Buffer_Nb   DB 0
Buffer_Size             DW 0   ; Frequency / 50
DMA_Buffers_Total_Size  DW 0
DMA_Buffers_Max_Size    DW 0
Buffer_Current_Out_Offs DW 0

C_Row             DB 0     ; Current Row Number
C_Sequence        DB 0     ; Current Sequence index number
C_pattern         DB 0     ; Current Pattern Number
Cmd_ModifyPattern DB 0     ; 1 => Change the sequence index (To C_Sequence)
C_Pattern_Seg     DW 0     ; Current Pattern Segment
Compt_50          DW 0     ; Buffer Size counter for Timer IRQ
Tempo             DB 6     ; Tempo actuel.
Cmpt_tempo        DB 0     ; Compteur pour le tempo.
BPM               DB 125   ; BPM Actuel.
BPM_Cnt           DW 0     ; Compteur pour le BPM.
Volume_General    DB 40h   ; Volume de la musique. (S3M, Etc..)

MMSS_Pause        DB 0

Ch_Control    DB Max_Channels DUP (0)
CH_Panning    DB Max_Channels DUP (0)
CH_Command    DW Max_Channels DUP (0)   ; Offset de la routine de commande
CH_Per_part   DW Max_Channels DUP (0)   ; Periode de la voie (partition)
CH_Smp_Pla    DB Max_Channels DUP (0)   ; Sample Playing
Ch_Note       DB Max_Channels DUP (0)
VVolume_Part  DB Max_Channels DUP (0)   ; Volume (dans la partition)
VVolume_re    DB Max_Channels DUP (0)   ; Volume (jou‚ r‚ellement)
VVolume       DB Max_Channels DUP (0)   ; Volume avec Volume_Global et Volume (+/-)
Ch_Vol_Left   DB Max_Channels DUP (0)
Ch_Vol_Right  DB Max_Channels DUP (0)
VCurrent_CMD  DB Max_Channels DUP (0)
VCurrent_PAR  DB Max_Channels DUP (0)
VSmp_Offset   DB Max_Channels DUP (0)

; Variables used for the Mixing
VOffset_actuel  DW Max_Channels DUP (0)
VPart_entiere   DB Max_Channels DUP (0)
VPart_decimale  DB Max_Channels DUP (0)
VPart_decimale2 DB Max_Channels DUP (0)
VAccumulateur   DW Max_Channels DUP (0)

VC4Spd                DW Max_Channels DUP (0) ; Ajustement de la p‚riode pour C4 (Def 8363)
Adresse_Table_periode DW Max_Channels DUP (0) ;          ''
If UseFineTune Eq Yes
VFineTune             DB Max_Channels DUP (0) ;          ''
EndIf
GUS_Frequency   DD Max_Channels DUP (0)  ; Frequency for GUS and Adlib, in Hz * 256
GUS_Controle    DB Max_Channels DUP (0)  ; Channel Control Mask (Volume, Period change, Key Off...)
MUS_OPLStream   DB 0                            ; Set to 1 if OPL Stream Music

ContrInfo DB 73 ; Control Variable

;*** Fin du Bloc d'informations pour le Turbo Pascal ***

V_Par_Instr          DB Max_Channels DUP (0)   ; Instrument Read from the Partition, for Display Only
V_Par_Sample         DB Max_Channels DUP (0)   ; Sample Read from the Partition

If XMCMD Eq Yes     ; FT2 Variables
V_Rel_Note          DB Max_Channels DUP (0)   ; XM Relative Note Save
VC_Exec             DW Max_Channels DUP (0)
EndIf



;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
;Û                                                              Û
;Û                     DEBUT DU PROGRAMME                       Û
;Û                                                              Û
;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Start_Output     Lancer la sortie sonore               ³
;³                                                           ³
;³     Entr‚e      Rien                                      ³
;³     Sortie:     AX<>0 => Erreur !!!                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


;oldvect_clavier  DD 0
;Ancien_int       DB 0   ;Sound Blaster IRQ
SB_DMA_Frequency DB 0   ;Valeur to envoyer to la Sound Blaster

  ; Caract‚ristiques de la sortie sonore
  ; (Pas accessible au Pascal pour eviter les problèmes)

Sortie_Sonore  DB 0
Use_DMA    DB 0
Utilise_Stereo DB 0
;Utilise_Mixage DB 0        ; No more applicable : Combine left and right channels in stereo
;DMA_Continu    DB 0


PStart_Output PROC FAR    ;Appel du Pascal (Fonction, renvoie l'Erreur )
        PUSH DS BP
        DS_ASM

        CALL Start_Output

		XOR AH,AH
        MOV AL,Erreur_Modm         ; Renvoyer le code d'erreur
        POP BP DS
        RET
PStart_Output ENDP

; *TEST
PStart_IRQ PROC FAR    ;Appel du Pascal (Fonction, renvoie l'Erreur )
        RET
PStart_IRQ ENDP

Start_Output PROC NEAR

        MOV Erreur_Modm,0

        MOV AX,Out_Frequency
        MOV Real_Frequency,AX
        CALL InitDevice             ; Initialize the Sound output variables

If Mod_Master eq yes
        MOV MUS_OPLStream,0
Endif
		
		CALL Init_OPL               ; Init OPL2/3 Delay and Port

        CMP Ch_Number_Digit,0
		JNE Start_Digital_Music

        MOV Sortie_Sonore,NoOut     ; Adlib or Tandy > No Wave Output

		CMP Type_Module,T_VGM       ; VGM Has its own check code
		JE Start_VGM
		
		CMP Ch_Number_Adlib,0
		JNE Start_Adlib_Music

        MOV Erreur_Modm,Err_Invalid_Channels
		RET

; *** Start Adlib based Music *** (OR TDY)
Start_Adlib_Music:

        CMP OPL_Type,0              ; OPL Present ?
		JNE @@OPLPresent
		CMP OPL_LPT_Type,0          ; OPL LPT Present ?
		JNE @@OPLPresent
        MOV Erreur_Modm,Err_OPL_NotFound
		RET       
@@OPLPresent:

        CMP Type_Module,T_RAD
        JE Start_RAD
        CMP Type_Module,T_IMF
		JE Start_IMF
        CMP Type_Module,T_RAW
		JE Start_RAW
		CMP Type_Module,T_DRO
		JE Start_DRO

        JMP Start_Adlib  ; Start S3M/SAT adlib based (Timer, no Digital DMA...)

Start_RAD:
If UseRAD Eq Yes
        JMP RAD_Start
Else
        MOV Erreur_Modm,Err_Invalid_MOD
        RET
EndIf
	
Start_IMF:
        JMP IMF_Start

Start_RAW:
        JMP RAW_Start

Start_DRO:
        JMP DRO_Start	

Start_VGM:
        JMP VGM_Start

; Start a music in .MMM Format (Digital)
Start_Digital_Music:

If UseGUS eq Yes
        CMP Sortie_sonore,GUS       ;teste GUS
        JNE Not_Start_GUS
		JMP Start_GUS
Not_Start_GUS:
EndIf

If DEBUG Eq Yes
        CALL MM_Display_Debug
Endif
                                    ;*** Choix de la sortie sonore ***
        CMP Sortie_sonore,SB        ;SB with DMA ?
        JE Lancer_DMA_SB
        CMP Sortie_sonore,SBpro     ;SBpro with DMA ?		
        JE Lancer_DMA_SB
        CMP Sortie_sonore,T_DAC
		JNE Start_Timer_Output
		JMP Start_TDYDAC
                                    ;Sinon => Sortie Timer
; *** Start Timer based DAC Outputs ****
Start_Timer_Output:

;		MOV DMA_Continu,1           ; No need to compute DMA Buffer address each 1/50

        CALL Init_Variables_Freq    ; Initialize Frequency based Variables (DMA Buffer Size, Period Divisor ...)

        CALL Init_Direct_DAC_IRQ    ;Init the variables for the Timer IRQ
        CMP Erreur_Modm,0
        JNZ Fin_Lancer_Timer        ;Erreur => Fin !!!!
	
		CALL DMA_Buffers_Preprocessing
  
        MOV AX,Buffer_Start_Offs
		MOV Buffer_Current_Out_Offs,AX      ; Init to Buffer Offset Start
;        MOV Offset_Buffer_Index,AX
		MOV W [Offset IRQ_DAC_Index-2],AX   ; Place the Index in the DAC IRQ Code
		MOV W [Offset IRQ_PCS_Index-2],AX   ; Place the Index in the DAC IRQ Code
		
		MOV AX,Seg_Volume
		MOV W [Offset IRQ_DAC_Seg_Volume-2],AX
        MOV W [Offset IRQ_PCS_Seg_Volume-2],AX
		
		MOV AX,Buffer_Size        ;Init the Timer Counter
        MOV Compt_50,AX           ;To Buffer Size
		
        CALL Start_Timer_IRQ

Fin_Lancer_Timer:
        RET
		
; *** Start the Sound Blaster Pro/16 DMA Output ****
Lancer_DMA_SB:
        MOV Use_DMA,1
		
        MOV AX,Out_Frequency
		CALL SB_ComputeFrequency
		MOV Real_Frequency,AX
        CALL Init_Variables_Freq
		
		CALL DMA_Buffers_Preprocessing

        CMP Sortie_sonore,SB        ;SB: don't set SBPro Stereo
        JE Start_SB_DMA
		
        CMP Utilise_stereo,1
        JE Start_SB_Stereo
        CALL Stop_stereo            ;Disable the SBP stereo	
        JMP Start_SB_DMA
Start_SB_Stereo:
        CALL Fixer_stereo           ;Enable the SBP stereo
Start_SB_DMA:

        MOV AL,IRQ_SB               ;AL <- Nø de L'IRQ SB
        MOV DX,OFFSET IRQ_Sound_Blaster
        CALL Change_IRQ
		
;       CALL Init_SB
        MOV AL,DMA_SB8
If UseMix16 Eq Yes	
		CMP Out_16Bit,1
		JNE Select_SB_DMA8
		MOV AL,DMA_SB16
Select_SB_DMA8:
EndIf

		MOV DMA_Channel,AL
        MOV AX,Buffer_Start_Offs
	    CALL Calcul_Adresse_DMA
        MOV CX,DMA_Buffers_Total_Size
		
        CALL Programmer_DMA         ;Programmer le controleur DMA
        CALL SB_Start               ;Lancer la Commande SB de sortie DMA

RET ; ERR MODM Test
        CMP Erreur_Modm,Err_SB      ;Si Erreur Sound Blaster, Stopper Imm‚diatement
        JNE Fin_Lancer_DMA_SBPro_16
        CALL EndIRQ
Fin_Lancer_DMA_SBPro_16:
        RET

If UseGUS eq Yes
Start_GUS:
        CALL UInit_Play
EndIf

Start_Adlib:                          ; Adlib use the same Timer IRQ as the GUS (Don't move this code)

        CALL Gestion_Sonore           ; Compute the first Row	

        MOV IRQ50_Partition,Offset Gestion_Sonore	
        MOV DX,OFFSET IRQ_Timer_50		
        CALL Start_Timer_50           ; Start the IRQ Timer at 50 Hz

        RET
Start_Output ENDP

; *** Start the Tandy DAC 8Bit DMA Output ****
Start_TDYDAC Proc Near

        MOV Utilise_stereo,0
        MOV Use_DMA,1

        CALL TDYDAC_ComputeFrequency
        CALL Init_Variables_Freq

        MOV AX,Buffer_Start_Offs   ; Start the Output at the Output Buffer Begining
	    CALL Calcul_Adresse_DMA

; compute the DMA vs Mix Offset Delta
		MOV AX,Buffer_Start_Offs
		SUB AX,HW_DMA_Buffer_Offset
		MOV MixDMA_OffsetDelta,AX

		CALL DMA_Buffers_Preprocessing	

;Writech 'D'
;Writech 's'
;MOV AX,DMA_Buffers_Total_Size
;CALL WriteWordH 
;Writech 'D'

		MOV CX,DMA_Buffers_Total_Size
		MOV DMA_Channel,1
        CALL Programmer_DMA        ;Program the DMA Controller

        MOV AL,7                   ;IRQ 7
        MOV DX,OFFSET IRQ_TDY_DAC
        CALL Change_IRQ

        CALL TDYDAC_Start

        MOV DX,OFFSET IRQ_Timer_TDY		
        CALL Start_Timer_50           ; Start the Timer IRQ at 50 Hz

        RET
Start_TDYDAC Endp

; *** Initialise the Sound Output / Output device and Mixing variables ******

; PP: Post Processing
; *** Mixing: Mono 8Bit ***     1
; * Unsigned Output
; M8   L/R: Buffer_Current_Mix_Offs   PP: Convert_NS_8Mono or Convert_PCSpeaker
; * Signed Output
; M8   L/R: Buffer_Current_Mix_Offs   PP: Do_Nothing (Mix in the DMA Buffer)

; *** Mixing: Mono 16Bit ***   3
; Unsigned Output
; M8  L/R: Left_Buffer_Offs         PP: Convert_NS_16_8Mono (16b to 8b Signed)
; Unsigned Output
; M8  L/R: Left_Buffer_Offs         PP: Not Implemented (16b to 8b Unsigned)
; M16 L/R: Buffer_Current_Mix_Offs   PP: Do_Nothing (Mix in the DMA Buffer)

; *** Mixing: Stereo 8Bit ***   2
; * Unsigned Output
; S8  L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Convert_NS_8Stereo
; * Signed Output (Not implemented for the moment)
; S8  L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Not Implemented (2xBuffer to Signed 8Bit Single Stereo)

; *** Mixing: Stereo 16Bit ***  4
; * Unsigned Output
; S8  L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Convert_NS_16_8Stereo    (2xBuffer 16b to 8b Unsigned Stereo)
; S16 L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Not Implemented (2xBuffer 16b to 16b Unsigned Stereo)
; * Signed Output (Not implemented for the moment)
; S8  L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Not Implemented (2xBuffer 16b to 8b Signed Stereo)    ! Possibility to optimize
; S16 L: Left_Buffer_OffsR: Right_Buffer_Offs PP: Not Implemented (2xBuffer 16b to 8b Signed Stereo)


; Buffer_Convert_Code : Code to use to convert the buffers.
; Convert_PCSpeaker
; Convert_NS_8Mono
; Convert_NS_16_8Mono
; Convert_NS_8Stereo	
; Convert_NS_16_8Stereo

InitDevice PROC NEAR

        MOV Volume_total,40h

; Mixing variables Init

        XOR AX,AX
        MOV Max_Mixed3,AL
        MOV IRQ_Cnt,AX
        MOV Slow_Mix1_Cnt,AX	
		MOV Slow_Mix2_Cnt,AX
		MOV Slow_Mix3_Cnt,AX
		MOV Volume_Skip,AL

; Channels limit variables init
		MOV Mix_Channels_Nb_MAX,AL ; Value to use if >0
		MOV Mix_Channels_Limit,AL  ; Value used and Displayed
        
		MOV AL,PMix_ChLimit_Type    ; 0 Off, 1: Auto 2: Manual
		MOV AH,0FFh
		TEST AL,AL
		JE MLT_End
		XOR AH,AH
		DEC AL
		JZ MLT_End
		MOV AH,PMix_ChLimit_Nb
MLT_End:
        MOV Mix_ChLimit_Nb,AH

; Output device and mixing Vars Init
		
		MOV AL,PSortie_Sonore
        MOV Sortie_Sonore,AL
        MOV AL,PUse_DMA
        MOV Use_DMA,AL
        MOV AL,PUse_Stereo
        MOV Utilise_Stereo,AL
		
;        MOV AL,PUtilise_Mixage
;        MOV Utilise_Mixage,AL
	
        MOV Mix_Buffers_Completed,1

        XOR AX,AX
		MOV Stopper_IRQ_SB,AL
        MOV Stop_Output,AL
		MOV Output_Stopped,AL
If UseMix16 Eq Yes	
		MOV Out_16Bit,AL
EndIf		
		MOV Out_Signed,AL
		MOV Mix_Mono_Use_Left,AL
        MOV Out_16Bit,AL
        MOV Buffer_Convert_Code,Offset Do_Nothing ; For Signed 8 and 16 Bit Mono
		
; Adjust the parameters for each sound Output

        CMP Sortie_Sonore,SB
		JE  InitDev_SBTDMono_8b
		CMP Sortie_Sonore,SBPro
		JNE InitDev_NoSB
		JMP  InitDev_SBPro
InitDev_NoSB:
; * No Sound Blaster
        CMP Sortie_Sonore,T_DAC
		JE InitDev_SBTDMono_8b
; * No Tandy DAC		
        MOV Use_DMA,0
		CMP Sortie_Sonore,Gus
		JE InitDev_GUS		
; * No GUS and SB
        CMP Sortie_Sonore,HPint
		JNE InitDev_No_PCSpeaker
; * PC Speaker
        MOV Buffer_Convert_Code,Offset Convert_PCSpeaker
If UseMix16 Eq Yes		
		MOV Mix_16Bit,0                  ; !!! Change the 16Bit settings value.
EndIf		
		RET

; * 8 Bit Not signed devices (DAC)
InitDev_No_PCSpeaker:		
		MOV Utilise_Stereo,0
If UseMix16 Eq Yes
        CMP Mix_16Bit,1
        JE InitDev_NoPC_16bMix
EndIf		
		MOV Buffer_Convert_Code,Offset Convert_NS_8Mono
        RET

; * 8 Bit Not signed devices (DAC) 16Bit Mix
If UseMix16 Eq Yes
InitDev_NoPC_16bMix:
        MOV Buffer_Convert_Code,Offset Convert_NS_16_8Mono
        MOV Mix_Mono_Use_Left,1
;		Writechar 'a'
        RET
Endif		

InitDev_GUS:
        MOV Utilise_Stereo,1
        RET
		
; * SB Mono or Tandy DAC 8b
InitDev_SBTDMono_8b:
		MOV Utilise_Stereo,0
If UseMix16 Eq Yes
        CMP Mix_16Bit,1
        JE InitDev_SBMono_16bMix
EndIf		
; * 8b Not signed (SB, Tandy DAC)
		MOV Buffer_Convert_Code,Offset Convert_NS_8Mono
        RET	
		
; ; * 16b to 8b Not signed (SB, Tandy DAC)
If UseMix16 Eq Yes
InitDev_SBMono_16bMix:
        MOV Buffer_Convert_Code,Offset Convert_NS_16_8Mono
        MOV Mix_Mono_Use_Left,1
;WriteChar 'b'		
		RET
EndIf
		
InitDev_SBPro:  ; SB Pro or 16
        CMP Utilise_Stereo,1
		JE InitDev_SBStereo ; Go to SB Stereo 8b
;		XOR AX,AX
        CMP Type_SB,T_SB16 
        JE InitDev_SB16Mono ; Go to SB16 Mono 16b
; * SB/ SB Pro Mono
        JMP InitDev_SBTDMono_8b

; * SB16 Mono *
InitDev_SB16Mono:
If UseMix16 Eq Yes
		CMP Mix_16Bit,0          ; Mix in 16 Bit ?
		JE InitDev_SB16Mono_8b
; * SB16 Mono, Mix 16Bit
		MOV Out_16Bit,1          ; 16 Bit Output
        MOV Out_Signed,1         ; Signed, No Buffer convertion
		RET
; * SB16 Mono, Mix 8Bit
InitDev_SB16Mono_8b:
EndIf
        MOV Out_Signed,1         ; Signed, No Buffer convertion
        RET
		
InitDev_SBStereo:
        CMP Type_SB,T_SB16 
        JE InitDev_SB16Stereo		
; * SBPro Stereo *
If UseMix16 Eq Yes
        CMP Mix_16Bit,1
        JE InitDev_SBProStereo_16bMix
EndIf		
; * SBPro Stereo 8Bit Mix
        MOV Buffer_Convert_Code,Offset Convert_NS_8Stereo	
        RET
If UseMix16 Eq Yes
InitDev_SBProStereo_16bMix:
; * SBPro Stereo 16Bit Mix
        MOV Buffer_Convert_Code,Offset Convert_NS_16_8Stereo
		RET
EndIf		

; * SB16 Stereo      ; Mix 16Bit not supported.
InitDev_SB16Stereo:
If UseMix16 Eq Yes
        CMP Mix_16Bit,1
        JE InitDev_SB16Stereo_16bMix
EndIf		
        MOV Buffer_Convert_Code,Offset Convert_NS_8Stereo		
		RET
;		Writechar '6'
If UseMix16 Eq Yes
InitDev_SB16Stereo_16bMix:
        MOV Buffer_Convert_Code,Offset Convert_NS_16_8Stereo
        RET
EndIf		
InitDevice ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³              Initialisation de la musique                 ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

PStart_Music PROC FAR    ;Appel du Pascal (Fonction, renvoie l'Erreur )
        PUSH DS BP
        DS_ASM
        CALL Init_Var_MOD
		XOR AX,AX
        MOV AL,Erreur_Modm         ; Renvoyer le code d'erreur
        POP BP DS
        RET
PStart_Music ENDP

Init_Var_MOD PROC NEAR
        CLI
        CLD                       ; Toutes les copies en sens croissant
        DS_ASM
        ES_ASM

        CMP Type_Module,T_XM
        JE Not_Copy_SmpNb
;Not XM: Instr number + Sample Number	   
        MOV AL,Nb_Total_Samples
        MOV Nb_Instr,AL
Not_Copy_SmpNb:

        MOV Erreur_Modm,0
        XOR CX,CX                 ; Annule partie haute compteur
		XOR DX,DX
		MOV DL,Ch_Number

; Init Var to FFFFh

        MOV AX,0FFFFh
        MOV DL,Ch_Number

        MOV DI,OFFSET CH_Smp_Pla
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Sample to 0FFh

        MOV DI,OFFSET V_Par_Instr
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Sample to 0FFh		

        MOV DI,OFFSET V_Par_Sample
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Sample to 0FFh		

        MOV DI,OFFSET CH_Per_part
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels Periode_V to FFFFh		

		MOV DI,OFFSET Ch_Note
        MOV CL,DL
        REP STOSB                 ; Initialize Notes to FFh

; Init Variable to various default values

		MOV DI,OFFSET Ch_Control
        MOV AL,CM_Stopped
        MOV CL,DL
        REP STOSB                 ; "Active" les Ch_Number premiŠres voies

        MOV DI,OFFSET CH_Command
        MOV AX,OFFSET Do_Nothing
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels CH_Command to 'Rien'

If XMCMD Eq Yes	 
        MOV DI,OFFSET VC_Exec
        MOV AX,OFFSET Do_Nothing
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels CH_Command to 'Rien'  
EndIf
		
		
        MOV DI,Offset Table_Vibrato
        MOV AX,Offset Ta_vib
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels Table_Vibrato to Ta_vib

        MOV DI,Offset Table_Tremolo
        MOV AX,Offset Ta_vib
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels Table_Tremolo to Ta_vib		
		
        MOV AX,8363
        MOV DI,OFFSET VC4Spd
        MOV CL,DL
        REP STOSW                 ; annule les Max_Channels VC4Spd 0
		

; ****************  Init Var to 0  ***********

        XOR AX,AX
        MOV DI,OFFSET VVolume_Part
        MOV CL,DL
        REP STOSB                 ; annule les Max_Channels VVolume_Part

        MOV DI,OFFSET VPart_entiere
        MOV CL,DL
        REP STOSW                 ; annule les Max_Channels Partie_entiere 0

        MOV DI,OFFSET VAccumulateur
        MOV CL,DL
        REP STOSW                 ; annule les Max_Channels Accumulateur 0

        MOV DI,OFFSET VVolume
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels VVolume to 0

        MOV DI,OFFSET VVolume_re
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels VVolume_re to 0

        MOV DI,OFFSET Retrig_V_Tr
        XOR AL,AL
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Retrig_Vibr to 0

        MOV DI,OFFSET TSmp_Offs
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels TSmp_Offs to 0

        MOV DI,OFFSET Param_pr_dn
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Param_pr_dn to 0

        MOV DI,OFFSET Param_pr_up
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Param_pr_up to 0

        MOV DI,OFFSET Param_VS
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Param_VS to 0		

        MOV DI,OFFSET Cmpt_Commande
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Param_VS to 0		
		
        MOV DI,OFFSET Per_tone_prt
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Period Tone Portamento to 0
		
        MOV DI,OFFSET VSmp_Offset
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Sample Offsets
		

If UseGUS eq yes
        MOV DI,OFFSET GUS_Frequency
        MOV CL,DL
		SHL CL,1
        REP STOSW                 ; Init the Max_Channels GUS_Frequency to 0

        MOV DI,OFFSET GUS_Controle
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels GUS_Controle to 0
EndIf

        MOV DI,OFFSET VCurrent_CMD
        MOV CL,DL
        REP STOSB 
        
		MOV DI,OFFSET VCurrent_PAR
        MOV CL,DL
        REP STOSB 

        ;Initialisation des variables Adlib
If UseOPL2 eq Yes
;        XOR AL,AL
;        MOV DI,OFFSET Old_KSL_TL1
;        MOV CL,9
;        REP STOSB                 ; Init the 9 Old_KSL_TL1 to 0

;        MOV DI,OFFSET Old_KSL_TL2
;        MOV CL,9
;        REP STOSB                 ; Init the 9 Old_KSL_TL2 to 0

        MOV DI,OFFSET Old_Key_B0
        MOV CL,9
        REP STOSB                 ; Init the 9 Old_Key to 0

        MOV DI,OFFSET Old_FB
        MOV CL,9
        REP STOSB                 ; Init the 9 Old_FB to 0
EndIf

If XMCMD Eq Yes
        MOV DI,OFFSET  V_Rel_Note
        MOV CL,DL
        REP STOSB  
Endif

If Mod_Master Eq yes              ;Mod Master Display Variables init.

; Introscan Display ?
        XOR AX,AX
	    CMP Duree_intro,AL
        JE Disable_Introscan_Display
	    INC AL
Disable_Introscan_Display:
        MOV Display_IntroScan,AL
 
 ; Shuffle Display ?	
        DS_TP
        MOV AL,Shuffle
        DS_ASM
		MOV Display_Shuffle,AL


		CMP Seg_Video,0B800h
		JE Not_Init_Monochrome
; Monochrome (Hercule/MCA) Display
        MOV AL,M_WoB
		MOV C_MSG_Off,AL
		
        MOV AL,M_BoW
        MOV C_MSG_On_Intro,AL
        MOV C_MSG_On_Shuff,AL
        MOV C_MSG_On_Pause,AL
        MOV C_MSG_On_Rep,AL
		
		MOV C_Grey_M_Black,0
		
Not_Init_Monochrome:

        MOV DI,OFFSET Anc_vol_V1
        MOV AL,1
        MOV CL,DL
        REP STOSB                 ; Init the Max_Channels Anc_vol_V to 1

        MOV DI,OFFSET Old_pos
        MOV AX,80*2*29
        MOV CL,DL
        REP STOSW                 ; Init the Max_Channels Old_pos to 4000

        XOR AX,AX
        MOV N_Voie_aff,AL
		MOV MMSS_Pause,AL
        MOV Afficher_fin_voies,AL
        DS_TP
        MOV TP_Chrono_sec,AL
        MOV TP_Chrono_min,AL
        MOV TP_Fading,AL
        MOV Activer_Shell,AL
        DS_ASM
        MOV Touche_fin,Tfin_normale
EndIf

        MOV AL,Tempo_Start
        MOV Tempo,AL              ; Initialise la Tempo de d‚part.
        MOV Cmpt_Tempo,1          ; Initialisation du Tempo : Tempo 1 to Start with a Command

        MOV AL,BPM_Start          ; Initialisation des BPM...
        MOV BPM,AL                ; BPM de d‚part.
		CALL Exec_SetBPM
		MOV BPM_Cnt,0
		
        MOV AL,Vol_Gene_Depart
        MOV Volume_General,AL      ; Volume G‚n‚ral d‚part
		
		XOR AX,AX
        MOV Cmpt_Boucles,AL
        MOV Bouclage_en_cours,AL
        MOV DoJumpLoop,AL
        MOV Cmd_ModifyPattern,AL

        MOV Musique_Terminee,AL    ; Activer la lecture de la partition
		
        MOV PattBreakRow,AL
        MOV PJumpPattern,AL
        MOV Debut_Boucle_Pattern,AL ; Pour JumpLoop
        MOV C_Patt_Length,1
        MOV C_Row,AL             ; => Chercher le 1er pattern to la 1ø note
        MOV C_Sequence,AL
        MOV DoPatternBreak,AL
;        MOV MMSS_Pause ,AL
        MOV Pattern_Vide,AL         ; Pattern non vide

                  ;-- Mise en place des octaves --

        XOR BX,BX
        MOV BL,Octave_Min ; Max Period of the Min Octave
        SHL BX,1
        MOV AX,Maxi_Octaves[BX]
        MOV Max_Period,AX
        MOV BL,Octave_Max ; Min Period of the Max Octave
        SHL BX,1
        MOV DX,Mini_Octaves[BX]
        MOV Min_Period,DX
        SUB AX,DX
        MOV Moyen_Notes,AX

        MOV AL,Pos_de_restart     ;Initialisation du bouclage du module
        DEC AL
        CMP AL,Sequence_Len
        JBE Ajuster_Bouclage
        MOV Pos_de_restart,1
Ajuster_Bouclage:

        STI
        RET

Init_Var_MOD ENDP


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Init Direct DAC IRQ                                     ³
;³   Configure the Direct DAC interrupts                     ³
;³   (Code auto g‚n‚r‚)                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Init_Direct_DAC_IRQ PROC NEAR
       DS_ASM

                                 ;Type de sortie (SB, Beeper ...)
       CMP Sortie_sonore,HPint
       JNZ Pas_c_beeper          ;HP Interne
       RET
Pas_c_beeper:                    ;D/A Sur LPT1
       CMP Sortie_sonore,LPT1
       JNZ Pas_c_LPT1
	   MOV AX,LPT1_Port
       OR AX,AX
       JNZ LPT1_Port_Ok
       JMP C_Err_Sortie_Introuvable
LPT1_Port_Ok:
	   MOV W Offset IRQ_DAC_Port_Instr-2,AX  ; Change the DAC IRQ Code Port
       RET

Pas_c_LPT1:                      ;D/A Sur LPT2
       CMP Sortie_sonore,LPT2
       JNZ Pas_c_LPT2
	   MOV AX,LPT2_Port
       OR AX,AX
       JNZ LPT2_Port_Ok
       JMP C_Err_Sortie_Introuvable
LPT2_Port_Ok:
	   MOV W Offset IRQ_DAC_Port_Instr-2,AX  ; Change the DAC IRQ Code Port
       RET
	   
Pas_c_LPT2:                      

       CMP Sortie_sonore,C_DAC
       JNZ Pas_C_DAC
	   MOV AX,Port_CustomDAC
       OR AX,AX
       JNZ Port_CustomDAC_Ok
       JMP C_Err_Sortie_Introuvable
Port_CustomDAC_Ok:
	   MOV W Offset IRQ_DAC_Port_Instr-2,AX  ; Change the DAC IRQ Code Port	   
       RET
Pas_C_DAC:
                                  ;NO MORE SUPPORTED: Adlib   
;       CMP Sortie_sonore,Adlib
;       JNZ Pas_c_Adlib
;	    MOV OUT_Procedure,Offset OUT_Adlib
;       RET
;Pas_c_Adlib:                     ;NO MORE SUPPORTED: Disney SS Sur LPT1
;       CMP Sortie_sonore,LPT1
;       JNZ Pas_c_Disney1
;       CMP LPT1_Port,0
;       JNZ Port_Disney1_bon
;       JMP C_Err_Sortie_Introuvable
;Port_Disney1_Bon:
;       MOV OUT_Procedure,Offset OUT_Disney1
;       RET
;Pas_c_Disney1:                   ;NO MORE SUPPORTED: Disney SS Sur LPT2
;       CMP Sortie_sonore,LPT2
;       JNZ C_Err_Sortie_Introuvable
;       CMP LPT2_Port,0
;       JNZ Port_Disney2_bon
;       JMP C_Err_Sortie_Introuvable
;Port_Disney2_Bon:
;       MOV OUT_Procedure,Offset OUT_Disney2
;       RET
	   
C_Err_Sortie_Introuvable:
      MOV Erreur_Modm,Err_Output_NotFound 
      RET
	  
Init_Direct_DAC_IRQ ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Clean_Buffers_DMA: Clean the DMA Buffers for the Pause       ³
;³                                                               ³
;³  Unsigned -> 80h signed or 16Bit -> 0h                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Clean_Buffers_DMA Proc Near
        PUSH ES

        CLD
        MOV DI,Buffer_Start_Offs
        MOV ES,Seg_Volume      ; ES=Volume table and Buffers segment

        MOV CX,DMA_Buffers_End_Offs
		SUB CX,DI
		
        MOV AX,8080h           ; Signed
        CMP Out_Signed,1
        JNE Clean_Buffer_NotSigned
        XOR AX,AX              ; Not Signed
Clean_Buffer_NotSigned:

		SHR CX,1               ; Compute the Buffers Real Size /2
		JNC Clean_Buffers_DMA_Odd
		STOSB
Clean_Buffers_DMA_Odd:
        REP STOSW             ; Clean the Buffer

        POP ES
        RET
Clean_Buffers_DMA Endp


;-----------------------------------------------------------
; Pre calculate the DMA Buffers before starting the Output
;-----------------------------------------------------------
Preproc_Loop DB 0

DMA_Buffers_Preprocessing Proc Near


	    
		XOR AX,AX
		MOV Buffer_Ahead_Cnt,AL
        MOV DMA_Buffer_Playing,AL
		MOV DMA_Buffer_Mixing,AL
	
        MOV Preprocessing,1

		MOV AL,Buffers_Ahead_Target
        MOV Preproc_Loop,AL

		MOV AX,Buffer_Start_Offs 
        MOV Buffer_Current_Mix_Offs,AX  ; Start at the Buffer begining

DMA_PreprocessingLoop:
        CALL Gestion_Sonore         ; Fill the Buffers
        DEC Preproc_Loop
        JNZ DMA_PreprocessingLoop
		
        MOV Preprocessing,0

        RET
DMA_Buffers_Preprocessing Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³           -= Set the next Buffer address =-
;³ Register changed : AX                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Add Buffer_Real_Size and Go back if the @ is above or equal to the DMA/Output Buffer end

Move_Buffer_Offset Proc Near  ; Set the Next Mixing Buffer Offset

		MOV AX,Buffer_Current_Mix_Offs
		ADD AX,Buffer_Real_Size

		CMP AX,DMA_Buffers_End_Offs  ; Next Buffer_Current_Mix_Offs = Buffer_Current_Mix_Offs+Buffer_Real_Size
		JB DMA_Buffer_End_NotReached ; End not reached: Ok we can mix there

        MOV AX,Buffer_Start_Offs     ; Next BufferStart + Buffer End >  Start at the Begining (Sound Blaster / Timer DAC)
		MOV Buffer_Current_Mix_Offs,AX	
		RET

DMA_Buffer_End_NotReached:
		MOV Buffer_Current_Mix_Offs,AX	
        RET
Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Init_Variables_Freq  Initialize all the Frequency        ³
;³                       Based variables                     ³
;³  SB_ComputeFrequency Must be started before                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Init_Variables_Freq Proc Near

; ** Calculate Buffer Size
        XOR DX,DX                
        MOV AX,Real_Frequency
        MOV BH,0
        MOV BL,Vitesse_Ticks     ; Nb of Tick per second (50)
        DIV BX
                                 ; AX=Buffer Size Trunc(Frequency/Tick)
        SHL DX,1
		JNC Not_Adjust_BSize
        INC AX                   ; Perform a Round, not a Trunc		
Not_Adjust_BSize:                ; AX=Round(Frequency/Tick)

; ** Calculate the Nb of 1, 4 and 64 samples Block
        MOV BX,AX
		AND BX,00000011b         ; Nb of Bytes to Mix at the end.
        MOV Mix_Loop1_Nb,BL

        MOV Buffer_Size,AX       ; ** Buffer_Size
		
		SHR AX,1
		SHR AX,1

		AND AX,00001111b
		MOV Mix_Loop4_Nb,AX      ; Number of 4 Bytes mix loop (Remaining after the 64 Bytes Loops)
		MOV AX,Buffer_Size
		MOV CL,6
		SHR AX,CL
		MOV Mix_Loop64_Nb,AX     ; Number of 64 Bytes mix loop

; ** Calculate the value for Amiga Period to Frequency conversion
        ; (1712*8363*256) / Frequency      ; OPT Improved precision (32b/16b) (New Precision, 3/12/20)
        MOV BX,Real_Frequency
		
        XOR DX,DX
		MOV AX,0DA77h
		DIV BX		
		MOV P_Amiga_h,AX
		MOV AX,9000h
		DIV BX
		MOV P_Amiga_l,AX

        MOV BX,Real_Frequency
		CALL Timer_HzToPeriod   ; Put the value in Periode_timer
		
        MOV AL,Vitesse_Ticks	
	    MOV Chrono_50,AL
		
;        MOV AX,0FFFFh
;        XOR DX,DX
;        MOV BX,Periode_timer       ; Attention, calculer la valeur
;        DIV BX
;        MOV Valeur_18,AX
;        MOV Cpt_appel_ancien_int,1 ;Calculs pour appeler l'IRQ 18,2 fois/sec.

; ** Calculate the Real Buffer Sizes (Number of Buffers to calculate and so on)
        MOV AX,Buffer_Size
        CMP Utilise_Stereo,1
        JNE Pas_Doubler_Tampon2
        SHL AX,1                   ; Stereo > Size *2
Pas_Doubler_Tampon2:
If UseMix16 Eq Yes
        CMP Out_16Bit,0
		JE No_16Bit_DMA_Buffer
        SHL AX,1                   ; 16 Bit > Size *2		
No_16Bit_DMA_Buffer:
Endif
        MOV Buffer_Real_Size,AX   ; ** Buffer_Real_Size = Buffer_Size x2 if Stereo x2 if 16Bit
        MOV DMA_Buffer_Size,AX    ; ** DMA_Buffer_Size = Buffer_Real_Size

        XOR DX,DX
		MOV AX,DMA_Buffers_Max_Size
		MOV BX,Buffer_Real_Size
        MOV DMA_Buffers_Max_NB,AL

; ** Variables init for SB		

        MOV AL,5
		MOV DMA_Buffers_NB,AL       ; ** DMA_Buffers_NB
        MOV Buffers_Total_Nb,AL     ; ** Buffers_Total_Nb

        MOV Buffers_Ahead_Min,1     ; ** Buffers_Ahead_Min
        MOV Buffers_Ahead_Min3,4    ; ** Buffers_Ahead_Min		
        MOV Buffers_Ahead_Target,5  ; ** Buffers_Ahead_Target

        CMP Sortie_sonore,T_DAC
		JNE Init_Var_No_TDAC

; ** Variables init for Tandy DAC
; 9 Max at 48KHz
        MOV AL,9
		MOV DMA_Buffers_NB,AL       ; ** DMA_Buffers_NB
        MOV Buffers_Total_Nb,AL     ; ** Buffers_Total_Nb
		DEC AL
		DEC AL                      ; Target : 7
        MOV Buffers_Ahead_Target,AL ; ** Buffers_Ahead_Target

        MOV Buffers_Ahead_Min,2     ; ** Buffers_Ahead_Min
	
; Compute the Offset Delta limits. (Mixed - Playing)
        XOR BX,BX
        MOV AX,Buffer_Size
        MOV MixDelta_Slow,AX
        MOV BL,Buffers_Ahead_Min ; Def 2
		MUL BX
		MOV MixDelta_Min,AX      ; Buffer_Real_Size * Buffers_Ahead_Min
		ADD AX,Buffer_Size
		MOV MixDelta_2,AX        ; MixDelta_Min + Buffer_Real_Size    : Apply VolLimit3
		ADD AX,Buffer_Size
		MOV MixDelta_3,AX        ; MixDelta_Min + 2*Buffer_Real_Size  : Apply VolLimit2
		ADD AX,Buffer_Size
		MOV MixDelta_4,AX        ; MixDelta_Min + 3*Buffer_Real_Size  : Increase Volume
        MOV AX,Buffer_Size
        MOV BL,Buffers_Ahead_Target ; Buffer_Real_Size * Buffers_Ahead_Target
		MUL BX
		MOV MixDelta_Target,AX
		
Init_Var_No_TDAC:

; ** Calculate the Size to put in the DMA Controller **

		MOV BX,DMA_Buffer_Size
		XOR AX,AX
		MOV AL,DMA_Buffers_NB      
		MUL BX                     ; AX=DMA_Buffers_NB * Buffer_Real_Size

        MOV DMA_Buffers_Total_Size,AX ; ** DMA_Buffers_Total_Size
		ADD AX,Buffer_Start_Offs      ; End of the DMA Buffers
		MOV DMA_Buffers_End_Offs,AX   ; ** DMA_Buffers_End_Offs
			
        RET
Init_Variables_Freq EndP

; Activate the PC Speaker output, Change the Timer IRQ and change the Timer Frequency


  ; 8253 PIT Mode control (port 0x43) values

  TIMER0 EQU 00h
  TIMER1 EQU 40h
  TIMER2 EQU 80h

  LATCH  EQU 00h
  LSB    EQU 10h
  MSB    EQU 20h
  BOTH   EQU 30h ; LSB first, then MSB

  MODE0  EQU 00h ; Interrupt on terminal count: low during countdown then high                            (useful for PWM)
  MODE1  EQU 02h ; Programmable one shot      : low from gate rising to end of countdown
  MODE2  EQU 04h ; Rate generator             : output low for one cycle out of N                         (useful for timing things)
  MODE3  EQU 06h ; Square wave generator      : high for ceil(n/2) and low for floor(n/2)                 (useful for beepy sounds)
  MODE4  EQU 08h ; Software triggered strobe  : high during countdown then low for one cycle
  MODE5  EQU 0ah ; Hardware triggered strobe  : wait for gate rising, then high during countdown, then low for one cycle

  BINARY EQU 00h
  BCD    EQU 01h

Start_Timer_IRQ PROC NEAR
       PUSH AX ES

       CMP Sortie_sonore,HPint
       JNZ Pas_Init_beeper       ;HP Interne

       IN AL,61h                 ;Activate the PC Speaker (Port B Bit 1)
       OR AL,03h
       OUT 61h,AL

       mov al,TIMER2+LSB+MODE0+BINARY   ; 10010000b
       out 43h,al
       mov al,01h
       out 42h,al  ; Counter 2 count = 1 - terminate count quickly

Pas_Init_Beeper:

       MOV DX,Offset IRQ_Timer_DAC   ; Generic DAC Output IRQ
	   CMP Sortie_sonore,HPint
	   JNE Not_Speaker_IRQ           ; PC Speaker IRQ
	   MOV DX,Offset IRQ_Timer_PCS
Not_Speaker_IRQ:

       CALL Change_Timer_IRQ      ; Change the Timer IRQ
       
       MOV AX,Periode_timer
       CALL Set_Timer0_Period     ; Change Timer Frequency

       POP ES AX
       RET
Start_Timer_IRQ ENDP

Stop_Timer PROC NEAR
        PUSH AX ES

        IN AL,61h        ;Stopper le H.P. Interne
        AND AL,0FCh
        OUT 61h,AL

        CLI
        XOR AX,AX
        CALL Set_Timer0_Period
        CALL Restore_Timer_IRQ
        STI

        MOV Output_Stopped,1
        POP ES AX
        RET
Stop_Timer ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                               ³
;³                  Nouvelles Interruptions                      ³
;³                                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; Read the Tandy DAC Position from the DMA
; Then, calculate the Mixing Buffer position Vs DMA
; Output BX : CurrentMix_Delta
Update_BuffersDelta Proc Near
; Writech':'
        MOV DL,1 ; DMA channel 1
        CALL DMA8_ReadOffset

        ADD AX,MixDMA_OffsetDelta
		MOV Buffer_Current_Out_Offs,AX  ; TDY : Save Current DMA Offset (For Display Only)
		
		MOV BX,Buffer_Current_Mix_Offs  ; Offset of the Last mixed Byte
		CMP BX,AX
		JAE @@MixIsAbove
		ADD BX,DMA_Buffers_Total_Size   ; Mix Buffer is before > Add the buffer Size
@@MixIsAbove:
        SUB BX,AX
		MOV CurrentMix_Delta,BX
			
        MOV Buffer_Ahead_Cnt,6    ; To avoid to cut the mixing.
		CMP BX,MixDelta_Min
		JA @@MixAboveMin
		MOV AL,Buffers_Ahead_Min  ; Cut the mixing or don't mix the next buffer (Slow)
		MOV Buffer_Ahead_Cnt,AL
@@MixAboveMin:
        RET
Update_BuffersDelta Endp

; Tandy DAC: IRQ for the end of the DMA buffer: Only Aknowledge the IRQ
IRQ_TDY_DAC Proc Far

		PUSH AX
		PUSH DX
        PUSH DS
        DS_ASM

; TDY DAC Acknowledge ?
	    MOV DX,CS:TDYDAC_Port
        IN AL,DX
;       TEST AL,8        ; Does not work with DosBox
;       JZ IRQ_TDY_NotDAC

; Clear the DMA interrupt at the sound chip
        AND AL,0F7h
        OUT DX,AL
        OR AL,8
        OUT DX,AL

; IRQ Acknowledge
        MOV AL,20h
        OUT 20h,AL
        STI

;Writech 'I'
;CALL Affiche_DMA_Addr

IRQ_TDY_NotDAC:

		POP DS
		POP DX
        POP AX
        IRET
IRQ_TDY_DAC Endp

Pause_TDY_DAC:
;WriteCh 'P'
        CALL Move_Buffer_Offset

        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

; Timer run at 50Hz, to Update the Mix vs DMA progress ans start the mixing
IRQ_Timer_TDY Proc Far
        PUSH AX
        PUSH BX
        PUSH DX
        PUSH DS
        PUSH ES
        DS_ASM
		
; IRQ Acknowledge
        MOV AL,20h
        OUT 20h,AL
        STI

;WriteCh 'T'
;CALL Affiche_DMA_Addr

; ** Compare the DMA Offset with the Last Mixed Offset

        CALL Update_BuffersDelta

        CMP MMSS_Pause,1
        JE Pause_TDY_DAC

@@MixDeltaMin_NotReached:
 
        CMP Stopper_IRQ_SB,1
        JE IRQ_TDY_Stop                 ; The End > Stop the DMA/IRQ

        CMP Mix_Buffers_Completed,1     ; Mix Not Complete (Still in progress), Skip
		JNE IRQ_TDY_SkipPartition

        MOV AX,CurrentMix_Delta
        CMP AX,MixDelta_Target          ; Current Delta >= Target, Skip
		JAE IRQ_TDY_SkipPartition

		PUSH CX
		PUSH SI
		PUSH DI
		PUSH BP
        CALL Gestion_Sonore   ; Read the partition and Mix the Buffers
        POP BP
		POP DI
		POP SI
		POP CX
		JMP IRQ_TDY_End

IRQ_TDY_SkipPartition:

IRQ_TDY_End:
        INC IRQ_Cnt
		
        CMP Stop_Output,1  ; Stopper la sortie sonore ?
        JNE IRQ_TDY_NotStop
        MOV Stopper_IRQ_SB,1  ; Stop the DMA/IRQ the next time.  !! To check if it is correct
IRQ_TDY_NotStop:
 
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

IRQ_TDY_Stop:                   ; Pause or End...

        CALL Stop_Timer_50

        CALL TDYDAC_Stop

        PUSH DI
		CALL EndIRQ           ; Put back the IRQ
        POP DI
		
		MOV AL,0
		CALL TDYDAC_SetVol    ; Set Volume to 0 (Need Ramp Down)
		
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

IRQ_Timer_TDY Endp
      
;******************* Interruption Sound Blaster **********************

Stopper_IRQ_SB DB 0

Pause_SB_IRQ:
        CALL Move_Buffer_Offset
		
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

IRQ_Sound_Blaster Proc Near
		PUSH AX
		PUSH BX
		PUSH DX
        PUSH DS
		PUSH ES
        DS_ASM
		
; SB IRQ Acknowledge
        MOV BX,0Eh
If UseMix16 Eq Yes	
	    CMP Out_16Bit,0
	    JE SBIRQ__8BitAck
        INC BX
SBIRQ__8BitAck:
EndIf
        MOV DX,SB_BasePort
        ADD DX,BX
        IN AL,DX        ; Read port 2xEh for 8Bit, 2xFh for 16 Bit

; IRQ Controller IRQ Acknowledge
        MOV AL,20h
        OUT 20h,AL
        OUT 0A0h,AL
        STI

; Check if Pause or End
		
        CMP MMSS_Pause ,1
        JE Pause_SB_IRQ
		
        CMP Stopper_IRQ_SB,1
        JE Fin_IRQ_SB           ; The End > Stop the DMA/IRQ

;        CMP DMA_Continu,1
;        JE Exec_Partition
		
;        writechar 'R'          ; Debug
                                ; No DMA AutoInit -> Restart the SB DMA
;		CALL Restart_DMA_NC_SB  ; Use AX, BX, DX Registers

Exec_Partition:

		DEC Buffer_Ahead_Cnt     ; ** One more buffer Played

        CMP Mix_Buffers_Completed,1     ; Mix Not Complete : Do not Mix
        JNE Pas_calc_part

		PUSH CX
		PUSH SI
		PUSH DI
		PUSH BP
        CALL Gestion_Sonore   ; Read the partition and Mix the Buffers
        POP BP
		POP DI
		POP SI
		POP CX
		JMP IRQ_SB_End

Pas_calc_part:
; If the Buffers are not completed, update the debug Values
        MOV AL,Buffer_Ahead_Cnt
        MOV BL,Buffers_Ahead_Min3 ; Buffers_Ahead_Min +3		
		CMP AL,BL
        JAE	IRQ_SB_End
		INC Slow_Mix1_Cnt
		DEC BL
        CMP AL,BL
		JE IRQ_SB_End
		INC Slow_Mix2_Cnt
		DEC BL
        CMP AL,BL
		JE IRQ_SB_End
		INC Slow_Mix3_Cnt
		
IRQ_SB_End:
        INC IRQ_Cnt
		
        CMP Stop_Output,1  ; Stopper la sortie sonore ?
        JNE Pas_Stopper_IRQ_SB
        MOV Stopper_IRQ_SB,1  ; Lancer l'arrˆt de l'IRQ au prochain appel
Pas_Stopper_IRQ_SB:
;        CMP Erreur_Modm,Err_SB ;Si Erreur Sound Blaster, Stopper Immediatement
;        JE  Fin_IRQ_SB
 
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

Fin_IRQ_SB:                   ; Pause ou fin de la sortie...

        CALL Init_Sb          ; Change AX DX

        PUSH DI
		CALL EndIRQ           ; Put back the IRQ
        POP DI
		
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX
        IRET

IRQ_Sound_Blaster Endp

EndIRQ Proc Near
        CALL Restaurer_IRQ    ; Fin de la sortie
        MOV Output_Stopped,1
        RET
EndIRQ Endp

If UseGUS eq Yes

Voie_GUS DW 0
MODE_GUS DB 0

Programmer_GUS Proc Near
        MOV Voie_GUS,-1
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

        INC Voie_GUS                ;Incr‚menter la voie Gravis.
        MOV AX,Voie_GUS
        CALL U_SetVoice             ;Positionner la voie.

        MOV BX,Voie_Reelle
        TEST Ch_Control[BX],CM_KeyOff     ;KeyOff ?
        JZ GUS_Pas_KeyOff
        AND Ch_Control[BX],Not CM_KeyOff  ;Disable the KeyOff
        OR Ch_Control[BX],CM_Stopped      ;Disable the voie
        CALL KeyOff_GUS
        JMP Boucler_GUS                   ;KeyOff =>Fin
GUS_Pas_KeyOff:


        MOV BX,Voie_Reelle
        TEST Ch_Control[BX],CM_Disabled
        JZ Pas_stop_voie_GUS
        JMP Boucler_GUS             ;Si voie stopp‚e =>Fin
Pas_stop_voie_GUS:

        TEST GUS_Controle[BX],M_ChSample     ;Changer le sample ?
        JZ Pas_Start_Sample_GUS
        AND GUS_Controle[BX],Not M_ChSample  ;Efface le Bit
        OR GUS_Controle[BX],M_ChVolume       ;Modifier le volume !

        CALL U_Start_Sample

Pas_Start_Sample_GUS:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChPeriode    ;Changer la p‚riode ?
        JZ Pas_Set_Period_GUS
        AND GUS_Controle[BX],Not M_ChPeriode ;Efface le Bit

        CALL U_Set_Period

Pas_Set_Period_GUS:

        MOV BX,Voie_Reelle                   
        TEST GUS_Controle[BX],M_ChVolume     ;Changer le volume ?
        JZ Pas_Set_Ch_Volume_GUS
        AND GUS_Controle[BX],Not M_ChVolume  ;Efface le Bit

        CALL U_Changer_Volume_GUS

Pas_Set_Ch_Volume_GUS:

        MOV BX,Voie_Reelle
        TEST GUS_Controle[BX],M_ChPanning     ;Changer le Panning ?
        JZ Pas_Changer_Panning_GUS
        AND GUS_Controle[BX],Not M_ChPanning  ;Efface le Bit

        MOV BL,CH_Panning[BX]       ; BX 0 -> 80h
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
Programmer_GUS Endp

Mute_GUS Proc Near
       MOV CL,0
       XOR CH,CH
Eff_Voies_GUS:                     ; Boucle de 0 to Ch_Number-1
       PUSH CX
       MOV AX,CX
                                   ; AX Numero de voie
       CALL U_SetVoice             ; Choix de la voie...
       XOR BX,BX                   ; BX <= Volume=0
       CALL U_SetVolume            ; *** Regler le volume ***
       POP CX
       INC CX
       CMP CL,Ch_Number
       JNE Eff_Voies_GUS
       RET
Mute_GUS Endp

EndIf

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  D‚sactive voies: Couper les samples                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Stop_Channels Proc Near              ;D‚sactive les voies
       PUSH BX CX

       MOV CL,Ch_Number
       XOR CH,CH
       XOR BX,BX
Boucle_desac_voies:
       OR Ch_Control[BX],CM_Stopped  ;Disable the voie
       INC BX
       DEC CX
       JNZ Boucle_desac_voies

       TEST OtherMUS_Out,M_SN76489
       JZ Stop_NoTDY
       CALL TDY_Mute
Stop_NoTDY:	   
       
	   
If UseGUS eq Yes
       CMP Sortie_sonore,GUS
       JNE Pas_Desact_voies_GUS
       CALL Mute_GUS
EndIf ;UseGUS

Pas_Desact_voies_GUS:
       POP CX BX
       RET
Stop_Channels Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Changer_le_volume: Mise to jours du volume des voies          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Changer_le_volume Proc Near
        PUSH BX BP
		
        XOR BX,BX
		MOV BL,Ch_Number		
		MOV BP,BX
		SHL BP,1

Boucle_ajuste_volume:
        MOV AL,VVolume_re[BX]
        CALL Set_Ch_Volume
		DEC BP
		DEC BP
		DEC BX
		JNZ Boucle_ajuste_volume

        POP BP BX
        RET
Changer_le_volume Endp


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³              D‚finition des blocs du timer                ³
;³                                                           ³
;³   (HP Interne, DAC, Disney Sound Source, Sound Master)    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;Offset_Buffer_Index DW 0
OUT_Procedure DW 0

OUT_SB Proc Near                  ;Sortir la commande vers la Sound Blaster
        MOV AH,AL
		
        MOV DX,SB_BasePort
        ADD DX,0Ch
BL_Boucle1_sort_SB_8:
        IN AL,DX
        OR AL,AL
        JS BL_Boucle1_sort_SB_8
        MOV AL,10h                ;Commande sortie directe
        OUT DX,AL
                                  ;Envoyer l'octet vers la Sound Blaster
        
        MOV DX,SB_BasePort
        ADD DX,0Ch
BL_Boucle_sort_SB_8:
        IN AL,DX
        OR AL,AL
        JS BL_Boucle_sort_SB_8
        MOV AL,AH
        OUT DX,AL
		RET
OUT_SB EndP

;SSOff EQU 0Ch
;SSon  EQU 04h

;OUT_Disney1 Proc Near            ;Disney Sound Source sur LPT1
;        MOV DX,LPT1_Port
;        OUT DX,AL
;        ADD DX,2
;        MOV AL,SSOff
;        OUT DX,AL
;        PUSH AX
;        POP AX
;        MOV AL,SSOn
;        OUT DX,AL
;		RET
;OUT_Disney1 EndP

;OUT_Disney2 Proc Near            ;Disney Sound Source sur LPT2
;        MOV DX,LPT2_Port
;        OUT DX,AL
;        ADD DX,2
;        MOV AL,SSOff
;        OUT DX,AL
;        PUSH AX
;        POP AX
;        MOV AL,SSOn
;        OUT DX,AL
;		RET
;OUT_Disney2 EndP

;OUT_Adlib Proc Near               ;Adlib
;        PUSH AX
;        MOV DX,388h
;        MOV AL,43h                ;Porteuse de la voie 1
;        OUT DX,AL
;        IN  AL,DX
;        IN  AL,DX
;        IN  AL,DX
;        IN  AL,DX
;        IN  AL,DX
;        IN  AL,DX

;        INC DX
;        POP AX
;        MOV BX,OFFSET T_Adlib
;        XLAT                      ;Lire la table Log
;        OUT DX,AL                 ;AL, Niveau total
;		RET
;OUT_Adlib EndP

;OUT_S_Master Proc Near            ;Sound master
;        MOV DX,0388h
;        OUT DX,AL
;		RET
;OUT_S_Master EndP

; ***************  PC Speaker "DAC" IRQ using Timer   *************

IRQ_Timer_PCS:

        PUSH DS
        PUSH SI
        PUSH DX
        PUSH AX
		CLD

; ******  Read the Buffer Data 
        MOV SI,1234h             ; Index
IRQ_PCS_Index:  
		
        MOV AX,1234h             ; DS=Segment de la table de volume et Tampons
IRQ_PCS_Seg_Volume:
        MOV DS,AX
        LODSB
        OUT 42h,AL
		
        MOV W CS:[Offset IRQ_PCS_Index-2],SI

        MOV AL,20h
        OUT 20h,AL

        DEC CS:Compt_50
        JZ IRQ_Timer_PCS_NextBuffer
		
		POP AX
        POP DX
	    POP SI		
        POP DS
        IRET

IRQ_Timer_PCS_NextBuffer:		

        DS_ASM
		
        MOV AX,Buffer_Size        
        MOV Compt_50,AX           ; Chrono for the Display
	
		CMP SI,DMA_Buffers_End_Offs
		JB IRQ_Timer_Out_DoMix    ; End of the Mix Buffers ? 
		MOV AX,Buffer_Start_Offs ; Yes -> ReInit
        MOV W CS:[Offset IRQ_PCS_Index-2],AX
        
		JMP IRQ_Timer_Out_DoMix

; ***************  Generic Direct DAC IRQ using Timer   *************

IRQ_Timer_DAC:                   
        PUSH DS
        PUSH SI
        PUSH DX 
        PUSH AX
		CLD

; ******  Read the Buffer Data 
        MOV SI,1234h             ; Index
IRQ_DAC_Index:
		
        MOV AX,1234h             ; DS=Segment de la table de volume et Tampons
IRQ_DAC_Seg_Volume:
        MOV DS,AX
        LODSB
        MOV DX,1234h
IRQ_DAC_Port_Instr:		
        OUT DX,AL

        MOV W CS:[Offset IRQ_DAC_Index-2],SI

        MOV AL,20h
        OUT 20h,AL

        DEC CS:Compt_50
        JZ IRQ_Timer_NextBuffer
		
        POP AX
        POP DX
	    POP SI		
        POP DS
        IRET

IRQ_Timer_NextBuffer:		

        DS_ASM
		
        MOV AX,Buffer_Size               ;Incr‚mente le Chrono
        MOV Compt_50,AX                  ;    (50ø ou 32ø de seconde)
        ADD Buffer_Current_Out_Offs,AX   ; Currently playing Buffer @

		CMP SI,DMA_Buffers_End_Offs
		JB IRQ_Timer_Out_DoMix           ; End of the Mix Buffers ? 
		MOV AX,Buffer_Start_Offs         ; Yes -> ReInit
        MOV W CS:[Offset IRQ_DAC_Index-2],AX
		MOV Buffer_Current_Out_Offs,AX   ; Currently playing Buffer @ (Reset to the begining)

IRQ_Timer_Out_DoMix:
		STI
        
		DEC Buffer_Ahead_Cnt     ; One more buffer Played
		
        CMP Mix_Buffers_Completed,1         ; Calcul non termin‚ => ne pas calculer
        JNE IRQ_Timer_Slow
		
        PUSH ES		
		PUSH DI
		PUSH BX
		PUSH CX
		PUSH BP
        CALL Gestion_Sonore        ; Appel de la partition
        POP BP
		POP CX
		POP BX
		POP DI
        POP ES

        JMP IRQ_Timer_Slow2

IRQ_Timer_Slow:

        MOV AL,Buffer_Ahead_Cnt
        MOV BL,Buffers_Ahead_Min3 ; Buffers_Ahead_Min +3		
		CMP AL,BL		
        JAE	IRQ_Timer_Slow2
		INC Slow_Mix1_Cnt
        DEC BL
		CMP AL,BL
		JE IRQ_Timer_Slow2
		INC Slow_Mix2_Cnt
        DEC BL
		CMP AL,BL
		JE IRQ_Timer_Slow2
		INC Slow_Mix3_Cnt

IRQ_Timer_Slow2:
        INC IRQ_Cnt
		
        CMP Stop_Output,1
        JNE Fin_IRQ_Timer
		
        CALL Stop_Timer             ; Fin de la sortie Timer

Fin_IRQ_Timer:
        POP AX
        POP DX
	    POP SI		
        POP DS
        IRET

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Lecture de la partition + Calcul du Tampon                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
	
Gestion_Sonore Proc Near
       MOV Mix_Buffers_Completed,0     ; Calculation not completed (Fini)
	   CLD

Restart_Part_Mix:

C_R
	   
If UseOPL2 eq Yes
       CMP Ch_Number_Adlib,0
       JE  Pas_MAJ_OPL2
       CMP OPL_Type,0
       JE Pas_MAJ_OPL2
       CALL OPL2_Update
Pas_MAJ_OPL2:
EndIf

If UseGUS eq Yes
       CMP Ch_Number_Digit,0
       JE Pas_MAJ_GUS
       CMP Sortie_Sonore,GUS
       JNE Pas_MAJ_GUS
       CALL Programmer_GUS
Pas_MAJ_GUS:
EndIf  ; UseGUS

C_G

       CMP Musique_Terminee,1
       JE  Seulement_Sortie_Sonore
       CALL Partition        ; Start the Partition
Seulement_Sortie_Sonore:

; Start the Buffer Mixing

       CMP Ch_Number_Digit,0 ; No Digital sound, no buffer to Mix
       JE Buffers_Mix_Completed
If UseGUS eq Yes
       CMP Sortie_sonore,GUS ; Si GUS, ne pas calculer le tampon...
       JE Buffers_Mix_Completed
EndIf ;UseGUS	   

;C_W

      CALL Build_Mix_List     ; Build the list of channels to Mix

      MOV CL,Mix_Channels_Nb
      CMP Mix_Channels_Nb_MAX,CL
	  JAE MChann_NotMAx
      MOV Mix_Channels_Nb_MAX,CL  ; For the Debug Display
MChann_NotMax:	  

; Start the sound Mixing (If Not GUS) 

       CALL Calcul_tampon

       CALL Move_Buffer_Offset  ; Select the Next buffer

       INC Buffer_Ahead_Cnt     ; One more buffer Computed
	   
;  Display the Debugs Var

If Mod_Master eq yes
      DS_TP
	  CMP Center_Display,3
      JNE Pas_Aff_Debug_Part
	  DS_ASM
      CALL AffDebug_Tick
Pas_Aff_Debug_Part:
      DS_ASM
EndIf

;C_B
       CMP Preprocessing,1
	   JE Buffers_Mix_Completed        ; Preprocessing is One by One

       CMP Sortie_sonore,T_DAC         ; Tandy DAC End is different (Based on Offset Delta)
	   JE GS_End_Tandy

; Check if we need to build another buffer	   
       MOV AL,Buffer_Ahead_Cnt
	   CMP AL,Buffers_Ahead_Target     ; Buffers_Ahead_Target  : Nb of buffers to have (Can be < Nb Total )
	   JB Buffers_Mix_NotCompleted

Buffers_Mix_Completed:                 ; *** End of the Buffer Mixing ***

       MOV Volume_Skip,0               ; Reset Volume Skip	
       MOV Mix_Buffers_Completed,1     ; Tampon calcul‚.
       RET ; *** The End ***

Buffers_Mix_NotCompleted: 
; More Bufers Needed, Check if we need to increase the Min volume

; Modify the Minimum volume to use based on the Nb of buffer calculated.
       MOV BL,Buffers_Ahead_Min3 ; Buffers_Ahead_Min +3
	   
	   MOV AH,Volume_Skip
;  -> Reduce VolSkip
       CMP AL,BL
	   JA VolSkipUpdateEnd   ; >4, Go to mix the next buffer
	   JNE VolSkip_Test2
	   TEST AH,AH
	   JZ VolSkipUpdateEnd
       SUB Volume_Skip,VolSkipIncr
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End
	   
VolSkip_Test2:
;  -> Increase VolSkip to Vol_Limit2
       DEC BL
	   CMP AL,BL
	   JNE VolSkip_Test3
	   CMP AH,Vol_Limit2
	   JAE VolSkipUpdateEnd
	   ADD Volume_Skip,VolSkipIncr
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End
	   
VolSkip_Test3:
;  -> Increase VolSkip to Vol_Limit3
       DEC BL
	   CMP AL,BL
	   JNE Do4BuffersLate
	   CMP AH,Vol_Limit3
	   JAE VolSkipUpdateEnd
	   ADD Volume_Skip,VolSkipIncr

VolSkipUpdateEnd:
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End

Do4BuffersLate:
; 4 Buffers Late -> The Mixing code is Too Slow (Output Frequency too High)

       MOV Erreur_Modm,Err_Too_Slow    ; Error code to define
	   MOV Stop_Output,1               ; Stop the music

	   JMP Buffers_Mix_Completed

; Check if we need to build another buffer for the Tandy DAC Output
; 7 Steps, much more complex due to the different possibilities.
GS_End_Tandy:

       CALL Update_BuffersDelta        ; Get the Current Delta Value

       MOV BX,CurrentMix_Delta
       CMP BX,MixDelta_Target          
; 1) Current Delta >= Target, Mixing Complete
       JAE Buffers_Mix_Completed       

	   CMP BX,MixDelta_4
	   JB Test_TD_3
; 2) Current Delta >= MixDelta_4 Vol=0
       MOV Volume_Skip,0               
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End

Test_TD_3:
       INC Slow_Mix1_Cnt
	   MOV AH,Volume_Skip
	   CMP BX,MixDelta_3
	   JB  Test_TD_2
; 3) Current Delta >= MixDelta_3 Decrease Volume
	   TEST AH,AH                      
	   JZ VolSkipUpdateEnd
       SUB Volume_Skip,VolSkipIncr
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End
	   
Test_TD_2:
       INC Slow_Mix2_Cnt
	   CMP BX,MixDelta_2
	   JB Test_TD_1
; 4) -> Increase VolSkip to Vol_Limit2
	   CMP AH,Vol_Limit2
	   JAE VolSkipUpdateEnd
	   ADD Volume_Skip,VolSkipIncr
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End

Test_TD_1:
       INC Slow_Mix3_Cnt
	   CMP BX,MixDelta_Min
	   JB TD_Use_Vol3
;  5) -> Increase VolSkip to Vol_Limit3	   
	   CMP AH,Vol_Limit3
	   JAE VolSkipUpdateEnd
	   ADD Volume_Skip,VolSkipIncr
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End
	   
TD_Use_Vol3:
	   CMP BX,MixDelta_Slow  ; bugged for the moment
	   JBE Do4BuffersLate    ; 7) Below the Slow Limit > Stop music

;  6) -> VolSkip = Vol_Limit3
       INC Slow_Mix1_Cnt
       INC Slow_Mix2_Cnt
       INC Slow_Mix3_Cnt
	   MOV AH,Vol_Limit3
       MOV Volume_Skip,AH
	   JMP Restart_Part_Mix  ; Do the Partition and Mixing again, as the IRQ Came before mixing End

	   
; The end of the procedure is above
Gestion_Sonore Endp

If Mod_Master eq yes
AffDebug_Tick Proc Near

      MOV AX,Seg_Video
      MOV ES,AX

	  MOV DI,2*(28-1)+160*(2+Ypart-1)
      MOV BL,C_Red                 
      MOV AL,Volume_Skip
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche 

;	  MOV DI,2*(24-1)+160*(3+Ypart-1)	
;      MOV BL,C_Red              ; Red
;      MOV AL,Mix_Late_Cnt
;      MOV BH,1                  ;affiche dizaines nulles
;      CALL BIA8                 ;affiche 


	  MOV DI,2*(31-1)+160*(3+Ypart-1)	
      MOV BL,C_Green              ; Red
      MOV AL,Buffer_Ahead_Cnt
      MOV BH,1                  ;affiche dizaines nulles
      CALL BIA8                 ;affiche 

      MOV DI,2*(57-1)+160*(3+Ypart-1)
      MOV AX,Slow_Mix2_Cnt
      MOV BH,6                 ;Brown
      CALL WriteXY_Dec16	
	  
	  MOV DI,2*(68-1)+160*(3+Ypart-1)
      MOV AX,Slow_Mix3_Cnt
      MOV BH,C_Red             ;Red
      CALL WriteXY_Dec16	

; Mix Delta (TDAX Only)
      MOV DI,2*(42-1)+160*(4+Ypart-1)  ; Output Current Offset
      MOV AX,CurrentMix_Delta  
      MOV BH,C_White
      CALL Affichedbxy 
	  
;	   MOV DI,2*(55-1)+160*(3+Ypart-1)
;      MOV AX,Offset_Buffer_Index
;      MOV BH,15                 ;Jaune/Noir
;      CALL WriteXY_Dec16

;	   MOV DI,2*(60-1)+160*(3+Ypart-1)
;      MOV AX,Buffer_Start_Offs
;      MOV BH,15                 ;Jaune/Noir
;      CALL WriteXY_Dec16
	  
      RET
AffDebug_Tick Endp
EndIf

; Build the Mix Channel List
; - Channels With Not Loaded samples are already inactive
; - Remove Adlib Channels                 ; OPT Add Adlib as a Ch_Control Channel
; - Remove the Disables Channels (Completely disables channel)
; - Remove the Stopped (No more playing) Channels

; Then, Limit the number of channels based on priority (Sample Type and length) and Volume

VLim1 Equ 10h
VLim2 Equ 20h

Build_Mix_List Proc Near

        MOV AX,DS
        MOV ES,AX
        MOV DI, Offset Mix_Channel_List

        XOR CL,CL
        XOR BX,BX
		MOV AH,1
Build_MixChLoop:

        CMP M_CH_Type[BX],AH         ;Voie Digitale et active ?
        JNE Build_MixChLoop_Next     ;Non => Fin
		
        MOV AL,Ch_Control[BX]        ;Channel Control Byte

		MOV Ch_Control[BX],AL        ; Stop Channel Pause (display Only)
		
        TEST AL,CM_KeyOff            ;If KeyOff Disable the Channel and Disable KeyOff
        JZ BMixLoop_Not_KeyOff
        AND AL,Not CM_KeyOff         ;Disable the KeyOff
        OR AL,CM_Stopped             ;Disable the Channel
		MOV Ch_Control[BX],AL
        JMP Build_MixChLoop_Next
BMixLoop_Not_KeyOff:

        AND AL,CM_Stopped+CM_Disabled ;Voie active et pas stoppee ?
        JNZ Build_MixChLoop_Next      ;Non => Sample pas chargé		

        CMP VVolume[BX],0             ;Skip if Volume =0
		JE Build_MixChLoop_Next

        MOV AL,BL
		STOSB                         ;Store the Channel number in the list
		INC CL
		
Build_MixChLoop_Next:
        INC BL
		CMP BL,Ch_Number            ;Mix all the channels one by one
		JNE Build_MixChLoop

        MOV Mix_Channels_Nb,CL
; Check if we need to reduce the Nb of channels to mix

        MOV AL,Mix_ChLimit_Nb
		OR AL,AL
		JE BML_AutoLimit            ; Zero : Autodetect the limit Nb of Channel
		CMP AL,0FFh
		JNE BML_ManualLimit         ; Not -1 -> Manuel Limitation
		RET

BML_AutoLimit:
;Writech 'a'	
        CMP Slow_Mix3_Cnt,30
        JA BML_AutoStarted
        RET	
BML_AutoStarted:
        MOV AL,Max_Mixed3
		INC	AL
        CMP Slow_Mix3_Cnt,100
		JB BML_ManualLimit
        DEC AL       ; Slow_Mix3_Cnt> Fix the Limit as if it was manual.
		DEC AL
		MOV Mix_ChLimit_Nb,AL
		 
BML_ManualLimit:
        CMP AL,2
		JAE Mix_Channels_LimitOk
		MOV AL,2                  ; Security: Limit >=2
Mix_Channels_LimitOk:		
        MOV Mix_Channels_Limit,AL ; Save the Used Nb of Channels Limit

; AL <- Max Nb of Channels
; CL <- Nb of Channels to mix
;Writech '-'
		CMP CL,AL
		JA Remove_LP_Chan
		RET              ; Channels to Mix <= Limit -> Do not remove channels
Remove_LP_Chan:
        SUB CL,AL
		MOV DH,CL
                         ; DH: number of channels to remove		
;PUSH DX
;        MOV AL,DH
;		Call WriteByteH  ; Write the Nb of channels to remove (1-9)
;POP DX	
	
		CLD              ; As we use LODSB
		XOR BX,BX		 ;OPT Remove
		MOV SI,Offset Mix_Channel_List
		XOR CX,CX       
		MOV CL,Mix_Channels_Nb

        MOV AH,3                 ; Value for comparison
BML_Initial_Loop:
		LODSB                    ; Load the channel number from the "To Mix" List
		MOV BL,AL
		
;**********************************************************************
;1) Compute the Priority Value and Disable Priority 3 and Volume <VLim1

		MOV AL,Ch_LoopType[BX]
		MOV DL,Ch_Smp_Tick_Cnt[BX]    ; DL Tick count AL, LoopType, AH, Prio
		CMP DL,AH         ; Samples played time <= 3 ?
		JBE BMSetPrioEnd  ; Prio+0
		INC AL            ; Prio+1
		CMP DL,10         ; Samples played since few time has a medium priority
		JBE BMSetPrioEnd
		INC AL            ; Prio+2
BMSetPrioEnd:
        MOV Ch_Priority[BX],AL  ; Priority: Loope Type + Sample Play duration

		CMP VVolume[BX],VLim1
        JA  BML_NotDisable_VLP3        ; Volume <VLim1 ?
        CMP AL,AH                      ; Priority <3 ?
		JE BML_Stop_VLP3
;Pause the Channel: Priority <3 and Volume <VLim1
        OR Ch_Control[BX],CM_FPause
		JMP BML_PauseCont_VLP3
BML_Stop_VLP3: 
;Stop the Channel: Priority 3 and Volume <VLim1
		OR Ch_Control[BX],CM_Stopped+CM_FStop
BML_PauseCont_VLP3: 		
		DEC SI
		MOV Byte Ptr [SI],0FFh         ; Replace the Channel number by -1
		INC SI
;Writech 'x'
		DEC DH
		JNZ BML_NotDisable_VLP3
		JMP BML_ReduceList             ; No more channels to stop -> End
BML_NotDisable_VLP3:

		LOOP BML_Initial_Loop
		
;***************************************************************************
;2) Disable ( Priority > x With Volume < ) and ( Priority > x With Volume < )

		MOV SI,Offset Mix_Channel_List
		XOR CX,CX
		MOV CL,Mix_Channels_Nb
		
BML_Do_Loop2:
		LODSB                    ; Load the channel number from the "To Mix" List
		
		CMP AL,0FFh
		JNE BML_Loop2_Not_Disabled
		LOOP BML_Do_Loop2
		JMP BML_Do_Loop2_End
BML_Loop2_Not_Disabled:		
		MOV BL,AL
        MOV AL,Ch_Priority[BX]
        MOV AH,VVolume[BX]
		
		CMP AH,VLim2
		JA BML_Not_Cut2
        CMP AL,2
		JB BML_Not_Cut2
		
        ;Stop the Channel
		OR Ch_Control[BX],CM_Stopped+CM_FStop
		DEC SI
		MOV Byte Ptr [SI],0FFh         ; Replace the Channel number by -1
		INC SI
;Writech 'y'		
		DEC DH
		JNZ BML_Not_Cut2
		JMP BML_ReduceList             ; No more channels to stop -> End
		
BML_Not_Cut2:		
		LOOP BML_Do_Loop2
BML_Do_Loop2_End:
		
;****************************************************************************
;3) Disable ( Priority > x With Volume < ) and ( Priority > x With Volume < )

		MOV SI,Offset Mix_Channel_List
		XOR CX,CX
		MOV CL,Mix_Channels_Nb

BML_Do_Loop3:
		LODSB                          ; Load the channel number from the "To Mix" List

		CMP AL,0FFh
		JNE BML_Loop3_Not_Disabled
		LOOP BML_Do_Loop3
		JMP BML_Do_Loop3_End
BML_Loop3_Not_Disabled:	
	
		MOV BL,AL
        MOV AL,Ch_Priority[BX]

        CMP AL,1
		JB BML_Not_Cut3
		JA BML_Cut3
		; Priority 1
        MOV AH,VVolume[BX]
		CMP AH,VLim2
		JA BML_Not_Cut3 ; P1 and Vol Max No Cut
BML_Cut3:
			
        ;Stop the Channel
		OR Ch_Control[BX],CM_Stopped+CM_FStop
		DEC SI
		MOV Byte Ptr [SI],0FFh         ; Replace the Channel number by -1
		INC SI
;Writech 'z'		
		DEC DH
		JNZ BML_Not_Cut3
		JMP BML_ReduceList            ; No more channels to stop -> End
		
BML_Not_Cut3:
		LOOP BML_Do_Loop3
BML_Do_Loop3_End:

BML_ReduceList:

; Build the Final Reduced List and Pause the channels not removed before.
	
;        PUSH DX
;Writech ','			
;        MOV AL,DH
;		Call WriteByteH  ; Write the Nb of channels to remove (1-9)
;        POP DX			

		MOV SI,Offset Mix_Channel_List
		MOV DI,SI ; ES=DS already
		XOR CX,CX
		MOV CL,Mix_Channels_Nb

;        PUSH CX
;Writech 'c'			
;        MOV AL,CL
;		Call WriteByteH  ; Write the Nb of channels to remove (1-9)
;        POP CX	

BML_FinalListLoop:
        LODSB
        CMP AL,0FFh
		JNE BML_FinalListLoop_Add
        LOOP BML_FinalListLoop     ; 0FFh > Remove from the list
		JMP BML_FinalListLoopEnd
BML_FinalListLoop_Add:
        STOSB		               ; Else, Add to the List
        LOOP BML_FinalListLoop
		
BML_FinalListLoopEnd:
		MOV BL,Mix_Channels_Limit
        MOV Mix_Channels_Nb,BL
		
		OR DH,DH
		JZ BML_End

		MOV SI,Offset Mix_Channel_List
        XOR BH,BH                  
		MOV BL,Mix_Channels_Limit
		ADD SI,BX
		MOV CL,DH                 ; Declare as Paused the last channels 
		
BML_PauseRemChannels:
        LODSB
		MOV BL,AL
		CMP AL,32
		JAE BML_RemNoPause
        OR Ch_Control[BX],CM_FPause
BML_RemNoPause:		
		LOOP BML_PauseRemChannels

BML_End:		
        RET
Build_Mix_List Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                 Lecture de la partition                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;partition_en_cours DB 0   ; 1 si lecture de la partition en cours
Pattern_Vide  DB 0

Chrono_Fading Proc Near
;Gestion Chrono et fading
       DEC Chrono_50
       JNZ Chrono_End
       MOV AL,Vitesse_Ticks    ; 50 or 32
	   MOV Chrono_50,AL

                 
       CMP Duree_intro,0       ;IntroScan active?
       JZ Increment_Time       ;non
       MOV AL,Duree_intro
       DS_TP
       CMP TP_Fading,1         ;Fading already active ?
       DS_ASM
       JE Increment_Time        ;oui
       DEC AL
       DS_TP
       MOV AH,TP_Chrono_sec
       DS_ASM
       CMP AL,AH               ;TP_Chrono_sec=Duree_intro-1?
       JE lance_fading         ;oui
       INC AL
       CMP AL,AH               ;TP_Chrono_sec=Duree_intro?
       JNE Increment_Time      ;non
       DS_TP
       MOV Stop_Output,1       ;Stop the Music/Audio
       DS_ASM	   
	   RET
lance_fading:
       DS_TP
       MOV TP_Fading,1
       DS_ASM
       MOV AL,Volume_total
       MOV Sauvegarde_du_volume,AL  ; Sauvegarde du volume avant le Fading
Increment_Time:
       DS_TP
	   INC TP_Chrono_sec
       CMP TP_Chrono_sec,60
       JNE Chrono_End2
       MOV TP_Chrono_sec,0
       INC TP_Chrono_min

Chrono_End2:
       DS_ASM
Chrono_End:
       RET
Chrono_Fading Endp

Partition Proc near

;      MOV Partition_en_cours,1
;      MOV New_Note_Started,0
	   
        CALL Chrono_Fading

       ADD BPM_Cnt,520     ; 65000/125 (Base BPM)
BPMLoop:
       MOV AX,BPM_Val
       CMP BPM_Cnt,AX
       JB  NoProcess
       SUB BPM_Cnt,AX

	   DEC Cmpt_Tempo
	   JNZ Do_Commands

	   MOV AL,Tempo
	   MOV Cmpt_Tempo,AL    ; Reinit Tempo Counter
;	   MOV TickCnt,0

       CALL Partition_personnelle
	
	   JMP Not_Do_Command

Do_Commands:

C_BL

;JMP Not_Do_Command

       XOR BX,BX
       XOR BP,BP
Do_Command_Loop:
     
       CALL CH_Command[BP]

If XMCMD Eq Yes	   
       CALL VC_Exec[BP]	   
EndIf
	   
       INC BP
	   INC BP                        ; BP=2*BX (Index Mots)
	   INC BX                        ; Incr‚mente le compteur de voies       
       CMP BL,Ch_Number
       JNE Do_Command_Loop

Not_Do_Command:	   
;WriteChar '3'
        jmp BPMLoop

NoProcess:		

;WriteChar '4'
       CMP Musique_Terminee,1
       JE Fin_player

       DS_TP
       CMP TP_Fading,1          ; Gestion du Fading
       DS_ASM                   ; OPT Deplacer DS_ASM
       JNE Pas_fin_mus
       CMP Volume_total,2
       JBE Fin_player
       DEC Volume_total
       CMP Touche_fin,Tfin_Esc  ; a-t-on appuy‚ sur Esc?
       JNE Fading_IntroScan     ; non, alors c'est le Fading de l'IntroScan
       DEC Volume_total         ; Fading avec Esc deux fois plus rapide
Fading_IntroScan:
       CALL Changer_le_volume   ; Modifier le volume pour le fading
Pas_fin_mus:
       DS_TP
       MOV Test_Periodique,1    ; Pour l'affichage (D‚tecte le 50ø ou 32ø )
       DS_ASM
       RET

Fin_Player:

       MOV Stop_Output,1    ;Stopper la sortie sonore
;Fin_Fin_Player:
       RET
Partition Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Partition_personnelle: Gestion de la partition       ³
;³      ( Tempo, BMP, S‚quence ... )                         ³
;³      Entr‚e: Rien                                         ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;Taille_note EQU 6

DoPatternBreak      DB 0  ; 1 -> Go to the next Pattern
PattBreakRow        DB 0  ; Pattern Break Row number

PJumpPattern    DB 0          ; 1 => Sauter au pattern JumpParam
JumpParam       DB 0          ; Pattern pour Jump Pattern

C_Channel       DB 0          ; Current Channel number
C_Patt_Length   DB 0          ; Nb of Row for the current Pattern
C_PartIndex     DW 0          ; Current Row index in the partition (First Channel)
C_ChannelIndex  DW 0          ; Current index in the partition (Current Channel)
Loop_RowIndex   DW 0          ; Jump Loop Row Index (First Channel) -> To set when the Loop Occurs

;Note_Mask DB 0               ; Note Mask var, to check what is available in the current Note
;M_Sample  EQU 01h
;M_Note    EQU 02h
;M_Volume  EQU 04h
;M_Command EQU 08h
;M_Param   EQU 10h

Partition_personnelle Proc Near
        MOV Test_Jump_Loop,0             ; To avoid 2 Jmp Loop on the same Row

; ******** Process Commands based on Row / Sequence ************

        CMP Cmd_ModifyPattern,1          ; **** Changer de pattern ****
        JNE Pas_Cmd_ModifyPattern        ; (Touche droite ou gauche...)
        MOV Cmd_ModifyPattern,0
        MOV AL,C_Sequence

        CALL Stop_Channels
        MOV AL,C_Sequence
        DEC AL
        JMP Modifier_N_Pattern
Pas_Cmd_ModifyPattern:

        CMP PJumpPattern,1              ; ** Command Jump Pattern ? Not processed if 
        JNE Pas_JPattern
        MOV AL,JumpParam
        JMP Modifier_N_Pattern
Pas_JPattern:

        CMP DoPatternBreak,1            ; ** Command Pattern Break ?
        JE  pattern_suivant             ; Oui => Pattern suivant
        MOV PattBreakRow,0
        INC C_Row                       ; Incr‚menter la position de la note

        CMP DoJumpLoop,1                ; ** Commande Jump Loop ?
        JNE Pas_Exec_Jump_Loop
        MOV DoJumpLoop,0
        MOV AL,Debut_Boucle_Pattern
        MOV C_Row,AL                    ; Initialiser au d‚but de la boucle

        CALL Do_Change_Row
		
Pas_Exec_Jump_Loop:

        MOV AL,C_Patt_Length
        CMP C_Row,AL                    ; Fin de Pattern? (Compare avec Taille_Pattern)
        JNE Patt_Proc_Channels		

pattern_suivant:                        ; Oui -> Pattern suivant
        MOV AL,C_Sequence
;        MOV AH,Sequence_Len
        CMP AL,Sequence_Len             ; Sequence End ?
        JNE Modifier_N_Pattern          ; Non -> Nouveau pattern
                                        ; Oui => Gestion du bouclage
        DS_TP                           ; Boucler le module ?????
        CMP Boucler_MOD,1
        JE Boucler_Module
        CMP Boucler_MOD,2
        JE Boucler_Module_n
Pas_boucler:
        DS_ASM
        MOV Musique_Terminee,1          ; Pas de bouclage -> Fin
        RET
Boucler_Module_n:
        DS_ASM
        DEC nb_de_boucles
        JZ Pas_boucler
Boucler_Module:
        DS_ASM
        MOV AL,Pos_de_restart
        MOV C_Sequence,AL             ; Boucler le module...

        CALL Stop_Channels

        MOV PattBreakRow,0
        MOV AL,C_Sequence
        DEC AL
Modifier_N_Pattern:

        CALL Do_NextPattern
		CMP Pattern_Vide,1      ;Modified for .S3M Pattern 254 (Go to Next Pattern)
		JE Pattern_suivant

        CALL Do_Change_Row

Patt_Proc_Channels:

        MOV ES,C_Pattern_Seg   ;C_Pattern_Seg Segment du pattern actuel
        MOV SI,C_PartIndex
        MOV EmptyChannelCount,0

                             ;*********************************
        PUSH BP              ;** Boucle de lecture des voies **
        XOR BX,BX            ;*********************************
        XOR BP,BP
Boucle_part_voies:
        INC Ch_Smp_Tick_Cnt[BX]              ; Increment the Tick Counter for the channel (To compute priority)
		AND CH_Control[BX],Not CM_FPause     ; Remove the Forced Pause Flag

        CALL Do_ReadChannelPart

        CMP BL,Ch_Number
		JAE Skip_ProcChannel ; If Nb of Channel in the pattern is > Nb of Channels (S3M)

        TEST DL,DL
	    JZ  Part_NotEmpty
        
		MOV CH_Command[BP],Offset Do_Nothing  ; Stop the Commands
		MOV VC_Exec[BP],Offset Do_Nothing
		
        ; Partition Empty, Test if the previous command was a Vibrato or Arpeggio
        TEST Retrig_V_Tr[BX],M_Vib_VibVS_Cmd+M_Arpegio
		JZ   PartNull_NoRetrig
		AND Retrig_V_Tr[BX],Not (M_Vib_VibVS_Cmd+M_Arpegio)
		
		MOV CX,CH_Per_part[BP]
        CALL Set_Period      ;Fixer la p‚riode de la voie	

; To add Tremolo Retrig
		
PartNull_NoRetrig:
        JMP Skip_ProcChannel
Part_NotEmpty:
        PUSH ES SI
        CALL Proc_Channel      ;Process the channel partition
        POP SI ES
Skip_ProcChannel:
        INC BX               ;Increment Channel counters
        ADD BP,2             ;BP=2*BX (Index Mots)
        CMP BL,Ch_Number_patt
		JNE Boucle_Part_voies
        POP BP
        
		
		CMP EmptyChannelCount,0  ; If Empty Channel count<>0, the Index is not correct
		JE ReadPart_NotIncIndex
		INC SI
ReadPart_NotIncIndex:		
		MOV C_PartIndex,SI  ;Save the Current (Next) Index
		
        RET
Partition_personnelle Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Do_ReadChannelPart: Read the channel partition           ³
;³                                                           ³
;³  Input  : ES:SI Pointer to the Current channel Data       ³
;³           BX:   Channel number                            ³
;³  Output : C_Note, C_instrument ...                        ³
;³                                                           ³
;³           BL : 1 No Partition Info                        ³
;³  Change :                                                 ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; Offset in the Not Compressed partition
Po_Note        EQU B ES:[SI]  
Po_Instrument  EQU B ES:[SI+1]
Po_Command     EQU B ES:[SI+2]
Po_Param       EQU B ES:[SI+3]
Po_Volume      EQU B ES:[SI+4]

EmptyChannelCount DB 0

Do_ReadChannelPart Proc Near

       XOR AX,AX
	   MOV W C_Note,AX     ; Clean Note + Instrument
       MOV W C_Command,AX  ; Clean Command + Param
       MOV C_Volume,0FFh
       MOV DL,1

       CMP CP_Pattern,AL   ; Compressed pattern ?
       JNE DP_Do_Compressed_Pattern
	   
       MOV AX,W ES:[SI]   ; Read Note + Instrument
	   TEST AX,AX
	   JZ NoteInstrZ
	   MOV W C_Note,AX    ; Store Note + Instrument
       XOR DL,DL
	   
NoteInstrZ:
       MOV AX,W ES:[SI+2] ; Read Command + Param
	   TEST AX,AX
	   JZ CmdParamZ
	   MOV W C_Command,AX
       XOR DL,DL
	   
CmdParamZ:
       CMP Note_Size,4
	   JE VolZ
       MOV AL,Po_Volume   ; Read Volume
	   CMP AL,040h
	   JA VolZ
	   MOV C_Volume,AL
       XOR DL,DL
VolZ:
	   XOR AX,AX
	   MOV AL,Note_Size
       ADD SI,AX
	   RET
	   
DP_Do_Compressed_Pattern:        ; **** Read Compressed Pattern Data ****

       TEST BX,BX
	   JNZ DP_NotFirstChannel
	   MOV AL,ES:[SI]            ; ** Read the Index Delta to the next channel
	   INC SI
	   TEST AL,AL
	   JNZ DP_NotFirstChannel    ; If not 0, the value is ignored
	   MOV AL,Ch_Number_patt   ; ** The full Row is empty
	   DEC AL
	   MOV EmptyChannelCount,AL  ; Index Delta = 0 -> All the Channels are empty
	   RET
	   
DP_NotFirstChannel:	   
       CMP EmptyChannelCount,0   ; ** Check if next Channel is empty
	   JE  CP_NoEmptyChannel     ; Empty channels counter is not 0 -> Skip
	   DEC EmptyChannelCount     ; Next Channel is empty
	   RET
	   
CP_NoEmptyChannel:	   
	   MOV AL,ES:[SI]            ; ** Read the Compression Mask or Note (Like FT2 Format)
	   TEST AL,80h               ; Check if the values are compressed
	   JZ DP_AllDataPresent
       MOV DH,AL                 ; Move the Compression Mask to DL
	   SHL DH,1
	   SHL DH,1
	   JNC DP_ChannelNotEmpty
	   ; Channel Empty -> read the Nb of Empty Channels
	   AND AL,00111111b
	   MOV EmptyChannelCount,AL
	   INC SI
	   RET
	   
DP_ChannelNotEmpty:             ; ** Read Compressed Values
       INC SI
       XOR DL,DL                ; Not Empty
; Test Note
       SHL DH,1
	   JNC DP_TestInstr
	   MOV AL,ES:[SI]
	   MOV C_Note,AL
	   INC SI
DP_TestInstr:
; Test Instrument
       SHL DH,1
	   JNC DP_TestCmd
	   MOV AL,ES:[SI]
	   MOV C_Instr,AL
	   INC SI
DP_TestCmd:
; Test Command
       SHL DH,1
	   JNC DP_TestParam
	   MOV AL,ES:[SI]
	   MOV C_Command,AL
	   INC SI
DP_TestParam:
; Test Parameter
       SHL DH,1
	   JNC DP_TestVol
	   MOV AL,ES:[SI]
	   MOV C_Param,AL
	   INC SI
DP_TestVol:
; Test Volume
       SHL DH,1
	   JNC DP_TestEnd
	   MOV AL,ES:[SI]
	   MOV C_Volume,AL
	   INC SI
DP_TestEnd:
       RET
	   
DP_AllDataPresent:             ; ** Read Uncompressed values
       MOV AX,W ES:[SI]        ; Read Note + Instrument
	   MOV W C_Note,AX
       MOV AX,W ES:[SI+2]      ; Read Command + Param
	   MOV W C_Command,AX
       MOV AL,Po_Volume        ; Read Volume
	   MOV C_Volume,AL
       XOR DL,DL               ; Not Empty
	   ADD SI,5
       RET
Do_ReadChannelPart Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Do_Change_Row: Search for the row Index in the Pattern   ³
;³                                                           ³
;³  Input  : C_Row Row Number                                ³
;³  Output : SI, C_PartIndex <- Row Index                     ³
;³  Change : AX,BX                                           ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Do_Change_Row  Proc Near
        MOV AL,C_Row
		TEST AL,AL
		JNZ RowNotNull
        XOR SI,SI
        MOV C_PartIndex,SI
        RET
RowNotNull:		
; Test if Compressed
        CMP CP_Pattern,0
        JNE Do_Compressed_Change_Row

; ** Not Compressed **	
        XOR AH,AH
        XOR BH,BH
        MOV BL,Note_Size
        MUL BL
        MOV BL,Ch_Number_patt
        MUL BX
        MOV SI,AX            ;=Note_Size*C_Row*Ch_Number_patt
        MOV C_PartIndex,SI      
        RET

Do_Compressed_Change_Row:
; ** Compressed **
        PUSH DS
		XOR AX,AX
		XOR CX,CX
		MOV CL,C_Row
        MOV DS,C_Pattern_Seg   ;C_Pattern_Seg Segment du pattern actuel
		XOR SI,SI
Do_Search_RowOffset:
		LODSB                  ; Read the Delta to the next Row-1
		ADD SI,AX
		Loop Do_Search_RowOffset
		POP DS
        MOV C_PartIndex,SI
		RET

Do_Change_Row  Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Do_NextPattern: Placer la musique au pattern AL     ³
;³                       de la sequence                      ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Do_NextPattern Proc Near
        MOV C_Sequence,AL
        INC C_Sequence
        XOR AH,AH                       ; AX, Position dans la s‚quence
        MOV BX,AX

        MOV AL,Table_Tempo[BX]          ; Read the Pattern Tempo
        OR AL,AL                        ; Tempo pour le Pattern>0 ?? (669)
        JZ Pas_Modif_Tempo_Pattern
        MOV Tempo,AL                    ; Oui, Modifier le Tempo
        MOV Cmpt_Tempo,AL
Pas_Modif_Tempo_Pattern:
        MOV AL,Table_Sequence[BX]       ; AL <- Nø de pattern
        CMP AL,128
		JBE PatternNumberOk
		MOV Pattern_Vide,1              ; Pattern >128, Skip it
		RET
PatternNumberOk:		
        MOV C_pattern,AL

        XOR BX,BX
        MOV BL,AL
        MOV AL,Table_taille_patt[BX]
        MOV C_Patt_Length,AL    ; Chercher le nombre de notes par pattern

        MOV BL,C_pattern
		SHL BX,1
		MOV AX,Seg_Pattern[BX]
        CMP AX,0
        MOV Pattern_Vide,0
        JNE Pattern_Non_Vide
        MOV Pattern_Vide,1
Pattern_Non_Vide:
        MOV C_Pattern_Seg,AX       ; Init le segment du pattern
        MOV AL,PattBreakRow        ; C_Row to PattBreakRow !
        MOV C_Row,AL

        MOV PattBreakRow,0
        MOV PJumpPattern,0
        MOV DoPatternBreak,0
        MOV Debut_Boucle_Pattern,0
        RET
Do_NextPattern Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Proc_Channel:  Traiter une note                         ³
;³                                                           ³
;³      entr‚e: BX Num‚ro de la voie                         ³
;³              BP=BX*2   (Index pour les mots)              ³
;³              Periode_Partition, Instrument_Partition...   ³
;³                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;Current Partition Data  !! Don't change the Order, must match the partition order !!
Align 4
C_Note    DB 0
C_Instr   DB 0
C_Command DB 0
C_Param   DB 0
C_Volume  DB 0

; Values to use
Note_Sample      DB 0
Note_Periode     DW 0      ; Period to set at the end of the partition Read
Note_Note        DB 0

Periode_Partition DW 0    ; Period defined in the Partition (Not set to it if Tone Portamento)

Command_ProcOffs  DW 0    ; Command Procedure Offset (To execute between the Row Ticks)
Start_Sample    DB 0
Start_Volume    DB 0
Start_Periode   DB 0
Save_Periode    DB 0

; L‚gende: O, Oui
;          N, Non
;          I, Impossible
;          x, Pas de commande

None         EQU 0   ;x   ;Pas de commande.
CArpeggio    EQU 1   ;O   ;Arpeggio.
PortUp       EQU 2   ;O   ;Portamento Up.
PortDown     EQU 3   ;O   ;Portamento down.
TonePort     EQU 4   ;O   ;Tone portamento.
CVibrato     EQU 5   ;O   ;Vibrato.
T_VSlide     EQU 6   ;O   ;Tone portamento+Volume slide.
Vib_VSlide   EQU 7   ;O   ;Vibrato+Volume slide.
CTremolo     EQU 8   ;O   ;Tr‚molo. (Vibrato pour le volume)
CPanning     EQU 9   ;O   ;Panning. (Normalement, Commande 8 non utilis‚e)
SampleOffs   EQU 10  ;O   ;Fixer l'offset de l'‚chantillon.
VolSlide     EQU 11  ;O   ;Volume slide.
JumpPattern  EQU 12  ;O   ;Sauter vers la position xx.
CSetVolume   EQU 13  ;O   ;D‚finir le volume.
EndPattern   EQU 14  ;O   ;Fin du pattern.
Extended     EQU 15  ;x   ;Commandes ‚tendues. (17...)
SetTempo     EQU 16  ;O   ;D‚finir le tempo.

CSetFilter   EQU 17  ;I   ;Activer le filtre. (Amiga)
CFinePortaUp EQU 18  ;O   ;Portamento Up Lent.
CFinePortaDn EQU 19  ;O   ;Portamento Down lent.
CGlissCtrl   EQU 20  ;N   ;Contr“le du glissando.  (pour le Tone portamento)
CVibCtrl     EQU 21  ;O   ;D‚finir la table du vibrato.
CFineTune    EQU 22  ;O   ;Modifier la p‚riode d'un son.
CJumpLoop    EQU 23  ;O   ;Bouclage de pattern.
CTremCtrl    EQU 24  ;O   ;D‚finir la table du tremolo.
CRien2       EQU 25  ;x
CRetrigNote  EQU 26  ;O   ;R‚attaque aprŠs x 50ø de secondes.
CVolFineUp   EQU 27  ;O   ;Augmente le volume lentement.
CVolFineDown EQU 28  ;O   ;Diminue le volume lentement.
CNoteCut     EQU 29  ;O   ;Couper la note aprŠs xx 50ø de secondes.
CNoteDelay   EQU 30  ;O   ;Lancer la note aprŠs xx 50ø de secondes.
CPattDelay   EQU 31  ;O   ;Retarde le d‚but du pattern suivant.
CFunkIt      EQU 32  ;N,I ;Jouer la note to l'envers.

CSetBPM      EQU 33  ;O   ;Fixer les BPM.
CSetGVolume  EQU 34  ;O   ;Fixer le volume general. (S3M)
CTremor      EQU 35  ;    ;Tremor (Note ON/OFF Alternativement)
CFreqAdj     EQU 36  ;O   ;Ajustement de la fr‚quence. (669)
CULTSpecial  EQU 37  ;N   ;Commande sp‚ciale ULT. (Stop Loop,...)
CVibSweep    EQU 38  ;N   ;Profondeur du vibrato.
CRelease     EQU 39  ;N   ;Key Off (SAT) !!!!! A programmer !!!!! 
CEFPortamento EQU 40 ;O   ;Extra Fine Portamento (XM,IT)													

Proc_Channel PROC NEAR       ; Traiter la partition

        CMP Pattern_Vide,1
        JNE Lire_Part
		RET
Lire_Part:

        MOV Start_Sample,0         ; OPT Can be replaced by one Byte
        MOV Start_Volume,0
        MOV Start_Periode,0
        MOV Save_Periode,0
        MOV Command_ProcOffs,OFFSET Do_Nothing
		MOV VC_Exec[BP],OFFSET Do_Nothing
		
                                   ; ----- Read the previous values -----
                                   ;In Note_xxxx Variables

        MOV CX,CH_Per_part[BP]
;        CALL Ajuster_Periode_Inv  ;Lecture de part => P‚riode MOD
        MOV Note_Periode,CX        ;Note_Period <- Current Period (Not modified by Vibrato and Arpeggio)

		MOV AL,Ch_Note[BX]
		MOV Note_Note,AL           ; Read the note currently played

        MOV AL,V_Par_Sample[BX]
        MOV Note_sample,AL	       ; Read the note sample playing
		
        ; ******* Read the Partition **********
        ; ***** 1: Read Sample *****
						  
        MOV AL,C_Instr             
        TEST AL,AL
        JNZ Do_Read_Instr_Infos
		JMP End_Instrument        ; No Instrument/Sample
Do_Read_Instr_Infos:	
		DEC AL

        MOV V_Par_Instr[BX],AL    ; Save the Sample number	
	
        CMP Type_Module,T_XM
        JNE Dont_Read_XMInstr

        ; ***** Read the Instrument Data *****
		
        ; * Convert Instrument number to Sample Number

        PUSH ES
		XOR AH,AH
		MOV CL,3
		SHL AX,CL                 ; Compute the Instrument Headed Offset (Header Size:8b}
		MOV DI,AX
        MOV ES,Seg_Instr          ; ES:DI Instrument Header
		MOV AL,ES:ISample_Nb[DI]  ; BL = Default Instrument sample number
		
		CMP ES:ISamples_Total[DI],1
		JBE XM_Instr_UseDefSmp    ; Only one sample in the instrument ? don't use the conversion table

		
		MOV AH,C_Note
		DEC AH
		CMP AH,95 ; Note >95 Means note=0 or Key Off -> Use Note_Note
        JBE XM_Instr_Read_Smp_Nb  ; Partition Note is Correct
		
		MOV AH,Note_Note
		DEC AH
		CMP AH,95 ; Note >95 Means note=0 or Key Off -> Use Note_Note		
		JA XM_Instr_UseDefSmp     ; Current Note incorrect
XM_Instr_Read_Smp_Nb:
       
	    INC AH
        PUSH BX    ; AH=Note, Preserve BX
        XOR BH,BH
	    MOV BL,AH
        MOV ES,ES:IInstrDataSeg[DI] ; Read the Instrument Data Tables Segment
        MOV AL,ES:[BX]              ; Read the Sample associated with the note (Table is at Offset 0)
;		writechar 'I'
        POP BX

XM_Instr_UseDefSmp:

        POP ES

Dont_Read_XMInstr:
        CMP AL,NB_Total_Samples
		JAE End_Instrument
		
        MOV V_Par_Sample[BX],AL    ; Save the Sample number		
		MOV Note_Sample,AL

      ; *** Read the Sample Values ***
		
		PUSH ES                    ; Save the pointer to the partition entry 
        XOR AH,AH
        Pointer_Sample AX
		
		TEST ES:SInfo[DI],M_Adlib
		JZ Read_Digital_Smp_Infos
        MOV AL,ES:AVolume[DI]      ; Read the Adlib Instrument Volume
        MOV VVolume_Part[BX],AL
		MOV AX,ES:ADadj[DI]        ; Read the Adlib Instrument FineTune (Converted to C#4 Adjust value)
        MOV VC4Spd[BP],AX

;        writechar 'A'

        JMP ReadSampleValues_End
Read_Digital_Smp_Infos:		
        MOV AL,ES:SVolume[DI]      ; Read the Sample Volume
        MOV VVolume_Part[BX],AL
		MOV AX,ES:SDadj[DI]        ; Read the Sample FineTune (Converted to C#4 Adjust value)
        MOV VC4Spd[BP],AX

If XMCMD Eq Yes
		MOV AL,ES:SRel_Note[DI]
		MOV V_Rel_Note[BX],AL
EndIf

;Reinit the Sample Offset
        MOV VSmp_Offset[BX],0

ReadSampleValues_End:					 
        POP ES

        MOV Start_Volume,1         ; Change the playing Volume to the Sample Volume
        TEST Ch_Control[BX],CM_FStop
		JZ End_Instrument
        AND Ch_Control[BX],Not (CM_Stopped+CM_FStop) ; If the Sample stop was forced, restart it.
		MOV Ch_Smp_Tick_Cnt[BX],0  ; Reset the Tick Counter
		
End_Instrument:

         ; ***** 2: Read the Note / Period ***** 127:Key Off

        MOV Periode_Partition,0
		XOR CX,CX
		MOV CL,C_Note
        CMP CL,127                   ; If Note=127 -> Key Off
        JNE LP_Pas_Note_KeyOff
		CMP V_Par_Sample[BX],0FFh    ; If No Instrument, no Key Off (Occurs only when no note has been played )
		JNE LP_KeyOff
		JMP End_Period
LP_KeyOff:		
        OR Ch_Control[BX],CM_KeyOff  ; Bit KeyOff to 1 !!!!!
		JMP End_Period
LP_Pas_Note_KeyOff:
        OR CX,CX
		JZ End_Period               ; Note 0 not played (To be Corrected to 0FFh}
		
If XMCMD Eq Yes
		ADD CL,V_Rel_Note[BX]       ; Add Relative Note
EndIf		
      
        CALL Get_Period

        MOV DX,CX
        SUB DX,Min_Period
        CMP DX,Moyen_Notes
        JA Periode_incorrecte       ; Periode incorrecte=>Periode_Partition=0
        MOV Periode_Partition,CX    ; Initialise la p‚riode

Periode_incorrecte:

        OR CX,CX                   ; Is there a Period in the partition ?
        JE End_Period
		MOV Save_Periode,1         ; Ask Note Delay to save the Period

; Check for Tone Portamento

        CMP Note_Note,0FFh
		JE Update_Note             ; If there is no playing Note, do not execute Tone Portamento

        MOV AL,C_Command           ; Tone Portamento -> Don't use the period
        CMP AL,TonePort
        JE Garder_Period_TP
        CMP AL,T_VSlide
        JE Garder_Period_TP

Update_Note:
; Update the Note and Period
        MOV AL,C_Note              ; Save/Update the Note
		MOV Note_Note,AL
		MOV Note_Periode,CX        ; Save/Update the Period
		JMP Per_Lancer_Sample
Garder_Period_TP:
; Start the Sample
        MOV AL,C_Instr
		OR AL,AL                 ; Instrument =0 ?
		JE End_Period            ; If Tone Portamento and No Sample or Same Sample, Don't start sample
		DEC AL                   ; DEC Sample
        CMP AL,CH_Smp_Pla[BX]		
        JE End_Period

Per_Lancer_Sample:   ; *** Start a Note ***
        MOV Start_Periode,1                ;--  Change the Note    --
        MOV Start_Sample,1                 ;--  Change the Sample  --
        AND Ch_Control[BX],Not CM_KeyOff   ; Disable Key Off	

;Reinit the Sample Offset
;        MOV VSmp_Offset[BX],0 ; If Not ProTracker

        TEST Retrig_V_Tr[BX],M_Retrig_Vib ; Test if we need to reset the Vibrato and tremolo index when a note is started
        JNZ Pas_Retrig_Vibrato
        MOV Vibr_Index[BX],0
Pas_Retrig_Vibrato:		
        TEST Retrig_V_Tr[BX],M_Retrig_Trem
        JNZ Pas_Retrig_Tremolo
        MOV Trem_Index[BX],0
Pas_Retrig_Tremolo:

End_Period:                   
  
        ; ***** 3: Read Volume
		
        MOV AL,C_Volume            
        CMP AL,0FFh                ; 0FFh -> No Volume ; OPT Be carefull about Vol Col Effect
        JE End_VolumeCmd
        CMP AL,50h                 ; Volume Effects Start at 50h
        JA Test_Volume_Effects
        MOV VVolume_Part[BX],AL
        MOV Start_Volume,1
		JMP End_VolumeCmd
		
Test_Volume_Effects:
        ; ***** 3b: Volume Commands
;WriteCh 'V'
;Writech 'c'
        CALL Do_VolCol_Commands
		
End_VolumeCmd:
        ;Test if we need to reset the Period for an Arpeggio

        ; ***** 4: Partition Commands execution ************
		
		MOV AH,C_Command
        MOV AL,C_Param	
		MOV VCurrent_CMD[BX],AH
        MOV VCurrent_PAR[BX],AL

; Commands Below (Vibrato, Arpeggio) must be always checked (If Not present)  -> Be carefull during partition decode !
        CMP AH,CVibrato
        JNE Pas_eff_4
		OR Retrig_V_Tr[BX],M_Vib_VibVS_Cmd
        CALL Execute_vibrato
        JMP Fin_Commandes
Pas_eff_4:
        CMP AH,Vib_Vslide
        JNE Pas_eff_6
		OR Retrig_V_Tr[BX],M_Vib_VibVS_Cmd
        CALL Exec_Vib_vs
        JMP Fin_Commandes
Pas_eff_6:
;No Vibrato,-> Test if the Previous command was a Vibrato
        Test Retrig_V_Tr[BX],M_Vib_VibVS_Cmd
		JZ Vib_VibVS_NoResetPeriod
		AND Retrig_V_Tr[BX],Not M_Vib_VibVS_Cmd
		MOV Start_Periode,1 ; Change Period if the previous command was Vibrato or VS
Vib_VibVS_NoResetPeriod:	

        CMP AH,CArpeggio     ; Is it Arpeggio ?
        JNE Pas_eff_0
        CALL Exec_Arpeggio
        JMP Fin_Commandes
Pas_eff_0:
;No Arpeggio,-> Test if the Previous command was an Arpeggio
        TEST Retrig_V_Tr[BX],M_Arpegio
		JZ No_Retrig_Arpeggio
        AND Retrig_V_Tr[BX],Not M_Arpegio
		MOV Start_Periode,1 ; Change Period if the previous command Arpeggio
No_Retrig_Arpeggio:	

		OR AH,AH
		JNE Exec_Command		
		JMP Fin_Commandes		
Exec_Command:

        CMP AH,CSetVolume
        JNE Pas_eff_C
        CMP AL,40h
        JBE Volume_correct
        MOV AL,40h
Volume_correct:
        MOV VVolume_Part[BX],AL
        MOV Start_Volume,1
        JMP Fin_Commandes
Pas_eff_C:
        CMP AH,PortDown
        JNE Pas_eff_2
        CALL Exec_Port_DN
        JMP Fin_Commandes
Pas_eff_2:
        CMP AH,PortUp
        JNE Pas_eff_1
        CALL Exec_Port_UP
        JMP Fin_Commandes
Pas_eff_1:
        CMP AH,VolSlide
        JNE Pas_eff_A
        CALL Exec_Vol_slide
        JMP Fin_Commandes
Pas_eff_A:
        CMP AH,EndPattern
        JNE Pas_eff_D
        CALL Exec_EndPattern
        JMP Fin_Commandes
Pas_eff_D:
        CMP AH,TonePort
        JNE Pas_eff_3
        CALL Exec_Tone_prt
        JMP Fin_Commandes
Pas_eff_3:
        CMP AH,SetTempo
        JNE Pas_eff_F
        CALL Exec_set_tempo
        JMP Fin_Commandes
Pas_eff_F:
        CMP AH,T_Vslide
        JNE Pas_eff_5
        CALL Exec_Tone_vs
        JMP Fin_Commandes
Pas_eff_5:
        CMP AH,JumpPattern
        JNE Pas_eff_B
        CALL Exec_JumpPattern
        JMP Fin_Commandes
Pas_eff_B:
        CMP AH,CVolFineUp
        JNE Pas_VlFUp
        CALL Exec_VolFineUp
        JMP Fin_Commandes
Pas_VlFUp:
        CMP AH,CVolFineDown
        JNE Pas_VlFDown
        CALL Exec_VolFineDown
        JMP Fin_Commandes
Pas_VlFDown:
        CMP AH,CFinePortaUp
        JNE Pas_eff_FinePortUp
        CALL Exec_FinePortaUp
        JMP Fin_Commandes
Pas_eff_FinePortUp:
        CMP AH,CFinePortaDn
        JNE Pas_eff_FinePortDown
        CALL Exec_FinePortaDown
        JMP Fin_Commandes
Pas_eff_FinePortDown:
        CMP AH,CTremolo
        JNE Pas_Tremolo
        CALL Exec_Tremolo
        JMP Fin_Commandes
Pas_Tremolo:
        CMP AH,CNoteCut
        JNE Pas_NoteCut
        CALL Exec_NoteCut
        JMP Fin_Commandes
Pas_NoteCut:
        CMP AH,CRetrigNote
        JNE Pas_RetrigNote
        CALL Exec_RetrigNote
        JMP Fin_Commandes
Pas_RetrigNote:
        CMP AH,SampleOffs
        JNE Pas_SampleOffs
        CALL Exec_SampleOffs
        JMP Fin_Commandes
Pas_SampleOffs:
        CMP AH,CJumpLoop
        JNE Pas_JumpLoop
        CALL Exec_JumpLoop
        JMP Fin_Commandes
Pas_JumpLoop:
        CMP AH,CFineTune
        JNE Pas_FineTune
        CALL Exec_FineTune
        JMP Fin_Commandes
Pas_FineTune:
        CMP AH,CVibCtrl
        JNE Pas_VibCtrl
        CALL Exec_VibCtrl
        JMP Fin_Commandes
Pas_VibCtrl:
        CMP AH,CTremCtrl
        JNE Pas_TremCtrl
        CALL Exec_TremCtrl
        JMP Fin_Commandes
Pas_TremCtrl:
        CMP AH,CSetBPM
        JNE Pas_SetBPM
        CALL Exec_SetBPM
        JMP Fin_Commandes
Pas_SetBPM:
        CMP AH,CSetGVolume
        JNE Pas_SetGVolume
        CALL Exec_SetGVolume
        JMP Fin_Commandes
Pas_SetGVolume:
        CMP AH,CPanning
        JNE Pas_Panning
        CALL Exec_Panning
        JMP Fin_Commandes
Pas_Panning:
        CMP AH,CPattDelay
        JNE Pas_PattDelay
        CALL Exec_PattDelay
        JMP Fin_Commandes
Pas_PattDelay:
        CMP AH,CNoteDelay
        JNE Pas_NoteDelay
        CALL Exec_NoteDelay
        JMP Pas_Start_Periode     ; Don't change the Note/Period, but can change the Volume
Pas_NoteDelay:
        CMP AH,CTremor
        JNE Not_Tremor
        CALL Exec_Tremor
        JMP Fin_Commandes		
Not_Tremor:
        CMP AH,CEFPortamento
		JNE Not_EFPort
		CALL Exec_EFPort
Not_EFPort:

Fin_Commandes:                     ; ********************** Samples Start *************************

        CMP Start_Sample,1         ;Modifier l'instrument ?
        JNE Pas_Start_Sample
If Mod_Master eq yes		
        OR Ch_Control[BX],M_VolChanged   ;Pitch display	
EndIf		
;WriteCh '.'	
        CALL DoStart_Sample        ; !!!!!!! Si le sample est le meme juste faire "Retrig"

Pas_Start_Sample:

        CMP Start_Periode,1
		JNE Pas_Start_Periode
        MOV CX,Note_Periode
        MOV CH_Per_part[BP],CX     ;Save the Period to play
        CALL Set_Period            ;Fixer la p‚riode de la voie
		MOV CL,Note_Note
		MOV Ch_Note[BX],CL		
Pas_Start_Periode:

        CMP Start_Volume,1         ;Modifier le volume ?
        JNE Pas_Start_Volume
        MOV AL,VVolume_Part[BX]    ;Read the Volume
        CALL Set_Ch_Volume

Pas_Start_Volume:
Fin_Proc_Channel:

        MOV AX,Command_ProcOffs
        MOV CH_Command[BP],AX

        RET

Proc_Channel ENDP

; XM Volume Commands


;    $b0-$bf   Vibrato
;    $c0-$cf   Set panning
;    $d0-$df   Panning slide left
;    $e0-$ef   Panning slide right
;    $f0-$ff   Tone porta

; Volume slide and Vol Volume Slide CMD Does not share the same variable, not here.

Do_VolCol_Commands Proc Near
        SUB AL,50h
		CMP AL,10h
		JAE Not_VE_VSDown
;*   $60-$6f   Volume slide down
		
        TEST AL,AL
        JZ VE_VSD_End   ; Zero -> No Nothing (No Save)
        MOV Param_vs[BX],AL
		MOV VC_Exec[BP],Offset Volume_Slide
VE_VSD_End:
;WriteChar 'D'
		RET
Not_VE_VSDown:
		CMP AL,20h
		JAE Not_VE_VSUp
;    $70-$7f   Volume slide up		

		MOV CL,4
		SHL AL,CL
        TEST AL,AL
        JZ VE_VSU_End   ; Zero -> No Nothing (No Save)
        MOV Param_vs[BX],AL
        MOV VC_Exec[BP],Offset Volume_Slide
VE_VSU_End:
;WriteChar 'U'
		RET
Not_VE_VSUp:
		CMP AL,30h
		JAE Not_VE_FVSDown
;    $80-$8f   Fine volume slide down		

		AND AL,0Fh
		TEST AL,AL
		JZ VE_FVSDown_RET
        MOV CL,VVolume_Part[BX]
        SUB CL,AL
        CMP CL,40h
        JB VE_FVSDownOk
        XOR CL,CL
VE_FVSDownOk:
		MOV VVolume_Part[BX],CL
        MOV Start_Volume,1
VE_FVSDown_RET:
;WriteChar 'd'
		RET
Not_VE_FVSDown:
		CMP AL,40h
		JAE Not_VE_FVSUp
;    $90-$9f   Fine volume slide up

		AND AL,0Fh
		TEST AL,AL
		JZ VE_FVSUp_RET
        MOV CL,VVolume_Part[BX]
        ADD CL,AL
        CMP CL,40h
        JBE VE_FVSUpOk
        MOV CL,40h
VE_FVSUpOk:
		MOV VVolume_Part[BX],CL
        MOV Start_Volume,1
VE_FVSUp_RET:
;Writechar 'u'
		RET
Not_VE_FVSUp:
		CMP AL,50h
		JAE Not_VE_VibSpeed
;    $a0-$af   Set vibrato speed
;Writechar '1'
		RET
Not_VE_VibSpeed:
		CMP AL,60h
		JAE Not_VE_Vib
;Writechar '2'
		RET
Not_VE_Vib:
		CMP AL,70h
		JAE Not_VE_Panning
	
		AND AL,0Fh
		SHL AL,1
		SHL AL,1
		SHL AL,1          ; Convert Panning: 0-0Fh to 0-80h
		CALL Exec_Panning

;Writechar 'P'

		RET
Not_VE_Panning:
		CMP AL,80h
		JAE Not_VE_PSlideL
;Writechar '3'
		RET
Not_VE_PSlideL:		
		CMP AL,90h
		JAE Not_VE_PSlideR
;Writechar '4'
		RET
Not_VE_PSlideR:	
		CMP AL,0A0h
		JAE Not_VE_ToneP
;Writechar '5'
		RET
Not_VE_ToneP:	

		RET
Do_VolCol_Commands Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   DoStart_Sample:  Change le sample pour une voie         ³
;³                                                           ³
;³   Input : Note_Sample, Le Nø de sample.                  ³
;³            BX,BP Channel number                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DoStart_Sample Proc Near

        MOV AL,Note_Sample
        CMP AL,Nb_Total_Samples
        JAE Pas_de_sample             ;Nø du sample trop grand !!!

        XOR AH,AH
		Pointer_Sample AX
		
        MOV DL,ES:SInfo[DI]
        TEST DL,M_Charge             ;Sample is Loaded ?
        JZ  Pas_de_sample            ;No -> Stop the Channel

        CMP M_CH_Type[BX],1          ;Channel Type  ?     1:Digital/2:Adlib
        JE  Start_Digit_Sample       ;Non => Ne pas changer !!!

;Start Adlib Sample
        MOV CH_Smp_Pla[BX],AL
        MOV AX,ES:ADadj[DI]
        MOV VC4Spd[BP],AX
		
		JMP Fin_DoStart_Sample

Start_Digit_Sample:	
        MOV CH_Smp_Pla[BX],AL
		XOR AL,AL
		MOV AH,VSmp_Offset[BX]    ;Sample Start Offset
        MOV VOffset_actuel[BP],AX
        MOV VAccumulateur[BX],0
        MOV AX,ES:SDadj[DI]
        MOV VC4Spd[BP],AX

Fin_DoStart_Sample:
	
		XOR AL,AL
        TEST DX,M_Boucle
		JZ LoopType_NoLoop
		INC AL
LoopType_NoLoop:
		MOV Ch_LoopType[BX],AL             ; Reset the Loop Type for priority definition

        MOV Ch_Smp_Tick_Cnt[BX],0          ; Reset the Counter for Sample playing duration
        AND Ch_Control[BX],Not (CM_Stopped+CM_FStop)  ; Bit to 0 => Start the Channel
If UseGUS Eq Yes
        OR GUS_Controle[BX],M_ChSample     ; Change the Sample (GUS/Adlib)
EndIf
        RET
		
Pas_de_sample:
        OR Ch_Control[BX],CM_Stopped       ; Bit to 1 => Stop the Channel
		RET
DoStart_Sample Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Set_Ch_Volume:  Change the volume for a channel        ³
;³                                                           ³
;³   Input : BX=Channel number;BP=2*BX                       ³
;³           AL=Le volume                                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Set_Ch_Volume Proc near

        CMP AL,40h
        JBE SetVolOk
;       Writechar 'x'
        RET
SetVolOk:

        XOR AH,AH
        MOV VVolume_re[BX],AL

        PUSH BX
        MOV BL,Volume_total  ; Volume controlled by the user and the Fading
        CMP BL,40h
        JE Total_Volume_Max	
        MUL BL
If ModeXT Eq Yes
        MOV CL,6
		SHR AX,6
Else
        SHR AX,6
EndIf
Total_Volume_Max:

        MOV BL,Volume_General ; Volume in the partition
        CMP BL,40h
        JE GVol_Max
        MUL BL
If ModeXT Eq Yes
        MOV CL,6
		SHR AX,CL
Else
        SHR AX,6
EndIf
GVol_Max:
        POP BX

        MOV VVolume[BX],AL              ;Ajuste le volume (Voie BX)
If UseGUS eq yes
        OR  GUS_Controle[BX],M_ChVolume ;Pour la Gravis UltraSound
EndIf
		
;If ModeXT Eq No
;       CMP Calculer_Panning,1
;       JNE Pas_Ajuster_VP

        CALL Ajuster_Volumes_Panning ;Calculer les volumes pour le panning (Not supported for the moment)
;Pas_Ajuster_VP:
;EndIf
        RET
Set_Ch_Volume EndP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Ajuster_Volumes_Panning : Calcul du volume gauche et    ³
;³                             du volume droit               ³
;³                                                           ³
;³   Input : BX=Nø de voie;BP=2*CX                          ³
;³            AL=Le volume                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;If ModeXT eq No
Ajuster_Volumes_Panning Proc near

;        MOV AL,VVolume[BX]

;        PUSH AX
;        MOV DL,CH_Panning[BX]
;        MUL DL
;If ModeXT Eq Yes
;        MOV CL,7
;		SHR AX,CL
;Else
;        SHR AX,7
;EndIf        
;        MOV Ch_Vol_Right[BX],AL    ;40h -> Volume Maxi
;        POP AX

;        MOV DH,80h
;        SUB DH,DL
;        MUL DH
;If ModeXT Eq Yes
;        MOV CL,7
;		SHR AX,CL
;Else
;        SHR AX,7
;EndIf
;        MOV Ch_Vol_Left[BX],AL    ;40h -> Volume Mini  ; Does not need to compute Volume Left and right if Gravis
        OR GUS_Controle[BX],M_ChPanning  ;Set the M_ChPanning Bit	
        RET
Ajuster_Volumes_Panning Endp
;EndIf

Get_Period Proc Near
        PUSH BX                     ; Read the Period from the note
		MOV BX,CX
		SHL BX,1
		MOV CX,T_per0[BX]
		
        MOV BX,DS:VC4Spd[BP]
        CMP BX,8363
        JE Not_Adjust_Period
        CMP BX,100               ; Marge de 100 (qui digitalise to 100 Hz ?)
        JB Not_Adjust_Period

                                 ; - Ajuster la p‚riode - ( Fr‚q pour C-4 )
        PUSH AX
        PUSH DX
        MOV AX,8363
        MUL CX
        DIV BX
        MOV CX,AX                ;AX=Periode*8363/Dadj
        POP DX
        POP AX

Not_Adjust_Period:		
		
		POP BX
		RET
Get_Period EndP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Set_Period: Change la p‚riode pour une voie        ³
;³                    avec v‚rification de la valeur         ³
;³                                                           ³
;³   Input : BX=Nø de voie                                  ³
;³            BP=2*BX                                        ³
;³            CX=La p‚riode                                  ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Set_Period PROC NEAR

;Writechar 'P'

		CMP CX,10
		JBE Pas_Set_Period          ; No Period <10

		CMP CX,Min_Period
		JL Pas_Set_Period
		CMP CX,Max_Period
		JA Pas_Set_Period           ; Periode incorrecte=>Periode=0

        CMP M_CH_Type[BX],2         ; Channel Type ?  1:Digital/2:Adlib
        JE Change_Periode_GUS       ; Adlib code use the "GUS" Frequency

If UseGUS eq yes
        CMP Sortie_sonore,GUS       ;  GUS ?
		JE  Change_Periode_GUS
EndIf

        PUSH CX
        MOV DX,P_Amiga_h        ;Calcul des incr‚ments pour le mixage.
        MOV AX,P_Amiga_l
        DIV CX  ; Avoid DIV by 0

        MOV VPart_entiere[BX],AH
        MOV VPart_decimale[BX],AL
		
		XOR AX,AX
        MOV AX,DX              ; Divide with the Rest for Better Precision
        DIV CX
        MOV VPart_decimale2[BX],AH
		
        POP CX
		RET
		
Pas_Set_Period:

        RET

;If UseGUS eq yes or UseOPL2 Eq Yes
                                ;Calcul de la frequence en Hz pour la GUS
Change_Periode_GUS:

		; 14317456 = C-4 Period*C-4 Frequency (1712*8363) (DA 7790h)
        SHL BP,1
		
		XOR DX,DX            ; Divide 32Bit by 16Bit
		MOV AX,0DAh
		DIV CX		
		MOV B GUS_Frequency[BP+2],AL ; High part of the Frequency
		MOV AX,7790h
		DIV CX
		MOV W GUS_Frequency[BP],AX

		OR GUS_Controle[BX],M_ChPeriode  ;Change the Period
Pas_Div5:
        SHR BP,1

        RET
;EndIf

Set_Period ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Set_Period_Fine : Modifier la p‚riode suivant la   ³
;³                          valeur du FineTune               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseFineTune Eq Yes
Set_Period_Fine Proc Near

        PUSH SI
        PUSH CX

        CMP Start_Periode,0
        JE Fin_Fine
        CMP Use_FineTune_CMD,1
        JNE Fin_Fine
        MOV DX,Periode_Partition
                                  ;Cherche l'indice de la p‚riode
        XOR CX,CX                 ;Actuelle dans la table
        MOV SI,Offs_Table_tune    ;PremiŠre table
Fine_Boucle_cherche_per:
        LODSW
        CMP AX,DX
        JBE Fine_Periode_trouvee
        INC CX
        CMP CX,Total_FineTune
        JNE Fine_Boucle_cherche_per
        JMP Fin_Fine              ;Note non trouv‚e => Pas de FineTune
Fine_Periode_trouvee:

        MOV AL,VFineTune[BX]
        XOR AH,AH
        SHL AX,1
        MOV SI,Offset Offs_Table_tune
        ADD SI,AX
        MOV AX,w [SI]
        MOV Adresse_Table_periode[BP],AX
        MOV SI,AX
        SHL CX,1
        ADD SI,CX
        MOV AX,w [SI]      ;AX <- Nouvelle periode
        MOV Periode_Partition,AX
Fin_Fine:
        POP CX
        POP SI
        RET
Set_Period_Fine Endp
EndIf


;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ DoXMEnv:                                                                ³
;³                                                                         ³
;³ Input: ES:DI Pointer to the Vol Env Data                            ³
;³        ESI Pointer to the envelope data structure (EnvPos, EnvSegPos)   ³
;³                                                                         ³
;³ Output: EAX Envelope value                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseVolEnv eq Yes

P0    EQU Word Ptr
Val0  EQU Word Ptr 2
P1    EQU Word Ptr 4
Val1  EQU Word Ptr 6

ES:DI Pointer to the Vol Env Data

EnvType DB 0

DoXMEnv Proc
        cmp V_ChEnvSegPos[bp],0
        jne XMEnvNoLoop

        mov dx,V_EnvPos[bp]

; ** Do Sustain **

        test ES:EnvType[di],E_Sustain ;Sustain Off => Always do loop
        jz XMEnvDoLoop

        cmp dl,ES:EnvSustain[di]     ;When fade is on, do not loop if sustain
        jne XMEnvDoLoop              ;point is Loop end point 
                                     ;(fade is release with FT2)

        test Ch_Control[BX],Not M_FadeVol ;Don't loop when fade is on
        jnz XMEnvNoLoop                  ;and current point is sustain

; ** Do Loop **
XMEnvDoLoop:
        test Envtype[edi],E_Loop
        jz XMEnvNoLoop
	
        cmp dl,ES:EnvLoopEnd[di]
        jne XMEnvNoLoop
        mov dl,ES:EnvLoopStart[di]
        mov VChEnvPos[esi+2*ebp],dx
XMEnvNoLoop:

; ** Get Envelope value **
        movzx eax,VChEnvPos[esi+2*ebp]
        lea ecx,EnvEnvelope[edi+4*eax]
        inc al
        cmp al,EnvPoints[edi]             ;Is it the envelope End ?
        je XMEnvLast
        movsx eax,P0[ecx]
        movsx ebx,P1[ecx]
        sub ebx,eax
        mov DPos,bx
        movsx eax,Val1[ecx]
        movsx edx,Val0[ecx]
        sub eax,edx
        imul VChEnvSegPos[esi+2*ebp]
        idiv DPos
        add ax,Val0[ecx]         ; al=Val0+((Val1-Val0)*chVolEnvSegPos)/DPos

; ** Process Sustain if no KeyOff **
	    cmp VChEnvSegPos[esi+2*ebp],0
	    jne XMEnvNoSustain
        test EnvType[edi],E_Sustain
        jz XMEnvNoSustain
        test VChControl[2*ebp],CC_FadeVol ; (KeyOff for FT2)
        jnz XMEnvNoSustain                ; If KeyOff, No sustain
        movzx edx,VChEnvPos[esi+2*ebp]
        cmp dl,EnvSustain[edi]
        je XMEnvEnd                       ;Do volume Sustain

XMEnvNoSustain:
        movzx edx,VChEnvSegPos[esi+2*ebp]
        inc edx
        cmp dx,DPos
        jb XMEnvNoStep
        xor edx,edx                     ;Envelope Pos is at an envelope point
        inc VChEnvPos[esi+2*ebp]
XMEnvNoStep:
        mov VChEnvSegPos[esi+2*ebp],dx
        jmp XMEnvEnd

XMEnvLast:
        mov ax,Val0[ecx]
XMEnvEnd:

        ret
DoXMEnv Endp
endif   ;UseVolEnv

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³              Installation des commandes                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Set General Volume   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_SetGVolume PROC NEAR
        CMP AL,40h
        JBE Pas_Ajuster_GVol   ; si >40h mettre 40h
        MOV AL,40h
Pas_Ajuster_GVol:
        MOV Volume_General,AL
        CALL Changer_le_volume ; Ajuster le volume pour toutes les voies !!
        RET
Exec_SetGVolume Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³       Set Tempo        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_set_tempo PROC NEAR

        OR AL,AL
        JZ Fin_Exec_set_tempo
        MOV Tempo,AL
        MOV Cmpt_Tempo,AL
Fin_Exec_set_tempo:
        RET

Exec_set_tempo ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     Pattern Break      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_EndPattern Proc Near
        MOV AH,AL
        AND AH,0Fh                 ;Convertir de BCD to Hexa
        AND AL,0F0h
        SHR AL,1
        ADD AH,AL
If ModeXT Eq Yes
        SHR AL,1
		SHR AL,1
Else
        SHR AL,2
EndIf
        ADD AH,AL
        CMP AH,C_Patt_Length
        JAE Fin_EndPattern
        MOV DoPatternBreak,1
        MOV PattBreakRow,AH
Fin_EndPattern:
        RET
Exec_EndPattern Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Jump Pattern      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_JumpPattern Proc Near
        MOV AH,AL

        CMP AH,C_Sequence
		JAE Jump_NoLoop
        DS_TP
        MOV AL,Boucler_MOD
        DS_ASM
        OR AL,AL
        JZ Fin_JumpPattern
Jump_NoLoop:		

        CMP AH,Sequence_Len
        JA Fin_JumpPattern
        MOV PJumpPattern,1
        MOV JumpParam,AH

Fin_JumpPattern:
        RET
Exec_JumpPattern Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³       PattDelay        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_PattDelay Proc Near
        OR AL,AL
        JZ Fin_PattDelay
        MOV CL,Tempo
        XOR AH,AH
        MUL CL
        MOV Cmpt_Tempo,AL   ;Attendre Tempo*Parametre 50ø de secondes...
Fin_PattDelay:
        RET
Exec_PattDelay EndP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³       Arpeggio         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Arpeggio PROC NEAR

        MOV DX,Note_Periode
        OR DX,DX
        JZ Fin_Exec_Arpeggio      ;P‚riode nulle => Fin

        XOR CX,CX
		MOV CL,Note_Note          ;CX=Current note index
If XMCMD Eq Yes
		ADD CL,V_Rel_Note[BX]     ; Add Relative Note
EndIf	
		
        MOV Per0_arp[BP],DX       ;Period 0 arpeggio

        XOR AH,AH
        PUSH BX
		
        PUSH CX                   ; Save the Note
;		MOV BX,CX                 ; Note -> BX
If ModeXT Eq Yes
        SHR AL,1
		SHR AL,1
        SHR AL,1
		SHR AL,1		
Else
        SHR AL,4
EndIf
        ADD CX,AX
        CMP CX,12*Nb_Octaves_Total
        JA Pas_modif_per1

        CALL Get_Period
Pas_modif_per1:
        MOV Per1_arp[BP],CX       ;Period 1 arpeggio
        POP CX 
		
        MOV AL,C_Param
        AND AL,00001111b

        ADD CX,AX
        CMP CX,12*Nb_Octaves_Total
        JA Pas_modif_per2
		
        CALL Get_Period
Pas_modif_per2:
        POP BX
		
        MOV Per2_arp[BP],CX     ;Period 2 arpeggio
		
        OR Retrig_V_Tr[BX],M_Arpegio            ; Set the Mask saying that an Arpeggio is Started.
        MOV Compt_arp[BX],0
        MOV Command_ProcOffs,OFFSET Do_arpeggio		

Fin_Exec_Arpeggio:
        RET
Exec_Arpeggio ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Portamento Down     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_port_DN PROC NEAR

        TEST AL,AL
        JZ Pas_modif_Port_Dn
        MOV Param_pr_dn[BX],AL
Pas_modif_Port_Dn:
        MOV Command_ProcOffs,OFFSET Port_down
        RET
Exec_port_DN ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Portamento Up       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Port_up PROC NEAR

        TEST AL,AL
        JZ Pas_modif_Port_Up
        MOV Param_pr_up[BX],AL
Pas_modif_Port_Up:
        MOV Command_ProcOffs,OFFSET Port_Up
        RET
Exec_Port_up ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Fine Portamento Up    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_FinePortaUp PROC NEAR
        TEST AL,AL
        JZ Pas_modif_PortFineUp
        MOV Param_pr_up[BX],AL
Pas_modif_PortFineUp:
        MOV Cmpt_Commande[BX],0
        MOV Command_ProcOffs,OFFSET Fine_Portamento_Up
        RET
Exec_FinePortaUp ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Fine Portamento Down  ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_FinePortaDown PROC NEAR
        TEST AL,AL
        JZ Pas_modif_PortFineDown
        MOV Param_pr_Dn[BX],AL
Pas_modif_PortFineDown:
        MOV Cmpt_Commande[BX],0
        MOV Command_ProcOffs,OFFSET Fine_Portamento_Down
        RET
Exec_FinePortaDown ENDP


;--------------------------
;  Extra Fine Protamento
;  Parma : 1x EFPort Down
;          éx EFPort Up
;--------------------------

Exec_EFPort PROC NEAR	
        TEST AL,AL
        JNZ EFPort_DirOk
		MOV AL,Param_EFPort[BX]
EFPort_DirOk:
        CMP AL,20h
		JAE EF_Port_Down
        CMP AL,10h
        JAE EF_Port_Up
        RET
		
EF_Port_Up:
        JNE EF_PortUp_ParamOk
		MOV AL,Param_EFPort[BX]
EF_PortUp_ParamOk:
        MOV Param_EFPort[BX],AL   ; Save the correct parameter
		AND AX,000Fh
		MOV CX,Note_Periode
		SUB CX,AX
        MOV Start_Periode,1       ; Change and "Start" the Period
        MOV Note_Periode,CX
		RET
		
EF_Port_Down:
        JNE EF_PortDn_ParamOk
		MOV AL,Param_EFPort[BX]
EF_PortDn_ParamOk:
        MOV Param_EFPort[BX],AL   ; Save the correct parameter
		AND AX,000Fh
		MOV CX,Note_Periode
		ADD CX,AX
        MOV Start_Periode,1       ; Change and "Start" the Period
        MOV Note_Periode,CX
        RET
Exec_EFPort ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     Volume slide       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Vol_slide PROC NEAR

        TEST AL,AL
        JZ Garde_vs
        MOV Param_vs[BX],AL
Garde_vs:
        MOV Command_ProcOffs,OFFSET volume_slide
        CMP Volume_Sl_Rapide,1
        JNE Pas_Volume_Sl_Rapide
        CALL Volume_Slide
Pas_Volume_Sl_Rapide:
        RET

Exec_Vol_slide ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Volume Fine Up      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_VolFineUp PROC NEAR

        TEST AL,AL
        JZ Garde_vfUp
If ModeXT eq Yes         ;ParamŠtre to gauche pour +
		SHL AL,1
		SHL AL,1
        SHL AL,1	  	 
		SHL AL,1
Else
        SHL AL,4
EndIf        
        MOV param_vs[BX],AL
Garde_VFUp:
        MOV Cmpt_Commande[BX],0
        MOV Command_ProcOffs,OFFSET volume_fine
        RET

Exec_VolFineUp ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Volume Fine Down    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_VolFineDown PROC NEAR

        TEST AL,AL
        JZ Garde_vfDown
        MOV param_vs[BX],AL
Garde_VFDown:
        MOV Cmpt_Commande[BX],0
        MOV Command_ProcOffs,OFFSET volume_fine
        RET

Exec_VolFineDown ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Tone portamento     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Tone_prt PROC NEAR

        MOV CX,Periode_Partition   ; Period in the partition -> Target Period
        TEST CX,CX                 ; Periode=0 => Continue the previous Tone Port
        JNZ Cont_Exec_3
        CMP Per_tone_prt[BP],0     ; Period=0 and Target Period=0 Do Nothing
        JZ  Fin_exec_Tone_prt
        JMP Exec_ancien_3          ; Ancien Tone Prt incorrect => Fin
Cont_exec_3:
		MOV DX,CX
        MOV Per_tone_prt[BP],DX
        MOV dir_tone_prt[BX],0
        MOV CX,Note_Periode        ; Currently played period

        CMP DX,CX
        JA  Exec_ancien_3          ; Choisir la direction du Tone
        MOV dir_tone_prt[BX],1     ; Portamento
Exec_ancien_3:
        OR AL,AL
        JZ utilise_anc_param       ; Utilise l'ancien paramŠtre si=0
        MOV param_tone_prt[BX],AL
utilise_anc_param:
        MOV Command_ProcOffs,OFFSET Tone_portamento
Fin_Exec_Tone_prt:
        RET

Exec_Tone_prt ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³        Vibrato         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Execute_vibrato PROC NEAR

        MOV AH,AL
        OR AH,AH
        JZ Keep_Vib_Speed      ;ParamŠtre=0 =>on conserve les valeurs
                               ;Pr‚c‚dentes
        AND AL,0Fh
		OR AL,AL
		JZ Keep_Vib_Amp
        MOV Amplitude_vib[BX],AL
Keep_Vib_Amp:		
If ModeXT Eq Yes
        SHR AH,1
		SHR AH,1
        SHR AH,1
		SHR AH,1		
Else
        SHR AH,4
EndIf
        OR AH,AH
		JZ Keep_Vib_Speed
        MOV Vitesse_vib[BX],AH
Keep_Vib_Speed:
        MOV Command_ProcOffs,OFFSET Vibrato
		
;		CALL Vibrato           ; Vibrato even when we read the partition
        RET

Execute_vibrato ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³        Tremolo         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Tremolo PROC NEAR
        MOV AH,AL
        TEST AH,AH
        JZ Garde_val_tre        ;ParamŠtre=0 =>on conserve les valeurs
                                ;Pr‚c‚dentes
        AND AL,0Fh
        MOV Amplitude_trem[BX],AL
If ModeXT Eq Yes
        SHR AH,1
		SHR AH,1
        SHR AH,1
		SHR AH,1		
Else
        SHR AH,4
EndIf		
        MOV Vitesse_trem[BX],AH

Garde_val_tre:
        CMP Start_Volume,1
        JNE Pas_modif_vol_tremolo
        MOV Trem_Index[BX],0
Pas_modif_vol_tremolo:
        MOV Command_ProcOffs,OFFSET Tremolo
        RET

Exec_Tremolo ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Tremor      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Tremor PROC NEAR
        OR AL,AL
        JZ Garde_Val_Tremor
        MOV Param_Tremor[BX],AL
        MOV Partie_Tremor[BX],0     ;0 Note On, 1 Note Off
Garde_Val_Tremor:
        MOV Cmpt_Commande[BX],0
        MOV Command_ProcOffs,OFFSET Tremor
        RET
Exec_Tremor ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Vibrato Controle    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_VibCtrl Proc near
        OR Retrig_V_Tr[BX],M_Retrig_Vib
        CMP AL,4
        JB  ERetrig_Vib
        AND Retrig_V_Tr[BX],NOT M_Retrig_Vib
        SUB AL,4
ERetrig_Vib:

        CMP AL,0
        JNE Pas_Vib_Sinus
        MOV DS:Table_Vibrato[BP],Offset Ta_vib      ;Sinus
        JMP Fin_Exec_VibCtrl
Pas_Vib_Sinus:
        CMP AL,1
        JNE Pas_Vib_Rampe
        MOV DS:Table_Vibrato[BP],Offset Ta_rampe
        JMP Fin_Exec_VibCtrl
Pas_Vib_Rampe:
        CMP AL,2
        JNE Pas_Vib_Carre
        MOV DS:Table_Vibrato[BP],Offset Ta_carre
Pas_Vib_Carre:                      ;4 => Hazard (Garde la meme valeur )

Fin_Exec_VibCtrl:
        RET
Exec_VibCtrl Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Tremolo Controle    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_TremCtrl PROC NEAR
        OR Retrig_V_Tr[BX],M_Retrig_Trem
        CMP AL,4
        JB  ERetrig_Trem
        AND Retrig_V_Tr[BX],NOT M_Retrig_Trem
        SUB AL,4
ERetrig_Trem:

        CMP AL,0
        JNE Pas_Trem_Sinus
        MOV DS:Table_Tremolo[BP],Offset Ta_vib      ;Sinus
        JMP Fin_Exec_TremCtrl
Pas_Trem_Sinus:
        CMP AL,1
        JNE Pas_Trem_Rampe
        MOV DS:Table_Tremolo[BP],Offset Ta_rampe
        JMP Fin_Exec_TremCtrl
Pas_Trem_Rampe:
        CMP AL,2
        JNE Pas_Trem_Carre
        MOV DS:Table_Tremolo[BP],Offset Ta_carre
Pas_Trem_Carre:                      ;4 => Hazard (Garde la meme valeur )

Fin_Exec_TremCtrl:
        RET
Exec_TremCtrl Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Vibrato+Vol Slide   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_vib_vs PROC NEAR
        MOV Param_vs[BX],AL  ; Test to not memorize Vol Slide Param if 0
;        CALL Exec_vol_slide
        MOV Command_ProcOffs,OFFSET Vibrato_vs
        RET
Exec_vib_vs ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Tone port+Vol Slide   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_tone_vs PROC NEAR
        MOV Param_vs[BX],AL  ; Test to not memorize Vol Slide Param if 0
;        CALL  Exec_vol_slide 
		XOR AL,AL
        CALL Exec_Tone_prt
        MOV Command_ProcOffs,OFFSET Tone_vs
        RET

Exec_tone_vs ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     Note Cut     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_NoteCut PROC NEAR
        INC AL
        MOV Cmpt_Commande[BX],AL
        MOV Command_ProcOffs,OFFSET NoteCut
		CALL NoteCut
        RET
Exec_NoteCut ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Note Delay     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_NoteDelay PROC NEAR
        INC AL
        MOV Cmpt_Commande[BX],AL
        MOV Command_ProcOffs,OFFSET NoteDelay

        CMP Start_Sample,1        ;Modifier l'instrument ?
        JNE NDPas_Start_Sample
        MOV AL,Note_Sample
        MOV CH_Smp_Pla[BX],AL
NDPas_Start_Sample:
        CMP Save_Periode,1        ;Modifier la p‚riode ?
        JNE NDPas_Save_Periode
        MOV CX,Note_Periode
;        CALL Ajuster_Periode      ;Ajuster la p‚riode !!!!!            OPT : La periode n est pas correct si le sample n est pas demarre
        MOV CH_Per_part[BP],CX  ;Sauver la valeur de la p‚riode
NDPas_Save_Periode:
        CALL NoteDelay            ;Si Delay=0, lancer tout de suite !!!
        RET
Exec_NoteDelay ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Retrig Note    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_RetrigNote PROC NEAR
        MOV AH,AL
        CMP Type_Module,T_S3M
        JNE Pas_Retrig_S3M      ; Si S3M, relancer le retrig si param 0
        OR AH,AH
        JZ Retrig_Idem
Pas_Retrig_S3M:
        TEST AH,AH
        JZ Pas_Retrig
        MOV AL,AH
        AND AH,0Fh
        MOV Delai_Ret[BX],AH
If ModeXT Eq Yes
        SHR AL,1
		SHR AL,1
        SHR AL,1
		SHR AL,1		
Else
        SHR AL,4
EndIf
        MOV Param_Ret[BX],AL
Retrig_Idem:
        MOV AH,Delai_Ret[BX]    ; Copier Delai Retr dans Cmpt_Commande
        MOV Cmpt_Commande[BX],AH
        MOV Command_ProcOffs,OFFSET RetrigNote
Pas_Retrig:
        RET
Exec_RetrigNote ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    Sample Offset   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

TSmp_Offs DB Max_Channels DUP (0)

Exec_SampleOffs PROC NEAR
        OR AL,AL
        JNZ Pas_Smp_Offs0
        MOV AL,TSmp_Offs[BX]      ; Si ParamŠtre=0, valeur pr‚c‚dente.
Pas_Smp_Offs0:
        MOV TSmp_Offs[BX],AL
        CMP Start_Sample,1
        JNE Suite_Smp_Offs
		
        MOV VSmp_Offset[BX],AL
Suite_Smp_Offs:
        RET

Exec_SampleOffs Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Set BPM       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_SetBPM Proc Near
		MOV BPM_Val,520           ; Value for 125BPM : 65000/125 (If BPM<20)
        CMP AL,20
		JBE Skip_BPM
        PUSH BX
        MOV BPM,AL
		XOR BX,BX
		MOV BL,AL
		XOR DX,DX
		MOV AX,65000
		DIV BX
		MOV BPM_Val,AX
		POP BX
Skip_BPM:		
        RET
Exec_SetBPM Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     Jump Loop      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Debut_Boucle_Pattern DB 0
Cmpt_Boucles         DB 0
Bouclage_en_cours    DB 0
DoJumpLoop           DB 0
Test_Jump_Loop       DB 0

Exec_JumpLoop PROC NEAR
        CMP Test_Jump_Loop,1
        JE Fin_Exec_JumpLoop         ;D‚jto utilis‚ sur la mˆme ligne ?

        MOV Test_Jump_Loop,1
        MOV AH,AL
        OR AH,AH
        JNZ Pas_debut_Bouclage
        MOV AL,C_Row
        MOV Debut_Boucle_Pattern,AL  ;Fixer le d‚but du bouclage
        JMP Fin_Exec_JumpLoop
Pas_debut_Bouclage:
        CMP Bouclage_en_cours,1      ;Bouclage en cours ?
        JNE Lancer_Bouclage
        DEC Cmpt_Boucles             ;Fin du bouclage ?
        JE Stopper_Bouclage
        MOV DoJumpLoop,1        ;Boucler
        JMP Fin_Exec_JumpLoop
Stopper_Bouclage:
        MOV Bouclage_en_cours,0      ;Stopper le bouclage
        JMP Fin_Exec_JumpLoop
Lancer_Bouclage:
        MOV Bouclage_en_cours,1      ;Lancer le bouclage
        MOV Cmpt_Boucles,AH
        MOV DoJumpLoop,1
Fin_Exec_JumpLoop:
        RET
Exec_JumpLoop Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     FineTune       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_FineTune PROC Near
;        MOV AL,Note_Sample         ;du sample
;        XOR AH,AH
;        Pointer_Sample AX
;        MOV AL,C_Param
;        CMP AL,0Fh
;        JAE Fin_Exec_FineTune
;        MOV ES:SFine_Tune[DI],AL
;        MOV VFineTune[BX],AL
;        CALL Set_Period_Fine
;Fin_Exec_FineTune:
        RET
Exec_FineTune Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      Panning       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Exec_Panning Proc Near  ; Panning 0 to 80h
        CMP Utiliser_Panning,1
        JNE EP_Pas_Modif_Panning
;        CMP Sortie_Sonore,SB
;        JNE EP_Ajuster_Panning
        CMP AL,80h
        JA EP_Pas_Modif_Panning
EP_Ajuster_Panning:     
        MOV CH_Panning[BX],AL
        CALL Ajuster_Volumes_Panning
        OR GUS_Controle[BX],M_ChPanning  ;Set the M_ChPanning Bit
EP_Pas_Modif_Panning:
        RET
Exec_Panning Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                      COMMANDES                            ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Cmpt_Commande DB Max_Channels DUP (0)  ;Compteur pour VolFine, FinePorta
                                    ;Retrig, NoteCut, NoteDelay...

Compt_arp DB Max_Channels DUP (0)
Per0_arp  DW Max_Channels DUP (0)
Per1_arp  DW Max_Channels DUP (0)
Per2_arp  DW Max_Channels DUP (0)

Param_EFPort DB Max_Channels DUP (0)  ;XM									  
Param_pr_dn DB Max_Channels DUP (0)
Param_pr_up DB Max_Channels DUP (0)
Param_VS DB Max_Channels DUP (0)

Per_tone_prt   DW Max_Channels DUP (0)
Param_tone_prt DB Max_Channels DUP (0)
dir_tone_prt   DB Max_Channels DUP (0)

Table_Vibrato DW Max_Channels DUP (0)

Retrig_V_Tr   DB Max_Channels DUP (0)    ;0 Retrig 1 Pas de retrig Retrig Temolo, Vibrato and Arpeggio Ctrl

M_Retrig_Vib    Equ 1
M_Retrig_Trem   Equ 2
M_Vib_VibVS_Cmd Equ 4
M_Arpegio       Equ 8  ; Set to 1 if the previous command was an Arpeggio

Vitesse_vib   DB Max_Channels DUP (0)
Amplitude_vib DB Max_Channels DUP (0)
Vibr_Index    DB Max_Channels DUP (0)

Table_Tremolo  DW Max_Channels DUP (0)
Vitesse_Trem   DB Max_Channels DUP (0)
Amplitude_Trem DB Max_Channels DUP (0)
Trem_Index    DB Max_Channels DUP (0)

Param_Tremor   DB Max_Channels DUP (0)
Partie_Tremor  DB Max_Channels DUP (0)

Delai_Ret DB Max_Channels DUP (0)
Param_Ret DB Max_Channels DUP (0)

; Empty Command

Do_Nothing Proc Near
        RET
Do_Nothing Endp		

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     - Arpeggio -       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Do_Arpeggio PROC NEAR

        INC Compt_arp[BX]
        MOV AL,Compt_arp[BX]
        DEC AL
        JNZ arp2
        MOV CX,Per0_arp[BP]
        JMP Fin_arp
arp2:
        DEC AL
        JNZ arp3
        MOV CX,Per1_arp[BP]
        JMP Fin_arp
arp3:
        MOV CX,Per2_arp[BP]
        MOV compt_arp[BX],0
Fin_arp:
;        CALL Ajuster_Periode  ; Periodes Arpeggio pas r‚elles => Ajuster
        CALL Set_Period
        RET
Do_Arpeggio Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  - Portamento Down -   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                 
Port_down Proc Near
        MOV CX,CH_Per_part[BP]
        XOR AH,AH
        MOV AL,Param_pr_dn[BX]
		SHL AX,1              ; Param*4
		SHL AX,1
        ADD CX,AX
;        CMP CX,Max_Period ;_Act
;        JB Port_dn_inf
;        MOV CX,Max_Period ;_Act                ;P‚riode au maximum
;Port_dn_inf:

        MOV CH_Per_part[BP],CX
        CALL Set_Period
        RET
Port_down Endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   - Portamento Up -    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Port_up Proc Near
        MOV CX,CH_Per_part[BP]
        XOR AH,AH
        MOV AL,Param_pr_up[BX]
		SHL AX,1                ; Param*4
		SHL AX,1
        SUB CX,AX
        CMP CX,Min_Period
        JGE Pru_Periode_correcte          ; Period Greater than the Min (Signed)

;Writechar 'C'
        CMP Type_Module,T_S3M             ;S3M => Cut the sample if the note is too high
        JNE Pas_Couper_PrtUp              ;(ST3 Bug 8-)
        OR Ch_Control[BX],CM_Stopped+CM_KeyOff ;Disable the channel

Pas_Couper_PrtUp:
        MOV CX,Min_Period ;_Act           ; Minimum Period
Pru_Periode_correcte:

        MOV CH_Per_part[BP],CX
        CALL Set_Period
        RET
Port_up ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ - Fine Portamento Up - ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Fine_Portamento_Up PROC NEAR
        CMP Cmpt_Commande[BX],0
        JNE Pas_exec_Port_Up
        CALL Port_up
        MOV Cmpt_Commande[BX],1
Pas_exec_Port_Up:
        RET
Fine_Portamento_Up ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ - Fine Portamento Down - ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Fine_Portamento_Down PROC NEAR
        CMP Cmpt_Commande[BX],0
        JNE Pas_exec_Port_Down
        CALL Port_Down
        MOV Cmpt_Commande[BX],1
Pas_exec_Port_Down:
        RET
Fine_Portamento_Down ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    - Volume Slide -    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Volume_slide PROC NEAR
        MOV AL,Param_VS[BX]
VolSlide_Direct:
        OR AL,AL                  ; AL=0?
        JE Fin_volume_slide
        MOV DL,AL
        AND DL,0Fh                ; DL <- 2ø partie
        OR DL,DL                  ; Volume Slide Down ???
        JZ Vol_sl_add
        MOV CL,VVolume_Part[BX]   ; Volume Slide Down ...
        SUB CL,DL
        CMP CL,40h
        JB Fin_vs
        XOR CL,CL
        JMP Fin_vs
Vol_sl_add:                       ; Volume Slide Up ...
If ModeXT Eq Yes
        SHR AL,1
		SHR AL,1
        SHR AL,1
		SHR AL,1		
Else
        SHR AL,4
EndIf                
        MOV CL,VVolume_Part[BX]
        ADD CL,AL
        CMP CL,40h
        JBE Fin_vs
        MOV CL,40h
;        JMP Fin_vs
Fin_vs:
        MOV AL,CL
        MOV VVolume_Part[BX],AL
        CALL Set_Ch_Volume
Fin_volume_slide:
        RET
Volume_slide ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  - Volume fine (Up et Down) -   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Volume_fine PROC NEAR
        CMP Cmpt_Commande[BX],0
        JNE Pas_exec_VolFine
        CALL VOLUME_Slide
        MOV Cmpt_Commande[BX],1
Pas_exec_VolFine:
        RET
Volume_fine ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  - Tone Portamento -   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Tone_portamento PROC NEAR
        MOV DX,Per_tone_prt[BP]
;        CALL Ajuster_Periode
;        MOV DX,CX                      ;DX=P‚riode de fin.

        MOV CX,CH_Per_part[BP]       ;CX=P‚riode actuelle

        XOR AH,AH
        MOV AL,Param_tone_prt[BX]
        OR AL,AL
        JNZ Cont_t_pr
        MOV CX,DX
        JMP Fin_t_pr
Cont_t_pr:
        SHL AX,1              ; Param*4
		SHL AX,1
        CMP dir_tone_prt[BX],0
        JZ t_pr_monte
        SUB CX,AX
        CMP CX,DX
        JA Test_si_Grand
        MOV CX,DX
        JMP Fin_t_pr
Test_si_grand:
        MOV AX,CX
        SUB AX,Min_Period  ; _Act
        CMP AX,Moyen_notes ; _Act
        JB Fin_t_pr
        MOV CX,DX
        JMP Fin_t_pr
t_pr_monte:
        ADD CX,AX
        CMP CX,DX
        JB Fin_t_pr
        MOV CX,DX
Fin_t_pr:
        MOV CH_Per_part[BP],CX      ; Periode dans CX
        CALL Set_Period
        RET
Tone_portamento ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      - Vibrato -       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Vibrato PROC NEAR                     ;Ne pas changer CH_Per_part !!!
         CMP Vibr_Index[BX],63
         JB Pas_per_vib
         SUB Vibr_Index[BX],64
Pas_per_vib:
         MOV SI,DS:Table_Vibrato[BP]
         MOV CL,Vibr_Index[BX]
         XOR CH,CH
         ADD SI,CX
         MOV AL,[SI]
         MUL Amplitude_vib[BX]
If ModeXT Eq Yes
         MOV CL,5         ; SHR 5 instead of 7
		 SHR AX,CL
Else
         SHR AX,5
EndIf 		 
         MOV CX,DS:CH_Per_part[BP]
         CMP Vibr_Index[BX],32
         JNA Pas_neg_v
         SUB CX,AX
         JMP Fin_vib
Pas_neg_v:
         ADD CX,AX
Fin_vib:
         MOV AL,Vitesse_vib[BX]
         ADD Vibr_Index[BX],AL

         CALL Set_Period
         RET
Vibrato ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      - Tremolo -       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Tremolo PROC NEAR
         CMP Trem_Index[BX],63
         JB Pas_per_Trem
         SUB Trem_Index[BX],64
Pas_per_Trem:
         MOV SI,Table_Tremolo[BP]         ;Table du tremolo (sinus,rampe,carr‚)
         MOV CL,Trem_Index[BX]
         XOR CH,CH
         ADD SI,CX
         MOV AL,[SI]
         MUL Byte Ptr Amplitude_Trem[BX]  ;Valeur dans AH   (Amplitude*Sin(...))
If ModeXT eq Yes         ;Amplitude*4
		 SHL AX,1
		 SHL AX,1
Else
         SHL AX,2
EndIf 
         MOV CL,VVolume_Part[BX]
         CMP Trem_Index[BX],32
         JNA Pas_neg_Trem
         SUB CL,AH        ;Modifier le volume
         CMP CL,40h
         JBE Fin_Trem     ;Volume <0 ???
         XOR CL,CL
         JMP Fin_Trem
Pas_neg_Trem:
         ADD CL,AH
         CMP CL,40h
         JBE Fin_Trem
         MOV CL,40h
Fin_Trem:
         MOV AL,vitesse_Trem[BX]
         ADD Trem_Index[BX],AL
                               ;***  Modifier le volume ***
         MOV AL,CL                  ;Volume dans CL
         CALL Set_Ch_Volume
         RET
Tremolo ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³      - Tremor -        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Tremor PROC NEAR

         INC Cmpt_Commande[BX]
         MOV AL,Param_Tremor[BX]
         CMP Partie_Tremor[BX],0
         JNE Partie_Off
If ModeXT eq Yes
		 SHR AL,1
		 SHR AL,1
         SHR AL,1		 
		 SHR AL,1
Else
         SHR AL,4
EndIf		 
         CMP AL,Cmpt_Commande[BX]
         JA  Fin_Tremor
         XOR AL,AL                   ;Couper le volume.
         CALL Set_Ch_Volume
         MOV Partie_Tremor[BX],1
         MOV Cmpt_Commande[BX],0
         JMP Fin_Tremor
Partie_Off:
         AND AL,0Fh
         CMP AL,Cmpt_Commande[BX]
         JA  Fin_Tremor
         MOV AL,VVolume_Part[BX]    ;Remettre le volume normal.
         CALL Set_Ch_Volume
         MOV Partie_Tremor[BX],0
         MOV Cmpt_Commande[BX],0
Fin_Tremor:
         RET
Tremor ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ - Vibrato+Vol Slide -  ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Vibrato_vs PROC NEAR
        CALL Vibrato
        JMP Volume_slide
Vibrato_vs ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³- Tone port+Vol Slide - ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Tone_vs PROC NEAR
        CALL Tone_portamento
        JMP Volume_slide
Tone_vs ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³     - Note Cut -     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

NoteCut:
        DEC Cmpt_Commande[BX]
        JNZ Fin_NC
		
        XOR AL,AL                       ;Volume 0 => Stop the Sound
        MOV VVolume_Part[BX],AL
        CALL Set_Ch_Volume

        MOV CH_Command[BP],Offset Do_Nothing  ;Stop the Note Cut Execution
Fin_NC:
        RET

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³    - Note Delay -    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

NoteDelay PROC NEAR
		
        DEC Cmpt_Commande[BX]
        JNZ Fin_ND

; Start the Note
        MOV AL,VVolume_Part[BX]
        CALL Set_Ch_Volume       ;Changer le volume
        MOV CX,CH_Per_part[BP]
        CALL Set_Period      ;Changer la p‚riode de la voie
        MOV AL,CH_Smp_Pla[BX]
        MOV Note_Sample,AL
        MOV VSmp_Offset[BX],0
        CALL DoStart_Sample       ;Changer le sample

        MOV CH_Command[BP],Offset Do_Nothing  ; Stop the Note Delay Execution

Fin_ND:
        RET
NoteDelay ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   - Retrig Note -    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;FTRetrigNote PROC NEAR
;
;        RET
;FTRetrigNote ENDP

RetrigNote PROC NEAR
        DEC Cmpt_Commande[BX]
        JZ Couper_Ret
        JMP Fin_Ret

Couper_Ret:
        MOV AL,CH_Smp_Pla[BX]
        MOV Note_Sample,AL
        MOV VSmp_Offset[BX],0
        CALL DoStart_Sample
		
        MOV AL,Delai_Ret[BX]
        MOV Cmpt_Commande[BX],AL

        MOV CL,Param_Ret[BX]
        OR CL,CL
        JNZ Cont_Ret
		JMP Fin_Ret
Cont_Ret:

        MOV AL,VVolume_Part[BX]
        CMP CL,8
        JAE R_Augmenter_Vol
                               ;Diminuer le volume
        MOV CH,1
        CMP CL,1               ; 1 => Volume=Volume-1
        JE Decrementer_Volume
        MOV CH,2
        CMP CL,2               ; 2 => Volume=Volume-2
        JE Decrementer_Volume
        MOV CH,4
        CMP CL,3               ; 3 => Volume=Volume-4
        JE Decrementer_Volume
        MOV CH,8
        CMP CL,4               ; 4 => Volume=Volume-8
        JE Decrementer_Volume
        MOV CH,16
        CMP CL,5               ; 5 => Volume=Volume-16
        JE Decrementer_Volume
        CMP CL,7
        JNE Diviser_Volume
        XOR AH,AH              ; 7 => Volume=Volume*2/3
        SHL AX,1               ; Vol*2
        MOV CH,3
        DIV CH                 ; Vol/3 => Vol*2/3
        JMP Fin_Diminuer_Vol
Diviser_Volume:                ; 6 => Volume=Volume/2
        SHR AL,1
        JMP Fin_Diminuer_vol
Decrementer_Volume:
        SUB AL,CL
Fin_Diminuer_vol:
        CMP AL,40h
        JBE Fin_R_Modif_Vol
        XOR AL,AL
        JMP Fin_R_Modif_Vol

R_Augmenter_Vol:               ;Augmenter le volume

        MOV CH,1
        CMP CL,9               ; 9 => Volume=Volume+1
        JE Incrementer_Volume
        MOV CH,2
        CMP CL,0Ah             ; A => Volume=Volume+2
        JE Incrementer_Volume
        MOV CH,4
        CMP CL,0Bh             ; B => Volume=Volume+4
        JE Incrementer_Volume
        MOV CH,8
        CMP CL,0Ch             ; C => Volume=Volume+8
        JE Incrementer_Volume
        MOV CH,16
        CMP CL,0Dh             ; D => Volume=Volume+16
        JE Incrementer_Volume
        CMP CL,0Eh
        JNE Doubler_Volume
        MOV AH,AL              ; F => Volume=Volume*3/2
        SHL AL,1
        ADD AL,AH
        SHR AL,1
        JMP Fin_Augmente_Vol

Doubler_Volume:                ; E => Volume=Volume*2
        SHL AL,1
        JMP Fin_Augmente_vol
Incrementer_Volume:
        ADD AL,CL
Fin_Augmente_vol:
        CMP AL,40h
        JBE Fin_R_Modif_Vol
        MOV AL,40h
Fin_R_Modif_Vol:
        MOV VVolume_Part[BX],AL
        CALL Set_Ch_Volume  ;Modifier le volume (il est dans AL)

Fin_Ret:
        RET
RetrigNote ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   PInit_Tables  Fournir les pointeurs au Pascal          ³
;³   Change:      ES,DI                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

PInit_Tables PROC FAR
      PUSH BP
      MOV BP,SP

      LES DI,DWORD PTR SS:[BP+6]
	  
	  MOV AX,DS
      MOV CS:DS_TurboPascal,AX

      CLD

	  MOV AX,OFFSET TPTable
	  STOSW
	  MOV AX,CS
	  STOSW
	  MOV AX,OFFSET TPVariables
      STOSW
	  MOV AX,CS
	  STOSW	  
      MOV AX,OFFSET TPInfo
      STOSW
	  MOV AX,CS
	  STOSW
      MOV AX,OFFSET TPMusique
      STOSW
      MOV AX,CS
	  STOSW
	  
      POP BP
      RET 4
PInit_Tables ENDP

INCLUDE MIXAGE.ASM

If UseOPL2 eq Yes
INCLUDE ADLIB.ASM           ;Commandes Adlib
 If UseRAD Eq Yes
 INCLUDE RADPLAY.ASM         ;RAD Files Player
 endIf
INCLUDE IMFDROP.ASM 
EndIf

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                      AFFICHAGES                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If Mod_Master eq yes
 INCLUDE MODMUTIL.ASM        ;Calcul duree...
 INCLUDE MODMAFF.ASM         ;Display
EndIf

CODE ENDS
END

