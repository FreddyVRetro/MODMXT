{************************************************************************}
{                                MM_AFF.PAS                              }
{                                                                        }
{  unit� pour Mod Master: routines d'affichages                          }
{                                                                        }
{  AUTEURS: Fabrice Couteau et Freddy V�tel�.                            }
{                                                                        }
{                                                                        }
{                               D�but d'�criture le --/--/93             }
{                               Derni�res modifications le 19/10/95      }
{************************************************************************}
UNIT MM_AFF;

{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

INTERFACE

USES Souris,SourisC;

{$I Types}

{==========================================================}

PROCEDURE AfficheBoutonsOKAnnuler(x,y: Byte; Var boutonOK,boutonAnnuler: Bouton);
PROCEDURE AfficheEcran;
PROCEDURE AfficheReglages;

PROCEDURE AfficheErreur(chaine1,chaine2: String25;Offset:Byte);
PROCEDURE AfficheErreurLecteurPasPret(liste_lecteurs: String80; lecteur_courant: Char; Var nouveau_lecteur: Char);
PROCEDURE AfficheErreurLecture;
PROCEDURE AfficheBoutonsProgramme;

FUNCTION  EffaceModule(nom_module: String12): Boolean;

PROCEDURE RegleSortie;
PROCEDURE RegleOptions;

PROCEDURE Aide;

{==========================================================}

IMPLEMENTATION


USES Crt,Dos,VARUnit,Fichiers,Clavier,Util,UtilC,Texte,
     Memoire,MMSS_CMD,MMSS_Var,MM_VAR,MM_DIV,SBUnit,TDYUnit,GUSUnit;

CONST MonoStereo: Array[0..1] of String[6]
       =('Mono','Stereo');

VAR {variables pour l'economiseur}
    teste_touche,touche_appuyee: Boolean;
    anc_INT09h: Pointer;

{==========================================================}

PROCEDURE AfficheBoutonsOKAnnuler(x,y: Byte; Var boutonOK,boutonAnnuler: Bouton);
Begin
 boutonOK.Definit(0,x,y,' OK ',241,243,0,0);
 boutonAnnuler.Definit(0,x+9,y,' Cancel ',112,120,0,0);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 boutonOK.Affiche; boutonAnnuler.Affiche;
End; {AfficheBoutonsOKAnnuler}

{----------------------------------------------------------}

PROCEDURE AfficheEcran;

Type t_donnees_bt=Record
                   x,y,attr_relache,attr_appuye,attr_lettre: Byte
                  End;

Const Titre_bouton_txt: Array[1..nbr_boutons] of String[11]
       =('Ou^t^put','^O^ptions','^I^ntroScan','^S^huffle',' ^P^lay  ','  ^A^ll  ',
          ' ^C^lear ',' ^L^oad ',' Sa^v^e ',' ^H^elp ',' ^E^xit ');
{$IFNDEF CGAOnly}
      Donnees_bt: Array[1..nbr_boutons] of t_donnees_bt
       =((x:56;y: 9;attr_relache:176;attr_appuye:184;attr_lettre:180),  {Sortie}
         (x:67;y: 9;attr_relache:208;attr_appuye:216;attr_lettre:212),  {Options}
         (x:55;y:12;attr_relache: 32;attr_appuye: 40;attr_lettre: 36),  {IntroScan}
         (x:68;y:12;attr_relache: 32;attr_appuye: 40;attr_lettre: 36),  {Shuffle}
         (x:56;y:17;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Lecture}
         (x:56;y:19;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Tout}
         (x:56;y:21;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Efface}
         (x:68;y:18;attr_relache:240;attr_appuye:248;attr_lettre:244),  {Charge}
         (x:68;y:20;attr_relache:240;attr_appuye:248;attr_lettre:244),  {Sauve}
         (x:56;y:25;attr_relache: 71;attr_appuye: 72;attr_lettre: 79),  {Aide}
         (x:68;y:25;attr_relache:192;attr_appuye:200;attr_lettre:207)); {Quitte}
{$ELSE}
      Donnees_bt: Array[1..nbr_boutons] of t_donnees_bt
       =((x:56;y: 9;attr_relache:176;attr_appuye:184;attr_lettre:180),  {Sortie}
         (x:67;y: 9;attr_relache:208;attr_appuye:216;attr_lettre:212),  {Options}
         (x:55;y:12;attr_relache: 32;attr_appuye: 40;attr_lettre: 36),  {IntroScan}
         (x:68;y:12;attr_relache: 32;attr_appuye: 40;attr_lettre: 36),  {Shuffle}
         (x:56;y:15;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Lecture}
         (x:56;y:17;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Tout}
         (x:56;y:19;attr_relache:224;attr_appuye:232;attr_lettre:228),  {Efface}
         (x:68;y:17;attr_relache:240;attr_appuye:248;attr_lettre:244),  {Charge}
         (x:68;y:19;attr_relache:240;attr_appuye:248;attr_lettre:244),  {Sauve}
         (x:56;y:22;attr_relache: 71;attr_appuye: 72;attr_lettre: 79),  {Aide}
         (x:68;y:22;attr_relache:192;attr_appuye:200;attr_lettre:207)); {Quitte}
{$ENDIF}
         {Reglages_txt: Array[langues] of String[8]=('Settings','Reglages');}

         {Programme_txt: String[7]='Program';}

Var i: Byte;

Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
{$IFNDEF CGAOnly}
 palette_noire.Fixe;
{$ENDIF}
 EffacePage(0,11);

 For i:=1 to nbr_boutons do
  With Donnees_bt[i] do
   boutons[i].Definit(0,x,y,' '+Titre_bouton_txt[i]+' ',
                         attr_relache,attr_appuye,attr_lettre,128);
 EffaceZone(0,1,1,80,1,31);
 AffChXY(0,30,1,'- MOD MASTER XT v1.02 -',31);
 
 {fenetre modules}
{$IFNDEF CGAOnly}
 EffaceZoneCoins(1,3,50,26,49);
 Cadre(0,1,2,3,49,26,49,'',0,'');
 AffCarXY(0,50,26,#227,56);
 {$ELSE}
 EffaceZoneCoins(2,3,50,23,49);
 Cadre(0,1,3,3,49,23,49,'',0,'');
 {$ENDIF}

{$IFNDEF CGAOnly}
  {ombre horizontale fenetre modules}
  AffCarXY(0, 2,27,#236,8);
  AffChXY(0,3,27,RepeteCar(chr(220),50-3+1),128);
  AffCarXY(0,51,27,#237,8);
  {ombre verticale fenetre modules}
  AffCarXY(0,51, 3,#231,8);
 For i:=4 to 26 do AffCarXY(0,51,i,' ',128); 
{$ELSE}
 {ombre horizontale fenetre modules}
 AffChXY(0,3,24,RepeteCar(chr(220),50-3+2),128);
 {ombre verticale fenetre modules}
 For i:=4 to 23 do AffCarXY(0,51,i,' ',128); 
 {$ENDIF}

 {$IFNDEF CGAOnly}      { VGA 28 Lines}
 {fenetre boutons}
 EffaceZoneCoins(53,3,79,26,154);
 Cadre(0,1,54,3,78,11,154,' Settings ',154,'');
 Cadre(0,1,55,4,77,8,144,'',144,'');
 Cadre(0,1,54,16,78,23,154,' '+Programme_txt+' ',154,'');
 AffCarXY(0,79,26,#227,152);
 {ombre horizontale fenetre boutons}
 AffCarXY(0,54,27,#236,8);
 AffChXY(0,55,27,RepeteCar(chr(220),79-55+1),128);
 AffCarXY(0,80,27,#237,8);
 {ombre verticale fenetre boutons}
 AffCarXY(0,80, 3,#231,8);
 For i:=4 to 26 do AffCarXY(0,80,i,' ',128);
{$ELSE}                  { CGA 25 Lines }
 {fenetre boutons}
 EffaceZoneCoins(53,3,79,23,154);
 Cadre(0,1,54,3,78,11,154,' Settings ',154,'');
 Cadre(0,1,55,4,77,8,144,'',144,'');
 Cadre(0,1,54,14,78,21,154,' Program ',154,'');
 {ombre horizontale fenetre boutons}
 AffChXY(0,55,24,RepeteCar(chr(220),79-55+2),128);
 {ombre verticale fenetre boutons}
 For i:=4 to 23 do AffCarXY(0,80,i,' ',128); 
 {$ENDIF}
 
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 boutons[bt_Sortie].Affiche;
 boutons[bt_Options].Affiche;
 boutons[bt_Aide].Affiche;
 boutons[bt_Quitte].Affiche
End; {AfficheEcran}

{----------------------------------------------------------}

PROCEDURE AfficheReglages;
Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
 EffaceZone(0,56,5,76,7,154);

 {points s�parateurs}
 AffCarXY(0,67,6,'-',154);
 AffCarXY(0,64,7,'-',154);
 AffCarXY(0,70,7,'-',154);

 If EMS_Presente Then AffChXY(0,66,7,'EMS',155);
 If MMSS_Use_UMB Then AffChXY(0,72,7,'UMB',155);

 With MMSS_CFG^ do
  Begin
  
   If MMSS_CFG^.Wave_Output in [SB,SBPro]
	      then
		   AffChXY(0,66-(Length(SBName[SBConfig.Type_]) Div 2),5,
                         SBName[SBConfig.Type_],159)
          else 
           AffChXY(0,66-(Length(MMSS_Output_Name[Wave_Output]) Div 2),5,
                         MMSS_Output_Name[Wave_Output],159);
  

   {fr�quence}
   Case Wave_Output of
    HPint,
    LPT1,
    LPT2,
    C_DAC,
    TDY_DAC,
    SB,
    SBPro: AffChXY(0,58,6,EntierTexte(MM_Default_Frequency,5)+' Hz',158);
    GUS: AffChXY(0,58,6,'44100 Hz',158)
   End;

   {mono/st�r�o}
   Case Wave_Output of
    HPint,
    LPT1,
    LPT2,
    C_DAC,
    TDY_DAC,
    SB: AffChXY(0,69,6,MonoStereo[0],158);
    SBPro: AffChXY(0,69,6,MonoStereo[Byte(Utilise_Stereo)],158);
    GUS: AffChXY(0,69,6,MonoStereo[1],158)
   End;

   AffChXY(0,58,7,EntierTexte(MM_Default_Volume Div 5,3)+' %',155)
  End;
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
End; {AfficheReglages}

{----------------------------------------------------------}

PROCEDURE AfficheErreur(chaine1,chaine2: String25;Offset:Byte);

Var z: Zone;
    boutonOK: Bouton;
    sortie: Boolean;
    x,y: Byte;

Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
 OmbreZoneCoins(25,10,55,16,z,71);
 Cadre(0,1,26,10,54,16,71,' Error ',78,'');
 AffChXY(0,28+Offset,11,chaine1,79);
 AffChXY(0,28+Offset,12,chaine2,79);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 With boutonOK do Begin Definit(0,38,14,' OK ',97,99,0,0); Affiche End;
 Repeat
  AttendClavierSouris(True,False,x,y);
  If KeyPressed Then sortie:=(ReadKey=Enter)
                Else sortie:=boutonOK.Clique
 Until sortie;
 RestaureZoneSuppr(0,z)
End; {AfficheErreur}

{----------------------------------------------------------}

PROCEDURE AfficheErreurLecteurPasPret(liste_lecteurs: String80; lecteur_courant: Char; Var nouveau_lecteur: Char);
{Const x: Array[langues] of Byte=(32,29);
      xc: Array[langues] of Byte=(45,48);}
Var msg: String25;
    z: Zone;
    touche: Key;
    sortie: Boolean;
    code_message: Byte;
Begin
 msg:=Erreurs[lecteur_txt]+' '+repert[1]+': '+Erreurs[pas_pret_txt];
 If liste_lecteurs='' Then
  Begin {reste sur le meme lecteur}
   If repert[1]=LettreCDRom Then code_message:=inserez_CDRom_txt
                            Else code_message:=inserez_disq_txt;
   AfficheErreur(msg,Erreurs[code_message],0)
  End
 Else {demande la lettre du nouveau lecteur}
  Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
   OmbreZoneCoins(26,11,53,15,z,71);
   Cadre(0,1,27,11,52,15,71,' '+msg+' ',78,'');
   AffChXY2(0,29,13,Erreurs[nouveau_lecteur_txt]+'?  ^�'+lecteur_courant+':�^',79,228);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
   nouveau_lecteur:=lecteur_courant;
   GotoXY(48,13);
   Curseur(plat);
   sortie:=False;
   Repeat
    touche:=UpCase(ReadKey);
    Case touche of
     Key('A')..Key('Z'): If Pos(Char(touche),liste_lecteurs)>0 Then
                          Begin nouveau_lecteur:=Char(touche); sortie:=True End
    End
   Until sortie;
   If Cursor_On Then Curseur(Rect) else Curseur(Off);
   RestaureZoneSuppr(0,z)
  End
End; {AfficheErreurLecteurPasPret}

{----------------------------------------------------------}

PROCEDURE AfficheErreurLecture;
Begin
 AfficheErreur(Erreurs[err_lecture_txt],Erreurs[changez_disq_txt],0)
End; {AfficheErreurLecture}

{----------------------------------------------------------}

PROCEDURE AfficheBoutonsProgramme;
Var i: Byte;
Begin
 For i:=1 to 3 do  {boutons 5,7,9: Lecture, Tout, Sauve}
  With boutons[3+2*i] do Begin Active(Programme); Affiche End
End; {AfficheBoutonsProgramme}

{----------------------------------------------------------}

FUNCTION EffaceModule(nom_module: String12): Boolean;

Var z: Zone;
    boutonOui,boutonNon: Bouton;
    nouveau_lecteur: Char;
    sortie,efface: Boolean;
    x,y: Byte;
    touche: Key;

Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
 OmbreZoneCoins(26,10,54,15,z,71);
 Cadre(0,1,27,10,53,15,71,' Warning ',78,'');
 AffChXY(0,30,11,'Delete '+nom_module+' ?',70);
 LigneHorizBouts(12,27,53,71);
 boutonOui.Definit(0,32,13,' ^Y^es ',252,248,249,128);
 boutonNon.Definit(0,44,13,' ^N^o  ',207,200,206,128);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 boutonOui.Affiche; boutonNon.Affiche;

 Repeat
  AttendClavierSouris(True,False,x,y);
  If KeyPressed Then
   Begin
    touche:=ReadKey;
    efface:=boutonOui.Appuye(Char(touche));
    sortie:=boutonNon.Appuye(Char(touche)) or (touche=Esc)
   End
  Else
   Begin
    efface:=boutonOui.Clique;
    sortie:=boutonNon.Clique
   End
 Until sortie or efface;

 If efface Then
  Begin
   Repeat
    EffaceFichier(repert+nom_module);
    Case f_erreur of
     f_err_CRC,
     f_err_donnees,
     f_err_media,
     f_err_secteur : AfficheErreur(Erreurs[err_ecriture_txt],Erreurs[changez_disq_txt],0);
     f_err_protect : AfficheErreur(Erreurs[disq_protegee_txt],Erreurs[en_ecriture_txt],0);
     f_err_pas_pret: AfficheErreurLecteurPasPret('','C',nouveau_lecteur);  {reste sur le m�me lecteur}
     f_err_acces_ref : AfficheErreur(Erreurs[Fichier_Protege_txt],Erreurs[en_ecriture_txt],0);
    End
   Until Not(f_erreur in [f_err_protect,f_err_pas_pret]);
   EffaceModule:=(f_erreur=f_ok)
  End
 Else EffaceModule:=False;

 RestaureZoneSuppr(0,z)
End; {EffaceModule}

{----------------------------------------------------------}

PROCEDURE AfficheCase(x,y: Byte; active: Boolean);
Begin
 If Active then AffChXY(0,x,y,'[X]',29)
           else 
 AffChXY(0,x,y,'[ ]',29)
End; {AfficheCase}

{----------------------------------------------------------}

PROCEDURE AfficheFleches(x,y: Byte);
Begin
 AffChXY2(0,x  ,y,' ^^ ',177,176);
 AffChXY2(0,x+4,y,' ^^ ',177,176)
End; {AfficheFleches}

{----------------------------------------------------------}

PROCEDURE RegleSortie;

Const CouleurSortie: Array[Boolean] of Byte=(24,23);

      Title_Output: Array[1..2] of String[16]
       = (' ^Wave^ / Synth ',' Wave / ^Synth^ ');

      { Wave Output windows size }
	  xd_fen: Array[0..MMSS_Out_Nb_W-1] of Byte    =(73,73,73, 73,73,73,76,73);
      HauteurFen: Array[0..MMSS_Out_Nb_W-1] of Byte=( 3, 3, 3,  3, 3, 5,10, 5);
{                                                   ^  ^  ^ ^    ^  ^  ^  ^
                                             HP int��  �  � TDY  �  �  �  ��GUS
                                                  CNA1��  �     DCAC�  ��SBPro
                                                     CNA2��         ��SB        }

      { Synth Output windows size }
      xd_fen_s: Array[0..MMSS_Out_Nb_S-1] of Byte    =(70,70,69,69);
      HauteurFen_S: Array[0..MMSS_Out_Nb_S-1] of Byte=( 4, 4, 4, 4);
	  
	  x_OPL_Model: Array[0..2] of Byte    =(41,50,59);
 	  x_TDY_Type: Array[0..2] of Byte    =(41,50,58); {,66);}
	  x_CMS_Type: Array[0..2] of Byte    =(41,50,58); {,66);}
    Lpt_txt: Array[0..4] of String[4]=('None','LPT1','LPT2','LPT3','LPT4');

      xDMA: Array[SB..SBPro] of Byte=(41,42);
      xIRQ: Array[SB..SBPro] of Byte=(49,54);

      xDMA_opt: Array[SB..SBPro] of Byte=(45,47);
      xIRQ_opt: Array[SB..SBPro] of Byte=(53,59);

      Sortie_txt: Array[1..5] of String[10]=
                   ('Frequency','Filter','Mixing','Left vol.'  ,'Right vol.' );

Var z,zone2,zone_ligne,zone_ombre_ligne: Zone;
    Out_Type : Byte;  { 1: Wave 2: Synth }
    boutonOK,boutonAnnuler: Bouton;
    touche: Key;
    x,y,i,Out_Nb_W,Out_Nb_S,anc_num_sortie: Byte;
    defile,attends_relache,ok,sortie: Boolean;
    freq: Word;
    DMA,IRQ,volL,volR,pannG,pannD,MixGUS,t_SB: Byte;
    UtDMA,UtFilt,UtSte,UtMix,DC: Boolean;
    iWave,GLineIn : Boolean;

Procedure AfficheSortieSonore(numero,couleur: Byte);
Begin
    AffChXY(0,9,8+numero,' '+XString(MMSS_Output_Name[numero],' ',22),couleur);
    if (numero=LPT1) then
      AffChXY(0,25,8+numero,'('+EntierHexa(MMSS_CFG^.LPT1_Port,3)+'h)',couleur);
    if (numero=LPT2) and MMSS_W_Output_Available[LPT2] then
      AffChXY(0,25,8+numero,'('+EntierHexa(MMSS_CFG^.LPT2_Port,3)+'h)',couleur);
    if (numero=C_DAC) and MMSS_W_Output_Available[C_DAC] then
      AffChXY(0,25,8+numero,'('+EntierHexa(MMSS_CFG^.CDAC_Port,3)+'h)',couleur);
    if (numero=TDY_DAC) and MMSS_W_Output_Available[TDY_DAC] then
      AffChXY(0,25,8+numero,'('+EntierHexa(TDY_DACPort,3)+'h)',couleur)
End; {AfficheSortieSonore}

Procedure AfficheCurseur(x,y,longueur,position: Byte);
Begin
 AffChXY(0,x,y,RepeteCar(#246,longueur),16);
 AffCarXY(0,x+position,y,#9,29)
End; {AfficheCurseur}

{ Display a Wave Output values }
Procedure Display_Wave;
Var i:Byte;
Begin

If anc_num_sortie<=MMSS_Out_Nb_W Then
     Begin
      With zone_ligne do Begin Restaure(0,0,0,0); Supprime End;
      With zone2 do Begin Restaure(0,0,0,0); Supprime End
     End;
    OmbreZoneCoins(38,Out_Nb_W+7,xd_fen[Out_Nb_W],Out_Nb_W+7+HauteurFen[Out_Nb_W]-1,zone2,19);
    Cadre(0,1,39,Out_Nb_W+7,xd_fen[Out_Nb_W]-1,Out_Nb_W+7+HauteurFen[Out_Nb_W]-1,19,'',0,'');
    zone_ligne.Sauve(0,32,Out_Nb_W+8,37,Out_Nb_W+9);
    zone_ombre_ligne.Sauve(0,34,Out_Nb_W+9,37,Out_Nb_W+9);
    With zone_ombre_ligne do Begin Restaure(0,0,0,8); Supprime End;
    If CodeXY(0,38,Out_Nb_W+9)=226 Then AffCarXY(0,38,Out_Nb_W+9,#226,16);
    LigneHorizBouts(Out_Nb_W+8,32,39,19); {ligne de liaison}

    If Out_Nb_W<>GUS Then { Frequency is displayed for all except GUS }
     Begin
      AffChXY(0,41,Out_Nb_W+8,Sortie_txt[1],23); {Frequency}
      AfficheFleches(64,Out_Nb_W+8)
     End;

    If (Out_Nb_W in [SB,SBPro]) Then
     Begin
      AffChXY2(0,xDMA[Out_Nb_W],Out_Nb_W+10,'^D^MA',23,31);
      AffChXY2(0,xIRQ[Out_Nb_W],Out_Nb_W+10,'^I^RQ',23,31);
     End;

    {trac� des lignes}
    Case Out_Nb_W of
     SB   : Begin
             AffChXY(0,58,Out_Nb_W+10,'DC',23);
             AffCarXY(0,66,Out_Nb_W+10,'V',23);
             LigneHorizBouts(Out_Nb_W+9,39,xd_fen[Out_Nb_W]-1,19);
             LigneVerticBouts(47,Out_Nb_W+9,Out_Nb_W+11,19);
             LigneVerticBouts(56,Out_Nb_W+9,Out_Nb_W+11,19);
             LigneVerticBouts(64,Out_Nb_W+9,Out_Nb_W+11,19)
            End;
     SBPro: Begin
             For i:=1 to 3 do
             LigneHorizBouts(Out_Nb_W+7+2*i,39,xd_fen[Out_Nb_W]-1,19);
             LigneVerticBouts(51,Out_Nb_W+ 9,Out_Nb_W+13,19);
             LigneVerticBouts(63,Out_Nb_W+ 9,Out_Nb_W+13,19);
             AffCarXY(0,51,Out_Nb_W+11,chr(197),19);
             AffCarXY(0,63,Out_Nb_W+11,chr(197),19);
			 
			 AffChXY(0,50,Out_Nb_W+7,SBName[SBConfig.Type_],19);
			 
             AffChXY2(0,41,Out_Nb_W+12,'^S^tereo',23,31); {Stereo}
           {  AffChXY(0,53,Out_Nb_W+12,Sortie_txt[3],23); }{Mixage}
             AffChXY(0,65,Out_Nb_W+12,Sortie_txt[2],23); {Filter}
             AffChXY(0,41,Out_Nb_W+14,Sortie_txt[4],23); {Vol. gauche}
             AffChXY(0,41,Out_Nb_W+15,Sortie_txt[5],23); {Vol. droite}
	 
             AffCarXY(0,54,Out_Nb_W+14,'-',31);
             AffCarXY(0,73,Out_Nb_W+14,'+',31);

             AffCarXY(0,54,Out_Nb_W+15,'-',31);
             AffCarXY(0,73,Out_Nb_W+15,'+',31)
            End;
     GUS  : Begin
			 AffChXY(0,48,Out_Nb_W+7,' Memory: '+EntierTexte(Taille_GUS,4)+'Kb ',19);
             LigneHorizBouts(Out_Nb_W+9,39,xd_fen[Out_Nb_W]-1,19);
			 AffChXY2(0,42,Out_Nb_W+8,'^I^nterWave',23,31);
             AffChXY2(0,58,Out_Nb_W+8,'^L^ine In',23,31);

             AffChXY(0,41,Out_Nb_W+10,Sortie_txt[3],23); {Mixage}
			 
             AffChXY(0,50,Out_Nb_W+10,MonoStereo[0],22); {Mono}
             AffChXY(0,65,Out_Nb_W+10,MonoStereo[1],22); {Stereo}
            End
    End;
End;

{ Display a Synth Output values }
Procedure Display_Synth;
Var i:Byte;
Begin

If anc_num_sortie<=MMSS_Out_Nb_W Then
     Begin
      With zone_ligne do Begin Restaure(0,0,0,0); Supprime End;
      With zone2 do Begin Restaure(0,0,0,0); Supprime End
     End;

OmbreZoneCoins(38,Out_Nb_S+7,xd_fen_s[Out_Nb_S],Out_Nb_S+7+HauteurFen_s[Out_Nb_S]-1,zone2,19);
Cadre(0,1,39,Out_Nb_S+7,xd_fen_s[Out_Nb_S]-1,Out_Nb_S+7+HauteurFen_s[Out_Nb_S]-1,19,'',0,'Space/Right/Left');
zone_ligne.Sauve(0,32,Out_Nb_S+8,37,Out_Nb_S+9);
zone_ombre_ligne.Sauve(0,34,Out_Nb_S+9,37,Out_Nb_S+9);
With zone_ombre_ligne do Begin Restaure(0,0,0,8); Supprime End;
If CodeXY(0,38,Out_Nb_S+9)=226 Then AffCarXY(0,38,Out_Nb_S+9,#226,16);
LigneHorizBouts(Out_Nb_S+8,32,39,19); {ligne de liaison}

    Case Out_Nb_S of
     OPL,OPLLPT : Begin
	               AffChXY(0,45,Out_Nb_S+8,'None     OPL2     OPL3',23);
                   AffChXY(0,41,Out_Nb_S+9,'Port:',23);
                  End;
     TDY,CMS : Begin { TDYLPT 'is' CMS }
	       { AffChXY(0,45,Out_Nb_S+8,'None     Int     LPT     Emul',23);}
             AffChXY(0,45,Out_Nb_S+8,'None     Int     LPT',23);
           { If TDY_Type=3 then AffChXY(0,41,Out_Nb_S+9,'Emul:',23) 
	           Else } 
			    AffChXY(0,41,Out_Nb_S+9,'Port:',23);
           End;
    End;
End;

Procedure Display_Update_Wave;
Begin

  If Out_Nb_W<>GUS Then
   AffChXY(0,53,Out_Nb_W+8,EntierTexte(freq,5)+' Hz',29);

  If (Out_Nb_W in [SB,SBPro]) Then
   Begin
    AffChXY(0,xDMA_opt[Out_Nb_W],Out_Nb_W+10,EntierTexte(DMA,1),29);
    AffChXY(0,xIRQ_opt[Out_Nb_W],Out_Nb_W+10,EntierTexte(IRQ,2),29);
   End;

  Case Out_Nb_W of
   SB   : Begin
           AfficheCase(58,Out_Nb_W+10,DC);
           AffChXY(0,68,Out_Nb_W+10,EntierTexte(MinEntier(t_SB,2),1)+'.x',29)
		  End;
   SBPro: Begin
           AfficheCase(48,Out_Nb_W+12,UtSte);
           {AfficheCase(60,Out_Nb_W+12,UtMix);}
           AfficheCase(72,Out_Nb_W+12,UtFilt);
           AfficheCurseur(56,Out_Nb_W+14,16,volL);
           AfficheCurseur(56,Out_Nb_W+15,16,volR)
          End;
   GUS  : Begin
           AfficheCase(52,Out_Nb_W+8,iWave);        { Interwave Selection }
		   AfficheCase(66,Out_Nb_W+8,GLineIn);     { Line in selection }
           AfficheCurseur(55,Out_Nb_W+10,9,MixGUS)
		  End;
  End;
End;

Procedure Display_Update_Synth;
Var i:Byte;
    chlpt: String[4];
Begin
    Case Out_Nb_S of
     OPL   : Begin
              For i:=0 to 2 do
                  If OPL_Model=i then AfficheCase(x_OPL_Model[i],Out_Nb_S+8,True)
                     Else AfficheCase(x_OPL_Model[i],Out_Nb_S+8,False);
			 AffChXY(0,47,9,EntierHexa(OPL_Base,3)+'h',23);
             End;
     OPLLPT: Begin
              For i:=0 to 2 do
                  If OPL_LPT_Model=i then AfficheCase(x_OPL_Model[i],Out_Nb_S+8,True)
                     Else AfficheCase(x_OPL_Model[i],Out_Nb_S+8,False);
			 AffChXY(0,47,10,Lpt_txt[OPL_LPT_Nb],29);
             End;
     TDY    : Begin
              For i:=0 to 2 do {No, Int, LPT}
                  If TDY_Type=i then AfficheCase(x_TDY_Type[i],Out_Nb_S+8,True)
                      Else AfficheCase(x_TDY_Type[i],Out_Nb_S+8,False);
                  If TDY_Type=2 then AffChXY(0,47,11,Lpt_txt[TDY_LPT_Nb],29)
                      Else AffChXY(0,47,11,EntierHexa(TDY_PortList[TDY_PortNb],3)+'h',29);
              End;
     CMS    : Begin
              For i:=0 to 2 do {No, Int, LPT}
                  If CMS_Type=i then AfficheCase(x_TDY_Type[i],Out_Nb_S+8,True)  { Same position as Tandy }
                      Else AfficheCase(x_TDY_Type[i],Out_Nb_S+8,False);
                  If CMS_Type=2 then AffChXY(0,47,12,Lpt_txt[CMS_LPT_Nb],29)
                      Else AffChXY(0,47,12,EntierHexa(CMS_PortList[CMS_PortNb],3)+'h',29);
              End;			  
     PSG    : Begin
              For i:=0 to 1 do {No, Int}
                  If CMS_Type=i then AfficheCase(x_TDY_Type[i],Out_Nb_S+8,True)  { Same position as Tandy }
                      Else AfficheCase(x_TDY_Type[i],Out_Nb_S+8,False);
              End;
    End;
End;

Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
 Out_Type:=1;
 OmbreZoneCoins(7,7,33,21,z,19);
 Cadre(0,1,8,7,32,21,19,'',0,'Enter/Esc/Tab');
 LigneHorizBouts(18,8,32,19);
 AfficheBoutonsOKAnnuler(12,19,boutonOK,boutonAnnuler);

 Out_Nb_S:=0;

 {cherche les valeurs actuelles}
 With MMSS_CFG^do
  Begin
   Out_Nb_W:=Wave_Output;
   freq:=MM_Default_Frequency;
   DMA:=DMA_SB8; IRQ:=IRQ_SB;
   UtFilt:=Utilise_Filtre;
   UtSte:=Utilise_Stereo;
   UtMix:=Utilise_Mixage;
   DC:=Utilise_DC;
   t_SB:=MMType_SB;
   iWave:=GUS_InterWave;
   GLineIn:=GUS_LineIn;
  End;
 UtDMA:=(Out_Nb_W in [SB,SBPro]);
 volL:=SB_LeftVol; volR:=SB_RightVol;
 pannG:=MMSS_Def_LeftPan; pannD:=MMSS_Def_RightPan;
 MixGUS:=8-(pannG Div 8);

 anc_num_sortie:=MMSS_Out_Nb_W+1; {pour forcer affichage zone2 et ligne}
 defile:=False;
 Repeat
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
  AffChXY2(0,14,7,Title_Output[Out_Type],19,27); { Display the Window Title }
  
  If (Out_Type=1) then { Display Wave }
    Begin
	
    For i:=0 to MMSS_Out_Nb_W-1 do
        If (i<>Out_Nb_W) Then AfficheSortieSonore(i,CouleurSortie[MMSS_W_Output_Available[i]]);
    AfficheSortieSonore(Out_Nb_W,105);
	
     If Out_Nb_W<>anc_num_sortie Then
      Begin
       Display_Wave;
       anc_num_sortie:=Out_Nb_W
      End; { If Output is changed }
     { Displayed all the time }
     CorrigeParametres(Out_Nb_W,T_SB,freq,UtDMA,UtSte,UtMix,UtFilt,DC,IRQ);
     Display_Update_Wave;
    End
   Else { Display Synth }
    Begin

    { Display the Output name }
    For i:=0 to MMSS_Out_Nb_S-1 do
        AffChXY(0,9,8+i,' '+XString(MMSS_S_Output_Name[i],' ',22),23);
    AffChXY(0,9,8+Out_Nb_S,' '+XString(MMSS_S_Output_Name[Out_Nb_S],' ',22),105);
	
     If Out_Nb_S<>anc_num_sortie Then
      Begin
       Display_Synth;
       anc_num_sortie:=Out_Nb_S
      End; { If Output is changed }
     Display_Update_Synth;
    End;

  AttendClavierSouris(Not defile,False,x,y);
  defile:=False;
  attends_relache:=False;
  If KeyPressed Then
   Begin
    touche:=ReadKey;
    ok:=(touche=Enter);
    sortie:=(touche=Esc);
	If touche=Tab then { Change between Wave and Synth Output display }
	 Begin
      EffaceZone(0,9,8,31,17,19);
	 If (Out_Type=1) then
        Begin
         Out_Type:=2;
         anc_num_sortie:=Out_Nb_S+1; { Force the Redraw }
        End
       Else
        Begin
         Out_Type:=1;
         anc_num_sortie:=Out_Nb_W+1; { Force the Redraw }
        End;
     End;

    If (Out_Type=1) then { Wave Output Keys }
    Case touche of
     Up  : If Out_Nb_W>0 Then
            Begin
             i:=Out_Nb_W-1;
             While Not(MMSS_W_Output_Available[i]) and (i>0) do Dec(i);
             If MMSS_W_Output_Available[i] Then Out_Nb_W:=i
            End;
     Down: If Out_Nb_W<MMSS_Out_Nb_W-1 Then
            Begin
             i:=Out_Nb_W+1;
             While Not(MMSS_W_Output_Available[i]) and (i<MMSS_Out_Nb_W-1) do Inc(i);
             If MMSS_W_Output_Available[i] Then Out_Nb_W:=i
            End;
     PgUp,Home: Begin
                 i:=0;
                 While Not(MMSS_W_Output_Available[i]) do Inc(i);
                 Out_Nb_W:=i
                End;
     PgDn,End_: Begin
                 i:=MMSS_Out_Nb_W-1;
                 While Not(MMSS_W_Output_Available[i]) do Dec(i);
                 Out_Nb_W:=i
                End;
      Left  :  If (freq>5000) Then
                  Begin Dec(freq,200); defile:=True End;
      Right :  If (freq<Get_MaxFreq(Out_Nb_W,T_SB,UtSte,DC)) Then
                  Begin Inc(freq,200); defile:=True End;
      Space :  Begin
                If Out_Nb_W=GUS Then iWave:=Not(iWave)
	           Else If Out_Nb_W=SB then DC:=Not(DC)
               End;
      68,100 :  Case DMA of {D}
                  0 : DMA:=1;
                  1 : DMA:=3;
                  3 : DMA:=0
                 End;
      83,115 : If Out_Nb_W=SBPro then {S}
	              Begin
                   UtSte:=Not(UtSte);
                   If Not(UtSte) Then UtMix:=False;
                  End;	 
      73,105 : If (Out_Nb_W=SBPro) or (Out_Nb_W=SB) Then {I}
	           Case IRQ of
                2 : IRQ:=5;
                5 : IRQ:=7;
                7 : If Out_Nb_W=SBPro Then IRQ:=10 Else IRQ:=2;
                10: IRQ:=2
               End
			   Else If Out_Nb_W=GUS Then iWave:=Not(iWave);
	  76,108 : If Out_Nb_W=GUS Then GLineIn:=Not(GLineIn);
	  70,102 : If Out_Nb_W=SBPro Then 
	              Begin
                   UtFilt:=Not(UtFilt);
                   attends_relache:=True
                  End
    End; { Case Key Wave}

    If (Out_Type=2) then { Synth Output Keys }
    Begin
    Case touche of
      Up  : If Out_Nb_S>0 Then Out_Nb_S:=Out_Nb_S-1;
      Down: If Out_Nb_S<MMSS_Out_Nb_S-1 Then Out_Nb_S:=Out_Nb_S+1;
      PgUp,Home: Out_Nb_S:=0;
      PgDn,End_: Out_Nb_S:=MMSS_Out_Nb_S-1;

      Right : Case Out_Nb_S of 
               OPL    : If OPL_Model<2 then INC(OPL_Model);
               OPLLPT : If (OPL_LPT_Model<2) and (LPT_Nb<>0) then INC(OPL_LPT_Model);
               TDY    : If TDY_Type<2 then INC(TDY_Type); { No Emul for the moment }
               CMS    : If CMS_Type<2 then INC(CMS_Type); { No Emul for the moment }
               PSG    : If PSG_Type<1 then INC(PSG_Type); { No Emul for the moment }
              End;

      Left :  Case Out_Nb_S of 
               OPL    : If OPL_Model>0 then DEC(OPL_Model);
               OPLLPT : If (OPL_LPT_Model>0) and (LPT_Nb<>0) then DEC(OPL_LPT_Model);
               TDY    : If TDY_Type>0 then DEC(TDY_Type);
			         CMS    : If CMS_Type>0 then DEC(CMS_Type);
			         PSG    : If PSG_Type>0 then DEC(PSG_Type);
              End;

      Space,112,80 : Case Out_Nb_S of {p, P, Space }
                       OPLLPT: Begin
	                            INC(OPL_LPT_Nb);
                                If OPL_LPT_Nb>LPT_Nb then OPL_LPT_Nb:=1;
                               End;
                       PSG: Begin
	                            INC(OPL_PSG_Nb);
                                If OPL_PSF_Nb>PSG_Nb then OPL_PSG_Nb:=1;
                               End;                               
                       TDY : Case TDY_Type Of
                                1 : Begin
                                     INC(TDY_PortNb);
                                     If TDY_PortNb>TDY_PortTotal then TDY_PortNb:=1;
                                    End;
	                            2 :Begin
                                    INC(TDY_LPT_Nb);
                                    If TDY_LPT_Nb>LPT_Nb then TDY_LPT_Nb:=1;
                                   End;
                                { 3: Emul }
							 End;
                       CMS : Case CMS_Type Of
                                1 : Begin
                                     INC(CMS_PortNb);
                                     If CMS_PortNb>CMS_PortTotal then CMS_PortNb:=1;
                                    End;
	                            2 :Begin
                                    INC(CMS_LPT_Nb);
                                    If CMS_LPT_Nb>LPT_Nb then CMS_LPT_Nb:=1;
                                   End;
                                { 3: Emul }
							 End;							 

                       End;  {Case Out_Nb_S }
       End; { Case Touche }
    End; { Keys Synth}

   End
  Else  {Mouse button pressed}
   Begin
    If (Out_Type=1) then
	 Begin
     If (x in [9..31]) and (y in [8..8+MMSS_Out_Nb_W-1]) Then
      If MMSS_W_Output_Available[y-8] Then Out_Nb_W:=y-8;

     If Out_Nb_W<>GUS Then
      If y=Out_Nb_W+8 Then
       Case x of
        64..66: If freq>5000 Then Begin Dec(freq,100); defile:=True End;
        68..70: If freq<Get_MaxFreq(Out_Nb_W,T_SB,UtSte,DC) Then Begin Inc(freq,100); defile:=True End
       End;

     If (Out_Nb_W in [SB,SBPro]) Then
      If y=Out_Nb_W+10 Then
       Begin
        If (x in [xDMA[Out_Nb_W]..xDMA_opt[Out_Nb_W]+1]) Then
         Begin
          Case DMA of
           0 : DMA:=1;
           1 : DMA:=3;
           3 : DMA:=0
          End;
          attends_relache:=True
         End;
        If (x in [xIRQ[Out_Nb_W]..xIRQ_opt[Out_Nb_W]+1]) Then
         Begin
          Case IRQ of
           2 : IRQ:=5;
           5 : IRQ:=7;
           7 : If Out_Nb_W=SBPro Then IRQ:=10 Else IRQ:=2;
           10: IRQ:=2
          End;
          attends_relache:=True
         End;
        If (x in [66..71]) and (t_SB<=2) Then t_SB:=3-t_SB
       End;

     Case Out_Nb_W of
	  SB   : If (x in [58..62]) and (y=Out_Nb_W+10) Then
                Begin
                DC:=Not(DC);
                attends_relache:=True
                End;
      SBPro: Begin
              If y=Out_Nb_W+12 Then
               Case x of
                41..49: Begin
                         UtSte:=Not(UtSte);
                         If Not(UtSte) Then UtMix:=False;
                         attends_relache:=True
                        End;
                65..73: Begin
                         UtFilt:=Not(UtFilt);
                         attends_relache:=True
                        End
               End;
              If y=Out_Nb_W+14 Then
               Case x of
                54    : If volL> 0 Then Begin Dec(volL); defile:=True End;
                56..71: volL:=x-56;
                73    : If volL<15 Then Begin Inc(volL); defile:=True End
               End;
              If y=Out_Nb_W+15 Then
               Case x of
                54    : If volR> 0 Then Begin Dec(volR); defile:=True End;
                56..71: volR:=x-56;
                73    : If volR<15 Then Begin Inc(volR); defile:=True End
               End
             End;
      GUS  : Begin
	          If y=Out_Nb_W+10 Then
               Case x of
                50..53: MixGUS:=0;
                55..63: MixGUS:=x-55;
                65..70: MixGUS:=8
               End;
              If Y=Out_Nb_W+8 Then
                 If ((x>44) and (x<54)) then iWave:=Not(iWave);
				 If ((x>56) and (x<70)) then GLineIn:=Not(GLineIn);
             End
     End; { Case Out_Nb_W }
    End; { If Out_Type=1 }

   If Out_Type=2 Then { Synth menu Mouse Click }
    Begin
      If (x in [9..31]) and (y in [8..8+MMSS_Out_Nb_S-1]) Then Out_Nb_S:=y-8;

      Case Out_Nb_S of
       OPL: If y=8 Then
             Case x of
               41..48: OPL_Model:=0; { None }
               51..58: OPL_Model:=1; { OPL2 }
               59..65: OPL_Model:=2; { OPL2 }
             End;
       OPLLPT:If y=9 Then
               Case x of
                41..48: OPL_LPT_Model:=0;
                51..58: OPL_LPT_Model:=1;
                59..65: OPL_LPT_Model:=2;
               End
			    Else
              if y=10 then 
			   Begin
                INC(OPL_LPT_Nb);
                If OPL_LPT_Nb>LPT_Nb then OPL_LPT_Nb:=1
			   End;			   
       TDY: If y=10 Then
             Case x of
               41..48: TDY_Type:=0; { None }
               51..58: TDY_Type:=1; { Int  }
               59..65: TDY_Type:=2; { LPT  }
             End;
       CMS: If y=11 Then
             Case x of
               41..48: CMS_Type:=0; { None }
               51..58: CMS_Type:=1; { Int  }
               59..65: CMS_Type:=2; { LPT  }
             End;
       PSG: If y=11 Then
             Case x of
               41..48: PSG_Type:=0; { None }
               51..58: PSG_Type:=1; { Int  }
             End;	             
	  End;

     End; { If Out_Type=2 }

    ok:=boutonOK.Clique;
    sortie:=boutonAnnuler.Clique;
    If defile Then DelaiBoutonSouris(10)
     Else If attends_relache Then Repeat Until BoutonSouris=aucun
   End
 Until ok or sortie;

 If ok Then  {sauve les nouvelles valeurs}
  Begin
   With MMSS_CFG^do
    Begin
     If Wave_Output<>Out_Nb_W then recharge_module:=True;
	 Wave_Output:=Out_Nb_W;
     If Out_Nb_W<>GUS Then MM_Default_Frequency:=freq;
     If (Out_Nb_W in [SB,SBPro]) Then
      Begin
       DMA_SB8:=DMA; IRQ_SB:=IRQ;
       Utilise_DC :=DC;
       MMType_SB  :=t_SB
      End;
     Case Out_Nb_W of
      SBPro: Begin
              Utilise_Filtre:=UtFilt;
              Utilise_Stereo:=UtSte;
              Utilise_Mixage:=UtMix and UtSte;
              SB_LeftVol:=VolL; SB_RightVol:=VolR;
              SBP_MasterVolume(SB_LeftVol,SB_RightVol);
              SBP_Filtre(UtFilt);
              pannG:=$20; pannD:=$60
             End;
      GUS: Begin
            pannG:=8*(8-MixGUS); pannD:=$80-pannG;
            GUS_InterWave:=iWave; {iWave}
           End
     End;
     CorrigeParametres(Wave_Output,MMType_SB,MM_Default_Frequency,Use_DMA,Utilise_Stereo,
                       Utilise_Mixage,Utilise_Filtre,Utilise_DC,IRQ_SB)
    End;
   MMSS_Def_LeftPan:=pannG; MMSS_Def_RightPan:=pannD;
   GUS_LineIn:=GLineIn;
  End;

  { Update the Wave Output values (Updated all the times)}

 MMSS_CFG^.OPL_Model:=OPL_Model;
 MMSS_CFG^.OPL_LPT_Model:=OPL_LPT_Model;
 MMSS_CFG^.OPL_LPT_Nb:=OPL_LPT_Nb;
 
 MMSS_CFG^.TDY_Type:=TDY_Type;
 MMSS_CFG^.TDY_LPT_Nb:=TDY_LPT_Nb;
 TDY_Port:=TDY_PortList[TDY_PortNb];
 MMSS_CFG^.TDY_Port:=TDY_Port;
 
 MMSS_CFG^.CMS_Type:=CMS_Type;
 MMSS_CFG^.CMS_LPT_Nb:=CMS_LPT_Nb;
 CMS_Port:=CMS_PortList[CMS_PortNb];
 MMSS_CFG^.CMS_Port:=CMS_Port;

 RestaureZoneSuppr(0,zone_ligne);
 RestaureZoneSuppr(0,z); RestaureZoneSuppr(0,zone2);

 If ok Then AfficheReglages
End; {RegleSortie}

{----------------------------------------------------------}

PROCEDURE RegleOptions;

Const Options_txt: Array[1..3] of String[16]=
     ('Default Volume','IntroScan Length','Memory');
	 Limit_txt: Array[0..2] of String[6]=
     ('Off  ','Auto ','Fixed');

      Couleur: Array[Boolean] of Byte=(24,23);

Var z: Zone;
    boutonOK,boutonAnnuler: Bouton;
    touche: Key;
    x,y: Byte;
    i: Word;
    defile,ok,sortie: Boolean;
    voldef,duree,octMOD,delai_eco: Byte;
	LimitType,LimitNb:Byte;
    utEMS,utUMB,utFine,utPann,utBPM,utInt,ut16b: Boolean;

Begin
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}
 OmbreZoneCoins(23,6,57,22,z,19);
 Cadre(0,1,24,6,56,22,19,'',0,'');
 AffChXY(0,36,6,' Options ',19);
 For i:=1 to 3 do
   Begin
    LigneHorizBouts(6+2*i,24,56,19);
    AffChXY(0,26,5+2*i,Options_txt[i],23)
   End;

 AfficheFleches(48,7);  {vol/def}
 AfficheFleches(48,9);  {Introscan}

 AffChXY(0,33,11,EntierTexte(MemoireDOSLibre SHR 6,3)+'Kb',23);
 AffChXY(0,41,11,'EMS',Couleur[EMS_presente]);
 AffChXY(0,49,11,'UMB',Couleur[UMB_presente]);
 
 AffChXY(0,35,12,' Partition ',19);
 AffChXY(0,26,13,'FineTune',23);
 AffChXY(0,26,14,'Panning',23);
 AffChXY(0,49,13,'BPM',23);
 AffChXY(0,41,14,'Octaves MOD',23);
 
 LigneHorizBouts(15,24,56,19); 
 AffChXY(0,39,15,' Mix ',19);
  
{ AffChXY(0,26,16,'Interpolation',23);}
 AffChXY(0,26,16,'16Bit',23);
 AffChXY(0,41,16,'Ch Limit',23);
 AffChXY(0,30,17,'Max Channels',23); 
 AfficheFleches(48,17);  {Max Channels} 
 LigneHorizBouts(18,24,56,19);

 AfficheBoutonsOKAnnuler(32,20,boutonOK,boutonAnnuler);

 {cherche les valeurs actuelles}
 voldef:=MM_Default_Volume Div 5;
 duree:=duree_IntroScan;
 utEMS:=MMSS_EMS_First;
 utUMB:=MMSS_Use_UMB;
 With MMSS_CFG^ do
  Begin
   utFine:=Use_FineTune_CMD;
   utPann:=Use_Panning_CMD;
   utBPM :=Use_BPM_CMD;
{  utInt :=Utiliser_Interpolation;}
   ut16b :=Mix_16Bit;
   LimitType:=Mix_ChLimit_Type;
   LimitNb:=Mix_ChLimit_Nb     
  End;
 octMOD:=Nb_Octaves_MOD;

 defile:=False;
 Repeat
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}
  AffChXY(0,42,7,EntierTexte(voldef,3)+'%',29);
  AffChXY(0,43,9,EntierTexte(duree,2)+'s',29);
  AfficheCase(45,11,utEMS); AfficheCase(53,11,utUMB);
  AfficheCase(35,13,utFine); AfficheCase(53,13,utBPM);
  AfficheCase(35,14,utPann); AffCarXY(0,54,14,Char(48+octMOD),29);
{  AfficheCase(40,16,utInt);}
  AfficheCase(35,16,ut16B);
  AffChXY(0,50,16,Limit_txt[LimitType],29);
  AffChXY(0,44,17,EntierTexte(LimitNb,2),29);
  
  AttendClavierSouris(Not defile,False,x,y);
  defile:=False;
  If KeyPressed Then
   Begin
    touche:=ReadKey;
    ok:=(touche=Enter);
    sortie:=(touche=Esc);
    Case touche of
	  43,328 : If voldef<100 Then  Inc(voldef);
	  45,336 : If voldef>  1 Then  Dec(voldef);
      98,66  : utBPM:=Not(utBPM);
	  111,79 : Case OctMOD Of
                        3:octMOD:=5;
                        5:octMOD:=7;
                        7:octMOD:=3
                       End;
      112,80 : utPann:=Not(utPann); 
      101,69 : If EMS_presente Then utEMS:=Not(utEMS);
      102,70 : utFine:=Not(utFine);
{     105,73 : utInt:=Not(utInt);}
      49 ,38 : ut16b:=Not(ut16b);
      117,85 : If UMB_presente Then utUMB:=Not(utUMB);
          99 : Begin
                LimitType:=LimitType+1;
                If LimitType=3 then LimitType:=0;
               End;
      331 : If LimitNb> 3 Then Begin Dec(LimitNb); defile:=True End;
      333 : If LimitNb<31 Then Begin Inc(LimitNb); defile:=True End
    End
   End
  Else
   Begin
    Case y of
      7: Case x of
          48..50: If voldef>  1 Then Begin Dec(voldef); defile:=True End;
          52..54: If voldef<100 Then Begin Inc(voldef); defile:=True End
         End;
      9: Case x of
          48..50: If duree> 2 Then Begin Dec(duree); defile:=True End;
          52..54: If duree<30 Then Begin Inc(duree); defile:=True End
         End;
     11: Case x of
          41..46: If EMS_presente Then utEMS:=Not(utEMS);
          49..54: If UMB_presente Then utUMB:=Not(utUMB)
         End;
     13: Case x of
          26..36: utFine:=Not(utFine);
          49..54: utBPM:=Not(utBPM)
         End;
     14: Case x of
          26..36: utPann:=Not(utPann);
          41..54: Case OctMOD Of
                        3:octMOD:=5;
                        5:octMOD:=6;
                        6:octMOD:=3
                       End;
         End;
     16: Case x of
 {         26..42: utInt:=Not(utInt);}
          26..37: ut16b:=Not(ut16b);
          41..56: Begin
                  LimitType:=LimitType+1;
				  If LimitType=3 then LimitType:=0;
                  End;
         End;
     17: Case x of
		  48..50: If LimitNb> 3 Then Begin Dec(LimitNb); defile:=True End;
          52..54: If LimitNb<31 Then Begin Inc(LimitNb); defile:=True End
         End;
    End;
    ok:=boutonOK.Clique;
    sortie:=boutonAnnuler.Clique;
    If defile Then DelaiBoutonSouris(10) Else Repeat Until BoutonSouris=aucun
   End
 Until ok or sortie;

 If ok Then  {sauve les nouvelles valeurs}
  Begin
   MM_Default_Volume:=5*voldef;
   duree_IntroScan:=duree;
   MMSS_EMS_First:=utEMS;
   MMSS_Use_UMB:=utUMB;
   With MMSS_CFG^ do
    Begin
     Use_FineTune_CMD:=utFine;
     Use_Panning_CMD:=utPann;
     Use_BPM_CMD:=utBPM;
     Utiliser_Interpolation:=utInt;
     Mix_16Bit:=ut16b;
     Mix_ChLimit_Type:=LimitType;
     Mix_ChLimit_Nb  :=LimitNb     
    End;
   Nb_Octaves_MOD:=octMOD;
   
   For i:=premier_module to nbr_fich do With Module[i] do
    If (Default_Mask AND M_DefVol) <>0 Then Volume:=MM_Default_Volume;
   recharge_module:=True
  End;

 RestaureZoneSuppr(0,z);

 If ok Then AfficheReglages
End; {RegleOptions}

{----------------------------------------------------------}

PROCEDURE Aide;

Const Car: Array[Boolean] of Char=(' ',#11);

      nbr_lignes_aide=21;
      Aide_txt: Array[1..nbr_lignes_aide] of String80
       = ('* To press a button, use the mouse or hit the highlighted key',
          '  displayed on it. (Only when this button is lit)',
          '* Inside the list of modules, move the selector with the keys',
          '  ^^, ^Page^, ^Home^/^End^ and ^'#27#26'^ (previous/next module in a program)',
          '  and change the display mode (title of the module/size and volume)',
          '  by hitting ^Tab^.',
          '* You can also search and select a module with its initial by',
          '  hitting ^Shift^+<initial>.',
          '* To play the selected module, hit ^<��^ or click it with the left',
          '  button of the mouse.',
          '* You can adjust the volume of the selected module with ^-^ and ^+^, or',
          '  put the default volume on all the modules with ^Ctrl^+^<��^.',
          '* If you want the volume of one module to follow automatically the',
          '  default volume settings, hit ^'#27'Del^ ("d" is displayed).',
		  '* You can adjust the frequency of the selected module with ^Left/Right^',
          '* To delete a module from the disk, hit ^Del^.',
          '* ^Playlist:^ To Add/Remove a module, use ^Space^ or Right Click',
          '* To select a drive, hit ^Alt^+<drive>.',
          '* The ^-^/^+^ commands in the Output/Options windows and the ^^/^^ arrows',
          '  of the lifts are 3-speed with the mouse, depending on you press',
          '  the left button, the right one, or both at the same time.');

      hauteur_fenetre=14; {nombre de lignes affichables simultan�ment}
      x_asc=77; y_asc=8;  {coordonn�es de la fl�che vers le haut}

Var z: Zone;
    boutonOK: Bouton;
    sortie,defile_fleches,bouge_ascenseur: Boolean;
    i,x,y,premiere: Byte;


Procedure DefileHaut;
Begin
 If premiere>1 Then Dec(premiere)
End; {DefileHaut}


Procedure DefileBas;
Begin
 If premiere<nbr_lignes_aide-hauteur_fenetre+1 Then Inc(premiere)
End; {DefileBas}


Begin {Aide}
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  
 OmbreZoneCoins(3,4,x_asc+1,25,z,22);
 Cadre(0,1,4,4,x_asc,25,22,' Help ',27,'');
 AffChXY(0,32,5,ident_ModM,30);
 AffChXY(0,25,6,copyright_String,23);
 LigneHorizBouts( 7,4,x_asc,22);
 LigneHorizBouts(22,4,x_asc,22);

{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
 With boutonOK do Begin Definit(0,38,23,' OK ',241,248,0,0); Affiche End;

 premiere:=1;
 sortie:=False; defile_fleches:=False; bouge_ascenseur:=False;
 Repeat
{$IFNDEF NoMOUSE}
  CacheCursSouris;
{$ENDIF}  

  AfficheAscenseur(x_asc,y_asc,hauteur_fenetre,nbr_lignes_aide,premiere,11);

  For i:=premiere to premiere+hauteur_fenetre-1 do
   Begin
  {  If (Car[(Aide_txt[i][1] in majuscules)]) then
     AffCarXY(0,6,i-premiere+y_asc,'-',18)}
    EffaceZone(0,7,i-premiere+y_asc,x_asc-2,i-premiere+y_asc,27);
    AffChXY2(0,7,i-premiere+y_asc,Aide_txt[i],19,27)
   End;

  If BoutonSouris=aucun Then
   Begin defile_fleches:=False; bouge_ascenseur:=False End;

  If defile_fleches or bouge_ascenseur Then ZoneSouris(x_asc,y_asc,x_asc,y_asc+hauteur_fenetre-1)
                                       Else ZoneSouris(1,1,80,hauteur_ecran_txt);

  AttendClavierSouris(Not(defile_fleches or bouge_ascenseur),False,x,y);
{$IFNDEF CGAOnly}
  SourisBouge:=False;
   If bouge_ascenseur Then
   Repeat Until KeyPressed or SourisBouge or (BoutonSouris=aucun);
{$ELSE}
   If bouge_ascenseur Then
   Repeat Until KeyPressed or (BoutonSouris=aucun);
{$ENDIF}

  If KeyPressed Then
   Case ReadKey of
    Up  : DefileHaut;
    Down: DefileBas;
    PgUp: If premiere>hauteur_fenetre Then Dec(premiere,hauteur_fenetre)
                                      Else premiere:=1;
    PgDn: Begin
           Inc(premiere,hauteur_fenetre);
           If premiere>nbr_lignes_aide-hauteur_fenetre+1 Then
            premiere:=nbr_lignes_aide-hauteur_fenetre+1
          End;
    Home: premiere:=1;
    End_: premiere:=nbr_lignes_aide-hauteur_fenetre+1;
    Enter,Esc: sortie:=True
   End
  Else
   Begin
    If x=x_asc Then
     Case y of
      y_asc: Begin defile_fleches:=True; DefileHaut; DelaiBoutonSouris(10) End;
      y_asc+hauteur_fenetre-1: Begin defile_fleches:=True; DefileBas; DelaiBoutonSouris(10) End;
      y_asc+1..y_asc+hauteur_fenetre-2:
             Begin
              defile_fleches:=False; bouge_ascenseur:=True;
              premiere:=1+Round((y-y_asc-1)*(nbr_lignes_aide-hauteur_fenetre)/(hauteur_fenetre-3))
             End
     End;
    sortie:=boutonOK.Clique
   End
 Until sortie;

 RestaureZoneSuppr(0,z)
End; {Aide}

{----------------------------------------------------------}

END.
