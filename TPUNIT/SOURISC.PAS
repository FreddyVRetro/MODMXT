{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                       --==ðð SOURISC.PAS ðð==--                      º}
{º                                                                      º}
{º Unit‚ pour g‚rer la souris en mode texte CGA                         º}
{º    IMPORTANT: … charger aprŠs l'unit‚ Souris !!                      º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 286           D‚but d'‚critureúúúúúúúúúúúúúú ??/03/94 º}
{º                              DerniŠres modificationsúúúúúúú 26/07/98 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

{$UNDEF Smooth}
{$DEFINE CGAOnly}

UNIT SourisC;

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

{==========================================================}

procedure DefCursSouris(mode,fond,ecriture: BYTE; caractere: CHAR);

function  Xsouris: BYTE;
function  Ysouris: BYTE;

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


VAR mode_curseur,
    couleur_fond_souris,
    couleur_ecriture_initiale_souris,couleur_ecriture_souris: BYTE;
    caractere_souris: CHAR;

{==========================================================}

{----------------------------------------------------------}

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
  shl AL,1
  shl AL,1
  shl AL,1
  shl AL,1
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
 if ((actif_) or (Hercule=1)) then AffChXY2(page,xg,y,titre,attribut[appuye_],attribut_lettre)
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
