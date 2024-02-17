{************************************************************************}
{                                CHPTM.PAS                               }
{                                                                        }
{  Loader pour les fichiers PTM. ( Poly Tracker )                        }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le 08/10/95             }
{                               DerniŠres modifications le 08/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChPTM;
{$ELSE}
UNIT ChPTM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES VARUnit,Fichiers,Util,Chutil,MMSS_Mem,MMSS_Var,CRT;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Mem,MMSS_Var,CRT;
{$ENDIF}

PROCEDURE Charge_PTM(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE
     Char4=Array[0..3] of Char;
     Char28=Array[1..28] of Char;

     T_En_tete_PTM=Record
                    Nom      : Array[1..28] of Char;
                    EofMark  : Byte;
                    FVersion : Word;
                    Byte1    : Byte;
                    LongSeq  : Word;
                    NbSampl  : Word;      { Nombre de samples  }
                    NbPatt   : Word;      { Nombre de pattern  }
                    NbVoies  : Word;      { Nombre de voies    }
                    FFlags   : Word;
                    Word1    : Word;
                    SongID   : Char4;     { PTMF }
                    Fill1    : Array[1..16]  of Byte;  { Zone vide }
                    ChannPan : Array[1..32]  of Byte;
                    Sequence : Array[1..256] of Byte;
                    PatSeg   : Array[1..128] of Word;
                   End;

    T_PTM_Instrument=Record
                     SType     : Byte;   { 1:Sample 2:Adlib 3:Midi         }
                     DOSName   : Array[1..12] of CHAR;
                     Volume    : Byte;
                     C4Spd     : Word;   { Fr‚quence pour C-2 (D‚f 8448 Hz)}
                     SmpSeg    : Word;   { Interne !                       }
                     FileOfs   : Longint;{ Position du sample              }
                     Len       : LongInt;
                     Rep       : LongInt;
                     RepEnd    : LongInt;
                     GUSBegin  : Longint;{ Adresse de d‚part GUS (Interne) }
                     GUSLStart : Longint;{ D‚but du bouclage GUS (Interne) }
                     GUSLEnd   : Longint;{ Flags GUS (Interne)             }
                     GUSLoop   : Byte;
                     Byte1     : Byte;
                     Nom       : Char28;
                     Id        : Char4;  { PTMS                            }
                     End;

     Ptr_En_tete_PTM=^T_En_tete_PTM;

VAR PTM : Ptr_En_tete_PTM;
    Ch_Number : Byte;
    Format      : Word;
    PosFichier  : Longint;

{---------------------------------------------------------}

PROCEDURE Charge_pattern(Nb_Patt: Word);
Var Patt: Array[1..5000] of Byte;
    Pattern: Ptr_Patt;

    c   : Byte;
    i,j : Word;
    n   : Word;
    Row : Word;
    Taille: Word;
    Position_Pattern : Word;
    Dernier_Param_E : Array[1..16] of Byte;
    Dernier_Param_VS: Array[1..16] of Byte;
    Param1 : Byte;
Label pattern_ok;

Begin
 Erreur_de_chargement:=Err_memoire;    { Si EXIT, Erreur de m‚moire }
 {Writeln('Nombre de pattern: ',Nb_patt);}
 For n:=1 to Nb_Patt do
  Begin
  {Writeln('Pattern :',n);
  Repeat until Readkey=#13;}
   For i:=1 to Musique^.Sequence_Len do
    If (Musique^.Sequence[i]=n-1) Then
                                  Begin
                                  {Writeln('Ok !');
                                  Repeat until Readkey=#13;}
                                  Goto pattern_ok;
                                  End;
   Continue;  {passe au 'n' suivant}
   pattern_ok:                                            {UMB ,EMS}
   If Not MMSS_MemAlloc(Pointeur_actuel,6*4*Ch_Number,True,False) Then EXIT;
   Pattern:=Pointeur_actuel;
   MMSS_Table^.Seg_Pattern[n]:=Seg(Pointeur_actuel^);
   Musique^.Taille_Pattern[n]:=64;

   FillChar(Dernier_Param_E,16,0);
   FillChar(Dernier_Param_Vs,16,0);
   Fillchar(pattern^,384*Ch_Number,0);
   For i:=1 to Ch_Number*64 do Pattern^[i].Volume:=255;
   Taille:=16*(PTM^.PatSeg[n+1]-PTM^.PatSeg[n]);
   f_module.LitPos(16*LongInt(PTM^.PatSeg[n]),Patt,Taille);                        {Lire le pattern}

   For j:=1 to Ch_Number do
    Begin
     i:=1;
     Row:=0;
     While (i<=Taille) And (Row<64) do
      Begin
       c:=Patt[i];
       Inc(i);
       If c=0 Then Inc(Row)
              Else If (c AND $1F)=(j-1) Then
                    Begin

                     {Effacer partition }
                     C_Note.Commande:=Rien;
                     C_Note.Parametre:=0; C_Note.Instrument:=0;
                     C_Note.Periode:=0; C_Note.Volume:=0;

                     If (c AND $20)<>0 Then   {**** P‚riode et note ****}
                      Begin
                       C_Note.Periode:=i;
                       If C_Note.Periode=254 Then
                          Begin
                          C_Note.Periode:=$FF;  { KeyOff }
                          {Writeln('Key Off');}
                          End
                          Else
                          Begin
                          If (C_Note.Periode>96) Then C_Note.Periode:=0;
                          If C_Note.Periode=0 Then
						      C_Note.Periode:=MMSS_Table^.Table_Period[C_Note.Periode-1];
                             {C_Note.Periode:=PeriodArray[C_Note.Periode-1]}
                          End;
                       C_Note.Instrument:=Patt[i+1];

                       If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
                       Inc(i,2)
                      End;

                     If (c AND $40)<>0 Then   {**** Commande ****}
                      Begin
                       C_Note.Parametre:=Patt[i+1];
                       Case Patt[i] of
                        0: C_Note.Commande:=Arpeggio;
                        1: Begin
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_E[j];
                           Dernier_Param_E[j]:=C_Note.Parametre;
                           If C_Note.Parametre>$E0 Then
                            Begin
                             C_Note.Commande:=FinePortaDown; {Fine ou Extra Fine }
                             If C_Note.Parametre>$F0 Then C_Note.Parametre:=C_Note.Parametre AND $F
                                Else
                                Begin
                                C_Note.Parametre:=(C_Note.Parametre AND $F) SHR 2;
                                If C_Note.Parametre=0 Then C_Note.Commande:=Rien;
                                End;
                            End
                            Else C_Note.Commande:=PortDown;
                           End;
                        2: Begin
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_E[j];
                           Dernier_Param_E[j]:=C_Note.Parametre;
                           If C_Note.Parametre>$E0 Then
                            Begin
                             C_Note.Commande:=FinePortaUp;  { Fine ou Extra Fine }
                             If C_Note.Parametre>$F0 Then C_Note.Parametre:=C_Note.Parametre AND $F
                                Else
                                Begin
                                C_Note.Parametre:=(C_Note.Parametre AND $F) SHR 2;
                                If C_Note.Parametre=0 Then C_Note.Commande:=Rien;
                                End
                            End
                           Else C_Note.Commande:=PortUp;
                           End;
                        3: C_Note.Commande:=TonePortamento;
                        4: C_Note.Commande:=Vibrato;
                        5: C_Note.Commande:=Tone_VSlide;
                        6: C_Note.Commande:=Vib_VSlide;
                        7: C_Note.Commande:=Tremolo;
                        9: C_Note.Commande:=SampleOffs;
                      $0A: Begin
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_Vs[j];
                           Dernier_Param_Vs[j]:=C_Note.Parametre;
                           If C_Note.Parametre>$F0 Then
                            Begin
                             C_Note.Commande:=VolFineDown; {Fine Down}
                             C_Note.Parametre:=C_Note.Parametre AND $F
                            End
                           Else If ((C_Note.Parametre AND $F)=$F) And
                                 (C_Note.Parametre>$F) Then
                                 Begin
                                  C_Note.Commande:=VolFineUp;  {Fine Up}
                                  C_Note.Parametre:=C_Note.Parametre SHR 4
                                 End
                                Else C_Note.Commande:=VolSlide;
                           End;
                      $0B: C_Note.Commande:=JumpPattern;
                      $0C: C_Note.Commande:=SetVolume;
                      $0D: C_Note.Commande:=EndPattern;
                      $0E: Begin                         { Sxy }
                            CASE (C_Note.Parametre AND $F0) SHR 4 of
                                  0:C_Note.Commande:=SetFilter;
                                  1:C_Note.Commande:=FinePortaDown;
                                  2:C_Note.Commande:=FinePortaUp;
                                  4:C_Note.Commande:=VibCtrl;
                                  5:C_Note.Commande:=FineTune;
                                  7:C_Note.Commande:=TremCtrl;
                                  8:Begin { Panning 0->F }
                                    C_Note.Commande:=CPanning;
                                    End;
                                  9:C_Note.Commande:=RetrigNote;
                                 $A:C_Note.Commande:=VolFineUP;
                                 $B:C_Note.Commande:=VolFineDown;
                                 $C:C_Note.Commande:=NoteCut;
                                 $D:C_Note.Commande:=NoteDelay;
                                 $E:C_Note.Commande:=PattDelay;
                                 $F:C_Note.Commande:=Funkit;
                                 End;
                            C_Note.Parametre:=C_Note.Parametre AND $F;
                            IF C_Note.Commande=CPanning Then
                               Begin
                               MMSS_CFG^.Calculer_Panning:=True;
                               C_Note.Parametre:=Panning_GUS_SB(C_Note.Parametre);
                               End;
                            End;
                      $0F: Begin
                            C_Note.Commande:=SetTempo;
                            If C_Note.Parametre=0 Then C_Note.Commande:=Rien;
                            If C_Note.Parametre>$1F Then C_Note.Commande:=SetBPM;
                           End;
                      $10: C_Note.Commande:=SetGVolume;
                      $11: C_Note.Commande:=RetrigNote;
                      $12: Begin
                           C_Note.Commande:=Vibrato;   { Fine Vibrato }
                           Param1:=(C_Note.Parametre AND $0F) SHR 2;
                           C_Note.Parametre:=(C_Note.Parametre AND $F0)+Param1;
                           End;
                        Else Begin
                              C_Note.Commande:=Rien;
                              C_Note.Parametre:=0
                             End
                       End;
                       Inc(i,2)
                      End;

                     If (c AND $80)<>0 Then   {**** Volume ****}
                      Begin
                       C_Note.Volume:=Patt[i]+1;
                       If C_Note.Volume>65 Then C_Note.Volume:=65;
                       Inc(i)
                      End;

                     If (C_Note.Commande=CPanning) Then
                        If C_Note.Parametre>$80 Then
                        Begin
                        C_Note.Commande:=Rien;
                        C_Note.Parametre:=0;
                        End
                        Else MMSS_CFG^.Calculer_Panning:=True;

                     If Row<64 Then
                        Begin
                        Position_Pattern:=j+Ch_Number*Row;
                        DEC(C_Note.Volume); { Attention !!! }
                        Pattern^[Position_Pattern]:=C_Note;
                        End;
                    End
                   Else
                    Begin
                     If (c AND $20)<>0 Then Inc (i,2);
                     If (c AND $40)<>0 Then Inc (i,2);
                     If (c AND $80)<>0 Then Inc (i)
                    End
      End  {While}
    End; {For j}
  End; {For n}
  Erreur_de_chargement:=Ok;
End; {Charge_pattern}

{---------------------------------------------------------}

PROCEDURE Charge_Sampl(NbSampl: Word);

Var PTMSampl: T_PTM_Instrument;
    i,j,k: Integer;
    PremierOffs : Longint;
Begin
 PremierOffs:=0;

 Init_Charge_Sample;
 { R‚serve l'espace DOS pour la d‚finition de samples }
 Allouer_Samples(NbSampl);

 For CHU_NSmp:=1 to NbSampl do
  Begin
   f_module.LitPos(PosFichier,PTMSampl,Sizeof(PTMSampl));
   Inc(PosFichier,Sizeof(PTMSampl));

   New_Sample;

   {Move(PTMSampl.Nom,Smp.Nom,28);}
{   Move(PTMSampl.Nom,Musique^.PtrInstrNameMMSS_Table^[CHU_NSmp,1],24);}
   Smp.len:=PTMSampl.Len;
   Smp.Info:=M_Delta;

   If (PTMSampl.SType AND $10)>0 Then Writeln('16 Bit !!!');
   Writeln('Len: ',Smp.len);

   If (Smp.len>3) AND ((PTMSampl.SType AND $03)=1) {And ((PTMSampl.SType AND $10)=0)} Then
      Begin                   {Pr‚sent et utilis‚ dans la partition }

       If (PTMSampl.SType AND $04)>0 Then  { Instrument boucl‚ }
        Begin
         Smp.rep:=PTMSampl.Rep;
         Smp_rep_Fin:=PTMSampl.RepEnd;
        End
        Else
         Begin
         Smp.rep:=0;
         Smp_rep_Fin:=0;
         End;
       If (PTMSampl.SType AND $08)>0 Then  { bouclage Bidi }
          Smp.Info:=Smp.Info OR M_Bidi;
       If (PTMSampl.SType AND $10)>0 Then  { Sample 16 bit }
          Begin
          Smp.Info:=Smp.Info OR M_16Bit;
          Smp.len:=Smp.len SHR 1;
          Smp.rep:=Smp.rep SHR 1;
          Smp_rep_Fin:=Smp_rep_Fin SHR 1;
          End;

       Smp.Volume:=PTMSampl.Volume;
       If Smp.Volume>64 Then Smp.Volume:=64;
       Smp.C4Spd:=PTMSampl.C4Spd;
{       Smp.Fine_Tune:=0;  }
       If PremierOffs=0 Then PremierOffs:=PTMSampl.FileOfs;
       Writeln('Offset: ',PTMSampl.FileOfs);
       f_module.PlacePointeur(PTMSampl.FileOfs);
       Charger_sample;
      End;

  Repeat until Readkey=#13;

  Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample...  }
  End;

  PTM^.PatSeg[PTM^.NbPatt+1]:=PremierOffs DIV 16; { Fin du dernier pattern }

  Fin_Charge_Sample;
End; {Charge_Sampl}

{---------------------------------------------------------}

PROCEDURE Charge_PTM(chemin: String80; Var erreur: Word);

LABEL FinChPTM;
Var
    Nom_fich: String12;
    i:Integer;
Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok Then
  Begin
  Init_Module;
  Musique^.Type_Module:=T_PTM;            { Type de module  }
  Musique^.C_Pattern:=False;
{  Nom_fichier[Length(nom_fich)+1]:=NomFichierSeul(chemin); }

  New(PTM);
  f_module.LitPos(0,PTM^,Sizeof(PTM^));
  PosFichier:=Sizeof(PTM^);

  Move(PTM^.Nom,Musique^.Titre,28);       { Titre du module }
  Musique^.Octave_Min:=0;
  Musique^.Octave_Max:=7;

  Ch_Number:=PTM^.NbVoies;
  Musique^.Sequence_Len:=PTM^.LongSeq;
  Musique^.Pos_de_restart:=1;                 { Position de bouclage         }
  Musique^.Ch_Number_Patt:=Ch_Number;     { Nb de voies dans un pattern  }
  Musique^.Ch_Number:=Ch_Number;          { Nombre r‚el de voies         }
  Move(PTM^.Sequence,Musique^.Sequence,256);

  If (PTM^.NbVoies>32) OR (PTM^.NbSampl>255) OR (PTM^.NbPatt>128) OR
     (PTM^.LongSeq>256) OR (PTM^.SongID<>'PTMF') Then
     Erreur_de_chargement:=Err_Format
     Else If PTM^.FVersion<>$0203 Then Erreur_de_chargement:=Err_Unknown_Version;

  FillChar(SamplFlags,SizeOf(SamplFlags),1);
  If Erreur_de_chargement=Ok Then
     Charge_Sampl(PTM^.NbSampl);              { Charger les samples  }

  If Erreur_de_chargement In [Ok,Err_Samples] Then
     Charge_pattern(PTM^.NbPatt);             { Charger la partition }

  If Erreur In [Ok,Err_samples] Then
   Begin
   FillChar(MMSS_Table^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }

   If Panning_Utilisable Then                { Table de panning }
      Begin
      MMSS_CFG^.Calculer_Panning:=True;
      For i:=1 to Ch_Number do
             MMSS_MUS^.M_CH_Panning[i]:=Panning_GUS_SB(PTM^.ChannPan[i] AND $0F);
      End;
   Compter_Voies;
   End;
FinChPTM:
  Dispose(PTM);
  f_module.Ferme;
  Erreur:=Erreur_de_chargement;
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_PTM}

END.