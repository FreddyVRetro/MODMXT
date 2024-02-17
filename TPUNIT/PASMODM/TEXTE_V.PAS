{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                       --==ðð TEXTE.PAS ðð==--                        º}
{º                                                                      º}
{º Unit‚ pour g‚rer le mode texte sur ‚cran couleur (CGA, VGA )         º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 8088          D‚but d'‚critureúúúúúúúúúúúúúúú??/10/93 º}
{º                              DerniŠres modificationsúúúúúúúú05/02/97 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT Texte_V;

{$A+,G-,Q-,R-,S-}

INTERFACE

{$I Types}

CONST {variables d‚pendant du mode texte courant}
      delta_segment_VRAM: Word=16+((80*25) SHR 3); {variation de segment RAM vid‚o d'une page vers la suivante}
      largeur_ecran_txt : Byte=80;  {nombre de colonnes de l'‚cran texte (virtuelles si >80)}
      hauteur_ecran_txt : Byte=25;  {nombre de lignes visibles de l'‚cran texte}
      largeur_car: Byte= 9; {largeur d'un caractŠre en pixels}
      hauteur_car: Byte=16; {hauteur d'un caractŠre en pixels}

      {dimensions max de l'‚cran texte en colonnes/lignes}
      largeur_ecran_max=132; {SVGA}
      hauteur_ecran_max=50;  {VGA}

      {adresse et attribut courants pour AffCar/AffCh}
      AdrTexte : WordPtr=Ptr($B800,0);
      AttrTexte: Byte=16*0+7;

      {incr‚ment automatique pour Palette16.Fondu}
      auto=0;

      {jeux de caractŠres pour ActiveJeuCar}
      car8x16=$14;
      car8x14=$11;
      car8x8 =$12;

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
    

TYPE {type pour objets Zone et Ecran}
     VRAM=Array[1..largeur_ecran_max*hauteur_ecran_max] of
           Record attr: Byte; car: Char End;

     Zone=Object
           xg_,yh_,xd_,yb_: Integer; {xg_,yh_: coin sup‚rieur gauche
                                      xd_,yb_: coin inf‚rieur droit}
           PROCEDURE Sauve(page: Byte; xg,yh,xd,yb: Integer);
           PROCEDURE Ombre(page: Byte; xg,yh,xd,yb: Integer; attr: Byte);
           PROCEDURE RestaureLimite(page: Byte; x,y: Integer; xg,yh,xd,yb: Byte);
           PROCEDURE Restaure(page: Byte; dx,dy: Shortint; attr: Byte);
           PROCEDURE DeplaceLimite(page: Byte; dx,dy: Shortint; Var zone_cachee: Zone; xg,yh,xd,yb: Byte);
           PROCEDURE Deplace      (page: Byte; dx,dy: Shortint; Var zone_cachee: Zone);
           PROCEDURE Supprime;
           PROCEDURE Charge_(nom_fichier: String80; Var erreur: Word);
           PROCEDURE Sauve_ (nom_fichier: String80; Var erreur: Word);
          Private
           taille_octets: Word; {=2*(xd_-xg_+1)*(yb_-yh_+1)}
           contenu: ^VRAM;
          End;

     Ecran=Object
           PROCEDURE Sauve(page: Byte);
           PROCEDURE Restaure(page: Byte);
           PROCEDURE Supprime;
          Private
           contenu: ^VRAM;
          End;

     RVB=Record R,V,B: Byte End;

     Palette16=Object  {VGA}
                palette: Array[0..15] of RVB;
                PROCEDURE Charge;
                PROCEDURE Fixe;
                PROCEDURE Fondu(increment: Byte);
                PROCEDURE Charge_(nom_fichier: String80; Var erreur: Word);
                PROCEDURE Sauve_ (nom_fichier: String80; Var erreur: Word);
               End;

     {types de motifs ASCII pour RedefCar}
     Ascii16=Array[1..16,1..8] of Char; {25 lignes}
     Ascii14=Array[1..14,1..8] of Char; {28 lignes}
     Ascii8 =Array[1.. 8,1..8] of Char; {50 lignes}

     {types de motifs binaires pour RedefCar et objets FonteXX}
     Binaire16=Array[1..16] of Byte; {25 lignes}
     Binaire14=Array[1..14] of Byte; {28 lignes}
     Binaire8 =Array[1.. 8] of Byte; {50 lignes}

     Fonte16=Object
              fonte: Array[Byte] of Binaire16;
              PROCEDURE Charge(table: Byte);
              PROCEDURE Redef (table: Byte);
              PROCEDURE Charge_(nom_fichier: String80; Var erreur: Word);
              PROCEDURE Sauve_ (nom_fichier: String80; Var erreur: Word);
             End;

     Fonte14=Object
              fonte: Array[Byte] of Binaire14;
              PROCEDURE Charge(table: Byte);
              PROCEDURE Redef (table: Byte);
              PROCEDURE Charge_(nom_fichier: String80; Var erreur: Word);
              PROCEDURE Sauve_ (nom_fichier: String80; Var erreur: Word);
             End;

     Fonte8 =Object
              fonte: Array[Byte] of Binaire8;
              PROCEDURE Charge(table: Byte);
              PROCEDURE Redef (table: Byte);
              PROCEDURE Charge_(nom_fichier: String80; Var erreur: Word);
              PROCEDURE Sauve_ (nom_fichier: String80; Var erreur: Word);
             End;


CONST palette_defaut: Palette16=(palette:(
                       (R: 0; V: 0; B: 0), {Noir}
                       (R: 0; V: 0; B:42), {Bleu}
                       (R: 0; V:42; B: 0), {Vert}
                       (R: 0; V:42; B:42), {Cyan}
                       (R:42; V: 0; B: 0), {Rouge}
                       (R:42; V: 0; B:42), {Magenta}
                       (R:42; V:21; B: 0), {Marron}
                       (R:42; V:42; B:42), {Gris clair}
                       (R:21; V:21; B:21), {Gris fonc‚}
                       (R:21; V:21; B:63), {Bleu clair}
                       (R:21; V:63; B:21), {Vert clair}
                       (R:21; V:63; B:63), {Cyan clair}
                       (R:63; V:21; B:21), {Rouge clair}
                       (R:63; V:21; B:63), {Magenta clair}
                       (R:63; V:63; B:21), {Jaune}
                       (R:63; V:63; B:63)  {Blanc}
                      ));

      palette_noire: Palette16=(palette:(
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0),
                      (R:0; V:0; B:0),(R:0; V:0; B:0)
                     ));

      palette_blanche: Palette16=(palette:(
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63),
                        (R:63; V:63; B:63),(R:63; V:63; B:63)
                       ));

{==========================================================}

PROCEDURE ActiveJeuCar(jeu_caracteres,table: Byte); {VGA}
PROCEDURE InitTexte(lignes: Byte); {VGA si lignes>25}
PROCEDURE InitTexteVirtuel(colonnes: Byte); {VGA}
PROCEDURE InitTexte132(lignes: Byte); {SVGA}
FUNCTION  TesteModeTexte(Var largeur,hauteur: Byte): Byte;

PROCEDURE Clignotement(clignote: Boolean);

PROCEDURE ChargeDAC(couleur: Byte; Var comp: RVB); {VGA}
PROCEDURE FixeDAC  (couleur: Byte; comp: RVB); {VGA}

PROCEDURE SelectJeuCar(jeu1,jeu2: Byte); {VGA}
PROCEDURE LargeurCar(largeur: Byte); {VGA}
FUNCTION  PointeurTable(table: Byte): Pointer; {VGA}
PROCEDURE AccedeCar; {VGA}
PROCEDURE AccedeMem; {VGA}
PROCEDURE MotifBinaire(table: Byte; caractere: Char; Var motif); {VGA}
PROCEDURE PointCar(caractere: Char; ligne,colonne: Byte; allume: Boolean); {VGA}
PROCEDURE LigneCar(caractere: Char; ligne: Byte; allume: Boolean); {VGA}
PROCEDURE ColonneCar(caractere: Char; colonne: Byte; allume: Boolean); {VGA}
PROCEDURE RedefCar(table: Byte; premier_car: Char; nombre: Word; Var motif; mode: Byte); {VGA}

PROCEDURE ChargeFonte(table: Byte; Var buffer); {VGA}
PROCEDURE RedefFonte (table: Byte; Var buffer); {VGA}
PROCEDURE ChargeFonte_(nom_fichier: String80; hauteur: Byte; Var buffer; Var erreur: Word); {VGA}
PROCEDURE SauveFonte_ (nom_fichier: String80; hauteur: Byte; Var buffer; Var erreur: Word); {VGA}

PROCEDURE ScrolleVertical(ligne: Byte); {VGA}
PROCEDURE ScrolleHorizontal(colonne: Byte); {VGA}
PROCEDURE PlaceEcran(xg,yh: Word); {VGA}

PROCEDURE CursXY(page,x,y: Byte);
FUNCTION  PosX(page: Byte): Byte;
FUNCTION  PosY(page: Byte): Byte;

FUNCTION  PtrVRAM(page,x,y: Byte): WordPtr;

PROCEDURE AffCarXY(page,x,y: Byte; caractere: Char; attr: Byte);
PROCEDURE AffChXY (page,x,y: Byte; chaine: String; attr: Byte);
PROCEDURE AffChXY2(page,x,y: Byte; chaine: String; attr_ext,attr_int: Byte);
PROCEDURE AffChXYmc(page,x,y: Byte; chaine: String);
PROCEDURE AffCar(caractere: Char);
PROCEDURE AffCh(chaine: String);
PROCEDURE AffChE(chaine: String; caractere: Char; longueur: Byte);

PROCEDURE LigneHorizontale(page,epaisseur,y,xg,xd,attr: Byte);
PROCEDURE LigneVerticale  (page,epaisseur,x,yh,yb,attr: Byte);
PROCEDURE Cadre(page,epaisseur,xg,yh,xd,yb,attr: Byte; titre: String; attr_titre: Byte; touches: String25);

FUNCTION  CodeXY(page,x,y: Byte): Byte;
FUNCTION  AttrXY(page,x,y: Byte): Byte;

PROCEDURE EffaceZone(page,xg,yh,xd,yb,attr: Byte);
PROCEDURE EffacePage(page,attr: Byte);
PROCEDURE ChangePage(page: Byte);
PROCEDURE CopiePage (page_source,page_dest: Byte);

PROCEDURE ScrolleZoneHaut  (page,xg,yh,xd,yb: Byte);
PROCEDURE ScrolleZoneBas   (page,xg,yh,xd,yb: Byte);
PROCEDURE ScrolleZoneGauche(page,xg,yh,xd,yb: Byte);
PROCEDURE ScrolleZoneDroite(page,xg,yh,xd,yb: Byte);

{==========================================================}

IMPLEMENTATION

USES Fichiers,Util,VGA;

CONST {table de correspondance entre nø couleur et nø registre DAC}
      couleurs: Array[0..15] of Byte=(0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63);

{==========================================================}

PROCEDURE ActiveJeuCar(jeu_caracteres,table: Byte); {VGA}
{charge et active le jeu de caractŠres de la table (0 ou 1)}
Begin
 If Not(jeu_caracteres in [car8x16,car8x14,car8x8]) Then jeu_caracteres:=car8x16;
 Case jeu_caracteres of
  car8x16: Begin hauteur_ecran_txt:=25; hauteur_car:=16 End;
  car8x14: Begin hauteur_ecran_txt:=28; hauteur_car:=14 End;
  car8x8 : Begin hauteur_ecran_txt:=50; hauteur_car:=8  End
 End;
 delta_segment_VRAM:=16+((largeur_ecran_txt*hauteur_ecran_txt) SHR 3);
 AttendVBL;
 ASM
  MOV AH,11h
  MOV AL,jeu_caracteres
  MOV BL,table
  AND BL,00000001b      {corrige table: 0 ou 1}
  INT 10h
 End
End; {ActiveJeuCar}

{----------------------------------------------------------}

PROCEDURE InitTexte(lignes: Byte); {VGA si lignes>25}
{initialise le mode texte 80 colonnes x 25/28/50 lignes}
Begin
 ASM
  MOV AX,txt80_16c   {mode texte standard 80x25 16 couleurs par d‚faut}
  INT 10h
 End;
 largeur_ecran_txt:=80;
 If CarteVGA Then
  Begin
   If Not(lignes in [25,28,50]) Then lignes:=25;
   Case lignes of
    25: ActiveJeuCar(car8x16,0);
    28: ActiveJeuCar(car8x14,0);
    50: ActiveJeuCar(car8x8 ,0)
   End;
   LargeurCar(9)
  End
 Else
  Begin delta_segment_VRAM:=256; hauteur_ecran_txt:=25 End;

 AdrTexte :=Ptr($B800,0);
 AttrTexte:=16*0+7;
End; {InitTexte}

{----------------------------------------------------------}

PROCEDURE InitTexteVirtuel(colonnes: Byte); {VGA}
{fixe la longueur des lignes dans la RAM vid‚o -> 80..254 caractŠres
 Remarque: le nombre de colonnes est ajust‚ pour ˆtre pair;
 IMPORTANT: si colonnes>80, l'affichage multi-page n'est plus valable!}
Begin
 largeur_ecran_txt:=colonnes AND $FE;
 ASM
  MOV DX,CRTControl
  MOV AH,colonnes
  SHR AH,1
  MOV AL,Offset_
  OUT DX,AX         {d‚finit le nombre de colonnes}
 End;
End; {InitTexteVirtuel}

{----------------------------------------------------------}

PROCEDURE InitTexte132(lignes: Byte); {SVGA}
{initialise le mode texte 132 colonnes x 25,28,50 lignes
 REMARQUES: Ne fonctionne qu'en mode 8 pixels -> ne pas appeler LargeurCar !
            En mode 25 lignes, seule la page nø0 est affich‚e correctement
            En mode 50 lignes, deux pages seulement sont disponibles}
Begin
 ASM
  MOV AX,txt132_16c
  INT 10h
 End;
 largeur_ecran_txt:=132;
 If Not(lignes in [25,28,50]) Then lignes:=25;
 Case lignes of
  25: ActiveJeuCar(car8x16,0);
  28: ActiveJeuCar(car8x14,0);
  50: ActiveJeuCar(car8x8 ,0)
 End;

 AdrTexte :=Ptr($B800,0);
 AttrTexte:=16*0+7;
End; {InitTexte132}

{----------------------------------------------------------}

FUNCTION TesteModeTexte(Var largeur,hauteur: Byte): Byte; Assembler;
{renvoie le nø du mode texte actuel et ses dimensions en caractŠres}
ASM
 MOV AH,0Fh
 INT 10h
 LES DI,largeur
 MOV ES:[DI],AH
 MOV DX,40h
 MOV ES,DX
 MOV DL,ES:[84h]
 INC DL
 LES DI,hauteur
 MOV ES:[DI],DL
End; {TesteModeTexte}

{----------------------------------------------------------}

PROCEDURE Clignotement(clignote: Boolean); Assembler;
{si clignote=TRUE, les couleurs>=128 clignotent, sinon le fond est plus clair}
ASM
 MOV AX,1A00h {fonction 1Ah du BIOS EGA/VGA pour tester si carte EGA ou VGA}
 INT 10h
 CMP AL,1Ah
 JE  @egavga  {c'est une carte VGA}
 MOV AH,12h
 MOV BL,10h   {sous-fonction 10h de la fonction 12h du BIOS EGA/VGA}
 INT 10h
 CMP BL,10h   {BL a chang‚?}
 JNE @egavga  {oui, c'est donc une carte EGA}
 {on suppose ici que c'est une carte CGA!}
 MOV AL,00101001b   {par d‚faut, active le clignotement}
 CMP clignote,True
 JE  @suiteCGA
 MOV AL,00001001b   {d‚sactive le clignotement}
@suiteCGA:
 MOV DX,3D8h  {contr“leur CRT de la carte CGA}
 OUT DX,AL    {fixe l'attribut}
 JMP @fin
@egavga:
 MOV AX,1003h {fonction 10h du BIOS EGA/VGA pour fixer l'attribut clignotement}
 MOV BL,clignote
 INT 10h
@fin:
End; {Clignotement}

{----------------------------------------------------------}

PROCEDURE ChargeDAC(couleur: Byte; Var comp: RVB); {VGA}
Begin
 PortW[DACRead]:=couleurs[couleur AND $0F]; {charge le nø de registre DAC}
 With comp do Begin R:=Port[DACData]; V:=Port[DACData]; B:=Port[DACData] End
End; {ChargeDAC}

{----------------------------------------------------------}

PROCEDURE FixeDAC(couleur: Byte; comp: RVB); {VGA}
Begin
 ASM
  MOV AL,couleur
  AND AL,00001111b   {couleur de 0 … 15}
  MOV BX,OFFSET couleurs
  XLAT               {AL=nø registre DAC correspondant … couleur}
  MOV DX,DACWrite
  OUT DX,AL          {charge le nø de couleur dans le DAC}
  MOV DX,DACData
  MOV AL,comp.R
  OUT DX,AL          {fixe le rouge}
  MOV AL,comp.V
  OUT DX,AL          {fixe le vert}
  MOV AL,comp.B
  OUT DX,AL          {fixe le bleu}
 End
End; {FixeDAC}

{----------------------------------------------------------}

PROCEDURE Palette16.Charge; {VGA}
{charge la palette de 16 couleurs}
Var couleur: Byte;
Begin
 For couleur:=0 to 15 do ChargeDAC(couleur,palette[couleur])
End; {Palette16.Charge}

{----------------------------------------------------------}

PROCEDURE Palette16.Fixe; {VGA}
{fixe la palette de 16 couleurs}
Var couleur: Byte;
Begin
 AttendVBL;
 For couleur:=0 to 15 do FixeDAC(couleur,palette[couleur])
End; {Palette16.Fixe}

{----------------------------------------------------------}

PROCEDURE Palette16.Fondu(increment: Byte); {VGA}
{fait un fondu entre la palette courante et la palette destination}
Var initiale,courante: Palette16;
    couleur,diff,maxdiff,i: Byte;
Begin
 courante.Charge;
 initiale:=courante;
 If increment=auto Then  {calcule le nombre de palettes interm‚diaires automatiquement}
  Begin
   maxdiff:=0;
   For couleur:=0 to 15 do
    Begin
     diff:=Abs(palette[couleur].R-courante.palette[couleur].R);
     If diff>maxdiff Then maxdiff:=diff;
     diff:=Abs(palette[couleur].V-courante.palette[couleur].V);
     If diff>maxdiff Then maxdiff:=diff;
     diff:=Abs(palette[couleur].B-courante.palette[couleur].B);
     If diff>maxdiff Then maxdiff:=diff
    End
  End
 Else maxdiff:=increment; {nombre de palettes interm‚diaires fix‚}
 For i:=1 to maxdiff do
  Begin
   For couleur:=0 to 15 do
    Begin
     courante.palette[couleur].R:=initiale.palette[couleur].R+i*(palette[couleur].R-initiale.palette[couleur].R) Div maxdiff;
     courante.palette[couleur].V:=initiale.palette[couleur].V+i*(palette[couleur].V-initiale.palette[couleur].V) Div maxdiff;
     courante.palette[couleur].B:=initiale.palette[couleur].B+i*(palette[couleur].B-initiale.palette[couleur].B) Div maxdiff
    End;
   courante.Fixe
  End
End; {Palette16.Fondu}

{----------------------------------------------------------}

PROCEDURE Palette16.Charge_(nom_fichier: String80; Var erreur: Word); {VGA}
{charge la palette de 16 couleurs depuis le disque (48 octets)}
Var f: Fichier;
Begin
 With f do
  Begin
   Ouvre(lecture,nom_fichier);
   If f_erreur=f_ok Then
    Begin
     erreur:=0;
     If Taille=3*16 Then LitPos(0,palette,3*16) Else erreur:=err_format;
     Ferme;
     If erreur=err_format Then Exit
    End
  End;
 erreur:=f_erreur
End; {Palette16.Charge_}

{----------------------------------------------------------}

PROCEDURE Palette16.Sauve_(nom_fichier: String80; Var erreur: Word); {VGA}
{sauve la palette de 16 couleurs sur disque (48 octets)}
Var f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),nom_fichier);
   If f_erreur=f_ok Then Begin Ecrit(palette,3*16); Ferme End
  End;
 erreur:=f_erreur
End; {Palette16.Sauve_}

{----------------------------------------------------------}

PROCEDURE SelectJeuCar(jeu1,jeu2: Byte); Assembler; {VGA}
{s‚lectionne les 2 jeux de caractŠres affich‚s … l'‚cran (0 ó jeu1,jeu2 ó 7):
 (par d‚faut, jeu1=jeu2=0)
 -si jeu1=jeu2: 256 caractŠres, 16 couleurs d'‚criture
 -sinon: 512 caractŠres, 8 couleurs d'‚criture
         octet d'attribut: si bit 3=0: caractŠre affich‚ avec jeu1
                           si bit 3=1: caractŠre affich‚ avec jeu2}
ASM
 XOR AH,AH

 MOV AL,jeu1
 MOV BL,AL
 AND AL,00000011b
 OR  AH,AL
 AND BL,00000100b
 SHL BL,1
 SHL BL,1
 OR  AH,BL

 MOV AL,jeu2
 MOV BL,AL
 AND AL,00000011b
 SHL AL,1
 SHL AL,1
 OR  AH,AL
 AND BL,00000100b
 SHL BL,1
 SHL BL,1
 SHL BL,1
 OR  AH,BL

 MOV DX,Sequencer
 MOV AL,CharMapSelect
 OUT DX,AX
End; {SelectJeuCar}

{----------------------------------------------------------}

PROCEDURE LargeurCar(largeur: Byte); {VGA}
{fixe la largeur des caractŠres en pixels (8 ou 9)}
{-> NE PAS PAS APPELER EN MODE SVGA 132 colonnes !! <-}
Begin
 largeur_car:=largeur;
 AttendVBL;
 ASM
  MOV BX,0001h      {BH=alignement horizontal (ajust‚ … la fin)}
  CMP largeur,8     {BL=valeur pour le s‚quenceur}
  JE  @suite
  MOV BX,0800h
 @suite:
  MOV DX,MiscOutput
  IN AL,DX
  AND AL,11110011b  {passe en 640 points}
  CMP largeur,8
  JE  @ecrit_largeur
  OR  AL,00000100b  {passe en 720 points}
 @ecrit_largeur:
  MOV DX,InputStatus0
  OUT DX,AL         {fixe la largeur des caractŠres}

  CLI
  MOV DX,Sequencer
  MOV AX,(00000001b SHL 8)+Reset
  OUT DX,AX         {r‚initialise le s‚quenceur}
  MOV AH,BL         {00000000b: 9 points, 00000001b: 8 points}
  MOV AL,ClockingMode
  OUT DX,AX         {fixe la largeur des caractŠres}
  MOV AX,(00000011b SHL 8)+Reset
  OUT DX,AX         {relance le s‚quenceur}
  STI

  MOV AX,1000h
  MOV BL,13h
  INT 10h           {ajuste l'‚cran horizontalement}
 End
End; {LargeurCar}

{----------------------------------------------------------}

FUNCTION PointeurTable(table: Byte): Pointer; Assembler; {VGA}
{renvoie un pointeur sur les matrices de caractŠres de la table en ROM}
ASM
 MOV BH,table
 CMP table,courante
 JNE @suite
 MOV BH,6           {table 8x16}
 CMP hauteur_ecran_txt,25
 JE  @suite
 MOV BH,2           {table 8x14}
 CMP hauteur_ecran_txt,28
 JE  @suite
 MOV BH,3           {table 8x8}
@suite:
 MOV AX,1130h
 INT 10h
 MOV DX,ES
 MOV AX,BP      {DX:AX -> table de caractŠres en ROM}
End; {PointeurTable}

{----------------------------------------------------------}

PROCEDURE AccedeCar; Assembler; {VGA}
{autorise l'accŠs aux tables de caractŠres en A000:0000
 IMPORTANT! La RAM vid‚o ne peut plus ˆtre adress‚e en B800}
ASM
 CLI

 MOV DX,Sequencer
 MOV AX,(00000100b SHL 8)+MapMask
 OUT DX,AX      {autorise l'accŠs au plan de bits #2 (table de caractŠres)}
 MOV AX,(00000111b SHL 8)+MemoryMode
 OUT DX,AX      {d‚sactive le mode Odd/Even (pour lire les octets lin‚airement)}

 MOV DX,GraphControl
 MOV AX,(00000010b SHL 8)+ReadMapSelect
 OUT DX,AX      {indique le plan de bits #2}
 MOV AX,(00000000b SHL 8)+GraphicsMode
 OUT DX,AX      {d‚sactive le mode Odd/Even}
 MOV AX,(00000100b SHL 8)+Miscellaneous
 OUT DX,AX      {indique la taille de la RAM vid‚o en A000: 64ko (8 tables*256 car.*32 lignes)}

 STI
End; {AccedeCar}

{----------------------------------------------------------}

PROCEDURE AccedeMem; Assembler; {VGA}
{r‚tablit l'accŠs … la RAM vid‚o en B800:0000}
ASM
 CLI

 MOV DX,Sequencer
 MOV AX,(00000011b SHL 8)+MapMask
 OUT DX,AX      {r‚tablit l'accŠs aux plans de bits #0 et #1 (RAM vid‚o: code/attribut)}
 MOV AX,(00000011b SHL 8)+MemoryMode
 OUT DX,AX      {r‚active le mode Odd/Even (pour lire les octets en alternance)}

 MOV DX,GraphControl
 MOV AX,(00000000b SHL 8)+ReadMapSelect
 OUT DX,AX      {indique le plan de bits #0}
 MOV AX,(00010000b SHL 8)+GraphicsMode
 OUT DX,AX      {r‚active le mode Odd/Even}
 MOV AX,(00001110b SHL 8)+Miscellaneous
 OUT DX,AX      {indique la taille de la RAM vid‚o en B800: 32ko (8 pages*4000 octets)}

 STI
End; {AccedeMem}

{----------------------------------------------------------}

PROCEDURE MotifBinaire(table: Byte; caractere: Char; Var motif); Assembler; {VGA}
{renvoie dans le tampon 'motif' le motif binaire du caractŠre
 (compos‚ de hauteur_car octets, du haut vers le bas)  (0 ó table ó 7)}
ASM
 CALL AccedeCar

 PUSH DS
 CLD

 XOR SI,SI
 MOV BL,table
 TEST BL,00000100b  {table>3 ?}
 JZ  @suite         {non}
 MOV SI,2000h

@suite:
 AND BL,00000011b   {BL=(table Modulo 4)}

 MOV AL,4000h/256
 MUL BL             {AX=64*(table Modulo 4)}
 XCHG AH,AL         {AX=4000h*(table Modulo 4)}
 ADD SI,AX          {SI=offset du d‚but de la table}

 XOR AH,AH
 MOV AL,caractere
 MOV CL,5
 SHL AX,CL          {AX=32*code}
 ADD SI,AX          {SI=offset de la ligne 0 du caractŠre}

 XOR CH,CH
 MOV CL,hauteur_car
 SHR CX,1           {CX=hauteur_car/2}

 MOV AX,0A000h
 MOV DS,AX          {DS=A000: segment des tables de caractŠres}

 LES DI,motif
 REP MOVSW

 POP DS

 CALL AccedeMem
End; {MotifBinaire}

{----------------------------------------------------------}

PROCEDURE PointCar(caractere: Char; ligne,colonne: Byte; allume: Boolean); Assembler; {VGA}
{allume ou ‚teint un point dans la matrice du caractŠre (table nø0 seulement)
 0 ó ligne ó hauteur_car-1   et   0 ó colonne ó 7        25,28,50 lignes
 REMARQUE: ne fonctionne qu'aprŠs un appel … AccedeCar}
ASM
 MOV AX,0A000h
 MOV ES,AX          {ES=A000: segment des tables de caractŠres}

 MOV CL,colonne
 MOV BL,10000000b
 SHR BL,CL          {BL=80h SHR colonne: masque de bits pour l'‚criture}

 XOR AH,AH
 MOV AL,caractere
 MOV CL,5
 SHL AX,CL
 ADD AL,ligne       {AL=32*code_ascii+ligne}
 MOV DI,AX          {DI=offset ligne}
 MOV AL,ES:[DI]     {AL=motif binaire de la ligne}

 CMP allume,True
 JNE @eteint_point
 OR  AL,BL          {allume le point}
 JMP @ecrit_motif
@eteint_point:
 NOT BL
 AND AL,BL          {‚teint le point}
@ecrit_motif:
 MOV ES:[DI],AL     {‚crit le motif binaire de la ligne}
End; {PointCar}

{----------------------------------------------------------}

PROCEDURE LigneCar(caractere: Char; ligne: Byte; allume: Boolean); Assembler; {VGA}
{allume ou ‚teint une ligne dans la matrice du caractŠre (table nø0 seulement)
 0 ó ligne ó hauteur_car-1      25,28,50 lignes
 REMARQUE: ne fonctionne qu'aprŠs un appel … AccedeCar}
ASM
 MOV AX,0A000h
 MOV ES,AX          {ES=A000: segment des tables de caractŠres}

 XOR AH,AH
 MOV AL,caractere
 MOV CL,5
 SHL AX,CL
 ADD AL,ligne       {AL=32*code_ascii+ligne}
 MOV DI,AX          {DI=offset ligne}

 MOV AL,allume
 NEG AL             {AL=motif binaire d'une ligne: si allume=TRUE->FFh, sinon 00h}
 MOV ES:[DI],AL     {‚crit le motif binaire de la ligne}
End; {LigneCar}

{----------------------------------------------------------}

PROCEDURE ColonneCar(caractere: Char; colonne: Byte; allume: Boolean); Assembler; {VGA}
{allume ou ‚teint une colonne dans la matrice du caractŠre (table nø0 seulement)
 0 ó colonne ó 7        25,28,50 lignes
 REMARQUE: ne fonctionne qu'aprŠs un appel … AccedeCar}
ASM
 MOV AX,0A000h
 MOV ES,AX          {ES=A000: segment des tables de caractŠres}

 XOR AH,AH
 MOV AL,caractere
 MOV CL,5
 SHL AX,CL
 MOV DI,AX          {DI=32*code_ascii: offset ligne 0 du caractŠre}

 MOV CL,colonne
 MOV BL,10000000b
 SHR BL,CL          {BL=80h SHR colonne: masque de bits pour l'‚criture}

 CLD
 MOV CL,hauteur_car

 CMP allume,True
 JE  @allume_colonne

 NOT BL
@eteint_colonne:
 MOV AL,ES:[DI]     {AL=motif binaire de la ligne}
 AND AL,BL          {‚teint un point}
 STOSB              {‚crit le motif binaire de la ligne}
 DEC CL
 JNZ @eteint_colonne
 JMP @fin

@allume_colonne:
 MOV AL,ES:[DI]     {AL=motif binaire de la ligne}
 OR  AL,BL          {allume un point}
 STOSB              {‚crit le motif binaire de la ligne}
 DEC CL
 JNZ @allume_colonne

@fin:
End; {ColonneCar}

{----------------------------------------------------------}

PROCEDURE RedefCar(table: Byte; premier_car: Char; nombre: Word; Var motif; mode: Byte); {VGA}
{red‚finit 'nombre' caractŠres cons‚cutifs … partir de 'premier_car',
 (0 ó table ó 7) en utilisant des motifs cons‚cutifs:

 -si mode=ascii, chaque motif doit ˆtre de type Ascii__
                                                     À´
                                      'hauteur_car' ÄÄÙ
   Les caractŠres contenus dans le motif peuvent ˆtre:
     -un espace (#32) ou un Null (#0), si le point est ‚teint
     -un caractŠre>#32, si le point est allum‚

 -si mode=binaire, chaque motif doit ˆtre de type Binaire__
                                                         À´
                                          'hauteur_car' ÄÄÙ

 REMARQUE: En mode 9 pixels, pour les caractŠres dont le code ASCII est
           compris entre 192 (C0h) et 223 (DFh), la 8Šme colonne est copi‚e
           automatiquement dans la 9Šme}

Var motif_binaire: Array[Byte] of Binaire16; {256 caractŠres maxi}
    ptr_motif: Pointer;

Begin
 AccedeCar;
 If mode=ascii Then ptr_motif:=@motif_binaire Else ptr_motif:=@motif;
 ASM
  PUSH DS
  CLD

  CMP mode,ascii      {mode ASCII?}
  JNE @suite          {non, mode binaire -> pas de conversion de motif}

  MOV DH,Byte(nombre)
  MOV CH,hauteur_car
  LDS SI,motif        {DS:SI -> motif (ASCII)}
  LES DI,ptr_motif    {ES:DI -> motif_binaire}

 @boucle_caractere:
  @boucle_ligne:
   XOR DL,DL          {masque de bits=0}
   MOV CL,8           {CL=largeur du motif d'une ligne (8 bits)}
   @boucle_colonne:
    SHL DL,1          {d‚cale le masque de bits … gauche}
    LODSB             {charge un caractŠre du motif ASCII}
    CMP AL,' '        {espace ou inf‚rieur?}
    JBE @pas_point    {oui}
    OR  DL,00000001b  {met le bit 0 du masque … 1}
   @pas_point:
    DEC CL
    JNZ @boucle_colonne
   MOV AL,DL
   STOSB              {‚crit le masque dans motif_binaire}
   DEC CH
   JNZ @boucle_ligne
  DEC DH
  JNZ @boucle_caractere

 @suite:
  MOV AX,0A000h
  MOV ES,AX          {ES=A000: segment des tables de caractŠres}

  XOR DI,DI
  MOV BL,table
  TEST BL,00000100b  {table>3 ?}
  JZ  @suite2        {non}
  MOV DI,2000h

  @suite2:
  AND BL,00000011b   {BL=(table Modulo 4)}

  MOV AL,4000h/256
  MUL BL             {AX=64*(table Modulo 4)}
  XCHG AH,AL         {AX=4000h*(table Modulo 4)}
  ADD DI,AX          {DI=offset du d‚but de la table}

  XOR AH,AH
  MOV AL,premier_car
  MOV CL,5
  SHL AX,CL          {AX=32*premier_code}
  ADD DI,AX          {DI=offset de la ligne 0 du premier caractŠre}

  XOR AH,AH
  MOV AL,hauteur_car
  SHR AX,1           {AX=hauteur_car/2}

  MOV DX,32
  SUB DL,hauteur_car {DX=32-hauteur_car: incr‚ment DI}

  LDS SI,ptr_motif

  MOV BX,nombre
 @boucle_redef:
  MOV CX,AX
  REP MOVSW          {red‚finit un caractŠre}
  ADD DI,DX          {DI=offset de la ligne 0 du caractŠre suivant}
  DEC BX
  JNZ @boucle_redef

  POP DS
 End;
 AccedeMem
End; {RedefCar}

{----------------------------------------------------------}

PROCEDURE ChargeFonte(table: Byte; Var buffer); Assembler; {VGA}
{charge le motif des 256 caractŠres dans un tampon}
ASM
 CALL AccedeCar

 MOV CH,hauteur_car

 PUSH DS
 CLD

 MOV AX,0A000h
 MOV DS,AX          {DS=A000: segment des tables de caractŠres}

 XOR SI,SI
 MOV BL,table
 TEST BL,00000100b  {table>3 ?}
 JZ  @suite         {non}
 MOV SI,2000h

@suite:
 AND BL,00000011b   {BL=(table Modulo 4)}

 MOV AL,4000h/256
 MUL BL             {AX=64*(table Modulo 4)}
 XCHG AH,AL         {AX=4000h*(table Modulo 4)}
 ADD SI,AX          {SI=offset de la ligne 0 du caractŠre 0}

 XOR AH,AH
 MOV AL,CH
 SHR AX,1           {AX=hauteur_car/2}

 MOV DX,32
 SUB DL,CH          {DX=32-hauteur_car: incr‚ment SI}

 LES DI,buffer

 MOV BX,256
@boucle_charge:
 MOV CX,AX
 REP MOVSW          {red‚finit un caractŠre}
 ADD SI,DX          {SI=offset de la ligne 0 du caractŠre suivant}
 DEC BX
 JNZ @boucle_charge

 POP DS

 CALL AccedeMem
End; {ChargeFonte}

{----------------------------------------------------------}

PROCEDURE RedefFonte(table: Byte; Var buffer); Assembler; {VGA}
{red‚finit le motif des 256 caractŠres depuis un tampon}
ASM
 CALL AccedeCar

 PUSH DS
 CLD

 MOV AX,0A000h
 MOV ES,AX          {ES=A000: segment des tables de caractŠres}

 XOR DI,DI
 MOV BL,table
 TEST BL,00000100b  {table>3 ?}
 JZ  @suite         {non}
 MOV DI,2000h

@suite:
 AND BL,00000011b   {BL=(table Modulo 4)}

 MOV AL,4000h/256
 MUL BL             {AX=64*(table Modulo 4)}
 XCHG AH,AL         {AX=4000h*(table Modulo 4)}
 ADD DI,AX          {DI=offset de la ligne 0 du caractŠre 0}

 XOR AH,AH
 MOV AL,hauteur_car
 SHR AX,1           {AX=hauteur_car/2}

 MOV DX,32
 SUB DL,hauteur_car {DX=32-hauteur_car: incr‚ment DI}

 LDS SI,buffer

 MOV BX,256
@boucle_charge:
 MOV CX,AX
 REP MOVSW          {red‚finit un caractŠre}
 ADD DI,DX          {DI=offset de la ligne 0 du caractŠre suivant}
 DEC BX
 JNZ @boucle_charge

 POP DS

 CALL AccedeMem
End; {RedefFonte}

{----------------------------------------------------------}

PROCEDURE ChargeFonte_(nom_fichier: String80; hauteur: Byte; Var buffer; Var erreur: Word); {VGA}
{charge la fonte de 256 caractŠres (16,14 ou 8 pixels) depuis le disque}
Var f: Fichier;
Begin
 With f do
  Begin
   Ouvre(lecture,nom_fichier);
   If f_erreur=f_ok Then
    Begin
     erreur:=0;
     If (Taille=256*hauteur) Then LitPos(0,buffer,256*hauteur) Else erreur:=err_format;
     Ferme;
     If erreur=err_format Then Exit
    End
  End;
 erreur:=f_erreur
End; {ChargeFonte_}

{----------------------------------------------------------}

PROCEDURE SauveFonte_(nom_fichier: String80; hauteur: Byte; Var buffer; Var erreur: Word); {VGA}
{sauve la fonte de 256 caractŠres (16,14 ou 8 pixels) sur disque}
Var f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),nom_fichier);
   If f_erreur=f_ok Then Begin Ecrit(buffer,256*hauteur); Ferme End
  End;
 erreur:=f_erreur
End; {SauveFonte_}

{----------------------------------------------------------}

PROCEDURE Fonte16.Charge(table: Byte); {VGA}
Begin
 ChargeFonte(table,fonte)
End; {Fonte16.Charge}

PROCEDURE Fonte16.Redef(table: Byte); {VGA}
Begin
 RedefFonte(table,fonte)
End; {Fonte16.Redef}

PROCEDURE Fonte16.Charge_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 ChargeFonte_(nom_fichier,16,fonte,erreur)
End; {Fonte16.Charge_}

PROCEDURE Fonte16.Sauve_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 SauveFonte_(nom_fichier,16,fonte,erreur)
End; {Fonte16.Sauve_}

{----------------------------------------------------------}

PROCEDURE Fonte14.Charge(table: Byte); {VGA}
Begin
 ChargeFonte(table,fonte)
End; {Fonte14.Charge}

PROCEDURE Fonte14.Redef(table: Byte); {VGA}
Begin
 RedefFonte(table,fonte)
End; {Fonte14.Redef}

PROCEDURE Fonte14.Charge_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 ChargeFonte_(nom_fichier,14,fonte,erreur)
End; {Fonte14.Charge_}

PROCEDURE Fonte14.Sauve_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 SauveFonte_(nom_fichier,14,fonte,erreur)
End; {Fonte14.Sauve_}

{----------------------------------------------------------}

PROCEDURE Fonte8.Charge(table: Byte); {VGA}
Begin
 ChargeFonte(table,fonte)
End; {Fonte8.Charge}

PROCEDURE Fonte8.Redef(table: Byte); {VGA}
Begin
 RedefFonte(table,fonte)
End; {Fonte8.Redef}

PROCEDURE Fonte8.Charge_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 ChargeFonte_(nom_fichier,8,fonte,erreur)
End; {Fonte8.Charge_}

PROCEDURE Fonte8.Sauve_(nom_fichier: String80; Var erreur: Word); {VGA}
Begin
 SauveFonte_(nom_fichier,8,fonte,erreur)
End; {Fonte8.Sauve_}

{----------------------------------------------------------}

PROCEDURE ScrolleVertical(ligne: Byte); Assembler; {VGA}
{place l'adresse de base de la RAM vid‚o sur la 1Šre colonne de la ligne}
ASM
 CLI
 MOV DX,CRTControl
 XOR AH,AH
 MOV AL,largeur_ecran_txt
 XOR BH,BH
 MOV BL,ligne
 DEC BL
 MUL BL              {AX=largeur_ecran_txt*(ligne-1)}
 MOV BL,AL
 MOV AL,StartAddrHigh
 OUT DX,AX           {‚crit poids fort d‚calage}
 MOV AH,BL
 MOV AL,StartAddrLow
 OUT DX,AX           {‚crit poids faible d‚calage}
 STI
End; {ScrolleVertical}

{----------------------------------------------------------}

PROCEDURE ScrolleHorizontal(colonne: Byte); Assembler; {VGA}
{place l'adresse de base de la RAM vid‚o sur la colonne de la 1Šre ligne}
ASM
 CLI
 MOV DX,CRTControl
 MOV AL,StartAddrHigh
 MOV AH,0           {poids fort d‚calage}
 OUT DX,AX
 MOV AL,StartAddrLow
 MOV AH,colonne
 DEC AH             {poids faible d‚calage}
 OUT DX,AX
 STI
End; {ScrolleHorizontal}

{----------------------------------------------------------}

PROCEDURE PlaceEcran(xg,yh: Word); Assembler; {VGA}
{place l'adresse de base de la RAM vid‚o sur (xg,yh) - en pixels -
 (0,0): adresse normale
 Pour se d‚placer d'un caractŠre horizontalement, ajouter ñlargeur_car … xg
 Pour se d‚placer d'un caractŠre verticalement, ajouter ñhauteur_car … yh}
ASM
 CLI                 {‚vite les 'sauts' si une touche est appuy‚e, par ex.}
 CALL AttendVBL
 CALL AttendFinHBL

 MOV AX,yh
 MOV CH,hauteur_car
 DIV CH              {AL=yh/hauteur_car, AH=yh Modulo hauteur_car}

 MOV CH,AH           {CH=yh Modulo hauteur_car}

 MUL largeur_ecran_txt  {AX=largeur_ecran_txt*(yh/hauteur_car)}
 MOV BX,AX
 MOV AX,xg
 MOV CL,largeur_car
 DIV CL              {AL=xg/largeur_car, AH=xg Modulo largeur_car}

 MOV CL,AH           {CL=xg Modulo largeur_car}

 XOR AH,AH
 ADD AX,BX           {AX=(xg/largeur_car)+largeur_ecran_txt*(yh/hauteur_car)}
 MOV BL,AL

 MOV DX,CRTControl
 MOV AL,StartAddrHigh
 OUT DX,AX           {‚crit poids fort d‚calage}
 MOV AH,BL
 MOV AL,StartAddrLow
 OUT DX,AX           {‚crit poids faible d‚calage}

 MOV DX,CRTControl
 MOV AH,CH           {AH=yh Modulo hauteur_car: d‚calage vertical}
 MOV AL,VPelPanning
 OUT DX,AX           {fait un smooth vertical}

 MOV DX,AttrControl
 MOV AL,HPelPanning OR 00100000b   {bit 5 … 1 sinon ‚cran noir!}
 OUT DX,AL

 MOV AL,CL           {AL=xg Modulo largeur_car: d‚calage horizontal}
 OR  AL,AL
 JNZ @pas_nul
 MOV AL,8+1
@pas_nul:
 DEC AL
 OUT DX,AL           {fait un smooth horizontal}

 STI                 {autorise les interruptions}
End; {PlaceEcran}

{----------------------------------------------------------}

PROCEDURE CursXY(page,x,y: Byte); Assembler;
{‚quivalent de GotoXY multi-page en mode 25,28,50 lignes}
ASM
 MOV AH,2
 MOV BH,page
 MOV DH,y
 DEC DH
 MOV DL,x
 DEC DL
 INT 10h
End; {CursXY}

{----------------------------------------------------------}

FUNCTION PosX(page: Byte): Byte; Assembler;
{renvoie l'abscisse du curseur clignotant dans la page}
ASM
 MOV AH,3
 MOV BH,page
 INT 10h
 INC DL
 MOV AL,DL
End; {PosX}

{----------------------------------------------------------}

FUNCTION PosY(page: Byte): Byte; Assembler;
{renvoie l'ordonn‚e du curseur clignotant dans la page}
ASM
 MOV AH,3
 MOV BH,page
 INT 10h
 INC DH
 MOV AL,DH
End; {PosY}

{----------------------------------------------------------}

FUNCTION PtrVRAM(page,x,y: Byte): WordPtr; Assembler;
{renvoie un pointeur sur la m‚moire vid‚o en (x,y)}
ASM
 XOR AH,AH
 MOV AL,page
 MUL delta_segment_VRAM
 ADD AX,0B800h
 MOV ES,AX           {ES=B800+delta_segment_VRAM*page}

 XOR AH,AH
 MOV AL,x
 MOV BX,AX
 DEC BX              {BX=x-1}
 MOV AL,y
 DEC AL
 MUL largeur_ecran_txt  {AX=largeur_ecran_txt*(y-1)}
 ADD AX,BX
 SHL AX,1            {AX=2*((x-1)+largeur_ecran_txt*(y-1))}
 MOV DX,ES
End; {PtrVRAM}

{----------------------------------------------------------}

PROCEDURE AffCarXY(page,x,y: Byte; caractere: Char; attr: Byte);
{affiche un caractŠre en (x,y)}
Var ptr_VRAM: Pointer;
Begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 ASM
  LES DI,ptr_VRAM
  MOV AH,attr
  MOV AL,caractere
  MOV ES:[DI],AX
 End
End; {AffCarXY}

{----------------------------------------------------------}

PROCEDURE AffChXY(page,x,y: Byte; chaine: String; attr: Byte);
{affiche une chaŒne en (x,y)}
Var ptr_VRAM: Pointer;
Begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 ASM
  PUSH DS
  CLD

  LES DI,ptr_VRAM
  PUSH SS
  POP DS
  LEA SI,chaine
  LODSB               {AL=longueur chaŒne}
  OR  AL,AL
  JZ  @fin            {chaŒne vide}
  MOV AH,attr
  MOV BL,AL

 @affiche_car:
  LODSB               {AL=code ASCII}
  STOSW               {affiche un caractŠre}
  DEC BL
  JNZ @affiche_car

 @fin:
  POP DS
 End
End; {AffChXY}

{----------------------------------------------------------}

PROCEDURE AffChXY2(page,x,y: Byte; chaine: String; attr_ext,attr_int: Byte);
{affiche une chaŒne avec l'attribut 'attr_ext', sauf les portions de chaŒne
 d‚limit‚es par des '^' qui sont affich‚es avec l'attribut 'attr_int'}
Var ptr_VRAM: Pointer;
Begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 ASM
  PUSH DS
  CLD

  LES DI,ptr_VRAM
  PUSH SS
  POP DS
  LEA SI,chaine
  LODSB               {AL=longueur chaŒne}
  OR  AL,AL
  JZ  @fin            {chaŒne vide}

  MOV AH,attr_ext     {AH=attribut couleur par d‚faut}
  MOV BH,attr_int     {BH=attribut 2Šme couleur}
  MOV BL,AL

 @affiche_car:
  LODSB               {AL=code ASCII}
  CMP AL,'^'          {caractŠre de contr“le '^' ?}
  JE  @echange_attr   {oui}
  STOSW               {affiche un caractŠre}
  JMP @suite
 @echange_attr:
  XCHG AH,BH          {‚change attr_ext et attr_int}
 @suite:
  DEC BL
  JNZ @affiche_car

 @fin:
  POP DS
 End
End; {AffChXY2}

{----------------------------------------------------------}

PROCEDURE AffChXYmc(page,x,y: Byte; chaine: String);
{affiche une chaŒne avec plusieurs attributs de couleur, selon le format:
  caractŠre de contr“le: '^', suivi par la valeur de l'attribut: 0..255 }
Var ptr_VRAM: Pointer;
Begin
 ptr_VRAM:=PtrVRAM(page,x,y);
 ASM
  PUSH DS
  CLD

  LES DI,ptr_VRAM
  PUSH SS
  POP DS
  LEA SI,chaine
  LODSB               {AL=longueur chaŒne}
  OR  AL,AL
  JZ  @fin            {chaŒne vide}

  MOV BL,AL

 @affiche_chaine:
  LODSB               {AL=code ASCII}
  CMP AL,'^'
  JNE @affiche_car
  DEC BL
  LODSB               {AL=attribut}
  MOV AH,AL
  JMP @suite
 @affiche_car:
  STOSW
 @suite:
  DEC BL
  JNZ @affiche_chaine

 @fin:
  POP DS
 End
End; {AffChXYmc}

{----------------------------------------------------------}

PROCEDURE AffCar(caractere: Char); Assembler;
{affiche un caractŠre … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis incr‚mente la position courante}
ASM
 LES DI,AdrTexte
 MOV AH,AttrTexte
 MOV AL,caractere
 MOV ES:[DI],AX
 ADD WORD(AdrTexte),2
End; {AffCar}

{----------------------------------------------------------}

PROCEDURE AffCh(chaine: String); Assembler;
{affiche une chaŒne … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis d‚place la position courante … la fin de la chaŒne}
ASM
 PUSH DS
 CLD

 LES DI,AdrTexte
 MOV AH,AttrTexte
 LDS SI,chaine
 LODSB               {AL=longueur chaŒne}
 XOR DH,DH
 MOV DL,AL
 SHL DX,1
 JZ  @fin            {chaŒne vide}
 MOV BL,AL

@affiche_car:
 LODSB               {AL=code ASCII}
 STOSW               {affiche un caractŠre}
 DEC BL
 JNZ @affiche_car

@fin:
 POP DS

 ADD WORD(AdrTexte),DX
End; {AffCh}

{----------------------------------------------------------}

PROCEDURE AffChE(chaine: String; caractere: Char; longueur: Byte); Assembler;
{affiche une chaŒne … la position courante (AdrTexte) et avec l'attribut courant (AttrTexte)
 puis d‚place la position courante … la fin de la chaŒne
 l'affichage est limit‚ … 'longueur' caractŠres: si la chaŒne est plus
 courte, l'affichage est compl‚t‚ par 'caractere'

 c'est un raccourci pour AffCh(XString(chaine,caractere,longueur))}
ASM
 PUSH DS
 CLD

 LES DI,AdrTexte
 MOV AH,AttrTexte
 LDS SI,chaine
 LODSB              {AL=longueur chaŒne}
 MOV BL,AL
 MOV DL,longueur
 MOV CL,DL
 SUB CL,AL
 JNS @affiche_ch

 MOV BL,DL
 XOR CL,CL

@affiche_ch:
 OR  BL,BL
 JZ  @suite

@affiche_car:
 LODSB
 STOSW
 DEC BL
 JNZ @affiche_car

@suite:
 XOR CH,CH
 MOV AL,caractere
 REP STOSW

 POP DS

 XOR DH,DH
 SHL DX,1
 ADD WORD(AdrTexte),DX
End; {AffChE}

{----------------------------------------------------------}

PROCEDURE LigneHorizontale(page,epaisseur,y,xg,xd,attr: Byte);
Var ptr_VRAM: Pointer;
Begin
 If xd<xg Then Exit;

 ptr_VRAM:=PtrVRAM(page,xg,y);
 ASM
  LES DI,ptr_VRAM
  MOV AH,attr
  MOV AL,'Ä'        {par d‚faut, ‚paisseur=1}
  CMP epaisseur,1
  JE  @suite
  MOV AL,'Í'
 @suite:
  XOR CH,CH
  MOV CL,xd
  SUB CL,xg
  INC CL            {CX=xd-xg+1}
  CLD
  REP STOSW         {affiche ligne}
 End
End; {LigneHorizontale}

{----------------------------------------------------------}

PROCEDURE LigneVerticale(page,epaisseur,x,yh,yb,attr: Byte);
Var ptr_VRAM: Pointer;
Begin
 If yb<yh Then Exit;

 ptr_VRAM:=PtrVRAM(page,x,yh);
 ASM
  LES DI,ptr_VRAM
  XOR DH,DH
  MOV DL,largeur_ecran_txt
  DEC DL
  SHL DX,1            {incr‚ment DI: DX=2*(largeur_ecran_txt-1)}
  MOV AH,attr
  MOV AL,'³'          {par d‚faut, ‚paisseur=1}
  CMP epaisseur,1
  JE  @suite
  MOV AL,'º'
 @suite:
  MOV CL,yb
  SUB CL,yh
  INC CL              {CL=yb-yh+1}
  CLD
 @affiche_ligne:
  STOSW
  ADD DI,DX
  DEC CL
  JNZ @affiche_ligne
 End
End; {LigneVerticale}

{----------------------------------------------------------}

PROCEDURE Cadre(page,epaisseur,xg,yh,xd,yb,attr: Byte; titre: String; attr_titre: Byte; touches: String25);
{trace un cadre de coordonn‚es (xg,yh,xd,yb), d'‚paisseur 1 ou 2, avec la couleur 'attr'
 -le titre est centr‚ en haut du cadre, affich‚ avec la couleur 'attr_titre'
 -la chaŒne 'touches' est affich‚e dans le coin inf‚rieur droit du cadre}

Const coin1: Array[1..2] of Char=('Ú','É');
      coin2: Array[1..2] of Char=('¿','»');
      coin3: Array[1..2] of Char=('À','È');
      coin4: Array[1..2] of Char=('Ù','¼');
      horiz: Array[1..2] of Char=('Ä','Í');

Var n: Byte;

Begin
 If xg>xd Then Begin n:=xg; xg:=xd; xd:=n End;
 If yh>yb Then Begin n:=yh; yh:=yb; yb:=n End;
 If (xd>xg) and (yb>yh) Then
  Begin
   n:=(xd-xg-1)-Length(titre);
   AffCarXY(page,xg,yh,coin1[epaisseur],attr);
   LigneHorizontale(page,epaisseur,yh,xg+1,xg+(n SHR 1),attr);
   LigneHorizontale(page,epaisseur,yh,xd-n+(n SHR 1),xd-n-1+(n AND $FE),attr);
   If Odd(n) Then AffChXY (page,xd-n+(n AND $FE),yh,horiz[epaisseur]+coin2[epaisseur],attr)
             Else AffCarXY(page,xd-n+(n AND $FE),yh,coin2[epaisseur],attr);
   LigneVerticale(page,epaisseur,xg,yh+1,yb-1,attr);
   LigneVerticale(page,epaisseur,xd,yh+1,yb-1,attr);
   AffCarXY(page,xg,yb,coin3[epaisseur],attr);
   LigneHorizontale(page,epaisseur,yb,xg+1,xd-1,attr);
   AffCarXY(page,xd,yb,coin4[epaisseur],attr);
   AffChXY(page,xg+(n SHR 1)+1,yh,titre,attr_titre);
   AffChXY(page,xd-1-Length(touches),yb,touches,attr)
  End
 Else
  If xg=xd Then LigneVerticale(page,epaisseur,xg,yh,yb,attr)
  Else
   If yh=yb Then LigneHorizontale(page,epaisseur,yh,xg,xd,attr)
End; {Cadre}

{----------------------------------------------------------}

FUNCTION CodeXY(page,x,y: Byte): Byte;
{renvoie le code ASCII du caractŠre en (x,y)}
Begin
 CodeXY:=BytePtr(PtrVRAM(page,x,y))^
End; {CodeXY}

{----------------------------------------------------------}

FUNCTION AttrXY(page,x,y: Byte): Byte;
{renvoie l'attribut du caractŠre en (x,y)}
Begin
 AttrXY:=Hi(WordPtr(PtrVRAM(page,x,y))^)
End; {AttrXY}

{----------------------------------------------------------}

PROCEDURE Transfert(sens: Shortint;
                    source: Pointer; delta_source: Integer;
                    destination: Pointer; delta_dest: Integer; Ncol,Nlig: Byte); Assembler;
ASM
 PUSH DS
 CLD
 CMP sens,+1
 JE  @suite    {croissant}
 STD
@suite:
 LDS SI,source
 LES DI,destination
 MOV AX,delta_source
 MOV DX,delta_dest
 MOV BL,Ncol
 MOV BH,Nlig
 XOR CH,CH
@copie:
 MOV CL,BL
 REP MOVSW
 ADD SI,AX
 ADD DI,DX
 DEC BH
 JNZ @copie
 POP DS
End; {Transfert}

{----------------------------------------------------------}

PROCEDURE Zone.Sauve(page: Byte; xg,yh,xd,yb: Integer);
{sauve une zone de l'‚cran (les coordonn‚es peuvent sortir des limites)}
Var L,H,Ncol,Nlig: Byte;
    xg_zone,yh_zone,xd_zone,yb_zone: Integer;
    DI: Word;
Begin
 If (xd<xg) or (yb<yh) Then Begin taille_octets:=0; Exit End;

 L:=xd-xg+1; H:=yb-yh+1; taille_octets:=2*L*H;
 xg_:=xg; yh_:=yh; xd_:=xd; yb_:=yb;
 GetMem(contenu,taille_octets);
 xg_zone:=MaxEntier(1,xg); xd_zone:=MinEntier(largeur_ecran_txt,xd);
 yh_zone:=MaxEntier(1,yh); yb_zone:=MinEntier(hauteur_ecran_txt,yb);
 If (xd_zone<xg_zone) or (yb_zone<yh_zone) Then Exit; {zone hors ‚cran}

 Ncol:=xd_zone-xg_zone+1; Nlig:=yb_zone-yh_zone+1;
 DI:=0;
 If yh<1 Then Inc(DI,2*(1-yh)*L);
 If xg<1 Then Inc(DI,2*(1-xg));
 Transfert(+1,PtrVRAM(page,xg_zone,yh_zone),2*(largeur_ecran_txt-Ncol),AddPtr(contenu,DI),2*(L-Ncol),Ncol,Nlig)
End; {Zone.Sauve}

{----------------------------------------------------------}

PROCEDURE Zone.Ombre(page: Byte; xg,yh,xd,yb: Integer; attr: Byte);
{sauve une zone et affiche un rectangle d'attribut 'attr' avec une ombre sur
 les bords gauche et inf‚rieur}
Var ombre_horiz,ombre_vertic: Zone;
Begin
 Zone.Sauve(page,xg,yh,xd+2,yb+1);
 With ombre_horiz do
  Begin Sauve(page,xg+2,yb+1,xd+2,yb+1); Restaure(page,0,0,8); Supprime End;
 With ombre_vertic do
  Begin Sauve(page,xd+1,yh+1,xd+2,yb); Restaure(page,0,0,8); Supprime End;
 EffaceZone(page,MaxEntier(1,xg),MaxEntier(1,yh),
                 MinEntier(largeur_ecran_txt,xd),MinEntier(hauteur_ecran_txt,yb),attr)
End; {Zone.Ombre}

{----------------------------------------------------------}

PROCEDURE Zone.RestaureLimite(page: Byte; x,y: Integer; xg,yh,xd,yb: Byte);
{affiche la zone en (x,y) dans les limites de la fenˆtre (xg,yh,xd,yb)}
Var L,H,Ncol,Nlig: Byte;
    xg_zone,yh_zone,xd_zone,yb_zone: Integer;
    SI: Word;
Begin
 L:=xd_-xg_+1; H:=yb_-yh_+1;
 xg_zone:=MaxEntier(xg,x); xd_zone:=MinEntier(xd,x+L-1);
 yh_zone:=MaxEntier(yh,y); yb_zone:=MinEntier(yb,y+H-1);
 If (xd_zone<xg_zone) or (yb_zone<yh_zone) Then Exit; {zone hors ‚cran}

 Ncol:=xd_zone-xg_zone+1; Nlig:=yb_zone-yh_zone+1;
 SI:=0;
 If y<yh Then Inc(SI,2*(yh-y)*L);
 If x<xg Then Inc(SI,2*(xg-x));
 Transfert(+1,AddPtr(contenu,SI),2*(L-Ncol),PtrVRAM(page,xg_zone,yh_zone),2*(largeur_ecran_txt-Ncol),Ncol,Nlig)
End; {Zone.RestaureLimite}

{----------------------------------------------------------}

PROCEDURE Zone.Restaure(page: Byte; dx,dy: Shortint; attr: Byte);
{restaure la zone avec un d‚placement ‚ventuel (dx,dy)
 -si attr=0, les couleurs d'origine sont conserv‚es
 -sinon, la zone est restaur‚e avec l'attribut 'attr'}
Var ptr_contenu: Pointer;
    taille_octets_: Word;
Begin
 If taille_octets=0 Then Exit;

 If attr<>0 Then
  Begin
   ptr_contenu:=contenu; taille_octets_:=taille_octets;
   ASM
    LES DI,ptr_contenu
    INC DI              {ES:DI -> premier attribut … changer}
    CLD
    MOV CX,taille_octets_
    SHR CX,1            {CX=nombre caractŠres}
    MOV AL,attr
   @ecrit_attr:
    STOSB               {‚crit attribut}
    INC DI              {saute code ASCII}
    DEC CX
    JNZ @ecrit_attr
   End
  End;
 Zone.RestaureLimite(page,xg_+dx,yh_+dy,1,1,largeur_ecran_txt,hauteur_ecran_txt)
End; {Zone.Restaure}

{----------------------------------------------------------}

PROCEDURE Zone.DeplaceLimite(page: Byte; dx,dy: Shortint; Var zone_cachee: Zone; xg,yh,xd,yb: Byte);
{d‚place une zone sur l'‚cran dans les limites (xg,yh,xd,yb) et modifie ses
 coordonn‚es; zone_cachee doit d‚j… contenir le fond reconvert}
Begin
 With zone_cachee do
  Begin RestaureLimite(page,xg_,yh_,xg,yh,xd,yb); Supprime; Sauve(page,xg_+dx,yh_+dy,xd_+dx,yb_+dy) End;
 Inc(xg_,dx); Inc(xd_,dx); Inc(yh_,dy); Inc(yb_,dy);
 Zone.RestaureLimite(page,xg_,yh_,xg,yh,xd,yb)
End; {Zone.DeplaceLimite}

{----------------------------------------------------------}

PROCEDURE Zone.Deplace(page: Byte; dx,dy: Shortint; Var zone_cachee: Zone);
{d‚place une zone dans les limites de l'‚cran et modifie ses coordonn‚es;
 zone_cachee doit d‚j… contenir le fond reconvert}
Var SI,DI: Word;
    L,H,LI,HI,x,y: Byte;
    sens_copie: Shortint;
    ptr_contenu: Pointer;
    delta_L,delta_dx,delta_copie: Integer;
Begin
 L:=xd_-xg_+1; H:=yb_-yh_+1;

 If (Abs(dx)<L) and (Abs(dy)<H) Then  {intersection}
  Begin
   LI:=L-Abs(dx); HI:=H-Abs(dy);
   ptr_contenu:=zone_cachee.contenu;

   {restaure}
   If dy<>0 Then
    Begin
     SI:=0; delta_L:=2*(largeur_ecran_txt-L);
     If dy>0 Then Begin y:=yh_ End Else Begin Inc(SI,2*HI*L); y:=yb_+dy+1 End;
     Transfert(+1,AddPtr(ptr_contenu,SI),0,PtrVRAM(page,xg_,y),delta_L,L,Abs(dy))
    End;
   If dx<>0 Then
    Begin
     SI:=0; y:=yh_; delta_dx:=2*(largeur_ecran_txt-Abs(dx));
     If dx>0 Then x:=xg_ Else Begin x:=xd_+dx+1; Inc(SI,2*LI) End;
     If dy>0 Then Begin Inc(SI,2*L*dy); Inc(y,dy) End;
     Transfert(+1,AddPtr(ptr_contenu,SI),2*LI,PtrVRAM(page,x,y),delta_dx,Abs(dx),HI)
    End;

   {copie}
   If dy=0 Then sens_copie:=Sgn(dx) Else sens_copie:=Sgn(dy);
   If dx*dy>=0 Then Begin SI:=2*dx; DI:=0 End Else Begin SI:=0; DI:=-2*dx End;
   If dy<>0 Then Inc(SI,2*L*dy);
   If sens_copie=-1 Then Begin Inc(SI,taille_octets-2); Inc(DI,taille_octets-2) End;
   delta_copie:=2*Abs(dx)*sens_copie;
   Transfert(sens_copie,AddPtr(ptr_contenu,SI),delta_copie,AddPtr(ptr_contenu,DI),delta_copie,LI,HI);

   {sauve}
   If dy<>0 Then
    Begin
     If dy>0 Then Begin DI:=2*HI*L; y:=yb_+1 End Else Begin DI:=0; y:=yh_+dy End;
     Transfert(+1,PtrVRAM(page,xg_+dx,y),delta_L,AddPtr(ptr_contenu,DI),0,L,Abs(dy))
    End;
   If dx<>0 Then
    Begin
     DI:=0; y:=yh_;
     If dx>0 Then Begin x:=xd_+1; Inc(DI,2*LI) End Else x:=xg_+dx;
     If dy<0 Then Inc(DI,-2*L*dy) Else Inc(y,dy);
     Transfert(+1,PtrVRAM(page,x,y),delta_dx,AddPtr(ptr_contenu,DI),2*LI,Abs(dx),HI)
    End;

  With zone_cachee do
   Begin Inc(xg_,dx); Inc(xd_,dx); Inc(yh_,dy); Inc(yb_,dy) End
  End
 Else  {pas d'intersection}
  With zone_cachee do
   Begin Restaure(page,0,0,0); Supprime; Sauve(page,xg_+dx,yh_+dy,xd_+dx,yb_+dy) End;
 Inc(xg_,dx); Inc(xd_,dx); Inc(yh_,dy); Inc(yb_,dy);
 Zone.Restaure(page,0,0,0)
End; {Zone.Deplace}

{----------------------------------------------------------}

PROCEDURE Zone.Supprime;
Begin
 If taille_octets>0 Then FreeMem(contenu,taille_octets)
End; {Zone.Supprime}

{----------------------------------------------------------}

PROCEDURE Zone.Charge_(nom_fichier: String80; Var erreur: Word);
Var f: Fichier;
Begin
 With f do
  Begin
   Ouvre(lecture,nom_fichier);
   If f_erreur=f_ok Then
    Begin
     erreur:=0;
     Lit(xg_,2); Lit(yh_,2); Lit(xd_,2); Lit(yb_,2);
     taille_octets:=2*(xd_-xg_+1)*(yb_-yh_+1);
     If (2*4+taille_octets<>Taille) or
        (xg_>xd_) or (yh_>yb_) or
        (xd_>largeur_ecran_max) or (yb_>hauteur_ecran_max) Then erreur:=err_format
     Else
      Begin
       GetMem(contenu,taille_octets);
       LitPos(2*4,contenu^,taille_octets)
      End;
     Ferme;
     If erreur=err_format Then Exit
    End
  End;
 erreur:=f_erreur
End; {Zone.Charge_}

{----------------------------------------------------------}

PROCEDURE Zone.Sauve_(nom_fichier: String80; Var erreur: Word);
Var f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),nom_fichier);
   If f_erreur=f_ok Then
    Begin
     Ecrit(xg_,2); Ecrit(yh_,2); Ecrit(xd_,2); Ecrit(yb_,2); {entˆte}
     Ecrit(contenu^,taille_octets);
     Ferme
    End
  End;
 erreur:=f_erreur
End; {Zone.Sauve_}

{----------------------------------------------------------}

PROCEDURE Ecran.Sauve(page: Byte);
{sauve la page dans un ‚cran (25,28,50 lignes) SANS COLONNES VIRTUELLES (80!)}
Begin
 New(contenu);
 Transfert(+1,PtrVRAM(page,1,1),0,contenu,0,largeur_ecran_txt,hauteur_ecran_txt)
End; {Ecran.Sauve}

{----------------------------------------------------------}

PROCEDURE Ecran.Restaure(page: Byte);
{restaure l'‚cran sur une page SANS COLONNES VIRTUELLES (80!)}
Begin
 Transfert(+1,contenu,0,PtrVRAM(page,1,1),0,largeur_ecran_txt,hauteur_ecran_txt)
End; {Ecran.Restaure}

{----------------------------------------------------------}

PROCEDURE Ecran.Supprime;
Begin
 Dispose(contenu)
End; {Ecran.Supprime}

{----------------------------------------------------------}

PROCEDURE EffaceZone(page,xg,yh,xd,yb,attr: Byte);
Var ptr_VRAM: Pointer;
Begin
 If (xd<xg) or (yb<yh) Then Exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 ASM
  LES DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}

  MOV BH,yb
  SUB BH,yh
  INC BH              {BH=yb-yh+1: nombre de lignes}
  MOV BL,xd
  SUB BL,xg
  INC BL              {BL=xd-xg+1: nombre de colonnes}

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  SUB DL,BL
  SHL DX,1            {incr‚ment DI: DX=2*(largeur_ecran_txt-nombre colonnes)}

  MOV AH,attr
  MOV AL,' '

  CLD
  XOR CH,CH
 @efface_ligne:
  MOV CL,BL           {CX=nombre de colonnes}
  REP STOSW           {efface une ligne}
  ADD DI,DX
  DEC BH
  JNZ @efface_ligne
 End
End; {EffaceZone}

{----------------------------------------------------------}

PROCEDURE EffacePage(page,attr: Byte);
Begin
 EffaceZone(page,1,1,largeur_ecran_txt,hauteur_ecran_txt,attr)
End; {EffacePage}

{----------------------------------------------------------}

PROCEDURE ChangePage(page: Byte); Assembler;
{change la page visible courante SANS COLONNES VIRTUELLES (80!)}
ASM
 MOV AH,5
 MOV AL,page
 INT 10h
End; {ChangePage}

{----------------------------------------------------------}

PROCEDURE CopiePage(page_source,page_dest: Byte);
Begin
 Transfert(+1,PtrVRAM(page_source,1,1),0,PtrVRAM(page_dest,1,1),0,largeur_ecran_txt,hauteur_ecran_txt)
End; {CopiePage}

{----------------------------------------------------------}

PROCEDURE ScrolleZoneHaut(page,xg,yh,xd,yb: Byte);
Var ptr_VRAM: Pointer;
Begin
 If (xd<xg) or (yb<=yh) Then Exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 ASM
  PUSH DS
  CLD

  LES DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}
  XOR AH,AH
  MOV AL,largeur_ecran_txt
  MOV SI,AX
  SHL SI,1
  ADD SI,DI           {SI=DI+2*largeur_ecran_txt: source=ligne du dessous}

  MOV BH,yb
  SUB BH,yh           {BH=yb-yh: nombre de lignes-1}
  MOV BL,xd
  SUB BL,xg
  INC BL              {BL=xd-xg+1: nombre de colonnes}

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  SUB DL,BL
  SHL DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt-nombre colonnes)}

  PUSH ES
  POP DS

  XOR CH,CH
 @scrolle:
  MOV CL,BL           {CX=nombre colonnes}
  REP MOVSW           {copie une ligne}
  ADD SI,DX
  ADD DI,DX           {ligne suivante}
  DEC BH
  JNZ @scrolle

  MOV AL,' '          {espace}
  MOV CL,BL           {CX=nombre colonnes}
 @efface:
  STOSB               {efface ligne du bas}
  INC DI              {saute l'attribut}
  DEC CL
  JNZ @efface

  POP DS
 End
End; {ScrolleZoneHaut}

{----------------------------------------------------------}

PROCEDURE ScrolleZoneBas(page,xg,yh,xd,yb: Byte);
Var ptr_VRAM: Pointer;
Begin
 If (xd<xg) or (yb<=yh) Then Exit;

 ptr_VRAM:=PtrVRAM(page,xg,yb);
 ASM
  PUSH DS
  CLD

  LES DI,ptr_VRAM     {ES:DI -> coin inf‚rieur gauche}
  XOR AH,AH
  MOV AL,largeur_ecran_txt
  MOV SI,AX
  SHL SI,1
  NEG SI
  ADD SI,DI           {SI=DI-2*largeur_ecran_txt: source=ligne du dessus}

  MOV BH,yb
  SUB BH,yh           {BH=yb-yh: nombre de lignes-1}
  MOV BL,xd
  SUB BL,xg
  INC BL              {BL=xd-xg+1: nombre de colonnes}

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  ADD DL,BL
  SHL DX,1            {d‚cr‚ment SI et DI: DX=2*(largeur_ecran_txt+nombre colonnes)}

  PUSH ES
  POP DS

  XOR CH,CH
 @scrolle:
  MOV CL,BL           {CX=nombre colonnes}
  REP MOVSW           {copie une ligne}
  SUB SI,DX
  SUB DI,DX           {ligne suivante}
  DEC BH
  JNZ @scrolle

  MOV AL,' '          {espace}
  MOV CL,BL           {CX=nombre colonnes}
 @efface:
  STOSB               {efface ligne du haut}
  INC DI              {saute l'attribut}
  DEC CL
  JNZ @efface

  POP DS
 End
End; {ScrolleZoneBas}

{----------------------------------------------------------}

PROCEDURE ScrolleZoneGauche(page,xg,yh,xd,yb: Byte);
Var ptr_VRAM: Pointer;
Begin
 If (xd<=xg) or (yb<yh) Then Exit;

 ptr_VRAM:=PtrVRAM(page,xg,yh);
 ASM
  PUSH DS

  LES DI,ptr_VRAM     {ES:DI -> coin sup‚rieur gauche}
  MOV SI,DI
  INC SI
  INC SI              {SI=DI+2: source=colonne de droite}

  MOV BH,yb
  SUB BH,yh
  INC BH              {BH=yb-yh+1: nombre de lignes}
  MOV BL,xd
  SUB BL,xg           {BL=xd-xg: nombre de colonnes-1}
  PUSH BX

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  SUB DL,BL
  SHL DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt-(nombre colonnes-1))}

  PUSH ES
  POP DS

  CLD
  XOR CH,CH
 @scrolle:
  MOV CL,BL           {CX=(nombre colonnes)-1}
  REP MOVSW           {copie une ligne}
  ADD SI,DX
  ADD DI,DX           {ligne suivante}
  DEC BH
  JNZ @scrolle

  SUB DI,DX
  MOV AL,' '          {espace}

  STD                 {sens d‚croissant}
  POP BX
  MOV CL,BH           {CX=nombre lignes}

  POP DS

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  SHL DX,1
  DEC DX              {d‚cr‚ment DI: DX=2*largeur_ecran_txt-1}

 @efface:
  STOSB               {efface colonne de droite}
  SUB DI,DX           {ligne suivante}
  DEC CL
  JNZ @efface
 End
End; {ScrolleZoneGauche}

{----------------------------------------------------------}

PROCEDURE ScrolleZoneDroite(page,xg,yh,xd,yb: Byte);
Var ptr_VRAM: Pointer;
Begin
 If (xd<=xg) or (yb<yh) Then Exit;

 ptr_VRAM:=PtrVRAM(page,xd,yh);
 ASM
  PUSH DS

  LES DI,ptr_VRAM     {ES:DI -> coin sup‚rieur droit}
  MOV SI,DI
  DEC SI
  DEC SI              {SI=DI-2: source=colonne de gauche}

  MOV BH,yb
  SUB BH,yh
  INC BH              {BH=yb-yh+1: nombre de lignes}
  MOV BL,xd
  SUB BL,xg           {BL=xd-xg: nombre de colonnes-1}
  PUSH BX

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  ADD DL,BL
  SHL DX,1            {incr‚ment SI et DI: DX=2*(largeur_ecran_txt+(nombre colonnes-1))}

  PUSH ES
  POP DS

  STD                 {sens d‚croissant}
  XOR CH,CH
 @scrolle:
  MOV CL,BL           {CX=(nombre colonnes)-1}
  REP MOVSW           {copie une ligne}
  ADD SI,DX
  ADD DI,DX           {ligne suivante}
  DEC BH
  JNZ @scrolle

  SUB DI,DX
  MOV AL,' '          {espace}

  POP BX
  MOV CL,BH           {CX=nombre lignes}

  POP DS

  XOR DH,DH
  MOV DL,largeur_ecran_txt
  SHL DX,1
  DEC DX              {d‚cr‚ment DI: DX=2*largeur_ecran_txt-1}

 @efface:
  STOSB               {efface colonne de gauche}
  SUB DI,DX           {ligne suivante}
  DEC CL
  JNZ @efface
 End
End; {ScrolleZoneDroite}

{==========================================================}

END.