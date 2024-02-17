{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                        --==ðð UTIL.PAS ðð==--                        º}
{º                                                                      º}
{º Unit‚ contenant des routines diverses (configuration, lecteurs, ‚cranº}
{º entiers, r‚pertoires, chaŒnes, ...)                                  º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 286           D‚but d'‚critureúúúúúúúúúúúúúú ??/10/94 º}
{º                              DerniŠres modificationsúúúúúúú 26/07/98 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT Util;

{$A+,G-,Q-,R-,S-}

INTERFACE

{$I Types}

CONST {familles pour Processeur}
      _8086  =1;
      _286   =2;
      _386   =3;
      _486   =4;
      Pentium=5;
      PentPro=6;

      {formats pour TypeLecteur}
      disque_dur   =0;
      lecteur_5p25 =1;
      lecteur_3p5  =2;
      lecteur_CDRom=3;

      {formes du curseur clignotant pour Curseur}
      plat =$0607; {standard}
      rect =$0007; {rectangle}
      carre=$0105; {carr‚}
      off  =$1000; {invisible}

      {options pour EntierTexte2}
      et_zeros   =$20; {extension de z‚ros … gauche pour les nombresò0}
      et_j_gauche=$40; {justification … gauche}

      {modes vid‚o pour ModeVideo}
      txt40_mono    =$00;
      txt40_16c     =$01;
      txt80_mono    =$02;
      txt80_16c     =$03; txt_standard=txt80_16c;
      gr320x200_mono=$04;
      gr320x200_4c  =$05;
      gr640x200_2c  =$06;
      txt80_mono_   =$07;
      gr320x200_16c =$0D;
      gr640x200_16c =$0E;
      gr640x350_mono=$0F;
      gr640x350_16c =$10;
      gr640x480_2c  =$11;
      gr640x480_16c =$12;
      gr320x200_256c=$13;
      txt132_16c    =$14; {SVGA}


VAR Timer       : LONGINT absolute $0040:$006C;
    ModeVideo   : BYTE    absolute $0040:$0049;
    NombreLignes: BYTE    absolute $0040:$0084;

{==========================================================}

{configuration mat‚rielle / g‚n‚rale}
function  Processeur: BYTE;
function  Coprocesseur: BOOLEAN;
function  IndicePerformance: LONGINT;

{configuration vid‚o}
function  CarteVGA: BOOLEAN;
function  DetecteVESA: BOOLEAN;

{configuration lecteurs / r‚pertoires actifs ...}
function  NbrLecteurs: BYTE;
function  NbrDisquesDurs: BYTE;
function  LettreCDROM: CHAR;
function  ListeLecteurs: String26;
function  CheminAccesDOS(lecteur: CHAR): String80;
function  CheminAcces(lecteur: CHAR): String80;
function  NomFichierDOS(nom_fichier: String80): String80;
function  RepertTemp: String80;
function  LecteurPhysique(lecteur: CHAR): BOOLEAN;
function  TypeLecteur(lecteur: CHAR): BYTE;

{d‚tection systŠme d'exploitation}
function  _4DOS: BOOLEAN;
function  Win3X: BOOLEAN;

{gestion faisceau vid‚o}
procedure AttendVBL;
procedure AttendVBL2;
procedure AttendHBL;
procedure AttendHBL2;
procedure AttendFinHBL;

{curseur en mode texte}
procedure Curseur(forme: WORD);

{conversion de nombres entiers / r‚els}
function  EntierTexte(entier: LONGINT; nombre_chiffres: BYTE): String12;
function  EntierTexte2(entier: LONGINT; nombre_chiffres: BYTE): STRING;
function  ReelTexte(reel: REAL; i,j: BYTE): String12;
function  EntierHexa(entier: LONGINT; nombre_chiffres: BYTE): String8;

function  MinEntier(entier1,entier2: INTEGER): INTEGER;
function  MaxEntier(entier1,entier2: INTEGER): INTEGER;
function  LimiteEntier(entier,limite_inf,limite_sup: INTEGER): INTEGER;
function  Sgn(x: INTEGER): SHORTINT;
function  SwapB(b: BYTE): BYTE;
function  SwapW(w: WORD): WORD;
function  SwapL(l: LONGINT): LONGINT;
function  SwapLB(l: LONGINT): LONGINT;

{op‚rateurs logiques sur les nombres 8/16/32 bits}
function  AND_B(var valeur: BYTE; masque: BYTE): BYTE;
function   OR_B(var valeur: BYTE; masque: BYTE): BYTE;
function  XOR_B(var valeur: BYTE; masque: BYTE): BYTE;
function  NOT_B(var valeur: BYTE): BYTE;

function  AND_W(var valeur: WORD; masque: WORD): WORD;
function   OR_W(var valeur: WORD; masque: WORD): WORD;
function  XOR_W(var valeur: WORD; masque: WORD): WORD;
function  NOT_W(var valeur: WORD): WORD;

function  AND_L(var valeur: LONGINT; masque: LONGINT): LONGINT;
function   OR_L(var valeur: LONGINT; masque: LONGINT): LONGINT;
function  XOR_L(var valeur: LONGINT; masque: LONGINT): LONGINT;
function  NOT_L(var valeur: LONGINT): LONGINT;

{‚change de zones m‚moire}
procedure SwapVar(var var1; var var2; taille: WORD);

{incr‚mentation de pointeurs}
function  AddPtr(pointeur: POINTER; decalage: WORD): POINTER;

{gestion des noms de fichiers / r‚pertoires}
function  NomFichierSeul(chemin: String80): String12;
function  RepertoireSeul(chemin: String80): String80;
function  ExtensionSeule(chemin: String80): String3;
function  SousRepertoire(repert: String80): String12;
function  CorrigeNomFichier(repertoire,nom_fichier: String80): String80;
function  LimiteNomFichier(nom_fichier: String80; longueur: BYTE): String80;

{gestion des chaŒnes de caractŠres}
function  RepeteCar(car: CHAR; nombre: BYTE): STRING;
function  Min(chaine: STRING): STRING;
function  Maj(chaine: STRING): STRING;
function  PosF(sous_chaine,chaine: STRING): BYTE;
function  CopyL(chaine: STRING; longueur: BYTE): STRING;
function  CopyR(chaine: STRING; longueur: BYTE): STRING;
function  XString (chaine: STRING; caractere: CHAR; longueur: BYTE): STRING;
function  XCString(chaine: STRING; caractere: CHAR; longueur: BYTE): STRING;

function Str2Hex(chaine: STRING): WORD;

{pause systŠme}
procedure Pause(delai_18: BYTE);

{‚change d'interruptions}
procedure SwapIntVec(n_int: BYTE; var old: POINTER; new: POINTER);

{==========================================================}

IMPLEMENTATION

USES Dos;

{==========================================================}

function Processeur: BYTE; assembler;
{renvoie le type de processeur identifi‚ (8086,286,386,486,Pentium ou +)}
asm
 mov DL,_8086
 push SP
 pop AX
 cmp SP,AX
 jne @fin       {8086}

 mov DL,_286
 pushf
 pop AX
 or  AX,0100000000000000b
 push AX
 popf
 pushf
 pop AX
 test AX,0100000000000000b
 jz  @fin       {286}

 mov DL,_386
 mov BX,SP
 and SP,1111111111111100b  { ‚vite une erreur d'alignement }
 DB 66h; pushf             { PUSHFD }
 DB 66h; pop AX            { pop EAX }
 DB 66h; mov CX,AX         { mov ECX,EAX }
 DB 66h,35h; DD 00040000h  { xor EAX,00040000h : inverse bit Alignment Check }
 DB 66h; push AX           { push EAX }
 DB 66h; popf              { POPFD }
 DB 66h; pushf             { PUSHFD }
 DB 66h; pop AX            { pop EAX }
 DB 66h; xor AX,CX         { xor EAX,ECX : teste bit AC }
 jz @fin        {386}

 mov DL,_486
 and SP,1111111111111100b  { ‚vite une erreur d'alignement }
 DB 66h; push CX           { push ECX }
 DB 66h; popf              { POPFD }
 mov SP,BX
 DB 66h; mov AX,CX         { mov EAX,ECX }
 DB 66h,35h; DD 00200000h  { xor EAX,00200000h : inverse bit CPUID }
 DB 66h; push AX           { push EAX }
 DB 66h; popf              { POPFD }
 DB 66h; pushf             { PUSHFD }
 DB 66h; pop AX            { pop EAX }
 DB 66h; xor AX,CX         { xor EAX,ECX : teste bit CPUID }
 jz @fin        {486}

 DB 66h; xor AX,AX         { xor EAX,EAX }
 DB 0Fh,0A2h               { CPUID, AX=0 (CPUID caps) }
 DB 66h; cmp AX,1          { cmp EAX,1 }
 jl @fin
 DB 66h; xor AX,AX         { xor EAX,EAX }
 DB 66h; inc AX
 DB 0Fh,0A2h               { CPUID, AX=1 (CPU info) }
 and AH,00001111b          { masque nø de famille }
 mov DL,AH      {Pentium (P5) ou sup‚rieur (P6)...}

@fin:
 mov AL,DL
end; {Processeur}

{----------------------------------------------------------}

function Coprocesseur: BOOLEAN; assembler;
{renvoie TRUE si le PC dispose d'un coprocesseur math‚matique}
var cw: WORD;
asm
 mov AL,FALSE
 DB  0DBh,0E3h         {FINIT : initialise le coprocesseur}
 mov BYTE ptr cw+1,0   {Hi-BYTE Control-WORD = 0}
 DB  36h,0D9h,7Eh,0FEh {FSTCW cw : sauvegarde Status Control WORD}
 cmp BYTE ptr cw+1,3   {Hi-BYTE Control-WORD = 3? (ready)}
 jne @fin              {non -> pas de coprocesseur}
 mov AL,TRUE
@fin:
end; {Coprocesseur}

{----------------------------------------------------------}

function IndicePerformance: LONGINT; assembler;
{renvoie un entier proportionnel … la vitesse du processeur}
asm
 mov DX,40h
 mov ES,DX

 mov CL,ES:[6Ch]
 inc CL
@synchronise:
 mov CH,ES:[6Ch]
 inc CH
 cmp CH,CL
 je  @synchronise

 mov CL,CH
 xor DX,DX
 xor AX,AX
 mov BX,1234h
@calcule:
 push AX
 push DX
 mov DX,BX
 mov AX,BX
 imul BX
 pop DX
 pop AX
 add AX,1
 adc DX,0
 mov CH,ES:[6Ch]
 inc CH
 cmp CH,CL
 je  @calcule
end; {IndicePerformance}

{----------------------------------------------------------}

function CarteVGA: BOOLEAN; assembler;
{renvoie TRUE si le PC dispose d'une carte VGA ou sup‚rieure}
asm
 mov AX,1A00h
 int 10h
 cmp AL,1Ah
 je  @carteVGAdetectee
 mov AL,FALSE
 jmp @fin
@carteVGAdetectee:
 mov AL,TRUE
@fin:
end; {CarteVGA}

{----------------------------------------------------------}

function DetecteVESA: BOOLEAN; assembler;
{renvoie TRUE si la carte vid‚o est au standard VESA}
var buffer: array[BYTE] of CHAR;
asm
 push SS
 pop ES
 lea DI,buffer
 mov AX,4F00h
 int 10h
 mov BL,FALSE
 cmp AX,004Fh
 jne @fin
 mov BL,TRUE
@fin:
 mov AL,BL
end;

{----------------------------------------------------------}

function NbrLecteurs: BYTE; assembler;
{renvoie le nombre de lecteurs de disquettes install‚s}
asm
 int 11h
 and AL,11000000b
{ shr AL,6}
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 inc AL
end; {NbrLecteurs}

{----------------------------------------------------------}

function NbrDisquesDurs: BYTE; assembler;
{renvoie le nombre de disques durs physiques install‚s
 Remarque: ne s'applique pas aux disques virtuels et lecteurs CD-ROM}
asm
 mov AH,08h
 mov DL,80h
 int 13h
 mov AL,DL
end; {NbrDisquesDurs}

{----------------------------------------------------------}

function LettreCDROM: CHAR; assembler;
{renvoie la lettre du premier lecteur CD-Rom trouv‚, sinon renvoie NUL (#0)}
asm
 mov AX,1500h
 xor BX,BX
 int 2Fh        {MSCDEX install‚?}
 xor AL,AL
 or  BX,BX
 jz  @fin       {non, ou pas de lecteur CD-Rom}

 mov AX,150Bh
 xor BX,BX
 xor CH,CH      {CX=nø lecteur CD-Rom}
 int 2Fh        {support‚ par MSCDEX?}
 cmp BX,0ADADh
 jne @pas_ok    {non}
 or  AX,AX
 jz  @fin       {erreur}

 mov AL,CL
 add AL,'A'     {ok, lettre trouv‚e}
 jmp @fin

@pas_ok:
 xor AL,AL
@fin:
end; {LettreCDROM}

{----------------------------------------------------------}

function ListeLecteurs: String26;
{renvoie une chaŒne contenant les lettres de tous les lecteurs disponibles}
var ch_liste: String26;
    ch_lecteur: array[1..3] of CHAR;
    FCB: array[1..37] of BYTE;
    lecteur: CHAR;
    ok: BOOLEAN;
begin
 ch_liste:='';
 for lecteur:='A' to 'Z' do begin
  ch_lecteur[1]:=lecteur;
  ch_lecteur[2]:=':';
  ch_lecteur[3]:=#0;
  asm
   push DS
   mov AX,2906h
   mov DX,SS
   mov DS,DX
   mov ES,DX
   lea SI,ch_lecteur
   lea DI,FCB
   int 21h
   mov ok,TRUE
   cmp AL,-1     {lecteur existe?}
   jne @fin      {oui}
   mov ok,FALSE
  @fin:
   pop DS
  end;
  if ok then ch_liste:=ch_liste+lecteur;
 end;
 if NbrLecteurs=1 then Delete(ch_liste,2,1); {supprime B}
 ListeLecteurs:=ch_liste;
end; {ListeLecteurs}

{------------------------------------------------}

function CheminAccesDOS(lecteur: CHAR): String80; assembler;
{renvoie le chemin d'accŠs DOS courant du lecteur (ne marche pas avec CD-Rom!)}
asm
 push DS
 cld
 mov AH,52h
 int 21h
 lds SI,ES:[BX+16h]  {DS:SI -> table des chemins d'accŠs}
 les DI,@Result
 push DI
 inc DI
 xor BL,BL           {longueur chemin}
 mov AL,lecteur
 sub AL,'A'
 mov CL,88
 mul CL
 add SI,AX           {DS:SI -> chemin d'accŠs au lecteur}
 lodsb
 cmp AL,'A'
 jb  @fin
 cmp AL,'Z'
 ja @fin
 stosb               {‚crit la lettre}
 lodsw
 cmp AX,'\:'
 jne @fin
 stosw               {‚crit ':\'}
 mov BL,3
@boucle:
 lodsb
 or  AL,AL
 jz  @fin
 stosb
 inc BL
 cmp BL,80
 jb  @boucle

@fin:
 pop DI
 mov ES:[DI],BL      {‚crit longueur chemin}
 pop DS
end; {CheminAccesDOS}

{----------------------------------------------------------}

function CheminAcces(lecteur: CHAR): String80;
{renvoie le chemin d'accŠs courant du lecteur (CD-Rom ou non...)}
var ch: String80;
begin
 if lecteur=LettreCDRom then
  begin GetDir(Ord(lecteur)-64,ch); CheminAcces:=ch end
 else CheminAcces:=CheminAccesDOS(lecteur);
end; {CheminAcces}

{----------------------------------------------------------}

function NomFichierDOS(nom_fichier: String80): String80; assembler;
{convertit un nom de chemin/fichier au format standard DOS
 -> remplace les '/' par des '\' et les minuscules par des majuscules}
asm
 push DS
 cld
 lds SI,nom_fichier
 les DI,@Result
 lodsb
 or  AL,AL
 stosb
 jz  @fin
 mov CL,AL
@boucle:
 lodsb
 cmp AL,'/'
 jne @pas_slash
 mov AL,'\'
 jmp @suite
 @pas_slash:
 cmp AL,'a'
 jb  @suite
 cmp AL,'z'
 ja  @suite
 sub AL,'a'-'A'
 @suite:
 stosb
 dec CL
 jnz @boucle
@fin:
 pop DS
end; {NomFichierDOS}

{----------------------------------------------------------}

function RepertTemp: String80;
{renvoie le nom du r‚pertoire temporaire s'il existe, sinon la racine 'C:\'}
var rep: String80;
begin
 rep:=GetEnv('TEMP');
 if rep='' then begin
  rep:=GetEnv('TMP');
  if rep='' then rep:='C:\';
 end;
 if rep[Length(rep)]<>'\' then rep:=rep+'\';
 RepertTemp:=rep;
end; {RepertTemp}

{----------------------------------------------------------}

function LecteurPhysique(lecteur: CHAR): BOOLEAN;
{renvoie TRUE si le lecteur existe physiquement}
var ch: String80;
begin
 if lecteur=LettreCDRom then LecteurPhysique:=(lecteur<>#0)
 else begin
  ch:=CheminAccesDOS(lecteur);
  LecteurPhysique:=(ch[1]=lecteur);
 end;
end; {LecteurPhysique}

{----------------------------------------------------------}

function TypeLecteur(lecteur: CHAR): BYTE;
{renvoie le type du lecteur (disque dur, lecteur 5"¬ ou 3"«, lecteur CD-Rom)}
var type_lecteur: BYTE;
begin
 if lecteur in ['A','B'] then begin
  asm
   mov AH,08h
   mov DL,lecteur
   sub DL,'A'
   int 13h
   inc BL
   shr BL,1
   mov type_lecteur,BL
  end;
  TypeLecteur:=type_lecteur;
 end
 else
  if lecteur=LettreCDROM then TypeLecteur:=lecteur_CDRom
  else TypeLecteur:=disque_dur;
end; {TypeLecteur}

{----------------------------------------------------------}

function _4DOS: BOOLEAN; assembler;
{renvoie TRUE si 4DOS est d‚tect‚}
asm
 mov AX,0D44Dh
 mov BX,0
 int 2Fh
 mov BL,FALSE
 cmp AX,44DDh
 jne @fin
 mov BL,TRUE
@fin:
 mov AL,BL
end; {_4DOS}

{----------------------------------------------------------}

function Win3X: BOOLEAN; assembler;
{renvoie TRUE si Windows 3.x est actif}
asm
 mov AX,4680h           { Win 3.x Standard check         }
 int 2Fh                { Call Int Multiplex             }
 or AX,AX               { if AX = 0 Win in REAL mode     }
 jnz @EnhancedCheck     { if not check for enhanced mode }
 mov AL,TRUE            { set Result to TRUE             }
 jmp @fin               { Go to end of routine           }
@EnhancedCheck:         { else check for enhanced mode   }
 mov AX,1600h           { Win 3.x Enhanced check         }
 int 2Fh                { Call Int Multiplex             }
 or AL,AL               { Check returned value           }
 jz @fin                { if not one of the below it     }
 cmp AL,80h             { is not installed               }
 mov AL,FALSE
 je @fin
 mov AL,TRUE            { Nope it must BE INSTALLED      }
@fin:
end; {Win3X}

{----------------------------------------------------------}

procedure AttendVBL; assembler;
{attend le retour vertical du faisceau}
asm
 mov DX,3DAh
@boucle:
 in  AL,DX
 and AL,00001000b
 jz @boucle
end; {AttendVBL}

{------------------------------------------------}

procedure AttendVBL2; assembler;
{attend le retour vertical du faisceau}
asm
 mov DX,3DAh
@boucle1:
 in  AL,DX
 and AL,00001000b
 jnz @boucle1
@boucle2:
 in  AL,DX
 and AL,00001000b
 jz  @boucle2
end; {AttendVBL2}

{------------------------------------------------}

procedure AttendHBL; assembler;
{attend le retour horizontal du faisceau}
asm
 mov DX,3DAh
@boucle:
 in  AL,DX
 and AL,00000001b
 jz  @boucle
end; {AttendHBL}

{----------------------------------------------------------}

procedure AttendHBL2; assembler;
{attend le retour horizontal du faisceau}
asm
 mov DX,3DAh
@boucle1:
 in  AL,DX
 and AL,00000001b
 jnz @boucle1
@boucle2:
 in  AL,DX
 and AL,00000001b
 jz  @boucle2
end; {AttendHBL2}

{----------------------------------------------------------}

procedure AttendFinHBL; assembler;
{attend la fin du retour horizontal du faisceau (nouvel ‚cran)}
asm
 mov DX,3DAh
@boucle:
 in  AL,DX
 and AL,00000001b
 jnz @boucle
end; {AttendFinHBL}

{----------------------------------------------------------}

procedure Curseur(forme: WORD); assembler;
{modifie la forme du curseur clignotant en mode texte}
asm
 mov AH,1
 mov CX,forme
 int 10h
end; {Curseur}

{----------------------------------------------------------}

function EntierTexte(entier: LONGINT; nombre_chiffres: BYTE): String12;
{convertit un nombre entier en chaŒne}
var chaine: String12;
begin
 Str(entier:nombre_chiffres,chaine);
 EntierTexte:=chaine;
end; {EntierTexte}

{----------------------------------------------------------}

function EntierTexte2(entier: LONGINT; nombre_chiffres: BYTE): STRING; assembler;
{convertit un nombre entier (-655359..+655359) en chaŒne (2 fois + rapide)
 1ónombre_chiffresó31, plus ‚ventuellement des options:
  et_zeros   : extension de z‚ros … gauche (seulement si entierò0)
  et_j_gauche: justification … gauche }
asm
 mov CH,nombre_chiffres
 xor CL,CL              {nombre de chiffres calcul‚s}
 mov BX,256*'0'+' '     {conversion d‚cimal->ASCII et extension … gauche}
 mov SI,10
 xor DI,DI
 mov DX,WORD(entier+2)
 mov AX,WORD(entier)
 or  DX,DX
 jns @divise
 neg DX
 neg AX
 jz  @ax0
 dec DX
@ax0:
 inc DI                 {n‚gatif->positif}

@divise:
 div SI
 add DL,BH              {d‚cimal->ASCII}
 push DX
 inc CL
 xor DX,DX
 or  AX,AX
 jnz @divise

 or  DI,DI              {positif?}
 jz @ecrit_longueur
 mov DL,'-'
 push DX
 inc CL
 and CH,not et_zeros    {pas d'extension de z‚ros pour les nombres<0}

@ecrit_longueur:
 les DI,@Result
 mov AL,CH
 and AL,00011111b       {masque les options->AL=nombre de chiffres voulus}
 cmp CL,AL
 jb  @plus_court
 mov BYTE(ES:[DI]),CL
 xor AL,AL              {pas de remplissage}
 jmp @suite
@plus_court:
 mov BYTE(ES:[DI]),AL
 sub AL,CL              {longueur remplissage=nombre chiffres voulus-calcul‚s}

@suite:
 inc DI
 test CH,et_j_gauche
 jz  @pas_j_gauche
@ecrit_chiffres:
 pop WORD(ES:[DI])
 inc DI
 dec CL
 jnz @ecrit_chiffres
 or  AL,AL
 jz  @fin
@remplissage:
 mov BYTE(ES:[DI]),BL
 inc DI
 dec AL
 jnz @remplissage
 jmp @fin

@pas_j_gauche:
 test CH,et_zeros
 jz  @pas_et_zeros
 mov BL,BH              {extension … gauche avec '0'}
@pas_et_zeros:
 or  AL,AL
 jz  @ecrit_chiffres2
@remplissage2:
 mov BYTE(ES:[DI]),BL
 inc DI
 dec AL
 jnz @remplissage2
@ecrit_chiffres2:
 pop WORD(ES:[DI])
 inc DI
 dec CL
 jnz @ecrit_chiffres2

@fin:
end; {EntierTexte2}

{----------------------------------------------------------}

function ReelTexte(reel: REAL; i,j: BYTE): String12;
{convertit un nombre r‚el en chaŒne}
var chaine: String12;
begin
 Str(reel:i:j,chaine);
 ReelTexte:=chaine;
end; {ReelTexte}

{----------------------------------------------------------}

function EntierHexa(entier: LONGINT; nombre_chiffres: BYTE): String8; assembler;
asm
 push DS
 cld

 les DI,@Result
 xor DH,DH
 mov DL,nombre_chiffres
 mov BYTE ptr ES:[DI],DL
 inc DI
 mov SI,DI
 mov CL,4

 mov AX,WORD(entier+2)
 mov CH,4
@boucle_poids_fort:
 rol AX,CL
 mov BL,AL
 and BL,00001111b
 cmp BL,9
 ja @sup_9_1
 add BL,'0'
 jmp @ecrit_chiffre_1
@sup_9_1:
 add BL,'A'-10
@ecrit_chiffre_1:
 mov BYTE ptr ES:[DI],BL
 inc DI
 dec CH
 jnz @boucle_poids_fort

 mov AX,WORD(entier)
 mov CH,4
@boucle_poids_faible:
 rol AX,CL
 mov BL,AL
 and BL,00001111b
 cmp BL,9
 ja @sup_9_2
 add BL,'0'
 jmp @ecrit_chiffre_2
@sup_9_2:
 add BL,'A'-10
@ecrit_chiffre_2:
 mov BYTE ptr ES:[DI],BL
 inc DI
 dec CH
 jnz @boucle_poids_faible

 push ES
 pop DS
 mov CX,DX
 mov DI,SI
 add SI,8
 sub SI,CX
 rep movsb
 pop DS
end; {EntierHexa}

{----------------------------------------------------------}

function MinEntier(entier1,entier2: INTEGER): INTEGER; assembler;
{renvoie le plus petit des deux entiers}
asm
 mov AX,entier1
 cmp AX,entier2
 jl  @fin
 mov AX,entier2
@fin:
end; {MinEntier}

{----------------------------------------------------------}

function MaxEntier(entier1,entier2: INTEGER): INTEGER; assembler;
{renvoie le plus grand des deux entiers}
asm
 mov AX,entier1
 cmp AX,entier2
 jg  @fin
 mov AX,entier2
@fin:
end; {MaxEntier}

{----------------------------------------------------------}

function LimiteEntier(entier,limite_inf,limite_sup: INTEGER): INTEGER; assembler;
{renvoie entier si î [limite_inf..limite_sup], sinon renvoie la limite d‚pass‚e}
asm
 mov DX,entier
 mov BX,limite_inf
 cmp DX,BX
 mov AX,BX
 jl  @fin
 mov AX,DX
 mov BX,limite_sup
 cmp AX,BX
 jng @fin
 mov AX,BX
@fin:
end; {LimiteEntier}

{----------------------------------------------------------}

function Sgn(x: INTEGER): SHORTINT; assembler;
{renvoie le signe de l'entier (0 ou ñ1}
asm
 mov AX,x
 or  AX,AX
 jz  @fin
 mov AL,+1
 jns @fin
 mov AL,-1
@fin:
end; {Sgn}

{----------------------------------------------------------}

function SwapB(b: BYTE): BYTE; assembler;
{‚change les 2 quartets d'un octet (ex: 12h -> 21h)}
asm
 mov AL,b
{ rol AL,4}
 rol AL,1
 rol AL,1
 rol AL,1
 rol AL,1
end; {SwapB}

{----------------------------------------------------------}

function SwapW(w: WORD): WORD; assembler;
{‚change les 2 octets d'un mot (ex: 1234h -> 3421h)
 utile pour conversion INTEL<->MOTOROLA}
asm
 mov AX,w
 xchg AH,AL
end; {SwapW}

{----------------------------------------------------------}

function SwapL(l: LONGINT): LONGINT; assembler;
{‚change les 2 mots d'un mot long (ex: 12345678h -> 56781234h)}
asm
 mov DX,WORD ptr l
 mov AX,WORD ptr l+2
end; {SwapL}

{----------------------------------------------------------}

function SwapLB(l: LONGINT): LONGINT; assembler;
{‚change les 4 octets d'un mot long (ex: 12345678h -> 78563412h)
 utile pour conversion INTEL<->MOTOROLA}
asm
 mov DX,WORD ptr l
 mov AX,WORD ptr l+2
 xchg DH,DL
 xchg AH,AL
end; {SwapLB}

{----------------------------------------------------------}

function AND_B(var valeur: BYTE; masque: BYTE): BYTE; assembler;
{effectue un and (8 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BL,masque
 and ES:[SI],BL
 mov AL,ES:[SI]
end; {AND_B}

{----------------------------------------------------------}

function OR_B(var valeur: BYTE; masque: BYTE): BYTE; assembler;
{effectue un or (8 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BL,masque
 or  ES:[SI],BL
 mov AL,ES:[SI]
end; {OR_B}

{----------------------------------------------------------}

function XOR_B(var valeur: BYTE; masque: BYTE): BYTE; assembler;
{effectue un xor (8 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BL,masque
 xor ES:[SI],BL
 mov AL,ES:[SI]
end; {XOR_B}

{----------------------------------------------------------}

function NOT_B(var valeur: BYTE): BYTE; assembler;
{effectue un not (8 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 not BYTE(ES:[SI])
 mov AL,ES:[SI]
end; {NOT_B}

{----------------------------------------------------------}

function AND_W(var valeur: WORD; masque: WORD): WORD; assembler;
{effectue un and (16 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,masque
 and ES:[SI],BX
 mov AX,ES:[SI]
end; {AND_W}

{----------------------------------------------------------}

function OR_W(var valeur: WORD; masque: WORD): WORD; assembler;
{effectue un or (16 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,masque
 or  ES:[SI],BX
 mov AX,ES:[SI]
end; {OR_W}

{----------------------------------------------------------}

function XOR_W(var valeur: WORD; masque: WORD): WORD; assembler;
{effectue un xor (16 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,masque
 xor ES:[SI],BX
 mov AX,ES:[SI]
end; {XOR_W}

{----------------------------------------------------------}

function NOT_W(var valeur: WORD): WORD; assembler;
{effectue un not (16 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 not WORD(ES:[SI])
 mov AX,ES:[SI]
end; {NOT_W}

{----------------------------------------------------------}

function AND_L(var valeur: LONGINT; masque: LONGINT): LONGINT; assembler;
{effectue un and (32 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,WORD(masque+2)
 and ES:[SI+2],BX
 mov DX,ES:[SI+2]
 mov BX,WORD(masque)
 and ES:[SI],BX
 mov AX,ES:[SI]
end; {AND_L}

{----------------------------------------------------------}

function OR_L(var valeur: LONGINT; masque: LONGINT): LONGINT; assembler;
{effectue un or (32 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,WORD(masque+2)
 or  ES:[SI+2],BX
 mov DX,ES:[SI+2]
 mov BX,WORD(masque)
 or  ES:[SI],BX
 mov AX,ES:[SI]
end; {OR_L}

{----------------------------------------------------------}

function XOR_L(var valeur: LONGINT; masque: LONGINT): LONGINT; assembler;
{effectue un xor (32 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 mov BX,WORD(masque+2)
 xor ES:[SI+2],BX
 mov DX,ES:[SI+2]
 mov BX,WORD(masque)
 xor ES:[SI],BX
 mov AX,ES:[SI]
end; {XOR_L}

{----------------------------------------------------------}

function NOT_L(var valeur: LONGINT): LONGINT; assembler;
{effectue un not (32 bits) de masque sur valeur et renvoie le r‚sultat}
asm
 les SI,valeur
 not WORD(ES:[SI+2])
 not WORD(ES:[SI])
 mov DX,ES:[SI+2]
 mov AX,ES:[SI]
end; {NOT_L}

{----------------------------------------------------------}

procedure SwapVar(var var1; var var2; taille: WORD); assembler;
{‚change deux variables de mˆme type (nombre,chaŒne,structure...)}
asm
 push DS

 mov CX,taille
 jcxz @fin

 lds SI,var1
 les DI,var2

 cmp SI,DI
 jne @debut
 mov AX,DS
 mov BX,ES
 cmp AX,BX
 je  @fin       {adresses identiques}

@debut:
 shr CX,1
 jnc @echange
 mov AL,[SI]
 xchg ES:[DI],AL
 mov [SI],AL
 jcxz @fin
 inc SI
 inc DI

@echange:
 mov AX,[SI]
 xchg ES:[DI],AX
 mov [SI],AX
 add SI,2
 add DI,2
 dec CX
 jnz @echange

@fin:
 pop DS
end; {SwapVar}

{----------------------------------------------------------}

function AddPtr(pointeur: POINTER; decalage: WORD): POINTER; assembler;
{renvoie la "somme" du pointeur avec le d‚calage.

 Remarque: avec l'option $X+ (syntaxe ‚tendue), le mˆme r‚sultat peut ˆtre
           obtenu en ‚crivant q:=p+d, o— 'p' est de type PChar et 'd' INTEGER}
asm
 les AX,pointeur
 mov DX,ES
 add AX,decalage
 jnc @fin
 inc DX
 sub AX,16
@fin:
end; {AddPtr}

{----------------------------------------------------------}

function NomFichierSeul(chemin: String80): String12;
{renvoie le nom de fichier (nomf.ext) d'un chemin complet
 (lecteur:\rep\...\sous_rep\nomf.ext)}
var p: BYTE;
begin
 p:=PosF('\',chemin);
 if p<>0 then NomFichierSeul:=CopyR(chemin,Length(chemin)-p)
 else begin
  p:=PosF(':',chemin);
  if p<>0 then NomFichierSeul:=CopyR(chemin,Length(chemin)-p)
          else NomFichierSeul:=chemin
 end
end; {NomFichierSeul}

{----------------------------------------------------------}

function RepertoireSeul(chemin: String80): String80;
{renvoie le chemin (lecteur:\rep\...\) priv‚ du nom de fichier
 d'un chemin complet (lecteur:rep\...\sous_rep\nomf.ext)}
begin
 RepertoireSeul:=CopyL(chemin,Length(chemin)-Length(NomFichierSeul(chemin)))
end; {RepertoireSeul}

{----------------------------------------------------------}

function ExtensionSeule(chemin: String80): String3;
{renvoie l'extension (ext) d'un chemin complet (lecteur:\rep\...\sous_rep\nomf.ext)}
var nom_fichier: String12;
    i: BYTE;
begin
 nom_fichier:=NomFichierSeul(chemin);
 i:=Pos('.',nom_fichier);
 if i=0 then ExtensionSeule:='' else ExtensionSeule:=Copy(nom_fichier,i+1,3)
end; {ExtensionSeule}

{----------------------------------------------------------}

function SousRepertoire(repert: String80): String12;
{renvoie le dernier sous-r‚pertoire (sous_rep) d'un chemin sans nom
 de fichier (lecteur:\rep\...\sous_rep[\])}
var p: BYTE;
begin
 if repert[Length(repert)]='\' then dec(repert[0]);
 p:=PosF('\',repert);
 if p=0 then SousRepertoire:=''
        else SousRepertoire:=CopyR(repert,Length(repert)-p)
end; {SousRepertoire}

{----------------------------------------------------------}

function CorrigeNomFichier(repertoire,nom_fichier: String80): String80;
var rep: String80;
begin
 rep:=RepertoireSeul(nom_fichier);
 if rep='' then rep:=repertoire
           else if rep[1]='.' then rep:=FExpand(repertoire+rep);
 CorrigeNomFichier:=rep+NomFichierSeul(nom_fichier)
end; {CorrigeNomFichier}

{----------------------------------------------------------}

function LimiteNomFichier(nom_fichier: String80; longueur: BYTE): String80; assembler;
{si nom_fichier est plus long que 'longueur', renvoie le nom de fichier
 limit‚ … 'longueur' caractŠres avec des '...' au milieu (longueur ò 24 !)}
asm
 push DS
 cld

 xor CH,CH
 lds SI,nom_fichier
 les DI,@Result
 lodsb
 mov AH,longueur
 cmp AL,AH
 jbe @copie

 xor BH,BH
 mov BL,AL
 add BX,SI
 dec BX
 xor DH,DH
 mov DL,AH
 add DX,DI

 mov AL,AH
 stosb
 mov CL,AH
 shr CL,1
 dec CL
 dec CL
 rep movsb
 mov AL,'.'
 stosb
 stosb
 stosb
 stosb

 std
 mov SI,BX
 mov DI,DX
 mov CL,AH
 shr CL,1
 dec CL
 rep movsb
 jmp @fin

@copie:
 stosb
 mov CL,AL
 rep movsb

@fin:
 pop DS
end; {LimiteNomFichier}

{----------------------------------------------------------}

function RepeteCar(car: CHAR; nombre: BYTE): STRING; assembler;
{renvoie une chaŒne de 'nombre' caractŠres 'car'}
asm
 cld
 les DI,@Result
 xor CH,CH
 mov CL,nombre
 mov AL,CL
 stosb
 mov AL,car
 mov AH,AL
 shr CL,1
 jnc @pair
 stosb
@pair:
 rep stosw
end; {RepeteCar}

{----------------------------------------------------------}

function Min(chaine: STRING): STRING; assembler;
{convertit une chaŒne en minuscules}
asm
 push DS
 cld

 lds SI,chaine
 les DI,@Result
 lodsb
 stosb
 or  AL,AL
 jz  @fin

 mov BL,AL
@boucle:
 lodsb
 cmp AL,'A'
 jb  @suite
 cmp AL,'Z'
 ja  @suite
 add AL,32
@suite:
 stosb
 dec BL
 jnz @boucle

@fin:
 pop DS
end; {Min}

{----------------------------------------------------------}

function Maj(chaine: STRING): STRING; assembler;
{convertit une chaŒne en majuscules en tenant compte des lettres accentu‚es}
const conv_maj: array[''..'˜'] of CHAR='UEAAAACEEEIIIAAE’’OOOUUY';
      ptr_conv_maj: POINTER=@conv_maj;
asm
 push DS
 cld

 lds SI,chaine
 les DI,@Result
 lodsb
 stosb
 or  AL,AL
 jz  @fin

 mov BL,AL
@boucle:
 lodsb
 cmp AL,'a'
 jb  @pas_min
 cmp AL,'z'
 ja  @pas_min
 sub AL,32
 jmp @suite
@pas_min:
 cmp AL,''
 jb  @suite
 cmp AL,'˜'
 ja  @suite
 mov DX,DS
 mov CX,BX
 pop DS
 push DS
 lds BX,ptr_conv_maj
 sub AL,''
 xlat
 mov DS,DX
 mov BX,CX
@suite:
 stosb
 dec BL
 jnz @boucle

@fin:
 pop DS
end; {Maj}

{----------------------------------------------------------}

function PosF(sous_chaine,chaine: STRING): BYTE; assembler;
{renvoie la position de 'sous-chaine' dans 'chaine' en commen‡ant la
 recherche par la FIN; renvoie 0 si pas trouv‚e}
asm
 push DS

 les DI,sous_chaine
 mov AL,ES:[DI]
 or  AL,AL
 jz  @fin       {sous-chaine=''}
 mov AH,AL
 lds SI,chaine
 mov AL,[SI]
 or  AL,AL
 jz  @fin       {chaine=''}
 cmp AL,AH
 jae @ok
 xor AL,AL
 jmp @fin       {sous-chaine plus longue que chaine}
@ok:
 xor BH,BH
 mov BL,AL
 add SI,BX      {DS:SI -> dernier car. de chaine}
 push DI
 mov BL,AH
 add DI,BX      {ES:DI -> dernier car. de sous-chaine}
 mov DX,DI
 pop BX

@cherche:
 mov AH,[SI]
 cmp AH,ES:[DI]
 je  @caractere_trouve
 mov DI,DX
 jmp @suite
@caractere_trouve:
 dec DI
 cmp DI,BX
 je  @fin
@suite:
 dec SI
 dec AL
 jnz @cherche

@fin:
 pop DS
end; {PosF}

{----------------------------------------------------------}

function CopyL(chaine: STRING; longueur: BYTE): STRING; assembler;
{renvoie la portion de chaŒne gauche de 'longueur' caractŠres}
asm
 push DS
 cld
 lds SI,chaine
 les DI,@Result
 lodsb
 xor CH,CH
 mov CL,longueur
 cmp AL,CL
 jae @suite
 mov CL,AL
@suite:
 mov AL,CL
 stosb
 rep movsb
 pop DS
end; {CopyL}

{----------------------------------------------------------}

function CopyR(chaine: STRING; longueur: BYTE): STRING; assembler;
{renvoie la portion de chaŒne droite de 'longueur' caractŠres}
asm
 push DS
 cld
 lds SI,chaine
 les DI,@Result
 lodsb
 xor DH,DH
 mov DL,AL
 xor CH,CH
 mov CL,longueur
 cmp AL,CL
 jae @suite
 mov CL,AL
@suite:
 mov AL,CL
 stosb
 sub DL,AL
 add SI,DX
 rep movsb
 pop DS
end; {CopyR}

{----------------------------------------------------------}

function XString(chaine: STRING; caractere: CHAR; longueur: BYTE): STRING; assembler;
{renvoie une chaŒne ‚tendue … 'longueur' caractŠres par 'caractere'
 (tronqu‚e si plus longue que 'longueur')}
asm
 push DS
 cld
 lds SI,chaine
 les DI,@Result
 lodsb
 xor CH,CH
 mov CL,longueur
 mov DL,CL
 cmp AL,DL
 jae @tronque

 xchg AL,CL
 stosb
 mov DH,CL
 rep movsb
 mov CL,DL
 sub CL,DH
 mov AL,caractere
 rep stosb
 jmp @fin

@tronque:
 mov AL,CL
 stosb
 rep movsb
@fin:
 pop DS
end; {XString}

function Str2Hex(chaine: STRING): WORD; assembler;
asm
 push DS
 cld
 lds SI,chaine
 mov bx,0
 lodsb
 mov dl,al
@Str2HexLoop:
 mov cl,4
 shl bx,cl
 lodsb
 cmp AL,'a'
 jb @NotAFm
 cmp al,'f'
 ja @NotAFm
 sub al,'a'-10
 jmp @AddValue   { String a-f found -> Add }
@NotAFm:
 cmp AL,'A'
 jb @NotAF
 cmp al,'F'
 ja @NotAF
 sub al,'A'-10
 jmp @AddValue   { String A-F found -> Add }
@NotAF:
 cmp AL,'0'
 jb @Err
 cmp al,'9'
 ja @Err
 sub al,'0'      { String 0-9 found -> Add }
@AddValue:
 add bl,al
 dec dl
 or dl,dl
 jne @Str2HexLoop
 jmp @end
@Err:
 mov bx,0        { Invalid Char detected }
@end:
 mov ax,bx
 pop DS
end; {XString}

{----------------------------------------------------------}

function XCString(chaine: STRING; caractere: CHAR; longueur: BYTE): STRING; assembler;
{renvoie une chaŒne centr‚e ‚tendue … 'longueur' caractŠres par 'caractere'
 (tronqu‚e si plus longue que 'longueur')}
asm
 push DS
 cld
 lds SI,chaine
 les DI,@Result
 lodsb
 xor CH,CH
 mov CL,longueur
 mov DL,CL
 cmp AL,DL
 jae @tronque

 mov BL,AL
 sub DL,AL
 shr DL,1
 mov DH,DL
 adc DH,0

 xchg AL,CL
 stosb
 mov CL,DL
 mov AL,caractere
 rep stosb
 mov CL,BL
 rep movsb
 mov CL,DH
 rep stosb
 jmp @fin

@tronque:
 mov AL,CL
 stosb
 rep movsb
@fin:
 pop DS
end; {XCString}

{----------------------------------------------------------}

procedure Pause(delai_18: BYTE);
{attend pendant 'delai_18' 18Šmes de seconde}
var timer_debut: LONGINT;
begin
 timer_debut:=Timer;
 repeat until Timer>=timer_debut+delai_18;
end; {Pause}

{----------------------------------------------------------}

procedure SwapIntVec(n_int: BYTE; var old: POINTER; new: POINTER); assembler;
{renvoie l'ancien vecteur d'interruption dans 'old' et installe le nouveau
 … l'adresse point‚e par 'new'}
asm
 push DS
 cli
 cld
 les DI,old
 xor DX,DX
 mov DS,DX
 xor BH,BH
 mov BL,n_int
{ shl BX,2 }
 shl BX,1
 shl BX,1
 mov SI,BX
 movsw
 movsw
 xor DX,DX
 mov ES,DX
 mov DI,BX
 push SS
 pop DS
 lea SI,new
 movsw
 movsw
 sti
 pop DS
end; {SwapIntVec}

{==========================================================}

END.
