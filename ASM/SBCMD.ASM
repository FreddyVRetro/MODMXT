;            ���������������������������������������������������ͻ
;            �     ��������������� SBCMD.INC ���������������     �
;            �                                                   �
;            �           --==�� Mod Master v2.1 ��==--           �
;            ���������������������������������������������������ĺ
;            �   Auteur                         Freddy Vetele    �
;            �                                                   �
;            �   Derniere modification          30/03/2022       �
;            ���������������������������������������������������ͼ


T_SB1  EQU 1 ;Sound Blaster 1.0
T_SB15 EQU 2 ;Sound Blaster 1.5
T_SB2  EQU 3 ;Sound Blaster 2.x
T_BB   EQU 4 ;BlasterBoard
T_BB2  EQU 5 ;BlasterBoard 2
T_SBP  EQU 6 ;Sound Blaster Pro
T_SBP2 EQU 7 ;Sound Blaster Pro 2.x
T_SB16 EQU 8 ;Sound Blaster 16


Commande_DSP  DB 0
Frequence_DSP DB 0

;-----------------------------------------------------------
;
;              Routines pour la Sound Blaster
;
;-----------------------------------------------------------

SB_DSP_Init PROC NEAR

        MOV DX,SB_BasePort
        ADD DX,6
        MOV AL,1
        OUT DX,AL
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        IN AL,DX
        XOR AL,AL
        OUT DX,AL
        MOV AL,0D1h       ; Active le HP
        CALL SB_DSP_Write
        RET
		
SB_DSP_Init ENDP

Fixer_stereo PROC NEAR

        MOV AL,0Eh
        MOV DX,SB_BasePort
        ADD DX,4           ; MixAddrPort  (2x4h)
        OUT DX,AL          ; Register 0Eh
        INC DX
        IN AL,DX           ; Lecture registre 0Eh
        OR AL,2            ; Bit 1 � 1
        MOV AH,AL
        MOV AL,0Eh
        DEC DX
        OUT DX,AL
        INC DX
        MOV AL,AH
        OUT DX,AL          ; Sortie registre 0Eh
        RET

Fixer_stereo ENDP

; Set the Stereo, for Sound Blaster Pro
Stop_stereo PROC NEAR

        MOV AL,0Eh
        MOV DX,SB_BasePort
        ADD DX,4           ; MixAddrPort  (2x4h)
        OUT DX,AL
        INC DX
        IN AL,DX           ; Register 0Eh
        AND AL,11111101b   ; Bit 1 � 0
        MOV AH,AL
        MOV AL,0Eh
        DEC DX
        OUT DX,AL
        INC DX
        MOV AL,AH
        OUT DX,AL
        RET
Stop_stereo ENDP

Attendre_SB PROC NEAR

        MOV DX,SB_BasePort
        ADD DX,0Ch          ;DSPWritePort
        XOR CX,CX           ;Try 65536 Times
bo_att_SB:
        IN AL,DX
        OR AL,AL
        JNS Fin_bo_att_SB
        LOOP bo_att_SB
        MOV Erreur_Modm,Err_SB  ;Sound Blaster Timeout...
;        MOV Stopper_Sortie,1    ;Stop the music
;        CALL SB_DSP_Init
Fin_bo_att_SB:
        RET

Attendre_SB ENDP

;-----------------------------------------------------------
;    SB_DSP_Write    Sortie d'une commande vers le DSP
;
;    Input: AL Command
;-----------------------------------------------------------

SB_DSP_Write PROC Near
        CMP Erreur_Modm,Err_SB
        JE Pas_SB_DSP_Write
        PUSH CX
        PUSH AX
        CALL Attendre_SB
        POP AX
        OUT DX,AL
        POP CX
Pas_SB_DSP_Write:
        RET
SB_DSP_Write Endp

; Type de commande en fonction de la carte :
;
;           Non continu    Continu
; SB 1.0       14h           N/A  DSP 1.x  ; No more supported.
; SB 1.5       14h           1Ch  DSP 2.0
; SB 2.0       91h           90h  DSP 2.1
; SBPro        91h           90h  DSP 3.x
; SB 16        91h                DSP 4.x
; BB 2

SB_Start PROC NEAR

;        CMP DMA_Continu,0       ; Not Autoinit DMA -> Command 14h
;        JE Commande_DMA_14h   ; ( Car envoi de la taille avec 48h )
		
        CMP Type_SB,T_SB15
        JAE SB_Start_Autoinit ; Sound blaster 1.5+ => Comme la SBpro :)

        MOV Erreur_Modm,Err_SB  ;Sound Blaster Timeout...
;        MOV Stopper_Sortie,1    ;Stop the music

        RET

Commande_DMA_14h: ; No more active for the moment. (For SB 1.0)

;        MOV AL,40h               ;Send the Frequency (SB/SBP/BB)
;        CALL SB_DSP_Write
;        MOV AL,SB_DMA_Frequency
;        CALL SB_DSP_Write

;        MOV Commande_DSP,014h
;		MOV AL,14h               ;DSP 14h : Not Continuous Slow DMA
;        CALL SB_DSP_Write

;        MOV AX,Buffer_Byte_Size
;        DEC AX
;        MOV AX,CX
;        CALL SB_DSP_Write        ;Envoyer Buffer_Samples_Nb-1
;        XCHG AH,AL
;        CALL SB_DSP_Write

        RET

SB_Start_Autoinit:

;Load/Adjust the Output Buffers Size
        MOV CX,Buffer_Byte_Size
	CMP Out_16Bit,0      ; Output in 16 Bit ?
        JE Pas_BuffSB_16
        SHR CX,1             ; 16Bit > Size sent to the SB /2
Pas_BuffSB_16:
        DEC CX               ; CX, Taille du tampon...
		
; ** 1) Send the frequency **

        CMP Type_SB,T_SB16 
	JNE Use_SbFrequency
        CMP Mix_Mono_Use_Left,1  ; 16Bit to 8bit is always unsigned (SB16 command is alyays signed)
	JE Use_SbFrequency
; For SB16 Only
        MOV  AL,041h             ; DSP 41h : Set Frequency
	MOV Frequence_DSP,AL
        CALL SB_DSP_Write
        MOV  AX,Real_Frequency
        XCHG AL,AH
        CALL SB_DSP_Write
        MOV  AL,AH
        CALL SB_DSP_Write
		
		JMP Skip_SBFrequency
Use_SbFrequency:
; For SB, BB, SBPro (BlasterBoard always use SB Frequency)	
        MOV AL,40h             ; DSP 40h : Set Frequency
		MOV Frequence_DSP,AL		
        CALL SB_DSP_Write      ; (SB 2.0/SB Pro)
        MOV AL,SB_DMA_Frequency
        CALL SB_DSP_Write      ; Write the Frequency		
Skip_SBFrequency:

; ** 2) Send the Output command **

; ** Autoinit DMA 8 Bit Unsigned DSP >= 1.5
        CMP Type_SB,T_BB2
		JE Start_SB16_Autoinit

        MOV Commande_DSP,1Ch       ; 8 Bit Autoinit DMA (SB 1.5)
        CMP Type_SB,T_SB15         ; SB 1.5
        JE Start_SBSBPro_Autoinit

        MOV Commande_DSP,90h       ; 8 Bit Autoinit DMA High Speed (SB2.0 SBPro)
        CMP Type_SB,T_SB16 
        JNE Start_SBSBPro_Autoinit ; Command DSP <=4
		
; SB16
Start_SB16_Autoinit:

        CMP Mix_Mono_Use_Left,1  ; 16Bit to 8bit is always unsigned so do SB/SBPro command
		JE Start_SBSBPro_Autoinit

; ** Autoinit High Speed DMA 8 Bit Signed DSP >= 4.00 (SB16 or more) **

        MOV AL,0C6h              ; DSP C6h : 8Bit DMA Output
If UseMix16 Eq Yes	
		CMP Out_16Bit,0          ; Output in 16 Bit ?
		JE Use_SB16_Signed8
		MOV AL,0B6h              ; Yes -> DSP B6h : 16Bit DMA Output
Use_SB16_Signed8:
EndIf
                                 ; 8/16 Bit Autoinit DMA High Speed Output (SB16)
		MOV Commande_DSP,AL
        CALL SB_DSP_Write
        MOV  AL,010h             ; 10h : Mono Signed (Bit 4 Signed/Unsigned,  Bit 5 Stereo/Mono)
        CMP  Utilise_Stereo,1
        JNE  @@nostereo
        MOV  AL,020h             ; 20h: Stereo Signed
@@nostereo:
        CALL SB_DSP_Write        ; write 2nd command byte
        MOV  AL,CL               ; lower part of size
        CALL SB_DSP_Write
        MOV  AL,CH               ; higher part of size
        CALL SB_DSP_Write

        JMP Fin_SB_StartPro

;** Autoinit High Speed DMA 8 Bit UnSigned DSP < 4.00 **
Start_SBSBPro_Autoinit:

        MOV AL,48h             ; DSP 48h : Write the Size
        CALL SB_DSP_Write
        MOV AX,CX
        CALL SB_DSP_Write      ; Partie basse de la taille
        XCHG AH,AL
        CALL SB_DSP_Write      ; Partie haute de la taille

        MOV  AL,Commande_DSP
        CALL SB_DSP_Write      ; Lancer la commande Sortie DMA
                               ; Auto Initialis�e (Sortie continue)
Fin_SB_StartPro:
        RET

SB_Start ENDP

Restart_DMA_NC_SB Proc Near

        CALL Programmer_DMA

        MOV AL,14h
        CALL SB_DSP_Write
		
        MOV AX,Buffer_Byte_Size    ; Commande 14h => Pas Stereo (Taille simple) 
        DEC AX
        CALL SB_DSP_Write
        XCHG AH,AL
        CALL SB_DSP_Write

        RET
Restart_DMA_NC_SB Endp


;-----------------------------------------------------------------
;   SB_ComputeFrequency   Calculs pour sortie DMA
;                    sur Sound Blaster
;-----------------------------------------------------------------

SB_ComputeFrequency PROC NEAR
                             ;Calculer l'octet a envoyer to la SB
        CMP Type_SB,T_SB16
		JE SB_ComputeFrequency_End ;The Sound Blaster 16 use the real frequency
		; OK for BB2 as it does not use the real frequency
		
	    PUSH AX
        MOV DX,15            ;(1000000/65536)  Valeurs pour Mono
        MOV AX,16960         ;(1000000 MOD 65536)
        CMP Utilise_Stereo,1
        JNE  Pas_Calc_Stereo1
        MOV DX,7             ;(500000  /  65536)  ; Valeurs pour Stereo
        MOV AX,41248         ;(500000 MOD 65536)
Pas_Calc_Stereo1:
        POP BX               ;BX=Out_Frequency
        DIV BX
        MOV BX,256           
        SUB BX,AX            ;BX=256-1000000/fr�quence
        MOV SB_DMA_Frequency,BL
                             ;Valeurs pour calculer la fr�quence
                             ;des samples (Utilise la fr�quence r�elle SB)
        XOR BH,BH
        MOV AX,BX
        MOV BX,256           ;AX=Freq_DMA
        SUB BX,AX            ;BX=256-Freq_DMA
        MOV DX,15            ;(1000000  /  65536)  ; Valeurs pour Mono
        MOV AX,16960         ;(1000000 MOD 65536)
        CMP Utilise_Stereo,1
        JNE  Pas_Calc_Stereo2
        MOV DX,7             ;(500000  /  65536)   ; Valeurs pour Stereo
        MOV AX,41248         ;(500000 MOD 65536)
Pas_Calc_Stereo2:
        DIV BX               ;AX=1000000/256-Freq_DMA

SB_ComputeFrequency_End:
        RET

SB_ComputeFrequency ENDP
