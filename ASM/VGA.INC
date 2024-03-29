;   旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
;   � ***  Constantes ports & registres carte VGA + quelques routines  *** �
;   읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

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

;registres du contr뱇eur CRT
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

;registres du s굌uenceur
      Reset         EQU 00h
      ClockingMode  EQU 01h
      MapMask       EQU 02h
      CharMapSelect EQU 03h
      MemoryMode    EQU 04h

;registres du contr뱇eur d'attributs
      ModeControl_  EQU 10h
      Overscan      EQU 11h
      ColorPlaneEn  EQU 12h
      HPelPanning   EQU 13h
      ColorSelect   EQU 14h

;registres du contr뱇eur graphique
      SetReset      EQU 00h
      EnSetReset    EQU 01h
      ColorCompare  EQU 02h
      FuncSelect    EQU 03h
      ReadMapSelect EQU 04h
      GraphicsMode  EQU 05h
      Miscellaneous EQU 06h
      ColorDontCare EQU 07h
      BitMask       EQU 08h


;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
;� ACCEDECAR  Autorise l'acc둺 aux tables de caract둹es en A000:0000    �
;�                                                                      �
;� Entr괻s: aucune                                                      �
;� Sortie : aucune                                                      �
;� Change : AX,DX,Flags                                                 �
;� Remarques: La RAM vid굊 ne peut plus 늯re adress괻 en B800 (texte) ! �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
AccedeCar PROC NEAR
        CLI

        MOV DX,Sequencer
        MOV AX,(00000100b SHL 8)+MapMask
        OUT DX,AX      ;autorise l'acc둺 au plan de bits #2 (table de caract둹es)
        MOV AX,(00000111b SHL 8)+MemoryMode
        OUT DX,AX      ;d굎active le mode Odd/Even (pour lire les octets lin괶irement)

        MOV DX,GraphControl
        MOV AX,(00000010b SHL 8)+ReadMapSelect
        OUT DX,AX      ;indique le plan de bits #2
        MOV AX,(00000000b SHL 8)+GraphicsMode
        OUT DX,AX      ;d굎active le mode Odd/Even
        MOV AX,(00000100b SHL 8)+Miscellaneous
        OUT DX,AX      ;indique la taille de la RAM vid굊 en A000: 64ko (8 tables*256 car.*32 lignes)

        STI
        RET
AccedeCar ENDP


;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
;� ACCEDEMEM  R굏ablit l'acc둺 � la RAM vid굊 en B800:0000  (texte)     �
;�                                                                      �
;� Entr괻s: aucune                                                      �
;� Sortie : aucune                                                      �
;� Change : AX,DX,Flags                                                 �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
AccedeMem PROC NEAR
        CLI

        MOV DX,Sequencer
        MOV AX,(00000011b SHL 8)+MapMask
        OUT DX,AX      ;r굏ablit l'acc둺 aux plans de bits #0 et #1 (RAM vid굊: code/attribut)
        MOV AX,(00000011b SHL 8)+MemoryMode
        OUT DX,AX      ;r괶ctive le mode Odd/Even (pour lire les octets en alternance)

        MOV DX,GraphControl
        MOV AX,(00000000b SHL 8)+ReadMapSelect
        OUT DX,AX      ;indique le plan de bits #0
        MOV AX,(00010000b SHL 8)+GraphicsMode
        OUT DX,AX      ;r괶ctive le mode Odd/Even
        MOV AX,(00001110b SHL 8)+Miscellaneous
        OUT DX,AX      ;indique la taille de la RAM vid굊 en B800: 32ko (8 pages*4000 octets)

        STI
        RET
AccedeMem ENDP


;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
;� CHARGEDAC  Charge le contenu d'un registre DAC (carte VGA seulement) �
;�                                                                      �
;� Entr괻 : AL=num굍o du registre DAC                                   �
;� Sorties: DH=rouge (0..63)                                            �
;�          CH=vert  (0..63)                                            �
;�          CL=bleu  (0..63)                                            �
;� Change : rien                                                        �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
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


;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
;� FIXEDAC    Fixe le contenu d'un registre DAC                         �
;�                                                                      �
;� Entr괻s: AL=num굍o du registre DAC                                   �
;�          DH=rouge (0..63)                                            �
;�          CH=vert  (0..63)                                            �
;�          CL=bleu  (0..63)                                            �
;� Sortie : aucune                                                      �
;� Change : rien                                                        �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
FixeDAC PROC NEAR
        PUSH AX DX
        MOV AH,DH               ; sauvegarde le rouge car DX modifi�

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

