{************************************************************************}
{                                CHMOD.PAS                               }
{                                                                        }
{  Loader pour les fichiers MOD (ProTracker - Amiga  4->32 voies :))     }
{                                                                        }
{  AUTEUR: Freddy Vetele.                                                }
{                                                                        }
{  11/4/2019 Correct Portamento                                          }
{                               DerniŠres modifications le 04/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChMOD; {unit‚ pour charger les fichiers MOD }

{$ELSE}
UNIT ChMOD_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
{$ENDIF}

PROCEDURE Charge_MOD(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE Char4=Array[1..4] of Char;

CONST inconnu  =0;   {identificateurs}
                     { 'M.K.' NoiseTracker 4 Voies }
                     { 'FLT4' Startrekker  4 Voies }
                     { 'M!K!' NoiseTracker 4 Voies }
					 { '3CHN' ?            3 Voies }
                     { '6CHN' FastTracker  6 Voies }
                     { '8CHN' FastTracker  8 Voies }
                     { 'FLT8' Startrekker  8 Voies }
                     { 'OCTA' Octalyser    8 Voies }
                     { 'OKTA' Octalyser    8   T_MOD_OS    }
                     { 'CD81' Octalyser (Atari STe et Falcon) }
                     { 'M&K&' NoiseTracker 4 Voies }
                     { 'RASP' Startrekker  4 Voies }
                     { '16CH' TakeTracker 16 Voies }
                     { '32CH' TakeTracker 32 Voies }
                     { 'FA04' Digital F030 4 Voies }
                     { 'FA08' Digital F030 8 Voies }
                     { xxTZ et autres, detection automatique du nb de voies }

      nbr_ident=19;
      Identificateurs: Array[1..nbr_ident] of Char4
                        =('M.K.','FLT4','M!K!','3CHN','6CHN','8CHN','FLT8','OCTA',
                          'CD81','M&K&','RASP','16CH','32CH','FA04','FA08',
                          'TDZ4','TDZ6','TDZ8','OKTA');
      Nb_Voies_Ident: Array[1..nbr_ident] of Byte
                        =(4,4,4,3,6,8,8,8,8,4,4,16,32,4,8,4,6,8,8);
TYPE T_Instrument=Record
                   Nom     : Char22;
                   Long    : Word;
                   Finetune,
                   Vol     : Byte;
                   Debut_b,
                   Long_b  : Word
                  End;

     T_En_tete_15=Record
                   Nom      : Char20;
                   Samples  : Array[1..15] of T_Instrument;
                   Long     : Byte;
                   Boucle   : Byte;
                   Sequence : Byte128
                  End;

     T_En_tete_31=Record
                   Nom      : Char20;
                   Samples  : Array[1..31] of T_Instrument;
                   Long     : Byte;
                   Boucle   : Byte;
                   Sequence : Byte128;
                   Ident    : Char4
                  End;

     Ptr_En_tete_15=^T_En_tete_15;
     Ptr_En_tete_31=^T_En_tete_31;

     T_Note_MOD=Record Case Integer of
                 1: (l          : LongInt);
                 2: (w1,w2      : Word);
                 3: (b1,b2,b3,b4: Byte)
                End;

     T_Pattern_MOD=Array[1..512] of T_Note_MOD;
     Ptr_patt_MOD=^T_Pattern_MOD;

VAR  Ch_Number: Byte;
     Type_Mod:Byte;     {0:31 Instr;1:15 Instr }

{---------------------------------------------------------}

PROCEDURE Convertir_pattern(Pattern_MOD: Ptr_Patt_MOD);
Var i : Byte;
    r,c : Byte;
    j   : Word;
    Period : Word;
Begin
 j:=0;
 C_Note.Volume:=255;
 for r:=1 to 64 do { Row Loop }
  Begin
   for c:=0 to Ch_Number-1 do { Channels Loop }
    Begin
	 j:=j+1;
	 With Pattern_MOD^[j] do
     Begin
     C_Note.Commande:=(b3 And $F)+1;
     C_Note.Parametre:=b4;
     If C_Note.Commande=$E+1 Then {Commande ‚tendue}
      Begin
       C_Note.Commande:=$11+(b4 SHR 4);
       C_Note.Parametre:=(b4 And $F)
     End
     Else
     If (C_Note.Commande=CPanning) Then
        Begin
        If C_Note.Parametre>$80 Then
           Begin
           C_Note.Commande:=Rien;
           C_Note.Parametre:=0;
           End
           Else MMSS_CFG^.Calculer_Panning:=True;
        End;
     If (C_Note.Commande=Arpeggio) And (C_Note.Parametre=0) Then C_Note.Commande:=Rien;
     If (C_Note.Commande=SetTempo) Then
        Begin
         If (C_Note.Parametre>$1F) And (MMSS_CFG^.Use_BPM_CMD) Then C_Note.Commande:=SetBPM;
         If (C_Note.Parametre=0  ) Then C_Note.Commande:=Rien;
        End;

     Period:=b2+(WORD(b1 And $F) SHL 8);
     If Period=0 then i:=0   { Search for the Period in the Period Table }
        Else
        Begin
         i:=35;
         Repeat i:=i+1;
         until (i=12*10) or (MMSS_Table^.Table_Period[i]<=Period);
         i:=i-24   { Perios is *4 }
        End;
       
      C_Note.Periode:=i;
      C_Note.Instrument:=(b3 SHR 4)+(b1 And 16);

     If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
     CP_AddVal;      { Ecrire la note dans la partition }

     End  { With }
    End; { Channels Loop }
   CP_NextRow
  End	{ Row Loop }
End; {Convertir_pattern}

{---------------------------------------------------------}

PROCEDURE Charge_MOD31(MOD31: Ptr_En_Tete_31;Tot_sample: Byte);
Var Nb_pattern: Byte;
    i,j: Integer;
    Pattern_MOD: Ptr_Patt_MOD;

Begin
{Writeln(' Taille Header MOD 31:',SizeOf(MOD31^));}

 Erreur_de_chargement:=Err_format;

 For i:=1 to 128 do if (MOD31^.sequence[i]>128) and (MOD31^.sequence[i]<>255) Then EXIT; { Erreur de format }
 
 Musique^.Sequence_Len:=MOD31^.Long;
 If (Musique^.Sequence_Len=0) or (Musique^.Sequence_Len>128) then EXIT; { Error in Sequence Length }
 
 Musique^.Note_Size:=4;
 
 Nb_pattern:=0;
 For i:=1 to 128 do
  If (Nb_pattern<MOD31^.Sequence[i]) and (MOD31^.Sequence[i]<128) Then
     Nb_pattern:=MOD31^.Sequence[i];
 Inc(Nb_pattern);

 {Writeln('Nb Pattern: ',Nb_Pattern);}

 Move(MOD31^.Sequence,Musique^.Sequence,Musique^.Sequence_Len);
 Check_Used_Pattern;
 {Nb_pattern:=Check_Used_Pattern;}

 With Musique^ do
  If (Pos_de_restart>Sequence_Len ) OR
     (Pos_de_restart=0)  Then Pos_de_restart:=1;

 Erreur_de_chargement:=Err_memoire;    { Si EXIT, Erreur de m‚moire }

{***          Charge les patterns          ***}

 GetMem(Pattern_MOD,64*4*Ch_Number); 

 For i:=1 to Nb_pattern do
  Begin
   If (Musique^.Taille_Pattern[i]=0) {or (i>55) } Then
    Begin { Don't load the pattern not in the sequence }
	f_module.DeplacePointeur(64*4*Ch_Number);
	End
   Else
    Begin

    IF Not CP_NewPattern(4*5*Ch_Number) Then
       Begin
	   Writeln('Last Pattern Loaded:',i,'/',Nb_Pattern);
       {Repeat until Readkey=#13;        }
       FreeMem(Pattern_MOD,64*4*Ch_Number);
       EXIT;
       End;
    MMSS_Table^.Seg_Pattern[i]:=SEG(CP_Pattern^);

    f_module.Lit(Pattern_MOD^,64*4*Ch_Number);
	
    Convertir_pattern(Pattern_MOD);
	
	CP_End; { Resize the Pattern Memory }
	
	{MMSS_Table^.Taille_Pattern[i]:=64;}
   End;
  End;
 FreeMem(Pattern_MOD,64*4*Ch_Number);

{***         Charge les instruments         ***}

 Erreur_de_Chargement:=Ok;
 Init_Charge_Sample;
 { R‚serve l'espace DOS pour la d‚finition de samples }
 If not Allouer_Samples(Tot_Sample) Then EXIT;
 Convertir_signe:=False;

 For CHU_NSmp:=1 to Tot_sample do
  Begin
   New_Sample;
   Move(MOD31^.Samples[CHU_NSmp].Nom[1],Musique^.PtrInstrNameTable^[CHU_NSmp,1],22); {Nom du sample }

{Writeln(Musique^.PtrInstrNameTable^[CHU_NSmp]);}
   Smp.len:=LONGINT(SWAP(MOD31^.Samples[CHU_NSmp].long))*2;

   With MMSS_Table^ do
    If Smp.len>3 Then
     Begin
      Smp.rep:=LONGINT(SWAP(MOD31^.Samples[CHU_NSmp].Debut_b))*2;
      Smp.rep_len:=LONGINT(SWAP(MOD31^.Samples[CHU_NSmp].Long_b))*2;
	  
      Smp_rep_fin:=LONGINT(Smp.rep+Smp.rep_len);
      Smp.Volume:=MOD31^.Samples[CHU_NSmp].vol;
{      Smp.Fine_Tune:=0;}
	  
      if (MOD31^.Samples[CHU_NSmp].FineTune AND $0F =0) then Smp.C4Spd:=8363
      else Smp.C4Spd:=FineTuneConv[MOD31^.Samples[CHU_NSmp].FineTune];

      Charger_Sample;

     End  { Smp.len>4 }
     Else If Smp.len>0 Then f_module.DeplacePointeur(Smp.len);
    Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
   End;
{Repeat until Readkey=#13;}
Fin_Charge_Sample;

{***      Fin du chargement des instruments      ***}

End; {Charge_MOD31}

{---------------------------------------------------------}

PROCEDURE Charge_MOD15(MOD31: Ptr_En_Tete_31);
Var MOD15: Ptr_En_tete_15;
    i: Byte;
Begin
 New(MOD15);
 f_module.LitPos(0,MOD15^,Sizeof(MOD15^));
 MOD31^.Long:=MOD15^.long;
 MOD31^.Boucle:=MOD15^.Boucle;
 For i:=1 to 15 do MOD31^.Samples[i]:=MOD15^.Samples[i];
 MOD31^.Sequence:=MOD15^.Sequence;

 Charge_MOD31(MOD31,15);
 Dispose(MOD15);
End; {Charge_MOD15}

{---------------------------------------------------------}

PROCEDURE Charge_MOD(chemin: String80; Var erreur: Word);

Var MOD31: Ptr_En_tete_31;
    Pattern_MOD: Ptr_patt_MOD;

Function Ident(ModIdent:Char4): Byte;
Var i,j: Byte;
Begin
 i:=1; j:=inconnu;
 Repeat
  If (ModIdent=Identificateurs[i]) Then j:=i;
  Inc(i)
 Until (i>nbr_ident) or (j>0);
 Ident:=j
End;

Procedure Chercher_Ch_Number(ModIdent:Char4);
Var NIdent:Byte;
    i:Byte;
    Chiffre_trouve:Boolean;
Begin
Ch_Number:=0;
NIdent:=Ident(ModIdent);
If NIdent>0 Then
   Begin
   Type_Mod:=0;
   Ch_Number:=Nb_Voies_Ident[NIdent];
   End
   Else
   Begin
           { Recherche d'un nombre dans l'identificateur ... }
   Chiffre_trouve:=False;
   i:=0;
   Repeat
   INC(i);
   If ModIdent[i] in ['0'..'9'] Then Chiffre_trouve:=True;
   Until (i=4) or Chiffre_trouve;
   If Chiffre_trouve Then
      Begin
      Ch_Number:=Ord(ModIdent[i])-48;
      If (i<4) And (ModIdent[i+1] in ['0'..'9']) Then
         Ch_Number:=10*Ch_Number+Ord(ModIdent[i+1])-48;
      End;
   If Ch_Number<>0 Then
      If Ch_Number In [4..32] Then Type_Mod:=0
                                Else Ch_Number:=0;
   End;
IF Ch_Number=0 Then
   Begin
   Ch_Number:=4;
   Type_Mod:=1;
   End;
End;


Begin  {Charge_MOD}
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);
 
 If f_erreur=f_ok then
  Begin
  Init_Module;
  MMSS_CFG^.Calculer_Panning:=False;
  New(MOD31);

  f_module.LitPos(0,MOD31^,Sizeof(MOD31^));

  Musique^.Type_Module:=T_MOD;       { Type de module }
  Musique^.C_Pattern:=True;
  Move(MOD31^.Nom,Musique^.Titre,20);
  Nom_fichier:=NomFichierSeul(chemin);

  Musique^.Pos_de_restart:=MOD31^.Boucle;

   If (ExtensionSeule(Nom_fichier)='WOW') or
      (ExtensionSeule(Nom_fichier)='OCT') Then
     Begin
     Type_Mod:=0;
     Ch_Number:=8;
     End
     Else
     Chercher_Ch_Number(MOD31^.Ident);   { Chercher le Nb de voies        }
                                         { le type du module              }
  If Erreur_de_chargement=Ok Then
   If Type_Mod=0 Then
     Begin
      Musique^.Ch_Number:=Ch_Number;
      Musique^.Ch_Number_Patt:=Ch_Number;
      Charge_MOD31(MOD31,31)
     End
     Else
     Begin
      Musique^.Ch_Number:=Ch_Number;
      Musique^.Ch_Number_Patt:=Ch_Number;
      Charge_MOD15(MOD31)
     End;

Case Nb_Octaves_MOD Of
	 3:Begin
            Musique^.Octave_Min:=3;
            Musique^.Octave_Max:=5;
	   End;
	 5:Begin
            Musique^.Octave_Min:=2;
            Musique^.Octave_Max:=6;
	   End;
	 7:Begin
            Musique^.Octave_Min:=1;
            Musique^.Octave_Max:=7;
	   End
	 End;

  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num‚riques... }
  Compter_Voies;

  Dispose(MOD31);
  Erreur:=Erreur_de_chargement;
  f_module.Ferme
  End
 Else
 Begin
 Writeln(chemin+', File Open Error:',f_erreur);
 Erreur:=Err_lecture  {Impossible d'ouvrir le fichier}
 End;
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_MOD}

END.