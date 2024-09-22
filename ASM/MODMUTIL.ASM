;            ���������������������������������������������������ͻ
;            �           --==�� Mod Master v2.2 ��==--           �
;            ���������������������������������������������������ĺ
;            �   Auteur������������������������ Freddy V�tel�    �
;            �   Avec l'aide de���������������� Fabrice Couteau  �
;            �                                                   �
;            �   Derni�re modification��������� 24/10/1995       �
;            �    03/04/2019 : Remove Keyboard IRQ               �
;            ���������������������������������������������������ͼ

;scan-codes des touches utilis�es et action associ�e

scanF1 EQU 59           ;affiche/efface page d'aide
scanF2 EQU 60           ;liste instruments <-> partition
scanF3 EQU 61
scanF4 EQU 62
scanF5 EQU 63
scanF6 EQU 64           ;Debug
scanUp    EQU 72        ;Affichage des voies <-
scanDown  EQU 80        ;Affichage des voies ->
scan1 EQU 2             ;active/d�sactive voie 1
scan2 EQU 3             ;active/d�sactive voie 2
scan3 EQU 4             ;active/d�sactive voie 3
scan4 EQU 5             ;active/d�sactive voie 4
scan5 EQU 6             ;active/d�sactive voie 5
scan6 EQU 7             ;active/d�sactive voie 6
scan7 EQU 8             ;active/d�sactive voie 7
scan8 EQU 9             ;active/d�sactive voie 8
scan9 EQU 0Ah
scan0 Equ 0Bh

scanAQ EQU 16           ;decremente couleur barre pitch
scanZW EQU 17           ;incremente couleur barre pitch
scanQA EQU 30           ;decremente couleur bout barre pitch 
scanS EQU 31            ;incremente couleur bout barre pitch
ScanD EQU 32            ;lance le DOS Shell
scanW EQU 44            
scanX EQU 45            
scanO EQU 24            ;d�cr�mente caractere barre periode
scanP EQU 25            ;incr�mente caractere barre periode
scanL EQU 38            ;decremente couleur barre periode
scanM EQU 39            ;incremente couleur barre periode
scanR EQU 19            ;active/d�sactive fonction Repeat
scanI EQU 23            ;Disable IntroScan
scanTab    EQU 15       ;mode texte <-> mode graphique
scanEspace EQU 57       ;active/desactive Pause
scanPlus   EQU 78       ;augmente le volume relatif
scanMoins  EQU 74       ;diminue le volume relatif
scanLeft   EQU 75       ;retour rapide
scanRight  EQU 77       ;avance rapide
scanPgUp   EQU 73       ;Module precedent dans un programme
scanPgDn   EQU 81       ;Module suivant dans un programme
scanEsc    EQU 1        ;abandonne la lecture


Afficher_fin_voies DB 0


Gerer_Touches PROC NEAR

; Read the Key Pressed OK, Working on PC1640
	  
       MOV ah,01h ; checks if a key is pressed
;	   MOV ah,11h
       INT 16h
       JNZ Read_Key
       DS_TP
       MOV Key_ScanCode,0        ; Save 0 for No Key
       DS_ASM
       RET ; zero = no key pressed
Read_Key:	   
       MOV ah,00h ; read the Key Code
       INT 16h	  
       XCHG AL,AH

       DS_TP
       MOV Key_ScanCode,AL         ; Save the Scan Code for the Pascal

       CMP TP_Fading,1             ; No Key read if fading, except "Escape"
       DS_ASM
       JNE Continuer_clavier
       JMP Test_Esc
Go_Keyboard_End:
       RET
	   
Continuer_clavier:

       CMP AL,scanF1
       JNE test_F2
If CGAOnly Eq No
       DS_TP
       CMP Mode_actuel,Mode_Texte
       JE change_aff_page_aide_texte
       MOV Changer_affichage,1          ; mode graphique -> passe en mode
       MOV Mode_a_afficher,Mode_Texte   ; texte et affiche la page d'aide
       JMP SHORT active_page_aide
change_aff_page_aide_texte:
EndIf
       DS_TP
       MOV AL,Center_Display
       CMP AL,2                        ; Help already displayed ?
       JNE active_page_aide
       MOV AL,CS:ancien_aff_centre
       MOV Center_Display,AL           ; Go to the previous screen
       JMP SHORT fin_F1
active_page_aide:
       MOV AL,Center_Display
       MOV CS:ancien_aff_centre,AL	   
       MOV Center_Display,CD_Help     ; 2 Help
fin_F1:                       
       MOV Change_aff_centre,1
       RET

Test_F2: ; F2 Sample List
       CMP AL,scanF2
       JNE test_F3
       CMP MUS_OPLStream,1           ; IMF, RAW, DRO, VGM
       JE Test_F3
	   
       DS_TP
       MOV Change_aff_centre,1
       MOV Center_Display,CD_Samples ; 0 Samples
       RET

Test_F3:
       CMP AL,scanF3
       JNE test_Monotone_File
       CMP Type_Module,T_RAD   ; No partition for RAD and IMF
       JE Test_Monotone_File
       CMP MUS_OPLStream,1     ; IMF, RAW, DRO
       JE Test_Monotone_File  
	   
       DS_TP
       CMP Center_Display,CD_Part
       JNE Change_Display_F3 ; Change the Display /Clean screen only one time
       RET
Change_Display_F3:	   
       MOV Change_aff_centre,1
       MOV Center_Display,CD_Part ; 1 Partition
       RET

Test_Monotone_File:              ;Monotone file -> No more test Keys
	   
;	   CMP Type_Module,T_MON
;	   JNE Continue_NotMON
;	   RET 
;Continue_NotMON:
	   	   
       CMP AL,scanEspace        ;Espace =>Pause
       JNE No_pause
       XOR MMSS_Pause,1
       JZ MMSS_Stop_Pause
       JMP SHORT Enable_Pause

MMSS_Stop_Pause:
       DS_ASM
       CALL Stop_Pause
       RET

Enable_Pause:
       CALL Affiche_Fonctions
       CALL MMSS_Start_Pause
       RET

No_Pause:
       CMP MMSS_Pause,1
       JNE test_Tab
       RET                ;Interdit toutes les touches si PAUSE

test_Tab:
       DS_ASM
If CGAOnly Eq No
       CMP AL,scanTab
       JMP test_PgUp
       DS_TP
       CMP Changer_affichage,1          ;Mode pas encore chang� => ne pas le
       DS_ASM                           ;changer.
       JE Suite_test_Tab
       DS_TP
       MOV Changer_affichage,1
       XOR Mode_a_afficher,1            ;Texte <-> Graphique
       DS_ASM
Suite_test_Tab:
       RET
EndIf
test_PgUp:
       CMP AL,scanPgUp
       JNE test_PgDn
       DS_TP
       MOV AH,Programme
       DS_ASM
       CMP AH,1
       JNE fin_PgUp
       DS_TP
       MOV AX,Numero_Module
       DS_ASM
       CMP AX,1
       JBE fin_PgUp
       MOV Touche_fin,Tfin_PgUp
       MOV Musique_Terminee,1  ;Stopper la musique
       MOV Stop_Output,1    ;Stopper la sortie sonore
fin_PgUp:
       RET

test_PgDn:                              ; PgDn
       CMP AL,scanPgDn
       JNE test_F4
       DS_TP
       MOV AH,Programme
       DS_ASM
       CMP AH,1
       JNE fin_PgDn
       DS_TP
       MOV CX,Numero_Module
       MOV AX,Longueur_prog
       DS_ASM
       CMP CX,AX                        ; Fin du programme ?
       JAE fin_PgDn
       MOV Touche_fin,Tfin_PgDn
       MOV Musique_Terminee,1  ;Stopper la musique
       MOV Stop_Output,1    ;Stopper la sortie sonore
fin_PgDn:
       RET

test_F4:                              ; F4
       CMP AL,scanF4
       JNE test_F5
	DS_TP
       MOV Change_aff_centre,1
       CMP Center_Display,4
	JNE Don_Swap_SubDisplayF4
	DS_ASM
   	XOR Display_NoteOrBar,1        ; Swap Display
	RET
	   
Don_Swap_SubDisplayF4:	   
       MOV Center_Display,4           ; 4 Multiple Channels
       RET

test_F5:                              ; F5
       CMP AL,scanF5
       JNE test_F6
       XOR Utiliser_Interpol,1
       CALL Affiche_Fonctions
       RET

test_F6:                              ; F6 : Debug
       CMP AL,scanF6
       JNE test_Up
       DS_TP
       MOV Change_aff_centre,1
       MOV Center_Display,3
       RET
	   
test_Up:              ; Channel -
       CMP AL,scanUp
       JNE test_Down
       MOV AH,N_voie_aff
       CMP AH,0
       JE Test_Plus
       DEC N_voie_aff
       DS_TP
       MOV Change_aff_centre,1
       RET
	   
test_Down:
       CMP AL,scanDown        ; Channel +
       JNE test_Plus
       MOV BL,Ch_Number
       SUB BL,N_voie_aff
       CMP BL,4
       JBE Test_Plus
       INC N_voie_aff
       DS_TP
       MOV Change_aff_centre,1
       DS_ASM
       RET

Test_Plus:
       CMP AL,scanPlus
       JNE test_Moins
       CMP Volume_Total,40h-4
       JBE VT_Not40h
	   MOV Volume_Total,40h-4
VT_Not40h:	   
       ADD Volume_Total,4
       CALL MMSS_Volume_UpdateAll
Suite_Plus:
       RET

Test_Moins:
       CMP AL,scanMoins
       JNE test_1
       CMP Volume_Total,4
       JAE VT_NotZero
	   MOV Volume_Total,4
VT_NotZero:	   
       SUB Volume_Total,4
       CALL MMSS_Volume_UpdateAll
Suite_Moins:
       RET

Test_1:
	MOV AH,AL             
	SUB AH,Scan1                   ; Test the '1' to '0' Keys
	CMP AH,9
	JA test_Right
       XOR BX,BX
	MOV BL,AH
       XOR Ch_Control[BX],CM_Disabled ; Reverse the Disabled bit
       JZ Stop_Channel_End            ; If channel enabled, Skip Disable

       OR Ch_Control[BX],CM_KeyOff+CM_NoteCut ; Enable Key Off (For Adlib / GUS)

; Tandy
       TEST OtherMUS_Out,M_SN76489
       JZ  Stop_Channel_End
       CALL TDY_Mute_Channel

Stop_Channel_End:
       RET
	   
Test_Right:
       CMP AL,scanRight
       JNE test_Left
	ADD Tick_Count,100 ; Test Fast Forward
       CMP Duree_intro,0
       JNZ Cont_droite
       MOV AL,Sequence_Len
       CMP C_Sequence,AL
       JB cont_cl_droite
cont_droite:
       RET
cont_cl_droite:
       MOV Cmpt_Tempo,1
       MOV Cmd_ModifyPattern,1
       INC C_Sequence        ; Incrementer la position
       RET

test_Left:
       CMP AL,scanLeft
       JNE test_D
       CMP Duree_intro,0
       JNZ cont_droite

       CMP C_Sequence,1
       JE  Pas_dec_pos
       DEC C_Sequence        ; D�cr�menter la position
Pas_dec_pos:
       MOV Cmpt_Tempo,1
       MOV Cmd_ModifyPattern,1
       RET

test_D:
       CMP AL,ScanD
       JNE test_A
       DS_TP
       MOV Activer_Shell,1
       RET

test_A:
       CMP AL,scanAQ
       JNE test_ZW
       DS_TP
       DEC coul_barre_pitch
       JNZ suite_AQ
       MOV coul_barre_pitch,15
suite_AQ:
       RET

test_ZW:
       CMP AL,scanZW
       JNE test_QA
       DS_TP
       INC coul_barre_pitch
       CMP coul_barre_pitch,15
       JBE suite_Z
       MOV coul_barre_pitch,1
suite_Z:
       RET

test_QA:
       CMP AL,scanQA
       JNE test_S
       DS_TP
       DEC coul_bout_pitch
       JNZ suite_Q
       MOV coul_bout_pitch,15
suite_Q:	   
       RET
test_S:
       CMP AL,scanS
       JNE test_O
       DS_TP
       INC coul_bout_pitch
       CMP coul_bout_pitch,15
       JBE suite_S
       MOV coul_bout_pitch,1
suite_S:
       RET

test_O:
       CMP AL,scanO
       JNE test_P
       DS_TP
       INC coul_barre_periode
       CMP coul_barre_periode,15
       JBE suite_O
       MOV coul_barre_periode,1
suite_O:
       RET

test_P:
       CMP AL,scanP
       JNE test_R
       DS_TP
       DEC coul_barre_periode
       JNZ suite_P
       MOV coul_barre_periode,15
suite_P:
       RET

test_R:
       CMP AL,scanR
       JNE test_I
       DS_TP
       CMP Boucler_MOD,0            ;fonction Repeat active? (Boucler=1 ou 2)
       MOV Boucler_MOD,1            ;active Repeat
       JZ suite_R                   ;non
       MOV Boucler_MOD,0            ;d�sactive Repeat
suite_R:
       DS_ASM
       CALL Affiche_Fonctions
       JMP SHORT Keyboard_End

test_I:
       CMP AL,scanI
       JNE test_Esc
       MOV Duree_intro,0            ;Disable IntroScan (continue � jouer
                                    ;le module courant dans le programme)
       CALL Affiche_Fonctions
       JMP SHORT Keyboard_End

test_Esc:
       CMP AL,scanEsc
       JNE Keyboard_End

       CMP Type_Module,T_RAD   ; Directly stop if RAD / IMF
       JE Arret_brutal
       CMP MUS_OPLStream,1     ; IMF, RAW, DRO
       JE Arret_brutal	   
	   
       DS_TP
       CMP TP_Fading,1
       DS_ASM
       JE Arret_brutal
       MOV Touche_fin,Tfin_Esc
       DS_TP
       MOV TP_Fading,1
       DS_ASM

       MOV AL,Volume_Total
       MOV Volume_Saved,AL

       JMP SHORT Keyboard_End
Arret_brutal:

       MOV Stop_Output,1

Keyboard_End:
       DS_ASM
       RET

Gerer_Touches ENDP