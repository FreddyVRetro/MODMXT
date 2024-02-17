{************************************************************************}
{                               MM_PARAM.PAS                             }
{                                                                        }
{  unit‚ pour Mod Master: routines pour la ligne de commande             }
{                                                                        }
{  AUTEUR: Fabrice Couteau.                                              }
{                                                                        }
{                                                                        }
{                               Debut d'ecriture le --/--/93             }
{                               Dernieres modifications le 05/21         }
{************************************************************************}
UNIT MM_PARAM;

{$A+,G-,Q-,R-,S-}

{$I MODMCFG.INI}

INTERFACE

{==========================================================}

PROCEDURE AnalyseParametres;
PROCEDURE AfficheSyntaxe;
PROCEDURE ChercheFichiers;

{==========================================================}

IMPLEMENTATION

USES Crt,Dos,Fichiers,Texte,Util,UtilC,
     MM_VAR,MMSS_Var,MM_DIV,MODMUnit;

{==========================================================}

PROCEDURE AnalyseParametres;
Var nbr_param,i,j: Byte;
    param: String[6];
    erreur: Integer;
Begin
 nbr_param:=ParamCount;
 mode_interactif:=(nbr_param=0);
 affiche_syntaxe:=(nbr_param>7);
 For i:=1 to nbr_param do
  Begin
   param:=Maj(ParamStr(i));
   If param='?' Then affiche_syntaxe:=True
   Else
    If param[1]='/' Then
     Begin
      Case param[2] of
       'R': Boucler_MOD := True;
       'I': Begin MMSS_CFG^.Duree_intro:=Duree_IntroScan; Shuffle:=False End;
       'S': Begin Shuffle:=True; MMSS_CFG^.Duree_intro:=0 End; {pas les 2 en mˆme temps!}
       'C': Cursor_On := True;
       'D': If (param[3] in [':','=']) Then
             Begin
              MMSS_CFG^.CDAC_Port:=Str2Hex(Copy(param,4,3));
              If (MMSS_CFG^.CDAC_Port<>0)
                 Then MMSS_W_Output_Available[C_DAC]:=True
                 Else affiche_syntaxe:=True;
             End
            Else affiche_syntaxe:=True;
       'V': If (param[3] in [':','=']) Then
             Begin
              Val(Copy(param,4,3),MMSS_Volume,erreur);
              If (erreur=0) and
                 (MMSS_Volume>=1) and (MMSS_Volume<=150) Then
               MMSS_Volume:=5*MMSS_Volume  {% -> volume}
              Else affiche_syntaxe:=True
             End
            Else affiche_syntaxe:=True
       Else affiche_syntaxe:=True
      End;
      If i=1 Then mode_interactif:=True {1er param. n'est pas un fichier}
     End
    Else
     If i=1 Then mode_interactif:=False Else affiche_syntaxe:=True
  End
End; {AnalyseParametres}

{----------------------------------------------------------}

PROCEDURE AfficheSyntaxe;

Const CRLF=#13#10;

      nbr_lignes_syntaxes=4;
      Syntaxes_txt: Array[1..nbr_lignes_syntaxes] of String80
       =( 'Syntaxes: MODM [options]                      Interactive mode with menu',
          '          MODM module_name[.ext] [options]    Plays the specified module(s)',
          '          MODM program_name[.PRG] [options]   Plays the specified program(s)'+CRLF,
          'module_name and program_name may include a path name and wildcards'+CRLF);


      nbr_lignes_options=6;
      Options_txt: Array[1..6] of String[48]
       =( '  /C      Always display the Cursor',
          '  /R      Enables the Repeat function',
          '  /I      Enables the IntroScan function',
          '  /S      Enables the Shuffle function',
          '  /D:xxx  Defines the Custom DAC I/O',
          '  /V:xxx  Defines the volume = xxx % (1 to 100)');
Var i: Byte;

Begin
 Write(CRLF+ident_ModM+' '+copyright_String+CRLF+'Format Supported: ');
 For i:=1 to nbr_extensions do
  Begin
   Write(Extensions[i]);
   Case i of
    1..nbr_extensions-2: Write(', ');
    nbr_extensions-1: Write(' and ');
    nbr_extensions: Write('.')
   End;
   If WhereX>75 Then Writeln
  End;
 WriteLn;
 For i:=1 to nbr_lignes_syntaxes do WriteLn(Syntaxes_txt[i]);
 For i:=1 to nbr_lignes_options do WriteLn(Options_txt[i]);
 Curseur(plat)
End; {AfficheSyntaxe}

{----------------------------------------------------------}

PROCEDURE ChercheFichiers;
Var i,long_repert: Byte;
    param: String80;


Procedure LitModules(PRG: Boolean);
Var i: Word;
    Erreur_Modm:Word;
    Erreur_Traitee:Boolean;
Begin
 Erreur_Traitee:=False;
 Programme:=(Longueur_Prog>1); Numero_module:=1;
 If Longueur_prog=1 Then Shuffle:=False;
 If Shuffle Then
  For i:=1 to (Longueur_prog Shr 1) do
   EchangeModules(i,1+Random(Longueur_prog));

 InitModeTexte;
 Repeat
  With Module[Numero_module] do
   Begin
    MM_ChargeModule(repert+Nom,erreur_fin);
    If (erreur_fin in [Ok,Err_samples]) Then
       Begin
       If Erreur_Traitee Then
          Begin
          InitModeTexte;
          Erreur_Traitee:=False;
          End;
       Play(repert+Nom);
       End
    Else
     Begin
      {InitTexte;}
      Case erreur_fin of
       Err_memoire: WriteLn(Erreurs[mem_insuff_txt]+' '+Erreurs[pour_charger_txt]+' '+Nom);
       Err_format : WriteLn(Erreurs[err_format_txt]+' '+Nom);
       Err_lecture: If PRG Then WriteLn(Nom+' '+Erreurs[nexiste_plus_txt])
                    Else WriteLn(Erreurs[err_pendant_lect_txt]+' '+Nom)
      End;
     Delay(500);
     Erreur_Traitee:=True;
     End;
    Case MMSS_CFG^.Touche_fin of
     Tfin_normale,Tfin_PgDn: Inc(Numero_module);
     Tfin_PgUp: Dec(Numero_module)
    End
   End
 Until (Numero_module<1) or (Numero_module>Longueur_prog)
       or (MMSS_CFG^.Touche_fin=Tfin_Esc)
End; {LitModules}


Procedure GereErreursFichiers(nombre_fichiers_trouves: Word);
Begin
 Case DosError of
  3: Begin
      WriteLn(Erreurs[chemin_txt]+' '+repert+' '+Erreurs[introuvable_txt]);
      erreur_fin:=3
     End;
  2,18: If nombre_fichiers_trouves=0 Then
         Begin
          WriteLn(Erreurs[fich_introuv_txt]);
          erreur_fin:=DosError
         End
        Else erreur_fin:=0;
  100,153..255: Begin
                 WriteLn(Erreurs[err_lecture_txt]);
                 erreur_fin:=DosError
                End;
  152: Begin
        WriteLn(Erreurs[lecteur_txt]+' '+repert[1]+': '+Erreurs[pas_pret_txt]);
        erreur_fin:=152
       End
 End
End; {GereErreursFichiers}


Procedure ChercheModules(nom_fichier: String12);
Var fich: SearchRec;
Begin
 Longueur_prog:=0;
 FindFirst(repert+nom_fichier,AnyFile,fich); {ReadOnly+Archive}
 While DosError=0 do
  Begin
   Inc(Longueur_prog);
   Module[Longueur_prog].Nom:=fich.Name;
   FindNext(fich)
  End;
 If Longueur_prog>0 Then LitModules(False) Else GereErreursFichiers(Longueur_prog)
End; {ChercheModules}


Procedure ChercheProgrammes(nom_fichier: String12);
Var fich: SearchRec;
    ident: String20;
    nbr_prog,i: Word;
    f: Fichier;
Begin
 nbr_prog:=0;
 FindFirst(repert+nom_fichier,AnyFile,fich);
 While DosError=0 do
  Begin
   Inc(nbr_prog);
   f.Ouvre(lecture,repert+fich.Name);
   erreur_fin:=f_erreur; {normalement, erreur_fin=0}
   f.Lit(ident[1],20); ident[0]:=#20;
{   If TestIdentModM(ident,Extensions[ext_PRG],version_min_PRG) Then
    Begin}
    Longueur_prog:=(f.Taille-20) Div 13;
    If NOT REGISTERED Then
      Longueur_prog:=MinEntier(LONG_PROG_LIMIT,Longueur_prog); {bridage !!}
    f.PlacePointeur(20);
    For i:=1 to Longueur_prog do f.Lit(Module[i].Nom[0],13);
    f.Ferme;
    If Longueur_prog>0 Then LitModules(True);
{    End
   Else
    Begin
     WriteLn(Erreurs[err_format_txt]+' '+Erreurs[le_prog_txt]+' '+fich.Name);
     erreur_fin:=3
    End;}
   FindNext(fich)
  End;
 GereErreursFichiers(nbr_prog)
End; {ChercheProgrammes}


Function TrouveFichierExt(nom_fichier: String12): Byte;
Var i,j: Byte;
    fich: SearchRec;
Begin
 i:=1; j:=0;
 Repeat
  FindFirst(repert+nom_fichier+'.'+Extensions[i],AnyFile,fich);
  If DosError=0 Then j:=i;
  Inc(i)
 Until (i>nbr_extensions) or (j>0);
 TrouveFichierExt:=j
End; {TrouveFichierExt}


Begin  {ChercheFichiers}
 param:=Maj(ParamStr(1));
 i:=Length(param); long_repert:=0; repert:='';
 Repeat
  If (param[i] in ['\',':']) Then long_repert:=i;
  Dec(i)
 Until (i=0) or (long_repert>0);
 If long_repert>0 Then
  Begin
   repert:=Copy(param,1,long_repert); Delete(param,1,long_repert)
  End;
 Case Extension(param) of
  0: If Pos('.',param)=0 Then  {pas d'extension->recherche les ext. possibles}
      Begin
       i:=TrouveFichierExt(param);
       If i>0 Then param:=param+'.'+Extensions[i];
       Case i of
        0: GereErreursFichiers(0);
        1..nbr_extensions: ChercheModules(param);
{        ext_PRG: ChercheProgrammes(param)}
       End
      End
     Else Begin AfficheSyntaxe; Halt End;
  1..nbr_extensions: ChercheModules(param);
  {ext_PRG: ChercheProgrammes(param)}
 End
End; {ChercheFichiers}

{==========================================================}

END.