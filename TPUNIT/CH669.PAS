{************************************************************************}
{                                CH669.PAS                               }
{                                                                        }
{  Loader pour les fichiers 669 (par TRAN de Renaissance) et E669.       }
{                                                                        }
{  AUTEUR: Freddy Vetele.                                                }
{                                                                        }
{                               Debut d'ecriture le --/11/94             }
{                               Dernieres modifications le 02/11/95      }
{************************************************************************}

{$UNDEF Groupe}
{$DEFINE NoGUS}

{$IFNDEF Groupe}
UNIT Ch669;
{$ELSE}
UNIT Ch669_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

{==========================================================}

PROCEDURE Charge_669(chemin: String80; Var erreur: Word);

{==========================================================}

IMPLEMENTATION

CONST
     Max_Samples_669=64;
     Ident669=$6669;    { 'if' }
     IdentUni669=$4E4A; { 'jn' }
TYPE
     TSizes=ARRAY[1..128] of byte;

     T669Header=
       RECORD
         Ident        : WORD;
         Comment      : ARRAY[1..3, 1..36] of CHAR;
         NSamples     : BYTE;
         NPatterns    : BYTE;
         RepStart     : BYTE;
         Sequence     : Byte128;
         Tempos       : ARRAY[1..128] of BYTE;
         Lengths      : TSizes;
       END;

     T669Instrument=
       RECORD
        Name     : ARRAY[1..13] of CHAR;
        Size     : LONGINT;
        RepStart : LONGINT;
        Replen   : LONGINT;
        END;

     T669Pattern = ARRAY[1..64,1..8] of
      RECORD
       CASE BYTE of
        0 : ( w1: WORD;
              b : BYTE );
        1 : ( b1,b2,b3:BYTE);
       END;

     Ptr_En_tete_669=^T669Header;

{---------------------------------------------------------}

PROCEDURE Charger_pattern(VAR Sizes:TSizes;Num:WORD);

VAR
  Patt    : T669Pattern;
  Pattern : Ptr_Patt;
  i,j  :WORD;
  t,n  :WORD;

Begin

{***          Charge les patterns          ***}

FOR n:=1 to Num do
 BEGIN
 IF Not MMSS_MemAlloc(Pointeur_actuel,24*8,False,False) Then EXIT;
 MMSS_Table^.Seg_Pattern[n]:=SEG(Pointeur_actuel^);
 Musique^.Taille_Pattern[n]:=Sizes[n]+1;

 Pattern:=Pointeur_actuel;
 f_module.Lit(Patt,SizeOf(Patt));
 For j:=1 to 8 do
   BEGIN
   For i:=1 to 64 do
      WITH Patt[i][j] do
       BEGIN
        C_Note.Instrument:=0;
        C_Note.Periode:=0;
        C_Note.Volume:=255;
        C_Note.Commande:=0;
        C_Note.Parametre:=0;
        IF b1<$FE Then
           Begin
		   {C_Note.Periode:=MMSS_Table^.Table_Period[b1 SHR 2+24];}
           C_Note.Periode:=b1 SHR 2+24;
           C_Note.Instrument:= ((SWAP(w1) SHR 4) AND 63)+1;
           End;
        IF b1<$FF Then
           C_Note.Volume:=((b2 AND 15) SHL 2)+((b2 AND 15) SHR 2);
        C_Note.Parametre:=b3 AND 15;
        C_Note.Commande:=Rien;
        If C_Note.Parametre<>0 Then
           CASE b3 SHR 4 OF
             0: C_Note.Commande:=PortUp;
             1: C_Note.Commande:=PortDown;
             2: C_Note.Commande:=TonePortamento;
             3: Begin
                C_Note.Commande:=FreqAdj;
                {If C_Note.Periode<>0 Then INC(C_Note.Periode);}
                End;
             4: Begin
                C_Note.Commande:=Vibrato;
                C_Note.Parametre:=(C_Note.Parametre SHL 4)+1;
                End;
             5: C_Note.Commande:=SetTempo;
           End;
       If C_Note.Commande=Rien Then C_Note.Parametre:=0;

       If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
       Pattern^[j+8*(i-1)]:=C_Note;
       End;
   End;
 End;

End; {Charger_pattern}

{---------------------------------------------------------}

PROCEDURE Charger_Donnees_Samples(Num:Byte);
VAR Instr669:T669Instrument;

Begin
{ R�serve l'espace DOS pour la d�finition de samples }
Allouer_Samples(Num);

For CHU_NSmp:=1 to Num do
  Begin
  f_module.Lit(Instr669,SizeOf(Instr669));
  New_Sample;

  {MOVE(Instr669.Name[1],Smp.Nom,13);}
  Move(Instr669.Name[1],Musique^.PtrInstrNameTable^[CHU_NSmp,1],13);
  
  Smp.len:=Instr669.Size;
  Smp.rep_len:=Instr669.RepLen;
  Smp.rep:=Instr669.RepStart;

  Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); {Sauvegarde du Sample}
  End;
End; { Charger_Donnees_Samples }

{---------------------------------------------------------}

PROCEDURE Charger_Samples669(Num:Byte);

VAR
    i,j: Integer;

BEGIN

{***         Charge les samples         ***}

 Init_Charge_Sample;
 Convertir_signe:=True;

 If Num>Max_Samples Then Num:=Max_Samples;

 For CHU_NSmp:=1 to Num do
  Begin
   Move(MMSS_Table^.PtrSamples[CHU_NSmp]^,Smp,SizeOf(Smp)); { Charger le sample }
   With MMSS_Table^ do
    If Smp.len>0 Then
     Begin

      If Smp.rep_len=65535 Then Smp.rep_len:=0; { Ajustement des donn�es }
      If Smp.rep_len>Smp.len Then Smp.rep_len:=0;
      If Smp.rep_len+Smp.rep>Smp.len Then Smp.rep:=Smp.len-Smp.rep_len;
      Smp_rep_fin:=Smp.rep+Smp.rep_len;

      Charger_Sample;

    End;  { Smp_len>4 }
   Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
  End;    { For       }

Fin_Charge_Sample;

{***      Fin du chargement des Samples      ***}

END; { Charger_Samples669 }

{---------------------------------------------------------}

PROCEDURE Charge_669(chemin: String80; Var erreur: Word);

Var FICH669  : Ptr_En_tete_669;
    Long669  : Byte;
    i:Integer;

Begin  {Charge_669}
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  Nom_fichier:=NomFichierSeul(chemin);

  MMSS_CFG^.Calculer_Panning:=False;
  New(FICH669);

  f_module.LitPos(0,FICH669^,Sizeof(FICH669^));

  Musique^.Type_Module:=T_669;                     { Type de module  }
  Musique^.C_Pattern:=False;
  Musique^.Octave_Min:=2;                          { Octaves...      }
  Musique^.Octave_Max:=6;
  Move(FICH669^.Comment[1,1],Musique^.Titre,32);   { Titre du module }

  { Titre du module }

  For i:=1 to 128 do
      If FICH669^.Sequence[i]<128 Then Musique^.Sequence_Len:=i;

  If FICH669^.Ident<>IdentUni669 Then
     Move(FICH669^.Tempos,Musique^.Tempo_Pattern,128);  { Placer les tempos }

  Move(FICH669^.Sequence,Musique^.Sequence,128);     { Copie de la s�quence }
  Musique^.Pos_de_restart:=FICH669^.Repstart+1;
  Musique^.Tempo_Start:=4;
  Musique^.Ch_Number:=8;
  Musique^.Ch_Number_Patt:=8;
  Musique^.BPM_Start:=80;        { Base 32� de seconde => 125*32/50=80 }

  Erreur_de_chargement:=Ok;

  If FICH669^.NSamples=0 Then
     Erreur_de_chargement:=Err_No_Sample;

  If FICH669^.NSamples>Max_Samples_669 Then
     Erreur_de_chargement:=Err_Format;

  If Erreur_de_chargement=Ok Then
     Charger_Donnees_Samples(FICH669^.NSamples);

  If Erreur_de_chargement=Ok Then
     Charger_Pattern(FICH669^.Lengths,FICH669^.NPatterns);

  If Erreur_de_chargement=Ok Then
     Charger_Samples669(FICH669^.NSamples);

  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num�riques... }
  Compter_Voies;

  Dispose(FICH669);

  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module; { Initialiser le Module il est incorrect... }
End; {Charge_669}

END.