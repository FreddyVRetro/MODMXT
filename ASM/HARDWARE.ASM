
; Procedures in this file:

;Save_Timer_IRQ
;Restore_Timer_IRQ
;Sauver_EMS
;Placer_Pages_EMS
;Calcul_Adresse_DMA
;Taille_DMA
;DMA8_ReadOffset
;Init_DMA
;Enable_IRQ
;Disable_IRQ
;Detourne_IRQ
;Set_Timer0_Period

; Sept 2022 : Removed Mod Master variables

HW_DMA_Buffer_Offset  DW 0
HW_DMA_Buffer_Page    DB 0

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

;-------------------------------------------------------------
;|                    EMS Code                               |
;-------------------------------------------------------------

;Sauver_EMS Proc Near
;        MOV Previous_EMS_Handle,-1    ; Pour �viter d'acc�der 2 fois de suite
;        MOV DX,Pascal_Handle_EMS      ; au m�me handle.
;        MOV AH,47h                    ; Save page Map content
;        INT 67h
;NotSaveEMS:		
;        RET
;Sauver_EMS Endp

;Recuperer_EMS Proc Near
;        MOV DX,Pascal_Handle_EMS
;        MOV AH,48h                    ; Restore Page Map content
;        INT 67h
;        RET
;Recuperer_EMS EndP

;-------------------------------------------------------------
;|  Placer_Pages_EMS: Acceder � un handle EMS                |
;|                                                           |
;|  Input: DX: EMS Handle number, Verify if not -1 Before    |
;|         CL: Nb of pages (1..4)                            |
;|                                                           |
;-------------------------------------------------------------

Previous_EMS_Handle DW 0
;Nb_Pages_EMS DB 0

Placer_Pages_EMS Proc Near

        CMP DX,Previous_EMS_Handle
        JE  Already_Configured       ; Same EMS Handle as before (Do not set)
        MOV Previous_EMS_Handle,DX

        PUSH BX

        XOR CH,CH
Boucle_Placer_Pages1:                ; Boucle pour les pages EMS
        MOV BX,CX                    ; BX: Logical page Number
        DEC BX
        MOV AX,BX                    ; AL, N?Page Physique
        MOV AH,44h                   ; Fonction 44h
        INT 67h                      ; Appel IRQ 67h
        LOOP Boucle_Placer_Pages1

        POP BX
Already_Configured:
        RET
Placer_Pages_EMS Endp

;-------------------------------------------------------------
;|                    DMA Code                               |
;-------------------------------------------------------------


;�����������������������������������������������������������Ŀ
;�         -= Calculer les adresses des tampons =-           �
;�������������������������������������������������������������

; Input : DX: DMA Buffer @ Segment
;         AX: DMA Buffer @ Offet
;         Seg_Volume : DMA Buffer @ Segment
Calcul_Adresse_DMA Proc Near
        MOV BX,AX        ; Calcul Adresses Tampon

		PUSH AX			    
        MOV CL,4         ; Pour le DMA
	    SHR BX,CL				
        MOV AX,DX
        ADD AX,BX        ; (Segment + Offset SHR 4)
        MOV CL,4
	    SHR AX,CL
                         ; AH = (Segment + Offset SHR 4) SHR 12
; DMA Page
        MOV HW_DMA_Buffer_Page,AH

        MOV AX,DX
        POP BX
        MOV CL,4
	    SHL AX,CL					
        ADD AX,BX        ; AX=Segment SHL 4 + Offset
; DMA Offset
		MOV HW_DMA_Buffer_Offset,AX

        RET
Calcul_Adresse_DMA Endp

Ifdef Mod_Master

Taille_DMA Proc Near      ;Routine pour le test
    XOR  AL,AL
    OUT  0Ch,AL           ; clear flipflop
    MOV  dl,DMA_SB8       ; DMA 1
    XOR  DH,DH
    SHL  DX,1
    INC  DX               ; DX = Channel * 2 + 1 = base counter
    IN   AL,DX            ; AL = Lower byte
    MOV  BL,AL
    IN   AL,DX            ; AL = Higher byte
    MOV  BH,AL
    MOV  AX,BX            ; AX = high and low part together ;) - return that
                          ; bytes left to send = ax + 1
    RET
Taille_DMA Endp
endif

DMA_Channel      DB 0   ; Currently used DMA Channel (Use only one at a time)
DMA_Channel_Mask DB 0

DMA_PAGE        db 087h,083h,081h,082h,08Fh,08Bh,089h,08Ah ; page register
DMA_ADDR        db 000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh ; base adddress
DMA_CNT         db 001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh ; base count

DMA_STAT   db 008h,0D0h        ;* read status register *;
DMA_CMD    db 008h,0D0h        ;* write command register *;
DMA_REQ    db 009h,0D2h        ;* write request register *;
DMA_MASK   db 00Ah,0D4h        ;* write single bit register *;
DMA_MODE   db 00Bh,0D6h        ;* write mode register *;
DMA_CLRFF  db 00Ch,0D8h        ;* clear byte ptr flip;flop *;
DMA_MCLR   db 00Dh,0DAh        ;* master clear register *;
DMA_CLRM   db 00Eh,0DCh        ;* clear mask register *;
DMA_WRTALL db 00Fh,0DEh        ;* write all mask register *;

DMA_PAGE_P DB 0
DMA_ADDR_P DB 0
DMA_CNT_P  DB 0

; Program the 8237 DMA Controller (DMA Channel 0 to 7)
; Mode : Autoinit, Single
; Change AX, BX, DX 
; Input : HW_DMA_Buffer_Page : HW_DMA_Buffer_Offset = Buffer Address
;         Buffers_Total_Size_Byte
;         DMA_Channel : DMA Channel
;         CX: DMA Buffer Size

Programmer_DMA PROC NEAR
PUSH DS
PUSH CS
POP DS
        XOR DX,DX                      ; Clear IO Number High Byte
		XOR BX,BX
        MOV BL,DMA_Channel
        MOV AL,BL
		AND AL,03h
		MOV DMA_Channel_Mask,AL

        XOR DX,DX

        MOV AL,DMA_PAGE[BX]
        MOV DMA_PAGE_P,AL   ; Page Register
        MOV AL,DMA_ADDR[BX]
		MOV DMA_ADDR_P,AL   ; Address Register
        MOV AL,DMA_CNT[BX]
		MOV DMA_CNT_P,AL    ; Count Register

        SHR BX,1
		SHR BX,1            ; DMA Controller Number -> BX
		
        ; -----  set channel mask register ------
        XOR DX,DX
		MOV AL,DMA_Channel_Mask
        ADD AL,4                      ;Port[$0A]:=4+DMA
		MOV DL,DMA_MASK[BX]
        OUT DX,AL                     ;Set DMA Channel Mask (Disable)

        ; ----- set mode register ------		
        MOV AL,58h                    ; 0101 10xx
        ADD AL,DMA_Channel_Mask       ;=58h+DMA
		MOV DL,DMA_MODE[BX]
        OUT DX,AL		

        ; ------  clear MSB/LSB flip flop -----------
        CLI
		XOR AL,AL
		MOV DL,DMA_CLRFF[BX]
        OUT DX,AL                     ;Clear Flip Flop (0Ch)

        ;---- set byte count register ----
        MOV AX,CX                    ;Number of Bytes/Word to send
		CMP DMA_Channel,4
		JB DMA_SetSize_NoDiv2
		SHR AX,1                     ;16 Bit DMA : Size/2
DMA_SetSize_NoDiv2:
        DEC AX                       ;Number Minus one
		MOV DL,DMA_CNT_P
        OUT DX,AL                    ;Charge la taille du tampon
        XCHG AH,AL
        OUT DX,AL

        ;---- set channel base address ---
		MOV AX,HW_DMA_Buffer_Offset
		CMP DMA_Channel,4
		JB DMA_SetAddr_NoDiv2
                                     ;16 Bit DMA: Divide Page and Offset by 2
        MOV CL,HW_DMA_Buffer_Page
		SHR CL,1                     ;Page /2
		RCR AX,1                     ;Offset/2 with page remain
DMA_SetAddr_NoDIV2:
		MOV DL,DMA_ADDR_P
        OUT DX,AL                    ;Send the Offset low Byte
        XCHG AH,AL
        OUT DX,AL

		MOV DL,DMA_PAGE_P            ;Page is the same in 8 and 16 Bit
		MOV AL,HW_DMA_Buffer_Page
        OUT DX,AL                    ;Send the Page number

        STI
		
        ; -----  clear channel (mask register) ------
        MOV AL,DMA_Channel_Mask    
        MOV DL,DMA_MASK[BX]          ;Mask Port > DMA
        OUT DX,AL                    ;Clear DMA Channel Mask (Enable)

POP DS
        RET

Programmer_DMA ENDP

;	CLI
;	MOV	AL,0FFh		; clear byte pointer flip/flop
;	OUT	0Ch,AL
;	JMP	$+2
;	IN	AL,2		; read low byte of address (throw it away)
;	JMP	$+2
;	IN	AL,2		; read high byte of address
;	STI

; Used by the Tandy DAC code, to check the current playing @
; Input DL: DMA Channel (0-3)
; Output AX: Offset in the page (64Kb Blocks)
DMA8_ReadOffset Proc Near
    PUSH BX
    XOR  AL,AL
    OUT  0Ch,AL         ; clear flipflop
	JMP	$+2             ; Add a small delay (Needed ?)
    XOR  DH,DH
    SHL  DX,1
                        ; dx = channel * 2 = Offset Register
    IN   AL,DX          ; al = lower byte
	JMP	$+2	            ; Add a small delay (Needed ?)
    MOV  BL,AL
    IN   AL,DX          ; al = higher byte
    MOV  BH,AL
    MOV  AX,BX          ; AX = high and low part together ;) - return that

	POP BX
	RET
DMA8_ReadOffset Endp

; For Debug
Affiche_DMA_Addr Proc Near
      ;Writech'@'
;       MOV DL,DMA_Channel
;       CALL DMA8_ReadOffset
;       CALL WritewordH
       RET
Affiche_DMA_Addr Endp

;-------------------------------------------------------------
;|                                                           |
;|         Routines pour la gestion des interruptions        |
;|                                                           |
;-------------------------------------------------------------

HW_Anc_21 DB 0
HW_Anc_A1 DB 0

;-------------------------------------------------------------
;| Activer l'Irq a l'aide des ports 21h et A1h               |
;| Input : AL : IRQ Number                                   |
;-------------------------------------------------------------

Enable_IRQ PROC NEAR      ;Autoriser l'IRQ grace au contr�leur d'IRQ
        CLI
        MOV BL,AL
		IN AL,21h     ;Activer l'IRQ
        MOV CS:HW_anc_21,AL ;Save the Original value

        CMP BL,7
        JA Enable_IRQ8
        MOV CL,BL
        MOV AH,1
        SHL AH,CL
        NOT AH       ;Si IRQ7 => 01111111b
        AND AL,AH    ;01111111b
        OUT 21h,AL
        STI
        RET
Enable_IRQ8:
        IN AL,0A1h
        MOV CS:HW_Anc_A1,AL
        MOV CL,BL
        SUB CL,8
        MOV AH,1
        SHL AH,CL
        NOT AH       ;Si IRQ8 => 11111110b
        AND AL,AH    ;Port[$A1] AND (NOT (1 SHL (IRQ_SB-8))
        OUT 0A1h,AL
        IN AL,21h
        MOV AH,11111011b ;IRQ 2 Cascade
        AND AL,AH
        OUT 21h,AL
        STI
        RET
Enable_IRQ ENDP

;-------------------------------------------------------------
;| Disable the IRQ using Ports 21h and A1h                   |
;-------------------------------------------------------------

Disable_IRQ PROC NEAR   ;Put back the IRQ mask to its original value
        MOV BL,AL
        CLI
        PUSH AX
        MOV AL,CS:HW_anc_21
        OUT 21h,AL
        POP AX
        CMP BL,7
        JBE Fin_Rest_Port
        MOV AL,CS:HW_Anc_A1
        OUT 0A1h,AL
Fin_Rest_Port:
        STI
        RET
Disable_IRQ ENDP

;-------------------------------------------------------------
; Change_IRQ  Detourner une Interruption
;
; Input: AL: IRQ Number
;        DX: New IRQ Offset
;-------------------------------------------------------------

HW_IRQ_Number    DB 0   ;Save the Vector Number
HW_Oldvect_IRQ   DD 0   ;Save the Old Vector

Change_IRQ PROC NEAR       ;Interruption pour le DMA

        PUSH AX              ;Sauve le N?de l'IRQ materielle
        PUSH DX              ;Sauve l'adresse de l'IRQ

        CMP AL,7
        JBE Det_7
        ADD AL,60h           ;IRQ au niveau logiciel = IRQ+68h
Det_7:                       ;( Deuxi�me contr�leur d'IRQ)
        ADD AL,8             ;IRQ au niveau logiciel = IRQ+8
        MOV CS:HW_IRQ_Number,AL

        XOR AH,AH            ;( Premier contr�leur d'IRQ)
        SHL AX,1
		SHL AX,1		
        MOV DI,AX            ;SI=(IRQ+8 ou 68h)*4 (Adresse dans la table
                             ;                     des vecteurs d'IRQ    )

        XOR AX,AX            ;R�cuperer le vecteur d'interruption
        MOV ES,AX            ;segment vecteur d'interruption
		MOV AX,ES:[DI]
		MOV W CS:HW_Oldvect_IRQ,AX
        MOV AX,ES:[DI+2]
        MOV W CS:[Offset HW_Oldvect_IRQ+2],AX

        POP DX
;        DS_ASM
        MOV AL,CS:HW_IRQ_Number
        MOV AH,25h           ;fixer vecteur d'interruption sur DS:[DX]
        INT 21h

        POP AX              ;Recupere le N?de l'IRQ
        CALL Enable_IRQ

        RET

Change_IRQ ENDP


;-------------------------------------------------------------
; Restaurer_IRQ
;
; Input: AL: IRQ Number
;-------------------------------------------------------------

Restaurer_IRQ PROC NEAR
        PUSH DI                 ;Is not saved in the IRQ calling this
        PUSH AX                 ;HArdware IRQ number is in AX

        CLI
		MOV AL,CS:HW_IRQ_Number
        XOR AH,AH
        SHL AX,1
		SHL AX,1
	
        MOV DI,AX              ;DI=(IRQ+8)*4
        XOR AX,AX
        MOV ES,AX
        MOV AX,W CS:HW_Oldvect_IRQ
        MOV ES:[DI],AX
        MOV AX,W CS:[Offset HW_Oldvect_IRQ+2]
        MOV ES:[DI+2],AX		
        STI

        POP AX

        CALL Disable_IRQ

        POP DI
        RET
Restaurer_IRQ ENDP

; Timer Code

;The Mode/Command register at I/O address 43h is defined as follows:
;
;       7 6 5 4 3 2 1 0
;       * * . . . . . .  Select chan:   0 0 = Channel 0
;                                       0 1 = Channel 1
;                                       1 0 = Channel 2
;                                       1 1 = Read-back command (8254 only)
;                                             (Illegal on 8253, PS/2)
;       . . * * . . . .  Cmd/Acc mode:  0 0 = Latch count value command
;                                       0 1 = Access mode: lobyte only
;                                       1 0 = Access mode: hibyte only
;                                       1 1 = Access mode: lobyte/hibyte
;       . . . . * * * .  Oper. mode:  0 0 0 = Mode 0
;                                     0 0 1 = Mode 1
;                                     0 1 0 = Mode 2
;                                     0 1 1 = Mode 3
;                                     1 0 0 = Mode 4
;                                     1 0 1 = Mode 5
;                                     1 1 0 = Mode 2
;                                     1 1 1 = Mode 3
;       . . . . . . . *  BCD/Binary mode: 0 = 16-bit binary
;                                         1 = four-digit BCD


;-------------------------------------------------------------
; Timer_HzToPeriod  Convert Frequency to Timer Period
; Input : BX Frequency
; Output: AX Timer Period

Timer_HzToPeriod Proc Near
        MOV DX,18             ;(1193182  /  65536)
        MOV AX,13534          ;(1193182 MOD 65536)
        DIV BX                ;1193182/F -> AX
;        MOV Periode_timer,AX  ; Save the Period
		RET
Timer_HzToPeriod Endp

;-------------------------------------------------------------
; Set_Timer0_Period  Modify the Timer 0 Frequency
;                                                         
; Input : AX: Timer Period (=1193182/Frequency)       
;         If AX=0 => Default Value (18,2/S)          
; Change AX
;-------------------------------------------------------------
; 54 (34h) 00 11 010 0
Set_Timer0_Period Proc Near
        CLI
        PUSH AX
        MOV  AL,34h      ;Timer 0, Mode 2, 
        OUT  43h,AL
        POP  AX
        OUT  40h,AL      ;Partie basse de la fr�quence
        XCHG AH,AL
        OUT  40h,AL      ;Partie haute de la fr�quence
        STI
        RET
Set_Timer0_Period Endp

;-------------------------------------------------------------
;   Change_Timer_IRQ                                         
;   Save the previous and Change the Timer IRQ                              
;   Input : CS:DX New IRQ Code Offset
;   OUT : ES=0                                              
;-------------------------------------------------------------

;Valeur_18 DW 0
;Cpt_appel_ancien_int DW 0
HW_Oldvect_Timer    DD 0

Change_Timer_IRQ PROC NEAR
      PUSH AX
	  PUSH ES
      XOR AX,AX
      MOV ES,AX
      MOV AX,ES:[4*08h]
      MOV W CS:HW_Oldvect_Timer,AX      ; Save Current Timer IRQ
	  MOV AX,ES:[4*08h+2]
	  MOV W CS:HW_Oldvect_Timer+2,AX
	  
      MOV WORD PTR ES:[4*08h],DX
      MOV WORD PTR ES:[4*08h+2],CS  ; Change Timer IRQ
	  POP ES
	  POP AX	  
	  RET
Change_Timer_IRQ ENDP

; Change AX and ES
Restore_Timer_IRQ PROC NEAR
      PUSH AX
	  PUSH ES
      XOR AX,AX
      MOV ES,AX
      MOV AX,W CS:HW_Oldvect_Timer     ; Restaure l'ancienne IRQ Timer
      MOV ES:[4*08h],AX
	  MOV AX,W CS:HW_Oldvect_Timer+2   ; Restaure l'ancienne IRQ Timer
	  MOV ES:[4*08h+2],AX
	  POP ES
	  POP AX
	  RET
Restore_Timer_IRQ ENDP

;****************** Timer Interrupt ********************
; 50 Hz for Gravis UltraSound or Adlib/OPL2 only output

Ifdef Mod_Master

IRQ50_Partition DW Offset Gestion_Sonore     ; Offset of the code to execute

IRQ_Timer_50 Proc Near    ; This IRQ use the Timer
		PUSH AX
		PUSH BX
		PUSH DX
        PUSH DS
		PUSH ES

        MOV AL,20h       ; IRQ Ack
        OUT 20h,AL

        DS_ASM
        CMP MMSS_Pause,1
        JE @@End

        PUSH SI		
		PUSH DI
		PUSH CX
		PUSH BP	

        CALL [IRQ50_Partition]       ;Appel de la partition
		
        POP BP
		POP CX
		POP DI
        POP SI

        CMP CS:Stop_Output,0
        JE @@End

;Writech 'x'
        CALL Stop_Timer_50
        MOV Output_Stopped,1
@@End:
        POP ES
		POP DS
		POP DX
		POP BX
        POP AX		
        IRET                       ; Fin de l'IRQ

IRQ_Timer_50 Endp

; Input DX: Offset of the Timer IRQ
Start_Timer_50 Proc Near

        CLI
	    CALL Change_Timer_IRQ

        MOV AX,23863                  ; 1193182/50 -> 50 Hz
        CALL Set_Timer0_Period        ; Set Timer IRQ to 50Hz
		STI
		
		RET
Start_Timer_50 Endp

Stop_Timer_50 Proc Near

        CLI
        XOR AX,AX
        CALL Set_Timer0_Period
        CALL Restore_Timer_IRQ
        STI

        RET
Stop_Timer_50 Endp
endif