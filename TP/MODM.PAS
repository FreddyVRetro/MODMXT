{                  Mod Master XT                    }
{ Mod Master 2.2 Modified to work on an XT Computer }

PROGRAM ModMaster;
{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

USES Crt,Dos,Clavier,Fichiers,Texte,Util,UtilC,Souris,SourisC,
     MM_VAR,MMSS_Var,MMSS_CMD,MM_DIV,MM_AFF,MM_PROG,MM_PARAM,MODMUNIT;

{$M 16384,0,56000} { Before 16Bit 39Kb 56000}

CONST MemoireMinimale=65000;

{==========================================================}

PROCEDURE GestionInterface;

Const
      CtrlV=22;

{$IFNDEF CGAOnly}
      hauteur_fenetre=22; {nombre de fichiers affichables simultanement}
      x_asc=42; y_asc=4;  {coordonnees de la fleche vers le haut}
      x_CGA=0;
{$ELSE}
      hauteur_fenetre=19; {nombre de fichiers affichables simultanement}
      x_asc=43; y_asc=4;  {coordonnees de la fleche vers le haut}
      x_CGA=1;
{$ENDIF}


Type typecoul=(normal,inverse);

Var x,y,anc_bouton_souris: Byte;
    i,premier,choix_fich,erreur,erreur_musique,fm: Word;
    lecteur_physique,lecteur_logique,nouveau_lecteur: Char;
    touche: Key;
    fich: SearchRec;
    nom_module,anc_module: String[14];
    liste_lecteurs: String26;
    change_rep,defile_fenetre,bouge_ascenseur,choix_clique,module_choisi,
    lecture_module,lecture_prog,IntroScan,anc_prog,quitte: Boolean;

{----------------------------------------------------------}

Procedure AttendClavierSouris(attend_bouge,condition: Boolean; Var x,y: Byte);
{modifiee pour l'economiseur...}
Var x_init,y_init,boutons: Byte;
    compteur_delai_eco,compteur_delai_eco_max: Word;
    top: Longint;

Begin
 VideBufferClavier;
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 EtatSouris(x_init,y_init,boutons);
 compteur_delai_eco_max:=Round(18.2*delai_economiseur*60);
 compteur_delai_eco:=compteur_delai_eco_max;
 top:=Timer;
 If attend_bouge Then
  Repeat
   EtatSouris(x,y,boutons)
  Until KeyPressed or (x<>x_init) or (y<>y_init) or (boutons=aucun);
 top:=Timer;
 Repeat
 Until KeyPressed or (BoutonSouris<>aucun) or condition;
 EtatSouris(x,y,boutons)
End; {AttendClavierSouris}


Procedure ChangeLecteur(lecteur: Char);
Begin
 If volume_modifie Then SauveFichierDIR;
 lecteur_physique:=lecteur; lecteur_logique:=lecteur_physique;
 repert:=CheminAcces(lecteur_logique);
 sous_repert_parent:=''; change_rep:=True
End; {ChangeLecteur}


Function Repertoire(index: Word): Boolean;
Begin
 Repertoire:=(Module[index].Nom[1]='\')
End; {Repertoire}

{----------------------------------------------------------}

Procedure AfficheChoix(ch: Word; coul: typecoul);
Const couleur_titre: Array[typecoul] of Byte=(48,63);
Var chaine: String20;
    couleur: Byte;
    vol: Word;
Begin
 If nbr_fich>0 Then With Module[ch] do
  Begin
   If Numero>0 Then AffChXY(0,3+x_CGA,ch-premier+y_asc,EntierTexte(Numero,3),63)
               Else AffChXY(0,3+x_CGA,ch-premier+y_asc,'   ',63);
   If coul=normal Then
        Case Repertoire(ch) of
          False: If MM_Hercule=True Then Couleur:=2  { Grey}
		            Else couleur:=48+CouleursExt[Extension(Module[ch].Nom)];
          True : If MM_Hercule=True Then Couleur:=$0A { White }	  
                    Else couleur:=62;
        End
   Else
    If MM_Hercule Then Couleur:=$70 { Gark on Grey, Reversed }
	   Else
        Case Repertoire(ch) of
         False: couleur:=31;
         True : couleur:=30
        End;
   AffChXY(0,6+x_CGA,ch-premier+y_asc,' '+XString(Nom,' ',13),couleur);
   If Repertoire(ch) Then AffChXY(0,21+x_CGA,ch-premier+y_asc,RepeteCar(' ',20),48)
   Else
    Begin
     Case File_Display_Mode of 
	     D_Name :  chaine:=XString(Titre,' ',20);

         D_Volume: Begin
                chaine:=EntierTexte(Taille,3)+'k ';
                If (Default_Mask AND M_DefVol) <>0 Then  {Module use Default Volume ? }
                 Begin
                  chaine:=chaine+'d';
                  vol:=MM_Default_Volume
                 End
                Else
                 Begin
                  chaine:=chaine+' ';
                  vol:=Volume
                 End;
                chaine:=chaine+' Volume: '+EntierTexte(vol Div 5,3)+'% '
               End;
         D_Freq : Begin
	           chaine:=EntierTexte(Taille,3)+'k ';
			    If (Default_Mask AND M_DefFreq) <>0 Then  {Module use Default Volume ? }
                 Begin
                  chaine:=chaine+'d Freq: '+EntierTexte(MM_Default_Frequency,5)+'Hz';
                  vol:=MM_Default_Volume
                 End
                Else
                 Begin
				  chaine:=chaine+'  Freq: '+EntierTexte(Frequency,5)+'Hz';
                  vol:=Volume
                 End;
			   
	           End;
	  End;
     AffChXY(0,21+x_CGA,ch-premier+y_asc,chaine,couleur_titre[coul])
    End
  End
End; {AfficheChoix}

{----------------------------------------------------------}

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

{----------------------------------------------------------}

Procedure ActiveLecture(prog: Boolean);
Begin
{$IFNDEF NoMOUSE}
 CacheCursSouris;
{$ENDIF}
 page_menu.Sauve(0);
 Numero_module:=1;
 lecture_module:=True; lecture_prog:=prog
End; {ActiveLecture}

{----------------------------------------------------------}

Procedure ProgrammeModule;
Var i: Word;
Begin
 If (nbr_modules>0) and Not(Repertoire(choix_fich)) Then
  With MMSS_CFG^,Module[choix_fich] do
   Begin
    If Numero=0 Then
     Begin Programme:=True; Inc(Longueur_prog); Numero:=Longueur_prog End
    Else
     Begin
      For i:=Numero+1 to Longueur_prog do Dec(Module[Indice(i)].Numero);
      Numero:=0;
      Dec(Longueur_prog); If Longueur_prog=0 Then Programme:=False
     End;
    AfficheBoutonsProgramme
   End
End; {ProgrammeModule}

{----------------------------------------------------------}

Procedure ProgrammeTout;
Var i: Word;
Begin
 With MMSS_CFG^ do
  Begin
   Longueur_prog:=0;
   For i:=premier_module to nbr_fich do
    Begin Inc(Longueur_prog); Module[i].Numero:=Longueur_prog End;
   Programme:=True; AfficheBoutonsProgramme;
   choix_fich:=Indice(1); CorrigePremier
  End
End; {ProgrammeTout}

{----------------------------------------------------------}

Procedure FonctionIntroScan;
Begin
 If Not(Programme) Then ProgrammeTout;
 IntroScan:=True; ActiveLecture(True)
End; {FonctionIntroScan}

{----------------------------------------------------------}

Procedure FonctionShuffle;
Var hasard,nbr_modules_programmes: Word;
    module_non_choisi: Array[1..nbr_fich_max] of Boolean;
Begin
 With MMSS_CFG^ do
  Begin
   For hasard:=1 to nbr_fich do module_non_choisi[hasard]:=True;
   If Not(Programme) Then  {programmer tout dans un ordre al�atoire}
    Begin
     Longueur_prog:=0;
     Repeat
      hasard:=premier_module+Random(nbr_modules);
      If module_non_choisi[hasard] Then
       Begin
        Inc(Longueur_prog); Module[hasard].Numero:=Longueur_prog;
        module_non_choisi[hasard]:=False
       End
     Until Longueur_prog=nbr_modules
    End
   Else  {r�arranger les modules d�j� programm�s dans un ordre al�atoire}
    Begin
     nbr_modules_programmes:=0;
     Repeat
      hasard:=premier_module+Random(nbr_modules);
      If (Module[hasard].Numero>0) and module_non_choisi[hasard] Then
       Begin
        Inc(nbr_modules_programmes);
        Module[hasard].Numero:=nbr_modules_programmes;
        module_non_choisi[hasard]:=False
       End
     Until nbr_modules_programmes=Longueur_prog
    End;
   Shuffle:=True; Programme:=True;
   AfficheBoutonsProgramme; ActiveLecture(True)
  End
End; {FonctionShuffle}

{----------------------------------------------------------}

Procedure EffaceProgramme;
Var i: Word;
Begin
 nom_programme:='';
 With MMSS_CFG^ do
  Begin
   For i:=1 to nbr_fich do Module[i].Numero:=0;
   Longueur_prog:=0; Programme:=False;
   AfficheBoutonsProgramme
  End
End; {EffaceProgramme}

{----------------------------------------------------------}

Function TesteChoixEstModule: Boolean;
Var test: Boolean;
Begin
 test:=False;
 If nbr_fich>0 Then
  Begin
   test:=Not(Repertoire(choix_fich));
   If Not(test) Then
    With Module[choix_fich] do
     Begin
      If volume_modifie Then SauveFichierDIR;
      If Nom='\..' Then
       Begin
        sous_repert_parent:=SousRepertoire(repert);
        repert:=FExpand(repert+'..\')
       End
      Else
       Begin
        sous_repert_parent:='';
        Dec(repert[0]);
        repert:=FExpand(repert+Nom+'\')
       End;
      change_rep:=True
     End
  End;
 TesteChoixEstModule:=test
End; {TesteChoixEstModule}

{----------------------------------------------------------}

Procedure DefileHaut;
Begin
 If choix_fich>1 Then Dec(choix_fich);
 CorrigePremier
End; {DefileHaut}

{----------------------------------------------------------}

Procedure DefileBas;
Begin
 If choix_fich<nbr_fich Then Inc(choix_fich);
 CorrigePremier
End; {DefileBas}

{----------------------------------------------------------}

Procedure DefilePageHaut;
Begin
 If choix_fich>hauteur_fenetre Then
  Begin
   Dec(choix_fich,hauteur_fenetre);
   If premier>hauteur_fenetre Then Dec(premier,hauteur_fenetre) Else premier:=1
  End
 Else Begin choix_fich:=1; premier:=1 End
End; {DefilePageHaut}

{----------------------------------------------------------}

Procedure DefilePageBas;
Begin
 Inc(choix_fich,hauteur_fenetre); Inc(premier,hauteur_fenetre);
 If choix_fich>nbr_fich Then choix_fich:=nbr_fich;
 If nbr_fich>=hauteur_fenetre Then
  If premier>nbr_fich-hauteur_fenetre+1 Then premier:=nbr_fich-hauteur_fenetre+1;
 If nbr_fich<hauteur_fenetre Then premier:=1
End; {DefilePageBas}

{----------------------------------------------------------}

Procedure QuickSort(debut,fin: Word);
Var i,j: Word;
    nom_aux: String[14];
Begin
 i:=debut; j:=fin; nom_aux:=Module[(debut+fin) Shr 1].Nom;
 Repeat
  While (Module[i].Nom<nom_aux) do Inc(i);
  While (nom_aux<Module[j].Nom) do Dec(j);
  If i<=j Then Begin EchangeModules(i,j); Inc(i); Dec(j) End
 Until i>j;
 If debut<j Then QuickSort(debut,j);
 If i<fin   Then QuickSort(i,fin)
End; {QuickSort}

{----------------------------------------------------------}

Procedure ChercheInitiale(initiale: Char);
Var i,j,nbr: Word;
Begin
 nbr:=0;
 For i:=premier_module to nbr_fich do
  If (Module[i].Nom[1]=initiale) Then Begin Inc(nbr); j:=i End;
 If nbr>0 Then
  Begin
   If (choix_fich>=j-nbr+1) and (choix_fich<j) Then Inc(choix_fich) Else choix_fich:=j-nbr+1;
   CorrigePremier
  End
End; {ChercheInitiale}

{----------------------------------------------------------}

Procedure AfficheLettresLecteurs;
Const couleur: Array[Boolean,1..2] of Byte=((99,96),(227,225));
Var i: Byte;
    lettre: Char;
Begin
 For i:=1 to MinEntier(Length(liste_lecteurs),(hauteur_fenetre Div 2)+1) do
  Begin
   lettre:=liste_lecteurs[i];
{$IFNDEF CGAOnly}
   AffChXY2(0,x_asc+3,y_asc+2*(i-1),'�^'+lettre+':^�',
   couleur[(lettre=lecteur_logique),2],couleur[(lettre=lecteur_logique),1])
{$Else}
   AffChXY2(0,x_asc+3,y_asc+2*(i-1),lettre+':',
   couleur[(lettre=lecteur_logique),2],couleur[(lettre=lecteur_logique),1])
{$EndIF}
  End
End; {AfficheLettresLecteurs}

{----------------------------------------------------------}

Procedure ChargeModule(chemin: String80; Var erreur: Word);
Var zone1: Zone;
Begin

{$IFNDEF NoMOUSE}
CacheCursSouris;
{$ENDIF}
 OmbreZoneCoins(26,11,53,13,zone1,19);
 Cadre(0,1,27,11,52,13,19,'',0,'');
 AffChXY(0,29,12,'Loading '+NomFichierSeul(chemin),31);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}

 MM_ChargeModule(chemin,erreur);
 RestaureZoneSuppr(0,zone1)
End; {ChargeModule}

Procedure TesteErreurModule(erreur: Word);
Begin
 Case erreur of
  Err_memoire: AfficheErreur(Erreurs[mem_insuff_txt],Erreurs[pour_charger_txt]+' '+nom_module,0);
  Err_format : AfficheErreur(Erreurs[err_format_txt],nom_module,0);
  Err_lecture: AfficheErreur(Erreurs[err_pendant_lect_txt],nom_module,0);
  Err_No_Sample: AfficheErreur(Erreurs[pas_instrument_txt],nom_module,0);
  Err_Unknown_Version: AfficheErreur(Erreurs[version_inconnue_txt],nom_module,0);
  Err_non_gere: AfficheErreur(Erreurs[format_non_gere_txt],nom_module,0)
 End
End; {TesteErreurModule}



Begin {GestionInterface}
 quitte:=False;

 liste_lecteurs:=ListeLecteurs; lecteur_logique:=repert[1];

 Repeat
{$IFNDEF NoMOUSE}
 CacheCursSouris;
{$ENDIF}
  EffaceZone(0,3+x_CGA,y_asc,x_asc-1,y_asc+hauteur_fenetre-1,49);
  LigneVerticBouts(x_asc,y_asc-1,y_asc+hauteur_fenetre,49);
{$IFNDEF NoMOUSE}
        AffCursSouris;
{$ENDIF}

  Repeat
   lecteur_physique:=repert[1]; AfficheLettresLecteurs;

{$IFNDEF NoMOUSE}
 CacheCursSouris;
{$ENDIF}
   AffChXY(0,1,hauteur_ecran_txt,' Path: '+XString(repert,' ',73),30);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}

   If repert[Length(repert)]<>'\' Then repert:=repert+'\';
   nbr_fich:=0;

   FindFirst(repert+'*.PRG',AnyFile,fich); {teste s'il y a des .PRG} {ReadOnly+Archive}
   PRG_present:=(DosError=0);
   FindFirst(repert+'*.*',AnyFile,fich); {ReadOnly+Directory+Archive}
   While (DosError=0) and (nbr_fich<nbr_fich_max) do
    Begin
     If fich.Name<>'.' Then
      If (Extension(fich.Name) in [1..nbr_extensions]) or
         (fich.Attr=Directory) Then
       Begin
        Inc(nbr_fich);
        With Module[nbr_fich] do
         Begin
          Nom:=fich.Name;
          If (fich.Attr=Directory) Then Insert('\',Nom,1);
          Taille:=fich.Size Shr 10
         End
       End;
     FindNext(fich)
    End;

    If DosError=152 Then
    Begin
     AfficheErreurLecteurPasPret(liste_lecteurs,repert[1],nouveau_lecteur);
     ChangeLecteur(nouveau_lecteur)
    End;
   If Not(DosError in [0,18,152]) Then AfficheErreurLecture
  Until DosError<>152;

  choix_fich:=1; premier:=1;
  If nbr_fich>0 Then
   Begin
    For i:=1 to nbr_fich do If Repertoire(i) Then Insert(#0,Module[i].Nom,1); {Classer les repertoires avant les fichiers}
    QuickSort(1,nbr_fich);
    For i:=1 to nbr_fich do If (Module[i].Nom[1]=#0) Then Delete(Module[i].Nom,1,1)
   End;
  nbr_modules:=0;
  For i:=1 to nbr_fich do
   Begin Module[i].Numero:=0; If Not(Repertoire(i)) Then Inc(nbr_modules) End;
  premier_module:=nbr_fich-nbr_modules+1;

  With MMSS_CFG^ do
   Begin Duree_intro:=0; Shuffle:=False; Programme:=False; Longueur_prog:=0 End;

  With boutons[bt_IntroScan] do
   Begin Active(nbr_modules>0); Affiche End;
  With boutons[bt_Shuffle] do
   Begin Active(nbr_modules>0); Affiche End;
  With boutons[bt_Tout] do
   Begin Active(nbr_modules>0); Affiche End;
  With boutons[bt_Charge] do
   Begin Active(PRG_present); Affiche End;
  AfficheBoutonsProgramme;

  For i:=premier_module to nbr_fich do
   With Module[i] do
    Begin
     Titre:='?'; Volume:=0; Frequency:=0; Default_Mask:=M_DefVol+M_DefFreq  {Default values for each module}
    End;

  If nbr_modules>0 Then AnalyseFichierDIR;

  If sous_repert_parent<>'' Then
   Begin
    i:=1; choix_fich:=0;
    Repeat
     If (Module[i].Nom='\'+sous_repert_parent) Then choix_fich:=i;
     Inc(i)
    Until choix_fich>0;
    CorrigePremier
   End;

  lecture_module:=False; lecture_prog:=False;
  volume_modifie:=False; IntroScan:=False;

  change_rep:=False; defile_fenetre:=False;
  bouge_ascenseur:=False; choix_clique:=False;

  Repeat
   If lecture_module Then       { **** Start Modules **** }
    With MMSS_CFG^ do
     Begin
      If lecture_prog Then
       Begin
        i:=Indice(Numero_module);
        nom_module:=Module[i].Nom;
        MMSS_Volume:=Module[i].Volume
       End
      Else
       With Module[choix_fich] do
        Begin
         nom_module:=Nom;
         If (Default_Mask AND M_DefVol) <>0 Then MMSS_Volume:=MM_Default_Volume
                          Else MMSS_Volume:=Volume
        End;

      If (nom_module=anc_module) and Not(recharge_module) Then erreur:=Ok
      Else
       Begin
        ChargeModule(repert+nom_module,erreur);
        recharge_module:=False
       End;
      If erreur in [Ok,Err_samples] Then  {erreur, mais on peut ecouter le module}
       Begin
        anc_module:=nom_module;
        If IntroScan Then Duree_intro:=duree_IntroScan Else Duree_intro:=0;
        anc_prog:=Programme;
        If Not(lecture_prog) Then Programme:=False;
        Mode_actuel:=Mode_Texte;
		
        if (Module[choix_fich].Default_Mask AND M_DefFreq)<>0 Then MMSS_CFG^.Out_Frequency:=MM_Default_Frequency
		   Else MMSS_CFG^.Out_Frequency:=Module[choix_fich].Frequency;
	    If (Module[choix_fich].Default_Mask AND M_IMF)=0 then { Correct Frequency if <> IMF }
		   If MMSS_CFG^.Out_Frequency<5000 Then MMSS_CFG^.Out_Frequency:=5000;
        With MMSS_CFG^ do
	     Begin
          Fm:=Get_MaxFreq(Wave_Output,MMType_SB,Utilise_stereo,Utilise_DC);
	      If MMSS_CFG^.Out_Frequency>Fm then MMSS_CFG^.Out_Frequency:=Fm
	     End;
{$IFNDEF NoMOUSE}
        CacheCursSouris;
{$ENDIF}

        Play(repert+nom_module);

{$IFNDEF NoMOUSE}
        AffCursSouris;
{$ENDIF}
     {   Writeln(MMSS_CFG^.MMSS_Error);}
		If MMSS_CFG^.MMSS_Error<>0 then AfficheErreur('Replay Error:',Play_Err[MMSS_CFG^.MMSS_Error],4);

        Programme:=anc_prog;
        IntroScan:=(Duree_intro>0); {car il peut etre desactive dans Play}
        lecture_module:=lecture_prog and (Touche_fin<>Tfin_Esc);
        Case Touche_fin of
         Tfin_normale: If Numero_module<Longueur_prog Then Inc(Numero_module) Else lecture_module:=False;
         Tfin_PgUp: Dec(Numero_module);
         Tfin_PgDn: Inc(Numero_module)
        End
       End
      Else  {erreur, le fichier n'a pas pu etre charge}
       Begin
{$IFNDEF CGAOnly}
        InitModeTexte;
{$ENDIF}		
        TesteErreurModule(erreur);
{$IFNDEF NoMOUSE}
	    CacheCursSouris;
{$ENDIF}
        anc_module:='';
        If lecture_prog Then
         Begin
          If Touche_fin=Tfin_PgUp Then
           Begin
            If Numero_module>1 Then Dec(Numero_module) Else lecture_module:=False
           End
          Else
           Begin
            If Numero_module<Longueur_prog Then Inc(Numero_module) Else lecture_module:=False
           End
         End
        Else lecture_module:=False
       End;

      If Not(lecture_module) Then
       Begin   
	   { InitModeTexte; }
        Clignotement(False);
{$IFNDEF NoMOUSE}
	    CacheCursSouris;
{$ENDIF}
        With page_menu do Begin Restaure(0); Supprime End;
        AffCursSouris;
	
        If lecture_prog Then
         Begin choix_fich:=Indice(Numero_module); CorrigePremier End
       End
     End
   Else  {pas de lecture}
    Begin

     If nbr_fich>hauteur_fenetre Then
      AfficheAscenseur(x_asc,y_asc,hauteur_fenetre,nbr_fich,premier,11);

     For i:=premier to premier+hauteur_fenetre-1 do
      If (i<=nbr_fich) and (i<>choix_fich) Then AfficheChoix(i,normal);
     AfficheChoix(choix_fich,inverse);

     IntroScan:=False; Shuffle:=False; {d�sactive les deux fonctions}

     If BoutonSouris=aucun Then
      Begin
       module_choisi:=False;
       If choix_clique and Not(defile_fenetre) Then
        If TesteChoixEstModule Then
         Case anc_bouton_souris of
          gauche: Begin ActiveLecture(False); module_choisi:=True End;
          droite: Begin ProgrammeModule; module_choisi:=True End
         End;
       defile_fenetre:=False; bouge_ascenseur:=False; choix_clique:=False
      End;

     If choix_clique Then ZoneSouris(3,y_asc-1,x_asc-1,y_asc+hauteur_fenetre)
     Else
      If defile_fenetre or bouge_ascenseur Then ZoneSouris(x_asc,y_asc,x_asc,y_asc+hauteur_fenetre-1)
                                           Else ZoneSouris(1,1,80,hauteur_ecran_txt);

     AttendClavierSouris(Not(defile_fenetre or bouge_ascenseur or choix_clique),change_rep or module_choisi,x,y);

     anc_bouton_souris:=BoutonSouris;
{     SourisBouge:=False;}
     If bouge_ascenseur or (choix_clique and Not(defile_fenetre)) Then
      Repeat Until KeyPressed {or SourisBouge} or (BoutonSouris=aucun);

     If KeyPressed Then
      Begin
       touche:=UpCase(ReadKey);
       If (EtatClavier and (ShiftG or ShiftD))=0 Then  {aucune touche Shift appuy�e}
        Begin

         Case touche of
          AltQ..AltM: If Pos(LettreAlt[touche],liste_lecteurs)>0 Then ChangeLecteur(LettreAlt[touche]);
          Left : With Module[choix_fich] do
                  If Numero>1 Then
                   Begin
                    choix_fich:=Indice(Numero-1); CorrigePremier
                   End
                  Else
                   If Programme Then
                    Begin
                     choix_fich:=Indice(1); CorrigePremier
                    End
		           Else  { Decrease individual module Frequency }
                    If Not(Repertoire(choix_fich)) Then
                      Begin
			 File_Display_Mode:=D_Freq; {Display Frequency}
                       With Module[choix_fich] do
					    Begin
                        If (Default_Mask AND M_NoFreq) = 0 Then { Adlib do nothing }
                           If (Default_Mask AND M_IMF) <> 0 Then
                              Begin { IMF 2 Frequency Choices }
                               If Frequency=700 then Frequency:=560
                                  Else If Frequency=560 then Frequency:=280
                                                        Else Frequency:=280;
                               volume_modifie:=True
                              End
                               Else If Frequency > 5000 Then
                                  Begin
                                   If (Default_Mask AND M_DefFreq) <>0 Then
                                      Begin
                                       Frequency:=MM_Default_Frequency;
                                       Default_Mask:=Default_Mask AND (NOT M_DefFreq);
                                      End;
                                   Dec(Frequency,200);
                                   volume_modifie:=True
                                  End
                           End;
                       End;

{      Left:    If freq>5000 Then Begin Dec(freq,200); defile:=True End;
      Right :  If freq<Get_MaxFreq(numero_sortie,T_SB,UtSte,DC) Then Begin Inc(freq,200); defile:=True End;					}
          Right: With Module[choix_fich] do
                  If (Numero>=1) and (Numero<Longueur_prog) Then
                   Begin
                    choix_fich:=Indice(Numero+1); CorrigePremier
                   End
                  Else
                   If Programme Then
                    Begin
                     choix_fich:=Indice(Longueur_prog); CorrigePremier
                    End
		   Else  { Increase individual module Frequency }
                     If Not(Repertoire(choix_fich)) Then
                      Begin
		               File_Display_Mode:=D_Freq; {Display Frequency}
                       With Module[choix_fich] do
                        If (Default_Mask AND M_NoFreq) = 0 Then { Adlib do nothing }
                         If (Default_Mask AND M_IMF) <> 0 Then
                           Begin { IMF 2 Frequency Choices }
                            If Frequency=280 then Frequency:=560
                             Else If Frequency=560 then Frequency:=700
		                      Else Frequency:=700;
				            volume_modifie:=True
			               End
                         Else
                          With MMSS_CFG^ do If Frequency<Get_MaxFreq(Wave_Output,MMType_SB,Utilise_Stereo,Utilise_DC) Then
                           Begin
                            If (Default_Mask AND M_DefFreq) <>0 Then
                               Begin
                                Frequency:=MM_Default_Frequency;
                                Default_Mask:=Default_Mask AND (NOT M_DefFreq);
                               End;
                            Inc(Frequency,200);
                            volume_modifie:=True
                           End
                      End;
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
          Del: If Not(Repertoire(choix_fich)) and (repert[1]<>LettreCDRom) Then
                change_rep:=EffaceModule(Module[choix_fich].Nom);
          F1: Aide;
          Enter: If TesteChoixEstModule Then ActiveLecture(False);
          Space: If TesteChoixEstModule Then ProgrammeModule;
          Tab: Begin
	        affiche_titre:=Not(affiche_titre);
		Inc(File_Display_Mode);
		If File_Display_Mode=3 then File_Display_Mode:=0
               End;
          Key('-'): If Not(Repertoire(choix_fich)) Then
                     Begin
                      affiche_titre:=False;
					  File_Display_Mode:=D_Volume; {Display Volume}
                      With Module[choix_fich] do
                       If Volume>5 Then
                        Begin
                         Dec(Volume,5); Default_Mask:=Default_Mask AND (NOT M_DefVol);
                         volume_modifie:=True
                        End
                     End;
          Key('+'): If Not(Repertoire(choix_fich)) Then
                     Begin
 {                     affiche_titre:=False;}
					  File_Display_Mode:=D_Volume; {Display Volume}
                      With Module[choix_fich] do
                       If Volume<750 Then { 100% = 500 }
                        Begin
                         Inc(Volume,5); Default_Mask:=Default_Mask AND (NOT M_DefVol);
                         volume_modifie:=True
                        End
                     End;
          CtrlEnter: If nbr_modules>0 Then
                      Begin
                       affiche_titre:=False;
                       For i:=premier_module to nbr_fich do
                        Module[i].Default_Mask:=Module[i].Default_Mask OR M_DefVol;
                       volume_modifie:=True
                      End;
          BDel: If Not(Repertoire(choix_fich)) Then
                 Begin
{                  affiche_titre:=False;}
                  If (File_Display_Mode)=D_Volume Then
				      With Module[choix_fich] do Default_Mask:=Default_Mask XOR M_DefVol
		     Else If (File_Display_Mode)=D_Freq Then
                                      With Module[choix_fich] do Default_Mask:=Default_Mask XOR M_DefFreq;
                  volume_modifie:=True
                 End;
		   Esc: quitte:=True
         End;
         If touche>255 Then touche:=0;
         If boutons[bt_Sortie].Appuye(Char(touche))    Then RegleSortie;
         If boutons[bt_Options].Appuye(Char(touche))   Then RegleOptions;
         If boutons[bt_IntroScan].Appuye(Char(touche)) Then FonctionIntroScan;
         If boutons[bt_Shuffle].Appuye(Char(touche))   Then FonctionShuffle;
         If boutons[bt_Lecture].Appuye(Char(touche))   Then ActiveLecture(True);
         If boutons[bt_Tout].Appuye(Char(touche))      Then ProgrammeTout;
         If boutons[bt_Efface].Appuye(Char(touche))    Then EffaceProgramme;
         If boutons[bt_Charge].Appuye(Char(touche))    Then
          Begin
           ChargeProgramme; AfficheBoutonsProgramme;
           If Programme Then
            Begin choix_fich:=Indice(1); CorrigePremier End
          End;
         If boutons[bt_Sauve].Appuye(Char(touche))  Then SauveProgramme;
         If boutons[bt_Aide].Appuye(Char(touche))   Then Aide;
         If boutons[bt_Quitte].Appuye(Char(touche)) Then quitte:=True
        End
       Else  {au moins une touche Shift est appuy�e}
        If (touche>=Key('A')) and (touche<=Key('Z')) and (nbr_modules>0) Then ChercheInitiale(Char(touche))
      End
     Else  {un bouton de la souris est cliqu�}
      Begin
       If (x in [3..x_asc-1]) and (y in [y_asc..y_asc+hauteur_fenetre-1]) Then
        If (premier+y-y_asc<=nbr_fich) Then
         Begin choix_clique:=True; choix_fich:=premier+y-y_asc End;
       If (x=x_asc) and (nbr_fich>hauteur_fenetre) Then
        Case y of
         y_asc: Begin defile_fenetre:=True; DefileHaut; DelaiBoutonSouris(10) End;
         y_asc+hauteur_fenetre-1: Begin defile_fenetre:=True; DefileBas; DelaiBoutonSouris(10) End;
         y_asc+1..y_asc+hauteur_fenetre-2:
                Begin
                 premier:=1+Round((y-y_asc-1)*(nbr_fich-hauteur_fenetre)/(hauteur_fenetre-3));
                 CorrigeChoix; bouge_ascenseur:=True
                End
        End;
       If (x in [x_asc+2..x_asc+5]) Then
        Begin
         For i:=1 to MinEntier(Length(liste_lecteurs),(hauteur_fenetre Div 2)+1) do
          If y=y_asc+2*(i-1) Then
           ChangeLecteur(liste_lecteurs[i]);
         Repeat Until BoutonSouris=aucun
        End;
       If choix_clique Then
        If y=y_asc-1 Then
         Begin
          defile_fenetre:=True; DefileHaut; Delay(15);
         End
        Else
         If y=y_asc+hauteur_fenetre Then
          Begin
           defile_fenetre:=True; DefileBas; Delay(15);
          End
         Else defile_fenetre:=False;
       If boutons[bt_Sortie].Clique    Then RegleSortie;
       If boutons[bt_Options].Clique   Then RegleOptions;
       If boutons[bt_IntroScan].Clique Then FonctionIntroScan;
       If boutons[bt_Shuffle].Clique   Then FonctionShuffle;
       If boutons[bt_Lecture].Clique   Then ActiveLecture(True);
       If boutons[bt_Tout].Clique      Then ProgrammeTout;
       If boutons[bt_Efface].Clique    Then EffaceProgramme;
       If boutons[bt_Charge].Clique    Then
        Begin
         ChargeProgramme; AfficheBoutonsProgramme;
         If Programme Then
          Begin choix_fich:=Indice(1); CorrigePremier End
        End;
       If boutons[bt_Sauve].Clique  Then SauveProgramme;
       If boutons[bt_Aide].Clique   Then Aide;
       If boutons[bt_Quitte].Clique Then quitte:=True
      End
    End
  Until change_rep or quitte
 Until quitte
End; {GestionInterface}

{==========================================================}

BEGIN

{$IFDEF MODMTINY}
 Writeln('Initializing '+Ident_Modm+' (Tiny : MMM Only)'+#13#10);
{$ELSE}
{$IFDEF MODMLITE}
 Writeln('Initializing '+Ident_Modm+' (Light : MMM, MOD, S3M, XM Only)'+#13#10);
{$ELSE}
 Writeln('Initializing '+Ident_Modm+' (Full)'+#13#10);
{$ENDIF}
{$ENDIF}

 MM_Hercule:=False;
 If Detect_Mono then
    Begin
     Writeln('Monochrome Display');
     MM_Hercule:=True;
     SetHerculeAddr;
    End;

 {If MaxAvail<MemoireMinimale Then
  Begin
   WriteLn('Not enough memory to run Mod Master.'); Halt(1)
  End;}

 If InitSouris Then Writeln('Mouse found');

 MMSS_Init(True,True); {Always place this first }

{ Writeln('Initialisation;',Maxavail);}
 Initialisation;
{ Writeln('LitFichierCFG;');}
 LitFichierCFG;
{ Writeln('InitCarteSonore;');}
 InitCarteSonore;
{ Writeln('AnalyseParametres;');}
 AnalyseParametres;

 If affiche_syntaxe Then AfficheSyntaxe
 Else
  Begin
{$IFNDEF ModeXT}
   VitesseClavier(0,0); {maximum}
{$ENDIF}
   If mode_interactif Then
    Begin
     Write('Speed test=');
	 Writeln(IndicePerformance);
     Writeln('Press any Key');
     erreur_fin:=0;
     Repeat
	  erreur_fin:=erreur_fin+1;
      Delay(50)
     Until (KeyPressed) or (erreur_fin=200);

     InitModeTexte;
     InitSouris;
     AffCursSouris;
	 
     AfficheEcran;
     AfficheReglages;

     GestionInterface;
	 
     If volume_modifie Then SauveFichierDIR;
     Inittexte;

    End
   Else 
    Begin
	 ChercheFichiers; {Mode non interactif ->Charger musique}
	 InitTexte
	End;

   EcritFichierCFG;
{$IFNDEF ModeXT}
   VitesseClavier(1,3); {normale}
   
   AffichePageFin;
{$ENDIF}
   Halt(erreur_fin)
  End
END.