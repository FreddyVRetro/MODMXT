{************************************************************************}
{                                CHDTM.PAS                               }
{                                                                        }
{  Loader pour les fichiers DTM (Digital Tracker - Falcon)               }
{                               (et DigiTracker  _ PC    )               }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                                                                        }
{                               DerniŠres modifications le 02/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChDTM;
{$ELSE}
UNIT ChDTM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,MMSS_Mem;
{$ENDIF}

{==========================================================}

PROCEDURE Charge_DTM(chemin: String80; Var erreur: Word);

{==========================================================}

IMPLEMENTATION

TYPE Char4=Array[1..4] of Char;

CONST
    Max_Samples_DTM=63;

    { Chunk Digital Tracker }

    Chunk_Debut       : Char4='D.T.';
    Chunk_Seq         : Char4='S.Q.';
    Chunk_PatternInfo : Char4='PATT'; { Aussi dans le format DigiTracker }
    Chunk_InstrInfo   : Char4='INST';
    Chunk_Pattern     : Char4='DAPT';
    Chunk_Instr       : Char4='DAIT';
    Ver204            : Char4='2.04';

    { Chunk DigiTracker     }

    Chunk_Song        : Char4='SONG';
    Chunk_Name        : Char4='NAME'; { Nom du module        }
    Chunk_Info        : Char4='INFO';
    Chunk_Init        : Char4='INIT'; { BPM,Tempo de d‚part  }
    Chunk_Sequence    : Char4='PSEQ'; { S‚quence             }


TYPE
     String5=String[5];
     Char22=Array[1..22] of Char;

     T_Chunk=RECORD
             Header:Char4;
             Tailleh:Word;      { Partie haute                }
             Taillel:Word;      { Partie basse (MOTOROLA !!!) }
             End;

     T_ChunkDebut=RECORD
             Type_musique:Word;
             Res1:Word;
             Res2:Word;
             Vitesse:Word;
             Tempo:Word;
             Bizarre:Longint;
             Nom:Array[1..20] of Char;
             End;

     T_Chunk_Seq=Record
             Nb_Pos:Word;
             Restart:Word;
             Res1:Longint;
             End;

     T_Chunk_PatternInfo=Record
             Nb_Voies:Word;
             Nb_Patt:Word;
             Version:Array[1..4] of Char;
             End;

     T_Chunk_Pattern=RECORD
             Voies_sauv:Longint;
             Num_Pattern:Word;
             Nb_Lignes:Word;
             End;

     T_Inf_Instr=RECORD
             Res1:Longint;
             Long1,
             Long2:Word;
             Fine:Byte;
             Volume:Byte;
             Rep_Start1,Rep_Start2:Word;
             Rep_Len1,Rep_Len2:Word;
             Nom:Char22;
             TypeInstr:Byte;
             Precision:Byte;
             Midi1,Midi2:Word;
             Freq1,Freq2:Word;
             End;

     TInstrInfos=
      RECORD
      Nom:Char22;
      Smp_len : Longint;
      Smp_rep : Longint;
      Smp_rep_Fin : Longint;
      Fine:Byte;
      Volume:Byte;
      Precision:Byte;    { 8 ou 16 Bit }
      End;

     TNoteDTM=Record Case Integer of
                 1: (l          : LongInt);
                 2: (w1,W2      : Word);
                 3: (b1,b2,b3,b4: Byte)
                End;
     TInstrDTM=ARRAY[1..Max_Samples_DTM] OF TInstrInfos;
     InstrDTM=^TInstrDTM;
     TPatternDTM=Array[1..2048] OF TnoteDTM;  { 32*64 }

VAR Chunk:T_Chunk;
    Taille_Chunk_Actuel:Longint;
    Nb_Voies_DTM:Byte;
    SamplesDTM:^TInstrDTM;
    Version:Byte;
    Nb_InstrDTM:Word;

{---------------------------------------------------------}

PROCEDURE Charger_PatternDTM;

VAR
  PatternDTM:^TPatternDTM;
  Pattern:Ptr_Patt;

  N_Pattern  :Word;
  Nb_Lignes  :Word;
  Taille_Patt:Word;

  Indice:Word;
  Note  :Byte;

  i:Integer;

Begin
 New(PatternDTM);
 f_module.DeplacePointeur(4);
 f_module.Lit(N_Pattern,2);
 f_module.Lit(Nb_Lignes,2);

 N_Pattern:=SWAP(N_Pattern)+1;
 Nb_Lignes:=SWAP(Nb_Lignes);
 If Nb_Lignes>64 Then    { Plus de 64 lignes => Erreur !!! }
    Begin
    Erreur_de_chargement:=Err_Format;
    Dispose(PatternDTM);
    EXIT;
    End;
 If Nb_Lignes>64 Then Nb_Lignes:=64;
 Taille_Patt:=Nb_Lignes*Nb_Voies_DTM*6;

 IF Not MMSS_MemAlloc(Pointeur_actuel,(Taille_Patt DIV 16)+1,True,False) Then
  Begin
   Dispose(PatternDTM);
   Erreur_de_chargement:=Err_Memoire;
   EXIT;
  End;
 Pattern:=Pointeur_actuel;
 MMSS_Table^.Seg_Pattern[N_Pattern]:=SEG(Pointeur_actuel^);
 Musique^.Taille_Pattern[N_Pattern]:=Nb_Lignes;
 f_module.Lit(PatternDTM^,Taille_Patt);

 C_Note.Volume:=255;
 For indice:=1 to Nb_Voies_DTM*Nb_Lignes do
  With PatternDTM^[indice] do
   Begin

   If Version=1 Then
      Begin              { Version 2.04 }
      C_Note.Periode:=0;
      if b1>0 Then
         if (b1 SHR 4)>1 Then
            Begin
            Note:=(b1 SHR 4)*12+b1 AND $0F;
            C_Note.Periode:=Note;
			{C_Note.Periode:=PeriodSet[(b1 SHR 4),(b1 AND $0F)];}
            End;
      {Volume:=b2 SHR 2;}
      {Write(b2 SHR 2,' '); }
      C_Note.Volume:=255; { ????????????? }
      C_Note.Instrument:=((b3 SHR 4)+(b2 AND $03) SHL 4);
      End
      Else               { Autre }
      Begin
      C_Note.Periode:=b2+(WORD(b1 And $7) SHL 8);
      C_Note.Instrument:=(b3 SHR 4)+(b1 And 16);
      C_Note.Volume:=255;
      End;
   If C_Note.Instrument>Max_Samples Then C_Note.Instrument:=0;

   C_Note.Commande:=(b3 AND $0F)+1;
   C_Note.Parametre:=b4;

   If C_Note.Commande=$E+1 Then {Commande ‚tendue}
     Begin
      C_Note.Commande:=$11+(b4 SHR 4);
     C_Note. Parametre:=(b4 And $0F)
     End
    Else
    If (C_Note.Commande=Arpeggio) And (C_Note.Parametre=0) Then C_Note.Commande:=Rien;
   If (C_Note.Commande in [VolSlide,PortUp,PortDown]) AND (C_Note.Parametre=0) Then
     Begin
      C_Note.Commande:=Rien;
      C_Note.Parametre:=0
     End;
   If (C_Note.Commande=SetTempo) Then
       Begin
       If (C_Note.Parametre>$20) Then C_Note.Commande:=SetBPM;
       If (C_Note.Parametre=0  ) Then C_Note.Commande:=Rien;
       End;
   If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
   Pattern^[Indice]:=C_Note;
   End;

 Dispose(PatternDTM);
End; { Charger_PatternDTM }

{---------------------------------------------------------}

Procedure ChSampleDTM;

Begin

f_module.Lit(CHU_NSmp,2);
CHU_NSmp:=SWAP(CHU_NSmp);
Inc(CHU_NSmp);
If (CHU_NSmp>0) AND (SamplesDTM^[CHU_NSmp].Precision=8) AND (CHU_NSmp<=Nb_InstrDTM) Then
   With MMSS_Table^ do
    Begin
    {Move(SamplesDTM^[CHU_NSmp].Nom,Smp.Nom,22);}
	Move(SamplesDTM^[CHU_NSmp],Musique^.PtrInstrNameTable^[CHU_NSmp,1],22);
    Smp.len:=SamplesDTM^[CHU_NSmp].Smp_Len;
    If Smp.len>4 Then
     Begin
      Smp.Info:=0;
      Smp.rep:=SamplesDTM^[CHU_NSmp].Smp_rep;
      Smp_rep_fin:=SamplesDTM^[CHU_NSmp].Smp_rep_fin;
      Smp.Volume:=SamplesDTM^[CHU_NSmp].Volume;

      if SamplesDTM^[CHU_NSmp].Fine>15 then Smp.C4Spd:=8363
        else Smp.C4Spd:=FineTuneConv[SamplesDTM^[CHU_NSmp].Fine];	  


      Charger_Sample;

     End;  { Smp_len>4 }
    Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
    End;
{If Smp_Len>2 Then Repeat until Readkey=#13;}

{***      Fin du chargement de l'instrument      ***}

End; {ChSample}

{---------------------------------------------------------}

PROCEDURE Ch_DTM; {Charge un fichier Digital Tracker }
Var i:Integer;
    Taille_Fich:Longint;
    Position_Fichier:Longint;
    Ch_Debut:T_ChunkDebut;
    Ch_Seq:T_Chunk_Seq;
    Ch_PattInfo:T_Chunk_PatternInfo;
    InstrDTM:^T_Inf_Instr;
    Chunk_Identifie:Boolean;

Begin
  MMSS_CFG^.Calculer_Panning:=False;
  New(SamplesDTM);

  Taille_Fich:=f_module.Taille;    { Lire la taille du fichier }
  Erreur_de_chargement:=Ok;

  Musique^.Type_Module:=T_DTM;     { Type de module }
  Musique^.C_Pattern:=False;  
  Musique^.Octave_Min:=0;
  Musique^.Octave_Max:=7;
  Musique^.Tempo_Start:=6;

  Position_Fichier:=0;
  f_module.PlacePointeur(0);
  Convertir_signe:=False;
  Init_Charge_Sample;

  Repeat

  f_module.Lit(Chunk,Sizeof(Chunk));
  Taille_Chunk_Actuel:=((SWAP(Chunk.Tailleh) SHL 16)+SWAP(Chunk.Taillel));
  Chunk_Identifie:=False;
  If Chunk.Header=Chunk_debut Then
     Begin
     Chunk_Identifie:=True;
     f_module.Lit(Ch_Debut,Sizeof(Ch_Debut));
     Ch_Debut.Vitesse:=SWAP(Ch_Debut.Vitesse);
     Ch_Debut.Tempo:=SWAP(Ch_Debut.Tempo);
     Move(Ch_Debut.Nom,Musique^.Titre,20);   { Titre du module }
     end;

  If Chunk.Header=Chunk_Seq Then
     Begin
     Chunk_Identifie:=True;
     f_module.Lit(Ch_Seq,SizeOf(Ch_Seq));
     Ch_Seq.Nb_Pos:=SWAP(Ch_Seq.Nb_Pos);
     Ch_Seq.Restart:=SWAP(Ch_Seq.Restart);
     f_module.Lit(Musique^.Sequence,Ch_Seq.Nb_Pos);
     Musique^.Sequence_Len:=Ch_Seq.Nb_Pos;
     Musique^.Pos_de_restart:=Ch_Seq.Restart;
     End;

  If Chunk.Header=Chunk_PatternInfo Then
     Begin
     Chunk_Identifie:=True;
     f_module.Lit(Ch_PattInfo,Sizeof(Ch_PattInfo));
     Ch_PattInfo.Nb_Voies:=SWAP(Ch_PattInfo.Nb_Voies);
     Ch_PattInfo.Nb_Patt:=SWAP(Ch_PattInfo.Nb_Patt);

     If Ch_PattInfo.Version=Ver204 Then Version:=1
        Else Version:=0;
     Nb_Voies_DTM:=Ch_PattInfo.Nb_Voies;
     Musique^.Ch_Number:=Ch_PattInfo.Nb_Voies;
     Musique^.Ch_Number_Patt:=Ch_PattInfo.Nb_Voies;
     End;

  If Chunk.Header=Chunk_InstrInfo then
      Begin
      Chunk_Identifie:=True;
      f_module.Lit(Nb_InstrDTM,2);
      Nb_InstrDTM:=SWAP(Nb_InstrDTM);
      { R‚serve l'espace DOS pour la d‚finition de samples }
      Allouer_Samples(Nb_InstrDTM);
      New(InstrDTM);
      if Nb_InstrDTM>Max_Samples_DTM Then Nb_InstrDTM:=Max_Samples_DTM;
      For CHU_NSmp:=1 to Nb_InstrDTM do
          Begin
          f_module.Lit(InstrDTM^,SizeOf(InstrDTM^));
          New_Sample;

          Smp.Len:=SWAP(InstrDTM^.Long1) SHL 16+SWAP(InstrDTM^.Long2);
          Smp.Rep:=SWAP(InstrDTM^.Rep_Start1) SHL 16+SWAP(InstrDTM^.Rep_Start2);
          Smp.Rep_Len:=SWAP(InstrDTM^.Rep_Len1) SHL 16+SWAP(InstrDTM^.Rep_Len2);
          {  Ajuster les valeurs du sample  }
          If Smp.Rep_Len<3 Then
             Begin
             Smp.rep:=0; Smp_rep_fin:=0 ; Smp.rep_Len:=0;
             End
             Else
             Begin
             If Smp.rep_len>Smp.len Then Smp.rep_len:=Smp.len;
             If Smp.rep_len+Smp.rep>Smp.len Then Smp.rep:=Smp.len-Smp.rep_len;
             Smp_rep_fin:=Smp.rep+Smp.rep_len;
             End;
          SamplesDTM^[CHU_NSmp].Nom:=InstrDTM^.Nom;
          SamplesDTM^[CHU_NSmp].Smp_Len:=Smp.Len;  { Sauver les carracteristiques }
          SamplesDTM^[CHU_NSmp].Smp_rep:=Smp.rep;  { du sample                    }
          SamplesDTM^[CHU_NSmp].Smp_rep_Fin:=Smp_rep_Fin;
          SamplesDTM^[CHU_NSmp].Fine:=InstrDTM^.Fine;
          SamplesDTM^[CHU_NSmp].Volume:=InstrDTM^.Volume;
          SamplesDTM^[CHU_NSmp].Precision:=InstrDTM^.Precision;

          End;
      Dispose(InstrDTM);
      End;
  If Chunk.Header=Chunk_Pattern then
     Begin
     Chunk_Identifie:=True;
     Charger_PatternDTM;
     End;

  If Chunk.Header=Chunk_Instr then
     Begin
     Chunk_Identifie:=True;
     ChSampleDTM;
     End;

  Position_Fichier:=Position_Fichier+Taille_Chunk_Actuel+8;
  f_module.PlacePointeur(Position_Fichier);
  If Not Chunk_Identifie Then Erreur_de_Chargement:=Err_Format;
  If Taille_Chunk_Actuel=0 Then Erreur_de_Chargement:=Err_Format;
  Until (Position_fichier>Taille_fich) or (Erreur_de_Chargement<>Ok);

  Fin_Charge_Sample;
  Dispose(SamplesDTM);

  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;
End; {Ch_DTM}

{---------------------------------------------------------}

PROCEDURE Ch_DT;
Begin
Erreur_de_Chargement:=Err_Non_Gere;
End; {Ch_DT}

{---------------------------------------------------------}

PROCEDURE Charge_DTM(chemin: String80; Var erreur: Word);
Var
   Nom_fich: String12;

Begin  {Charge_DTM}
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  Nom_fichier:=NomFichierSeul(chemin);

  f_module.Lit(Chunk,Sizeof(Chunk));            { D‚tecter le type du module }
  If Chunk.Header=Chunk_debut Then Ch_DTM       { Digital Tracker }
     Else If Chunk.Header=Chunk_Song Then Ch_DT { DigiTracker     }
             Else Erreur:=Err_Format;

  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_DTM}
END.