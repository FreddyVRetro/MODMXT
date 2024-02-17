UNIT MM_PROG;
{unit‚ pour Mod Master: routines pour les programmes}

{$A+,G-,Q-,R-,S-}

INTERFACE

{$DEFINE CGAOnly}

{==========================================================}

PROCEDURE ChargeProgramme;
PROCEDURE SauveProgramme;

{==========================================================}

IMPLEMENTATION

{$IFNDEF CGAOnly}
USES Dos,Clavier,Fichiers,Util,UtilSm,Texte,Souris,SourisM,
     MM_VAR,MMSS_Var,MM_DIV,MM_AFF;
{$ELSE}
USES Dos,Clavier,Fichiers,Util,UtilC,Texte,Souris,SourisC,
     MM_VAR,MMSS_Var,MM_DIV,MM_AFF;
{$ENDIF}

{==========================================================}

PROCEDURE ChargeProgramme;

Type typecoul=(normal,inverse);

Const Erreur_format_txt: Array[1..2] of String[11]
       =('Wrong','PRG format!');

      Couleur: Array[Boolean] of Byte=(25,31);

      nbr_prog_max=64; {nombre maximal de programme dans le r‚pertoire}

      hauteur_fenetre=8; {nombre de fichiers affichables simultan‚ment}
      x_asc=37; y_asc=10; {coordonn‚es de la flŠche vers le haut}

Var z: Zone;
    Prog: Array[1..nbr_prog_max] of String[8];
    fich: SearchRec;
    ident: String20;
    nom_prog: String12;
    DebutListe: Array[1..8] of String12;
    premier,nbr_prog,choix_prog,x,y: Byte;
    i,j,nbr_modules_prog: Word;
    defile_fenetre,bouge_ascenseur,choix_clique,
    ok_PRG,sortie,ok: Boolean;
    fPRG: Fichier;
    boutonOK,boutonAnnuler: Bouton;
    nouveau_lecteur: Char;


Procedure AfficheChoix(ch: Byte; coul: typecoul);
Const Color: Array[typecoul] of Byte=(27,48);
Begin
 AffChXY(0,27,ch-premier+y_asc,' '+XString(Prog[ch],' ',9),Color[coul])
End; {AfficheChoix}


Procedure CorrigePremier;
Begin
 If choix_prog<premier Then premier:=choix_prog;
 If choix_prog>premier+hauteur_fenetre-1 Then premier:=choix_prog-hauteur_fenetre+1
End; {CorrigePremier}


Procedure CorrigeChoix;
Begin
 If choix_prog<premier Then choix_prog:=premier;
 If choix_prog>premier+hauteur_fenetre-1 Then choix_prog:=premier+hauteur_fenetre-1
End; {CorrigeChoix}


Procedure DefileHaut;
Begin
 If choix_prog>1 Then Dec(choix_prog);
 CorrigePremier
End; {DefileHaut}


Procedure DefileBas;
Begin
 If choix_prog<nbr_prog Then Inc(choix_prog);
 CorrigePremier
End; {DefileBas}


Procedure DefilePageHaut;
Begin
 If choix_prog>hauteur_fenetre Then
  Begin
   Dec(choix_prog,hauteur_fenetre);
   If premier>hauteur_fenetre Then Dec(premier,hauteur_fenetre) Else premier:=1
  End
 Else Begin choix_prog:=1; premier:=1 End
End; {DefilePageHaut}


Procedure DefilePageBas;
Begin
 Inc(choix_prog,hauteur_fenetre); Inc(premier,hauteur_fenetre);
 If choix_prog>nbr_prog Then choix_prog:=nbr_prog;
 If nbr_prog>=hauteur_fenetre Then
  If premier>nbr_prog-hauteur_fenetre+1 Then premier:=nbr_prog-hauteur_fenetre+1;
 If nbr_prog<hauteur_fenetre Then premier:=1
End; {DefilePageBas}


Procedure AfficheNomModule(i: Byte);
Begin
 AffChXY(0,42,i+y_asc-1,XString(DebutListe[i],' ',12),Couleur[IndiceModule(DebutListe[i])>0])
End; {AfficheNomModule}


Begin  {ChargeProgramme}
 CacheCursSouris;
 OmbreZoneCoins(22,7,59,21,z,19);
 Cadre(0,1,23,7,58,21,19,' Load a Program ',27,'');
 Cadre(0,1,26,9,37,18,19,'',19,'');
 AfficheBoutonsOKAnnuler(33,19,boutonOK,boutonAnnuler);
 Repeat
  nbr_prog:=0;
  FindFirst(repert+'*.PRG',ReadOnly+Archive,fich);
  While (DosError=0) and (nbr_prog<nbr_prog_max) do
   Begin
    Inc(nbr_prog); Prog[nbr_prog]:=Copy(fich.Name,1,Pos('.',fich.Name)-1);
    FindNext(fich)
   End;
  If DosError=152 Then AfficheErreurLecteurPasPret('','C',nouveau_lecteur); {reste sur le mˆme lecteur}
  If Not(DosError in [0,18,152]) Then AfficheErreurLecture
 Until DosError<>152;

 defile_fenetre:=False; bouge_ascenseur:=False; choix_clique:=False;
 choix_prog:=1; premier:=1;
 sortie:=False; ok:=False;

 Repeat
  CacheCursSouris;

  If nbr_prog>hauteur_fenetre Then
   AfficheAscenseur(x_asc,y_asc,hauteur_fenetre,nbr_prog,premier,11);

  For i:=premier to premier+hauteur_fenetre-1 do
   If (i<=nbr_prog) and (i<>choix_prog) Then AfficheChoix(i,normal);
  AfficheChoix(choix_prog,inverse);

  If BoutonSouris=aucun Then
   Begin
    If choix_clique and Not(defile_fenetre) Then ok:=True;
    defile_fenetre:=False; bouge_ascenseur:=False; choix_clique:=False
   End;

  If choix_clique Then ZoneSouris(x_asc-10,y_asc-1,x_asc-1,y_asc+hauteur_fenetre)
  Else
   If defile_fenetre or bouge_ascenseur Then ZoneSouris(x_asc,y_asc,x_asc,y_asc+hauteur_fenetre-1)
                                        Else ZoneSouris(1,1,80,hauteur_ecran_txt);

  {recherche les 8 premiers modules dans le fichier PRG}
  AffCursSouris;
  With fPRG do
  Repeat
   Ouvre(lecture,repert+Prog[choix_prog]+'.PRG');
   ok_PRG:=False;
   Case f_erreur of
    f_ok: Begin
           Lit(ident[1],20); ident[0]:=#20;
		   Ok_PRG:=true;
           {ok_PRG:=TestIdentModM(ident,Extensions[ext_PRG],version_min_PRG);
           If ok_PRG Then
            Begin}
             nbr_modules_prog:=(Taille-20) Div 13;
             For i:=1 to 8 do DebutListe[i]:='';
             PlacePointeur(20);
             i:=1;
             While (i<=nbr_modules_prog) and (i<=8) do
              Begin
               Lit(DebutListe[i][0],13); Inc(i)
              End;
            {End;}
           Ferme
          End;
    f_err_CRC,
    f_err_donnees,
    f_err_media,
    f_err_secteur : AfficheErreurLecture;
    f_err_pas_pret: AfficheErreurLecteurPasPret('','C',nouveau_lecteur)  {reste sur le mˆme lecteur}
   End
  Until f_erreur<>f_err_pas_pret;

  CacheCursSouris;
  If ok_PRG Then
   Begin
    Cadre(0,1,40,y_asc-1,55,y_asc+hauteur_fenetre,19,' '+Prog[choix_prog]+' ',19,'');
    For i:=1 to 7 do AfficheNomModule(i);
    Case nbr_modules_prog of
     1..7: EffaceZone(0,42,y_asc+hauteur_fenetre-1,53,y_asc+hauteur_fenetre-1,19); {ligne du bas}
     8: AfficheNomModule(8)
     Else AffChXY(0,42,y_asc+hauteur_fenetre-1,'... ('+EntierTexte(nbr_modules_prog,3)+')   ',30)
    End
   End
  Else
   Begin
    EffaceZone(0,40,y_asc-1,55,y_asc+hauteur_fenetre,19);
    For i:=1 to 2 do
     AffChXY(0,43,i+y_asc-1,Erreur_format_txt[i],30)
   End;

  AttendClavierSouris(Not(defile_fenetre or bouge_ascenseur or choix_clique),ok,x,y);
{$IFNDEF CGAOnly}
  SourisBouge :=False;
  If bouge_ascenseur or (choix_clique and Not(defile_fenetre)) Then
   Repeat Until KeyPressed or SourisBouge or (BoutonSouris=aucun);
{$ELSE}
  If bouge_ascenseur or (choix_clique and Not(defile_fenetre)) Then
   Repeat Until KeyPressed or (BoutonSouris=aucun);
{$ENDIF}

  If KeyPressed Then
   Case ReadKey of
    Up  : DefileHaut;
    Down: DefileBas;
    PgUp: DefilePageHaut;
    PgDn: DefilePageBas;
    Home: Begin choix_prog:=1; premier:=1 End;
    End_: Begin
           choix_prog:=nbr_prog;
           If nbr_prog>hauteur_fenetre Then premier:=nbr_prog-hauteur_fenetre+1
          End;
    Enter: ok:=True;
    Esc: sortie:=True
   End
  Else  {souris...}
   Begin
    If (x in [x_asc-10..x_asc-1]) and (y in [y_asc..y_asc+hauteur_fenetre-1]) Then
     If (premier+y-y_asc<=nbr_prog) and (BoutonSouris=gauche) Then
      Begin choix_clique:=True; choix_prog:=premier+y-y_asc End;
    If (x=x_asc) and (nbr_prog>hauteur_fenetre) Then
     Case y of
      y_asc: Begin defile_fenetre:=True; DefileHaut; DelaiBoutonSouris(10) End;
      y_asc+hauteur_fenetre-1: Begin defile_fenetre:=True; DefileBas; DelaiBoutonSouris(10) End;
      y_asc+1..y_asc+hauteur_fenetre-2:
             Begin
              premier:=1+Round((y-y_asc-1)*(nbr_prog-hauteur_fenetre)/(hauteur_fenetre-3));
              CorrigeChoix; bouge_ascenseur:=True
             End
     End;
    If boutonOK.Clique Then ok:=True;
    If boutonAnnuler.Clique Then sortie:=True
   End
 Until sortie or ok;

 If ok Then
  Begin
   CacheCursSouris;
   With fPRG do
   Repeat
    Ouvre(lecture,repert+Prog[choix_prog]+'.PRG');
    Case f_erreur of
     f_ok: Begin
            nom_programme:=Prog[choix_prog];
            Lit(ident[1],20); ident[0]:=#20;
              nbr_modules_prog:=(Taille-20) Div 13;
              If NOT REGISTERED Then
               nbr_modules_prog:=MinEntier(LONG_PROG_LIMIT,nbr_modules_prog); {bridage !!}
              For i:=1 to nbr_fich do Module[i].Numero:=0;
              Longueur_prog:=0;
              PlacePointeur(20);
              For i:=1 to nbr_modules_prog do
               Begin
                Lit(nom_prog[0],13);
                j:=IndiceModule(nom_prog);
                If j>0 Then
                 Begin Inc(Longueur_prog); Module[j].Numero:=Longueur_prog End
               End;
              Programme:=(Longueur_prog>0);
              Ferme
             End;
           {End;}
     f_err_CRC,
     f_err_donnees,
     f_err_media,
     f_err_secteur : AfficheErreurLecture;
     f_err_pas_pret: AfficheErreurLecteurPasPret('','C',nouveau_lecteur)  {reste sur le mˆme lecteur}
    End
   Until f_erreur<>f_err_pas_pret;
   AffCursSouris
  End;

 RestaureZoneSuppr(0,z)
End; {ChargeProgramme}

{----------------------------------------------------------}

PROCEDURE SauveProgramme;

Var z: Zone;
    i,nbr_modules_prog: Word;
    fPRG: Fichier;
    chaine: String[8];
    abandon: Boolean;
    ident: String20;
    nouveau_lecteur: Char;

Begin
 CacheCursSouris;
 OmbreZoneCoins(28,12,53,14,z,19);
 Cadre(0,1,29,12,52,14,19,' Save the program ',27,'');
 AffChXY(0,33,13,'Name:',23);
 AffCursSouris;
 chaine:=LitChaine(nom_programme,40,13,9,8,True,alpha+symboles_fichiers,True,112,127,abandon);
 If Not(abandon) and (chaine<>'') Then
  With fPRG do
  Repeat
   Cree(Not(teste_existe),repert+chaine+'.PRG');
   Case f_erreur of
    f_ok: Begin
           nom_programme:=chaine;
           ident:=ident_ModM+' PRG ';
           Ecrit(ident[1],20);
           If REGISTERED Then nbr_modules_prog:=Longueur_prog
                         Else nbr_modules_prog:=MinEntier(LONG_PROG_LIMIT,Longueur_prog); {bridage !!}
           For i:=1 to nbr_modules_prog do Ecrit(Module[Indice(i)].Nom[0],13);
           Ferme;
           With boutons[bt_Charge] do Begin Active(True); Affiche End
          End;
    f_err_CRC,
    f_err_donnees,
    f_err_media,
    f_err_secteur : AfficheErreur(Erreurs[err_ecriture_txt],Erreurs[changez_disq_txt],0);
    f_err_protect : AfficheErreur(Erreurs[disq_protegee_txt],Erreurs[en_ecriture_txt],0);
    f_err_pas_pret: AfficheErreurLecteurPasPret('','C',nouveau_lecteur)  {reste sur le mˆme lecteur}
   End
  Until Not(f_erreur in [f_err_protect,f_err_pas_pret]);
 RestaureZoneSuppr(0,z)
End; {SauveProgramme}

{==========================================================}

END.