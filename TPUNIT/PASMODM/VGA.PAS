{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                         --==ğğ VGA.PAS ğğ==--                        º}
{º                                                                      º}
{º Unit‚ pour g‚rer la carte VGA par les ports                          º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 8088          D‚but d'‚critureúúúúúúúúúúúúúúú??/04/95 º}
{º                              DerniŠres modificationsúúúúúúúú03/09/95 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT VGA;

{$A+,G-,Q-,R-,S-}

INTERFACE

CONST {adresses des ports de la carte VGA}
      MiscOutput   =$3CC;
      InputStatus0 =$3C2;
      InputStatus1 =$3BA;
      CRTStatus    =$3DA;

      CRTControl   =$3D4;
       CRTControlIndex=CRTControl;
       CRTControlData =CRTControl+1;

      Sequencer    =$3C4;
       SequencerIndex=Sequencer;
       SequencerData =Sequencer+1;

      AttrControl  =$3C0;
       AttrControlIndex=AttrControl;
       AttrControlData =AttrControl+1;

      GraphControl =$3CE;
       GraphControlIndex=GraphControl;
       GraphControlData =GraphControl+1;

      DACWrite     =$3C8;
      DACRead      =$3C7;
      DACState     =$3C7;
      DACData      =$3C9;
      DACMask      =$3C6;

      {registres du contr“leur CRT}
      HTotal       =$00;
      EndHDisplay  =$01;
      StartHBlank  =$02;
      EndHBlank    =$03;
      StartHRetrace=$04;
      EndHRetrace  =$05;
      VTotal       =$06;
      Overflow     =$07;
      VPelPanning  =$08;
      MaxScanLine  =$09;
      CursorStart  =$0A;
      CursorEnd    =$0B;
      StartAddrHigh=$0C;
      StartAddrLow =$0D;
      CursorLocHigh=$0E;
      CursorLocLow =$0F;
      StartVRetrace=$10;
      EndVRetrace  =$11;
      EndVDisplay  =$12;
      Offset_      =$13;
      UnderlineLoc =$14;
      StartVBlank  =$15;
      EndVBlank    =$16;
      ModeControl  =$17;
      LineCompare  =$18;

      {registres du s‚quenceur}
      Reset        =$00;
      ClockingMode =$01;
      MapMask      =$02;
      CharMapSelect=$03;
      MemoryMode   =$04;

      {registres du contr“leur d'attributs}
      ModeControl_ =$10;
      Overscan     =$11;
      ColorPlaneEn =$12;
      HPelPanning  =$13;
      ColorSelect  =$14;

      {registres du contr“leur graphique}
      SetReset     =$00;
      EnSetReset   =$01;
      ColorCompare =$02;
      FuncSelect   =$03;
      ReadMapSelect=$04;
      GraphicsMode =$05;
      Miscellaneous=$06;
      ColorDontCare=$07;
      BitMask      =$08;

{==========================================================}

PROCEDURE UnLockCRT;

PROCEDURE SetVerticalTotal(n: Word);
PROCEDURE SetEndVerticalDisplay(n: Word);
PROCEDURE SetStartVerticalRetrace(n: Word);
PROCEDURE SetStartVerticalBlanking(n: Word);
PROCEDURE SetEndHorizontalBlanking(n: Byte);

PROCEDURE SetStartAddr(addr: Word);
PROCEDURE SetLineCompare(ligne: Word);

PROCEDURE SmoothVertical(decalage: Byte);
PROCEDURE SmoothHorizontal(decalage: Byte);

{==========================================================}

IMPLEMENTATION

{==========================================================}

PROCEDURE UnLockCRT; Assembler;
{autorise l'accŠs aux registres 00h … 07h du contr“leur CRT}
ASM
 MOV DX,CRTControl
 MOV AL,EndVRetrace
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,01111111b { Efface le premier Bit }
 OUT DX,AL
End; {UnLockCRT}

{----------------------------------------------------------}

PROCEDURE SetVerticalTotal(n: Word); Assembler;
ASM
 MOV BX,n

 MOV DX,CRTControl
 MOV AL,VTotal
 MOV AH,BL
 OUT DX,AX

 MOV BL,BH      {BL=BH: partie haute de n}

 MOV AL,Overflow
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,11011110b
 AND BH,00000001b
 OR AL,BH       {bit 0 de Overflow = bit 8 de n}

 AND BL,00000010b
 MOV CL,4
 SHL BL,CL
 OR AL,BL       {bit 5 de Overflow = bit 9 de n}

 OUT DX,AL
End; {SetVerticalTotal}

{----------------------------------------------------------}

PROCEDURE SetEndVerticalDisplay(n: Word); Assembler;
ASM
 MOV BX,n

 MOV DX,CRTControl
 MOV AL,EndVDisplay
 MOV AH,BL
 OUT DX,AX

 MOV BL,BH      {BL=BH: partie haute de n}

 MOV AL,Overflow
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,10111101b
 AND BH,00000001b
 SHL BH,1
 OR AL,BH       {bit 1 de Overflow = bit 8 de n}

 AND BL,00000010b
 MOV CL,5
 SHL BL,CL
 OR AL,BL       {bit 6 de Overflow = bit 9 de n}

 OUT DX,AL
End; {SetEndVerticalDisplay}

{----------------------------------------------------------}

PROCEDURE SetStartVerticalRetrace(n: Word); Assembler;
ASM
 MOV BX,n

 MOV DX,CRTControl
 MOV AL,StartVRetrace
 MOV AH,BL
 OUT DX,AX

 MOV BL,BH      {BL=BH: partie haute de n}

 MOV AL,Overflow
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,01111011b
 AND BH,00000001b
 SHL BH,1
 SHL BH,1
 OR AL,BH       {bit 2 de Overflow = bit 8 de n}

 AND BL,00000010b
 MOV CL,6
 SHL BL,CL
 OR AL,BL       {bit 7 de Overflow = bit 9 de n}

 OUT DX,AL
End; {SetStartVerticalRetrace}

{----------------------------------------------------------}

PROCEDURE SetStartVerticalBlanking(n: Word); Assembler;
ASM
 MOV BX,n

 MOV DX,CRTControl
 MOV AL,StartVBlank
 MOV AH,BL
 OUT DX,AX

 MOV BL,BH      {BL=BH: partie haute de n}

 MOV AL,Overflow
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,11110111b
 AND BH,00000001b
 MOV CL,3
 SHL BH,CL
 OR AL,BH       {bit 3 de Overflow = bit 8 de n}

 OUT DX,AL

 DEC DL
 MOV AL,MaxScanLine
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,11011111b
 AND BL,00000010b
 MOV CL,4
 SHL BL,CL
 OR AL,BL       {bit 5 de Maximum Scan Line = bit 9 de n}

 OUT DX,AL
End; {SetStartVerticalBlanking}

{----------------------------------------------------------}

PROCEDURE SetEndHorizontalBlanking(n: Byte); Assembler;
ASM
 MOV BL,n

 MOV BH,BL
 AND BH,00011111b

 MOV DX,CRTControl
 MOV AL,EndHBlank
 IN AL,DX
 INC DL
 AND AL,11100000b
 OR AL,BH
 OUT DX,AL

 DEC DL
 MOV AL,EndHRetrace
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,01111111b
 AND BL,00100000b
 SHL BL,1
 SHL BL,1
 OR AL,BL
 OUT DX,AL
End; {SetEndHorizontalBlanking}

{----------------------------------------------------------}

PROCEDURE SetStartAddr(addr: Word); Assembler;
{d‚place le d‚but de la RAM vid‚o}
ASM
 MOV AX,addr
 MOV BL,AL

 MOV DX,CRTControl
 MOV AL,StartAddrHigh
 OUT DX,AX
 MOV AL,StartAddrLow
 MOV AH,BL
 OUT DX,AX
End; {SetStartAddr}

{----------------------------------------------------------}

PROCEDURE SetLineCompare(ligne: Word); Assembler;
{s‚pare l'‚cran en deux, … partir de la ligne indiqu‚e (en pixels)
 Remarques: - la partie sup‚rieure peut ˆtre d‚cal‚e
            - la partie inf‚rieure est fixe}
ASM
 MOV BX,ligne

 MOV DX,CRTControl
 MOV AL,LineCompare
 MOV AH,BL
 OUT DX,AX

 MOV BL,BH      {BL=BH: partie haute de ligne}

 MOV AL,Overflow
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,11101111b
 AND BH,00000001b
 MOV CL,4
 SHL BH,CL
 OR AL,BH       {bit 4 de Overflow = bit 8 de ligne}

 OUT DX,AL

 DEC DL
 MOV AL,MaxScanLine
 OUT DX,AL
 INC DL
 IN AL,DX
 AND AL,10111111b
 AND BL,00000010b
 MOV CL,5
 SHL BL,CL
 OR AL,BL       {bit 6 de Maximum Scan Line = bit 9 de ligne}

 OUT DX,AL
End; {SetLineCompare}

{----------------------------------------------------------}

PROCEDURE SmoothVertical(decalage: Byte); Assembler;
{d‚cale l'‚cran verticalement}
{decalage: de 0 … 15 pixels}
ASM
 MOV DX,CRTControl
 MOV AL,VPelPanning
 MOV AH,decalage
 OUT DX,AX
End; {SmoothVertical}

{----------------------------------------------------------}

PROCEDURE SmoothHorizontal(decalage: Byte); Assembler;
{d‚cale l'‚cran horizontalement}
{decalage:    0 1 2 3 4 5 6 7 8  pixels
 Pel panning: 8 0 1 2 3 4 5 6 7}
ASM
 MOV DX,AttrControl
 MOV AL,HPelPanning OR 00100000b   {bit 5 … 1 sinon ‚cran noir!}
 OUT DX,AL
 MOV AL,decalage
 OR AL,AL
 JNZ @pas_nul
 MOV AL,8+1
@pas_nul:
 DEC AL
 OUT DX,AL
End; {SmoothHorizontal}

{==========================================================}

END.
