{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                        --==ðð UTILC.PAS ðð==--                       º}
{º                                                                      º}
{º Unit‚ contenant des routines diverses pour le mode texte couleur     º}
{º (CGA et VGA) et la souris (curseur normal ou smooth)                 º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 8088          D‚but d'‚critureúúúúúúúúúúúúúúú??/10/94 º}
{º                              DerniŠres modificationsúúúúúúúú04/09/95 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

{$UNDEF Smooth}

{$IFNDEF Smooth}
UNIT UtilC;
{$ELSE}
UNIT UtilSm;
{$ENDIF}


{$A+,G-,Q-,R-,S-}


INTERFACE

{$IFNDEF Smooth}
USES Texte,Util,Souris,SouriSC;
{$ELSE}
USES Texte,Util,Souris,SouriSm;
{$ENDIF}

CONST {caractŠres autoris‚s pour LitChaine}
      chiffres=['0'..'9'];
      majuscules=['A'..'Z'];
      minuscules=['a'..'z'];
      lettres=majuscules+minuscules;
      alpha=lettres+chiffres;
      espace=[' '];
      symboles_fichiers=['.',':','\','_','$'];

      {justifications pour LitNombre}
      j_gauche=1;
      j_droite=2;


VAR {variables globales pour SelectionneFichier}
    repert: String80;
    sous_repert_parent: String12;

{==========================================================}

PROCEDURE RestaureZoneSuppr(page: Byte; Var z: Zone);
PROCEDURE RestaureEcranSuppr(page: Byte; Var e: Ecran);

FUNCTION  LitChaine(chaine_init: String; x,y,long_aff,long_max: Byte; aff_bords: Boolean;
                    liste_car: SetofChar; conv_maj: Boolean;
                    attr,attr_inverse: Byte; Var abandon: Boolean): String;

FUNCTION  LitNombre(nombre_init: Real; aff_init: Boolean; x,y,long_ent,long_dec: Byte;
                    autorise_moins: Boolean; justification: Byte;
                    attr,attr_inverse: Byte; Var abandon: Boolean): Real;

PROCEDURE AfficheBoutonsOKAnnuler(x,y: Byte; Var boutonOK,boutonAnnuler: Bouton);
PROCEDURE AfficheErreur(chaine1,chaine2: String25);

PROCEDURE InitRepert;
PROCEDURE AfficheAscenseur(x_asc,y_asc,hauteur_fenetre: Byte; longueur_liste,index_premier: Word; attribut: Byte);
FUNCTION  SelectionneFichier(titre: String25; extension: String3; hauteur_fenetre: Byte): String80;

{==========================================================}

IMPLEMENTATION

USES Crt,Dos,Clavier;

{==========================================================}

PROCEDURE RestaureZoneSuppr(page: Byte; Var z: Zone);
Begin
 CacheCursSouris;
 With z do Begin Restaure(page,0,0,0); Supprime End;
 AffCursSouris
End; {RestaureZoneSuppr}

{----------------------------------------------------------}

PROCEDURE RestaureEcranSuppr(page: Byte; Var e: Ecran);
Begin
 CacheCursSouris;
 With e do Begin Restaure(page); Supprime End;
 AffCursSouris
End; {RestaureEcranSuppr}

{----------------------------------------------------------}

FUNCTION LitChaine(chaine_init: String; x,y,long_aff,long_max: Byte; aff_bords: Boolean;
                   liste_car: SetofChar; conv_maj: Boolean;
                   attr,attr_inverse: Byte; Var abandon: Boolean): String;

{chaine_init       : chaŒne initiale affich‚e lors de la saisie
 x,y               : coordonn‚es de la chaŒne saisie
 long_aff          : longueur de la portion de chaŒne affich‚e
 long_max          : longueur maximale de la chaŒne saisie
 aff_bords         : si TRUE, affiche les flŠches d‚filantes sur les c“t‚s
 liste_car         : liste des caractŠres autoris‚s … la saisie (type ensemble)
 conv_maj          : si TRUE, convertit les minuscules en majuscules … la saisie
 attr,attr_inverse : attributs normal et inverse (avant d‚placement)
 abandon          -> TRUE si Esc appuy‚, FALSE si ÄÙ appuy‚}

Const bord_gauche: Array[Boolean] of Char=(' ','');
      bord_droit : Array[Boolean] of Char=(' ','');

Var chaine,chaine_aff: String;
    touche: Key;
    pos_gauche,position,xs,ys: Byte;
    bouge,defile,ok: Boolean;


Procedure DefileGauche;
Begin
 If position>1 Then
  Begin
   Dec(position);
   If (position<pos_gauche+(long_aff Div 5)) and (pos_gauche>1) Then Dec(pos_gauche)
  End
End; {DefileGauche}


Procedure DefileDroite;
Begin
 If position<Length(chaine)+1 Then
  Begin
   bouge:=True;
   Inc(position);
   If (position>pos_gauche+long_aff-(long_aff Div 5)) and
      (pos_gauche<=Length(chaine)-long_aff+1) Then Inc(pos_gauche)
  End
End; {DefileDroite}


Begin  {LitChaine}
 chaine:=chaine_init;
 pos_gauche:=1; position:=1;
 ActiveMode(InsMode); {active le mode insertion par d‚faut}
 bouge:=False; defile:=False;
 ok:=False; abandon:=False;

 Repeat
  chaine:=CopyL(chaine,long_max);
  chaine_aff:=Copy(chaine,pos_gauche,long_aff);

  AttendVBL;
  CacheCursSouris;
  AffChXY(0,x,y,RepeteCar(' ',long_aff),attr);
  If bouge Then AffChXY(0,x,y,chaine_aff,attr)
           Else AffChXY(0,x,y,chaine_aff,attr_inverse);
  If aff_bords Then
   Begin
    AffCarXY(0,x-1,y,bord_gauche[pos_gauche>1],(attr and $F0) or 15);
    AffCarXY(0,x+long_aff,y,bord_droit[pos_gauche<Length(chaine)-long_aff+2],(attr and $F0) or 15)
   End;

  CursXY(0,x+position-pos_gauche,y);
  If (EtatClavier and InsMode)=InsMode Then Curseur(plat) Else Curseur(rect);

  AttendClavierSouris(Not(defile),False,xs,ys);
  defile:=False;

  If KeyPressed Then
   Begin
    touche:=ReadKey;
    If conv_maj Then touche:=UpCase(touche);
    Case touche of
     Enter: ok:=True;
     Esc  : abandon:=True;
     Space..255: If (Char(touche) in liste_car) Then
                  Begin
                   If Not(bouge) Then Begin bouge:=True; chaine:='' End;
                   If (EtatClavier and InsMode)=0 Then Delete(chaine,position,1);
                   Insert(Char(touche),chaine,position);
                   If position<long_max+1 Then
                    Begin
                     Inc(position);
                     If position=Length(chaine)+1 Then
                      Begin
                       If (pos_gauche<=Length(chaine)-long_aff+1) Then Inc(pos_gauche)
                      End
                     Else
                      If (position>pos_gauche+long_aff-(long_aff Div 5)) Then Inc(pos_gauche)
                    End
                  End;
     Bdel: If position>1 Then
            Begin
             bouge:=True;
             Delete(chaine,position-1,1);
             Dec(position);
             If ((position<pos_gauche+(long_aff Div 5)) or (position>Length(chaine)-long_aff+1)) and
                (pos_gauche>1) Then Dec(pos_gauche)
            End;
     Left : DefileGauche;
     Right: DefileDroite;
     Home : Begin bouge:=True; position:=1; pos_gauche:=1 End;
     End_ : Begin
             bouge:=True;
             position:=Length(chaine)+1;
             If Length(chaine)>=long_aff Then pos_gauche:=Length(chaine)-long_aff+2
            End;
     Del  : If position<Length(chaine)+1 Then
             Begin
              bouge:=True;
              Delete(chaine,position,1);
              If (pos_gauche>Length(chaine)-long_aff+2) and (pos_gauche>1) Then Dec(pos_gauche)
             End
    End
   End
  Else  {souris}
   Begin
    If ys=y Then
     If xs=x-1 Then Begin DefileGauche; defile:=True; DelaiBoutonSouris(5) End
     Else
      If xs=x+long_aff Then Begin DefileDroite; defile:=True; DelaiBoutonSouris(5) End
      Else If (xs in [x..x+long_aff-1]) and
              (xs-x+pos_gauche<=Length(chaine)+1) Then
            Begin position:=xs-x+pos_gauche; bouge:=True End;
    abandon:=(BoutonSouris=droite)
   End
 Until ok or abandon;

 Curseur(off);
 CacheCursSouris; AffChXY(0,x,y,chaine_aff,attr); AffCursSouris;
 Repeat Until BoutonSouris=aucun;
 If abandon Then chaine:=chaine_init;
 LitChaine:=chaine
End; {LitChaine}

{----------------------------------------------------------}

FUNCTION LitNombre(nombre_init: Real; aff_init: Boolean; x,y,long_ent,long_dec: Byte;
                   autorise_moins: Boolean; justification: Byte;
                   attr,attr_inverse: Byte; Var abandon: Boolean): Real;

{nombre_init       : nombre initial avant la saisie
 aff_init          : si TRUE, nombre initial affich‚
 x,y               : coordonn‚es de la chaŒne saisie
 long_ent          : longueur de la partie entiŠre
 long_dec          : longueur de la partie d‚cimale (0 si entier)
 autorise_moins    : si TRUE, nombres n‚gatifs autoris‚s
 justification     : alignement … gauche ou … droite
 attr,attr_inverse : attributs normal et inverse (avant d‚placement)
 abandon          -> TRUE si Esc appuy‚, FALSE si ÄÙ appuy‚}

Var nombre: Real;
    chaine: String[15];
    touche: Key;
    erreur: Word;
    position,long_max: Byte;
    dx: Shortint;
    bouge,ok: Boolean;


Procedure AjouteCar(car: Char);
Begin
 If Not(bouge) Then Begin bouge:=True; chaine:=''; position:=1 End;
 If (EtatClavier and InsMode)=0 Then Delete(chaine,position,1);
 If (Length(chaine)>=1) and (position=1) and (chaine[1]='-') Then Exit;

 Insert(car,chaine,position);
 If position<long_max Then Inc(position)
End; {AjouteCar}

Function Moins: Boolean;
Begin
 Moins:=(Pos('-',chaine)<>0)
End; {Moins}

Function PosVirgule: Byte;
Begin
 PosVirgule:=Pos('.',chaine)
End; {PosVirgule}


Begin {LitNombre}
 If aff_init Then Str(nombre_init:1:long_dec,chaine) Else chaine:='';
 Case justification of
  j_gauche: position:=1;
  j_droite: position:=Length(chaine)+1
 End;
 long_max:=long_ent; If long_dec<>0 Then Inc(long_max,long_dec+1);
 ActiveMode(InsMode); {active le mode insertion par d‚faut}
 bouge:=False;
 ok:=False; abandon:=False;

 Repeat
  chaine:=CopyL(chaine,long_max);
  If position>long_max Then position:=long_max;
  Case justification of
   j_gauche: dx:=0;
   j_droite: Begin dx:=long_max-Length(chaine)-1; If dx=-1 Then Inc(dx) End
  End;

  AttendVBL;
  CacheCursSouris;
  AffChXY(0,x,y,RepeteCar(' ',long_max),attr);
  If bouge Then AffChXY(0,x+dx,y,chaine,attr)
           Else AffChXY(0,x+dx,y,chaine,attr_inverse);

  CursXY(0,x+dx+position-1,y);
  If (EtatClavier and InsMode)=InsMode Then Curseur(plat) Else Curseur(rect);

  AffCursSouris;
  Repeat Until KeyPressed or (BoutonSouris=droite);

  If KeyPressed Then
   Begin
    touche:=ReadKey;
    Case touche of
     Enter: If chaine<>'' Then ok:=True Else abandon:=True;
     Esc  : abandon:=True;
     Key('0')..Key('9'): AjouteCar(Char(touche));
     Key('-'): If autorise_moins Then
                Begin
                 If Not(bouge) Then Begin bouge:=True; chaine:=''; position:=1 End;
                 If Moins Then Begin Delete(chaine,1,1); If position>1 Then Dec(position) End
                          Else Begin Insert('-',chaine,1); Inc(position) End
                End;
     Key('.'),Key(','): If (long_dec<>0) and ((PosVirgule=0) or Not(bouge)) Then
                         Begin
                          AjouteCar('.');
                          If (PosVirgule=1) or ((PosVirgule=2) and (chaine[1]='-')) Then
                           Begin Insert('0',chaine,PosVirgule); Inc(position) End
                         End;
     Left : If position>1 Then Begin bouge:=True; Dec(position) End;
     Right: If position<Length(chaine)+1 Then Begin bouge:=True; Inc(position) End;
     Home : Begin bouge:=True; position:=1 End;
     End_ : Begin bouge:=True; position:=Length(chaine)+1 End;
     Bdel : If position>1 Then
             Begin bouge:=True; Delete(chaine,position-1,1); Dec(position) End;
     Del  : If position<Length(chaine)+1 Then
             Begin bouge:=True; Delete(chaine,position,1) End
    End
   End
  Else abandon:=True
 Until ok or abandon;

 Curseur(off);
 CacheCursSouris; AffChXY(0,x,y,chaine,attr); AffCursSouris;
 Repeat Until BoutonSouris=aucun;
 If abandon Then nombre:=nombre_init Else Val(chaine,nombre,erreur);
 LitNombre:=nombre
End; {LitNombre}

{----------------------------------------------------------}

PROCEDURE AfficheBoutonsOKAnnuler(x,y: Byte; Var boutonOK,boutonAnnuler: Bouton);
Begin
 boutonOK.Definit(0,x,y,' OK ',113,115,0,128);
 boutonAnnuler.Definit(0,x+9,y,' Annuler ',112,120,0,128);
 AffCursSouris;
 boutonOK.Affiche; boutonAnnuler.Affiche
End; {AfficheBoutonsOKAnnuler}

{----------------------------------------------------------}

PROCEDURE AfficheErreur(chaine1,chaine2: String25);
Var z: Zone;
    boutonOK: Bouton;
    sortie: Boolean;
Begin
 CacheCursSouris;
 z.Ombre(0,24,9,54,15,64);
 Cadre(0,1,25,9,53,15,71,' Erreur ',78,' ÄÙ ');
 AffChXY(0,27,10,chaine1,79);
 AffChXY(0,27,11,chaine2,79);
 AffCursSouris;
 With boutonOK do Begin Definit(0,38,13,' OK ',116,124,0,128); Affiche End;
 Repeat
  If KeyPressed Then sortie:=(ReadKey=Enter) Else sortie:=boutonOK.Clique
 Until sortie;
 RestaureZoneSuppr(0,z)
End; {AfficheErreur}

{----------------------------------------------------------}

PROCEDURE InitRepert;
{… appeler avant le premier appel … SelectionneFichier !}
Begin
 GetDir(0,repert);
 If repert[Length(repert)]<>'\' Then repert:=repert+'\';
 sous_repert_parent:=''
End; {InitRepert}

{----------------------------------------------------------}

PROCEDURE AfficheAscenseur(x_asc,y_asc,hauteur_fenetre: Byte; longueur_liste,index_premier: Word; attribut: Byte);
{conditions: hauteur_fenetre>5
             longueur_liste>hauteur_fenetre
             1 ó index_premier ó longueur_liste-hauteur_fenetre+1}

Var h_asc,pos_asc: Byte;
    ptr_VRAM: Pointer;

Begin
 h_asc:=1+Round((hauteur_fenetre-4)*(hauteur_fenetre-1)/(longueur_liste-2)); {hauteur barre ascenseur}
 pos_asc:=1+Round((index_premier-1)*(hauteur_fenetre-2-h_asc)/(longueur_liste-hauteur_fenetre)); {position barre ascenseur}
 ptr_VRAM:=PtrVRAM(0,x_asc,y_asc); {pointeur sur la page nø0}
 ASM
  CLD
  LES DI,ptr_VRAM

  MOV WORD PTR ES:[DI],256*79+''
  ADD DI,160

  XOR CH,CH
  MOV CL,pos_asc
  DEC CL
  MOV BL,CL         {BL=CL=pos_asc-1}
  JCXZ @barre_ascenseur
  MOV AX,256*8+'±'
 @affiche_zone_sombre_sup:
  STOSW
  ADD DI,158
  LOOP @affiche_zone_sombre_sup

 @barre_ascenseur:
  MOV AH,attribut
  MOV AL,'Û'
  MOV CL,h_asc
 @affiche_barre_ascenseur:
  STOSW
  ADD DI,158
  LOOP @affiche_barre_ascenseur

  MOV CL,hauteur_fenetre
  DEC CL
  DEC CL
  SUB CL,h_asc
  SUB CL,BL         {CL=(hauteur_fenetre-2)-h_asc-(pos_asc-1)}
  JCXZ @fleche_bas

  MOV AX,256*8+'±'
 @affiche_zone_sombre_inf:
  STOSW
  ADD DI,158
  LOOP @affiche_zone_sombre_inf

 @fleche_bas:
  MOV WORD PTR ES:[DI],256*79+''
 End
End; {AfficheAscenseur}

{----------------------------------------------------------}

FUNCTION SelectionneFichier(titre: String25; extension: String3; hauteur_fenetre: Byte): String80;
{hauteur_fenetre=nombre de fichiers affich‚s (doit ˆtre > 5 !)}
{valeur standard: nbr_lignes-11}

Type typecoul=(normal,inverse);

Const x_asc=45; y_asc=6;  {coordonn‚es de la flŠche vers le haut}

Var z: Zone;
    x,y: Byte;
    i,premier,nbr_fich,choix_fich: Word;
    touche: Key;
    lecteur_physique,lecteur_logique: Char;
    fich: SearchRec;
    Dir: Array[1..512] of String[13];
    liste_lecteurs: String26;
    change_rep,defile_fenetre,bouge_ascenseur,choix_clique,
    ok,sortie: Boolean;
    boutonOK,boutonAnnuler: Bouton;


Procedure ChangeLecteur(lettre: Char);
Begin
 lecteur_physique:=lettre; lecteur_logique:=lecteur_physique;
 repert:=CheminAccesDOS(lecteur_logique);
 sous_repert_parent:=''; change_rep:=True
End; {ChangeLecteur}


Function Repertoire(index: Word): Boolean;
Begin
 Repertoire:=(Dir[index][1]='\')
End; {Repertoire}


Procedure AfficheChoix(ch: Word; coul: typecoul);
Const Couleur: Array[Boolean,typecoul] of Byte=((49,31),(62,30));
Begin
 If nbr_fich>0 Then
  AffChXY(0,x_asc-15,ch-premier+y_asc,' '+XString(Dir[ch],' ',14),Couleur[Repertoire(ch),coul])
End; {AfficheChoix}


Procedure TestChoix;
Begin
 If nbr_fich>0 Then
  If Repertoire(choix_fich) Then
   Begin
    If Dir[choix_fich]='\..' Then
     Begin
      sous_repert_parent:=SousRepertoire(repert);
      repert:=FExpand(repert+'..\')
     End
    Else
     Begin
      sous_repert_parent:='';
      Dec(repert[0]);
      repert:=FExpand(repert+Dir[choix_fich]+'\')
     End;
    change_rep:=True
   End
  Else ok:=True
End; {TestChoix}


Procedure CorrigePremier;
Begin
 If choix_fich<premier Then premier:=choix_fich;
 If choix_fich>premier+hauteur_fenetre-1 Then premier:=choix_fich-hauteur_fenetre+1
End; {CorrigePremier}


Procedure CorrigeChoix;
Begin
 If choix_fich<premier Then choix_fich:=premier;
 If choix_fich>premier+hauteur_fenetre-1 Then choix_fich:=premier+hauteur_fenetre-1
End; {CorrigeChoix}


Procedure DefileHaut;
Begin
 If choix_fich>1 Then Dec(choix_fich);
 CorrigePremier
End; {DefileHaut}


Procedure DefileBas;
Begin
 If choix_fich<nbr_fich Then Inc(choix_fich);
 CorrigePremier
End; {DefileBas}


Procedure DefilePageHaut;
Begin
 If choix_fich>hauteur_fenetre Then
  Begin
   Dec(choix_fich,hauteur_fenetre);
   If premier>hauteur_fenetre Then Dec(premier,hauteur_fenetre) Else premier:=1
  End
 Else Begin choix_fich:=1; premier:=1 End
End; {DefilePageHaut}


Procedure DefilePageBas;
Begin
 Inc(choix_fich,hauteur_fenetre); Inc(premier,hauteur_fenetre);
 If choix_fich>nbr_fich Then choix_fich:=nbr_fich;
 If nbr_fich>=hauteur_fenetre Then
  If premier>nbr_fich-hauteur_fenetre+1 Then premier:=nbr_fich-hauteur_fenetre+1;
 If nbr_fich<hauteur_fenetre Then premier:=1
End; {DefilePageBas}


Procedure QuickSort(debut,fin: Word);
Var i,j: Word;
    aux1,aux2: String[14];
Begin
 i:=debut; j:=fin; aux1:=Dir[(debut+fin) Shr 1];
 Repeat
  While Dir[i]<aux1 do Inc(i);
  While aux1<Dir[j] do Dec(j);
  If i<=j Then
   Begin
    aux2:=Dir[i]; Dir[i]:=Dir[j]; Dir[j]:=aux2;
    Inc(i); Dec(j)
   End
 Until i>j;
 If debut<j Then QuickSort(debut,j);
 If i<fin   Then QuickSort(i,fin)
End; {QuickSort}


Procedure ChercheInitiale(initiale: Char);
Var i,j,nbr: Word;
Begin
 nbr:=0;
 For i:=1 to nbr_fich do
  If Dir[i][1]=initiale Then Begin Inc(nbr); j:=i End;
 If nbr>0 Then
  Begin
   If (choix_fich>=j-nbr+1) and (choix_fich<j) Then Inc(choix_fich) Else choix_fich:=j-nbr+1;
   CorrigePremier
  End
End; {ChercheInitiale}


Procedure AfficheLettresLecteurs;
Const couleur: Array[Boolean] of Byte=(113,15);
Var i: Byte;
    lettre: Char;
Begin
 For i:=1 to MinEntier(Length(liste_lecteurs),(hauteur_fenetre Div 2)+1) do
  Begin
   lettre:=liste_lecteurs[i];
   AffChXY(0,x_asc+2,y_asc-1+2*(i-1),' '+lettre+': ',couleur[lettre=lecteur_logique])
  End
End; {AfficheLettresLecteurs}



Begin {SelectionneFichier}
 Curseur(off);
 CacheCursSouris;

 liste_lecteurs:=ListeLecteurs; lecteur_logique:=repert[1];

 z.Ombre(0,x_asc-20,y_asc-3,x_asc+8,y_asc+hauteur_fenetre+3,48);
 Cadre(0,1,x_asc-19,y_asc-3,x_asc+7,y_asc+hauteur_fenetre+3,49,' '+titre+' ',112,'');
 AfficheBoutonsOKAnnuler(x_asc-15,y_asc+hauteur_fenetre+1,boutonOK,boutonAnnuler);

 sortie:=False; ok:=False;
 Repeat
  CacheCursSouris;

  lecteur_physique:=repert[1]; AfficheLettresLecteurs;

  EffaceZone(0,x_asc-15,y_asc,x_asc-1,y_asc+hauteur_fenetre-1,48);
  Cadre(0,1,x_asc-16,y_asc-1,x_asc,y_asc+hauteur_fenetre,49,' '+lecteur_logique+':*.'+extension+' ',49,'');
  AffCursSouris;

  If repert[Length(repert)]<>'\' Then repert:=repert+'\';
  nbr_fich:=0;
  FindFirst(repert+'*.*',Directory+Archive,fich);
  While DosError=0 do
   Begin
    If fich.Name<>'.' Then
     If (extension='*') or (Pos('.'+extension,fich.Name)>0)
        or (fich.Attr=Directory) Then
      Begin
       Inc(nbr_fich);
       Dir[nbr_fich]:=fich.Name;
       If fich.Attr=Directory Then Dir[nbr_fich]:='\'+Dir[nbr_fich]
      End;
    FindNext(fich)
   End;
  If DosError=3 Then AfficheErreur('Chemin introuvable sur','le lecteur '+lecteur_physique+': v‚rifiez');
  If DosError=152 Then AfficheErreur('Lecteur '+lecteur_physique+': pas prˆt','Ins‚rez une disquette');
  If Not(DosError in [0,3,18,152]) Then AfficheErreur('Erreur de lecture','Changez de disquette');

  choix_fich:=1; premier:=1;
  If nbr_fich>0 Then
   Begin
    For i:=1 to nbr_fich do If Repertoire(i) Then Dir[i]:=#0+Dir[i]; {pour classer les r‚pertoires avant les fichiers}
    QuickSort(1,nbr_fich);
    For i:=1 to nbr_fich do If Dir[i][1]=#0 Then Delete(Dir[i],1,1)
   End;

  If sous_repert_parent<>'' Then
   Begin
    For i:=1 to nbr_fich do
     If (Dir[i]='\'+sous_repert_parent) Then Begin choix_fich:=i; Break End;
    CorrigePremier
   End;

  change_rep:=False; defile_fenetre:=False;
  bouge_ascenseur:=False; choix_clique:=False;

  Repeat
   {$IFNDEF Smooth}
   If (BoutonSouris=aucun) or Not(defile_fenetre) Then
   {$ENDIF}
   CacheCursSouris;

   If nbr_fich>hauteur_fenetre Then
    AfficheAscenseur(x_asc,y_asc,hauteur_fenetre,nbr_fich,premier,11);

   For i:=premier to premier+hauteur_fenetre-1 do
    If (i<=nbr_fich) and (i<>choix_fich) Then AfficheChoix(i,normal);
   AfficheChoix(choix_fich,inverse);

   If BoutonSouris=aucun Then
    Begin
     {$IFNDEF Smooth}
     DefCursSouris(standard,0,0,#0);
     {$ENDIF}
     If choix_clique and Not(defile_fenetre) Then TestChoix;
     defile_fenetre:=False; bouge_ascenseur:=False; choix_clique:=False
    End;

   If choix_clique Then ZoneSouris(x_asc-15,y_asc-1,x_asc-1,y_asc+hauteur_fenetre)
   Else
    If defile_fenetre or bouge_ascenseur Then ZoneSouris(x_asc,y_asc,x_asc,y_asc+hauteur_fenetre-1)
                                         Else ZoneSouris(1,1,80,hauteur_ecran_txt);

   AttendClavierSouris(Not(defile_fenetre or bouge_ascenseur or choix_clique),change_rep or ok,x,y);

   {$IFDEF Smooth}
   SourisBouge:=False;
   {$ENDIF}
   If bouge_ascenseur or (choix_clique and Not(defile_fenetre)) Then
    Repeat Until KeyPressed or SourisBouge or (BoutonSouris=aucun);

   If KeyPressed Then
    Begin
     touche:=UpCase(ReadKey);
     If (EtatClavier and (ShiftG or ShiftD))=0 Then {aucune touche Shift appuy‚e}
      Case touche of
       Key('A')..Key('Z'): If Pos(Char(touche),liste_lecteurs)>0 Then ChangeLecteur(Char(touche));
       Up  : DefileHaut;
       Down: DefileBas;
       PgUp: DefilePageHaut;
       PgDn: DefilePageBas;
       Home: Begin choix_fich:=1; premier:=1 End;
       End_: Begin
              choix_fich:=nbr_fich;
              If nbr_fich>hauteur_fenetre Then premier:=nbr_fich-hauteur_fenetre+1
             End;
       CtrlPgUp: If premier>1 Then Begin Dec(premier); CorrigeChoix End
                 Else DefileHaut;
       CtrlPgDn: If nbr_fich>hauteur_fenetre Then
                  If premier<nbr_fich-hauteur_fenetre+1 Then
                   Begin Inc(premier); CorrigeChoix End
                  Else DefileBas
                 Else DefileBas;
       Enter: TestChoix;
       Esc  : sortie:=True
      End
     Else  {au moins une touche Shift est appuy‚e}
      If (touche>=Key('A')) and (touche<=Key('Z')) Then ChercheInitiale(Char(touche))
    End
   Else  {souris}
    Begin
     If (x in [x_asc-15..x_asc-1]) and (y in [y_asc..y_asc+hauteur_fenetre-1]) Then
      If (premier+y-y_asc<=nbr_fich) and (BoutonSouris=gauche) Then
       Begin choix_clique:=True; choix_fich:=premier+y-y_asc End;
      If (x=x_asc) and (nbr_fich>hauteur_fenetre) Then
       If y=y_asc Then
        Begin
         {$IFNDEF Smooth}
         DefCursSouris(standard,0,0,#0);
         {$ENDIF}
         defile_fenetre:=True; DefileHaut; DelaiBoutonSouris(10)
        End
       Else
        If y=y_asc+hauteur_fenetre-1 Then
         Begin
          {$IFNDEF Smooth}
          DefCursSouris(standard,0,0,#0);
          {$ENDIF}
          defile_fenetre:=True; DefileBas; DelaiBoutonSouris(10)
         End
        Else
         If (y in [y_asc+1..y_asc+hauteur_fenetre-2]) Then
          Begin
           {$IFNDEF Smooth}
           DefCursSouris(change_tout,4,11,'');
           {$ENDIF}
           premier:=1+Round((y-y_asc-1)*(nbr_fich-hauteur_fenetre)/(hauteur_fenetre-3));
           CorrigeChoix; bouge_ascenseur:=True
          End;
      If (x in [x_asc+2..x_asc+5]) Then
       Begin
        For i:=1 to MinEntier(Length(liste_lecteurs),(hauteur_fenetre Div 2)+1) do
         If y=y_asc-1+2*(i-1) Then
          Begin
           {$IFNDEF Smooth}
           DefCursSouris(inverse_attribut,0,0,'û');
           {$ENDIF}
           ChangeLecteur(liste_lecteurs[i])
          End;
        Repeat Until BoutonSouris=aucun;
        {$IFNDEF Smooth}
        DefCursSouris(standard,0,0,#0)
        {$ENDIF}
       End;
      If choix_clique Then
       If y=y_asc-1 Then
        Begin
         {$IFNDEF Smooth}
         DefCursSouris(garde_fond,0,15,'');
         {$ENDIF}
         defile_fenetre:=True; DefileHaut; Delay(15)
        End
       Else
        If y=y_asc+hauteur_fenetre Then
         Begin
         {$IFNDEF Smooth}
          DefCursSouris(garde_fond,0,15,'');
          {$ENDIF}
          defile_fenetre:=True; DefileBas; Delay(15)
         End
        Else
         Begin
          {$IFNDEF Smooth}
          DefCursSouris(inverse_attribut,0,0,'û');
          {$ENDIF}
          defile_fenetre:=False
         End;
     If boutonOK.Clique Then TestChoix;
     sortie:=boutonAnnuler.Clique
    End
  Until change_rep or sortie or ok
 Until sortie or ok;

 RestaureZoneSuppr(0,z);
 If ok Then SelectionneFichier:=repert+Dir[choix_fich]
       Else SelectionneFichier:=''
End; {SelectionneFichier}

{==========================================================}

END.
