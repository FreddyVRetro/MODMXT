{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                       --==ðð SOURIS.PAS ðð==--                       º}
{º                                                                      º}
{º Unit‚ pour g‚rer la souris (routines g‚n‚rales ind‚p. du mode vid‚o) º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 286           D‚but d'‚critureúúúúúúúúúúúúúú ??/01/95 º}
{º                              DerniŠres modificationsúúúúúúú 26/07/98 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT Souris;

{$A+,G-,Q-,R-,S-}

INTERFACE

CONST {constantes pour BoutonSouris}
      aucun =$00;
      gauche=$01;
      droite=$02;
      milieu=$04;

      {constantes d'‚v‚nements}
      souris_bouge =$01;
      bt_gauche_app=$02;
      bt_gauche_rel=$04;
      bt_droit_app =$08;
      bt_droit_rel =$10;
      bt_milieu_app=$20;
      bt_milieu_rel=$40;
      bt_gauche=bt_gauche_app+bt_gauche_rel;
      bt_droit =bt_droit_app+bt_droit_rel;
      bt_milieu=bt_milieu_app+bt_milieu_rel;

      {flag pour le gestionnaire d'‚v‚nements}
      valide_gest_even: BOOLEAN=TRUE;

{==========================================================}

function  InitSouris: BOOLEAN;

procedure AffCursSouris;
procedure CacheCursSouris;

function  BoutonSouris: BYTE;
procedure DelaiBoutonSouris(base_temps: BYTE);

function  Xsouris: WORD;
function  Ysouris: WORD;
procedure EtatSouris(var x,y: WORD; var boutons: BYTE);
procedure BougeCursSourisXY(x,y: WORD);

function  NbrAppuisBouton(bouton: BYTE; var x,y: WORD): BYTE;
function  NbrRelachBouton(bouton: BYTE; var x,y: WORD): BYTE;
procedure ZoneSouris(xg,yh,xd,yb: WORD);
function  SourisBouge: BOOLEAN;

procedure InstalleGestEvenSouris(evenements: BYTE; addr_gest: POINTER);
procedure DesinstGestEvenSouris;
procedure ValideEv;
procedure InhibeEv;
procedure FinSourisEv;

procedure SeuilVitesseSouris(mickeys_par_seconde: WORD);
procedure SensibiliteSouris(mickeys_horiz,mickeys_vertic,seuil_double: WORD);

{==========================================================}

IMPLEMENTATION

USES Crt;

{==========================================================}

function InitSouris: BOOLEAN; assembler;
{renvoie TRUE si l'initialisation s'est bien pass‚e, FALSE sinon}
asm
 mov AX,00h
 int 33h
 or AX,AX
 jz @fin        {si AX=0 -> erreur}
 mov AL,TRUE    {ok}
@fin:
end; {InitSouris}

{----------------------------------------------------------}

procedure AffCursSouris; assembler;
asm
 mov AX,01h
 int 33h
end; {AffCursSouris}

{----------------------------------------------------------}

procedure CacheCursSouris; assembler;
asm
 mov AX,02h
 int 33h
end; {CacheCursSouris}

{----------------------------------------------------------}

function BoutonSouris: BYTE; assembler;
asm
 xor BL,BL
 mov AX,03h
 int 33h
 mov AL,BL
end; {BoutonSouris}

{----------------------------------------------------------}

procedure DelaiBoutonSouris(base_temps: BYTE);
begin
 case BoutonSouris of
  gauche: Delay(5*base_temps);
  droite: Delay(15*base_temps);
  milieu,gauche+droite: Delay(base_temps);
 end;
end; {DelaiBoutonSouris}

{----------------------------------------------------------}

function Xsouris: WORD; assembler;
{renvoie la coordonn‚e absolue X du curseur (0..639}
asm
 mov AX,03h
 int 33h
 mov AX,CX
end; {Xsouris}

{----------------------------------------------------------}

function Ysouris: WORD; assembler;
{renvoie la coordonn‚e absolue Y du curseur (0..199}
asm
 mov AX,03h
 int 33h
 mov AX,DX
end; {Ysouris}

{----------------------------------------------------------}

procedure EtatSouris(var x,y: WORD; var boutons: BYTE); assembler;
asm
 mov AX,03h
 int 33h
 les DI,x
 mov ES:[DI],CX
 les DI,y
 mov ES:[DI],DX
 les DI,boutons
 mov ES:[DI],BL
end; {EtatSouris}

{----------------------------------------------------------}

procedure BougeCursSourisXY(x,y: WORD); assembler;
asm
 mov AX,04h
 mov CX,x
 mov DX,y
 int 33h
end; {BougeCursSourisXY}

{----------------------------------------------------------}

function NbrAppuisBouton(bouton: BYTE; var x,y: WORD): BYTE; assembler;
{renvoie le nombre de fois que l‚ bouton a ‚t‚ appuy‚ depuis le dernier
 appel … cette fonction, et les coordonn‚es du curseur lors de l'appui}
asm
 mov AX,05h
 xor BH,BH
 mov BL,bouton
 shr BL,1
 int 33h
 les DI,x
 mov ES:[DI],CX
 les DI,y
 mov ES:[DI],DX
 mov AL,BL
end; {NbrAppuisBouton}

{----------------------------------------------------------}

function NbrRelachBouton(bouton: BYTE; var x,y: WORD): BYTE; assembler;
{renvoie le nombre de fois que l‚ bouton a ‚t‚ relƒch‚ depuis le dernier
 appel … cette fonction, et les coordonn‚es du curseur lors du relƒchement}
asm
 mov AX,06h
 xor BH,BH
 mov BL,bouton
 shr BL,1
 int 33h
 les DI,x
 mov ES:[DI],CX
 les DI,y
 mov ES:[DI],DX
 mov AL,BL
end; {NbrRelachBouton}

{----------------------------------------------------------}

procedure ZoneSouris(xg,yh,xd,yb: WORD); assembler;
asm
 mov AX,07h
 mov CX,xg
 mov DX,xd
 int 33h
 mov AX,08h
 mov CX,yh
 mov DX,yb
 int 33h
end; {ZoneSouris}

{----------------------------------------------------------}

function SourisBouge: BOOLEAN; assembler;
{SourisBouge=(CX<>0) ou (DX<>0)}
asm
 mov AX,0Bh
 int 33h
 mov AL,FALSE   {par d‚faut}
 or CX,CX
 jnz @bouge     {si CX<>0, la souris a boug‚}
 or DX,DX
 jz @fin        {si DX=0, la souris n'a pas boug‚}
@bouge:
 mov AL,TRUE
@fin:
end; {SourisBouge}

{----------------------------------------------------------}

{$L SourisEv}

procedure InstalleGestEvenSouris(evenements: BYTE; addr_gest: POINTER); external;
{installe un gestionnaire d'‚v‚nements, qui doit ˆtre d‚clar‚ comme suit:
 procedure GestEvenSouris(evenements,boutons: BYTE; posx,posy: WORD; dx,dy: INTEGER); far;}

procedure DesinstGestEvenSouris; external;
{cache le curseur de la souris, puis retire le gestionnaire d'‚v‚nements}

{----------------------------------------------------------}

procedure ValideEv;
begin
 valide_gest_even:=TRUE;
end; {ValideEv}

{----------------------------------------------------------}

procedure InhibeEv;
begin
 valide_gest_even:=FALSE;
end; {InhibeEv}

{----------------------------------------------------------}

procedure FinSourisEv;
{… appeler si un gestionnaire d'‚v‚nements a ‚t‚ install‚!}
begin
 CacheCursSouris;
 DesinstGestEvenSouris;
end; {FinSourisEv}

{----------------------------------------------------------}

procedure SeuilVitesseSouris(mickeys_par_seconde: WORD); assembler;
asm
 mov AX,13h
 mov DX,mickeys_par_seconde
 int 33h
end; {SeuilVitesseSouris}

{----------------------------------------------------------}

procedure SensibiliteSouris(mickeys_horiz,mickeys_vertic,seuil_double: WORD); assembler;
asm
 mov AX,1Ah
 mov BX,mickeys_horiz
 mov CX,mickeys_vertic
 mov DX,seuil_double
 int 33h
end; {SensibiliteSouris}

{==========================================================}

END.
