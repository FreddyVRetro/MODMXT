{************************************************************************}
{                                CHULT.PAS                               }
{                                                                        }
{ Loader pour les fichiers ULT (Ultra Tracker V1.0 … V1.6).              }
{                                                                        }
{ AUTEUR: Freddy V‚tel‚.                                                 }
{                                                                        }
{                               D‚but d'‚criture le 14/05/95             }
{                               DerniŠres modifications le 07/10/95      }
{************************************************************************}
        { Attention au panning pour sbPro (Pas 40h partout !!!) }

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChULT;
{$ELSE}
UNIT ChULT;
{$ENDIF}


INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

TYPE Char15=Array[1..15] of Char;

     Char32=Array[1..32] of Char;
Const
   Commandes_ULT:Array[0..15] of Byte=(Rien,PortUp,PortDown,TonePortamento,Vibrato,UltSpecial,Rien,
                                       Tremolo,Rien,SampleOffs,VolSlide,CPanning,SetVolume,EndPattern,
                                       Extended,SetTempo);
   NbVerULT = 4;
   IdentULT : Array[1..NbVerULT] of Char15=('MAS_UTrack_V001',  { 1.0 -> 1.3 }
                                            'MAS_UTrack_V002',  { v1.4 }
                                            'MAS_UTrack_V003',  { v1.5 }
                                            'MAS_UTrack_V004'); { v1.6 }

Type
     HeaderULT=RECORD
               Ident:Char15;
               Titre:Char32;
               Reserve:Byte;
               End;

     T_Smp_ULT=RECORD    { Versions <1.6. sinon, ajouter Dadj}
               Nom:Char32;
               Nom_Fich:Array[1..12] of Char;
               Rep:Longint;
               Rep_Fin:Longint;
               SizeStart:Longint;
               SizeEnd:Longint;
               Volume:Byte;
               BidiLoop:Byte;
               FineTune:Word;
               End;

Var VersionULT:Byte;
    Nb_Smp_ULT:Byte;
    Nb_Voies_ULT:Byte;
    Nb_Pattern_ULT:Byte;
    Position_Samples:Longint;
    Position_Actuelle:Longint;
    Table_Panning_ULT:Array[1..32] of Byte;

PROCEDURE Charge_ULT(chemin: String80; Var erreur: Word);

IMPLEMENTATION

{---------------------------------------------------------}

PROCEDURE Charge_Pattern_ULT;

Const Taille_Tampon=1024;

Var
    Pattern_ULT:Array[0..Taille_Tampon-1] of Byte;
    Index_ULT:Integer;
    Index:Word;
    Pattern: Ptr_Patt;
    N_Pattern:Byte;
    N_Voie:Byte;
    N_Note:Byte;
	Note:Byte;
    Position_Pattern:Word;
    Repeter:Boolean;
    Nb_Repetitions:Byte;
    Valeur:Byte;
    Param,Param1:Byte;
    Commd:Byte;
    i:Byte;

FUNCTION Lire_Valeur:Byte;
Begin
INC(Index_ULT);
If Index_ULT=Taille_Tampon Then
   Begin
   f_module.Lit(Pattern_ULT,Taille_Tampon);
   Inc(Position_Actuelle,Taille_Tampon);
   Index_ULT:=0;
   End;
Lire_Valeur:=Pattern_ULT[Index_ULT];
End;

PROCEDURE Traiter_Commande_ULT;
Begin
If Commd=SetVolume Then
   Begin
   Commd:=Rien;
   C_Note.Volume:=Param SHR 2;
   End;
If (Commd<>Rien) And (C_Note.Commande<>SetTempo) Then { Set Tempo prioritaire }
   Begin
   C_Note.Commande:=Commd;
   C_Note.Parametre:=Param;
   End;
If C_Note.Commande=Extended Then
   Begin
   C_Note.Commande:=SetFilter+C_Note.Parametre SHR 4;
   C_Note.Parametre:=C_Note.Parametre And $0F;
   If C_Note.Commande=SetFilter Then C_Note.Commande:=VibrSweep;
   End;
End;

Begin
Index_ULT:=Taille_Tampon-1;

For N_Pattern:=1 to Nb_Pattern_ULT do
    Begin
    IF Not MMSS_MemAlloc(Pointeur_actuel,24*Nb_voies_ULT,True,False) Then
       Begin
       Erreur_de_chargement:=Err_memoire;
       EXIT;
       End;
    MMSS_Table^.Seg_Pattern[N_Pattern]:=SEG(Pointeur_actuel^);
    End;

For N_Voie:=1 to Nb_Voies_ULT do        { Boucle sur les voies   }
 Begin
 For N_Pattern:=1 to Nb_Pattern_ULT do  { Boucle sur les pattern }
  Begin
  Pattern:=Ptr(MMSS_Table^.Seg_Pattern[N_Pattern],0);
  Musique^.Taille_Pattern[N_Pattern]:=64;
  N_Note:=0;
   Repeat
   Valeur:=Lire_Valeur;
   If Valeur=$FC Then
      Begin
      Repeter:=True;
      Nb_Repetitions:=Lire_Valeur;
      Valeur:=Lire_Valeur;
      End
      Else Repeter:=False;
   If Valeur In [1..60] Then 
                        Begin
						C_Note.Periode:=Valeur+24;
						{C_Note.Periode:=PeriodSet[(Valeur-1) DIV 12+2,(Valeur-1) MOD 12]}
						End
                        Else C_Note.Periode:=0;
   C_Note.Instrument:=Lire_Valeur;
   C_Note.Volume:=$FF;
   C_Note.Commande:=Rien;
   C_Note.Parametre:=0;

   Valeur:=Lire_Valeur;
   Param1:=Lire_Valeur;  { Invers‚ car Word !!! }
   Param:=Lire_Valeur;

   Commd:=Commandes_ULT[Valeur SHR 4];
   Traiter_Commande_ULT;
   Commd:=Commandes_ULT[Valeur AND $0F];
   Param:=Param1;
   Traiter_Commande_ULT;

   IF C_Note.Commande=CPanning Then
      Begin
      MMSS_CFG^.Calculer_Panning:=True;
      C_Note.Parametre:=Panning_GUS_SB(C_Note.Parametre);
      End;


   Position_Pattern:=N_Voie+N_Note*Nb_Voies_ULT;
   If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
   If Repeter Then
      Begin
      For i:=1 to Nb_Repetitions do
       Begin
	  if N_Note<=63 Then
	     Begin
             Pattern^[Position_Pattern]:=C_Note;
             Inc(Position_Pattern,Nb_Voies_ULT);
	     INC(N_Note)
	     End;
          End;
      {Inc(N_Note,Nb_Repetitions); }
       End
      Else
       Begin
       Pattern^[Position_Pattern]:=C_Note;
       Inc(N_Note);
       End;
   Until N_Note>=64;
 {Si le nombre de notes ne tombe pas juste, erreur ! }   
 {If N_Note>64 Then  
    Begin
    Erreur_de_Chargement:=Err_Format;
    EXIT;
    End; }
 End; { Boucle sur les Pattern }
End;{ Boucle sur les voies }
Dec(Position_Actuelle,Taille_Tampon);
Inc(Position_Actuelle,Index_ULT+1);   { Ici,Position actuelle est sur les  }
                                      { donn‚es des samples                }
End;

{---------------------------------------------------------}

PROCEDURE Charge_Samples_ULT;
Var Smp_ULT:T_Smp_ULT;
    Smp_ULT_Dadj:Word;

Begin
If Nb_Smp_ULT>Max_Samples Then Nb_Smp_ULT:=Max_Samples;

Init_Charge_Sample;
{ R‚serve l'espace DOS pour la d‚finition de samples }
Allouer_Samples(Nb_Smp_ULT);
Convertir_signe:=False;
Smp_ULT_Dadj:=0;

For CHU_NSmp:=1 to Nb_Smp_ULT do
    Begin
    f_module.LitPos(Position_Samples,Smp_ULT,SizeOf(Smp_ULT));
    INC(Position_Samples,SizeOf(Smp_ULT));
    If VersionUlt=4 Then
       Begin
       Smp_ULT_Dadj:=Smp_ULT.FineTune;
       INC(Position_Samples,2);
       End;
    New_Sample;
    {Move(Smp_ULT.Nom,Smp.Nom,32); }{ Nom du sample }
    Move(Smp_ULT.Nom,Musique^.PtrInstrNameTable^[CHU_NSmp,1],24);
	
    Smp.Info:=Smp_ULT.BidiLoop;   { 16 bit, Boucle, Bidi }
    Smp.Len:=Smp_ULT.SizeEnd-Smp_ULT.SizeStart;

    f_module.PlacePointeur(Position_Actuelle);
    If (Smp.Info And M_16Bit)=0 Then
       Inc(Position_Actuelle,Smp.Len)
       Else Inc(Position_Actuelle,Smp.Len*2);

    If (Smp.Len>0) Then
       Begin

       If ((Smp.Info And M_Boucle)=0) Then
          Begin       { Pas de bouclage }
           Smp.Rep:=0;
           Smp_Rep_Fin:=0;
          End
          Else        { Bouclage        }
          If (Smp.Info And M_16Bit)>0 Then
             Begin
              Smp.Rep:=Smp_ULT.Rep SHR 1;
              Smp_Rep_Fin:=Smp_ULT.Rep_Fin SHR 1;
             End
             Else
             Begin
              Smp.Rep:=Smp_ULT.Rep;
              Smp_Rep_Fin:=Smp_ULT.Rep_Fin;
             End;
       Smp.Rep_Len:=0;
       Smp.Volume:=Smp_ULT.Volume SHR 2;
       Smp.C4Spd:=Smp_ULT_Dadj;
{       Smp.Fine_Tune:=0;}

       Charger_Sample;

       End;
    Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
    End;
Fin_Charge_Sample;

End; { Charge_Samples_ULT }

{---------------------------------------------------------}

PROCEDURE Charge_ULT(chemin: String80; Var erreur: Word);
Label Fin_Chargement_ULT;
Var
   ULT : ^HeaderULT;
   i   : Integer;

Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  MMSS_CFG^.Calculer_Panning:=False;
  New(ULT);
  f_module.LitPos(0,ULT^,Sizeof(ULT^));

  Musique^.Type_Module:=T_ULT;       { Type de module  }
  Musique^.C_Pattern:=False;  
  Musique^.Octave_Min:=0;
  Musique^.Octave_Max:=7;
  Move(ULT^.Titre,Musique^.Titre,20);         { Titre du module }
  Nom_fichier:=NomFichierSeul(chemin);

  VersionULT:=0;
  For i:=1 to NbVerUlt do If ULT^.Ident=IdentULT[i] Then VersionULT:=i;
  If VersionULT=0 Then
     Begin                { Erreur, identificateur non reconnus }
     Erreur_de_chargement:=Err_lecture;
     GOTO Fin_Chargement_ULT;  { Je sais, c'est un GOTO mais c'est pratique ;)}
     End;

  Position_Samples:=49;
  If ULT^.Reserve>0 Then  { Eviter le texte... }
     If VersionULT>1 Then
        Begin
        Position_Samples:=49+(ULT^.Reserve)*32;
        f_module.PlacePointeur(Position_Samples-1);
        End;

  f_module.Lit(Nb_Smp_ULT,1);  { Lire le Nb de samples... }
  (*Writeln('ID: ',ULT^.Ident,' => Version ',VersionULT);
  Writeln('Titre: ',ULT^.Titre);
  Writeln('Reserve: ',ULT^.Reserve);
  Writeln('Nb de samples: ',Nb_Smp_ULT); *)

  If VersionUlt=4 Then Position_Actuelle:=Position_Samples+Nb_Smp_ULT*66
                  Else Position_Actuelle:=Position_Samples+Nb_Smp_ULT*64;

  f_module.PlacePointeur(Position_Actuelle);
  f_module.Lit(Musique^.Sequence,Max_Pattern);  { If Max_Pattern<256) }
  f_module.DeplacePointeur(256-Max_Pattern);
  f_module.Lit(Nb_Voies_ULT,1);
  f_module.Lit(Nb_Pattern_ULT,1);
  Inc(Nb_Voies_ULT);
  Inc(Nb_Pattern_ULT);
  If Nb_Voies_ULT>32 Then Erreur_de_chargement:=Err_format;
  Musique^.Ch_Number:=NB_Voies_ULT;
  Musique^.Ch_Number_Patt:=Nb_Voies_ULT;

     { Table de Panning }
  Inc(Position_Actuelle,258);
  If (VersionULT>2) And (Panning_Utilisable) Then
     Begin
     Inc(Position_Actuelle,Nb_Voies_ULT);
     f_module.Lit(Table_Panning_ULT,Nb_Voies_ULT);
     For i:=1 to Nb_Voies_ULT do MMSS_Info^.CH_Panning[i]:=Panning_GUS_SB(Table_Panning_ULT[i] AND $0F);
     MMSS_CFG^.Calculer_Panning:=True;
     End
     Else Init_Panning;

  For i:=1 to 256 do   { Chercher la taille de la s‚quence }
      If Musique^.Sequence[i]=$FF Then
         Begin
         Musique^.Sequence_Len:=i-1;
         Break;
         End;

  If Erreur_de_chargement=Ok Then Charge_Pattern_ULT;
  If Erreur_de_chargement=Ok Then Charge_Samples_ULT;

  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;

(*  Repeat until Readkey=#13; *)
Fin_Chargement_ULT:
  Dispose(ULT);
  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else
 Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;

End; { Charge_ULT }

END.