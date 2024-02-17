{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                      --==ðð CLAVIER.PAS ðð==--                       º}
{º                                                                      º}
{º Unit‚ pour g‚rer le clavier avec les codes ‚tendus                   º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 8088          D‚but d'‚critureúúúúúúúúúúúúúúú??/??/93 º}
{º (sauf indication contraire)  DerniŠres modificationsúúúúúúúú03/09/95 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT Clavier;

{$A+,G-,Q-,R-,S-}

INTERFACE

CONST {constantes de touches - codes standards et ‚tendus (9 bits)}
      Esc=27;
      Enter=13; CtrlEnter=10; AltEnter=20;
      Space=32;
      Bdel=8; CtrlBdel=127; AltBdel=14;

      Del=339; CtrlDel=403; AltDel=419;
      Ins=338; CtrlIns=402; AltIns=418;

      Tab=9; ShiftTab=15; CtrlTab=404; AltTab=421;

      F1=315; F2=316; F3=317; F4 =318; F5 =319; F6 =320;
      F7=321; F8=322; F9=323; F10=324; F11=325; F12=326;

      ShiftF1=340; ShiftF2=341; ShiftF3=342; ShiftF4 =343; ShiftF5 =344; ShiftF6 =345;
      ShiftF7=346; ShiftF8=347; ShiftF9=348; ShiftF10=349; ShiftF11=391; ShiftF12=392;

      CtrlF1=350; CtrlF2=351; CtrlF3=352; CtrlF4 =353; CtrlF5 =354; CtrlF6 =355;
      CtrlF7=356; CtrlF8=357; CtrlF9=358; CtrlF10=359; CtrlF11=393; CtrlF12=394;

      AltF1=360; AltF2=361; AltF3=362; AltF4 =363; AltF5 =364; AltF6 =365;
      AltF7=366; AltF8=367; AltF9=368; AltF10=369; AltF11=395; AltF12=396;

      Home=327; End_ =335;
      PgUp=329; PgDn =337;
      Left=331; Right=333;
      Up  =328; Down =336;

      CtrlHome=375; CtrlEnd  =373;
      CtrlPgUp=388; CtrlPgDn =374;
      CtrlLeft=371; CtrlRight=372;
      CtrlUp  =397; CtrlDown =401;

      AltHome=407; AltEnd  =415;
      AltPgUp=404; AltPgDn =417;
      AltLeft=411; AltRight=413;
      AltUp  =408; AltDown =416;

      AltA=286; AltB=304; AltC=302; AltD=288; AltE=274;
      AltF=289; AltG=290; AltH=291; AltI=279; AltJ=292;
      AltK=293; AltL=294; AltM=306; AltN=305; AltO=280;
      AltP=281; AltQ=272; AltR=275; AltS=287; AltT=276;
      AltU=278; AltV=303; AltW=273; AltX=301; AltY=277;
      AltZ=300;

      LettreAlt: Array[AltQ..AltM] of Char='QWERTYUIOP    ASDFGHJKL     ZXCVBNM';

      Alt1=376; Alt2=377; Alt3=378; Alt4=379; Alt5=380;
      Alt6=381; Alt7=382; Alt8=383; Alt9=384; Alt0=385;

      ChiffreAlt: Array[Alt1..Alt0] of Byte=(1,2,3,4,5,6,7,8,9,0);

      {constantes d'‚tat clavier}
      ShiftD =$01;
      ShiftG =$02;
      Ctrl   =$04;
      Alt    =$08;
      ScrMode=$10;
      NumMode=$20;
      MajMode=$40;
      InsMode=$80;

      {modes d'‚tat correspondant aux 3 LEDs du clavier}
      LEDs=NumMode or MajMode or ScrMode;

TYPE Key=Word;

VAR EtatClavier: Byte Absolute $40:$17;

{================================================}

FUNCTION ReadKey: Key;
FUNCTION KeyPressed: Boolean;
FUNCTION Chr(touche: Key): Char;
FUNCTION UpCase(touche: Key): Key;

PROCEDURE ActiveMode(mode: Byte);
PROCEDURE DesactiveMode(mode: Byte);

PROCEDURE VideBufferClavier;
PROCEDURE VitesseClavier(delai,vitesse: Byte);

{================================================}

IMPLEMENTATION

{================================================}

FUNCTION ReadKey: Key; Assembler;
{renvoie le code ASCII ou le code ‚tendu (>256) de la touche}
ASM
 MOV AH,00h
 INT 16h
 OR AL,AL
 JZ @code_etendu
 XOR AH,AH
 JMP @fin
@code_etendu:
 MOV AL,AH
 MOV AH,1
@fin:
End; {ReadKey}

{------------------------------------------------}

FUNCTION KeyPressed: Boolean; Assembler;
ASM
 MOV AH,01h
 INT 16h
 MOV AL,True
 JNZ @fin
 MOV AL,False
@fin:
End; {KeyPressed}

{------------------------------------------------}

FUNCTION Chr(touche: Key): Char; Assembler;
ASM
 MOV AX,touche
 OR AH,AH
 JZ @fin
 XOR AL,AL
@fin:
End; {Chr}

{------------------------------------------------}

FUNCTION UpCase(touche: Key): Key; Assembler;
ASM
 MOV AX,touche
 OR AH,AH
 JNZ @fin
 CMP AL,'a'
 JB @fin
 CMP AL,'z'
 JA @fin
 SUB AL,32
@fin:
End; {UpCase}

{------------------------------------------------}

PROCEDURE ActiveMode(mode: Byte);
{mode=ScrMode, NumMode, MajMode ou InsMode}
Begin
 EtatClavier:=EtatClavier or mode;
 ASM
  MOV AH,01h
  INT 16h       {actualise l'‚tat des LEDs du clavier}
 End
End; {ActiveMode}

{------------------------------------------------}

PROCEDURE DesactiveMode(mode: Byte);
{mode=ScrMode, NumMode, MajMode ou InsMode}
Begin
 EtatClavier:=EtatClavier and Not(mode);
 ASM
  MOV AH,01h
  INT 16h       {actualise l'‚tat des LEDs du clavier}
 End
End; {DesactiveMode}

{------------------------------------------------}

PROCEDURE VideBufferClavier; Assembler;
ASM
 CLI
 MOV DX,40h
 MOV ES,DX
 MOV AL,ES:[1Ch]
 MOV ES:[1Ah],AL
 STI
End; {VideBufferClavier}

{------------------------------------------------}

PROCEDURE VitesseClavier(delai,vitesse: Byte); Assembler; {AT seulement !}
ASM
 MOV AX,0305h
 MOV BH,delai
 MOV BL,vitesse
 INT 16h
End; {VitesseClavier}

{================================================}

END.
