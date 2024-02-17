{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                 --==ðð SOURIST/SOURISSM.PAS ðð==--                   º}
{º                                                                      º}
{º Unit‚ pour g‚rer la souris en mode texte (curseur normal ou smooth)  º}
{º Le mode "Smooth" est disponible en VGA et SVGA 132 colonnes          º}
{º Le mode NORMAL n'est PAS disponible en SVGA 132 colonnes !!          º}
{º                                                                      º}
{º    IMPORTANT: … charger aprŠs l'unit‚ Souris !!                      º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 286           D‚but d'‚critureúúúúúúúúúúúúúú ??/03/94 º}
{º                              DerniŠres modificationsúúúúúúú 26/07/98 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

{$UNDEF Smooth}

{$IFNDEF Smooth}
UNIT SourisT;
{$ELSE}
UNIT SourisSm;
{$ENDIF}

{$A+,G-,Q-,R-,S-}

INTERFACE

USES Texte;

{$I Types}

TYPE BoutonBase=object
                 procedure Active(condition: BOOLEAN);
                private
                 procedure Definit(page_,x,y_: BYTE; titre_: String25;
                                   attr_relache,attr_appuye,attr_lettre: BYTE);
                private
                 page,y,xg,xd: BYTE;
                 titre: String25;
                 attribut: array[BOOLEAN] of BYTE;
                 attribut_lettre: BYTE;
                 pos_lettre: BYTE;
                 actif_,appuye_: BOOLEAN;
                end;

     Bouton=object(BoutonBase)
             procedure Definit(page_,x,y_: BYTE; titre_: String25;
                               attr_relache,attr_appuye,attr_lettre,attr_inactif: BYTE);
             procedure Affiche;
             function Appuye(touche: CHAR): BOOLEAN;
             function Clique: BOOLEAN;
            private
             attribut_inactif: BYTE;
            end;

     Bouton3D=object(BoutonBase)
               procedure Definit(page_,x,y_: BYTE; titre_: String25;
                                 attend_relache_: BOOLEAN;
                                 base_delai_,
                                 attr_relache,attr_appuye,attr_lettre,
                                 coul_relief_haut_,coul_relief_bas_,coul_relief_coin_: BYTE;
                                 car_coin_inf_droit_: CHAR);
               procedure Affiche;
               function Appuye(touche: CHAR): BOOLEAN;
               function Clique: BOOLEAN;
              private
               coul_relief_haut,coul_relief_bas,coul_relief_coin: BYTE;
               car_coin_inf_droit: CHAR;
               base_delai: BYTE;
               attend_relache: BOOLEAN;
              end;

     CaseOpt=object
              procedure Definit(page_,x_,y_: BYTE;
                                car_non_cochee_,car_cochee_,car_appuyee_: CHAR;
                                attr_active,attr_inactive: BYTE);
              procedure Active(condition: BOOLEAN);
              procedure Coche(condition: BOOLEAN);
              procedure Affiche;
              function Cliquee: BOOLEAN;
             private
              page,x,y: BYTE;
              car: array[BOOLEAN] of CHAR;
              car_appuyee: CHAR;
              attribut: array[BOOLEAN] of BYTE;
              active_,cochee_,appuyee_: BOOLEAN;
             end;

     ObjClic=object
              procedure Definit(page_,x,y_: BYTE; titre_: String25;
                                attend_relache_: BOOLEAN;
                                base_delai_,attr_ext_,attr_int_: BYTE);
              procedure Affiche;
              function Clique: BOOLEAN;
             private
              page,y,xg,xd: BYTE;
              titre: String25;
              base_delai,attr_ext,attr_int: BYTE;
              attend_relache: BOOLEAN;
             end;

{$IFNDEF Smooth}
CONST {modes curseurs pour DefCursSouris}
      change_tout     =$00;
      garde_fond      =$01;
      garde_ecriture  =$02;
      garde_caractere =$04;
      inverse_fond    =$08;
      inverse_ecriture=$10;
      garde_attribut  =garde_fond+garde_ecriture;
      inverse_attribut=inverse_fond+inverse_ecriture;
      standard=inverse_attribut+garde_caractere;

{$ELSE}
CONST {formes curseurs pour DefCursSouris}
      fleche =0;
      sablier=1;
      rotatif=2;

{$ENDIF}

{$IFDEF Smooth}
CONST curseur_fleche_16: Binaire16=($80,$C0,$E0,$F0,$F8,$FC,$FE,$FF,$FF,$FC,$9C,$0E,$0E,$07,$07,00);
      curseur_fleche_14: Binaire14=($00,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF,$FC,$9C,$1C,$0E,$0E);
      curseur_fleche_8 : Binaire8 =($80,$E0,$F8,$FC,$FF,$FC,$9C,$0E);


CONST nulle=$FF;
      lente  =3;
      moyenne=2;
      rapide =1;
      vitesse_curseur: array[fleche..rotatif] of BYTE=(nulle,moyenne,rapide);

      nombre_sabliers_16=15;
      curseur_sablier_16: array[0..nombre_sabliers_16-1] of Binaire16=
       (($FF,$FF,$FF,$FF,$7E,$7E,$3C,$24,$24,$24,$42,$42,$81,$81,$81,$FF),
        ($FF,$F7,$FF,$FF,$7E,$7E,$3C,$24,$2C,$24,$4A,$4A,$81,$89,$81,$FF),
        ($FF,$E3,$F7,$FF,$7E,$7E,$3C,$2C,$24,$2C,$42,$4A,$89,$81,$9D,$FF),
        ($FF,$C1,$E3,$FF,$7E,$7E,$3C,$2C,$2C,$24,$4A,$42,$89,$9D,$BF,$FF),
        ($FF,$81,$C1,$F7,$7E,$7E,$3C,$24,$2C,$2C,$42,$4A,$89,$BF,$FF,$FF),
        ($FF,$81,$81,$E3,$76,$7E,$3C,$2C,$24,$2C,$4A,$42,$9F,$FF,$FF,$FF),
        ($FF,$81,$81,$C1,$66,$7E,$3C,$24,$2C,$24,$4A,$5A,$FF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$42,$76,$3C,$2C,$24,$2C,$4A,$7E,$FF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$42,$42,$34,$34,$2C,$24,$5E,$7E,$FF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$42,$42,$24,$24,$24,$3C,$7E,$7E,$FF,$FF,$FF,$FF),
        ($3C,$42,$81,$81,$81,$42,$24,$24,$24,$3C,$7E,$FF,$FF,$FF,$7E,$3C),
        ($00,$3C,$42,$81,$81,$81,$42,$24,$3C,$7E,$FF,$FF,$FF,$7E,$3C,$00),
        ($00,$00,$00,$3C,$42,$81,$81,$BD,$7E,$FF,$FF,$7E,$3C,$00,$00,$00),
        ($00,$00,$00,$00,$3C,$7E,$FF,$FF,$7E,$BD,$42,$3C,$00,$00,$00,$00),
        ($00,$00,$3C,$7E,$FF,$FF,$FF,$7E,$24,$42,$81,$81,$42,$3C,$00,$00));

      nombre_sabliers_14=12;
      curseur_sablier_14: array[0..nombre_sabliers_14-1] of Binaire14=
       (($FF,$FF,$FF,$FF,$7E,$3C,$24,$24,$24,$42,$81,$81,$81,$FF),
        ($FF,$F7,$FF,$FF,$7E,$3C,$2C,$24,$2C,$4A,$81,$89,$81,$FF),
        ($FF,$E3,$F7,$FF,$7E,$3C,$24,$2C,$24,$4A,$89,$81,$9D,$FF),
        ($FF,$C1,$E3,$FF,$7E,$3C,$2C,$24,$2C,$42,$89,$9D,$BF,$FF),
        ($FF,$81,$C1,$E3,$7E,$3C,$24,$2C,$24,$4A,$9D,$BF,$FF,$FF),
        ($FF,$81,$81,$E3,$76,$3C,$2C,$24,$2C,$4A,$BF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$66,$3C,$24,$2C,$24,$5E,$FF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$42,$34,$2C,$24,$3C,$7E,$FF,$FF,$FF,$FF),
        ($FF,$81,$81,$81,$42,$24,$24,$24,$3C,$7E,$FF,$FF,$FF,$FF),
        ($00,$3C,$42,$81,$81,$42,$24,$7E,$FF,$FF,$FF,$7E,$3C,$00),
        ($00,$00,$00,$3C,$42,$BD,$7E,$FF,$FF,$7E,$3C,$00,$00,$00),
        ($00,$00,$3C,$7E,$FF,$FF,$7E,$BD,$81,$81,$42,$3C,$00,$00));

      nombre_sabliers_8=11;
      curseur_sablier_8: array[0..nombre_sabliers_8-1] of Binaire8=
       (($FF,$FF,$7E,$3C,$24,$42,$81,$FF),
        ($FF,$F7,$7E,$3C,$24,$4A,$81,$FF),
        ($FF,$E3,$7E,$3C,$2C,$42,$9D,$FF),
        ($FF,$C3,$76,$3C,$24,$5A,$BD,$FF),
        ($FF,$C1,$66,$3C,$2C,$5A,$FF,$FF),
        ($FF,$81,$62,$34,$2C,$7E,$FF,$FF),
        ($FF,$81,$42,$24,$3C,$7E,$FF,$FF),
        ($7E,$81,$42,$24,$7E,$FF,$FF,$7E),
        ($00,$3C,$42,$BD,$FF,$FF,$7E,$00),
        ($00,$7E,$FF,$FF,$BD,$42,$3C,$00),
        ($7E,$FF,$FF,$7E,$24,$42,$81,$7E));

      curseur_rotatif_16: array[0..7] of Binaire16=
       (($00,$00,$3C,$4E,$8F,$8F,$8F,$8F,$F1,$F1,$F1,$F1,$72,$3C,$00,$00),
        ($00,$00,$3C,$42,$83,$87,$C7,$EF,$F7,$E3,$E1,$C1,$42,$3C,$00,$00),
        ($00,$00,$3C,$42,$81,$C3,$E7,$FF,$FF,$E7,$C3,$81,$42,$3C,$00,$00),
        ($00,$00,$3C,$42,$C1,$E1,$E3,$F7,$EF,$C7,$87,$83,$42,$3C,$00,$00),
        ($00,$00,$3C,$72,$F1,$F1,$F1,$F1,$8F,$8F,$8F,$8F,$4E,$3C,$00,$00),
        ($00,$00,$3C,$7A,$F9,$F9,$B1,$91,$89,$8D,$9F,$9F,$5E,$3C,$00,$00),
        ($00,$00,$3C,$7E,$FF,$BD,$99,$89,$91,$99,$BD,$FF,$7E,$3C,$00,$00),
        ($00,$00,$3C,$5E,$9F,$9F,$8D,$89,$91,$B1,$F9,$F9,$7A,$3C,$00,$00));

      curseur_rotatif_14: array[0..7] of Binaire14=
       (($00,$3C,$4E,$8F,$8F,$8F,$8F,$F1,$F1,$F1,$F1,$72,$3C,$00),
        ($00,$3C,$42,$83,$87,$C7,$EF,$F7,$E3,$E1,$C1,$42,$3C,$00),
        ($00,$3C,$42,$81,$C3,$E7,$FF,$FF,$E7,$C3,$81,$42,$3C,$00),
        ($00,$3C,$42,$C1,$E1,$E3,$F7,$EF,$C7,$87,$83,$42,$3C,$00),
        ($00,$3C,$72,$F1,$F1,$F1,$F1,$8F,$8F,$8F,$8F,$4E,$3C,$00),
        ($00,$3C,$7A,$F9,$F9,$B1,$91,$89,$8D,$9F,$9F,$5E,$3C,$00),
        ($00,$3C,$7E,$FF,$BD,$99,$89,$91,$99,$BD,$FF,$7E,$3C,$00),
        ($00,$3C,$5E,$9F,$9F,$8D,$89,$91,$B1,$F9,$F9,$7A,$3C,$00));

      curseur_rotatif_8: array[0..7] of Binaire8=
       (($3C,$4E,$8F,$8F,$F1,$F1,$72,$3C),
        ($3C,$46,$8F,$CF,$F3,$F1,$62,$3C),
        ($3C,$42,$E7,$FF,$FF,$E7,$42,$3C),
        ($3C,$62,$F1,$F3,$CF,$8F,$46,$3C),
        ($3C,$72,$F1,$F1,$8F,$8F,$4E,$3C),
        ($3C,$7A,$F1,$B1,$8D,$8F,$5E,$3C),
        ($3C,$7E,$BD,$99,$99,$BD,$7E,$3C),
        ($3C,$5E,$8F,$8D,$B1,$F1,$7A,$3C));
{$ENDIF}

{$IFDEF Smooth}
VAR Xsouris,Ysouris: BYTE;
    SourisBouge: BOOLEAN;
    {!! avant d'appeler SourisBouge, il faut l'initialiser … FALSE !!}
{$ENDIF}

{==========================================================}

{$IFNDEF Smooth}
procedure TestCoulCursSouris;
{$IFDEF CGAOnly}
procedure DefCursSouris(mode,fond,ecriture: BYTE; caractere: CHAR);
procedure InitSourisFleche(caractere: CHAR; test_couleurs: BOOLEAN); {VGA}
procedure CursSourisFleche(caractere: CHAR); {VGA}
{$ENDIF}
{$ELSE}
procedure CursSourisSmooth; {VGA}
procedure AffCursSouris; {VGA}
procedure CacheCursSouris; {VGA}
procedure DefCursSouris(forme: BYTE); {VGA}
procedure AnimeCursSouris; {VGA}

procedure InitSourisSmooth(car_1,car_2,car_3,car_4: CHAR); {VGA}
procedure FinSourisSmooth; {VGA}
{$ENDIF}

{$IFNDEF Smooth}
function  Xsouris: BYTE;
function  Ysouris: BYTE;
{$ENDIF}
procedure EtatSouris(var x,y,boutons: BYTE);
procedure BougeCursSourisXY(x,y: BYTE);

function  NbrAppuisBouton(bouton: BYTE; var x,y: BYTE): BYTE;
function  NbrRelachBouton(bouton: BYTE; var x,y: BYTE): BYTE;
procedure ZoneSouris(xg,yh,xd,yb: BYTE);

function  EstDansZone(x,y,xg,yh,xd,yb: BYTE): BOOLEAN;

procedure AttendClavierSouris(attend_bouge,condition: BOOLEAN; var x,y: BYTE);

{==========================================================}

IMPLEMENTATION

USES Clavier,Util,Souris;

VAR curseur_souris_change: BOOLEAN;

{$IFNDEF Smooth}
VAR mode_curseur,
    couleur_fond_souris,
    couleur_ecriture_initiale_souris,couleur_ecriture_souris: BYTE;
    caractere_souris: CHAR;

{$ELSE}
VAR x_souris_sm,y_souris_sm: INTEGER;

    car_souris_sm_1,anc_car_souris_sm_1,
    car_souris_sm_2,anc_car_souris_sm_2,
    car_souris_sm_3,anc_car_souris_sm_3,
    car_souris_sm_4,anc_car_souris_sm_4: CHAR;

    zone_souris_xg,zone_souris_yh,zone_souris_xd,zone_souris_yb: BYTE;

    ptr_curseur_souris: POINTER;
    curseur_visible: BOOLEAN;

    forme_actuelle,index_curseur: BYTE;
    top_anime_curseur: LONGINT;

{$ENDIF}

{==========================================================}

{$IFNDEF Smooth}

{$F+}
procedure GestEvenSouris(evenements,boutons: BYTE; posx,posy: WORD; dx,dy: INTEGER); assembler;
{appel‚e lorsque la souris bouge - met … jour le curseur (page nø0) si la
 couleur de fond recouverte et la couleur du curseur sont identiques}
asm
 mov AX,0B800h
 mov ES,AX         {ES=B800}

 mov CL,4
 mov DI,posy
 shl DI,CL         {DI=128*(posy/8)=16*posy}
 mov AX,DI
 shr AX,1
 shr AX,1
 add DI,AX         {DI=160*(posy/8)=20*posy}
 mov AX,posx
 shr AX,1
 shr AX,1
 add DI,AX
 inc DI            {DI=1+2*(posx/8)+160*(posy/8)}

 mov AL,ES:[DI]
 shr AL,CL         {AL=couleur de fond}
 cmp AL,couleur_ecriture_initiale_souris
 jne @suite

 mov AL,mode_curseur
 and AL,not(garde_ecriture)
 push AX
 mov AL,couleur_fond_souris
 push AX
 mov AL,couleur_ecriture_initiale_souris
 xor AL,00001111b  {inverse couleur d'‚criture du curseur}
 push AX
 mov AL,caractere_souris
 push AX
 call DefCursSouris  {cache, d‚finit et affiche le curseur}
 mov curseur_souris_change,TRUE
 jmp @fin

@suite:
 cmp curseur_souris_change,FALSE
 je @fin

 mov AL,mode_curseur
 push AX
 mov AL,couleur_fond_souris
 push AX
 mov AL,couleur_ecriture_initiale_souris
 push AX
 mov AL,caractere_souris
 push AX
 call DefCursSouris  {cache, d‚finit et affiche le curseur}
 mov curseur_souris_change,FALSE

@fin:
end; {GestEvenSouris}
{$F-}

{----------------------------------------------------------}

procedure TestCoulCursSouris;
{… utiliser avec DefCursSouris: le curseur sera toujours visible
 (la couleur du curseur est invers‚e si elle est confondue avec la
 couleur de fond du caractŠre recouvert).

 Remarque: Un gestionnaire d'‚v‚nements est install‚
           -> il faut terminer par FinSourisEv !}
begin
 curseur_souris_change:=FALSE;
 couleur_ecriture_initiale_souris:=couleur_ecriture_souris;
 InstalleGestEvenSouris(souris_bouge,@GestEvenSouris);
end; {TestCoulCursSouris}

{----------------------------------------------------------}

{$IFDEF CGAOnly}
procedure DefCursSouris(mode,fond,ecriture: BYTE; caractere: CHAR);
{d‚finit le curseur de la souris: mode d'affichage, couleurs et caractŠre.

 Remarque: Par d‚faut, le curseur sera invisible aux endroits o— la couleur
           de fond du caractŠre recouvert est ‚gale … la couleur du curseur.
           -> si n‚cessaire, appeler TestCoulCursSouris aprŠs DefCursSouris}
begin
 mode_curseur:=mode;
 couleur_fond_souris:=fond;
 couleur_ecriture_souris:=ecriture;
 caractere_souris:=caractere;

 asm
  xor CX,CX      {masque and}
  xor DX,DX      {masque xor}

  test mode,garde_fond
  jz @pas_garde_fond
  or CX,1111000000000000b
  jmp @test_garde_ecriture

 @pas_garde_fond:
  mov AL,fond
  shl AL,4
  or DH,AL
 @test_garde_ecriture:
  test mode,garde_ecriture
  jz @pas_garde_ecriture
  or CX,0000111100000000b
  jmp @test_garde_caractere

 @pas_garde_ecriture:
  mov AL,ecriture
  or DH,AL
 @test_garde_caractere:
  test mode,garde_caractere
  jz @pas_garde_caractere
  or CX,0000000011111111b
  jmp @test_inverse_fond

 @pas_garde_caractere:
  or DL,caractere
 @test_inverse_fond:
  test mode,inverse_fond
  jz @pas_inverse_fond
  and CX,0000111111111111b
  or  CX,1111000000000000b
  and DX,0000111111111111b
  or  DX,0111000000000000b

 @pas_inverse_fond:
  test mode,inverse_ecriture
  jz @fin
  and CX,1111000011111111b
  or  CX,0000111100000000b
  and DX,1111000011111111b
  or  DX,0000011100000000b

 @fin:
  mov AX,0Ah
  mov BX,0       {curseur logiciel}
  int 33h
 end;
end; {DefCursSouris}

{----------------------------------------------------------}

procedure InitSourisFleche(caractere: CHAR; test_couleurs: BOOLEAN); {VGA}
{initialise le caractŠre du curseur en forme de flŠche (couleur=blanc 15)
 test_couleurs: voir commentaires de DefCursSouris et TestCoulCursSouris...}
begin
 CursSourisFleche(caractere);
 if test_couleurs then TestCoulCursSouris;
end; {InitSourisFleche}

{----------------------------------------------------------}


procedure CursSourisFleche(caractere: CHAR); {VGA}
{red‚finit le curseur en forme de flŠche}
begin
 case hauteur_car of
  16: RedefCar(0,caractere,1,curseur_fleche_16,binaire);
  14: RedefCar(0,caractere,1,curseur_fleche_14,binaire);
  8 : RedefCar(0,caractere,1,curseur_fleche_8 ,binaire);
 end;
 DefCursSouris(garde_fond,0,15,caractere);
end; {CursSourisFleche}
{$ENDIF} {CGAOnly}

{----------------------------------------------------------}

function Xsouris: BYTE;
{renvoie la coordonn‚e horizontale du curseur (1..80)}
begin
 Xsouris:=1+(Souris.Xsouris shr 3);
end; {Xsouris}

{----------------------------------------------------------}

function Ysouris: BYTE;
{renvoie la coordonn‚e verticale du curseur (1..nbr_lignes)}
begin
 Ysouris:=1+(Souris.Ysouris shr 3);
end; {Ysouris}

{----------------------------------------------------------}

procedure EtatSouris(var x,y,boutons: BYTE);
var x_abs,y_abs: WORD;
begin
 Souris.EtatSouris(x_abs,y_abs,boutons);
 x:=1+(x_abs shr 3);
 y:=1+(y_abs shr 3);
end; {EtatSouris}

{----------------------------------------------------------}

procedure BougeCursSourisXY(x,y: BYTE);
begin
 Souris.BougeCursSourisXY((x-1) shl 3,(y-1) shl 3);
end; {BougeCursSourisXY}

{----------------------------------------------------------}

function NbrAppuisBouton(bouton: BYTE; var x,y: BYTE): BYTE;
var x_abs,y_abs: WORD;
begin
 NbrAppuisBouton:=Souris.NbrAppuisBouton(bouton,x_abs,y_abs);
 x:=1+(x_abs shr 3);
 y:=1+(y_abs shr 3);
end; {NbrAppuisBouton}

{----------------------------------------------------------}

function NbrRelachBouton(bouton: BYTE; var x,y: BYTE): BYTE;
var x_abs,y_abs: WORD;
begin
 NbrRelachBouton:=Souris.NbrRelachBouton(bouton,x_abs,y_abs);
 x:=1+(x_abs shr 3);
 y:=1+(y_abs shr 3);
end; {NbrRelachBouton}

{----------------------------------------------------------}

procedure ZoneSouris(xg,yh,xd,yb: BYTE);
begin
 Souris.ZoneSouris((xg-1) shl 3,(yh-1) shl 3,(xd-1) shl 3,(yb-1) shl 3);
end; {ZoneSouris}

{----------------------------------------------------------}

{$ELSE}

procedure CursSourisSmooth; {VGA}
{red‚finit le curseur de la souris en forme de flŠche (sur 4 caractŠres)}
var modulo_x,modulo_y: BYTE;
{ 1 2 }
{ 3 4 }
begin
 modulo_x:=x_souris_sm and $07;
 modulo_y:=y_souris_sm mod hauteur_car;

 AccedeCar;

 {red‚finit le curseur sur les 4 caractŠres}
 asm
  push DS
  cld

  mov AX,0A000h
  mov ES,AX          {ES=A000: segment table de caractŠres}

  {caractŠre curseur souris 1}
  xor AH,AH
  mov AL,anc_car_souris_sm_1
  shl AX,5           {AX=32*code}
  mov SI,AX          {ES:SI -> ligne 0 du caractŠre recouvert 1}

  xor AH,AH
  mov AL,car_souris_sm_1
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 1}

  mov CL,modulo_x    {CL=x_souris_sm Modulo 8}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … copier?}
  jz @suite_1        {non, le motif est entiŠrement sur cette ligne de texte}

 @boucle_copie_1:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 1}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 1}
  inc SI
  dec CH
  jnz @boucle_copie_1

 @suite_1:
  mov CH,hauteur_car
  sub CH,modulo_y    {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

  lds BX,ptr_curseur_souris  {DS:BX -> motif curseur}

 @boucle_redef_1:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 1}
  mov AH,[BX]        {charge une ligne du motif curseur}
  shr AH,CL          {d‚cale horizontalement}
  or AL,AH           {recouvre les deux lignes}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 1}
  inc SI
  inc BX
  dec CH
  jnz @boucle_redef_1

  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 2}
  xor AH,AH
  mov AL,anc_car_souris_sm_2
  shl AX,5           {AX=32*code}
  mov SI,AX          {ES:SI -> ligne 0 du caractŠre recouvert 2}

  xor AH,AH
  mov AL,car_souris_sm_2
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 2}

  mov CL,8
  sub CL,modulo_x    {CL=8-(x_souris_sm Modulo 8)}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … copier?}
  jz @suite_2        {non, le motif est entiŠrement sur cette ligne de texte}

 @boucle_copie_2:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 2}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 2}
  inc SI
  dec CH
  jnz @boucle_copie_2

 @suite_2:
  mov CH,hauteur_car
  sub CH,modulo_y    {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

  lds BX,ptr_curseur_souris  {DS:BX -> motif curseur}

 @boucle_redef_2:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 2}
  mov AH,[BX]        {charge une ligne du motif curseur}
  shl AH,CL          {d‚cale horizontalement}
  or AL,AH           {recouvre les deux lignes}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 2}
  inc SI
  inc BX
  dec CH
  jnz @boucle_redef_2

  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 3}
  xor AH,AH
  mov AL,anc_car_souris_sm_3
  shl AX,5           {AX=32*code}
  mov SI,AX          {ES:SI -> ligne 0 du caractŠre recouvert 3}

  xor AH,AH
  mov AL,car_souris_sm_3
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 3}

  mov CL,modulo_x    {CL=x_souris_sm Modulo 8}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … red‚finir?}
  jz @suite_3        {non, le motif est entiŠrement sur la ligne de texte du dessus}

  lds BX,ptr_curseur_souris  {DS:BX -> motif curseur}
  xor AH,AH
  mov AL,hauteur_car
  sub AL,modulo_y    {AX=hauteur_car-(y_souris_sm Modulo hauteur_car)}
  add BX,AX

 @boucle_redef_3:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 3}
  mov AH,[BX]        {charge une ligne du motif curseur}
  shr AH,CL          {d‚cale horizontalement}
  or AL,AH           {recouvre les deux lignes}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 3}
  inc SI
  inc BX
  dec CH
  jnz @boucle_redef_3

 @suite_3:
  mov CH,hauteur_car
  sub CH,modulo_y    {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

 @boucle_copie_3:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 3}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 3}
  inc SI
  dec CH
  jnz @boucle_copie_3

  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 4}
  xor AH,AH
  mov AL,anc_car_souris_sm_4
  shl AX,5           {AX=32*code}
  mov SI,AX          {ES:SI -> ligne 0 du caractŠre recouvert 4}

  xor AH,AH
  mov AL,car_souris_sm_4
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 4}

  mov CL,8
  sub CL,modulo_x    {CL=8-(x_souris_sm Modulo 8)}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … red‚finir?}
  jz @suite_4        {non, le motif est entiŠrement sur la ligne de texte du dessus}

  lds BX,ptr_curseur_souris  {DS:BX -> motif curseur}
  xor AH,AH
  mov AL,hauteur_car
  sub AL,modulo_y    {AX=hauteur_car-(y_souris_sm Modulo hauteur_car)}
  add BX,AX

 @boucle_redef_4:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 4}
  mov AH,[BX]        {charge une ligne du motif curseur}
  shl AH,CL          {d‚cale horizontalement}
  or AL,AH           {recouvre les deux lignes}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 4}
  inc SI
  inc BX
  dec CH
  jnz @boucle_redef_4

 @suite_4:
  mov CH,hauteur_car
  sub CH,modulo_y    {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

 @boucle_copie_4:
  mov AL,ES:[SI]     {charge une ligne du caractŠre recouvert 4}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 4}
  inc SI
  dec CH
  jnz @boucle_copie_4

  pop DS
 end;

 {trace le contour du curseur sur les 4 caractŠres}
 asm
  push DS
  cld

  mov AX,0A000h
  mov ES,AX          {ES=A000: segment table de caractŠres}

  {caractŠre curseur souris 1}
  xor AH,AH
  mov AL,car_souris_sm_1
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 1}

  mov CL,modulo_x
  inc CL             {CL=(x_souris_sm Modulo 8)+1}
  mov BL,modulo_y    {BL=y_souris_sm Modulo hauteur_car}
  mov CH,hauteur_car
  sub CH,BL          {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

  lds SI,ptr_curseur_souris  {DS:SI -> motif curseur}
  xor BH,BH
  add DI,BX

 @boucle_redef_1:
  mov AX,1111111111111111b   {masque contour par d‚faut}
  mov BH,[SI]        {charge une ligne du motif curseur}
  test BH,10000000b
  jz @inf_128_1
  and AH,11111101b
 @inf_128_1:
  mov BL,00000001b
 @calcule_masque_1:
  test BH,BL
  jz @bit_suivant_1
  mov DL,BL
  not DL
  and AL,DL
  @cherche_zero_1:
   shl BL,1
   jc @fin_masque_1
   test BH,BL
   jnz @cherche_zero_1
  xor DH,DH
  mov DL,BL
  shl DX,1
  not DX
  and AX,DX
 @bit_suivant_1:
  shl BL,1
  jnc @calcule_masque_1
 @fin_masque_1:      {AX=masque contour (10 bits utiles)}

  ror AX,CL          {d‚cale horizontalement}
  and AL,ES:[DI]     {masque une ligne du caractŠre curseur souris 1}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 1}
  inc SI
  dec CH
  jnz @boucle_redef_1

  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 2}
  xor AH,AH
  mov AL,car_souris_sm_2
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 2}

  mov CL,modulo_x    {CL=x_souris_sm Modulo 8}
  or CL,CL           {lignes … red‚finir?}
  jz @suite_3        {non, le motif est entiŠrement sur la colonne de texte … gauche}
  neg CL
  add CL,7           {CL=7-(x_souris_sm Modulo 8)}
  mov BL,modulo_y    {BL=y_souris_sm Modulo hauteur_car}
  mov CH,hauteur_car
  sub CH,BL          {CH=hauteur_car-(y_souris_sm Modulo hauteur_car)}

  lds SI,ptr_curseur_souris  {DS:SI -> motif curseur}
  xor BH,BH
  add DI,BX

 @boucle_redef_2:
  mov AX,1111111111111111b   {masque contour par d‚faut}
  mov BH,[SI]        {charge une ligne du motif curseur}
  test BH,10000000b
  jz @inf_128_2
  and AH,11111101b
 @inf_128_2:
  mov BL,00000001b
 @calcule_masque_2:
  test BH,BL
  jz @bit_suivant_2
  mov DL,BL
  not DL
  and AL,DL
  @cherche_zero_2:
   shl BL,1
   jc @fin_masque_2
   test BH,BL
   jnz @cherche_zero_2
  xor DH,DH
  mov DL,BL
  shl DX,1
  not DX
  and AX,DX
 @bit_suivant_2:
  shl BL,1
  jnc @calcule_masque_2
 @fin_masque_2:      {AX=masque contour (10 bits utiles)}

  rol AX,CL          {d‚cale horizontalement}
  and AL,ES:[DI]     {masque une ligne du caractŠre curseur souris 2}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 2}
  inc SI
  dec CH
  jnz @boucle_redef_2

 @suite_3:
  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 3}
  xor AH,AH
  mov AL,car_souris_sm_3
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 3}

  mov CL,modulo_x
  inc CL             {CL=(x_souris_sm Modulo 8)+1}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … red‚finir?}
  jz @suite_4        {non, le motif est entiŠrement sur la ligne de texte du dessus}

  lds SI,ptr_curseur_souris  {DS:SI -> motif curseur}
  xor BH,BH
  mov BL,hauteur_car
  sub BL,CH          {BX=hauteur_car-(y_souris_sm Modulo hauteur_car)}
  add SI,BX

 @boucle_redef_3:
  mov AX,1111111111111111b   {masque contour par d‚faut}
  mov BH,[SI]        {charge une ligne du motif curseur}
  test BH,10000000b
  jz @inf_128_3
  and AH,11111101b
 @inf_128_3:
  mov BL,00000001b
 @calcule_masque_3:
  test BH,BL
  jz @bit_suivant_3
  mov DL,BL
  not DL
  and AL,DL
  @cherche_zero_3:
   shl BL,1
   jc @fin_masque_3
   test BH,BL
   jnz @cherche_zero_3
  xor DH,DH
  mov DL,BL
  shl DX,1
  not DX
  and AX,DX
 @bit_suivant_3:
  shl BL,1
  jnc @calcule_masque_3
 @fin_masque_3:      {AX=masque contour (10 bits utiles)}

  ror AX,CL          {d‚cale horizontalement}
  and AL,ES:[DI]     {masque une ligne du caractŠre curseur souris 1}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 1}
  inc SI
  dec CH
  jnz @boucle_redef_3

 @suite_4:
  pop DS             {r‚cupŠre DS de Turbo-Pascal}
  push DS

  {caractŠre curseur souris 4}
  xor AH,AH
  mov AL,car_souris_sm_4
  shl AX,5           {AX=32*code}
  mov DI,AX          {ES:DI -> ligne 0 du caractŠre curseur souris 4}

  mov CL,modulo_x    {CL=x_souris_sm Modulo 8}
  or CL,CL           {lignes … red‚finir?}
  jz @fin            {non, le motif est entiŠrement sur la colonne de texte … gauche}
  neg CL
  add CL,7           {CL=7-(x_souris_sm Modulo 8)}
  mov CH,modulo_y    {CH=y_souris_sm Modulo hauteur_car}
  or CH,CH           {lignes … red‚finir?}
  jz @fin            {non, le motif est entiŠrement sur la ligne de texte du dessus}

  lds SI,ptr_curseur_souris  {DS:SI -> motif curseur}
  xor BH,BH
  mov BL,hauteur_car
  sub BL,CH          {BX=hauteur_car-(y_souris_sm Modulo hauteur_car)}
  add SI,BX

 @boucle_redef_4:
  mov AX,1111111111111111b   {masque contour par d‚faut}
  mov BH,[SI]        {charge une ligne du motif curseur}
  test BH,10000000b
  jz @inf_128_4
  and AH,11111101b
 @inf_128_4:
  mov BL,00000001b
 @calcule_masque_4:
  test BH,BL
  jz @bit_suivant_4
  mov DL,BL
  not DL
  and AL,DL
  @cherche_zero_4:
   shl BL,1
   jc @fin_masque_4
   test BH,BL
   jnz @cherche_zero_4
  xor DH,DH
  mov DL,BL
  shl DX,1
  not DX
  and AX,DX
 @bit_suivant_4:
  shl BL,1
  jnc @calcule_masque_4
 @fin_masque_4:      {AX=masque contour (10 bits utiles)}

  rol AX,CL          {d‚cale horizontalement}
  and AL,ES:[DI]     {masque une ligne du caractŠre curseur souris 1}
  stosb              {‚crit la ligne dans le caractŠre curseur souris 1}
  inc SI
  dec CH
  jnz @boucle_redef_4

 @fin:
  pop DS
 end;

 AccedeMem
end; {CursSourisSmooth}

{----------------------------------------------------------}

procedure AffCursSouris; {VGA}
{ 1 2 }
{ 3 4 }
begin
 if curseur_visible then exit;

 curseur_souris_change:=TRUE;

 {sauve les 4 caractŠres}
 asm
  mov AX,0B800h
  mov ES,AX         {ES=B800}

  mov DL,Xsouris
  mov DH,Ysouris

  xor BH,BH
  mov BL,largeur_ecran_txt

  xor AH,AH
  mov AL,DL
  mov DI,AX
  dec DI            {DI=Xsouris-1}
  mov AL,DH
  dec AL
  mul BL            {AX=largeur_ecran_txt*(Ysouris-1)}
  add DI,AX
  shl DI,1          {DI=2*((Xsouris-1)+largeur_ecran_txt*(Ysouris-1))}

  shl BX,1          {BX=2*largeur_ecran_txt}

  mov AL,ES:[DI]
  mov anc_car_souris_sm_1,AL
  mov AL,car_souris_sm_1
  mov ES:[DI],AL
  cmp DL,largeur_ecran_txt
  jae @suite        {Xsouris>=largeur_ecran_txt -> n'affiche pas le caractŠre 2}
  mov AL,ES:[DI+2]
  mov anc_car_souris_sm_2,AL
  mov AL,car_souris_sm_2
  mov ES:[DI+2],AL
 @suite:
  cmp DH,hauteur_ecran_txt
  jae @fin          {Ysouris>=hauteur_ecran_txt -> n'affiche pas les caractŠres 3,4}
  mov AL,ES:[DI+BX]
  mov anc_car_souris_sm_3,AL
  mov AL,car_souris_sm_3
  mov ES:[DI+BX],AL
  cmp DL,largeur_ecran_txt
  jae @fin          {Xsouris>=largeur_ecran_txt -> n'affiche pas le caractŠre 4}
  mov AL,ES:[DI+BX+2]
  mov anc_car_souris_sm_4,AL
  mov AL,car_souris_sm_4
  mov ES:[DI+BX+2],AL
 @fin:
 end;

 CursSourisSmooth;

 curseur_souris_change:=FALSE;
 curseur_visible:=TRUE;
end; {AffCursSouris}

{----------------------------------------------------------}

procedure CacheCursSouris; {VGA}
begin
 if not(curseur_visible) then exit;

 curseur_souris_change:=TRUE;

 {restaure les 4 caractŠres}
 asm
  mov AX,0B800h
  mov ES,AX         {ES=B800}

  mov DL,Xsouris
  mov DH,Ysouris

  xor BH,BH
  mov BL,largeur_ecran_txt

  xor AH,AH
  mov AL,DL
  mov DI,AX
  dec DI            {DI=Xsouris-1}
  mov AL,DH
  dec AL
  mul BL            {AX=largeur_ecran_txt*(Ysouris-1)}
  add DI,AX
  shl DI,1          {DI=2*((Xsouris-1)+largeur_ecran_txt*(Ysouris-1))}

  shl BX,1          {BX=2*largeur_ecran_txt}

  mov AL,anc_car_souris_sm_1
  mov ES:[DI],AL
  cmp DL,largeur_ecran_txt
  jae @suite        {Xsouris>=largeur_ecran_txt -> n'affiche pas le caractŠre 2}
  mov AL,anc_car_souris_sm_2
  mov ES:[DI+2],AL
 @suite:
  cmp DH,hauteur_ecran_txt
  jae @fin          {Ysouris>=hauteur_ecran_txt -> n'affiche pas les caractŠres 3,4}
  mov AL,anc_car_souris_sm_3
  mov ES:[DI+BX],AL
  cmp DL,largeur_ecran_txt
  jae @fin          {Xsouris>=largeur_ecran_txt -> n'affiche pas le caractŠre 4}
  mov AL,anc_car_souris_sm_4
  mov ES:[DI+BX+2],AL
 @fin:
 end;

 curseur_souris_change:=FALSE;
 curseur_visible:=FALSE;
end; {CacheCursSouris}

{----------------------------------------------------------}

{$F+}
procedure GestEvenSourisSmooth(evenements,boutons: BYTE; posx,posy: WORD; dx,dy: INTEGER);
{proc‚dure appel‚e lorsque la souris bouge - met … jour le curseur (page nø0)}
var cv: BOOLEAN;
begin
 if not(curseur_souris_change) then begin
  cv:=curseur_visible;
  if cv then begin AttendVBL; CacheCursSouris end;

  inc(x_souris_sm,dx div 2); inc(y_souris_sm,dy div 2);
  if x_souris_sm<(zone_souris_xg-1)*8           then x_souris_sm:=(zone_souris_xg-1)*8;
  if x_souris_sm>(zone_souris_xd*8-1)           then x_souris_sm:=(zone_souris_xd*8-1);
  if y_souris_sm<(zone_souris_yh-1)*hauteur_car then y_souris_sm:=(zone_souris_yh-1)*hauteur_car;
  if y_souris_sm>(zone_souris_yb*hauteur_car-1) then y_souris_sm:=(zone_souris_yb*hauteur_car-1);

  Xsouris:=1+(x_souris_sm div 8);
  Ysouris:=1+(y_souris_sm div hauteur_car);
  {!! Xsouris et Ysouris sont diff‚rentes des coordonn‚es renvoy‚es par le driver !!}

  if cv then AffCursSouris;
  asm
   mov AX,0Bh
   int 33h    {pour annuler dx et dy (sinon, pb de d‚placement du curseur...)}
  end;
 end;

 SourisBouge:=TRUE;
end; {GestEvenSourisSmooth}
{$F-}

{----------------------------------------------------------}

procedure DefCursSouris(forme: BYTE); {VGA}
begin
 curseur_souris_change:=TRUE;

 if forme<>forme_actuelle then index_curseur:=0;
 forme_actuelle:=forme;
 top_anime_curseur:=Timer;

 case forme_actuelle of
  fleche : case hauteur_car of
            16: ptr_curseur_souris:=@curseur_fleche_16;
            14: ptr_curseur_souris:=@curseur_fleche_14;
             8: ptr_curseur_souris:=@curseur_fleche_8;
           end;
  sablier: case hauteur_car of
            16: ptr_curseur_souris:=@curseur_sablier_16[index_curseur];
            14: ptr_curseur_souris:=@curseur_sablier_14[index_curseur];
             8: ptr_curseur_souris:=@curseur_sablier_8 [index_curseur];
           end;
  rotatif: case hauteur_car of
            16: ptr_curseur_souris:=@curseur_rotatif_16[index_curseur];
            14: ptr_curseur_souris:=@curseur_rotatif_14[index_curseur];
             8: ptr_curseur_souris:=@curseur_rotatif_8 [index_curseur];
           end;
 end;

 CursSourisSmooth;
 curseur_souris_change:=FALSE;
end; {DefCursSouris}

{----------------------------------------------------------}

procedure AnimeCursSouris; {VGA}
begin
 if Timer>=top_anime_curseur+vitesse_curseur[forme_actuelle] then begin
  case forme_actuelle of
   sablier: case hauteur_car of
             16: index_curseur:=(index_curseur+1) mod nombre_sabliers_16;
             14: index_curseur:=(index_curseur+1) mod nombre_sabliers_14;
              8: index_curseur:=(index_curseur+1) mod nombre_sabliers_8;
            end;
   rotatif: index_curseur:=(index_curseur+1) and $07;
  end;
  DefCursSouris(forme_actuelle);
 end;
end; {AnimeCursSouris}

{----------------------------------------------------------}

procedure InitSourisSmooth(car_1,car_2,car_3,car_4: CHAR); {VGA}
{d‚finit les 4 caractŠres du curseur, initialise les donn‚es et installe le
 gestionnaire d'‚v‚nements}
begin
 car_souris_sm_1:=car_1; car_souris_sm_2:=car_2;
 car_souris_sm_3:=car_3; car_souris_sm_4:=car_4;

 x_souris_sm:=Souris.Xsouris;
 y_souris_sm:=Souris.Ysouris; {coordonn‚es absolues}
 Xsouris:=1+(x_souris_sm div 8);
 Ysouris:=1+(y_souris_sm div hauteur_car); {coordonn‚es texte}

 zone_souris_xg:=1; zone_souris_yh:=1;
 zone_souris_xd:=largeur_ecran_txt; zone_souris_yb:=hauteur_ecran_txt;

 forme_actuelle:=fleche; DefCursSouris(fleche);

 curseur_visible:=FALSE;
 InstalleGestEvenSouris(souris_bouge,@GestEvenSourisSmooth);
end; {InitSourisSmooth}

{----------------------------------------------------------}

procedure FinSourisSmooth; {VGA}
begin
 CacheCursSouris;
 DesinstGestEvenSouris;
end; {FinSourisSmooth}

{----------------------------------------------------------}

procedure EtatSouris(var x,y,boutons: BYTE);
begin
 x:=Xsouris;
 y:=Ysouris;
 boutons:=BoutonSouris;
end; {EtatSouris}

{----------------------------------------------------------}

procedure BougeCursSourisXY(x,y: BYTE);
begin
 if not EstDansZone(x,y,zone_souris_xg,zone_souris_yh,
                        zone_souris_xd,zone_souris_yb) then exit;
 CacheCursSouris;
 Xsouris:=x;
 Ysouris:=y;
 x_souris_sm:=(x-1)*8;
 y_souris_sm:=(y-1)*hauteur_car;
 AffCursSouris;
end; {BougeCursSourisXY}

{----------------------------------------------------------}

function NbrAppuisBouton(bouton: BYTE; var x,y: BYTE): BYTE;
{NON UTILISABLE !!}
begin
 NbrAppuisBouton:=0;
 x:=Xsouris; y:=Ysouris;
end; {NbrAppuisBouton}

{----------------------------------------------------------}

function NbrRelachBouton(bouton: BYTE; var x,y: BYTE): BYTE;
{NON UTILISABLE !!}
begin
 NbrRelachBouton:=0;
 x:=Xsouris; y:=Ysouris;
end; {NbrRelachBouton}

{----------------------------------------------------------}

procedure ZoneSouris(xg,yh,xd,yb: BYTE);
begin
 CacheCursSouris;
 zone_souris_xg:=xg;
 zone_souris_yh:=yh;
 zone_souris_xd:=xd;
 zone_souris_yb:=yb;
 x_souris_sm:=LimiteEntier(x_souris_sm,(zone_souris_xg-1)*8,(zone_souris_xd*8-1));
 y_souris_sm:=LimiteEntier(y_souris_sm,(zone_souris_yh-1)*hauteur_car,(zone_souris_yb*hauteur_car-1));
 Xsouris:=1+(x_souris_sm div 8);
 Ysouris:=1+(y_souris_sm div hauteur_car);
 AffCursSouris
end; {ZoneSouris}

{----------------------------------------------------------}

{$ENDIF}

{tout ce qui suit est commun}

function EstDansZone(x,y,xg,yh,xd,yb: BYTE): BOOLEAN;
begin
 EstDansZone:=(x in [xg..xd]) and (y in [yh..yb]);
end; {EstDansZone}

{----------------------------------------------------------}

procedure AttendClavierSouris(attend_bouge,condition: BOOLEAN; var x,y: BYTE);
var x_init,y_init,boutons: BYTE;
begin
 VideBufferClavier;
 AffCursSouris;
 EtatSouris(x_init,y_init,boutons);
 if attend_bouge then
  repeat
   EtatSouris(x,y,boutons);
  until KeyPressed or (x<>x_init) or (y<>y_init) or (boutons=aucun);
 repeat until KeyPressed or (BoutonSouris<>aucun) or condition;
 EtatSouris(x,y,boutons);
end; {AttendClavierSouris}

{----------------------------------------------------------}

procedure BoutonBase.Active(condition: BOOLEAN);
begin
 actif_:=condition;
end; {BoutonBase.Active}

{----------------------------------------------------------}

procedure BoutonBase.Definit(page_,x,y_: BYTE; titre_: String25;
                             attr_relache,attr_appuye,attr_lettre: BYTE);
{si 'titre_' contient deux "^", le caractŠre suivant le premier "^" est la
 lettre en surbrillance, sinon le bouton ne peut pas ˆtre appuy‚ au clavier}
begin
 page:=page_; y:=y_; titre:=titre_;
 pos_lettre:=Pos('^',titre)+1;
 xg:=x; xd:=x+Length(titre)-1;
 if pos_lettre>1 then dec(xd,2);
 attribut[FALSE]:=attr_relache; attribut[TRUE]:=attr_appuye;
 attribut_lettre:=attr_lettre;
 actif_:=TRUE; appuye_:=FALSE; {actif et relƒch‚ par d‚faut}
end; {BoutonBase.Definit}

{----------------------------------------------------------}

procedure Bouton.Definit(page_,x,y_: BYTE; titre_: String25;
                         attr_relache,attr_appuye,attr_lettre,attr_inactif: BYTE);
begin
 inherited Definit(page_,x,y_,titre_,attr_relache,attr_appuye,attr_lettre);
 attribut_inactif:=attr_inactif;
end; {Bouton.Definit}

{----------------------------------------------------------}

procedure Bouton.Affiche;
const code: array[BOOLEAN,1..2] of CHAR=(('ß','Ü'),(' ',' '));
var attr_fond: BYTE;
begin
 CacheCursSouris;
 attr_fond:=AttrXY(page,xg,y+1) and $F0;
 if appuye_ then begin
  AffCarXY(page,xg-1,y,' ',attr_fond);
  AffCarXY(page,xg,y+1,' ',attr_fond);
 end;
 if actif_ then AffChXY2(page,xg,y,titre,attribut[appuye_],attribut_lettre)
           else AffChXY2(page,xg,y,titre,attribut_inactif,attribut_inactif);
 AffChXY(page,xg+1,y+1,RepeteCar(code[appuye_,1],xd-xg+1),attr_fond);
 AffCarXY(page,xd+1,y,code[appuye_,2],attr_fond);
 AffCursSouris;
end; {Bouton.Affiche}

{----------------------------------------------------------}

function Bouton.Appuye(touche: CHAR): BOOLEAN;
begin
 Appuye:=FALSE;
 if actif_ and (pos_lettre>1) and (System.UpCase(touche)=System.UpCase(titre[pos_lettre])) then begin
  Appuye:=TRUE;
  inc(xg); inc(xd); appuye_:=TRUE; Affiche;
  Pause(3);
  dec(xg); dec(xd); appuye_:=FALSE; Affiche;
  VideBufferClavier;
 end;
end; {Bouton.Appuye}

{----------------------------------------------------------}

function Bouton.Clique: BOOLEAN;
var xs,ys,bt: BYTE;
begin
 Clique:=FALSE;
 EtatSouris(xs,ys,bt);
 if actif_ then
  if (ys=y) and (xs in [xg-BYTE(appuye_)..xd]) then
   if bt=gauche then begin
    repeat
     EtatSouris(xs,ys,bt);
     if (ys=y) and (xs in [xg-BYTE(appuye_)..xd]) then begin
      if not(appuye_) then begin inc(xg); inc(xd) end; appuye_:=TRUE;
     end
     else begin
      if appuye_ then begin dec(xg); dec(xd) end; appuye_:=FALSE;
     end;
     AttendVBL;
     Affiche;
     {$IFDEF Smooth}
     SourisBouge:=FALSE;
     {$ENDIF}
     repeat until (BoutonSouris=aucun) or SourisBouge;
    until bt=aucun;

    Clique:=appuye_;
    if appuye_ then begin dec(xg); dec(xd); appuye_:=FALSE; Affiche end;
    VideBufferClavier;
   end;
end; {Bouton.Clique}

{----------------------------------------------------------}

procedure Bouton3D.Definit(page_,x,y_: BYTE; titre_: String25;
                           attend_relache_: BOOLEAN;
                           base_delai_,
                           attr_relache,attr_appuye,attr_lettre,
                           coul_relief_haut_,coul_relief_bas_,coul_relief_coin_: BYTE;
                           car_coin_inf_droit_: CHAR);
{si 'attend_relache_'=TRUE, 'base_delai_' n'a aucun effet}
begin
 inherited Definit(page_,x,y_,titre_,attr_relache,attr_appuye,attr_lettre);
 attend_relache:=attend_relache_;
 base_delai:=base_delai_;
 coul_relief_haut:=coul_relief_haut_; coul_relief_bas:=coul_relief_bas_;
 coul_relief_coin:=coul_relief_coin_;
 car_coin_inf_droit:=car_coin_inf_droit_;
end; {Bouton3D.Definit}

{----------------------------------------------------------}

procedure Bouton3D.Affiche;
var attr_fond,coul_haut,coul_bas,coul_coin: BYTE;
begin
 CacheCursSouris;
 attr_fond:=AttrXY(page,xg,y+1) and $F0;

 if not(actif_) then
  begin coul_haut:=coul_relief_bas; coul_bas:=0; coul_coin:=coul_relief_bas end
 else begin
  if appuye_ then begin coul_haut:=coul_relief_bas; coul_bas:=coul_relief_haut end
             else begin coul_haut:=coul_relief_haut; coul_bas:=coul_relief_bas end;
  coul_coin:=coul_relief_coin;
 end;

 AffCarXY(page,xd+1,y+1,car_coin_inf_droit  ,attr_fond or coul_bas);
 AffCarXY(page,xg-1,y+1,Succ(car_coin_inf_droit),attr_fond or coul_coin);
 AffCarXY(page,xd+1,y-1,Succ(Succ(car_coin_inf_droit)),attr_fond or coul_coin);
 AffCarXY(page,xg-1,y-1,Succ(Succ(Succ(car_coin_inf_droit))),attr_fond or coul_haut);
 AffCarXY(page,xg-1,y,'Þ',attr_fond or coul_haut);
 AffCarXY(page,xd+1,y,'Ý',attr_fond or coul_bas);
 AffChXY(page,xg,y-1,RepeteCar('Ü',xd-xg+1),attr_fond or coul_haut);
 AffChXY(page,xg,y+1,RepeteCar('ß',xd-xg+1),attr_fond or coul_bas);

 if actif_ then AffChXY2(page,xg,y,titre,attribut[appuye_],attribut_lettre)
           else AffChXY2(page,xg,y,titre,coul_relief_bas shl 4,coul_relief_bas shl 4);
 AffCursSouris;
end; {Bouton3D.Affiche}

{----------------------------------------------------------}

function Bouton3D.Appuye(touche: CHAR): BOOLEAN;
begin
 Appuye:=FALSE;
 if actif_ and (pos_lettre>1) and (System.UpCase(touche)=System.UpCase(titre[pos_lettre])) then begin
  Appuye:=TRUE;
  appuye_:=TRUE; Affiche;
  Pause(3);
  appuye_:=FALSE; Affiche;
  VideBufferClavier;
 end;
end; {Bouton3D.Appuye}

{----------------------------------------------------------}

function Bouton3D.Clique: BOOLEAN;
var xs,ys,bt: BYTE;
begin
 Clique:=FALSE;
 EtatSouris(xs,ys,bt);
 if actif_ then
  if (ys=y) and (xs in [xg..xd]) and (bt=gauche) then begin
   repeat
    EtatSouris(xs,ys,bt);
    appuye_:=(ys=y) and (xs in [xg..xd]);
    AttendVBL;
    Affiche;
    {$IFNDEF Smooth}
    if attend_relache then
     if appuye_ then DefCursSouris(inverse_attribut,0,0,'û')
                else DefCursSouris(standard,0,0,#0);
    {$ENDIF}
    if not(attend_relache) and appuye_ then
     begin DelaiBoutonSouris(base_delai); Clique:=TRUE; exit end;
    {$IFDEF Smooth}
    SourisBouge:=FALSE;
    {$ENDIF}
    repeat until (BoutonSouris=aucun) or SourisBouge;
   until bt=aucun;
   {$IFNDEF Smooth}
   if attend_relache then DefCursSouris(standard,0,0,#0);
   {$ENDIF}
   Clique:=appuye_;
   if appuye_ then begin appuye_:=FALSE; Affiche end;
   VideBufferClavier;
  end
  else
   if not(attend_relache) and appuye_ then begin
    appuye_:=FALSE;
    AttendVBL;
    Affiche;
   end;
end; {Bouton3D.Clique}

{----------------------------------------------------------}

procedure CaseOpt.Definit(page_,x_,y_: BYTE;
                          car_non_cochee_,car_cochee_,car_appuyee_: CHAR;
                          attr_active,attr_inactive: BYTE);
begin
 page:=page_; x:=x_; y:=y_;
 car[FALSE]:=car_non_cochee_; car[TRUE]:=car_cochee_;
 car_appuyee:=car_appuyee_;
 attribut[TRUE]:=attr_active; attribut[FALSE]:=attr_inactive;
 active_:=TRUE; cochee_:=FALSE; appuyee_:=FALSE; {active, non coch‚e et relƒch‚e par d‚faut}
end; {CaseOpt.Definit}

{----------------------------------------------------------}

procedure CaseOpt.Active(condition: BOOLEAN);
begin
 active_:=condition;
end; {CaseOpt.Active}

{----------------------------------------------------------}

procedure CaseOpt.Coche(condition: BOOLEAN);
begin
 cochee_:=condition;
end; {CaseOpt.Coche}

{----------------------------------------------------------}

procedure CaseOpt.Affiche;
begin
 CacheCursSouris;
 if appuyee_ then AffCarXY(page,x,y,car_appuyee,attribut[active_])
 else AffCarXY(page,x,y,car[cochee_],attribut[active_]);
 AffCursSouris;
end; {CaseOpt.Affiche}

{----------------------------------------------------------}

function CaseOpt.Cliquee: BOOLEAN;
var xs,ys,bt: BYTE;
begin
 Cliquee:=FALSE;
 EtatSouris(xs,ys,bt);
 if active_ then
  if (ys=y) and (xs=x) and (bt=gauche) then begin
   repeat
    EtatSouris(xs,ys,bt);
    appuyee_:=(ys=y) and (xs=x);
    Affiche;
    {$IFDEF Smooth}
    SourisBouge:=FALSE;
    {$ENDIF}
    repeat until (BoutonSouris=aucun) or SourisBouge;
   until bt=aucun;
   Cliquee:=appuyee_;
   if appuyee_ then begin appuyee_:=FALSE; cochee_:=not(cochee_); Affiche end;
   VideBufferClavier;
  end;
end; {CaseOpt.Cliquee}

{----------------------------------------------------------}

procedure ObjClic.Definit(page_,x,y_: BYTE; titre_: String25;
                          attend_relache_: BOOLEAN;
                          base_delai_,attr_ext_,attr_int_: BYTE);
{'titre_' peut contenir deux "^" pour l'affichage 2 couleurs
 l'objet peut ˆtre cliqu‚ avec n'importe quel bouton
 si 'attend_relache_'=TRUE, 'base_delai_' n'a aucun effet}
begin
 page:=page_; y:=y_; titre:=titre_;
 xg:=x; xd:=x+Length(titre)-1;
 if Pos('^',titre)<>0 then dec(xd,2);
 attend_relache:=attend_relache_;
 base_delai:=base_delai_;
 attr_ext:=attr_ext_; attr_int:=attr_int_;
end; {ObjClic.Definit}

{----------------------------------------------------------}

procedure ObjClic.Affiche;
begin
 CacheCursSouris; AffChXY2(page,xg,y,titre,attr_ext,attr_int); AffCursSouris;
end; {ObjClic.Affiche}

{----------------------------------------------------------}

function ObjClic.Clique: BOOLEAN;
var xs,ys,bt: BYTE;
    appuye: BOOLEAN;
begin
 Clique:=FALSE;
 EtatSouris(xs,ys,bt);
 if (ys=y) and (xs in [xg..xd]) and (bt<>aucun) then begin
  repeat
   EtatSouris(xs,ys,bt);
   appuye:=(ys=y) and (xs in [xg..xd]);
   {$IFNDEF Smooth}
   if attend_relache then
    if appuye then DefCursSouris(inverse_attribut,0,0,'û')
              else DefCursSouris(standard,0,0,#0);
   {$ENDIF}
   if not(attend_relache) and appuye then
    begin DelaiBoutonSouris(base_delai); Clique:=TRUE; exit end;
   {$IFDEF Smooth}
   SourisBouge:=FALSE;
   {$ENDIF}
   repeat until (BoutonSouris=aucun) or SourisBouge;
  until bt=aucun;
  {$IFNDEF Smooth}
  if attend_relache then DefCursSouris(standard,0,0,#0);
  {$ENDIF}
  Clique:=appuye;
  VideBufferClavier;
 end;
end; {ObjClic.Clique}

{==========================================================}

END.
