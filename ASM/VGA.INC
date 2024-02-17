;   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³ ***  Constantes ports & registres carte VGA + quelques routines  *** ³
;   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;adresses des ports de la carte VGA
      MiscOutput   EQU 3CCh
      InputStatus0 EQU 3C2h
      InputStatus1 EQU 3BAh
      CRTStatus    EQU 3DAh

      CRTControl   EQU 3D4h
       CRTControlIndex EQU CRTControl
       CRTControlData  EQU CRTControl+1

      Sequencer    EQU 3C4h
       SequencerIndex EQU Sequencer
       SequencerData  EQU Sequencer+1

      AttrControl  EQU 3C0h
       AttrControlIndex EQU AttrControl
       AttrControlData  EQU AttrControl+1

      GraphControl  EQU 3CEh
       GraphControlIndex EQU GraphControl
       GraphControlData  EQU GraphControl+1

      DACWrite      EQU 3C8h
      DACRead       EQU 3C7h
      DACState      EQU 3C7h
      DACData       EQU 3C9h
      DACMask       EQU 3C6h

;registres du contr“leur CRT
      HTotal        EQU 00h
      EndHDisplay   EQU 01h
      StartHBlank   EQU 02h
      EndHBlank     EQU 03h
      StartHRetrace EQU 04h
      EndHRetrace   EQU 05h
      VTotal        EQU 06h
      Overflow      EQU 07h
      VPelPanning   EQU 08h
      MaxScanLine   EQU 09h
      CursorStart   EQU 0Ah
      CursorEnd     EQU 0Bh
      StartAddrHigh EQU 0Ch
      StartAddrLow  EQU 0Dh
      CursorLocHigh EQU 0Eh
      CursorLocLow  EQU 0Fh
      StartVRetrace EQU 10h
      EndVRetrace   EQU 11h
      EndVDisplay   EQU 12h
      Offset_       EQU 13h
      UnderlineLoc  EQU 14h
      StartVBlank   EQU 15h
      EndVBlank     EQU 16h
      ModeControl   EQU 17h
      LineCompare   EQU 18h

;registres du s‚quenceur
      Reset         EQU 00h
      ClockingMode  EQU 01h
      MapMask       EQU 02h
      CharMapSelect EQU 03h
      MemoryMode    EQU 04h

;registres du contr“leur d'attributs
      ModeControl_  EQU 10h
      Overscan      EQU 11h
      ColorPlaneEn  EQU 12h
      HPelPanning   EQU 13h
      ColorSelect   EQU 14h

;registres du contr“leur graphique
      SetReset      EQU 00h
      EnSetReset    EQU 01h
      ColorCompare  EQU 02h
      FuncSelect    EQU 03h
      ReadMapSelect EQU 04h
      GraphicsMode  EQU 05h
      Miscellaneous EQU 06h
      ColorDontCare EQU 07h
      BitMask       EQU 08h


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ ACCEDECAR  Autorise l'accŠs aux tables de caractŠres en A000:0000    ³
;³                                                                      ³
;³ Entr‚es: aucune                                                      ³
;³ Sortie : aucune                                                      ³
;³ Change : AX,DX,Flags                                                 ³
;³ Remarques: La RAM vid‚o ne peut plus ˆtre adress‚e en B800 (texte) ! ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
AccedeCar PROC NEAR
        CLI

        MOV DX,Sequencer
        MOV AX,(00000100b SHL 8)+MapMask
        OUT DX,AX      ;autorise l'accŠs au plan de bits #2 (table de caractŠres)
        MOV AX,(00000111b SHL 8)+MemoryMode
        OUT DX,AX      ;d‚sactive le mode Odd/Even (pour lire les octets lin‚airement)

        MOV DX,GraphControl
        MOV AX,(00000010b SHL 8)+ReadMapSelect
        OUT DX,AX      ;indique le plan de bits #2
        MOV AX,(00000000b SHL 8)+GraphicsMode
        OUT DX,AX      ;d‚sactive le mode Odd/Even
        MOV AX,(00000100b SHL 8)+Miscellaneous
        OUT DX,AX      ;indique la taille de la RAM vid‚o en A000: 64ko (8 tables*256 car.*32 lignes)

        STI
        RET
AccedeCar ENDP


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ ACCEDEMEM  R‚tablit l'accŠs … la RAM vid‚o en B800:0000  (texte)     ³
;³                                                                      ³
;³ Entr‚es: aucune                                                      ³
;³ Sortie : aucune                                                      ³
;³ Change : AX,DX,Flags                                                 ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
AccedeMem PROC NEAR
        CLI

        MOV DX,Sequencer
        MOV AX,(00000011b SHL 8)+MapMask
        OUT DX,AX      ;r‚tablit l'accŠs aux plans de bits #0 et #1 (RAM vid‚o: code/attribut)
        MOV AX,(00000011b SHL 8)+MemoryMode
        OUT DX,AX      ;r‚active le mode Odd/Even (pour lire les octets en alternance)

        MOV DX,GraphControl
        MOV AX,(00000000b SHL 8)+ReadMapSelect
        OUT DX,AX      ;indique le plan de bits #0
        MOV AX,(00010000b SHL 8)+GraphicsMode
        OUT DX,AX      ;r‚active le mode Odd/Even
        MOV AX,(00001110b SHL 8)+Miscellaneous
        OUT DX,AX      ;indique la taille de la RAM vid‚o en B800: 32ko (8 pages*4000 octets)

        STI
        RET
AccedeMem ENDP


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ CHARGEDAC  Charge le contenu d'un registre DAC (carte VGA seulement) ³
;³                                                                      ³
;³ Entr‚e : AL=num‚ro du registre DAC                                   ³
;³ Sorties: DH=rouge (0..63)                                            ³
;³          CH=vert  (0..63)                                            ³
;³          CL=bleu  (0..63)                                            ³
;³ Change : rien                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ChargeDAC PROC NEAR
        PUSH AX

        MOV DX,DACRead
        OUT DX,AL
        MOV DX,DACData
        IN AL,DX
        MOV AH,AL               ; AH=rouge (pour ne pas modifier DX)
        IN AL,DX
        MOV CH,AL               ; CH=vert
        IN AL,DX
        MOV CL,AL               ; CL=bleu

        MOV DH,AH               ; DH=rouge

        POP AX
        RET
ChargeDAC ENDP


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ FIXEDAC    Fixe le contenu d'un registre DAC                         ³
;³                                                                      ³
;³ Entr‚es: AL=num‚ro du registre DAC                                   ³
;³          DH=rouge (0..63)                                            ³
;³          CH=vert  (0..63)                                            ³
;³          CL=bleu  (0..63)                                            ³
;³ Sortie : aucune                                                      ³
;³ Change : rien                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FixeDAC PROC NEAR
        PUSH AX DX
        MOV AH,DH               ; sauvegarde le rouge car DX modifi‚

        MOV DX,DACWrite
        OUT DX,AL
        MOV DX,DACData
        MOV AL,AH
        OUT DX,AL               ; fixe le rouge
        MOV AL,CH
        OUT DX,AL               ; fixe le vert
        MOV AL,CL
        OUT DX,AL               ; fixe le bleu

        POP DX AX
        RET
FixeDAC ENDP

