{************************************************************************}
{                                CHMTM.PAS                               }
{                                                                        }
{  Loader pour les fichiers MTM (MultiTracker Module).                   }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{                               D‚but d'‚criture le 14/02/94             }
{                               DerniŠres modifications le 04/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChMTM; {unit‚ pour charger les fichiers MOD }
{$ELSE}
UNIT ChMTM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

PROCEDURE Charge_MTM(chemin: String80; Var erreur: Word);

IMPLEMENTATION


TYPE
     Char3=Array[1..3] of Char;
CONST
     Max_Samples_MTM=31;
     MTMMagic:Char3='MTM';

TYPE

     T_En_tete_MTM=Record
                   IdentMTM : Char3;     { MTM }
                   Version  : Byte;
                   Nom      : Char20;
                   Nb_Track : WORD;
                   DernierPattern : Byte;
                   TailleMusique  : Byte;
                   LongExtra      : Word;
                   NbSamples: Byte;
                   Attibut  : Byte;
                   Tempo    : Byte;
                   Nb_Voies : Byte;
                   Table_Pan: Array[1..32] of Byte;
                  End;
     T_Sample=Array[1..Max_Samples_MTM] of Record
              Nom     : Array[1..22] of Char;
              Long    : Longint;
              Rep     : Longint;
              Rep_Fin : Longint;
              Fine   : Byte;
              Volume : Byte;
              Attrib : Byte;
              End;
     T_Track_Seq=Array[1..4096] of Word;

     Ptr_En_tete_MTM=^T_En_tete_MTM;
     Ptr_Sample=^T_Sample;

     T_Note_MTM=Record
                  b1,b2,b3: Byte
                End;
     T_Track_MTM=Array[1..64] of T_Note_MTM;

Var FlagPattern:Array[0..127] of Boolean;
    Dernier_Pattern:Byte;

{---------------------------------------------------------}

PROCEDURE Charger_Pattern_MTM(Var MTM:Ptr_En_tete_MTM;Ch_Number:Byte);

Var Track_Seq:^T_Track_Seq;
    Taille_Seq:Word;
    Track:Word;                     { Index des tracks }
    Track_MTM:^T_Track_MTM;
    Track_Traduit:Boolean;          { Pour ‚viter retraduire un track     }
    N_Pattern_Traduit,N_Voie_Traduite:Byte;
    Row:Byte;                       { Ligne dans la partition        }
    N_Pattern,N_Voie:Byte;          { Pattern et voies o— copier le track }
    Pattern : Ptr_Patt;
    Index_Pattern:Word;
    Debut_Track:Longint;    { Position de d‚but des tracks !!! }
    i,j:Integer;
Begin
New(Track_Seq);
            { Lire le s‚quencement des "Tracks" }
Taille_Seq:=(Dernier_Pattern+1)*32;
f_module.LitPos(194+37*MTM^.NbSamples+192*Longint(MTM^.Nb_Track),
              Track_Seq^,Taille_Seq*2);



            { Allouer tous les Patterns         }
For i:=0 to MTM^.DernierPattern do
 If FlagPattern[i] Then
   Begin
   IF Not MMSS_MemAlloc(Pointeur_actuel,24*Ch_Number,True,False) Then
      Begin
      Dispose(Track_Seq);
      Erreur_de_chargement:=Err_Memoire;
      EXIT;
      End;
   Fillchar(Pointeur_actuel^,64*6*Ch_Number,0);
   MMSS_Table^.Seg_Pattern[i+1]:=SEG(Pointeur_actuel^);
   Musique^.Taille_Pattern[i]:=64;
   Pattern:=Pointeur_actuel;
   End;
            { Lecture des Tracks et conversion de la partition }

f_module.PlacePointeur(194+37*MTM^.NbSamples);{ Place le pointeur de fichier }
                                                   { au d‚but des tracks          }
C_Note.Volume:=255;
New(Track_MTM);
For Track:=1 to MTM^.Nb_Track do
    Begin
    Track_Traduit:=False;
    f_module.Lit(Track_MTM^,192); { Lire le "track" Nø Track !!}
    For i:=1 to Taille_Seq do
     If Track_Seq^[i]=Track Then
        Begin
        N_Pattern:=i DIV 32;
        N_Voie:=i MOD 32;
        If N_Voie=0 Then
           Begin
           N_Voie:=32;
           DEC(N_Pattern);
           End;

        {Writeln('Track: ',Track);
        Writeln('Position: ',i);
        Write('Pattern Nø',N_Pattern);
        Writeln('Voie Nø',N_Voie);}
{        Repeat until Readkey=#13;}
        If (FlagPattern[N_Pattern] And (N_Voie<=Ch_Number)) Then
          Begin
          Pattern:=Ptr(MMSS_Table^.Seg_Pattern[N_Pattern+1],0);
          Index_Pattern:=N_Voie;
          For Row:=0 to 63 do
           With Track_MTM^[Row+1] do
            Begin
            C_Note.Periode:=0;
            If B1 SHR 2 <> 0 Then C_Note.Periode:=b1 SHR 2+24;
            C_Note.Instrument:=((b1 AND 3) SHL 4)+b2 SHR 4;
            C_Note.Commande:=(b2 And $F)+1;
            C_Note.Parametre:=b3;
            If C_Note.Commande=$E+1 Then {Commande ‚tendue}
               Begin
               C_Note.Commande:=$11+(b3 SHR 4);
               C_Note.Parametre:=(b3 And $F)
               End;

            If (C_Note.Commande=Rien2) Then
               Begin
               C_Note.Commande:=CPanning;
               MMSS_CFG^.Calculer_Panning:=True;
               C_Note.Parametre:=Panning_GUS_SB(C_Note.Parametre);
               End;

            If (C_Note.Commande=Arpeggio) And (C_Note.Parametre=0)
               Then C_Note.Commande:=Rien;
            If (C_Note.Commande in [VolSlide,PortUp,PortDown]) AND (C_Note.Parametre=0) Then
               Begin
                C_Note.Commande:=Rien;
                C_Note.Parametre:=0
               End;
            If (C_Note.Commande=SetTempo) Then
               Begin
               If (C_Note.Parametre>$1F) Then C_Note.Commande:=SetBPM;
               If (C_Note.Parametre=0  ) Then C_Note.Commande:=Rien;
               End;


            If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
            Pattern^[Index_Pattern]:=C_Note;
            Inc(Index_Pattern,Ch_Number);
            End;
          End;
        End;
    End;

Dispose(Track_MTM);
Dispose(Track_Seq);
End;  { Charger_Pattern_MTM }

{---------------------------------------------------------}

PROCEDURE Charger_Samples(Var MTM:Ptr_en_tete_MTM;Var Table_Sample:Ptr_Sample);

Begin
Init_Charge_Sample;
{ R‚serve l'espace DOS pour la d‚finition de samples }
Allouer_Samples(MTM^.NbSamples);
Convertir_signe:=True;

f_module.PlacePointeur(194+37*MTM^.NbSamples+192*Longint(MTM^.Nb_Track)+
              (Dernier_Pattern+1)*32*2+MTM^.LongExtra);
 For CHU_NSmp:=1 to MTM^.NbSamples do
  Begin
   New_Sample;
   {Move(Table_Sample^[CHU_NSmp].Nom,Smp.Nom,22);}
   Move(Table_Sample^[CHU_NSmp].Nom,Musique^.PtrInstrNameTable^[CHU_NSmp,1],22);
   Smp.len:=Table_Sample^[CHU_NSmp].long;
   With MMSS_Table^ do
    If (Smp.len>4) And (Table_Sample^[CHU_NSmp].Attrib=0) Then
     Begin

      Smp.rep:=Table_Sample^[CHU_NSmp].Rep;
      Smp_rep_fin:=Table_Sample^[CHU_NSmp].Rep_fin;
      Smp.Volume:=Table_Sample^[CHU_NSmp].Volume;
      if Table_Sample^[CHU_NSmp].Fine>15 then Smp.C4Spd:=8363
      else Smp.C4Spd:=FineTuneConv[Table_Sample^[CHU_NSmp].Fine];	  
      Smp.Info:=0;

      Charger_Sample;

     End  { Smp.len>4 }
     Else If Smp.len>0 Then f_module.DeplacePointeur(Smp.len);
   Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
  End;    { For       }

Fin_Charge_Sample;
End; { Charger_Samples }

{---------------------------------------------------------}

PROCEDURE Charge_MTM(chemin: String80; Var erreur: Word);

Label Fin_Charge_MTM;

Var MTM : Ptr_En_tete_MTM;
    Table_Sample : Ptr_Sample;
    Ch_Number  : Byte;
    nom_fich     : String12;
    i : Integer;
Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  Nom_fichier:=NomFichierSeul(chemin);

  New(MTM);
  New(Table_Sample);

  f_module.LitPos(0,MTM^,Sizeof(MTM^));

  Musique^.Type_Module:=T_MTM;              { Type de module  }
  Musique^.C_Pattern:=False;  
  Musique^.Octave_Min:=2;
  Musique^.Octave_Max:=6;
  Move(MTM^.Nom,Musique^.Titre,20);                 { Titre du module }
  Musique^.Sequence_Len:=MTM^.TailleMusique+1;

  FillChar(FlagPattern,128,0);      {Efface le tableau de flag des patterns}
  Musique^.Pos_de_restart:=0;
  Musique^.Tempo_Start:=6; {MTM^.Tempo;}
  Ch_Number:=MTM^.Nb_voies;
  Musique^.Ch_Number:=Ch_Number;
  Musique^.Ch_Number_Patt:=Ch_Number;

  For i:=1 to MTM^.NbSamples do
      f_module.Lit(Table_Sample^[i],Sizeof(Table_Sample^[1]));

  f_module.Lit(Musique^.Sequence,128);  { Lire la s‚quence }

     { Lecture de la s‚quence et d‚tection d'erreurs de format }

  Erreur_de_chargement:=Err_format;
  Dernier_Pattern:=0;
  If MTM^.IdentMTM<>MTMMagic Then Goto Fin_Charge_MTM; { Erreur dans le format }
  For i:=1 to Musique^.Sequence_Len do
      Begin
      If Musique^.Sequence[i]>127 Then Goto Fin_Charge_MTM; { Erreur dans le format }
      If Musique^.Sequence[i]>Dernier_Pattern Then Dernier_Pattern:=Musique^.Sequence[i];
      FlagPattern[Musique^.Sequence[i]]:=True;
      End;
  IF MTM^.NbSamples<=Max_Samples_MTM Then Erreur_de_chargement:=Ok;

  If Erreur_de_Chargement=Ok Then
     Charger_Pattern_MTM(MTM,Ch_Number); { Charge les patterns }
  If Erreur_de_Chargement=Ok Then
     Charger_Samples(MTM,Table_Sample);    { Charge les samples  }

{  Repeat until readkey=#13;}

  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;

  Dispose(Table_Sample);
  Dispose(MTM);
 Fin_Charge_MTM:        { Label }
  Erreur:=Erreur_de_chargement;
  f_module.Ferme;
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_MOD}

END.
