{************************************************************************}
{                                CHSTM.PAS                               }
{                                                                        }
{  Loader pour les fichiers STM (cr‚‚s par PSI de Future Crew).          }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le --/11/93             }
{                               DerniŠres modifications le 04/11/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChSTM;
{$ELSE}
UNIT ChSTM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

PROCEDURE Charge_STM(chemin: String80; Var erreur: Word);

IMPLEMENTATION

CONST Max_Samples_STM=31;

TYPE Char8=Array[1..8] of Char;

     T_STM_Instrument=Record
                       Nom     : Array[1..14] of Char;
                       fill1   : Word;
                       Long    : Word;
                       Debut_b,
                       Fin_b   : Word;
                       Volume  : Word;
                       C4Spd   : Word;
                       Fill2   : Array[1..6] of Byte
                      End;

     T_En_tete_STM=Record
                    Nom         : Char20;
                    Ident       : Char8;
                    Fill1       : Longint;
                    Tempo       : Byte;
                    NPatterns   : Byte;
                    Volume      : Byte;
                    Fill2       : Array[1..13] of Byte;
                    Instruments : Array[1..31] of T_STM_Instrument;
                    Sequence    : Byte128
                   End;

     Ptr_En_tete_STM=^T_En_tete_STM;

     T_Note_STM=Record
                 b1,b2,b3,b4: Byte
                End;

     T_Pattern_STM=Array[1..256] of T_Note_STM;

     Ptr_patt_STM=^T_Pattern_STM;

{---------------------------------------------------------}

PROCEDURE Convertir_pattern(Pattern_STM: Ptr_Patt_STM; Pattern: Ptr_Patt;
                            STM: Ptr_En_Tete_STM);
Var J: Integer;
    Note:Byte;
	
Begin
 For j:=1 to 64*4 do
  With Pattern_STM^[j] do
   Begin
    C_Note.Instrument:=0;
    C_Note.Periode:=0;

    If b1<>$FF Then
     Begin
      C_Note.Periode:=b1;
       If ((C_Note.Periode AND $F0)>$70) OR
          ((C_Note.Periode AND $F0)<$00) OR
          ((C_Note.Periode AND $0F)>$0B) Then C_Note.Periode:=0;
      C_Note.Instrument:=b2 SHR 3;
     End;

    If C_Note.Instrument>Max_Samples_STM Then C_Note.Instrument:=0;
    C_Note.Parametre:=b4;
    C_Note.Volume:=((b3 And $F0) SHR 1)+(b2 And $07);
    If C_Note.Volume>64 Then C_Note.Volume:=255;

    Case (b3 AND $F) of
     0: C_Note.Commande:=Rien;
     1: Begin
         C_Note.Commande:=SetTempo;
         C_Note.Parametre:=b4 SHR 4
        End;
     2: C_Note.Commande:=JumpPattern;
     3: C_Note.Commande:=EndPattern;
     4: C_Note.Commande:=VolSlide;
     5: C_Note.Commande:=PortDown;
     6: C_Note.Commande:=PortUp;
     7: C_Note.Commande:=TonePortamento;
     8: C_Note.Commande:=Vibrato;
     9: C_Note.Commande:=Tremor;
     10: C_Note.Commande:=Arpeggio;
     11: C_Note.Commande:=Vib_VSlide;
     Else C_Note.Commande:=Rien
    End;

    If C_Note.Periode<>0 Then                 { Ajustement des notes... }
    Begin
    Note:=((C_Note.Periode SHR 4)+2)*12+C_Note.Periode AND $0F;
	C_Note.Periode:=Note;
	End;
	
    If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
    Pattern^[j]:=C_Note;
   End
End; {Convertir_pattern}

{---------------------------------------------------------}

PROCEDURE ChargeSTM(STM: Ptr_En_Tete_STM);

Var Nb_pattern: Byte;
    i,j : Integer;
    Pattern_STM : Ptr_Patt_STM;

Begin

 Musique^.Sequence_Len:=0;
 For i:=1 to 128 do If STM^.Sequence[i]<99 Then Musique^.Sequence_Len:=i;
 Move(STM^.Sequence,Musique^.Sequence,128);

 Nb_pattern:=STM^.Npatterns;

{***          Charge les patterns          ***}

 Erreur_de_chargement:=Err_memoire;    { Si EXIT, Erreur de m‚moire }
 New(Pattern_STM);

 For i:=1 to Nb_pattern do
  Begin
   IF Not MMSS_MemAlloc(Pointeur_actuel,20*4,True,False) Then
      Begin
      Dispose(Pattern_STM);
      EXIT;
      End;
   MMSS_Table^.Seg_Pattern[i]:=SEG(Pointeur_actuel^);
   Musique^.Taille_Pattern[i]:=64;

   f_module.Lit(Pattern_STM^,256*4);
   Convertir_pattern(Pattern_STM,Pointeur_actuel,STM);
  End;

 Dispose(Pattern_STM);

{***            Charge les instruments            ***}

 Erreur_de_chargement:=Ok;
 Init_Charge_Sample;
 { Allocate the memory for the samples definition }
 If not Allouer_Samples(Max_Samples_STM) Then EXIT; 
 Convertir_signe:=False;

 For CHU_NSmp:=1 to Max_Samples_STM do
  Begin
   New_Sample;
   Move(STM^.Instruments[CHU_NSmp].Nom[1],Musique^.PtrInstrNameTable^[CHU_NSmp,1],14);
   Smp.len:=STM^.Instruments[CHU_NSmp].long;
   With MMSS_Table^ do
    If Smp.len>0 Then
     Begin

      With STM^.Instruments[CHU_NSmp] do   { Bouclage ???? }
       If (Debut_b<>0) OR (Fin_b<>65535) Then
        Begin
         Smp.Rep:=Debut_b; Smp_Rep_fin:=Fin_b
        End
        Else
        Begin
         Smp.Rep:=0; Smp_Rep_fin:=0
        End;
      Smp.Volume:=STM^.Instruments[CHU_NSmp].volume;
      Smp.C4Spd:=STM^.Instruments[CHU_NSmp].C4Spd;

      Charger_sample;

     End;
   Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
  End;

  Fin_Charge_Sample;

End; {ChargeSTM}

{---------------------------------------------------------}

PROCEDURE Charge_STM(chemin: String80; Var erreur: Word);
Var STM: Ptr_En_tete_STM;
    nom_fich: String12;
    Tempo:Byte;
    i:Byte;

Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok Then
  Begin
  Init_Module;
  MMSS_CFG^.Calculer_Panning:=False;
  New(STM);

  f_module.LitPos(0,STM^,Sizeof(STM^));

  Musique^.Type_Module:=T_STM;          { Type de module }
  Musique^.C_Pattern:=False;  
  Move(STM^.nom,Musique^.Titre,20);
  Musique^.Octave_Min:=2;
  Musique^.Octave_Max:=6;
  Nom_fichier:=NomFichierSeul(chemin);

  Tempo:=(STM^.Tempo SHR 4);
  If Tempo=0 Then Tempo:=6;
  Musique^.Pos_de_restart:=1;
  Musique^.Tempo_Start:=Tempo;

  Musique^.Ch_Number:=4;
  Musique^.Ch_Number_Patt:=4;

  Erreur_de_chargement:=Ok;
  For i:=1 to 128 do If STM^.Sequence[i]>99 Then Erreur_de_chargement:=Err_Format;
  IF STM^.Npatterns>99 Then Erreur_de_chargement:=Err_Format;

  If Erreur_de_chargement=Ok Then ChargeSTM(STM);


  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;
  Init_Panning;

  Dispose(STM);
  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_STM}

END.
