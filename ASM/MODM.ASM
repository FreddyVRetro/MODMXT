;��������������������������������������������������ͻ
;�                    MODM.ASM       V1.0           �
;�                                                  �
;�                   MOD MASTER                     �
;�                                                  �
;�   Auteur:                Freddy V�tel�           �
;�                                                  �
;�   D�but d'�criture:        3/5/1993              �
;�   Derni�re Modification:   1/1/1994              �
;�                                                  �
;�   Output SB Value before the Mixing              �
;    Changed how the player is stopped              
;�                                                  �
;�   A Compiler en fichier .COM (TLINK /t)          �
;��������������������������������������������������ͼ

TAB    equ 9
LF     equ 10
CR     equ 13

b Equ Byte Ptr
w Equ Word Ptr
d Equ DWord Ptr	  
	  
WAITSBlaster macro
       LOCAL WaitSBLoop
WaitSBLoop:
       MOV dx,22Ch
       IN al,dx
       OR al,al
       JS WaitSBLoop
	   endm

WRITE MACRO x         ;Macro ?criture
      MOV AL,x        ;      ! Change AX
      MOV AH,0Eh
      INT 10h
ENDM

WRITEL macro x              ;Macro ?criture de chaine
       MOV dx,offset x      ;x, chaine
       MOV ah,9
       INT 21h
       endm	   
	   
; r : Relative (From memory)
; i : Immediate

MOV_BX_i   macro
           LOCAL OpMOV_BX_i
OpMOV_BX_i db 0B8h  ; MOV AX,xxx   
           endm			

MOV_BX_i   macro
OpMOV_BX_i db 0BBh  ; MOV BX,xxx   
           endm	

MOV_CX_i   macro
OpMOV_CX_i db 0B9h  ; MOV CX,xxx   
           endm	
		   
MOV_DX_i   macro
           LOCAL OpMOV_DX_i
OpMOV_DX_i db 0BAh  ; MOV DX,xxx   
           endm	
	   
MOV_AX_r   macro    ; MOV AX,[xxx] 
OpMOV_AX_r db 0A1h
           endm

MOV_BX_r   macro    ; MOV BX,[xxx] 
OpMOV_BX_r db 08Bh,01Eh
           endm

MOV_CX_r   macro    ; MOV CX,[xxx] 
OpMOV_CX_r db 08Bh,00Eh
           endm		  

MOV_DX_r   macro    ; MOV DX,[xxx] 
OpMOV_DX_r db 08Bh,016h
           endm

MOV_DS_r   macro    ; MOV DS,[xxx] 
OpMOV_DS_r db 08Bh,006h
           endm	
		   
MOV_ES_r   macro    ; MOV ES,[xxx] 
OpMOV_ES_r db 08Bh,006h
           endm		   
	   

		   
;%define MOV_AX_xw {b 0xa1}
	   
CODE SEGMENT

     ORG 100h
     ASSUME CS:code,ds:code,es:code,ss:code

Start:

     JMP init      ;Contourne les variables
                   ;et lib�re la m�moire inutilis�e
				   
XOR W [SI],AX
XOR W [SI+1],AX
XOR W [SI+2],AX
XOR W [SI+3],AX

        MOV AX,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DH,DL
		ADD CX,DX
        ADC SI,BP
        MOV BL,[SI]
        ADD AH,ES:[BX]
        STOSW
        ADD DH,DL
        ADC SI,BP		
      
        MOV AL,ES:[SI]
        XLAT
        ADD [DI],AL
        INC DI
        ADD CH,CL
        ADC SI,BP
		
           
mov bl,ES:[si+1234h]
mov al,[bx]
mov bl,ES:[si+1234h]
mov ah,[bx]
add [di+12h],ax
		
		
;��������������������������������������������������������������ͻ
;�                  Variables Principales                       �
;��������������������������������������������������������������ͼ

db 0        ;???????????

debutfich dw 0              ;Segment du d�but de Fichier
titre db '                    ',0
mk db 0
Nb_pos dw 1D6h              ;Valeurs Pour fichiers non mk
Restart dw 1D7h
Liste_patt dw 1D8h
Part dw 258h
Nb_patt db 0
Nb_samp db 0
nb_reel_samp db 0
Pos_de_restart db 0
Type_de_module db 0
Ecran_noir db 0
erreur_param db 0
Adresse_video dw 0
Adresse_video_def dw 0


Sblastermsg db 'Carte Sound blaster initialis�e',10,13,'$'
Pas_sbmsg db 'Sortie sur le beeper',10,13,'$'
SB_Pres db 0
Utilise_sb db 0

Fin_msg db '  Cette version de Mod Master est FREEWARE',10,13
        db '  Vous pouvez copier et distribuer Mod Master librement, sans le modifier.',10,13
        db '  (Le fichier de documentation doit accompagner MODM.EXE).',10,10,13,'$'
        db '  Pour vos dons ou suggestions, mon Adresse:',10,13
        db '  La Pohu�re 49530 Bouzill� (FRANCE)',10,13,'$'
		
		
Pausemsg DB '-PAUSE-',0
Selection_gauche db 0
Selection_droite db 0
Selection_Centre db 0
Pause db 0
Stop_V1 db 0
Stop_V2 db 0
Stop_V3 db 0
Stop_V4 db 0

Anc_vol_V1 db 0
Anc_vol_V2 db 0
Anc_vol_V3 db 0
Anc_vol_V4 db 0		
		
;******************************************************************
;*                       Debut du programme                       *
;******************************************************************

debut PROC NEAR

      MOV Ecran_noir,0
      MOV Adresse_video,0B800h
      CALL traiter_param
      CMP erreur_param,0
      JE Pas_errp
      JMP fin_prog
Pas_errp:
      CMP Adresse_video_def,0B000h
      JNE Affichage_couleur
      MOV Adresse_video,0B000h
Affichage_couleur:
      CMP ecran_noir,1
      JE Tester_sb
      CALL Intro                ; Display the Top screen bar
	  
Tester_sb:
      MOV Utilise_sb,0
      CALL init_sb
      JNC SB_Presente
      CMP ecran_noir,1
      JE Pas_sb
      WRITEL Pas_sbmsg
      JMP Pas_sb
SB_presente:
      CMP ecran_noir,1
      JE SB_ActivateSP
      WRITEL sblastermsg
SB_ActivateSP:
      
	  WAITSBlaster
	  MOV al,0D1h   ; Turn On SB Speaker
      OUT dx,al
	  WAITSBlaster
	  
      MOV SB_Pres,1
      MOV Utilise_sb,1
Pas_sb:
      CALL charge_module        ;Charge le fichier
      JNC Pas_errf
      JMP fin_prog
Pas_errf:
      CALL Play
	  
      CMP ecran_noir,1
      JE Fin_prog
      CALL Init_ecran
      CALL Intro
      Writel Fin_msg
Fin_Prog:
      CALL Curseur_on

      MOV ah,04Ch
      MOV al,00h          ;Code fin 00
      INT 21h

debut endp

Intro proc near
      CALL Init_ecran
      CALL Curseur_off
      MOV ax,1Fh
      CALL Efface_ligne
      WRITEL debut_msg        ;Message de d�but
      RET
Intro endp

;�����������������������������������������������������������Ŀ
;�   Play          Lancer la musique                         �
;�     Entr�e  Rien                                          �
;�     Sortie  Rien                                          �
;�     Change                                                �
;�������������������������������������������������������������

Boucler db 0
nb_de_boucles db 0
Frequence_def dw 0
Touche DW 0

Play Proc near
      CALL Prepare_play

      CALL Joue_musique
      PUSH CS
      POP DS

      MOV ax,Adresse_video
      MOV ES,ax
      
boucle_Affichage:

      CMP Ecran_noir,1
	  JE Pas_de_barres
      CALL affiche_barres
Pas_de_barres:
	  

Read_Key:                        ; Read the Key Pressed OK, Working on PC1640
	  
      mov ah,01h ; checks if a key is pressed
      int 16h
      jz No_Key_Pressed ; zero = no pressed
      mov ah,00h ; read the Key Code
      int 16h	  
      MOV Touche,ax
      Jmp Key_Pressed
No_Key_Pressed:
      XOR AX,AX
Key_Pressed:

;JMP cl_pas_gauche

       CMP ah,39h
       JNE Pas_Pause
       CMP Pause,0
       JE Activer_Pause
Desact_pause:
       MOV Pause,0
       CALL Init_timer
       PUSH SI
       PUSH DI
       PUSH ES
       MOV ax,Adresse_video
       MOV ES,ax
       MOV ah,0
       MOV SI,offset Pausemsg
       MOV DI,2*36+160*24
       CALL Writelxy
       POP ES
       POP DI
       POP SI
       JMP Key_Check_End
Activer_Pause:
       PUSH SI
       PUSH DI
       PUSH ES
       MOV ax,Adresse_video
       MOV ES,ax
       MOV ah,8Ah
       MOV SI,offset Pausemsg
       MOV DI,2*36+160*24
       CALL Writelxy
       POP ES
       POP DI
       POP SI
       MOV Pause,1
       CALL Restore_timer
	   JMP Key_Check_End
Pas_Pause:

       CMP ah,3Bh
       JNE cl_Pas_F1
       CMP Selection_gauche,1
       JE cl_gauche_pitch
       MOV Change_aff_gauche,1
       MOV aff_gauche,offset Barre_volume
       MOV Selection_gauche,1
       JMP Key_Check_End
cl_gauche_pitch:
       MOV Change_aff_gauche,1
       MOV aff_gauche,offset Barre_pitch
       MOV Selection_gauche,0
	   JMP Key_Check_End
cl_Pas_F1:

       CMP ah,3Ch
       JNE cl_Pas_F2
       CMP Selection_droite,0
       JE cl_droite_eff_per
       MOV Change_aff_droite,1
       MOV aff_droite,offset Barre_periode
       MOV Selection_droite,0
       JMP Key_Check_End
cl_droite_eff_per:
       MOV Change_aff_droite,1
       MOV aff_droite,offset Rien_droite
       MOV Selection_droite,1
	   JMP Key_Check_End
cl_Pas_F2:

       CMP ah,3Dh
       JNE cl_Pas_F3
       CMP Selection_centre,0
       JE cl_Centre_eff_infos
       CMP Change_aff_Centre,1
       JE cl_Pas_F3
       MOV Change_aff_Centre,1
       MOV aff_Centre,offset Aff_position
       MOV Selection_Centre,0
       JMP Key_Check_End
cl_Centre_eff_infos:
       MOV Change_aff_Centre,1
       MOV aff_Centre,offset Rien_Centre
       MOV Selection_Centre,1
       JMP Key_Check_End
cl_Pas_F3:

       CMP ah,78
       JNE Key_Not_Plus
       CMP Volume_total_1,0
       JE Key_Not_Plus
       SUB Volume_total_1,4
       CALL Changer_le_volume
	   JMP Key_Check_End
Key_Not_Plus:

       CMP ah,74
       JNE Key_Not_moins
       CMP Volume_total_1,40h
       JE Key_Not_moins
       ADD Volume_total_1,4
       CALL Changer_le_volume
	   JMP Key_Check_End
Key_Not_moins:

       CMP ah,2
       JNE cl_Pas_1
       CMP Stop_V1,1
       JE Activer_voie_1
       MOV Stop_V1,1
       MOV offset_fin1,0
       MOV Fin_boucle1,0
       JMP Key_Check_End
Activer_voie_1:
       MOV Stop_V1,0
       JMP Key_Check_End
cl_Pas_1:
       CMP ah,3
       JNE cl_Pas_2
       CMP Stop_V2,1
       JE Activer_voie_2
       MOV Stop_V2,1
       MOV offset_fin2,0
       MOV Fin_boucle2,0
       JMP Key_Check_End
Activer_voie_2:
       MOV Stop_V2,0
       JMP Key_Check_End
cl_Pas_2:
       CMP ah,4
       JNE cl_Pas_3
       CMP Stop_V3,1
       JE Activer_voie_3
       MOV Stop_V3,1
       MOV offset_fin3,0
       MOV Fin_boucle3,0
       JMP Key_Check_End
Activer_voie_3:
       MOV Stop_V3,0
       JMP Key_Check_End
cl_Pas_3:
       CMP ah,5
       JNE cl_Pas_4
       CMP Stop_V4,1
       JE Activer_voie_4
       MOV Stop_V4,1
       MOV offset_fin4,0
       MOV Fin_boucle4,0
       JMP Key_Check_End
Activer_voie_4:
       MOV Stop_V4,0
       JMP Key_Check_End
cl_Pas_4:
       CMP ah,77
       JNE cl_Pas_droite
       MOV al,Tot_sequence
       CMP Pos_sequence,al
       JAE Key_Check_End
       MOV Pos_note,63
       MOV compt_tempo,1
       JMP cl_pas_gauche
cl_pas_droite:
       CMP ah,75
       JNE cl_Pas_gauche
       CMP Pos_sequence,1
       JBE Key_Check_End
       DEC Pos_sequence
       DEC Pos_sequence
       MOV Pos_note,63
       MOV compt_tempo,1
       JMP Key_Check_End
cl_pas_gauche:
	  
      CMP ah,1                   ; Escape Key
      JNE Key_Check_End
	  MOV stop_player,1          ; Ask the Timer Interrupt to Stop
	  
Key_Check_End:

      CMP Timer_stop,1           ; Boucle de test de touche ou de fin
      JE Fin_Boucle_Affichage
	  
	  CMP Pause,1	             ; If Pause, We can't wait 1/50
      JNE Do_Wait_50ms           ; Too long JMP
	  JMP Read_Key
Do_Wait_50ms:	  

	  CALL Wait_50ms

      JMP Boucle_Affichage
Fin_boucle_Affichage:
	  
      PUSH CS
      POP DS
      RET
Play endp

Wait_50ms Proc Near      ; Wait 50ms using the Timer interrupt
      CMP Test_periodique,0
      JE Test_per_0
Test_per_1:
      CMP Test_Periodique,1
      JNE Wait_50ms_End
      CMP Timer_stop,1           ; Boucle de test de touche ou de fin
      JE Wait_50ms_End	  
      JMP Test_per_1
Test_per_0:
      CMP Test_Periodique,0
      JNE Wait_50ms_End
      CMP Timer_stop,1           ; Boucle de test de touche ou de fin
      JE Wait_50ms_End		  
      JMP Test_per_0
Wait_50ms_End:
      RET
Wait_50ms endp

Prepare_play Proc near

      CMP boucler,2
      JAE Pas_tester_boucle
      MOV al,Tot_sequence
      CMP Pos_de_restart,al
      JBE Pas_res_78
      MOV Pos_de_restart,1
Pas_res_78:
      CMP Pos_de_restart,0
      JNE Pas_tester_boucle
      MOV Pos_de_restart,1
Pas_tester_boucle:
      MOV pos_note,63
      MOV stop_player,0
      MOV anc_volume,20
      MOV Pause,0

      MOV aff_gauche,offset Barre_pitch
      MOV aff_droite,offset Barre_periode
      MOV aff_centre,offset Aff_position

      CMP frequence,0
      JNE Frequence_definie
      MOV ax,Frequence_def
      MOV Frequence,ax
Frequence_definie:

      CMP Ecran_noir,1
      JE Pas_aff_ecran
      CALL Affiche_ecran
      CALL Curseur_off
Pas_aff_ecran:
      RET
Prepare_play Endp

;�����������������������������������������������������������Ŀ
;�   Affiche_barres     Affiche les barres                   �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������

aff_droite dw 0
aff_gauche dw 0
aff_centre dw 0
Change_aff_gauche db 0
Change_aff_droite db 0
Change_aff_centre db 0
anc_volume db 0

affiche_barres Proc near
      CALL aff_gauche
      CALL aff_droite
      CALL aff_centre
      RET
affiche_barres Endp

Aff_position Proc near
      CMP Change_aff_centre,1
      JNE Pas_aff_infos
      CALL Affiche_tableau_infos
      MOV Change_aff_centre,0
Pas_aff_infos:

      MOV al,Pos_sequence
      MOV DI,2*33+160*12
      CALL BIA
      MOV al,Pos_note
      MOV DI,2*44+160*12
      CALL affichebxy
      MOV al,Volume_Total_1

      SHR al,1
      SHR al,1
      MOV SI,2*31+160*17
      MOV ah,16
      SUB ah,al
      MOV cl,ah
      MOV bx,0CDBh
V_Boucle_barre:
      CMP Cl,0
      JZ V_Fin_boucle_barre
      MOV ES:[SI],bx
      INC SI
      INC SI
      DEC CL
      JMP V_Boucle_barre
V_Fin_Boucle_barre:
      MOV bx,04DBh
      MOV ES:[SI],bx
      INC SI
      INC SI
      MOV al,16
      SUB al,ah
      MOV cl,al
      MOV bx,0020h
V_Boucle_barre_e:
      CMP CL,0
      JZ V_Fin_boucle_barre_e
      MOV ES:[SI],bx
      INC SI
      INC SI
      DEC CL
      JMP V_Boucle_barre_e
V_Fin_Boucle_barre_e:

      RET
Aff_position Endp

Affiche_sample Proc near
      MOV SI,offset Sample_name
      MOV bl,Tot_samp
      MOV dx,15
      MOV DI,2*11+160*9-116
      MOV ah,03h
Boucle_aff_sample:
      MOV CX,22
      ADD DI,116
Aff_nom_samp:
      LODSB
      STOSW
      LOOP Aff_nom_samp
      DEC DX
      CMP DX,0
      JNE Boucle_aff_sample
      CMP bl,15
      JE Fin_aff_samp
      MOV dx,16
      MOV DI,2*48+160*9-116
Boucle_aff_sample2:
      MOV CX,22
      ADD DI,116
Aff_nom_samp2:
      LODSB
      STOSW
      LOOP Aff_nom_samp2
      DEC DX
      CMP DX,0
      JNE Boucle_aff_sample2
Fin_aff_samp:
      RET
Affiche_sample Endp

Charge_samp Proc near
      MOV SI,14h
      MOV DI,Offset Sample_name
      PUSH DS
      PUSH CS
      POP DS
      MOV ax,Debutfich
      MOV DS,ax
      MOV ax,31
      PUSH CS
      POP ES
Boucle_deplace_name:
      MOV CX,22
      REP MOVSB
      ADD SI,8
      DEC AX
      JNE Boucle_deplace_name
      POP DS
      RET
Charge_samp Endp

Charge_samp_stm Proc near
      MOV SI,48
      MOV DI,Offset Sample_name
     PUSH DS
      PUSH CS
      POP DS
      MOV ax,Debutfich
      MOV DS,ax
      MOV ax,31
      PUSH CS
      POP ES
S_Boucle_deplace_name:
      MOV CX,14
      REP MOVSB
      ADD SI,18
      ADD DI,8
      DEC AX
      JNE S_Boucle_deplace_name
      POP DS
      RET
Charge_samp_stm Endp

;�����������������������������������������������������������Ŀ
;�   Init_SB         Initialise la sound blaster             �
;�     Entr�e                                                �
;�                                                           �
;�     Sortie                                                �
;�                                                           �
;�     Change      AX,DX,SI                                  �
;�������������������������������������������������������������
Init_sb proc near
       MOV dx,226h
       MOV al,1
       OUT dx,al
       IN AL,dx
       IN al,dx
       IN al,dx
       IN al,dx
       SUB al,al
       OUT dx,al
       MOV bl,10h
Init_sb_boucle:
       CALL Lecture_sb
       CMP al,0AAh
       je Init_sb_ok
       DEC bl
       JNZ init_sb_boucle
       STC
       RET
Init_sb_ok:
       CLC
       RET
init_sb endp

Lecture_sb proc near
       PUSH cx
       MOV dx,22Eh
       MOV cx,200h
Boucle_lire_sb:
       IN al,dx
       OR al,al
       js lire_ok
       LOOP Boucle_lire_sb
       STC
       POP DX
       RET
Lire_ok:
      SUB dl,04h
      IN al,dx
      CLC
      POP cx
      RET
Lecture_sb ENDP

;�����������������������������������������������������������Ŀ
;�   Joue_musique                                            �
;�     Entr�e      Variables                                 �
;�                                                           �
;�     Sortie      Rien                                      �
;�     Info:  Le player est r�sident                         �
;�������������������������������������������������������������


n_sample db 0
Timer_stop db 0
Frequence dw 0
Periode_timer dw 0
p_timer_h dw 0
p_timer_l dw 0
Touche_detectee db 0

oldvect dd 0
Ancien_int  db 0
oldvect_clavier dd 0
Port_beeper db 0

Joue_Musique Proc near

        MOV Timer_stop,0
        MOV commande_v1,offset rien
        MOV commande_v2,offset rien
        MOV commande_v3,offset rien
        MOV commande_v4,offset rien

        MOV Offset_fin1,0
        MOV Offset_fin2,0
        MOV Offset_fin3,0
        MOV Offset_fin4,0
        MOV W [Offset SB_Offset_Actuel1-2],0
        MOV offset_actuel2,0
        MOV offset_actuel3,0
        MOV offset_actuel4,0
        MOV fin_boucle1,0
        MOV fin_boucle2,0
        MOV fin_boucle3,0
        MOV fin_boucle4,0

        MOV ax,adresse_table_volume
        MOV Voie1_vol,ah
        MOV Voie2_vol,ah
        MOV Voie3_vol,ah
        MOV Voie4_vol,ah

        MOV Per_t_pr_1,0
        MOV Per_t_pr_2,0
        MOV Per_t_pr_3,0
        MOV Per_t_pr_4,0
        MOV Param_t_pr_1,0
        MOV Param_t_pr_2,0
        MOV Param_t_pr_3,0
        MOV Param_t_pr_4,0

        MOV Periode_v1,358h
        MOV Periode_v2,358h
        MOV Periode_v3,358h
        MOV Periode_v4,358h
        MOV Old_pos_1,4000
        MOV Old_pos_2,4000
        MOV Old_pos_3,4000
        MOV Old_pos_4,4000

        XOR DX,DX
        MOV ax,Frequence
        MOV bx,50
        DIV bx
        MOV Valeur_50,ax
        MOV Compt_50,1
        MOV Compt_tempo,1
        MOV tempo,6

        MOV bx,frequence
        MOV ax,34DCh
        MOV dx,12h
        DIV bx           ; 1193180/F -> AX
        MOV Periode_timer,ax
        MOV CX,300h
        MUL CX
        MOV p_timer_h,dx
        MOV p_timer_l,ax

        sub  ax,ax
        mov  ds,ax     ;segment vect d'interruption
        mov  si,20h    ;ofs d'int timer
        mov  cx,4      ;4 octets a transferer
        push cs
        pop  es
        mov  di,offset oldvect
        cld
        rep  movsb

        push cs
        pop  ds
        MOV dx,offset Player
        CMP Utilise_sb,1
        JNE Init_beeper_1
	
        WAITSBlaster
        MOV al,10h   ; Command 10h : Direct DAC, 8-bit
        OUT DX,AL
		
        mov  dx,offset Player_sb
		
Init_beeper_1:
        mov  al,08h              ;Interruption Timer
        mov  ah,25h              ;fixer vect d'int sur ds[dx]
        int  21h

        MOV ax,Periode_timer
        CLI
        PUSH ax
        MOV al,34h       ;00110110b
        OUT 43h,al       ;Change la fr�quence
        POP ax           ;Du timer
        OUT 40h,al
        MOV al,ah
        OUT 40h,al
        STI

        MOV al,90h              ;Pr�pare le beeper
        OUT 43h,al

        IN AL,61h
        OR AL,03h
        OUT 61h,al
        MOV Port_beeper,al

        RET
Joue_musique endp

Init_timer Proc near

        PUSH CX
        PUSH ES
        PUSH DI
        PUSH SI

        sub  ax,ax
        mov  ds,ax     ;segment vect d'interruption
        mov  si,20h    ;ofs d'int timer
        mov  cx,4      ;4 octets a transferer
        push cs
        pop  es
        mov  di,offset oldvect
        cld
        rep  movsb

        push cs
        pop  ds
        MOV dx,offset Player
        CMP Utilise_sb,1
        JNE Init_beeper
        mov  dx,offset Player_sb
Init_beeper:
        mov  al,08h              ;Interruption Timer
        mov  ah,25h              ;fixer vect d'int sur ds[dx]
        int  21h

        MOV ax,Periode_timer
        CLI
        PUSH ax
        MOV al,34h  ;00110110b
        OUT 43h,al       ;Change la fr�quence
        POP ax           ;Du timer
        OUT 40h,al
        MOV al,ah
        OUT 40h,al
        STI

        POP SI
        POP DI
        POP ES
        POP CX
        RET
Init_timer endp

Restore_timer proc near

        PUSH CX
        PUSH ES
        PUSH DI
        PUSH SI
        CLI
        MOV al,00110110b
        OUT 43h,al
        MOV al,0
        OUT 40h,al    ;Fixe la fr�quence
        OUT 40h,al    ; � 18,2 Hz
        PUSH cs
        POP ds
        SUB ax,ax
        MOV es,ax
        MOV di,20h
        MOV si,offset oldvect
        MOV cx,4
        CLD
        REP movsb
        STI
        POP SI
        POP DI
        POP ES
        POP CX
        RET
Restore_timer  endp

restore_timer_fin Proc near
        PUSH CX
        PUSH ES
        PUSH DI
        PUSH SI
		
        CLI
        MOV al,0FFh
        OUT 21h,al
        STI
		
        IN al,61h
        AND al,0FCh
        OUT 61h,al

        CLI
        MOV al,34h
        OUT 43h,al
        MOV al,0
        OUT 40h,al    ;Fixe la fr�quence
        OUT 40h,al    ; � 18,2 Hz

        MOV al,0B6h
        OUT 43h,al
        MOV ax,0533h
        OUT 42h,al
        MOV al,ah
        OUT 42h,al

        PUSH cs
        POP ds
        SUB ax,ax
        MOV es,ax
        MOV di,20h
        MOV si,offset oldvect
        MOV cx,4
        CLD
        REP movsb

        MOV al,ancien_int
        OUT 21h,al
        STI

        POP SI
        POP DI
        POP ES
        POP CX
        RET

restore_timer_fin Endp

Changer_le_volume:
        MOV ah,Volume_reel_1
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE dim_vol_1
        XOR ah,ah
dim_vol_1:
        XOR al,al
        ADD ax,Adresse_table_volume
        MOV Voie1_vol,ah

        MOV ah,Volume_reel_2
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE dim_vol_2
        XOR ah,ah
dim_vol_2:
        ADD ax,Adresse_table_volume
        MOV Voie2_vol,ah
        MOV ah,Volume_reel_3
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE dim_vol_3
        XOR ah,ah
dim_vol_3:
        ADD ax,Adresse_table_volume
        MOV Voie3_vol,ah
        MOV ah,Volume_reel_4
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE dim_vol_4
        XOR ah,ah
dim_vol_4:
        ADD ax,Adresse_table_volume
        MOV Voie4_vol,ah
        RET

Ta_vib db 0,12,25,37,48,60,71,81,90,98,106,112,117,122,125,126,127
       db 126,125,122,117,112,106,98,90,81,71,60,48,37,25,12,0,0

T_bep     DB 20h,1Fh,1Eh,1Dh,1Ch,1Bh,1Ah,19h,18h,17h,16h,15h,14h,13h,12h,11h
      DB 11h,10h,10h,0Fh,0Fh,0Eh,0Eh,0Dh,0Dh,0Dh,0Ch,0Ch,0Ch,0Ch,0Bh,0Bh
      DB 0Bh,0Bh,0Ah,0Ah,0Ah,0Ah,0Ah,09h,09h,09h,09h,09h,09h,09h,09h,09h
      DB 08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,07h,07h,07h,07h
      DB 07h,07h,07h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,05h,05h
      DB 05h,05h,05h,05h,05h,05h,05h,05h,04h,04h,04h,04h,04h,04h,04h,04h
      DB 04h,04h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,02h,02h,02h,02h
      DB 02h,02h,02h,02h,02h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h

      DB 40h,40h,40h,40h,40h,40h,40h,40h,40h,40h,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
      DB 3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh
      DB 3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch
      DB 3Ch,3Ch,3Ch,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Ah,3Ah,3Ah
      DB 3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,39h,39h,39h,39h,39h,39h,39h,39h,39h
      DB 39h,38h,38h,38h,38h,38h,38h,38h,38h,37h,37h,37h,37h,37h,36h,36h
      DB 36h,36h,35h,35h,35h,35h,34h,34h,34h,33h,33h,32h,32h,31h,31h,30h
      DB 30h,2Fh,2Eh,2Dh,2Ch,2Bh,2Ah,29h,28h,27h,26h,25h,24h,23h,22h,21h


Test_Periodique db 0
stop_player     db 0     ;Set to 1 to Stop the Player

Volume_reel_1  db 0
Volume_reel_2  db 0
Volume_reel_3  db 0
Volume_reel_4  db 0
Volume_total_1 db 0

Change_V1 db 0
Change_V2 db 0
Change_V3 db 0
Change_V4 db 0

Commande_v1 dw 0
Commande_v2 dw 0
Commande_v3 dw 0
Commande_v4 dw 0

Sample_v1 db 0
Sample_v2 db 0
Sample_v3 db 0
Sample_v4 db 0

Periode_v1 dw 0
Periode_v2 dw 0
Periode_v3 dw 0
Periode_v4 dw 0
Nouv_per_v1 db 0
Nouv_per_v2 db 0
Nouv_per_v3 db 0
Nouv_per_v4 db 0

Pos_note db 0
Pos_sequence db 0
Seg_pattern dw 0
Tot_sequence db 0
Valeur_50 dw 0
Compt_50 dw 0
Tempo db 0
Compt_tempo db 0

offset_actuel1 dw 0
;Segment_actuel1 dw 0
Offset_fin1 dw 0
Part_decimale1 db 0
Part_entiere1 db 0
accumulateur1 db 0
Debut_boucle1 dw 0
Fin_boucle1 dw 0
Voie1_vol db 0

offset_actuel2 dw 0
Segment_actuel2 dw 0
Offset_fin2 dw 0
Part_decimale2 db 0
Part_entiere2 db 0
accumulateur2 db 0
Debut_boucle2 dw 0
Fin_boucle2 dw 0
Voie2_vol db 0

offset_actuel3 dw 0
Segment_actuel3 dw 0
Offset_fin3 dw 0
Part_decimale3 db 0
Part_entiere3 db 0
accumulateur3 db 0
Debut_boucle3 dw 0
Fin_boucle3 dw 0
Voie3_vol db 0

offset_actuel4 dw 0
Segment_actuel4 dw 0
Offset_fin4 dw 0
Part_decimale4 db 0
Part_entiere4 db 0
accumulateur4 db 0
Debut_boucle4 dw 0
Fin_boucle4 dw 0
Voie4_vol db 0

OutputBuffer db 0

;*  Sound Blaster Interrupt and Mixing *

SB_Boucle1:
        MOV bx,Debut_boucle1
        MOV dx,fin_boucle1
        OR dx,dx
        JE SB_Voie1             ;Pas de Boucle
        MOV offset_fin1,dx
;        JMP SB_Calc_Voie1	


Player_sb:
        PUSH ds
        PUSH es
        PUSH ax
        PUSH bx
        PUSH dx
        PUSH SI
        CLI
		
        PUSH CS
        POP DS

		WAITSBlaster		
        MOV al,OutputBuffer   
        SUB al,80h
        OUT DX,AL              ; Send the Data to the Sound Blaster (First 8bit DAC Command sent at the IRQ init)
		       
        MOV DX,1234h 		   ; Auto modified code
SB_Segment_actuel1:           
        MOV es,dx
        MOV BX,1234h
SB_Offset_Actuel1:		
        CMP offset_fin1,bx
        JNB SB_Pas_de_boucle1
		
        MOV bx,Debut_boucle1
        MOV dx,fin_boucle1
        OR dx,dx
        JE SB_Voie1
        MOV offset_fin1,dx
;W [Offset SB_Segment_actuel1-2]
		
SB_Pas_de_boucle1:
        XOR dh,dh
        MOV al,part_decimale1
        ADD accumulateur1,al
        MOV dl,Part_entiere1
        ADC bx,dx
        MOV W [Offset SB_Offset_Actuel1-2],bx
        MOV BL,es:[bx]
        MOV BH,Voie1_vol
        MOV ah,[BX]
SB_Voie1:
;       MOV dx,segment_actuel2        
        MOV DX,1234h 		   ; Auto modified code
SB_Segment_actuel2:  
        MOV es,dx
        MOV BX,1234h
SB_Offset_Actuel2:	
        CMP offset_fin2,bx
        JNB SB_Pas_de_boucle2
        MOV bx,Debut_boucle2
        MOV dx,fin_boucle2
        OR dx,dx
        JE SB_Voie2
        MOV offset_fin2,dx
SB_Pas_de_boucle2:
        XOR dh,dh
        MOV al,part_decimale2
        ADD accumulateur2,al
        MOV dl,Part_entiere2
        ADC bx,dx
        MOV W [Offset SB_Offset_Actuel2-2],bx
        MOV BL,es:[bx]
        MOV BH,Voie2_vol
        ADD ah,[BX]
SB_Voie2:
;       MOV dx,segment_actuel3
        MOV DX,1234h 		   ; Auto modified code
SB_Segment_actuel3:   	
        MOV es,dx
        MOV BX,1234h
SB_Offset_Actuel3:	
        CMP offset_fin3,bx
        JNB SB_Pas_de_boucle3
        MOV bx,Debut_boucle3
        MOV dx,fin_boucle3
        OR dx,dx
        JE SB_Voie3
        MOV offset_fin3,dx
SB_Pas_de_boucle3:
        XOR dh,dh
        MOV al,part_decimale3
        ADD accumulateur3,al
        MOV dl,Part_entiere3
        ADC bx,dx
        MOV W [Offset SB_Offset_Actuel3-2],bx
        MOV BL,es:[bx]
        MOV BH,Voie3_vol
        ADD ah,[BX]
SB_Voie3:
;        MOV dx,segment_actuel4
        MOV DX,1234h 		   ; Auto modified code
SB_Segment_actuel4:
		MOV es,dx
        MOV BX,1234h
SB_Offset_Actuel4:	
        CMP offset_fin4,bx
        JNB SB_Pas_de_boucle4
        MOV bx,Debut_boucle4
        MOV dx,fin_boucle4
        OR dx,dx
        JE SB_Voie4
        MOV offset_fin4,dx
SB_Pas_de_boucle4:
        XOR dh,dh
        MOV al,part_decimale4
        ADD accumulateur4,al
        MOV dl,Part_entiere4
        ADC bx,dx
        MOV W [Offset SB_Offset_Actuel4-2],bx
        MOV BL,es:[bx]
        MOV BH,Voie4_vol
        ADD ah,[BX]
SB_Voie4:

        MOV OutputBuffer,ah
		
        WAITSBlaster
        MOV al,10h   ; Command 10h : Direct DAC, 8-bit
        OUT DX,AL
		
        STI
        MOV al,20h
        OUT 20h,al
        DEC Compt_50
        JZ Partition_SB
        POP SI
        POP DX
        POP BX
        POP AX
        POP ES
        POP DS
        IRET

Partition_SB:
        JMP Partition

		
Player:
        PUSH ds
        PUSH es
        PUSH ax
        PUSH bx
        PUSH dx
        PUSH SI
        CLI
        PUSH CS
        POP DS

        XOR al,al

        MOV dx,1234h
Segment_actuel1:
        MOV es,dx
        MOV BX,offset_actuel1
        CMP offset_fin1,bx
        JNB P_Pas_de_boucle1
        MOV bx,Debut_boucle1
        MOV dx,fin_boucle1
        OR dx,dx
        JE Voie1
        MOV offset_fin1,dx
P_Pas_de_boucle1:
        XOR dh,dh
        MOV dl,part_decimale1
        ADD accumulateur1,dl
        MOV dl,Part_entiere1
        ADC bx,dx
        MOV offset_actuel1,bx
        MOV BL,es:[bx]
        MOV BH,Voie1_vol
        MOV al,[BX]
Voie1:

        MOV dx,segment_actuel2
        MOV es,dx
        MOV BX,offset_actuel2
        CMP offset_fin2,bx
        JNB P_Pas_de_boucle2
        MOV bx,Debut_boucle2
        MOV dx,fin_boucle2
        OR dx,dx
        JE Voie2
        MOV offset_fin2,dx
P_Pas_de_boucle2:
        XOR dh,dh
        MOV dl,part_decimale2
        ADD accumulateur2,dl
        MOV dl,Part_entiere2
        ADC bx,dx
        MOV offset_actuel2,bx
        MOV BL,es:[bx]
        MOV BH,Voie2_vol
        ADD al,[BX]
Voie2:
        MOV dx,segment_actuel3
        MOV es,dx
        MOV BX,offset_actuel3
        CMP offset_fin3,bx
        JNB P_Pas_de_boucle3
        MOV bx,Debut_boucle3
        MOV dx,fin_boucle3
        OR dx,dx
        JE Voie3
        MOV offset_fin3,dx
P_Pas_de_boucle3:
        XOR dh,dh
        MOV dl,part_decimale3
        ADD accumulateur3,dl
        MOV dl,Part_entiere3
        ADC bx,dx
        MOV offset_actuel3,bx
        MOV BL,es:[bx]
        MOV BH,Voie3_vol
        ADD al,[BX]
Voie3:
        MOV dx,segment_actuel4
        MOV es,dx
        MOV BX,offset_actuel4
        CMP offset_fin4,bx
        JNB P_Pas_de_boucle4
        MOV bx,Debut_boucle4
        MOV dx,fin_boucle4
        OR dx,dx
        JE Voie4
        MOV offset_fin4,dx
P_Pas_de_boucle4:
        XOR dh,dh
        MOV dl,part_decimale4
        ADD accumulateur4,dl
        MOV dl,Part_entiere4
        ADC bx,dx
        MOV offset_actuel4,bx
        MOV BL,es:[bx]
        MOV BH,Voie4_vol
        ADD al,[BX]
Voie4:

        MOV bx,offset T_bep
        XLAT
        OUT 42h,al
		
        STI		
        MOV al,20h
        OUT 20h,al
        DEC Compt_50
        JZ Partition
        POP SI
        POP DX
        POP BX
        POP AX
        POP ES
        POP DS
        IRET

Partition:
        PUSH DI

        MOV ax,Valeur_50
        MOV Compt_50,ax
        DEC compt_tempo
        JZ Calculer_part
        CMP Stop_V1,1
        JE Pas_cmd_1
        CALL Commande_V1
Pas_cmd_1:
        CMP Stop_V2,1
        JE Pas_cmd_2
        CALL Commande_V2
Pas_cmd_2:
        CMP Stop_V3,1
        JE Pas_cmd_3
        CALL Commande_V3
Pas_cmd_3:
        CMP Stop_V4,1
        JE Pas_cmd_4
        CALL Commande_V4
Pas_cmd_4:
        JMP Fin_commande
		
Calculer_part:
        MOV al,tempo
        MOV compt_tempo,al

        CALL Partition_mod
        CMP stop_player,1
        JE Fin_player

Fin_commande:
        CMP Test_Periodique,1
        MOV Test_Periodique,0
        JE Change_test_periodique
        MOV Test_Periodique,1
Change_test_periodique:

        POP DI
        POP SI
        POP DX
        POP BX
        POP AX
        POP ES
        POP DS
        IRET



Fin_Player:

        CALL restore_timer_fin
        MOV al,20h
        OUT 20h,al		

        MOV timer_stop,1                ; The Timer is Stopped
        POP DI
        POP SI
        POP DX
        POP BX
        POP AX
        POP ES
        POP DS
        IRET

Partition_mod:

        INC Pos_note
        CMP pos_note,64
        JNE lire_part_p
        MOV si,offset table_sequence
        MOV al,pos_sequence
        INC Pos_sequence
        CMP al,tot_sequence
        JNE Cont_part_p
        CMP Boucler,1
        JE Boucler_module
        CMP Boucler,2
        JE Boucler_module_n
        MOV stop_player,1
        JMP Fin_eff_4
Boucler_module_n:
        DEC nb_de_boucles
        CMP nb_de_boucles,0
        JNE Boucler_module
        MOV stop_player,1
        JMP Fin_eff_4
Boucler_module:
        MOV al,Pos_de_restart
        MOV Pos_sequence,al
        DEC al
Cont_part_p:
        XOR ah,ah
        ADD si,ax
        MOV al,[si]
        MOV si,offset table_pattern
        SHL ax,1
        ADD si,ax
        MOV ax,[si]
        MOV seg_pattern,ax
        MOV pos_note,0
Lire_part_p:
        MOV ax,seg_pattern
        PUSH ax
        POP es
        MOV al,Pos_note
        XOR ah,ah
        MOV si,ax
        SHL si,1
        SHL si,1
        SHL si,1
        SHL si,1

        CMP Stop_V1,1
        JNE Pas_stop_V1
        JMP Calc_voie_1
Pas_stop_V1:

        MOV bx,ES:[si]
        XCHG bh,bl
        MOV dh,bh
        PUSH DX

        MOV ax,ES:[si+2]        ;Pour tester si commande 3
        AND al,00001111b        ;Al contient la commande
        CMP al,3
        JE Periode_nule1_p
        AND bx,0000111111111111b
                              ;bx contient la p�riode
        MOV Nouv_per_v1,0
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Periode_nule1_p

        MOV periode_V1,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        MOV Nouv_per_v1,1
Periode_nule1_p:
        MOV bx,ES:[si+2]        ;Charge instrument
        SHR bl,1
        SHR bl,1
        SHR bl,1
        SHR bl,1
        DEC bl

        POP DX
        AND dh,11110000b
        CMP dh,10000b
        JNE pas_mk_1_p
        ADD bl,instr_ajoute
Pas_mk_1_p:
        CMP bl,0FFh
        JNE Cont_inst1
        CMP nouv_per_V1,1
        JNE Pas_reat_V1
        MOV bl,Sample_V1
        MOV nouv_per_V1,3
        JMP Cont_inst1
Pas_reat_V1:
        JMP Calc_voie_1
Cont_inst1:

        MOV Sample_V1,bl      ;Channel 1 Sample Start
        MOV al,bl
        XOR AH,AH
        SHL AL,1
        MOV DI,offset table_sample
        ADD di,ax
        MOV ax,[DI]
        MOV W [Offset SB_Segment_actuel1-2],ax
        MOV W [Offset SB_Offset_Actuel1-2],0

        MOV ax,[DI+62]
        MOV Offset_fin1,ax
        MOV ax,[DI+124]
        MOV Debut_boucle1,ax

        MOV ax,[DI+186]
        MOV Fin_boucle1,ax
        MOV Change_V1,1
                              ;Variables Instrument
        CMP nouv_per_V1,3
        JE Calc_voie_1

        MOV ax,[DI+248]

        MOV Volume_reel_1,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE Garder_vol_1
        XOR AX,AX
Garder_vol_1:

        ADD ax,Adresse_table_volume
        MOV Voie1_vol,ah

Calc_voie_1:
        MOV commande_V1,offset rien
        MOV ax,ES:[si+2]
        AND al,00001111b
        CMP al,0Ch
        JNE Pas_eff_C_1
                          ; C. Set volume
        XOR al,al
        CMP AX,4000h
        JB Volume_correcte1
        MOV ax,4000h
Volume_correcte1:

        MOV Volume_reel_1,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE SV_Garder_vol_1
        XOR ah,ah
SV_Garder_vol_1:
        ADD ax,Adresse_table_volume
        MOV Voie1_vol,ah
        JMP fin_eff_1
Pas_eff_C_1:
        CMP al,0Fh    ; Set Speed
        JNE Pas_eff_F_1
        CMP ah,0      ; F=0 Stop
        JE Pas_eff_F_1
		CMP ah,20h    ; >20h Set BPM Not Supported
		JAE Pas_eff_F_1
        MOV tempo,ah
        MOV compt_tempo,ah
        JMP Fin_eff_1
Pas_eff_F_1:
        CMP al,0h       ; 0 Arpeggio
        JNE Pas_eff_0_1
        CMP ah,0h
        JNE Cont_eff_F_1
        JMP Fin_eff_1
Cont_eff_F_1:
        MOV param_arp1,ah
        MOV compt_arp1,0
        MOV commande_V1,offset arpeggio_1
        JMP Fin_eff_1
Pas_eff_0_1:
        CMP al,2h       ; 2 Portamento Down
        JNE Pas_eff_2_1
        CMP ah,0h
        JNE Cont_eff_0_1
        JMP Fin_eff_1
Cont_eff_0_1:
        MOV param_pr_dn1,ah
        MOV commande_V1,offset Port_dn_1
        JMP fin_eff_1
Pas_eff_2_1:
        CMP al,1h       ; 1 Portamento Up
        JNE Pas_eff_1_1
        CMP ah,0h
        JNE Cont_eff_1_1
        JMP Fin_eff_1
Cont_eff_1_1:
        MOV param_pr_up1,ah
        MOV commande_V1,offset Port_up_1
        JMP fin_eff_1
Pas_eff_1_1:

        CMP al,0Ah       ; A. Volume slide
        JNE Pas_eff_A_1
        CMP ah,0h
        JNE Cont_eff_A_1
        JMP Fin_eff_1
Cont_eff_A_1:
        MOV param_vs_1,ah
        MOV commande_V1,offset vol_slide_1
        JMP Fin_eff_1
Pas_eff_A_1:
        CMP al,0Dh       ; D. Pattern break
        JNE Pas_eff_D_1
        MOV Pos_note,63
        JMP Fin_eff_1
Pas_eff_D_1:
        CMP al,03h       ; 3. Tone portamento
        JNE Pas_eff_3_1
        MOV bx,ES:[si]
        XCHG bh,bl
        AND bx,0000111111111111b
        CMP BX,0
        JNE Cont_Exec_3_1
        CMP Per_t_pr_1,0
        JE Pas_eff_3_1
        JMP Superieur_t_1
Cont_exec_3_1:
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_3_1
        MOV Per_t_pr_1,bx
        MOV dir_t_pr_1,0
        CMP bx,Periode_v1
        JA Superieur_t_1
        MOV dir_t_pr_1,1
superieur_t_1:
        CMP ah,0
        JE u_an_param_1
        MOV param_t_pr_1,ah
u_an_param_1:
        MOV Commande_v1,offset t_pr_1
        JMP Fin_eff_1
Pas_eff_3_1:
        CMP al,4        ; 4. Vibrato
        JNE Pas_eff_4_1
        CMP ah,0
        JNE Cont_eff_4_1
        JMP Garde_val_1
Cont_eff_4_1:
        MOV al,ah
        AND al,00001111b
        MOV Amplitude_1,al
        SHR ah,1
		SHR ah,1
		SHR ah,1
		SHR ah,1
        MOV Vitesse_1,ah
        MOV i_vib_1,0
Garde_val_1:
        MOV Commande_V3,offset Vibrato_1
        JMP Fin_eff_1
Pas_eff_4_1:
        CMP al,6        ; 6. Vibrato + volume slide
        JNE Pas_eff_6_1
        CMP ah,0h
        JNE Cont_eff_6_1
        JMP Fin_eff_1
Cont_eff_6_1:
        MOV param_vib_vs_1,ah
        MOV commande_V1,offset Vib_vs_1
        JMP Fin_eff_1
Pas_eff_6_1:
        CMP al,0Bh       ; B. Position jump  Bug ??
        JNE Pas_eff_B_1
        CMP Boucler,0
        JE Pas_eff_B_1
        MOV Pos_sequence,ah
        MOV Pos_Note,63
        DEC nb_de_boucles
        CMP nb_de_boucles,0
        JNE Pas_eff_b_1
        MOV stop_player,1
        JMP Fin_eff_4
Pas_eff_B_1:
        CMP al,5          ; 5. Tone portamento + volume slide
        JNE Pas_eff_5_1
                                  ;TSTSTSTSTSTSTSTSTSTSTSTSTS
        MOV bx,ES:[si+4]
        XCHG bh,bl
        AND bx,0000111111111111b

        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_5_1
        MOV Per_tvs_1,bx
        MOV dir_tvs_1,0
        CMP bx,Periode_v1
        JA Superieur_tvs_1
        MOV dir_tvs_1,1
superieur_tvs_1:
        MOV param_vs_1,ah              ;On execute un Vs normal
        MOV Commande_v1,offset tvs_1   ;Commande 5
        JMP Fin_eff_1
Pas_eff_5_1:
Fin_eff_1:
        CMP Stop_V2,1
        JNE Pas_stop_V2
        JMP Calc_voie_2
Pas_stop_V2:

        MOV bx,ES:[si+4]
        XCHG bh,bl
        MOV dh,bh
        PUSH DX

        MOV ax,ES:[si+6]        ;Pour tester si commande 3
        AND al,00001111b        ;Al contient la commande
        CMP al,3
        JE Periode_nule2_p
        AND bx,0000111111111111b
                                ;bx contient la p�riode
        MOV Nouv_per_v2,0
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Periode_nule2_p

        MOV periode_V2,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        MOV Nouv_per_v2,1
Periode_nule2_p:
        MOV bx,ES:[si+6]          ;Charge instrument
        SHR bl,1
        SHR bl,1
        SHR bl,1
        SHR bl,1
        DEC bl

        POP DX
        AND dh,11110000b
        CMP dh,10000b
        JNE pas_mk_2_p
        ADD bl,instr_ajoute

Pas_mk_2_p:
        CMP bl,0FFh
        JNE Cont_inst2
        CMP nouv_per_V2,1
        JNE Pas_reat_V2
        MOV bl,Sample_V2
        MOV nouv_per_V2,3
        JMP Cont_inst2
Pas_reat_V2:
        JMP Calc_Voie_2

Cont_inst2:

        MOV Sample_V2,bl
        MOV al,bl
        XOR AH,AH
        SHL AL,1
        MOV DI,offset table_sample
        ADD di,ax
        MOV ax,[DI]
        MOV W [Offset SB_Segment_actuel2-2],ax
        MOV W [Offset SB_Offset_actuel2-2],0

        MOV ax,[DI+62]
        MOV Offset_fin2,ax
        MOV ax,[DI+124]
        MOV Debut_boucle2,ax

        MOV ax,[DI+186]
        MOV Fin_boucle2,ax
        MOV Change_V2,1
                              ;Variables Instrument
        CMP nouv_per_V2,3
        JE Calc_voie_2
        MOV ax,[DI+248]

        MOV Volume_reel_2,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE Garder_vol_2
        XOR AX,AX
Garder_vol_2:

        ADD ax,Adresse_table_volume
        MOV Voie2_vol,ah
Calc_voie_2:

        MOV commande_V2,offset rien
        MOV ax,ES:[si+6]
        AND al,00001111b
        CMP al,0Ch
        JNE Pas_eff_C_2
                           ;Set Volume
        XOR al,al
        CMP ax,4000h
        JB Volume_correcte2
        MOV ax,4000h
Volume_correcte2:

        MOV Volume_reel_2,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE SV_Garder_vol_2
        XOR AX,AX
SV_Garder_vol_2:

        ADD ax,Adresse_table_volume
        MOV Voie2_vol,ah
        JMP Fin_eff_2
Pas_eff_C_2:
        CMP al,0Fh
        JNE Pas_eff_F_2
        CMP ah,0
        JE Pas_eff_F_2
		CMP ah,20h    ; >20h Set BPM Not Supported
		JAE Pas_eff_F_2		
        MOV tempo,ah
        MOV compt_tempo,ah
        JMP Fin_eff_2
Pas_eff_f_2:
        CMP al,0h
        JNE Pas_eff_0_2
        CMP ah,0h
        JNE Cont_eff_f_2
        JMP Fin_eff_2
Cont_eff_f_2:
        MOV param_arp2,ah
        MOV compt_arp2,1
        MOV commande_V2,offset arpeggio_2
        JMP Fin_eff_2
Pas_eff_0_2:
        CMP al,2h
        JNE Pas_eff_2_2
        CMP ah,0h
        JNE Cont_eff_0_2
        JMP Fin_eff_2
Cont_eff_0_2:
        MOV param_pr_dn2,ah
        MOV commande_V2,offset Port_dn_2
        JMP fin_eff_2
Pas_eff_2_2:
        CMP al,1h
        JNE Pas_eff_1_2
        CMP ah,0h
        JNE Cont_eff_1
        JMP Fin_eff_2
Cont_eff_1:
        MOV param_pr_up2,ah
        MOV commande_V2,offset Port_up_2
        JMP fin_eff_2
Pas_eff_1_2:
        CMP al,0Ah
        JNE Pas_eff_A_2
        CMP ah,0h
        JNE Cont_eff_A_2
        JMP Fin_eff_2
Cont_eff_A_2:
        MOV param_vs_2,ah
        MOV commande_V2,offset vol_slide_2
        JMP Fin_eff_2
Pas_eff_A_2:
        CMP al,0Dh
        JNE Pas_eff_D_2
        MOV Pos_note,63
        JMP Fin_eff_2
Pas_eff_D_2:
        CMP al,03h
        JNE Pas_eff_3_2
        MOV bx,ES:[si+4]
        XCHG bh,bl
        AND bx,0000111111111111b
        CMP BX,0
        JNE Cont_Exec_3_2
        CMP Per_t_pr_2,0
        JE Pas_eff_3_2
        JMP Superieur_t_2
Cont_exec_3_2:
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_3_2
        MOV Per_t_pr_2,bx
        MOV dir_t_pr_2,0
        CMP bx,Periode_v2
        JA Superieur_t_2
        MOV dir_t_pr_2,1
superieur_t_2:
        CMP ah,0
        JE u_an_param_2
        MOV param_t_pr_2,ah
u_an_param_2:
        MOV Commande_v2,offset t_pr_2
        JMP Fin_eff_2
Pas_eff_3_2:
        CMP al,4
        JNE Pas_eff_4_2
        CMP ah,0
        JNE Cont_eff_4_2
        JMP Garde_val_2
Cont_eff_4_2:
        MOV al,ah
        AND al,00001111b
        MOV Amplitude_2,al
        SHR ah,1
        SHR ah,1
        SHR ah,1
        SHR ah,1
        MOV Vitesse_2,ah
        MOV i_vib_2,0
Garde_val_2:
        MOV Commande_V2,offset Vibrato_2
        JMP Fin_eff_2
Pas_eff_4_2:
        CMP al,6
        JNE Pas_eff_6_2
        CMP ah,0h
        JNE Cont_eff_6_2
        JMP Fin_eff_2
Cont_eff_6_2:
        MOV param_vib_vs_2,ah
        MOV commande_V2,offset Vib_vs_2
        JMP Fin_eff_2
Pas_eff_6_2:
        CMP al,0Bh
        JNE Pas_eff_B_2
        CMP Boucler,0
        JE Pas_eff_B_2
        MOV Pos_sequence,ah
        MOV Pos_Note,63
        DEC nb_de_boucles
        CMP nb_de_boucles,0
        JNE Pas_eff_b_2
        MOV stop_player,1
        JMP Fin_eff_4
Pas_eff_B_2:
        CMP al,5
        JNE Pas_eff_5_2

        MOV bx,ES:[si+4]
        XCHG bh,bl
        AND bx,0000111111111111b

        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_5_2
        MOV Per_tvs_2,bx
        MOV dir_tvs_2,0
        CMP bx,Periode_v2
        JA Superieur_tvs_2
        MOV dir_tvs_2,1
superieur_tvs_2:
        MOV param_vs_2,ah              ;On execute un Vs normal
        MOV Commande_v2,offset tvs_2   ;Commande 5
        JMP Fin_eff_2
Pas_eff_5_2:
Fin_eff_2:
        CMP Stop_V3,1
        JNE Pas_stop_V3
        JMP Calc_voie_3
Pas_stop_V3:

        MOV bx,ES:[si+8]
        XCHG bh,bl
        MOV dh,bh
        PUSH DX

        MOV ax,ES:[si+10]        ;Pour tester si commande 3
        AND al,00001111b         ;Al contient la commande
        CMP al,3
        JE Periode_nule3_p
        AND bx,0000111111111111b
                                 ;bx contient la p�riode
        MOV Nouv_per_v3,0
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Periode_nule3_p

        MOV periode_V3,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        MOV Nouv_per_v3,1
Periode_nule3_p:
        MOV bx,ES:[si+10]          ;Charge instrument
        SHR bl,1
        SHR bl,1
        SHR bl,1
        SHR bl,1
        DEC bl

        POP DX
        AND dh,11110000b
        CMP dh,10000b
        JNE pas_mk_3_p
        ADD bl,instr_ajoute
Pas_mk_3_p:
        CMP bl,0FFh
        JNE Cont_inst3
        CMP nouv_per_V3,1
        JNE Pas_reat_V3
        MOV bl,Sample_V3
        MOV nouv_per_V3,3
        JMP Cont_inst3
Pas_reat_V3:
        JMP  Calc_voie_3

Cont_inst3:

        MOV Sample_V3,bl
        MOV al,bl
        XOR AH,AH
        SHL AL,1
        MOV DI,offset table_sample
        ADD di,ax
        MOV ax,[DI]
        MOV W [Offset SB_Segment_actuel3-2],ax
        MOV W [Offset SB_Offset_actuel3-2],0

        MOV ax,[DI+62]
        MOV Offset_fin3,ax
        MOV ax,[DI+124]
        MOV Debut_boucle3,ax

        MOV ax,[DI+186]
        MOV Fin_boucle3,ax
        MOV Change_V3,1
                              ;Variables Instrument
        CMP nouv_per_V3,3
        JE Calc_voie_3
        MOV ax,[DI+248]

        MOV Volume_reel_3,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE Garder_vol_3
        XOR AX,AX
Garder_vol_3:

        ADD ax,Adresse_table_volume
        MOV Voie3_vol,ah
Calc_voie_3:
        MOV commande_V3,offset rien
        MOV ax,ES:[si+10]
        AND al,00001111b
        CMP al,4

        CMP al,0Ch
        JNE Pas_eff_C_3
                             ;Set Volume
        XOR al,al
        CMP AX,4000h
        JB Volume_correcte3
        MOV ax,4000h
Volume_correcte3:

        MOV Volume_reel_3,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE SV_Garder_vol_3
        XOR AX,AX
SV_Garder_vol_3:

        ADD ax,Adresse_table_volume
        MOV Voie3_vol,ah
        JMP Fin_eff_3
Pas_eff_C_3:
        CMP al,0Fh
        JNE Pas_eff_F_3
        CMP ah,0
        JE Pas_eff_F_3
		CMP ah,20h    ; >20h Set BPM Not Supported
		JAE Pas_eff_F_3		
        MOV tempo,ah
        MOV compt_tempo,ah
        JMP Fin_eff_3
Pas_eff_F_3:
        CMP al,0h
        JNE Pas_eff_0_3
        CMP ah,0h
        JNE Cont_eff_0_3
        JMP Fin_eff_3
Cont_eff_0_3:
        MOV param_arp3,ah
        MOV compt_arp3,0
        MOV commande_V3,offset arpeggio_3
        JMP fin_eff_3
Pas_eff_0_3:
        CMP al,2h
        JNE Pas_eff_2_3
        CMP ah,0h
        JNE Cont_eff_2_3
        JMP Fin_eff_3
Cont_eff_2_3:
        MOV param_pr_dn3,ah
        MOV commande_V3,offset Port_dn_3
        JMP fin_eff_3
Pas_eff_2_3:
        CMP al,1h
        JNE Pas_eff_1_3
        CMP ah,0h
        JNE Cont_eff_1_3
        JMP Fin_eff_3
Cont_eff_1_3:
        MOV param_pr_up3,ah
        MOV commande_V3,offset Port_up_3
        JMP fin_eff_3
Pas_eff_1_3:
        CMP al,0Ah
        JNE Pas_eff_A_3
        CMP ah,0h
        JNE Cont_eff_A_3
        JMP Fin_eff_3
Cont_eff_A_3:
        MOV param_vs_3,ah
        MOV commande_V3,offset vol_slide_3
        JMP Fin_eff_3
Pas_eff_A_3:
        CMP al,0Dh
        JNE Pas_eff_D_3
        MOV Pos_note,63
        JMP Fin_eff_3
Pas_eff_D_3:
        CMP al,03h
        JNE Pas_eff_3_3
        MOV bx,ES:[si+8]
        XCHG bh,bl
        AND bx,0000111111111111b
        CMP BX,0
        JNE Cont_Exec_3_3
        CMP Per_t_pr_3,0
        JE Pas_eff_3_3
        JMP Superieur_t_3
Cont_exec_3_3:
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_3_3
        MOV Per_t_pr_3,bx
        MOV dir_t_pr_3,0
        CMP bx,Periode_v3
        JA Superieur_t_3
        MOV dir_t_pr_3,1
Superieur_t_3:
        CMP ah,0
        JE u_an_param_3
        MOV param_t_pr_3,ah
u_an_param_3:
        MOV Commande_v3,offset t_pr_3
        JMP Fin_eff_3
Pas_eff_3_3:
        CMP al,4
        JNE Pas_eff_4_3
        CMP ah,0
        JNE Cont_eff_4_3
        JMP Garde_val_3
Cont_eff_4_3:
        MOV al,ah
        AND al,00001111b
        MOV Amplitude_3,al
        SHR ah,1
        SHR ah,1
        SHR ah,1
        SHR ah,1
        MOV Vitesse_3,ah
        MOV i_vib_3,0
Garde_val_3:
        MOV Commande_V3,offset Vibrato_3
        JMP Fin_eff_3
Pas_eff_4_3:
        CMP al,6
        JNE Pas_eff_6_3
        CMP ah,0h
        JNE Cont_eff_6_3
        JMP Fin_eff_3
Cont_eff_6_3:
        MOV param_vib_vs_3,ah
        MOV commande_V3,offset Vib_vs_3
        JMP Fin_eff_3
Pas_eff_6_3:
        CMP al,0Bh
        JNE Pas_eff_B_3
        CMP Boucler,0
        JE Pas_eff_B_3
        MOV Pos_sequence,ah
        MOV Pos_Note,63
        DEC nb_de_boucles
        CMP nb_de_boucles,0
        JNE Pas_eff_b_3
        MOV stop_player,1
        JMP Fin_eff_4
Pas_eff_B_3:
        CMP al,5
        JNE Pas_eff_5_3

        MOV bx,ES:[si+4]
        XCHG bh,bl
        AND bx,0000111111111111b

        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_5_3
        MOV Per_tvs_3,bx
        MOV dir_tvs_3,0
        CMP bx,Periode_v3
        JA Superieur_tvs_3
        MOV dir_tvs_3,1
superieur_tvs_3:
        MOV param_vs_3,ah              ;On execute un Vs normal
        MOV Commande_v3,offset tvs_3   ;Commande 5
        JMP Fin_eff_3
Pas_eff_5_3:
Fin_eff_3:
        CMP Stop_V4,1
        JNE Pas_stop_V4
        JMP Calc_voie_4
Pas_stop_V4:

        MOV bx,ES:[si+12]
        XCHG bh,bl
        MOV dh,bh
        PUSH DX

        MOV ax,ES:[si+14]        ;Pour tester si commande 3
        AND al,00001111b         ;Al contient la commande
        CMP al,3
        JE Periode_nule4_p
        AND bx,0000111111111111b
                         ;bx contient la p�riode
        MOV Nouv_per_v4,0
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Periode_nule4_p

        MOV periode_v4,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        MOV Nouv_per_v4,1
Periode_nule4_p:
        MOV bx,ES:[si+14]           ;Charge instrument
        SHR bl,1
        SHR bl,1
        SHR bl,1
        SHR bl,1
        DEC bl

        POP DX
        AND dh,11110000b
        CMP dh,10000b
        JNE pas_mk_4_p
        ADD bl,instr_ajoute
Pas_mk_4_p:
        CMP bl,0FFh
        JNE Cont_inst4
        CMP nouv_per_V4,1
        JNE Pas_reat_V4
        MOV bl,Sample_V4
        MOV nouv_per_V4,3
        JMP Cont_inst4
Pas_reat_V4:
        JMP Calc_voie_4

Cont_inst4:
        MOV Sample_V4,bl
        MOV al,bl
        XOR AH,AH
        SHL AL,1
        MOV DI,offset table_sample
        ADD di,ax
        MOV ax,[DI]
        MOV W [Offset SB_Segment_actuel4-2],ax
        MOV W [Offset SB_Offset_actuel4-2],0

        MOV ax,[DI+62]
        MOV Offset_fin4,ax
        MOV ax,[DI+124]
        MOV Debut_boucle4,ax

        MOV ax,[DI+186]
        MOV Fin_boucle4,ax
        MOV Change_V4,1
                                ;Variables Instrument
        CMP nouv_per_V4,3
        JE Calc_voie_4
        MOV ax,[DI+248]

        MOV Volume_reel_4,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE Garder_vol_4
        XOR AX,AX
Garder_vol_4:

        ADD ax,Adresse_table_volume
        MOV Voie4_vol,ah
Calc_voie_4:

        MOV commande_V4,offset rien
        MOV ax,ES:[si+14]
        AND al,00001111b
        CMP al,0Ch
        JNE Pas_eff_C_4
                       ;Set Volume
        XOR al,al
        CMP AX,4000h
        JB Volume_correcte4
        MOV ax,4000h
Volume_correcte4:

        MOV Volume_reel_4,ah
        SUB ah,Volume_Total_1
        CMP ah,40h
        JBE SV_Garder_vol_4
        XOR AX,AX
SV_Garder_vol_4:

        ADD ax,Adresse_table_volume
        MOV Voie4_vol,ah
        JMP Fin_eff_4
Pas_eff_C_4:
        CMP al,0Fh    ; Set Tempo
        JNE Pas_eff_F_4
        CMP ah,0
        JE Pas_eff_F_4
		CMP ah,20h    ; >20h Set BPM Not Supported
		JAE Pas_eff_F_4		
        MOV tempo,ah
        MOV compt_tempo,ah
        JMP Fin_eff_4
Pas_eff_F_4:
        CMP al,0h
        JNE Pas_eff_0_4
        CMP ah,0h
        JNE Cont_eff_F_4
        JMP Fin_eff_4
Cont_eff_F_4:
        MOV param_arp4,ah
        MOV compt_arp4,0
        MOV commande_V4,offset arpeggio_4
        JMP Fin_eff_4
Pas_eff_0_4:
        CMP al,2h
        JNE Pas_eff_2_4
        CMP ah,0h
        JNE Cont_eff_0_4
        JMP Fin_eff_4
Cont_eff_0_4:
        MOV param_pr_dn4,ah
        MOV commande_V4,offset Port_dn_4
        JMP Fin_eff_4
Pas_eff_2_4:
        CMP al,1h
        JNE Pas_eff_1_4
        CMP ah,0h
        JNE Cont_eff_2_4
        JMP Fin_eff_4
Cont_eff_2_4:
        MOV param_pr_up4,ah
        MOV commande_V4,offset Port_up_4
        JMP Fin_eff_4
Pas_eff_1_4:
        CMP al,0Ah
        JNE Pas_eff_A_4
        CMP ah,0h
        JNE Cont_eff_A_4
        JMP Fin_eff_4
Cont_eff_A_4:
        MOV param_vs_4,ah
        MOV commande_V4,offset vol_slide_4
        JMP Fin_eff_4
Pas_eff_A_4:
        CMP al,0Dh
        JNE Pas_eff_D_4
        MOV Pos_note,63
        JMP Fin_eff_4
Pas_eff_D_4:
        CMP al,03h
        JNE Pas_eff_3_4
        MOV bx,ES:[si+12]
        XCHG bh,bl
        AND bx,0000111111111111b
        CMP BX,0
        JNE Cont_Exec_3_4
        CMP Per_t_pr_4,0
        JE Pas_eff_3_4
        JMP Superieur_t_4
Cont_exec_3_4:
        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_3_4
        MOV Per_t_pr_4,bx
        MOV dir_t_pr_4,0
        CMP bx,Periode_v4
        JA Superieur_t_4
        MOV dir_t_pr_4,1
superieur_t_4:
        CMP ah,0
        JE u_an_param_4
        MOV param_t_pr_4,ah
u_an_param_4:
        MOV Commande_v4,offset t_pr_4
        JMP Fin_eff_4
Pas_eff_3_4:
        CMP al,4
        JNE Pas_eff_4_4
        CMP ah,0
        JNE Cont_eff_4_4
        JMP Garde_val_4
Cont_eff_4_4:
        MOV al,ah
        AND al,00001111b
        MOV Amplitude_4,al
        SHR ah,1
        SHR ah,1
        SHR ah,1
        SHR ah,1
        MOV Vitesse_4,ah
        MOV i_vib_4,0
Garde_val_4:
        MOV Commande_V4,offset Vibrato_4
        JMP Fin_eff_4
Pas_eff_4_4:
        CMP al,6
        JNE Pas_eff_6_4
        CMP ah,0h
        JNE Cont_eff_6_4
        JMP Fin_eff_4
Cont_eff_6_4:
        MOV param_vib_vs_4,ah
        MOV commande_V4,offset Vib_vs_4
        JMP Fin_eff_4
Pas_eff_6_4:
        CMP al,0Bh
        JNE Pas_eff_B_4
        CMP Boucler,0
        JE Pas_eff_B_4
        MOV Pos_sequence,ah
        MOV Pos_Note,63
        DEC nb_de_boucles
        CMP nb_de_boucles,0
        JNE Pas_eff_b_4
        MOV stop_player,1
        JMP Fin_eff_4
Pas_eff_B_4:
        JMP Fin_eff_4
        CMP al,5
        JNE Pas_eff_5_4

        MOV bx,ES:[si+4]
        XCHG bh,bl
        AND bx,0000111111111111b

        MOV dx,bx
        SUB dx,71h
        CMP dx,2E7h
        JA Pas_eff_5_4
        MOV Per_tvs_4,bx
        MOV dir_tvs_4,0
        CMP bx,Periode_v4
        JA Superieur_tvs_4
        MOV dir_tvs_4,1
superieur_tvs_4:
        MOV param_vs_4,ah              ;On execute un Vs normal
        MOV Commande_v4,offset tvs_4   ;Commande 5
        JMP Fin_eff_4
Pas_eff_5_4:

Pas_eff_4:

Fin_eff_4:
        RET

;�����������������������������������������������������������Ŀ
;�                      COMMANDES                            �
;�������������������������������������������������������������

Rien:
        RET

Compt_arp1 db 0
Param_arp1 db 0

arpeggio_1:

       MOV bx,Periode_V1
       INC Compt_arp1
       CMP Compt_arp1,1
       JNE Pas_3n_1
       JMP Fin_arp1
Pas_3n_1:
       CMP Compt_arp1,2
       JNE Pas_3n1_1
       MOV al,param_arp1
       SHR al,1
       SHR al,1
       SHR al,1
       SHR al,1
       XOR ah,ah
       ADD bx,ax
       JMP Fin_arp1
Pas_3n1_1:
       MOV al,param_arp1
       AND al,00001111b
       XOR ah,ah
       ADD bx,ax
In_cmp1:
       MOV compt_arp1,0
Fin_arp1:
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        RET

Compt_arp2 db 0
Param_arp2 db 0

arpeggio_2:

       MOV bx,Periode_V2
       INC Compt_arp2
       CMP Compt_arp2,1
       JNE Pas_3n_2
       JMP Fin_arp2
Pas_3n_2:
       CMP Compt_arp2,2
       JNE Pas_3n1_2
       MOV al,param_arp2
       SHR al,1
       SHR al,1
       SHR al,1
       SHR al,1
       XOR ah,ah
       ADD bx,ax
       JMP Fin_arp2
Pas_3n1_2:
       MOV al,param_arp2
       AND al,00001111b
       XOR ah,ah
       ADD bx,ax
In_cmp2:
       MOV compt_arp2,0
Fin_arp2:
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        RET

Compt_arp3 db 0
Param_arp3 db 0

arpeggio_3:
       MOV bx,Periode_V3
       INC Compt_arp3
       CMP Compt_arp3,1
       JNE Pas_3n_3
       JMP Fin_arp3
Pas_3n_3:
       CMP Compt_arp3,2
       JNE Pas_3n1_3
       MOV al,param_arp3
       SHR al,1
       SHR al,1
       SHR al,1
       SHR al,1
       XOR ah,ah
       ADD bx,ax
       JMP Fin_arp3
Pas_3n1_3:
       MOV al,param_arp3
       AND al,00001111b
       XOR ah,ah
       ADD bx,ax
In_cmp3:
       MOV compt_arp3,0
Fin_arp3:
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        RET

Compt_arp4 db 0
Param_arp4 db 0
arpeggio_4:
       MOV bx,Periode_V4
       INC Compt_arp4
       CMP Compt_arp4,1
       JNE Pas_3n_4
       JMP Fin_arp4
Pas_3n_4:
       CMP Compt_arp4,2
       JNE Pas_3n1_4
       MOV al,param_arp4
       SHR al,1
       SHR al,1
       SHR al,1
       SHR al,1
       XOR ah,ah
       ADD bx,ax
       JMP Fin_arp4
Pas_3n1_4:
       MOV al,param_arp4
       AND al,00001111b
       XOR ah,ah
       ADD bx,ax
In_cmp4:
       MOV compt_arp4,0
Fin_arp4:
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        RET

Param_pr_dn1 db 0
Port_dn_1:
        MOV bx,periode_V1
        XOR ah,ah
        MOV al,Param_pr_dn1
        ADD bx,ax
        CMP BX,359h
        JB Port_dn_inf_1
        MOV bx,358h
Port_dn_inf_1:
        MOV periode_V1,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        RET

Param_pr_up1 db 0
Port_up_1:
        MOV bx,periode_V1
        XOR ah,ah
        MOV al,Param_pr_up1
        SUB bx,ax
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Pru_Periode_correcte_1
        MOV bx,71h
Pru_Periode_correcte_1:
        MOV periode_V1,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        RET

Param_pr_dn2 db 0
Port_dn_2:
        MOV bx,periode_V2
        XOR ah,ah
        MOV al,Param_pr_dn2
        CMP BX,359h
        JB Port_dn_inf_2
        MOV bx,358h
Port_dn_inf_2:
        ADD bx,ax
        MOV periode_V2,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        RET

Param_pr_up2 db 0
Port_up_2:
        MOV bx,periode_V2
        XOR ah,ah
        MOV al,Param_pr_up2
        SUB bx,ax
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Pru_Periode_correcte_2
        MOV bx,71h
Pru_Periode_correcte_2:
        MOV periode_V2,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        RET

Param_pr_dn3 db 0
Port_dn_3:
        MOV bx,periode_V3
        XOR ah,ah
        MOV al,Param_pr_dn3
        ADD bx,ax
        CMP BX,359h
        JB Port_dn_inf_3
        MOV bx,358h
Port_dn_inf_3:
        MOV periode_V3,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        RET

Param_pr_up3 db 0
Port_up_3:
        MOV bx,periode_V3
        XOR ah,ah
        MOV al,Param_pr_up3
        SUB bx,ax
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Pru_Periode_correcte_3
        MOV bx,71h
Pru_Periode_correcte_3:

        MOV periode_V3,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        RET

Param_pr_dn4 db 0
Port_dn_4:
        MOV bx,periode_V4
        XOR ah,ah
        MOV al,Param_pr_dn4
        ADD bx,ax
        CMP BX,359h
        JB Port_dn_inf_4
        MOV bx,358h
Port_dn_inf_4:
        MOV periode_V4,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        RET

Param_pr_up4 db 0
Port_up_4:
        MOV bx,periode_V4
        XOR ah,ah
        MOV al,Param_pr_up4
        SUB bx,ax
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Pru_Periode_correcte_4
        MOV bx,71h
Pru_Periode_correcte_4:
        MOV periode_V4,bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        RET

Param_vs_1 db 0
Vol_slide_1:
        MOV al,param_vs_1
        CMP al,1111b
        JA Vol_sl_add_1
        MOV bl,Volume_reel_1  ;Voie1_vol
        SUB bl,al
        CMP bl,40h
        JB Fin_vs_1
        MOV bl,0
        JMP Fin_vs_1
Vol_sl_add_1:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_1  ;Voie1_vol
        ADD bl,al
        CMP bl,40h
        JB Fin_vs_1
        MOV bl,40h
        JMP Fin_vs_1
Fin_vs_1:
        MOV Volume_reel_1,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE Vs_Garder_vol_1
        XOR bl,bl
Vs_Garder_vol_1:
        MOV dx,Adresse_table_volume
        ADD bl,dh       ;Ajoute d�calage table volume
        MOV Voie1_vol,bl
        RET

Param_vs_2 db 0
Vol_slide_2:
        MOV dx,Adresse_table_volume
        MOV al,param_vs_2
        CMP al,1111b
        JA Vol_sl_add_2
        MOV bl,Volume_reel_2
        SUB bl,al
        CMP bl,40h
        JB Fin_vs_2
        MOV bl,0
        JMP Fin_vs_2
Vol_sl_add_2:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_2
        ADD bl,al
        CMP bl,40h
        JB Fin_vs_2
        MOV bl,40h
        JMP Fin_vs_2
Fin_vs_2:
        MOV Volume_reel_2,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE Vs_Garder_vol_2
        XOR bl,bl
Vs_Garder_vol_2:

        ADD bl,dh       ;Ajoute d�calage table volume
        MOV Voie2_vol,bl
        RET

Param_vs_3 db 0
Vol_slide_3:
        MOV dx,Adresse_table_volume
        MOV al,param_vs_3
        CMP al,1111b
        JA Vol_sl_add_3
        MOV bl,Volume_reel_3
        SUB bl,al
        CMP bl,40h
        JB Fin_vs_3
        MOV bl,0
        JMP Fin_vs_3
Vol_sl_add_3:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_3
        ADD bl,al
        CMP bl,40h
        JB Fin_vs_3
        MOV bl,40h
        JMP Fin_vs_3
Fin_vs_3:
        MOV Volume_reel_3,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE Vs_Garder_vol_3
        XOR bl,bl
Vs_Garder_vol_3:

        ADD bl,dh       ;Ajoute d�calage table volume
        MOV Voie3_vol,bl
        RET

Param_vs_4 db 0
Vol_slide_4:
        MOV dx,Adresse_table_volume
        MOV al,param_vs_4
        CMP al,1111b
        JA Vol_sl_add_4
        MOV bl,Volume_reel_4
        SUB bl,al
        CMP bl,40h
        JB Fin_vs_4
        MOV bl,0
        JMP Fin_vs_4
Vol_sl_add_4:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_4
        ADD bl,al
        CMP bl,40h
        JB Fin_vs_4
        MOV bl,40h
        JMP Fin_vs_4
Fin_vs_4:
        MOV Volume_reel_4,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE Vs_Garder_vol_4
        XOR bl,bl
Vs_Garder_vol_4:

        ADD bl,dh       ;Ajoute d�calage table volume
        MOV Voie4_vol,bl
        RET

Per_t_pr_1 dw 0
Param_t_pr_1 db 0
dir_t_pr_1 db 0
t_pr_1:
        MOV bx,Periode_V1
        XOR ah,ah
        MOV al,Param_t_pr_1
        CMP al,0
        JNE Cont_t_pr_1
        MOV bx,Per_t_pr_1
        JMP Fin_t_pr_1
Cont_t_pr_1:
        CMP dir_t_pr_1,0
        JE t_pr_1_monte
        SUB bx,ax
        CMP bx,Per_t_pr_1
        JA Test_si_Grand_1
        MOV bx,Per_t_pr_1
        JMP Fin_t_pr_1
Test_si_grand_1:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_t_pr_1
        MOV bx,Per_t_pr_1
        JMP Fin_t_pr_1
t_pr_1_monte:
        ADD bx,ax
        CMP bx,Per_t_pr_1
        JB Fin_t_pr_1
        MOV bx,Per_t_pr_1
Fin_t_pr_1:
        MOV periode_V1,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        RET

Per_t_pr_2 dw 0
Param_t_pr_2 db 0
dir_t_pr_2 db 0
t_pr_2:
        MOV bx,Periode_V2
        XOR ah,ah
        MOV al,Param_t_pr_2
        CMP al,0
        JNE Cont_t_pr_2
        MOV bx,Per_t_pr_2
        JMP Fin_t_pr_2
Cont_t_pr_2:
        CMP dir_t_pr_2,0
        JE t_pr_2_monte
        SUB bx,ax
        CMP bx,Per_t_pr_2
        JA Test_si_Grand_2
        MOV bx,Per_t_pr_2
        JMP Fin_t_pr_2
Test_si_grand_2:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_t_pr_2
        MOV bx,Per_t_pr_2
        JMP Fin_t_pr_2
t_pr_2_monte:
        ADD bx,ax
        CMP bx,Per_t_pr_2
        JB Fin_t_pr_2
        MOV bx,Per_t_pr_2
Fin_t_pr_2:
        MOV periode_V2,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
      RET

Per_t_pr_3 dw 0
Param_t_pr_3 db 0
dir_t_pr_3 db 0
t_pr_3:
        MOV bx,Periode_V3
        XOR ah,ah
        MOV al,Param_t_pr_3
        CMP al,0
        JNE Cont_t_pr_3
        MOV bx,Per_t_pr_3
        JMP Fin_t_pr_3
Cont_t_pr_3:
        CMP dir_t_pr_3,0
        JE t_pr_3_monte
        SUB bx,ax
        CMP bx,Per_t_pr_3
        JA Test_si_Grand_3
        MOV bx,Per_t_pr_3
        JMP Fin_t_pr_3
Test_si_grand_3:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_t_pr_3
        MOV bx,Per_t_pr_3
        JMP Fin_t_pr_3
t_pr_3_monte:
        ADD bx,ax
        CMP bx,Per_t_pr_3
        JB  Fin_t_pr_3
        MOV bx,Per_t_pr_3
Fin_t_pr_3:

        MOV periode_V3,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        RET

Per_t_pr_4 dw 0
Param_t_pr_4 db 0
dir_t_pr_4 db 0
t_pr_4:
        MOV bx,Periode_V4
        XOR ah,ah
        MOV al,Param_t_pr_4
        CMP al,0
        JNE Cont_t_pr_4
        MOV bx,Per_t_pr_4
        JMP Fin_t_pr_4
Cont_t_pr_4:
        CMP dir_t_pr_4,0
        JE t_pr_4_monte
        SUB bx,ax
        CMP bx,Per_t_pr_4
        JA Test_si_grand_4
        MOV bx,Per_t_pr_4
        JMP Fin_t_pr_4
Test_si_grand_4:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_t_pr_4
        MOV bx,Per_t_pr_4
        JMP Fin_t_pr_4
t_pr_4_monte:
        ADD bx,ax
        CMP bx,Per_t_pr_4
        JB Fin_t_pr_4
        MOV bx,Per_t_pr_4
Fin_t_pr_4:
        MOV periode_V4,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        RET

Vitesse_1 db 0
Amplitude_1 db 0
i_vib_1 db 0
Vibrato_1:
         CMP i_vib_1,63
         JB Pas_per_vib_1
         SUB i_vib_1,64
Pas_per_vib_1:
         MOV SI,offset Ta_vib
         MOV bl,i_vib_1
         XOR bh,bh
         MOV al,[si+bx]
         MUL Amplitude_1
         SHR ax,1
         SHR ax,1
         SHR ax,1
         SHR ax,1
         SHR ax,1
         MOV bx,Periode_V1
         CMP i_vib_1,31
         JNA Pas_neg_v_1
         SUB bx,ax
         JMP Fin_vib_1
Pas_neg_v_1:
         ADD bx,ax
Fin_vib_1:
        MOV al,vitesse_1
        ADD i_vib_1,al
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        RET

Vitesse_2 db 0
Amplitude_2 db 0
i_vib_2 db 0
Vibrato_2:
         CMP i_vib_2,63
         JB Pas_per_vib_2
         SUB i_vib_2,64
Pas_per_vib_2:
         MOV SI,offset Ta_vib
         MOV bl,i_vib_2
         XOR bh,bh
         MOV al,[si+bx]
         MUL Amplitude_2
         SHR ax,1
         SHR ax,1
         SHR ax,1
         SHR ax,1
         SHR ax,1
         MOV bx,Periode_V2
         CMP i_vib_2,31
         JNA Pas_neg_v_2
         SUB bx,ax
         JMP Fin_vib_2
Pas_neg_v_2:
         ADD bx,ax
Fin_vib_2:
        MOV al,vitesse_2
        ADD i_vib_2,al
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        RET
 
Vitesse_3 db 0
Amplitude_3 db 0
i_vib_3 db 0
Vibrato_3:
        CMP i_vib_3,63
        JB Pas_per_vib_3
        SUB i_vib_3,64
Pas_per_vib_3:
        MOV SI,offset Ta_vib
        MOV bl,i_vib_3
        XOR bh,bh
        MOV al,[si+bx]
        MUL Amplitude_3
        SHR ax,1
        SHR ax,1
        SHR ax,1
        SHR ax,1
        SHR ax,1
        MOV bx,Periode_V3   ;_vib_3
        CMP i_vib_3,31
        JNA Pas_neg_v_3
        SUB bx,ax
        JMP Fin_vib_3
Pas_neg_v_3:
        ADD bx,ax
Fin_vib_3:
        MOV al,vitesse_3
        ADD i_vib_3,al
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        RET

Vitesse_4 db 0
Amplitude_4 db 0
i_vib_4 db 0
Vibrato_4:
        CMP i_vib_4,63
        JB Pas_per_vib_4
        SUB i_vib_4,64
Pas_per_vib_4:
        MOV SI,offset Ta_vib
        MOV bl,i_vib_4
        XOR bh,bh
        MOV al,[si+bx]
        MUL Amplitude_4
        SHR ax,1
        SHR ax,1
        SHR ax,1
        SHR ax,1
        SHR ax,1
        MOV bx,Periode_V4
        CMP i_vib_4,31
        JNA Pas_neg_v_4
        SUB bx,ax
        JMP Fin_vib_4
Pas_neg_v_4:
        ADD bx,ax
Fin_vib_4:
        MOV al,vitesse_4
        ADD i_vib_4,al
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        RET

Param_vib_vs_1 db 0
Vib_vs_1:
        MOV dx,Adresse_table_volume
        MOV al,param_vib_vs_1
        CMP al,1111b
        JA vib_vol_sl_add_1
        MOV bl,Volume_reel_1
        SUB bl,al
        CMP bl,40h
        JB Fin_vib_vs_1
        MOV bl,0
        JMP Fin_vib_vs_1
vib_vol_sl_add_1:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_1  ;Voie1_vol
        ADD bl,al
        CMP bl,40h
        JB Fin_vib_vs_1
        MOV bl,40
        JMP Fin_vib_vs_1
Fin_vib_vs_1:
        MOV Volume_reel_1,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE vib_Vs_Garder_vol_1
        XOR bl,bl
Vib_Vs_Garder_vol_1:

        ADD bl,dh           ;Ajoute d�calage table volume
        MOV Voie1_vol,bl
        JMP vibrato_1       ;Execute vibrato

Param_vib_vs_2 db 0
Vib_vs_2:
        MOV dx,Adresse_table_volume
        MOV al,param_vib_vs_2
        CMP al,1111b
        JA vib_vol_sl_add_2
        MOV bl,Volume_reel_2
        SUB bl,al
        CMP bl,40h
        JB Fin_vib_vs_2
        MOV bl,0
        JMP Fin_vib_vs_2
vib_vol_sl_add_2:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_2
        ADD bl,al
        CMP bl,40h
        JB Fin_vib_vs_2
        MOV bl,40
        JMP Fin_vib_vs_2
Fin_vib_vs_2:
        MOV Volume_reel_2,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE vib_Vs_Garder_vol_2
        XOR bl,bl
Vib_Vs_Garder_vol_2:

        ADD bl,dh           ;Ajoute d�calage table volume
        MOV Voie2_vol,bl
        JMP vibrato_2       ;Execute vibrato

Param_vib_vs_3 db 0
Vib_vs_3:
        MOV dx,Adresse_table_volume
        MOV al,param_vib_vs_3
        CMP al,1111b
        JA vib_vol_sl_add_3
        MOV bl,Volume_reel_3
        SUB bl,al
        CMP bl,40h
        JB Fin_vib_vs_3
        MOV bl,0
        JMP Fin_vib_vs_3
vib_vol_sl_add_3:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_3
        ADD bl,al
        SUB bl,dh
        CMP bl,40h
        JB Fin_vib_vs_3
        MOV bl,40
        JMP Fin_vib_vs_3
Fin_vib_vs_3:
        MOV Volume_reel_3,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE vib_Vs_Garder_vol_3
        XOR bl,bl
Vib_Vs_Garder_vol_3:

        ADD bl,dh           ;Ajoute d�calage table volume
        MOV Voie3_vol,bl
        JMP vibrato_3       ;Execute vibrato

Param_vib_vs_4 db 0
Vib_vs_4:
        MOV dx,Adresse_table_volume
        MOV al,param_vib_vs_4
        CMP al,1111b
        JA vib_vol_sl_add_4
        MOV bl,Volume_reel_4
        SUB bl,al
        CMP bl,40h
        JB Fin_vib_vs_4
        MOV bl,0
        JMP Fin_vib_vs_4
vib_vol_sl_add_4:
        SHR al,1
        SHR al,1
        SHR al,1
        SHR al,1
        MOV bl,Volume_reel_4
        ADD bl,al
        CMP bl,40h
        JB Fin_vib_vs_4
        MOV bl,40
        JMP Fin_vib_vs_4
Fin_vib_vs_4:
        MOV Volume_reel_4,bl
        SUB bl,Volume_Total_1
        CMP bl,40h
        JBE vib_Vs_Garder_vol_4
        XOR bl,bl
Vib_Vs_Garder_vol_4:

        ADD bl,dh           ;Ajoute d�calage table volume
        MOV Voie4_vol,bl
        JMP vibrato_4       ;Execute vibrato

Per_tvs_1 dw 0
dir_tvs_1 db 0
tvs_1:
        MOV bx,Periode_V1
        XOR ah,ah
        MOV al,Param_t_pr_1
        OR al,al
        JNE Cont_tvs_1
        MOV bx,Per_tvs_1
        JMP Fin_tvs_1
Cont_tvs_1:
        CMP dir_tvs_1,0
        JE tvs_1_monte
        SUB bx,ax
        CMP bx,Per_tvs_1
        JA Test_si_Grand_ts_1
        MOV bx,Per_tvs_1
        JMP Fin_tvs_1
Test_si_grand_ts_1:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_tvs_1
        MOV bx,Per_tvs_1
        JMP Fin_tvs_1
tvs_1_monte:
        ADD bx,ax
        CMP bx,Per_tvs_1
        JB Fin_tvs_1
        MOV bx,Per_tvs_1
Fin_tvs_1:
        MOV periode_V1,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere1,AH
        MOV Part_decimale1,AL
        MOV Accumulateur1,0
        JMP Vol_slide_1

Per_tvs_2 dw 0
dir_tvs_2 db 0
tvs_2:
        MOV bx,Periode_V2
        XOR ah,ah
        MOV al,Param_t_pr_2
        OR al,al
        JNE Cont_tvs_2
        MOV bx,Per_tvs_2
        JMP Fin_tvs_2
Cont_tvs_2:
        CMP dir_tvs_2,0
        JE tvs_2_monte
        SUB bx,ax
        CMP bx,Per_tvs_2
        JA Test_si_Grand_ts_2
        MOV bx,Per_tvs_2
        JMP Fin_tvs_2
Test_si_grand_ts_2:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_tvs_2
        MOV bx,Per_tvs_2
        JMP Fin_tvs_2
tvs_2_monte:
        ADD bx,ax
        CMP bx,Per_tvs_2
        JB Fin_tvs_2
        MOV bx,Per_tvs_2
Fin_tvs_2:
        MOV periode_V2,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere2,AH
        MOV Part_decimale2,AL
        MOV Accumulateur2,0
        JMP Vol_slide_2

Per_tvs_3 dw 0
dir_tvs_3 db 0
tvs_3:
        MOV bx,Periode_V3
        XOR ah,ah
        MOV al,Param_t_pr_3
        OR al,al
        JNE Cont_tvs_3
        MOV bx,Per_tvs_3
        JMP Fin_tvs_3
Cont_tvs_3:
        CMP dir_tvs_3,0
        JE tvs_3_monte
        SUB bx,ax
        CMP bx,Per_tvs_3
        JA Test_si_Grand_ts_3
        MOV bx,Per_tvs_3
        JMP Fin_tvs_3
Test_si_grand_ts_3:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_tvs_3
        MOV bx,Per_tvs_3
        JMP Fin_tvs_3
tvs_3_monte:
        ADD bx,ax
        CMP bx,Per_tvs_3
        JB Fin_tvs_3
        MOV bx,Per_tvs_3
Fin_tvs_3:
        MOV periode_V3,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere3,AH
        MOV Part_decimale3,AL
        MOV Accumulateur3,0
        JMP Vol_slide_3

Per_tvs_4 dw 0
dir_tvs_4 db 0
tvs_4:
        MOV bx,Periode_V4
        XOR ah,ah
        MOV al,Param_t_pr_4
        OR al,al
        JNE Cont_tvs_4
        MOV bx,Per_tvs_4
        JMP Fin_tvs_4
Cont_tvs_4:
        CMP dir_tvs_4,0
        JE tvs_4_monte
        SUB bx,ax
        CMP bx,Per_tvs_4
        JA Test_si_Grand_ts_4
        MOV bx,Per_tvs_4
        JMP Fin_tvs_4
Test_si_grand_ts_4:
        MOV dx,bx
        SUB dx,71h
        CMP dx,358h
        JB Fin_tvs_4
        MOV bx,Per_tvs_4
        JMP Fin_tvs_4
tvs_4_monte:
        ADD bx,ax
        CMP bx,Per_tvs_4
        JB Fin_tvs_4
        MOV bx,Per_tvs_4
Fin_tvs_4:
        MOV periode_V4,bx     ;Periode dans bx
        MOV dx,p_timer_h
        MOV ax,p_timer_l
        DIV bx
        MOV Part_entiere4,AH
        MOV Part_decimale4,AL
        MOV Accumulateur4,0
        JMP Vol_slide_4


;�����������������������������������������������������������Ŀ
;�                      AFFICHAGE                            �
;�������������������������������������������������������������

;�����������������������������������������������������������Ŀ
;�   Affiche_ecran      Initialise l'�cran                   �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������
Tetemsg db 'Mod Master V1.0            Player Amiga-Atari ST'
        db '          (c) 1993 Freddy v�tel�',0
Titre_ec db 'Titre: ',0
Pomsg db 'Positions: ',0
Sampmsg db 'Samples: ',0
Infomsg1 db '��Position�����Note��Ŀ',0
Infomsg2 db '�          �          �',0
Infomsg3 db '���������������������Ĵ',0
Infomsg4 db '�                     �',0
Infomsg5 db '���������Volume������Ĵ',0
Infomsga1 db '�����������������������',0


Affiche_ecran Proc near
           CALL init_ecran

           MOV ax,Adresse_video ;0B800h
           PUSH ax
           POP ES
           MOV ah,00011111b
           MOV SI,offset Tetemsg
           MOV DI,0
           CALL Writelxy


           MOV ah,6
           MOV SI,offset Titre_ec
           MOV DI,2*5+160*1
           CALL Writelxy
           MOV SI,offset titre
           CALL Writelxy

           CALL Affiche_tableau_Pitch
           CALL Affiche_tableau_Periode
           CALL Affiche_tableau_infos
           RET

Affiche_ecran Endp

Affiche_tableau_infos Proc near
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*11
        MOV ah,0Eh
        CALL Writelxy
        MOV SI,offset Infomsg2
        MOV DI,2*28+160*12
        CALL Writelxy
        MOV SI,offset Infomsg3
        MOV DI,2*28+160*13
        CALL Writelxy
        MOV SI,offset Infomsg4
        MOV DI,2*28+160*14
        CALL Writelxy
        MOV SI,offset Infomsg4
        MOV DI,2*28+160*15
        CALL Writelxy
        MOV SI,offset Infomsg5
        MOV DI,2*28+160*16
        CALL Writelxy
        MOV SI,offset Infomsg4
        MOV DI,2*28+160*17
        CALL Writelxy
        MOV SI,offset Infomsga1
        MOV DI,2*28+160*18
        CALL Writelxy


        MOV ah,07h
        MOV SI,offset Pomsg
        MOV DI,2*33+160*14
        CALL Writelxy
        MOV al,Tot_sequence
        MOV DI,2*44+160*14
        CALL BIA
        MOV ah,07h
        MOV SI,offset Sampmsg
        MOV DI,2*35+160*15
        CALL Writelxy
        MOV al,nb_reel_samp
        MOV DI,2*44+160*15
        CALL BIA
        RET
Affiche_tableau_infos Endp

Efface_Tableau_infos Proc near
        XOR ah,ah
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*11
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*12
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*13
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*14
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*15
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*16
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*17
        CALL Writelxy
        MOV SI,offset Infomsg1
        MOV DI,2*28+160*18
        CALL Writelxy

        RET
Efface_Tableau_infos Endp

Stop_msg_p db 'STOP                    ',0
Zero_per db '000',0

Barre_Periode Proc near

      CMP Change_aff_droite,1
      JNE Pas_aff_Periode
      CALL Affiche_tableau_Periode
      MOV Change_aff_droite,0
Pas_aff_Periode:

      CMP Stop_V1,1
      JNE Pas_stop_Per_1
      MOV ah,07h
      MOV SI,offset Stop_msg_p
      MOV DI,2*46+160*4
      CALL Writelxy
      MOV SI,offset Zero_per
      MOV DI,2*42+160*4
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Per_1
Pas_stop_Per_1:
      MOV ax,Periode_V1
      MOV bx,ax
      MOV DI,2*42+160*4
      CALL Affiche_p_xy
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      CMP bl,26
      JBE Barre_1
      MOV bl,26
Barre_1:
      INC DI
      INC DI
      MOV bh,26
      SUB bh,bl
      MOV cl,bh
      MOV ax,07CDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bl,23
      SUB bl,bh
      MOV cl,bl
      MOV ax,0020h
      REP STOSW
Fin_Per_1:
      CMP Stop_V2,1
      JNE Pas_stop_Per_2
      MOV ah,07h
      MOV SI,offset Stop_msg_p
      MOV DI,2*46+160*5
      CALL Writelxy
      MOV SI,offset Zero_per
      MOV DI,2*42+160*5
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Per_2
Pas_stop_Per_2:
      MOV ax,Periode_V2
      MOV bx,ax
      MOV DI,2*42+160*5
      CALL Affiche_p_xy
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      CMP bl,26
      JBE Barre_2
      MOV bl,26
Barre_2:
      INC DI
      INC DI
      MOV bh,26
      SUB bh,bl
      MOV cl,bh
      MOV ax,07CDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bl,23
      SUB bl,bh
      MOV cl,bl
      MOV ax,0020h
      REP STOSW
Fin_Per_2:
      CMP Stop_V3,1
      JNE Pas_stop_Per_3
      MOV ah,07h
      MOV SI,offset Stop_msg_p
      MOV DI,2*46+160*6
      CALL Writelxy
      MOV SI,offset Zero_per
      MOV DI,2*42+160*6
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Per_3
Pas_stop_Per_3:

      MOV ax,Periode_V3
      MOV bx,ax
      MOV DI,2*42+160*6
      CALL Affiche_p_xy
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      CMP bl,26
      JBE Barre_3
      MOV bl,26
Barre_3:
      INC DI
      INC DI
      MOV bh,26
      SUB bh,bl
      MOV cl,bh
      MOV ax,07CDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bl,23
      SUB bl,bh
      MOV cl,bl
      MOV ax,0020h
      REP STOSW
Fin_Per_3:
      CMP Stop_V4,1
      JNE Pas_stop_Per_4
      MOV ah,07h
      MOV SI,offset Stop_msg_p
      MOV DI,2*46+160*7
      CALL Writelxy
      MOV SI,offset Zero_per
      MOV DI,2*42+160*7
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Per_4
Pas_stop_Per_4:
      MOV ax,Periode_V4
      MOV bx,ax
      MOV DI,2*42+160*7
      CALL Affiche_p_xy
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      SHR BX,1
      CMP bl,26
      JBE Barre_4
      MOV bl,26
Barre_4:
      INC DI
      INC DI
      MOV bh,26
      SUB bh,bl
      MOV cl,bh
      MOV ax,07CDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bl,23
      SUB bl,bh
      MOV cl,bl
      MOV ax,0020h
      REP STOSW
Fin_Per_4:

      RET
Barre_Periode endp

Barre_volume Proc near

      CMP Change_aff_gauche,1
      JNE Pas_aff_volume
      CALL Affiche_tableau_volume
      MOV Change_aff_gauche,0
Pas_aff_volume:

      CMP Stop_V1,1
      JNE Pas_stop_Vol_1
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*4
      CALL Writelxy
      MOV SI,offset Zero_Vol
      MOV DI,2*8+160*4
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Vol_1
Pas_stop_Vol_1:

      MOV ax,adresse_table_volume
      MOV al,Voie1_vol
      SUB al,ah
      MOV bl,al
      MOV DI,2*8+160*4
      CALL affichebxy
      SHR BL,1
      SHR BL,1
      MOV cl,bl
      INC DI
      INC DI
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW

Fin_Vol_1:
      CMP Stop_V2,1
      JNE Pas_stop_Vol_2
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*5
      CALL Writelxy
      MOV SI,offset Zero_Vol
      MOV DI,2*8+160*5
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Vol_2
Pas_stop_Vol_2:

      MOV ax,adresse_table_volume
      MOV al,Voie2_vol
      SUB al,ah
      MOV bl,al
      MOV DI,2*8+160*5
      CALL affichebxy
      SHR BL,1
      SHR BL,1
      MOV cl,bl
      INC DI
      INC DI
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW
Fin_Vol_2:
      CMP Stop_V3,1
      JNE Pas_stop_Vol_3
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*6
      CALL Writelxy
      MOV SI,offset Zero_Vol
      MOV DI,2*8+160*6
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Vol_3
Pas_stop_Vol_3:

      MOV ax,adresse_table_volume
      MOV al,Voie3_vol
      SUB al,ah
      MOV bl,al
      MOV DI,2*8+160*6
      CALL affichebxy
      SHR BL,1
      SHR BL,1
      MOV cl,bl
      INC DI
      INC DI
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW
Fin_Vol_3:
      CMP Stop_V4,1
      JNE Pas_stop_Vol_4
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*7
      CALL Writelxy
      MOV SI,offset Zero_Vol
      MOV DI,2*8+160*7
      MOV ah,0Fh
      CALL Writelxy
      JMP Fin_Vol_4
Pas_stop_Vol_4:

      MOV ax,adresse_table_volume
      MOV al,Voie4_vol
      SUB al,ah
      MOV bl,al
      MOV DI,2*8+160*7
      CALL affichebxy
      SHR BL,1
      SHR BL,1
      MOV cl,bl
      INC DI
      INC DI
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW
Fin_Vol_4:


      RET
Barre_volume endp

Pitch_V1 db 0
Pitch_V2 db 0
Pitch_V3 db 0
Pitch_V4 db 0

Stop_msg db 'STOP             ',0
Zero_vol db '00',0

Barre_Pitch Proc near

      CMP Change_aff_gauche,1
      JNE Pas_aff_Pitch
      CALL Affiche_tableau_Pitch
      MOV Change_aff_gauche,0
Pas_aff_Pitch:

      CMP Stop_V1,1
      JNE Pas_stop_pitch_1
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*4
      CALL Writelxy
      JMP Fin_pitch_1
Pas_stop_pitch_1:
      MOV bl,Volume_reel_1
      CMP Change_V1,1
      MOV Change_V1,0
      JE Change_Pitch_1
      CMP Anc_vol_V1,bl
      JNE Change_pitch_1
      DEC Pitch_V1
      CMP Pitch_V1,41h
      JB Affiche_Pitch_1
      MOV Pitch_V1,0
      JMP Affiche_pitch_1
Change_pitch_1:
      MOV Pitch_V1,bl
Affiche_Pitch_1:
      MOV Anc_vol_V1,bl
      MOV bl,Pitch_V1
      SHR BL,1
      SHR BL,1
      MOV DI,2*11+160*4
      MOV cl,bl
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW

Fin_pitch_1:

      CMP Stop_V2,1
      JNE Pas_stop_pitch_2
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*5
      CALL Writelxy
      JMP Fin_pitch_2
Pas_stop_pitch_2:

      MOV bl,Volume_reel_2
      CMP Change_V2,1
      MOV Change_V2,0
      JE Change_Pitch_2
      CMP Anc_vol_V2,bl
      JNE Change_pitch_2
      DEC Pitch_V2
      CMP Pitch_V2,41h
      JB Affiche_Pitch_2
      MOV Pitch_V2,0
      JMP Affiche_pitch_2
Change_pitch_2:
      MOV Pitch_V2,bl
Affiche_Pitch_2:
      MOV Anc_vol_V2,bl
      MOV bl,Pitch_V2
      SHR BL,1
      SHR BL,1
      MOV DI,2*11+160*5
      MOV cl,bl
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW

Fin_pitch_2:

      CMP Stop_V3,1
      JNE Pas_stop_pitch_3
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*6
      CALL Writelxy
      JMP Fin_pitch_3
Pas_stop_pitch_3:

      MOV bl,Volume_reel_3
      CMP Change_V3,1
      MOV Change_V3,0
      JE Change_Pitch_3
      CMP Anc_vol_V3,bl
      JNE Change_pitch_3
      DEC Pitch_V3
      CMP Pitch_V3,41h
      JB Affiche_Pitch_3
      MOV Pitch_V3,0
      JMP Affiche_pitch_3
Change_pitch_3:
      MOV Pitch_V3,bl
Affiche_Pitch_3:
      MOV Anc_vol_V3,bl
      MOV bl,Pitch_V3
      SHR BL,1
      SHR BL,1
      MOV DI,2*11+160*6
      MOV cl,bl
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW
Fin_pitch_3:

      CMP Stop_V4,1
      JNE Pas_stop_pitch_4
      MOV ah,0Ch
      MOV SI,offset Stop_msg
      MOV DI,2*11+160*7
      CALL Writelxy
      JMP Fin_pitch_4
Pas_stop_pitch_4:

      MOV bl,Volume_reel_4
      CMP Change_V4,1
      MOV Change_V4,0
      JE Change_Pitch_4
      CMP Anc_vol_V4,bl
      JNE Change_pitch_4
      DEC Pitch_V4
      CMP Pitch_V4,41h
      JB Affiche_Pitch_4
      MOV Pitch_V4,0
      JMP Affiche_pitch_4
Change_pitch_4:
      MOV Pitch_V4,bl
Affiche_Pitch_4:
      MOV Anc_vol_V4,bl
      MOV bl,Pitch_V4
      SHR BL,1
      SHR BL,1
      MOV DI,2*11+160*7
      MOV cl,bl
      MOV ax,0CCDh
      REP STOSW
      MOV ah,2
      STOSW
      MOV bh,16
      SUB bh,bl
      MOV cl,bh
      MOV ax,0020h
      REP STOSW
Fin_pitch_4:

      RET
Barre_Pitch endp

Rien_droite Proc near
      CMP Change_aff_droite,1
      JNE Pas_eff_Periode
      CALL Efface_tableau_Periode
      MOV Change_aff_droite,0
Pas_eff_Periode:
      RET
Rien_droite Endp

Old_pos_1 dW 0
Old_pos_2 dW 0
Old_pos_3 dW 0
Old_pos_4 dW 0

Rien_Centre Proc near

      CMP Change_aff_Centre,1
      JNE Pas_eff_Tableau_infos
      CALL Efface_Tableau_infos
      CALL Affiche_sample
      MOV Change_aff_Centre,0
Pas_eff_Tableau_infos:

      MOV DI,Old_pos_1
      MOV AX,0E0Dh
      STOSW
      MOV al,Sample_v1
      CMP al,15
      MOV DX,2*6+160*9
      JB Sample_petit_1
      MOV DX,2*43+160*9
      SUB al,0Fh
Sample_petit_1:
      MOV bl,160
      MUL bl
      ADD AX,DX
      MOV DI,AX
      MOV ax,0F31h
      MOV Old_pos_1,DI
      STOSW

      MOV DI,Old_pos_2
      MOV AX,0E0Dh
      STOSW
      MOV al,Sample_v2
      CMP al,15
      MOV DX,2*7+160*9
      JB Sample_petit_2
      MOV DX,2*44+160*9
      SUB al,0Fh
Sample_petit_2:
      MOV bl,160
      MUL bl
      ADD AX,DX
      MOV DI,AX
      MOV ax,0F32h
      MOV Old_pos_2,DI
      STOSW

      MOV DI,Old_pos_3
      MOV AX,0E0Dh
      STOSW
      MOV al,Sample_v3
      CMP al,15
      MOV DX,2*8+160*9
      JB Sample_petit_3
      MOV DX,2*45+160*9
      SUB al,0Fh
Sample_petit_3:
      MOV bl,160
      MUL bl
      ADD AX,DX
      MOV DI,AX
      MOV ax,0F33h
      MOV Old_pos_3,DI
      STOSW

      MOV DI,Old_pos_4
      MOV AX,0E0Dh
      STOSW
      MOV al,Sample_v4
      CMP al,15
      MOV DX,2*9+160*9
      JB Sample_petit_4
      MOV DX,2*46+160*9
      SUB al,0Fh
Sample_petit_4:
      MOV bl,160
      MUL bl
      ADD AX,DX
      MOV DI,AX
      MOV ax,0F34h
      MOV Old_pos_4,DI
      STOSW

      RET
Rien_Centre Endp

Infomsg6 db '����������Volume�����Ŀ',0
Infomsg7 db '�  �                  �',0
Infomsg8 db '�����������������������',0

Affiche_tableau_volume Proc near

        MOV ah,05h
        MOV SI,offset Infomsg6
        MOV DI,2*7+160*3
        CALL Writelxy
        MOV SI,offset Infomsg7
        MOV DI,2*7+160*4
        CALL Writelxy
        MOV SI,offset Infomsg7
        MOV DI,2*7+160*5
        CALL Writelxy
        MOV SI,offset Infomsg7
        MOV DI,2*7+160*6
        CALL Writelxy
        MOV SI,offset Infomsg7
        MOV DI,2*7+160*7
        CALL Writelxy
        MOV SI,offset Infomsg8
        MOV DI,2*7+160*8
        CALL Writelxy
        RET
Affiche_tableau_volume ENDP

Infomsg9  db '   ������������������Ŀ',0
Infomsg10 db '   �                  �',0
Infomsg11 db '   ��������������������',0

Affiche_tableau_Pitch Proc near

           MOV SI,offset Infomsg9
           MOV DI,2*7+160*3
           MOV ah,05h
           CALL Writelxy
           MOV SI,offset Infomsg10
           MOV DI,2*7+160*4
           CALL Writelxy
           MOV SI,offset Infomsg10
           MOV DI,2*7+160*5
           CALL Writelxy
           MOV SI,offset Infomsg10
           MOV DI,2*7+160*6
           CALL Writelxy
           MOV SI,offset Infomsg10
           MOV DI,2*7+160*7
           CALL Writelxy
           MOV SI,offset Infomsg11
           MOV DI,2*7+160*8
           CALL Writelxy
           RET
Affiche_tableau_Pitch ENDP

Infomsg12 db '��������������P�riode��������Ŀ',0
Infomsg13 db '�   �                         �',0
Infomsg14 db '�������������������������������',0

Affiche_tableau_Periode Proc near

           MOV ah,07h
           MOV SI,offset Infomsg12
           MOV DI,2*41+160*3
           CALL Writelxy
           MOV SI,offset Infomsg13
           MOV DI,2*41+160*4
           CALL Writelxy
           MOV SI,offset Infomsg13
           MOV DI,2*41+160*5
           CALL Writelxy
           MOV SI,offset Infomsg13
           MOV DI,2*41+160*6
           CALL Writelxy
           MOV SI,offset Infomsg13
           MOV DI,2*41+160*7
           CALL Writelxy
           MOV SI,offset Infomsg14
           MOV DI,2*41+160*8
           CALL Writelxy
           RET
Affiche_tableau_Periode ENDP

Infomsg15 db '                                ',0

Efface_tableau_Periode Proc near
           XOR ah,ah
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*3
           CALL Writelxy
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*4
           CALL Writelxy
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*5
           CALL Writelxy
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*6
           CALL Writelxy
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*7
           CALL Writelxy
           MOV SI,offset Infomsg15
           MOV DI,2*41+160*8
           CALL Writelxy
           RET
Efface_tableau_Periode Endp

;�����������������������������������������������������������Ŀ
;�   Writelxy      Affiche un message dans la m�moire vid�o  �
;�     Entr�e                                                �
;�            SI:offset du message                           �
;�            DI:Adresse dans la m�moire vid�o               �
;�            AH:attribut                                    �
;�     Sortie Rien                                           �
;�     Change                                                �
;�������������������������������������������������������������

Writelxy Proc near

         LODSB
wr_Boucle_aff:
         STOSW
         LODSB
         OR al,al
         JNZ wr_boucle_aff
         RET
Writelxy Endp

;�����������������������������������������������������������Ŀ
;�   Curseur_off      Efface le curseur                      �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������

Curseur_off proc near
      MOV ah,01h
      MOV CX,0FFFFh
      INT 10h
      RET
Curseur_off endp
;�����������������������������������������������������������Ŀ
;�   Curseur_on      Affiche le curseur                      �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������

Curseur_on proc near
      MOV ah,01h
      MOV CX,0506h
      INT 10h
      RET
Curseur_on endp

;�����������������������������������������������������������Ŀ
;�   Init_ecran   Efface et initialise mode texte            �
;�     Entr�e      Rien                                      �
;�     Sortie      Rien                                      �
;�     Change      AX,BX,CX,DX,ES,SI,DI                      �
;�������������������������������������������������������������
init_ecran proc near
        MOV ax,0003h
        INT 10h
        RET
init_ecran endp

;�����������������������������������������������������������Ŀ
;�   Init_Var     Initialise les variables                   �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������

Chaine_mk db 'M.K.'
Tot_samp db 15

Param_err1 db 'Indiquez un nom de module !$'
Param_err2 db 'Param�tre incorrect$'
Param_err3 db 'Type de fichier incorrect$'
Utilisation_msg db 10,13
               db 'Utilisation: MODM MODULE[.MOD] [Param�tre]',10,10,13
               db 'Liste des Param�tres:',10,13
               db '    /BO=XX  Boucler X fois (/BO Boucler � l''infini)',10,13
               db '    /VG=XX  Volume G�n�ral (0-768)',10,13
               db '    /EN     Ecran noir (Pas de messages)',10,13
               db '    /EM     Utiliser l''�cran Monochrome',10,13
               db '    /F=XX   Fr�quence de sortie en Hz (3500-?)',10,13
               db '    /SD     Sauve les valeurs de /F et /VG dans MODM.DEF',10,10,13
               db '   ��������������Ŀ',10,13
               db '   �  That''s All  �',10,13
               db '   ����������������',10,10,13,'$'
Param_err4 db 'Fichier MODM.DEF inexistant',10,10,13
           db 'Tapez MODM /F=XX [/VG=XX] [/EM] /SD    Pour le cr�er',10,13,'$'
Sauve_msg db 'Sauve les Param�tres par d�faut',13,'$'
Instr_ajoute db 0
Adresse_table_volume dw 0
Volume_general dw 0
Table_Pattern db 256 dup (?)        ;Table d'adresse des pattern
Table_sequence db 128 dup (?)
Table_sample dw 31 dup (?)          ;Table d'adresse des sample
Table_sample_len db 62 dup (?)
Table_Repeat db 62 dup (?)
Table_Repeat_len db 62 dup (?)
Table_volume db 62 dup (?)
Compt_volume db 0

Volume db 17000 dup (?)

sample_name db 682 dup (?)

Init_Var  proc near

      MOV ds,debutfich       ;Source sur le d�but du fichier
      XOR SI,SI
      Push cs
      POP es
      MOV di,offset titre    ;Vers le titre
      CLD
      MOV cx,20              ;20 lettres � d�placer
      REP MOVSB

      MOV DI,offset chaine_mk
      MOV SI,438h
      MOV cx,4
      REPE CMPSB
      MOV instr_ajoute,0
      PUSH CS                ;DS a �t� chang�
      POP DS
      CMP CX,0
      JNE Pas_mk
      MOV mk,1

      MOV Nb_pos,3B6h        ;Change les adresses
      MOV Restart,3B7h       ;Pour fichier M.K.
      MOV Liste_patt,3B8h
      MOV Part,43Ch
      MOV tot_samp,31
      MOV instr_ajoute,16
Pas_mk:
      MOV nb_patt,0
      MOV si,Liste_patt      ;==>Cherche le nombre de pattern
      MOV di,nb_pos
      MOV ds,debutfich
      MOV cl,DS:[DI+1]                       ;**************
      MOV CS:[offset Pos_de_restart],cl      ;**************
      MOV cl,DS:[DI]         ;Nb de Position
      MOV CS:[offset tot_sequence],cl
      XOR ch,ch
      PUSH CS               ;CS -> DS
      POP DS
      MOV DI,offset table_sequence
Bo_patt:
      MOV ds,debutfich
      LODSB
      PUSH cs                ;CS -> DS
      POP ds
      CMP al,nb_patt
      JB patt_cont
      MOV nb_patt,al
Patt_cont:
      MOV cs:[di],al
      INC di
      LOOP Bo_patt

      MOV nb_reel_samp,0
      XOR ax,ax              ;==>Cherche Le dernier Sample
      XOR cx,cx
Debut_samp:
      PUSH AX
      CALL Sample_len
      CMP ax,0
      JE c_samp
      INC nb_reel_samp
      POP AX
      MOV cl,al
      PUSH AX
c_samp:
      POP AX
      INC al
      CMP al,tot_samp
      JNE debut_samp
      MOV nb_samp,cl

      PUSH CS
      POP DS
      MOV si,offset Table_sample_len
      MOV di,42
      MOV cl,Tot_Samp
      XOR ch,ch
      MOV ax,Debutfich
      MOV es,ax
Ecrire_table_len:
      MOV ax,es:[di]
      xchg ah,al
      SHL ax,1
      MOV ds:[si],ax
      INC si
      INC si
      ADD di,30
      LOOP Ecrire_table_len

      MOV si,offset Table_Repeat
      MOV di,46
      MOV cl,Tot_Samp
      XOR ch,ch
      MOV ax,Debutfich
Ecrire_table_rep:
      MOV ax,es:[di]
      XCHG ah,al
      SHL ax,1
      MOV ds:[si],ax
      INC si
      INC si
      ADD di,30
      LOOP Ecrire_table_rep

      MOV si,offset Table_Repeat_len
      MOV di,48
      MOV cl,Tot_Samp
      XOR ch,ch
      MOV ax,Debutfich
Ecrire_table_rep_len:
      MOV ax,es:[di]
      XCHG ah,al
      CMP ax,1
      JE Pas_de_repeat
      SHL ax,1
      MOV bx,es:[di-2]
      XCHG bh,bl
      SHL bx,1
      ADD ax,bx
      MOV ds:[si],ax
Pas_de_repeat:
      INC si
      INC si
      ADD di,30
      LOOP Ecrire_table_rep_len

      MOV si,offset Table_Volume
      MOV di,44
      MOV cl,Tot_Samp
      XOR ch,ch
      MOV ax,Debutfich
Ecrire_table_Vol:
      MOV ax,es:[di]
      MOV ds:[si],ax
      INC si
      INC si
      ADD di,30
      LOOP Ecrire_table_Vol

      RET

Init_Var  endp
;------------------------------------- Fin Init_Var -------

Coef dw 0
Volume_def dw 400

;�����������������������������������������������������������Ŀ
;�   Calcul_table_volume      Calculer la table              �
;�     Entr�e      Rien                                      �
;�     Sortie      Rien                                      �
;�     Change                                                �
;�������������������������������������������������������������

Calcul_table_volume Proc near

      ;*********** Table de convertion de volume ***********

      MOV ax,offset volume
      ADD ax,100h
      AND ax,1111111100000000b
      MOV Adresse_table_volume,ax
      MOV DI,ax                 ;ax offset de D�but de la table
      MOV Compt_Volume,0
      MOV ax,Volume_def
      MOV coef,ax          ;400
      CMP Volume_general,0
      JE Cal_vol
      MOV ax,Volume_general
      MOV coef,ax
Cal_vol:
      MOV ax,coef

Boucle_table_volume:
      MOV bl,Compt_volume
      XOR bh,bh
      MOV ax,bx
      MOV cx,coef              ;Ne pas mettre une valeur => a 1024
      MUL cx
      MOV bl,ah
      MOV cx,0FFFFh
Calcul_Table_vol:
      INC cx
      MOV ax,CX
                                ;Volume*256
      CBW                       ;Convertion de signe
      IMUL bx
      MOV CS:[di],ah
      INC di
      CMP CX,0FFh
      JNE Calcul_Table_vol
      INC Compt_volume
      CMP Compt_volume,41h
      JNE Boucle_table_volume
      RET
Calcul_table_volume Endp

;�����������������������������������������������������������Ŀ
;�   Sample_len   Calcule la longueur d'un Sample            �
;�     Entr�e      AL, Num�ro du sample                      �
;�     Sortie      AX, Longueur en Mot                       �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������

Sample_len  proc near
        MOV es,debutfich
        MOV bx,30
        MUL bl
        ADD ax,42
        MOV DI,ax
        MOV ax,ES:[DI]
        XCHG ah,al          ;L'amiga Place l'octet Fort au d�but
        RET
Sample_len endp

;�����������������������������������������������������������Ŀ
;�    Lire_def      Lire les Valeurs par d�faut              �
;�     Entr�e                                                �
;�     Sortie                                                �
;�     Change                                                �
;�������������������������������������������������������������

defname db 'MODM.DEF',0
Valeurs dw 0

Lire_def Proc near
      MOV ah,3Dh            ;==>Ouvrire le fichier
      MOV al,10000000b
      MOV dx,offset defname
      INT 21h
      MOV handle,ax
      JNC def_detourne1
      JMP def_err           ;Continuer si fichier ouvert
def_detourne1:
      MOV bx,handle         ;handle du fichier
      MOV ah,3Fh
      MOV cx,2
      MOV dx,offset Valeurs
      INT 21h
      JNC Charge_volume
      JMP def_err
Charge_volume:
      MOV ax,Valeurs
      MOV Volume_def,ax
      MOV bx,handle         ;handle du fichier
      MOV ah,3Fh
      MOV cx,2
      MOV dx,offset Valeurs
      INT 21h
      JNC Charge_adresse_video
      JMP def_err
Charge_adresse_video:
      MOV ax,Valeurs
      MOV Frequence_def,ax
      MOV bx,handle         ;handle du fichier
      MOV ah,3Fh
      MOV cx,2
      MOV dx,offset Valeurs
      INT 21h
      JNC Charge_def_fin
      JMP def_err
Charge_def_fin:
      MOV ax,Valeurs
      MOV Adresse_video_def,ax

      MOV bx,handle         ;handle du fichier
      MOV ah,3Eh            ;Ferme le fichier
      INT 21h

      RET
def_err:
      RET
Lire_def Endp

;�����������������������������������������������������������Ŀ
;�   Traiter_param   Execute la ligne de commande            �
;�     Entr�e      Rien                                      �
;�     Sortie      Carry:Erreur                              �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������


Param_cpt db 0
Param_tot db 0
Par db 3,1,'/BO',3,2,'/EN',3,4,'/VG',3,3,'/F=',3,5,'/SD',3,6,'/EM'
Type_de_param db 0
Sauve_valeurs db 0

Traiter_param Proc near
        CALL Parmtest
        CMP dl,0
        JNE Charger_nom
        CALL Intro
        WRITEL Utilisation_msg
        JMP tra_err
Charger_nom:
        MOV Type_de_module,0
        MOV Param_tot,dl
        MOV Param_cpt,0
        MOV DI,offset Partab
Boucle_param:
        MOV SI,[DI]
        PUSH DI
        CMP BYTE PTR [SI],'/'
        JE Parametre
        CALL Charger_nom_fichier
        JNC Pas_err_ch_fi
        JMP tra_err
Pas_err_ch_fi:
        JMP Continuer

Parametre:
        MOV off_ext,SI
        MOV DI,SI
Boucle_maj_pa:
        LODSB
        CMP al,0
        JE Continuer_comp_pa
        CMP al,40h
        JB par_chiffre
        AND al,11011111b          ;Minuscule => Majuscule
par_chiffre:
        STOSB
        JMP Boucle_maj_pa
Continuer_comp_pa:
        MOV SI,off_ext

        MOV DI,offset Par
        MOV Cpt_ext,0
        XOR ch,ch
Boucle_Compare_param:
        MOV cl,[DI]
        INC DI
        MOV dl,[DI]
        MOV Type_de_param,dl
        INC DI
        MOV SI,off_ext
Boucle_compare:
        LODSB
        CMP al,[DI]
        JNE Deplace_fin_param
        INC DI
        DEC CX
        CMP CX,0
        JNE Boucle_compare
        CMP CX,0
        JE Param_correcte
Deplace_fin_param:
        INC DI
        LOOP Deplace_fin_param
        INC Cpt_ext
        CMP Cpt_ext,6
        JNE Boucle_compare_param
        WRITEL Param_err2
        JMP Tra_err
Param_correcte:
        CALL Execute_param
        JNC Continuer
        JMP tra_err

Continuer:
        POP DI
        INC DI
        INC DI
        MOV bl,Param_tot
        INC Param_cpt
        CMP Param_cpt,bl
        JE Traitement_fini
        JMP Boucle_param
Traitement_fini:

        CMP Sauve_valeurs,1
        JNE Pas_sauve_valeurs
        WRITEL Sauve_msg
        CALL Ecrire_fich
        JC tra_err
Pas_sauve_valeurs:
        CALL Lire_def
        JNC Pas_err_def
        WRITEL Param_err4
        JMP Tra_err
Pas_err_def:

        CMP Type_de_module,0
        JNE Type_correcte
        CMP Sauve_valeurs,1
        JE Tra_err
        WRITEL Param_err1
        JMP tra_err
Type_correcte:

        MOV erreur_param,0
        RET
tra_err:
        MOV erreur_param,1
        RET
Traiter_param Endp

;�����������������������������������������������������������Ŀ
;�   Execute_param    Analyser le nom de fichier             �
;�     Entr�e      Rien                                      �
;�     Sortie      Carry:Erreur                              �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������

Execute_param Proc near
        MOV al,Type_de_param
        CMP al,1
        JNE Pas_param_1
        MOV Boucler,1
        MOV al,[SI]
        CMP al,'='
        JNE Pas_param_1
        INC SI
        MOV boucler,0
        CALL ASCIIBIN
        CMP ax,255
        JA Pas_param_1_err
        INC ax
        MOV nb_de_boucles,al
        MOV boucler,2
        JMP Fin_exec_param
Pas_param_1_err:
        JMP exec_pa_err
Pas_param_1:
        CMP al,2
        JNE Pas_param_2
        MOV Ecran_noir,1
        JMP Fin_exec_param
Pas_param_2:
        CMP al,3
        JNE Pas_param_3
        CALL ASCIIBIN
        CMP ax,3500
        JB Pas_param_3_err
        MOV frequence,ax
        JMP Fin_exec_param
Pas_param_3_err:
        JMP exec_pa_err
Pas_param_3:
        CMP al,4
        JNE Pas_param_4
        MOV al,[SI]
        CMP al,'='
        JNE Pas_param_4
        INC SI
        CALL ASCIIBIN
        CMP ax,768
        JAE Pas_param_4_err
        MOV Volume_general,ax
        JMP Fin_exec_param
Pas_param_4_err:
        JMP exec_pa_err
Pas_param_4:
        CMP al,5
        JNE Pas_param_5
        MOV Sauve_valeurs,1
        JMP Fin_exec_param
Pas_param_5:
        CMP al,6
        JNE Pas_param_6
        MOV Adresse_video,0B000h
        JMP Fin_exec_param
Pas_param_6:


Fin_exec_param:
        CLC
        RET
exec_pa_err:
        WRITEL ex_err_msg
        STC
        RET
Execute_param Endp
ex_err_msg db 'Valeur incorrecte',10,13,'$'
Freq_err db 'Utiliser le param�tre /F avec /SD$'

;�����������������������������������������������������������Ŀ
;�   Ecrire_fich   Ecrire le fichier MODM.DEF                �
;�     Entr�e      Rien                                      �
;�     Sortie      Carry:Erreur                              �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������

Ecrire_fich Proc near
        CMP Frequence,0
        JNE Freq_def
        WRITEL Freq_err
        JMP Ec_f_err
Freq_def:
        CMP Volume_general,0
        JNE Vol_def
        MOV Volume_general,250
Vol_def:
        MOV ah,3Ch
        MOV DX,offset defname
        XOR CX,CX
        INT 21h
        MOV handle,ax
        MOV ax,Volume_general
        MOV Valeurs,ax
        MOV ah,40h
        MOV BX,handle
        MOV CX,2
        MOV DX,offset Valeurs
        INT 21h
        MOV ax,Frequence
        MOV Valeurs,ax
        MOV ah,40h
        INT 21h
        MOV ax,Adresse_video
        MOV Valeurs,ax
        MOV ah,40h
        INT 21h


        MOV bx,handle         ;handle du fichier
        MOV ah,3Eh            ;Ferme le fichier
        INT 21h

        CLC
        RET
Ec_f_err:
        STC
        RET
Ecrire_fich Endp

;�����������������������������������������������������������Ŀ
;�   Charger_nom_fichier   Analyser le nom de fichier        �
;�     Entr�e      Rien                                      �
;�     Sortie      Carry:Erreur                              �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������


Extentions db 1,'MOD',0,2,'NST',0

Charger_nom_fichier Proc near
        MOV DI,offset filename
Boucle_charge_nom:
        LODSB
        CMP al,'.'
        JE Compare_ext
        CMP al,0
        JNE Cont_tsf
        JMP Fichier_mod
Cont_tsf:
        CMP al,':'
        JE cchiffre
        CMP al,40h
        JB cchiffre
        AND al,11011111b          ;Minuscule => Majuscule
cchiffre:
        STOSB
        JMP Boucle_charge_nom

Cpt_ext db 0
off_ext dw 0
off_car dw 0

Compare_ext:
        MOV off_car,DI
        MOV off_ext,SI
        STOSB
        MOV DI,SI
Boucle_maj:
        LODSB
        CMP al,0
        JE Continuer_comp
        AND al,11011111b          ;Minuscule => Majuscule
        STOSB
        JMP Boucle_maj
Continuer_comp:
        MOV SI,off_ext
        MOV DI,offset Extentions
        MOV Cpt_ext,0
Boucle_Compare_ext:
        MOV dl,[DI]
        MOV Type_de_module,dl
        INC DI
        MOV cx,4
        MOV SI,off_ext
        REPE CMPSB
        CMP CX,0
        JE Extention_correcte
Deplace_fin_ext:
        INC DI
        LOOP Deplace_fin_ext
        INC Cpt_ext
        CMP Cpt_ext,2
        JNE Boucle_compare_ext
        WRITEL Param_err3
        JMP Err_charge_n
Extention_correcte:
        MOV DI,off_car
        MOV SI,off_ext
        MOV al,'.'
        STOSB
        LODSB
        STOSB
        LODSB
        STOSB
        LODSB
        STOSB
        JMP Fin_Charge_nom
Fichier_mod:
        MOV al,"."
        STOSB
        MOV al,"M"
        STOSB
        MOV al,"O"
        STOSB
        MOV al,"D"
        STOSB
        MOV Type_de_module,1
Fin_Charge_nom:
        MOV al,0
        STOSB
        MOV al,10
        STOSB
        MOV al,13
        STOSB
        MOV al,'$'
        STOSB
        CLC
        RET
Err_charge_n:
        STC
        RET
Charger_nom_fichier Endp

;�����������������������������������������������������������Ŀ
;�   Charger_module     Charger le module en m�moire         �
;�     Entr�e      Rien                                      �
;�     Sortie      Carry:Erreur                              �
;�     Change      AX,BX,ES,DI                               �
;�������������������������������������������������������������

mem_libre dw 0
filename db 30 dup (?)
handle dw 0
ficherr db 'Le fichier ne peut �tre ouvert',10,13,'$'
fich_seg dw 0
cpt_patt db 0
cpt_samp db 0
cpt_table dw 0
err_mem db 'Fichier trop important pour tenir en m�moire',10,13,'$'
err_ch  db 'Erreur en lecture',10,13,'$'
ch_fichmsg db 'Charge le fichier $'

taille_fichh dw 0             ;Taille r�elle
taille_fichl dw 0             ;du fichier

Charge_module Proc near
      MOV ah,3Dh              ;==>Ouvrire le fichier
      MOV al,10000000b
      MOV dx,offset filename
      INT 21h
      MOV handle,ax
      JNC detourne1
      WRITEL ficherr
      JMP err_cm                 ;Continuer si fichier ouvert
detourne1:

      CALL reserve_mem        ;==>R�serve la m�moire
      JNC detourne3
      JMP err_cm
detourne3:
                              ;==>Calcul longueur du fichier
      MOV ah,42h
      MOV al,2                ;D�place par rapport � la fin du fichier
      MOV bx,handle           ;handle du fichier
      XOR cx,cx               ;D�placement de 0
      XOR dx,dx               ;donc donne la fin du fichier
      INT 21h
      ADD ax,500              ;Prendre des pr�cautions
      XOR bx,bx
      ADC dx,bx
      MOV taille_fichh,dx
      MOV taille_fichl,ax

      MOV ah,42h
      MOV al,0                ;D�place par rapport au d�but du fichier
      MOV bx,handle           ;handle du fichier
      XOR cx,cx               ;D�placement de 0
      XOR dx,dx
      INT 21h
                              ;==>Compare la taille du fichier et la
                              ;==>m�moire libre
      MOV ax,taille_fichh
      AND ax,0FFF0h           ;Regarde si fichier > � 1Mo
      OR ax,ax
      JNZ gros_fich
      MOV bx,mem_libre
      MOV cl,12               ;Compare dernier quartet de la m�moire
      SHR bx,cl               ;libre
      MOV ax,taille_fichh
      AND ax,000Fh            ;Avec Premier quartet de taille_fichh
      CMP bx,ax
      JA petit_fich           ;Plus de m�moire =>Petit Fichier
      MOV bx,mem_libre
      AND bx,0FFFh
      MOV ax,taille_fichl
      MOV cl,4
      SHR ax,cl
      CMP bx,ax
      JA petit_fich
      CMP bx,ax
      JB gros_fich
      MOV ax,taille_fichl     ;Compare le reste
      AND ax,000Fh
      OR ax,ax
      JZ Petit_fich
Gros_fich:
      WRITEL err_mem
      JMP err_cm
Petit_fich:

      CMP Ecran_noir,1
      JE Pas_aff_nom
      WRITEL ch_fichmsg
      WRITEL filename
Pas_aff_nom:
                              ;Charge Le Fichier
      CALL Prepare_mod
      JC err_cm
Ch_f_cm:
      CALL Charge_fich
      JC err_cm
      CALL Charge_samp
      CALL Calcul_table_volume
      CLC
      RET
err_cm:
      STC
      RET

Charge_module Endp

Prepare_mod Proc near
                             ;Charge Le Fichier
      MOV ax,debutfich
      MOV fich_seg,ax
      MOV bx,handle           ;Charge handle
      XOR DX,DX               ;Charge avec 0 dans l'offset
      MOV CX,43Ch             ;Charge Le d�but du Fichier
      PUSH ax
      POP ds
      MOV ah,3Fh
      INT 21h                 ;interruption du DOS
      JNC Mod_Continuer_lire
      JMP err_Prep_mod
Mod_Continuer_lire:
      PUSH CS
      POP DS
      CALL Init_var           ;Lire les infos

      CMP mk,1
      JE Charge_mk
      ADD fich_seg,26h        ;Se Place � un offset nul
      MOV ah,42h
      MOV al,0                ;D�place par rapport au d�but du fichier
      MOV bx,handle           ;handle du fichier
      XOR cx,cx               ;Se replace au d�but de la partition
      MOV dx,258h
      INT 21h
      JMP Fin_prep_mod
Charge_mk:
      ADD fich_seg,44h        ;Se Place � un offset nul
Fin_prep_mod:
      CLC
      RET

err_Prep_mod:
      WRITEL err_ch
 
      STC                 ;erreur
      RET
Prepare_mod Endp

;�����������������������������������������������������������Ŀ
;�   Charge_fich Charge le fichier en m�moire                �
;�     Entr�e      Rien                                      �
;�     Sortie                                                �
;�     Change      AX,BX,CX,DX,ES,SI,DI                      �
;�     Remarque    Utilise afficheb                          �
;�������������������������������������������������������������

Charge_fich proc near

Debut_charge:
      MOV al,Nb_patt
      INC al
      MOV cpt_patt,al         ;Initialise le compteur de Pattern
      MOV cpt_table,offset Table_pattern
      XOR DX,DX               ;Offset 0
      PUSH DS
      POP ES
Boucle_pattern:
      MOV di,cpt_table
      MOV ax,fich_seg       ;Sauve le segment du pattern
      PUSH CS
      POP ES
      STOSW
      MOV bx,handle         ;handle du fichier
      PUSH DS               ;Sauve DS
      PUSH fich_seg
      POP DS
      MOV ah,3Fh
      MOV cx,1024           ;1Ko Par Pattern
      XOR DX,DX
      INT 21h
      POP DS
      JNC Cont_ch_patt
      JMP err_charge
Cont_ch_patt:
      ADD Fich_seg,64       ;D�place le segment
      DEC cpt_patt
      JZ Debut_charge_samp
      ADD cpt_table,2
      JMP Boucle_pattern
Debut_charge_samp:

      MOV cpt_samp,0        ;Initialise le compteur de Sample
      MOV cpt_table,offset Table_sample
      XOR DX,DX             ;Offset 0
      PUSH CS
      POP ES
      INC nb_samp
Boucle_sample:
      MOV di,cpt_table
      MOV ax,fich_seg       ;Sauve le segment du pattern
      PUSH CS
      POP ES
      STOSW
      MOV al,cpt_samp
      CALL Sample_len
      SHL ax,1
      JC err_charge        ;Sample >=64 Ko
      MOV bx,handle        ;handle du fichier
      PUSH AX
      PUSH DS              ;Sauve DS
      PUSH fich_seg
      POP DS
      MOV CX,AX
      MOV ah,3Fh
      XOR DX,DX
      INT 21h
      POP DS
      POP AX
      JC err_charge
      SHR ax,1
      SHR ax,1
      SHR AX,1
      SHR AX,1
      INC AX
      ADD fich_seg,ax      ;D�place le segment
      INC cpt_samp
      MOV al,cpt_samp
      CMP al,nb_samp
      JE Fin_charge
      ADD cpt_table,2
      JMP Boucle_sample

fin_charge:
      MOV bx,handle         ;handle du fichier
      MOV ah,3Eh            ;Ferme le fichier
      INT 21h

      DEC nb_samp
      CLC                  ;Fichier charg�
      RET
                           ;Fin de charge_fich
err_charge:
      WRITEL err_ch
      JMP fin
fin:
      STC                 ;erreur
      RET

;�����������������������������������������������������������Ŀ
;� Reserve_mem R�serve Toute la M�moire disponible au DOS    �
;�                                                           �
;� Remarque: Inclus Dans charge_fich                         �
;�������������������������������������������������������������
Reserve_mem proc near

      MOV ah,48h
      MOV bx,0FFFFh
      INT 21h
      MOV mem_libre,bx        ;M�moire libre en paragraphe
                              ;R�server la m�moire
      MOV ah,58h
      MOV al,1
      MOV BX,2                ;Cherche bloc � partir du haut de la
      INT 21                  ;memoire
      MOV ah,48h              ;R�serve la m�moire disponible
      MOV bx,mem_libre
      INT 21h
      MOV debutfich,ax
      JC rerr
      CLC
      RET
rerr:
    STC
    RET
Reserve_mem endp

Charge_fich endp
;------------------------------------ Fin de charge_fich --

;-- PARMTEST : Saisir param�tres dans la ligne d'instruction -----------
;-- Entr�e   : DS:0000 = Adresse du PSP
;-- Sortie   : DL = Nombre de param�tres identifi�s
;-- Registres: AX, CX, DX, SI et FLAGS sont modifi�s
;-- Infos    : L'adresse de chaque param�tre est stock�e dans le tableau PARTAB
;--            comme adresse d'offset par rapport � DS. Un code ASCII 0 est
;--            en outre stock� � la suite de chaque param�tre.

partab  dw 63 dup (?)           ;Adresses des param�tres ligne d'instruction

parmtest  proc near

          PUSH CS
          POP ES
          mov  di,offset partab   ;Adresse de la table de param�tres
          cld                     ;Augmenter comptage pour instr. de cha�ne
          xor  dx,dx              ;Nombre de param�tres identifi�s
          mov  si,80h             ;Adresse � laquelle figure le nombre
                                  ;de caract�res de la ligne d'instruction
          mov  cl,byte ptr [si]   ;Lire nombre de caract�res
          or   cl,cl              ;Les param�tres ont-ils �t� transmis ?
          je   parmtend           ;NON --> Fin

          inc  si                 ;SI d�signe le d�but de la ligne d'instruction
          xor  ch,ch              ;Dans CX figure le nombre de caract�res
cherc:    lodsb                   ;Amener caract�re suivant dans AL
          cmp  al," "             ;Est-ce un espace ?
          je   espac              ;OUI --> ESPAC
          cmp  al,TAB             ;Est-ce un caract�re de tabulation ?
          je   espac              ;OUI --> ESPAC

          ;-- Ni espace ni tabulation ----------------------------------

          or   dh,dh              ;Le dernier caract�re �tait-il un espace ?
          jne  nextc              ;NON --> Traiter caract�re suivant

          inc  dl                 ;Incr�menter nombre de param�tres trouv�s
          not  dh                 ;Indique que ni " " ni TAB
          mov  ax,si              ;Adresse du param�tre
          dec  ax                 ;calculer
          stosw                   ;Sauver dans table de param�tres
nextc:    loop cherc              ;Lire caract�re suivant
          mov  byte ptr [si],0    ;Fixer caract�re NUL comme fin de param�tres

parmtend: ret                     ;Retour au programme d'appel

espac:    or   dh,dh              ;Le dernier caract�re �tait-il un espace ?
          je   nextc              ;OUI --> Traiter caract�re suivant

          ;-- Param�tre suivant identifi� ------------------------------

          xor  dh,dh              ;Ce caract�re �tait un espace
          mov  byte ptr [si-1],0  ;Fixer caract�re NUL comme fin de param�tres
          jmp  short nextc        ;Traiter caract�re suivant

parmtest endp

;-- ASCIIBIN : Convertir nombre ASCII en binaire (16 bits maxi) --------
;-- Entr�e   : DS:SI = Adresse du nombre � convertir en format ASCII
;-- Sortie   : AX = Le nombre converti
;--            Flag Carry = 1 : Nombre trop grand
;-- Registres: AX, BX, CX, SI et FLAGS sont modifi�s
;-- Infos    : La cha�ne ASCII doit �tre termin�e par le code 0

asciibin  proc near

          xor  bh,bh              ;Octet fort de chaque chiffre
          mov  cx,10              ;Nous travaillons en syst�me d�cimal
          xor  ax,ax              ;R�sultat jusqu'ici
ab_chi:   mov  bl,[si]            ;Lire chiffre suivant
          or   bl,bl              ;Code NUL (Fin) ?
          je   ab_fin             ;OUI --> Nombre converti sans probl�me
          cmp  bl,"0"             ;Tester si chiffre
          jb   ab_ret             ;NON --> erreur
          cmp  bl,"9"             ;Tester si chiffre
          ja   ab_err             ;NON --> erreur
          mul  cx                 ;Nombre calcul� jusqu'ici * 10
          jc   ab_ret             ;Nombre > 65535 --> Erreur
          and  bl,1111b           ;Convertir chiffre en binaire
          add  ax,bx              ;Ajouter au nombre ant�rieur
          inc  si                 ;Traiter chiffre suivant
          jmp  short ab_chi

ab_fin:  clc                      ;Pas d'erreur
          ret                     ;Retour au programme d'appel

ab_err:   stc                     ;Erreur
ab_ret:   ret                     ;Retour au programme d'appel

asciibin  endp
;�����������������������������������������������������������Ŀ
;�     Efface_ligne  Efface une ligne                        �
;�     Entr�e      AH:Ligne                                  �
;�                 AL:Attribut de la ligne                   �
;�     Sortie      Rien                                      �
;�     Change      AX,BX,ES,SI                               �
;�������������������������������������������������������������

Efface_ligne Proc near

      MOV bx,Adresse_video ;0B800h
      MOV es,bx
      MOV bl,160     ;160 Octets par ligne
      XOR bh,bh
      PUSH AX
      MOV al,ah
      XOR ah,ah
      MUL bl
      MOV SI,ax
      POP AX
      XOR bx,bx
      MOV ah,al
      MOV al,20h
Boucle_eff_l:
      MOV ES:[SI],ax
      INC SI
      INC SI
      INC bx
      CMP bx,80
      JB Boucle_eff_l
      RET
Efface_ligne endp

;-- BIA : Convertir binaire en ASCII et afficher -----------------------
;-- Entr�e   : AL = le nombre � convertir
;-- Sortie   : Aucune
;-- Registres: CX, AX, DL et FLAGS sont modifi�s

bia       proc near
          CMP al,100
          JAE bia_sup
          MOV WORD PTR ES:[DI-2],0
          mov  cl,10              ;Nous travaillons en syst�me d�cimal
          xor  ah,ah              ;Pr�parer division 16 bits
          div  cl                 ;Diviser AX par CL
          or   ax,3030h           ;Convertir r�sultat en ASCII
          push ax                 ;Ranger nombre
          MOV ah,0Fh
          STOSW
          pop  ax                 ;Retirer nombre
          mov  al,ah              ;Amener caract�re dans AL
          MOV ah,0Fh
          STOSW
          ret                     ;Retour au programme d'appel
bia_sup:
          PUSH ax
          MOV ax,0F31h
          MOV ES:[DI-2],ax
          POP ax
          sub ax,100
          mov  cl,10              ;Nous travaillons en syst�me d�cimal
          xor  ah,ah              ;Pr�parer division 16 bits
          div  cl                 ;Diviser AX par CL
          or   ax,3030h           ;Convertir r�sultat en ASCII
          PUSH ax
          MOV ah,0Fh
          STOSW
          POP AX
          mov  al,ah              ;Amener caract�re dans AL
          MOV ah,0Fh
          STOSW

          RET
bia       endp


;�����������������������������������������������������������Ŀ
;�     Affiche_p_xy Affiche la valeur dans AX en HEXA        �
;�     Entr�e      AX                                        �
;�                 DI:Position x,y  (2*x+160*y)              �
;�     Sortie      Rien                                      �
;�     Change      AX,BX,DX,ES                               �
;�     Remarque    Utilise afficheb                          �
;�������������������������������������������������������������
Affiche_p_xy Proc near
      PUSH AX
      MOV al,ah
      AND al,0Fh          ;Reste  de la division par 2^4
      ADD al,90h          ;Remplace
      DAA                 ;al
      ADC al,40h          ;par carract�re
      DAA                 ;ASCII

      MOV ah,0Fh
      STOSW
      POP AX
      CALL affichebxy
      RET
Affiche_p_xy Endp
;�����������������������������������������������������������Ŀ
;�     Affichedbxy Affiche la valeur dans AX en HEXA         �
;�     Entr�e      AX                                        �
;�                 DI:Position x,y  (2*x+160*y)              �
;�     Sortie      Rien                                      �
;�     Change      AX,BX,DX,ES                               �
;�     Remarque    Utilise afficheb                          �
;�������������������������������������������������������������
affichedbxy PROC
        PUSH ax
        MOV al,ah
        CALL AFFICHEBXY
        POP ax
        CALL AFFICHEBXY
        RET
affichedbxy ENDP
;�����������������������������������������������������������Ŀ
;�     Affichebxy   Affiche la valeur dans AL en HEXA        �
;�     Entr�e     AL                                         �
;�                DI:Position x,y  (2*x+160*y)               �
;�     Sortie     Rien                                       �
;�     Change     AX,BX,DX,ES                                �
;�������������������������������������������������������������
affichebxy PROC

      PUSH AX
      MOV ax,Adresse_video ;0B800h
      MOV es,ax
      POP AX
      PUSH ax             ;Valeur a afficher
      SHR al,1
      SHR al,1            ;Divise par 64
      SHR al,1
      SHR al,1
      ADD al,90h          ;Remplace
      DAA                 ;al
      ADC al,40h          ;par carract�re
      DAA                 ;ASCII

      MOV ah,0Fh
      STOSW

      POP AX
      AND al,0Fh          ;Reste  de la division par 2^4
      ADD al,90h          ;Remplace
      DAA                 ;al
      ADC al,40h          ;par carract�re
      DAA                 ;ASCII

      MOV ah,0Fh
      STOSW
      RET                 ;Redonne la main
affichebxy ENDP



;------------------------------------- Fin afficheb -------

;----------------- Variables

Debut_msg db 'Mod Master V1.02',10,13
          db '(c) 1993-2019 Freddy V�tel�',10,10,13,'$'

init:    MOV ah,4Ah
         MOV bx,offset Pfin
         MOV cl,4
         SHR bx,cl
         INC bx
         INT 21h
         MOV ax,offset pfin     ;
         SHR ax,1               ;
         SHL ax,1               ;
         MOV sp,ax              ;offset Pfin
         JMP debut

;== Pile ==================================
         dw 512  dup (?)

PFin equ this byte

CODE ENDS
END START


; Supported commands with *
;* 0 Arpeggio
;* Cmd 1. Portamento up
;* Cmd 2. Portamento down
;* Cmd 3. Tone portamento
;* Cmd 4. Vibrato
;* Cmd 5. Tone portamento + volume slide
;* Cmd 6. Vibrato + volume slide
;Cmd 7. Tremolo
;Cmd 9. Set sample offset
;* Cmd A. Volume slide
;* Cmd B. Position jump
;* Cmd C. Set volume
;* Cmd D. Pattern break
;* F
