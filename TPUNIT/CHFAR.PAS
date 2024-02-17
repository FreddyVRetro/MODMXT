{************************************************************************}
{                                CHFAR.PAS                               }
{                                                                        }
{  Loader pour les fichiers FAR (par Daniel Potter (Farandole Tracker))  }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le 25/08/95             }
{                               DerniŠres modifications le 02/11/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChFAR;
{$ELSE}
UNIT ChFAR_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

{==========================================================}

PROCEDURE Charge_FAR(chemin: String80; Var erreur: Word);

{==========================================================}

IMPLEMENTATION


TYPE TFARHeader=RECORD
                Ident     : Array[1..4]  of Char;   {  'FARþ'  }
                Titre     : Array[1..40] of Char;
                Ident1    : Array[1..3]  of Byte;   { 13,10,26 }
                HdrLen    : Word;
                Version   : Byte;
                ChannMap  : Array[1..16] of Byte;
                CurrOct   : Byte;   {Current editing octave             }
                CurrVoi   : Byte;   {Current editing voice              }
                CurrRow   : Byte;   {Current editing row                }
                CurrPatt  : Byte;   {Current editing pattern            }
                CurrOrd   : Byte;   {Current editing order              }
                CurrSamp  : Byte;   {Current editing sample             }
                CurrVol   : Byte;   {Current editing volume             }
                CurrTOS   : Byte;   {Current Top Off Screen display     }
                CurrEAS   : Byte;   {Current editing area on the screen }
                CurrTempo : Byte;   {Current tempo (default tempo)      }
                PannMap   : Array[1..16] of Byte;
                MarkTop   : Byte;
                MarkBot   : Byte;
                Gridgr    : Byte;   { Grid granularity                  }
                EditMode  : Byte;
                TextLen   : Word;
                END;

     T_Smp_FAR =Record
                Nom :Array[1..32] of Char;
                Len :Longint;
                Fine: Byte;
                Vol : Byte;
                Rep : Longint;
                Rep_Fin : Longint;
                SType   : Byte;
                SLMode  : Byte;
                End;

     T_Note_FAR=Record
                 b1,b2,b3,b4: Byte
                End;

     T_Pattern_FAR=Array[1..512] of T_Note_FAR;
     Ptr_patt_FAR=^T_Pattern_FAR;

     TPattSize=Array[1..256] of Word;

VAR PattSize:^TPattSize;

{---------------------------------------------------------}

PROCEDURE Charge_Pattern;
Var Nb_Colonnes:Integer;
    Tempo : Byte;
    i,j   : Integer;
    Pattern_FAR : Ptr_patt_FAR;
    Pattern: Ptr_Patt;

Begin

GetMem(Pattern_FAR,256*4*16);   { Tampon pour le chargement de la partition }
For i:=1 to 256 do
 If PattSize^[i]<>0 Then
 Begin
 Nb_Colonnes:=0;
 f_module.Lit(Nb_Colonnes,1);
 f_module.Lit(Tempo,1);

 Nb_Colonnes:=(PattSize^[i]-2) DIV (16*4);
 Musique^.Taille_Pattern[i]:=Nb_Colonnes;
 If Not MMSS_MemAlloc(Pointeur_actuel,6*Nb_Colonnes,True,False) Then
      Begin
      FreeMem(Pattern_FAR,256*4*16);
      EXIT;
      End;

 Pattern:=Pointeur_actuel;
 MMSS_Table^.Seg_Pattern[i]:=SEG(Pointeur_actuel^);
 f_module.Lit(Pattern_FAR^,(PattSize^[i]-2));

 For j:=1 to Nb_Colonnes*16 do
  With Pattern_FAR^[j] do
   Begin
    C_Note.Commande:=(b4 SHR 4);
    C_Note.Parametre:=b4 AND $0F;
    Case C_Note.Commande of
         $0F :C_Note.Commande:=SetTempo;
         $07 :Begin
              C_Note.Commande:=VolSlide;
              C_Note.Parametre:=C_Note.Parametre SHL 4;
              End;
         $08 :C_Note.Commande:=VolSlide;
         $0B :Begin
              C_Note.Commande:=CPanning;
              MMSS_CFG^.Calculer_Panning:=True;
              C_Note.Parametre:=Panning_GUS_SB(C_Note.Parametre);
              End;
         Else Begin
              C_Note.Commande :=0;
              C_Note.Parametre:=0;
              End;
         End;

    IF b1>0 Then
       Begin
       C_Note.Instrument:=b2+1;
	   C_Note.Periode:=b1+12*3-1;
       End
       Else
       Begin
       C_Note.Instrument:=0;
       C_Note.Periode:=0;
       End;

    If (b3 AND $0F)=0 Then
      C_Note.Volume:=255
      Else
      C_Note.Volume:=((b3 AND $0F)-1) SHL 2;

    If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
    Pattern^[j]:=C_Note;    { Ecrire la note dans la partition }
   End
 End;
FreeMem(Pattern_FAR,256*4*16);

End; {Charge_Pattern}

{---------------------------------------------------------}

PROCEDURE Charge_Samples_FAR;
Var Smp_FAR : T_Smp_FAR;
    SFlag   : Array[0..7] of Byte;
    i       : Integer;
    Nb_Smp_FAR : Byte;
Begin

Init_Charge_Sample; { R‚serve l'espace DOS pour la d‚finition de samples }

f_module.Lit(SFlag,8);
For i:=0 to 63 do If ((SFlag[i DIV 8]) And (1 SHL (i MOD 8))) >0 Then
    Nb_Smp_FAR:=i+1;

Allouer_Samples(Nb_Smp_FAR);
Convertir_signe:=False;

For CHU_NSmp:=1 to Nb_Smp_FAR do
    Begin
    New_Sample;
    If ((SFlag[(CHU_NSmp-1) DIV 8]) And (1 SHL ((CHU_NSmp-1) MOD 8))) >0 Then
       Begin
       f_module.Lit(Smp_FAR,SizeOf(Smp_FAR));
      { Move(Smp_FAR.Nom,Smp.Nom,32); }{Nom du sample }
	   Move(Smp_FAR.Nom,Musique^.PtrInstrNameTable^[CHU_NSmp,1],24);
	   
       Smp.Len:=Smp_FAR.Len;
       If (Smp.Len>0) Then
          Begin
          If Smp_FAR.SLMode=0 Then
             Begin       { No Loop }
              Smp.Rep:=0;
              Smp_Rep_Fin:=0;
             End
             Else        { Loop     }
             Begin
			  Smp.Info:=Smp.Info OR M_Boucle;
              Smp.Rep:=Smp_FAR.Rep;
              Smp_Rep_Fin:=Smp_FAR.Rep_Fin;
             End;
		  { Need to Add 16 Bit smple support }	 
          Smp.Rep_Len:=0;
          Smp.Volume:=64;
          Smp.C4Spd:=8363;
{          Smp.Fine_Tune:=0;}

          Charger_Sample;
          End;
       End;
    Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
    End;
Fin_Charge_Sample;

End; { Charge_Samples_FAR }

PROCEDURE Charge_FAR(chemin: String80; Var erreur: Word);
Var FichFAR  : TFARHeader;
    nom_fich : String12;
    Nb_Patt  : Byte;
    i:Integer;

Begin  {Charge_FAR}
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  Nom_fichier:=NomFichierSeul(chemin);
  
  f_module.LitPos(0,FICHFAR,Sizeof(FICHFAR));

  Musique^.Type_Module:=T_FAR;
  Musique^.C_Pattern:=False;  
  Move(FICHFAR.Titre,Musique^.Titre,32);        { Titre du module }
  Musique^.Tempo_Start:=4;
  Musique^.Ch_Number:=16;
  Musique^.Ch_Number_Patt:=16;
  Musique^.BPM_Start:=80;        { Base 32ø de seconde => 125*32/50=80 }

  f_module.DeplacePointeur(FICHFAR.TextLen);
  f_module.Lit(Musique^.Sequence,Max_Pattern);  { If Max_Pattern<256) }
  f_module.DeplacePointeur(256-Max_Pattern);
  f_module.Lit(Nb_Patt,1);
  f_module.Lit(Musique^.Sequence_Len,1);
  If Musique^.Sequence_Len>Max_Pattern Then Musique^.Sequence_Len:=Max_Pattern;
  
  f_module.Lit(Musique^.Pos_de_restart,1);
  New(PattSize);
  f_module.Lit(PattSize^,256*2);

  If (FICHFAR.HdrLen-(869+FICHFAR.TextLen))>0  { en tˆte plus grand ? }
     Then f_module.DeplacePointeur(869+FICHFAR.TextLen);
  For i:=1 to 256 do
      If (PattSize^[i]<67) And (PattSize^[i]>0) Then  { 0 lignes }
         Erreur_de_chargement:=Err_format;

  If Erreur_de_chargement=Ok Then Charge_Pattern;

  Dispose(PattSize);

  If Erreur_de_chargement=Ok Then Charge_Samples_FAR;

{  Musique^.Octave_Min:=3;
  Musique^.Octave_Max:=5;}

  Musique^.Octave_Min:=0;
  Musique^.Octave_Max:=7;

  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;

  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module; { Initialiser le Module il est incorrect... }
End; {Charge_FAR}

END.