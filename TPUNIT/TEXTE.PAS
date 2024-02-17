{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                       --==ðð TEXTE.PAS ðð==--                        º}
{º                                                                      º}
{º Unit‚ pour g‚rer le mode texte sur ‚cran couleur (CGA, VGA et SVGA)  º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚:  86           D‚but d'‚critureúúúúúúúúúúúúúú ??/10/93 º}
{º                              DerniŠres modificationsúúúúúúú 26/07/98 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}
{ FV : Modified for CGA Only and Hercule in 2019}

UNIT Texte;

{$A+,G-,Q-,R-,S-}

INTERFACE

{$I Types}

CONST {variables d‚pendant du mode texte courant}
      delta_segment_VRAM: WORD=16+((80*25) shr 3); {variation de segment RAM vid‚o d'une page vers la suivante}
      largeur_ecran_txt : BYTE=80;  {nombre de colonnes de l'‚cran texte (virtuelles si >80)}
      hauteur_ecran_txt : BYTE=25;  {nombre de lignes visibles de l'‚cran texte}
      largeur_car: BYTE= 9; {largeur d'un caractŠre en pixels}
      hauteur_car: BYTE=16; {hauteur d'un caractŠre en pixels}

      {dimensions max de l'‚cran texte en colonnes/lignes}
      largeur_ecran_max=80; {CGA}
      hauteur_ecran_max=25; {CGA}

      {adresse et attribut courants pour AffCar/AffCh}
	  Hercule  : Byte = 0;
      SegTexte : Word = $B800;
      AdrTexte : WordPtr=Ptr($B800,0);
      AttrTexte: BYTE=16*0+7;

      {tables de caractŠres pour PointeurTable}
      table8x16=6;
      table8x14=2;
      table8x8 =3;
      courante =0;

      {modes pour RedefCar}
      ascii  =1;
      binaire=2;

      {codes d'erreur pour .Charge_ de Palette16, FonteXX, Zone}
      err_format=1;

{
https://www.seasip.info/VintagePC/mda.html
Bit 1: Underline.
Bit 3: High intensity.
Bit 7: Blink
but there are eight exceptions:
Attributes 00h, 08h, 80h and 88h display as black space.
Attribute 70h displays as black on green.
Attribute 78h displays as dark green on green.
Attribute F0h displays as a blinking version of 70h (if blinking is enabled); as black on bright green otherwise.
Attribute F8h displays as a blinking version of 78h (if blinking is enabled); as dark green on bright green otherwise.
}

TYPE {type pour objets Zone et Ecran}
     VRAM=array[1..largeur_ecran_max*hauteur_ecran_max] of
           record attr: BYTE; car: CHAR end;

     Zone=object
           xg_,yh_,xd_,yb_: INTEGER; {xg_,yh_: coin sup‚rieur gauche
                                      xd_,yb_: coin inf‚rieur droit}
           procedure Sauve(page: BYTE; xg,yh,xd,yb: INTEGER);
           procedure Ombre(page: BYTE; xg,yh,xd,yb: INTEGER; attr: BYTE);
           procedure RestaureLimite(page: BYTE; x,y: INTEGER; xg,yh,xd,yb: BYTE);
           procedure Restaure(page: BYTE; dx,dy: SHORTINT; attr: BYTE);
           procedure DeplaceLimite(page: BYTE; dx,dy: SHORTINT; var zone_cachee: Zone; xg,yh,xd,yb: BYTE);
           procedure Deplace      (page: BYTE; dx,dy: SHORTINT; var zone_cachee: Zone);
           procedure Supprime;
           procedure Charge_(nom_fichier: String80; var erreur: WORD);
           procedure Sauve_ (nom_fichier: String80; var erreur: WORD);
          private
           taille_octets: WORD; {=2*(xd_-xg_+1)*(yb_-yh_+1)}
           contenu: ^VRAM;
          end;

     Ecran=object
           procedure Sauve(page: BYTE);
           procedure Restaure(page: BYTE);
           procedure Supprime;
          private
           contenu: ^VRAM;
          end;
		  
{==========================================================}

procedure InitTexte; {80*25}
procedure Clignotement(clignote: BOOLEAN);
Function Detect_Mono:Boolean;
procedure SetHerculeAddr;

procedure CursXY(page,x,y: BYTE);
function  PosX(page: BYTE): BYTE;
function  PosY(page: BYTE): BYTE;

function  PtrVRAM(page,x,y: BYTE): WordPtr;

procedure AffCarXY(page,x,y: BYTE; caractere: CHAR; attr: BYTE);
procedure AffChXY (page,x,y: BYTE; chaine: STRING; attr: BYTE);
procedure AffChXY2(page,x,y: BYTE; chaine: STRING; attr_ext,attr_int: BYTE);
procedure AffChXYmc(page,x,y: BYTE; chaine: STRING);
procedure AffCar(caractere: CHAR);
procedure AffCh(chaine: STRING);
procedure AffChE(chaine: STRING; caractere: CHAR; longueur: BYTE);

procedure LigneHorizontale(page,epaisseur,y,xg,xd,attr: BYTE);
procedure LigneVerticale  (page,epaisseur,x,yh,yb,attr: BYTE);
procedure Cadre(page,epaisseur,xg,yh,xd,yb,attr: BYTE; titre: STRING; attr_titre: BYTE; touches: String25);

function  CodeXY(page,x,y: BYTE): BYTE;
function  AttrXY(page,x,y: BYTE): BYTE;

procedure EffaceZone(page,xg,yh,xd,yb,attr: BYTE);
procedure EffacePage(page,attr: BYTE);
procedure ChangePage(page: BYTE);
procedure CopiePage (page_source,page_dest: BYTE);

procedure ScrolleZoneHaut  (page,xg,yh,xd,yb: BYTE);
procedure ScrolleZoneBas   (page,xg,yh,xd,yb: BYTE);
procedure ScrolleZoneGauche(page,xg,yh,xd,yb: BYTE);
procedure ScrolleZoneDroite(page,xg,yh,xd,yb: BYTE);

{==========================================================}

IMPLEMENTATION

USES Fichiers,Util;

{==========================================================}

procedure InitTexte;
{initialise le mode texte 80 colonnes x 25/28/50 lignes}
begin
 asm
  mov AX,03h   {mode texte standard 80x25 16 couleurs par défaut}
  int 10h
 end;
 largeur_ecran_txt:=80;
 delta_segment_VRAM:=256;
 hauteur_ecran_txt:=25;

 {AdrTexte :=Ptr($B800,0);}
 AttrTexte:=16*0+7;
end; {InitTexte}

{----------------------------------------------------------}

procedure Clignotement(clignote: BOOLEAN); assembler;
{si clignote=TRUE, les couleurs>=128 clignotent, sinon le fond est plus clair}
asm
 mov AX,1A00h {fonction 1Ah du BIOS EGA/VGA pour tester si carte EGA ou VGA}
 int 10h
 cmp AL,1Ah
 je  @egavga  {c'est une carte VGA}
 mov AH,12h
 mov BL,10h   {sous-fonction 10h de la fonction 12h du BIOS EGA/VGA}
 int 10h
 cmp BL,10h   {BL a chang‚?}
 jne @egavga  {oui, c'est donc une carte EGA}
 {on suppose ici que c'est une carte CGA!}
 mov AL,00101001b   {par d‚faut, active le clignotement}
 cmp clignote,TRUE
 je  @suiteCGA
 mov AL,00001001b   {d‚sactive le clignotement}
@suiteCGA:
 mov DX,3D8h  {contr“leur CRT de la carte CGA}
 out DX,AL    {fixe l'attribut}
 jmp @fin
@egavga:
 mov AX,1003h {fonction 10h du BIOS EGA/VGA pour fixer l'attribut clignotement}
 mov BL,clignote
 int 10h
@fin:
end; {Clignotement}

Function Detect_Mono:Boolean; assembler;
 asm
  mov AH,0Fh   {Get Video Mode}
  int 10h
  CMP AL,07
  JE @MDAOk
  XOR AX,AX
  RET
@MDAOk:
  MOV AX,1
 end;

procedure SetHerculeAddr;  { Change the Video memory Segment Value for Hercule }
Begin
Hercule  :=1;
AdrTexte :=Ptr($B000,0);
SegTexte := $B000;
end;

{----------------------------------------------------------}

procedure CursXY(page,x,y: BYTE); assembler;
{‚quivalent de GotoXY multi-page en mode 25,28,50 lignes}
asm
 mov AH,2
 mov BH,page
 mov DH,y
 dec DH
 mov DL,x
 dec DL
 int 10h
end; {CursXY}

{----------------------------------------------------------}

function PosX(page: BYTE): BYTE; assembler;
{renvoie l'abscisse du curseur clignotant dans la page}
asm
 mov AH,3
 mov BH,page
 int 10h
 inc DL
 mov AL,DL
end; {PosX}

{----------------------------------------------------------}

function PosY(page: BYTE): BYTE; assembler;
{renvoie l'ordonn‚e du curseur clignotant dans la page}
asm
 mov AH,3
 mov BH,page
 int 10h
 inc DH
 mov AL,DH
end; {PosY}

{----------------------------------------------------------}

function PtrVRAM(page,x,y: BYTE): WordPtr; assembler;
{renvoie un pointeur sur la m‚moire vid‚o en (x,y)}
asm
 xor AH,AH
; mov AL,page
; mul delta_segment_VRAM
; add AX,SegTexte
 mov ax,SegTexte
 mov ES,AX           {ES=B800+delta_segment_VRAM*page}

 xor AH,AH
 mov AL,x
 mov BX,AX
 dec BX              {BX=x-1}
 mov AL,y
 dec AL
 mul largeur_ecran_txt  {AX=largeur_ecran_txt*(y-1)}
 add AX,BX
 shl AX,1            {AX=2*((x-1)+largeur_ecran_txt*(y-1))}
 mov DX,ES
end; {PtrVRAM}

{----------------------------------------------------------}

procedure AffCarXY(page,x,y: BYTE; caractere: CHAR; attr: BYTE);
{affiche un caractŠre en (x,y)}
var ptr_VRAM: POINTER;
begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 asm
 
  CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:
 
  les DI,ptr_VRAM
  mov AH,attr
  mov AL,caractere
  mov ES:[DI],AX
 end;
end; {AffCarXY}

{----------------------------------------------------------}

procedure AffCarXYn(page,x,y,n: BYTE; caractere: CHAR; attr: BYTE);
{affiche un caractŠre en (x,y)}
var ptr_VRAM: POINTER;
begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 asm
 
  CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:
 
  les DI,ptr_VRAM
  mov AH,attr
  mov AL,caractere
  mov ES:[DI],AX
 end;
end; {AffCarXY}

{----------------------------------------------------------}

procedure AffChXY(page,x,y: BYTE; chaine: STRING; attr: BYTE);
{affiche une chaŒne en (x,y)}
var ptr_VRAM: POINTER;
begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 asm
  push DS
  cld
  
  CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:

  les DI,ptr_VRAM
  push SS
  pop DS
  lea SI,chaine
  lodsb               {AL=longueur chaŒne}
  or  AL,AL
  jz  @fin            {chaŒne vide}
  mov AH,attr
  mov BL,AL

 @affiche_car:
  lodsb               {AL=code ASCII}
  stosw               {affiche un caractŠre}
  dec BL
  jnz @affiche_car

 @fin:
  pop DS
 end;
end; {AffChXY}

{----------------------------------------------------------}

procedure AffChXY2(page,x,y: BYTE; chaine: STRING; attr_ext,attr_int: BYTE);
{affiche une chaŒne avec l'attribut 'attr_ext', sauf les portions de chaŒne
 d‚limit‚es par des '^' qui sont affich‚es avec l'attribut 'attr_int'}
var ptr_VRAM: POINTER;
begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 asm
  push DS
  cld

  CMP Hercule,0
  JE @NoHercule
  AND Attr_int,7Eh
  AND Attr_ext,7Eh
@NoHercule:

  les DI,ptr_VRAM
  push SS
  pop DS
  lea SI,chaine
  lodsb               {AL=longueur chaŒne}
  or  AL,AL
  jz  @fin            {chaŒne vide}

  mov AH,attr_ext     {AH=attribut couleur par d‚faut}
  mov BH,attr_int     {BH=attribut 2Šme couleur}
  mov BL,AL

 @affiche_car:
  lodsb               {AL=code ASCII}
  cmp AL,'^'          {caractŠre de contr“le '^' ?}
  je  @echange_attr   {oui}
  stosw               {affiche un caractŠre}
  jmp @suite
 @echange_attr:
  xchg AH,BH          {‚change attr_ext et attr_int}
 @suite:
  dec BL
  jnz @affiche_car

 @fin:
  pop DS
 end;
end; {AffChXY2}

{----------------------------------------------------------}

procedure AffChXYmc(page,x,y: BYTE; chaine: STRING);
{affiche une chaŒne avec plusieurs attributs de couleur, selon le format:
  caractŠre de contr“le: '^', suivi par la valeur de l'attribut: 0..255 }
var ptr_VRAM: POINTER;
begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 asm
  push DS
  cld

  les DI,ptr_VRAM
  push SS
  pop DS
  lea SI,chaine
  lodsb               {AL=longueur chaŒne}
  or  AL,AL
  jz  @fin            {chaŒne vide}

  mov BL,AL

 @affiche_chaine:
  lodsb               {AL=code ASCII}
  cmp AL,'^'
  jne @affiche_car
  dec BL
  lodsb               {AL=attribut}
  mov AH,AL
  jmp @suite
 @affiche_car:
  stosw
 @suite:
  dec BL
  jnz @affiche_chaine

 @fin:
  pop DS
 end;
end; {AffChXYmc}

{----------------------------------------------------------}

procedure AffCar(caractere: CHAR); assembler;
{affiche un caractŠre … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis incr‚mente la position courante}
asm
 les DI,AdrTexte
 mov AH,AttrTexte
 mov AL,caractere
 mov ES:[DI],AX
 add WORD(AdrTexte),2
end; {AffCar}

{----------------------------------------------------------}

procedure AffCh(chaine: STRING); assembler;
{affiche une chaŒne … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis d‚place la position courante … la fin de la chaŒne}
asm
 push DS
 cld

 les DI,AdrTexte
 mov AH,AttrTexte
 lds SI,chaine
 lodsb               {AL=longueur chaŒne}
 xor DH,DH
 mov DL,AL
 shl DX,1
 jz  @fin            {chaŒne vide}
 mov BL,AL

@affiche_car:
 lodsb               {AL=code ASCII}
 stosw               {affiche un caractŠre}
 dec BL
 jnz @affiche_car

@fin:
 pop DS

 add WORD(AdrTexte),DX
end; {AffCh}

{----------------------------------------------------------}

procedure AffChE(chaine: STRING; caractere: CHAR; longueur: BYTE); assembler;
{affiche une chaŒne … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis d‚place la position courante … la fin de la chaŒne
 l'affichage est limit‚ … 'longueur' caractŠres: si la chaŒne est plus
 courte, l'affichage est compl‚t‚ par 'caractere'

 c'est un raccourci pour AffCh(XString(chaine,caractere,longueur))}
asm
 push DS
 cld

 les DI,AdrTexte
 mov AH,AttrTexte
 lds SI,chaine
 lodsb              {AL=longueur chaŒne}
 mov BL,AL
 mov DL,longueur
 mov CL,DL
 sub CL,AL
 jns @affiche_ch

 mov BL,DL
 xor CL,CL

@affiche_ch:
 or  BL,BL
 jz  @suite

@affiche_car:
 lodsb
 stosw
 dec BL
 jnz @affiche_car

@suite:
 xor CH,CH
 mov AL,caractere
 rep stosw

 pop DS

 xor DH,DH
 shl DX,1
 add WORD(AdrTexte),DX
end; {AffChE}

{----------------------------------------------------------}

procedure LigneHorizontale(page,epaisseur,y,xg,xd,attr: BYTE);
var ptr_VRAM: POINTER;
begin
 if xd<xg then exit;

 ptr_VRAM:=PtrVRAM(page,xg,y);
 asm
 
   CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:
 
  les DI,ptr_VRAM
  mov AH,attr
  mov AL,'Ä'        {par d‚faut, ‚paisseur=1}
  cmp epaisseur,1
  je  @suite
  mov AL,'Í'
 @suite:
  xor CH,CH
  mov CL,xd
  sub CL,xg
  inc CL            {CX=xd-xg+1}
  cld
  rep stosw         {affiche ligne}
 end;
end; {LigneHorizontale}

{----------------------------------------------------------}

procedure LigneVerticale(page,epaisseur,x,yh,yb,attr: BYTE);
var ptr_VRAM: POINTER;
begin
 if yb<yh then exit;

 ptr_VRAM:=PtrVRAM(page,x,yh);
 asm
 
   CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:
 
  les DI,ptr_VRAM
  xor DH,DH
  mov DL,largeur_ecran_txt
  dec DL
  shl DX,1            {incr‚ment DI: DX=2*(largeur_ecran_txt-1)}
  mov AH,attr
  mov AL,'³'          {par d‚faut, ‚paisseur=1}
  cmp epaisseur,1
  je  @suite
  mov AL,'º'
 @suite:
  mov CL,yb
  sub CL,yh
  inc CL              {CL=yb-yh+1}
  cld
 @affiche_ligne:
  stosw
  add DI,DX
  dec CL
  jnz @affiche_ligne
 end;
end; {LigneVerticale}

{----------------------------------------------------------}

procedure Cadre(page,epaisseur,xg,yh,xd,yb,attr: BYTE; titre: STRING; attr_titre: BYTE; touches: String25);
{trace un cadre de coordonn‚es (xg,yh,xd,yb), d'‚paisseur 1 ou 2, avec la couleur 'attr'
 -le titre est centr‚ en haut du cadre, affich‚ avec la couleur 'attr_titre'
 -la chaŒne 'touches' est affich‚e dans le coin inf‚rieur droit du cadre}

const coin1: array[1..2] of CHAR=('Ú','É');
      coin2: array[1..2] of CHAR=('¿','»');
      coin3: array[1..2] of CHAR=('À','È');
      coin4: array[1..2] of CHAR=('Ù','¼');
      horiz: array[1..2] of CHAR=('Ä','Í');

var n: BYTE;

begin
 if xg>xd then begin n:=xg; xg:=xd; xd:=n end;
 if yh>yb then begin n:=yh; yh:=yb; yb:=n end;
 if (xd>xg) and (yb>yh) then begin
  n:=(xd-xg-1)-Length(titre);
  AffCarXY(page,xg,yh,coin1[epaisseur],attr);
  LigneHorizontale(page,epaisseur,yh,xg+1,xg+(n shr 1),attr);
  LigneHorizontale(page,epaisseur,yh,xd-n+(n shr 1),xd-n-1+(n and $FE),attr);
  if Odd(n) then AffChXY (page,xd-n+(n and $FE),yh,horiz[epaisseur]+coin2[epaisseur],attr)
            else AffCarXY(page,xd-n+(n and $FE),yh,coin2[epaisseur],attr);
  LigneVerticale(page,epaisseur,xg,yh+1,yb-1,attr);
  LigneVerticale(page,epaisseur,xd,yh+1,yb-1,attr);
  AffCarXY(page,xg,yb,coin3[epaisseur],attr);
  LigneHorizontale(page,epaisseur,yb,xg+1,xd-1,attr);
  AffCarXY(page,xd,yb,coin4[epaisseur],attr);
  AffChXY(page,xg+(n shr 1)+1,yh,titre,attr_titre);
  AffChXY(page,xd-1-Length(touches),yb,touches,attr);
 end
 else
  if xg=xd then LigneVerticale(page,epaisseur,xg,yh,yb,attr)
           else if yh=yb then LigneHorizontale(page,epaisseur,yh,xg,xd,attr);
end; {Cadre}

{----------------------------------------------------------}

function CodeXY(page,x,y: BYTE): BYTE;
{renvoie le code ASCII du caractŠre en (x,y)}
begin
 CodeXY:=BytePtr(PtrVRAM(page,x,y))^;
end; {CodeXY}

{----------------------------------------------------------}

function AttrXY(page,x,y: BYTE): BYTE;
{renvoie l'attribut du caractŠre en (x,y)}
begin
 AttrXY:=Hi(WordPtr(PtrVRAM(page,x,y))^);
end; {AttrXY}

{----------------------------------------------------------}

procedure Transfert(sens: SHORTINT;
                    source: POINTER; delta_source: INTEGER;
                    destination: POINTER; delta_dest: INTEGER; Ncol,Nlig: BYTE); assembler;
asm
 push DS
 cld
 cmp sens,+1
 je  @suite    {croissant}
 std
@suite:
 lds SI,source
 les DI,destination
 mov AX,delta_source
 mov DX,delta_dest
 mov BL,Ncol
 mov BH,Nlig
 xor CH,CH
@copie:
 mov CL,BL
 rep movsw
 add SI,AX
 add DI,DX
 dec BH
 jnz @copie
 pop DS
end; {Transfert}

{----------------------------------------------------------}

procedure Zone.Sauve(page: BYTE; xg,yh,xd,yb: INTEGER);
{sauve une zone de l'‚cran (les coordonn‚es peuvent sortir des limites)}
var L,H,Ncol,Nlig: BYTE;
    xg_zone,yh_zone,xd_zone,yb_zone: INTEGER;
    DI: WORD;
begin
 if (xd<xg) or (yb<yh) then begin taille_octets:=0; exit end;

 L:=xd-xg+1; H:=yb-yh+1; taille_octets:=2*L*H;
 xg_:=xg; yh_:=yh; xd_:=xd; yb_:=yb;
 GetMem(contenu,taille_octets);
 xg_zone:=MaxEntier(1,xg); xd_zone:=MinEntier(largeur_ecran_txt,xd);
 yh_zone:=MaxEntier(1,yh); yb_zone:=MinEntier(hauteur_ecran_txt,yb);
 if (xd_zone<xg_zone) or (yb_zone<yh_zone) then exit; {zone hors ‚cran}

 Ncol:=xd_zone-xg_zone+1; Nlig:=yb_zone-yh_zone+1;
 DI:=0;
 if yh<1 then inc(DI,2*(1-yh)*L);
 if xg<1 then inc(DI,2*(1-xg));
 Transfert(+1,PtrVRAM(page,xg_zone,yh_zone),2*(largeur_ecran_txt-Ncol),AddPtr(contenu,DI),2*(L-Ncol),Ncol,Nlig);
end; {Zone.Sauve}

{----------------------------------------------------------}

procedure Zone.Ombre(page: BYTE; xg,yh,xd,yb: INTEGER; attr: BYTE);
{sauve une zone et affiche un rectangle d'attribut 'attr' avec une ombre sur
 les bords gauche et inf‚rieur}
var ombre_horiz,ombre_vertic: Zone;
begin
 Zone.Sauve(page,xg,yh,xd+2,yb+1);
 with ombre_horiz do
  begin Sauve(page,xg+2,yb+1,xd+2,yb+1); Restaure(page,0,0,8); Supprime end;
 with ombre_vertic do
  begin Sauve(page,xd+1,yh+1,xd+2,yb); Restaure(page,0,0,8); Supprime end;
 EffaceZone(page,MaxEntier(1,xg),MaxEntier(1,yh),
                 MinEntier(largeur_ecran_txt,xd),MinEntier(hauteur_ecran_txt,yb),attr);
end; {Zone.Ombre}

{----------------------------------------------------------}

procedure Zone.RestaureLimite(page: BYTE; x,y: INTEGER; xg,yh,xd,yb: BYTE);
{affiche la zone en (x,y) dans les limites de la fenˆtre (xg,yh,xd,yb)}
var L,H,Ncol,Nlig: BYTE;
    xg_zone,yh_zone,xd_zone,yb_zone: INTEGER;
    SI: WORD;
begin
 L:=xd_-xg_+1; H:=yb_-yh_+1;
 xg_zone:=MaxEntier(xg,x); xd_zone:=MinEntier(xd,x+L-1);
 yh_zone:=MaxEntier(yh,y); yb_zone:=MinEntier(yb,y+H-1);
 if (xd_zone<xg_zone) or (yb_zone<yh_zone) then exit; {zone hors ‚cran}

 Ncol:=xd_zone-xg_zone+1; Nlig:=yb_zone-yh_zone+1;
 SI:=0;
 if y<yh then inc(SI,2*(yh-y)*L);
 if x<xg then inc(SI,2*(xg-x));
 Transfert(+1,AddPtr(contenu,SI),2*(L-Ncol),PtrVRAM(page,xg_zone,yh_zone),2*(largeur_ecran_txt-Ncol),Ncol,Nlig);
end; {Zone.RestaureLimite}

{----------------------------------------------------------}

procedure Zone.Restaure(page: BYTE; dx,dy: SHORTINT; attr: BYTE);
{restaure la zone avec un d‚placement ‚ventuel (dx,dy)
 -si attr=0, les couleurs d'origine sont conserv‚es
 -sinon, la zone est restaur‚e avec l'attribut 'attr'}
var ptr_contenu: POINTER;
    taille_octets_: WORD;
begin
 if taille_octets=0 then exit;

 if attr<>0 then begin
  ptr_contenu:=contenu; taille_octets_:=taille_octets;
  asm
  
  CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:
  
   les DI,ptr_contenu
   inc DI              {ES:DI -> premier attribut … changer}
   cld
   mov CX,taille_octets_
   shr CX,1            {CX=nombre caractŠres}
   mov AL,attr
  @ecrit_attr:
   stosb               {‚crit attribut}
   inc DI              {saute code ASCII}
   dec CX
   jnz @ecrit_attr
  end;
 end;
 Zone.RestaureLimite(page,xg_+dx,yh_+dy,1,1,largeur_ecran_txt,hauteur_ecran_txt);
end; {Zone.Restaure}

{----------------------------------------------------------}

procedure Zone.DeplaceLimite(page: BYTE; dx,dy: SHORTINT; var zone_cachee: Zone; xg,yh,xd,yb: BYTE);
{d‚place une zone sur l'‚cran dans les limites (xg,yh,xd,yb) et modifie ses
 coordonn‚es; zone_cachee doit d‚j… contenir le fond reconvert}
begin
 with zone_cachee do
  begin RestaureLimite(page,xg_,yh_,xg,yh,xd,yb); Supprime; Sauve(page,xg_+dx,yh_+dy,xd_+dx,yb_+dy) end;
 inc(xg_,dx); inc(xd_,dx); inc(yh_,dy); inc(yb_,dy);
 Zone.RestaureLimite(page,xg_,yh_,xg,yh,xd,yb);
end; {Zone.DeplaceLimite}

{----------------------------------------------------------}

procedure Zone.Deplace(page: BYTE; dx,dy: SHORTINT; var zone_cachee: Zone);
{d‚place une zone dans les limites de l'‚cran et modifie ses coordonn‚es;
 zone_cachee doit d‚j… contenir le fond reconvert}
var SI,DI: WORD;
    L,H,LI,HI,x,y: BYTE;
    sens_copie: SHORTINT;
    ptr_contenu: POINTER;
    delta_L,delta_dx,delta_copie: INTEGER;
begin
 L:=xd_-xg_+1; H:=yb_-yh_+1;

 if (Abs(dx)<L) and (Abs(dy)<H) then begin  {intersection}
  LI:=L-Abs(dx); HI:=H-Abs(dy);
  ptr_contenu:=zone_cachee.contenu;

  {restaure}
  if dy<>0 then begin
   SI:=0; delta_L:=2*(largeur_ecran_txt-L);
   if dy>0 then begin y:=yh_ end else begin inc(SI,2*HI*L); y:=yb_+dy+1 end;
   Transfert(+1,AddPtr(ptr_contenu,SI),0,PtrVRAM(page,xg_,y),delta_L,L,Abs(dy))
  end;
  if dx<>0 then begin
   SI:=0; y:=yh_; delta_dx:=2*(largeur_ecran_txt-Abs(dx));
   if dx>0 then x:=xg_ else begin x:=xd_+dx+1; inc(SI,2*LI) end;
   if dy>0 then begin inc(SI,2*L*dy); inc(y,dy) end;
   Transfert(+1,AddPtr(ptr_contenu,SI),2*LI,PtrVRAM(page,x,y),delta_dx,Abs(dx),HI)
  end;

  {copie}
  if dy=0 then sens_copie:=Sgn(dx) else sens_copie:=Sgn(dy);
  if dx*dy>=0 then begin SI:=2*dx; DI:=0 end else begin SI:=0; DI:=-2*dx end;
  if dy<>0 then inc(SI,2*L*dy);
  if sens_copie=-1 then begin inc(SI,taille_octets-2); inc(DI,taille_octets-2) end;
  delta_copie:=2*Abs(dx)*sens_copie;
  Transfert(sens_copie,AddPtr(ptr_contenu,SI),delta_copie,AddPtr(ptr_contenu,DI),delta_copie,LI,HI);

  {sauve}
  if dy<>0 then begin
   if dy>0 then begin DI:=2*HI*L; y:=yb_+1 end else begin DI:=0; y:=yh_+dy end;
   Transfert(+1,PtrVRAM(page,xg_+dx,y),delta_L,AddPtr(ptr_contenu,DI),0,L,Abs(dy))
  end;
  if dx<>0 then begin
   DI:=0; y:=yh_;
   if dx>0 then begin x:=xd_+1; inc(DI,2*LI) end else x:=xg_+dx;
   if dy<0 then inc(DI,-2*L*dy) else inc(y,dy);
   Transfert(+1,PtrVRAM(page,x,y),delta_dx,AddPtr(ptr_contenu,DI),2*LI,Abs(dx),HI)
  end;

  with zone_cachee do begin inc(xg_,dx); inc(xd_,dx); inc(yh_,dy); inc(yb_,dy) end;
 end
 else  {pas d'intersection}
  with zone_cachee do
   begin Restaure(page,0,0,0); Supprime; Sauve(page,xg_+dx,yh_+dy,xd_+dx,yb_+dy) end;

 inc(xg_,dx); inc(xd_,dx); inc(yh_,dy); inc(yb_,dy);
 Zone.Restaure(page,0,0,0);
end; {Zone.Deplace}

{----------------------------------------------------------}

procedure Zone.Supprime;
begin
 if taille_octets>0 then FreeMem(contenu,taille_octets);
end; {Zone.Supprime}

{----------------------------------------------------------}

procedure Zone.Charge_(nom_fichier: String80; var erreur: WORD);
var f: Fichier;
begin
 with f do begin
  Ouvre(lecture,nom_fichier);
  if f_erreur=f_ok then begin
   erreur:=0;
   Lit(xg_,2); Lit(yh_,2); Lit(xd_,2); Lit(yb_,2);
   taille_octets:=2*(xd_-xg_+1)*(yb_-yh_+1);
   if (2*4+taille_octets<>Taille) or
      (xg_>xd_) or (yh_>yb_) or
      (xd_>largeur_ecran_max) or (yb_>hauteur_ecran_max) then erreur:=err_format
   else begin
    GetMem(contenu,taille_octets);
    Lit(contenu^,taille_octets);
   end;
   Ferme;
   if erreur=err_format then exit;
  end;
 end;
 erreur:=f_erreur;
end; {Zone.Charge_}

{----------------------------------------------------------}

procedure Zone.Sauve_(nom_fichier: String80; var erreur: WORD);
var f: Fichier;
begin
 with f do begin
  Cree(not(teste_existe),nom_fichier);
  if f_erreur=f_ok then begin
   Ecrit(xg_,2); Ecrit(yh_,2); Ecrit(xd_,2); Ecrit(yb_,2); {entˆte}
   Ecrit(contenu^,taille_octets);
   Ferme;
  end;
 end;
 erreur:=f_erreur;
end; {Zone.Sauve_}

{----------------------------------------------------------}

procedure Ecran.Sauve(page: BYTE);
{sauve la page dans un ‚cran (25,28,50 lignes) SANS COLONNES VIRTUELLES (80!)}
begin
 New(contenu);
 Transfert(+1,PtrVRAM(page,1,1),0,contenu,0,largeur_ecran_txt,hauteur_ecran_txt);
end; {Ecran.Sauve}

{----------------------------------------------------------}

procedure Ecran.Restaure(page: BYTE);
{restaure l'‚cran sur une page SANS COLONNES VIRTUELLES (80!)}
begin
 Transfert(+1,contenu,0,PtrVRAM(page,1,1),0,largeur_ecran_txt,hauteur_ecran_txt);
end; {Ecran.Restaure}

{----------------------------------------------------------}

procedure Ecran.Supprime;
begin
 Dispose(contenu);
end; {Ecran.Supprime}

{----------------------------------------------------------}

procedure EffaceZone(page,xg,yh,xd,yb,attr: BYTE);
var ptr_VRAM: POINTER;
begin
 if (xd<xg) or (yb<yh) then exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 asm
  les DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}

  CMP Hercule,0
  JE @NoHercule
  AND Attr,7Eh
@NoHercule:

  mov BH,yb
  sub BH,yh
  inc BH              {BH=yb-yh+1: nombre de lignes}
  mov BL,xd
  sub BL,xg
  inc BL              {BL=xd-xg+1: nombre de colonnes}

  xor DH,DH
  mov DL,largeur_ecran_txt
  sub DL,BL
  shl DX,1            {incr‚ment DI: DX=2*(largeur_ecran_txt-nombre colonnes)}

  mov AH,attr
  mov AL,' '

  cld
  xor CH,CH
 @efface_ligne:
  mov CL,BL           {CX=nombre de colonnes}
  rep stosw           {efface une ligne}
  add DI,DX
  dec BH
  jnz @efface_ligne
 end;
end; {EffaceZone}

{----------------------------------------------------------}

procedure EffacePage(page,attr: BYTE);
begin
 EffaceZone(page,1,1,largeur_ecran_txt,hauteur_ecran_txt,attr);
end; {EffacePage}

{----------------------------------------------------------}

procedure ChangePage(page: BYTE); assembler;
{change la page visible courante SANS COLONNES VIRTUELLES (80!)}
asm
 mov AH,5
 mov AL,page
 int 10h
end; {ChangePage}

{----------------------------------------------------------}

procedure CopiePage(page_source,page_dest: BYTE);
begin
 Transfert(+1,PtrVRAM(page_source,1,1),0,PtrVRAM(page_dest,1,1),0,largeur_ecran_txt,hauteur_ecran_txt);
end; {CopiePage}

{----------------------------------------------------------}

procedure ScrolleZoneHaut(page,xg,yh,xd,yb: BYTE);
var ptr_VRAM: POINTER;
begin
 if (xd<xg) or (yb<=yh) then exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 asm
  push DS
  cld

  les DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}
  xor AH,AH
  mov AL,largeur_ecran_txt
  mov SI,AX
  shl SI,1
  add SI,DI           {SI=DI+2*largeur_ecran_txt: source=ligne du dessous}

  mov BH,yb
  sub BH,yh           {BH=yb-yh: nombre de lignes-1}
  mov BL,xd
  sub BL,xg
  inc BL              {BL=xd-xg+1: nombre de colonnes}

  xor DH,DH
  mov DL,largeur_ecran_txt
  sub DL,BL
  shl DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt-nombre colonnes)}

  push ES
  pop DS

  xor CH,CH
 @scrolle:
  mov CL,BL           {CX=nombre colonnes}
  rep movsw           {copie une ligne}
  add SI,DX
  add DI,DX           {ligne suivante}
  dec BH
  jnz @scrolle

  mov AL,' '          {espace}
  mov CL,BL           {CX=nombre colonnes}
 @efface:
  stosb               {efface ligne du bas}
  inc DI              {saute l'attribut}
  dec CL
  jnz @efface

  pop DS
 end;
end; {ScrolleZoneHaut}

{----------------------------------------------------------}

procedure ScrolleZoneBas(page,xg,yh,xd,yb: BYTE);
var ptr_VRAM: POINTER;
begin
 if (xd<xg) or (yb<=yh) then exit;

 ptr_VRAM:=PtrVRAM(page,xg,yb);
 asm
  push DS
  cld

  les DI,ptr_VRAM     {ES:DI -> coin inf‚rieur gauche}
  xor AH,AH
  mov AL,largeur_ecran_txt
  mov SI,AX
  shl SI,1
  neg SI
  add SI,DI           {SI=DI-2*largeur_ecran_txt: source=ligne du dessus}

  mov BH,yb
  sub BH,yh           {BH=yb-yh: nombre de lignes-1}
  mov BL,xd
  sub BL,xg
  inc BL              {BL=xd-xg+1: nombre de colonnes}

  xor DH,DH
  mov DL,largeur_ecran_txt
  add DL,BL
  shl DX,1            {d‚cr‚ment SI et DI: DX=2*(largeur_ecran_txt+nombre colonnes)}

  push ES
  pop DS

  xor CH,CH
 @scrolle:
  mov CL,BL           {CX=nombre colonnes}
  rep movsw           {copie une ligne}
  sub SI,DX
  sub DI,DX           {ligne suivante}
  dec BH
  jnz @scrolle

  mov AL,' '          {espace}
  mov CL,BL           {CX=nombre colonnes}
 @efface:
  stosb               {efface ligne du haut}
  inc DI              {saute l'attribut}
  dec CL
  jnz @efface

  pop DS
 end;
end; {ScrolleZoneBas}

{----------------------------------------------------------}

procedure ScrolleZoneGauche(page,xg,yh,xd,yb: BYTE);
var ptr_VRAM: POINTER;
begin
 if (xd<=xg) or (yb<yh) then exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 asm
  push DS

  les DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}
  mov SI,DI
  inc SI
  inc SI              {SI=DI+2: source=colonne de droite}

  mov BH,yb
  sub BH,yh
  inc BH              {BH=yb-yh+1: nombre de lignes}
  mov BL,xd
  sub BL,xg           {BL=xd-xg: nombre de colonnes-1}
  push BX

  xor DH,DH
  mov DL,largeur_ecran_txt
  sub DL,BL
  shl DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt-(nombre colonnes-1))}

  push ES
  pop DS

  cld
  xor CH,CH
 @scrolle:
  mov CL,BL           {CX=(nombre colonnes)-1}
  rep movsw           {copie une ligne}
  add SI,DX
  add DI,DX           {ligne suivante}
  dec BH
  jnz @scrolle

  sub DI,DX
  mov AL,' '          {espace}

  std                 {sens d‚croissant}
  pop BX
  mov CL,BH           {CX=nombre lignes}

  pop DS

  xor DH,DH
  mov DL,largeur_ecran_txt
  shl DX,1
  dec DX              {d‚cr‚ment DI: DX=2*largeur_ecran_txt-1}

 @efface:
  stosb               {efface colonne de droite}
  sub DI,DX           {ligne suivante}
  dec CL
  jnz @efface
 end;
end; {ScrolleZoneGauche}

{----------------------------------------------------------}

procedure ScrolleZoneDroite(page,xg,yh,xd,yb: BYTE);
var ptr_VRAM: POINTER;
begin
 if (xd<=xg) or (yb<yh) then exit;

 ptr_VRAM:=PtrVRAM(page,xd,yh);
 asm
  push DS

  les DI,ptr_VRAM     {ES:DI -> coin sup‚rieur droit}
  mov SI,DI
  dec SI
  dec SI              {SI=DI-2: source=colonne de gauche}

  mov BH,yb
  sub BH,yh
  inc BH              {BH=yb-yh+1: nombre de lignes}
  mov BL,xd
  sub BL,xg           {BL=xd-xg: nombre de colonnes-1}
  push BX

  xor DH,DH
  mov DL,largeur_ecran_txt
  add DL,BL
  shl DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt+(nombre colonnes-1))}

  push ES
  pop DS

  std                 {sens d‚croissant}
  xor CH,CH
 @scrolle:
  mov CL,BL           {CX=(nombre colonnes)-1}
  rep movsw           {copie une ligne}
  add SI,DX
  add DI,DX           {ligne suivante}
  dec BH
  jnz @scrolle

  sub DI,DX
  mov AL,' '          {espace}

  pop BX
  mov CL,BH           {CX=nombre lignes}

  pop DS

  xor DH,DH
  mov DL,largeur_ecran_txt
  shl DX,1
  dec DX              {d‚cr‚ment DI: DX=2*largeur_ecran_txt-1}

 @efface:
  stosb               {efface colonne de gauche}
  sub DI,DX           {ligne suivante}
  dec CL
  jnz @efface
 end;
end; {ScrolleZoneDroite}

{==========================================================}

END.
