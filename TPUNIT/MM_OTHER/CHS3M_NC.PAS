{************************************************************************}
{                                CHS3M.PAS                               }
{                                                                        }
{  Loader pour les fichiers S3M. (Scream Tracker 3.x de Future Crew)     }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le --/08/94             }
{                               DerniŠres modifications le 19/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChS3M;
{$ELSE}
UNIT ChS3M_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES VARUnit,Fichiers,Util,Chutil,MemUnit,MMSS_Var,CRT;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MemUnit,MMSS_Var,CRT;
{$ENDIF}

PROCEDURE Charge_S3M(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE
     Char4=Array[0..3] of Char;
     Char28=Array[1..28] of Char;

CONST
     Version0=$1300;  { ST3.00 }
     Version1=$1301;  { ST3.01 }
     Version2=$1310;  { ST3.10 }

     Max_Samples_S3M=99;
     S3MIdent1=$101A;   {Version + Fichier Song}
     S3MSample:Char4='SCRS';
     S3MAdlib:Char4='SCRI';

TYPE
     T_En_tete_S3M=Record
                    Nom      : Array[1..28] of Char;
                    Ident1   : Word;
                    Inconnu1 : Word;
                    LongSeq  : Word;
                    NbSampl  : Word;
                    NbPatt   : Word;
                    Flags    : Word;      { Limites Amiga, Optim du volume...}
                    Version  : Word;
                    Format   : Word;      { =1 sign‚, =2 non sign‚ }
                    Ident2   : Char4;     { SCRM }
                    Volume   : Byte;      { Volume g‚n‚ral         }
                    Tempo    : Byte;      { Vitesse de d‚marrage   }
                    BPM      : Byte;      { Master Multiplier      }
                    MainVol  : Byte;
                    UltraClR : Byte;      { Ultra click removal    }
                    Def_Pan  : Byte;      { Default Pan ???        }
                    Fill1    : Array[1..10] of Byte;
                    ChannMaps: Array[1..32] of Byte
                   End;

    T_S3M_Instrument=Record
                    Case Boolean of
                    True : (
                     SType     : Byte;  { 1:Sample 2:Adlib 3:Adlib drum  }
                     Name      : Array[1..13] of CHAR;
                     Position  : Word;
                     Len       : LongInt;
                     Rep       : LongInt;
                     RepEnd    : LongInt;
                     Volume    : Word;
                     Byte1     : Byte;
                     Flags     : Byte;  { +1 Boucle,+2 stereo,+4 16 bit   }
                     C4Spd     : Word;  { Fr‚quence pour C-2 (D‚f 8448 Hz)}
                     fill3     : Array[1..10] of Byte;
                     Word3     : Word;
                     Word4     : Word;
                     Comment   : Char28;
                     Id        : Char4;
                           );
                    False : (
                     AType     : Byte;  { 1:Sample 2:Adlib 3:Adlib drum  }
                     AName     : Array[1..13] of Char;
                     AFill1    : Array[1..2] of Byte;
                     AData     : T_OPL2Instr;
                     AByte1    : Byte;
                     AVolume   : Byte;
                     AFill2    : Array[1..3] of Byte;
                     AC4Spd    : Word;
                     AFill3    : Array[1..14] of Byte;
                     AComment  : Char28;
                     AId       : Char4;
                            )
                     End;

     Toffsets   =Array[1..100] of Word;

     Ptr_En_tete_S3M=^T_En_tete_S3M;

     T_Pattern_S3M=Array[1..5000] of Byte;
     Ptr_patt_S3M=^T_Pattern_S3M;

VAR VersionS3M:Byte;
    Ch_Number: Byte;
    Nb_reel_voies:Byte;
    Format : Word;

{---------------------------------------------------------}

PROCEDURE Charge_pattern(Var Pattofs: Toffsets; Nb_Patt: Word);
Var 
    Pattern: Ptr_Patt;
	Pattern_S3M : Ptr_Patt_S3M;
	Taille: Word;
    c,ch,Row : Byte;
    i   : Word;
    n   : Word;
    Position_Pattern : Word;
    Dernier_Param_E  : Array[0..31] of Byte;
    Dernier_Param_VS : Array[0..31] of Byte;
    Param1 : Byte;
    Note   : Byte;
Label pattern_ok;

Begin
 Erreur_de_chargement:=Err_memoire;    { Si EXIT, Erreur de m‚moire }
 nb_reel_voies:=0;
 {Writeln('Nombre de pattern: ',Nb_patt);}
 For n:=1 to Nb_Patt do
  Begin
  {Writeln('Pattern :',n);
  Repeat until Readkey=#13;}
   For i:=1 to Musique^.Sequence_Len do
    If (MMSS_Table^.Sequence[i]=n-1) Then
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
   MMSS_Table^.Taille_Pattern[n]:=64;

   FillChar(Dernier_Param_E,16,0);
   FillChar(Dernier_Param_Vs,16,0);
   Fillchar(pattern^,384*Ch_Number,0);
   For i:=1 to Ch_Number*64 do Pattern^[i].Volume:=255;
   f_module.LitPos(16*LongInt(Pattofs[n]),Taille,2); {Lire la taille du pattern}
   
   If Taille<MaxAvail-1024 Then GetMem(Pattern_S3M,Taille)
      Else Exit;
   f_module.Lit(Pattern_S3M^,Taille);                {Lire le pattern}

{   For j:=1 to Ch_Number do
    Begin}
     i:=1;
     Row:=0;
     While (i<=Taille) And (Row<64) do
      Begin
       c:=Pattern_S3M^[i];
       Inc(i);
       If c=0 Then Inc(Row)
          Else
          Begin
           Ch:=(c AND $1F);
           C_Note.Commande:=Rien;
           C_Note.Parametre:=0; C_Note.Instrument:=0;
           C_Note.Periode:=0; C_Note.Volume:=$FF;
            If (c AND $20)<>0 Then { Note Follow }
                      Begin
                       If Nb_reel_voies<(ch+1) Then Nb_reel_voies:=Ch+1; { D‚tecter le Nb de voies }
                       Note:=Pattern_S3M^[i];
                       If Note=254 Then
                          Begin
                          C_Note.Periode:=$FF;  { KeyOff }
                          {Writeln('Key Off');}
                          End
                          Else
                          Begin                          { Not sure the below test is needed }
                          If Note=255 Then C_Note.Periode:=0
						      Else {If ((Note AND $F0) > $80) OR            
                                      ((Note AND $0F) > $0B) Then 
							      Begin
							       Write('O',Note AND $F0,'N',Note AND $0F);
							       C_Note.Periode:=0;
							      End
								  Else}
                              Begin
							   {C_Note.Periode:=PeriodSet[(Note SHR 4),Note AND $0F]}
							    Note:=(Note SHR 4)*12+Note AND $0F;
							    C_Note.Periode:=Note;
                              End;
                          End;
                       C_Note.Instrument:=Pattern_S3M^[i+1];

                       If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
                       Inc(i,2)
                      End; { Note }

            If (c AND $40)<>0 Then
                      Begin
                       C_Note.Volume:=Pattern_S3M^[i];
                       If C_Note.Volume>64 Then C_Note.Volume:=64;
                       Inc(i)
                      End;

            If (c AND $80)<>0 Then
                      Begin
                       C_Note.Parametre:=Pattern_S3M^[i+1];
                       Case Pattern_S3M^[i] of
                        1: Begin
                            C_Note.Commande:=SetTempo;
                            If C_Note.Parametre=0 Then C_Note.Commande:=Rien;
                           End;
                        2: C_Note.Commande:=JumpPattern;
                        3: C_Note.Commande:=EndPattern;
                        4: Begin
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_Vs[Ch];
                           Dernier_Param_Vs[Ch]:=C_Note.Parametre;
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
                        5: Begin     { E }
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_E[Ch];
                           Dernier_Param_E[Ch]:=C_Note.Parametre;
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
                        6: Begin
                           If C_Note.Parametre=0 Then C_Note.Parametre:=Dernier_Param_E[Ch];
                           Dernier_Param_E[Ch]:=C_Note.Parametre;
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
                        7: C_Note.Commande:=TonePortamento;      { Gxx }
                        8: C_Note.Commande:=Vibrato;             { Hxx }
                        9: C_Note.Commande:=Tremor;              { Ixy }
                        10: C_Note.Commande:=Arpeggio;           { Jxy }
                        11: C_Note.Commande:=Vib_VSlide;         { Kxy }
                        12: C_Note.Commande:=Tone_VSlide;        { Lxy }
                        15: C_Note.Commande:=SampleOffs;         { Oxx }
                        17: C_Note.Commande:=RetrigNote;         { Qxy }
                        18: C_Note.Commande:=Tremolo;            { Rxy }
                        19: Begin                         { Sxy }
                            CASE (C_Note.Parametre AND $F0) SHR 4 of
                                  0:C_Note.Commande:=SetFilter;  { S0x }
                                  1:C_Note.Commande:=GlissCtrl;  { S1x }
                                  2:C_Note.Commande:=FineTune;   { S2x }
                                  3:C_Note.Commande:=VibCtrl;    { S3x }
                                  4:C_Note.Commande:=TremCtrl;   { S4x }
                                  8:Begin { Panning 0->F    S8x }
                                    C_Note.Commande:=CPanning;
                                    End;
                                 $A:C_Note.Commande:=Rien;   { SAx Stereo control }
                                 $B:C_Note.Commande:=JumpLoop;   { SBx }
                                 $C:C_Note.Commande:=NoteCut;    { SCx }
                                 $D:C_Note.Commande:=NoteDelay;  { SDx }
                                 $E:C_Note.Commande:=PattDelay;  { SEx }
                                 $F:C_Note.Commande:=Funkit;     { SFx }
                                 End;
                            C_Note.Parametre:=C_Note.Parametre AND $F;
                            IF C_Note.Commande=CPanning Then
                               Begin
                               MMSS_CFG^.Calculer_Panning:=True;
                               C_Note.Parametre:=Panning_GUS_SB(C_Note.Parametre);
                               End;
                            End;
                        20:Begin                                 { Txx }
                           C_Note.Commande:=SetBPM;              { Set BPM }
                           If C_Note.Parametre<$20 Then
                              Begin
                              C_Note.Commande:=Rien;
                              C_Note.Parametre:=0;
                              End;
                           End;
                        21:Begin { Commande ST3.20 }             { Uxy }
                           C_Note.Commande:=Vibrato;    { Vibrato Fine }
                           Param1:=(C_Note.Parametre AND $0F) SHR 2;
                           C_Note.Parametre:=(C_Note.Parametre AND $F0)+Param1;
                           End;
                        22:C_Note.Commande:=SetGVolume; { Set Global volume (0-40) }
                        Else Begin
                              C_Note.Commande:=Rien;
                              C_Note.Parametre:=0
                             End
                       End;
                       Inc(i,2)
                      End;

            If (C_Note.Commande=CPanning) Then
                        If C_Note.Parametre>$80 Then
                        Begin
                        C_Note.Commande:=Rien;
                        C_Note.Parametre:=0;
                        End
                        Else MMSS_CFG^.Calculer_Panning:=True;

            If ((Row<64) and (Ch<Ch_Number)) Then
                        Begin
                        Position_Pattern:=Ch+Ch_Number*Row+1;
                        Pattern^[Position_Pattern]:=C_Note;
                        End;

          End; { Read Note }
      End;  {While Row}
      FreeMem(Pattern_S3M,Taille);
  End; {For n}
  Erreur_de_chargement:=Ok;
  If Nb_reel_voies>Ch_Number then Nb_reel_voies:=Ch_Number;
End; {Charge_pattern}

{---------------------------------------------------------}

PROCEDURE Charge_Sampl(Var Instroffs: Toffsets; NbSampl: Word);

Var S3MSampl: T_S3M_Instrument;

    i,j,k: Integer;

Begin
 If NbSampl>Max_Samples Then NbSampl:=Max_Samples;

 Init_Charge_Sample;
 { R‚serve l'espace DOS pour la d‚finition de samples }
 If not Allouer_Samples(NbSampl) Then EXIT; 

 For CHU_NSmp:=1 to NbSampl do
  Begin
   f_module.LitPos(16*LongInt(Instroffs[CHU_NSmp]),S3MSampl,Sizeof(S3MSampl));

   New_Sample;
   If (S3MSampl.Id=S3MSample) Then
     Begin
     Move(S3MSampl.Comment,Smp.Nom,28);
     Smp.len:=S3MSampl.Len;
     {Smp.Info:=0;}

     If (Smp.len>3) AND (S3MSampl.Flags<=7) Then
      Begin                   {Pr‚sent et utilis‚ dans la partition }

       If (S3MSampl.Flags AND $01)=1 Then  { Loop }
        Begin
         Smp.rep:=S3MSampl.Rep;
         Smp_rep_Fin:=S3MSampl.RepEnd;
        End
        Else
         Begin
         Smp.rep:=0;
         Smp_rep_Fin:=0;
        End;
		
	   If (S3MSampl.Flags AND $04)<>0 Then  { 16 Bit }
	       Smp.Info:=Smp.Info+M_16Bit;
		   
	    If (S3MSampl.Flags AND $04)<>0 Then { Stereo }
		   Writeln('Stereo Sample Not supported');

       Smp.Volume:=S3MSampl.Volume;
       If Smp.Volume>64 Then Smp.Volume:=64;
       Smp.C4Spd:=S3MSampl.C4Spd;
{       Smp.Fine_Tune:=0;}

       f_module.PlacePointeur(16*LongInt(S3MSampl.Position));
       Charger_sample;

      End;
     End
     Else If (S3MSampl.Id=S3MAdlib) Then
       Begin
       Move(S3MSampl.AComment,Smp.Nom,28);
       Smp.Info:=1;           { 1 => 'Sample' Adlib }
       INC(Nb_instruments);
       If (S3MSampl.SType<>2) Then
          INC(Nb_Pas_Charge)
          Else
          Begin
          Smp.AVolume:=S3MSampl.AVolume;
          Smp.AC4Spd:=S3MSampl.AC4Spd;
          Smp.AData:=S3MSampl.AData;

          Smp.Info:=(Smp.Info OR M_Charge);
          End;
       End
       Else Move(S3MSampl.Comment,Smp.Nom,28);
  Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
  End;

  Fin_Charge_Sample;
End; {Charge_Sampl}

{---------------------------------------------------------}

PROCEDURE Charge_S3M(chemin: String80; Var erreur: Word);

LABEL FinChS3M;
Var S3M: Ptr_En_tete_S3M;
    Instrofs,Pattofs: Toffsets;
    Nom_fich: String12;
    Pan_Present:Boolean;
    Table_Pan:Array[1..32] of Byte;
    i:Integer;
Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok Then
  Begin
  Init_Module;
  Musique^.Type_Module:=T_S3M;            { Type de module  }
  Musique^.C_Pattern:=False;
  Nom_fichier:=NomFichierSeul(chemin);

  New(S3M);
  Pan_Present:=False;

  f_module.LitPos(0,S3M^,Sizeof(S3M^));
  Erreur_de_chargement:=Ok;

  Move(S3M^.Nom,Musique^.Titre,28);       { Titre du module }
  f_module.Lit(MMSS_Table^.Sequence,S3M^.LongSeq);

    { D‚tecter le premier $FF pour la fin de la s‚quence... }
  for i:=1 to 255 do
      If MMSS_Table^.Sequence[i]=$FF Then
         Begin
         S3M^.LongSeq:=i-1;
         Break
         End;

  For i:=1 to 32 do if S3M^.ChannMaps[i]<32 Then Ch_Number:=i;
  If Ch_Number>Max_Channels Then Ch_Number:=Max_Channels;
  Musique^.Sequence_Len:=S3M^.LongSeq;
  Musique^.Pos_de_restart:=1;                 { Position de bouclage         }
  Musique^.Ch_Number_Patt:=Ch_Number;     { Nb de voies dans un pattern  }
  Musique^.Tempo_depart:=S3M^.Tempo;          { Tempo Initial                }
  Musique^.BPM_depart:=S3M^.BPM;              { BPM Initial                  }
  Musique^.Volume_General_depart:=S3M^.Volume;{ Volume g‚n‚ral Initial       }

  If S3M^.Format=2 Then Convertir_signe:=True { Samples sign‚s ou non sign‚s }
                   Else Convertir_signe:=False;

  { Recherche de la version du fichier... }
  If S3M^.Version<=Version0 Then VersionS3M:=0
     Else If S3M^.Version<Version2 Then VersionS3M:=1
             Else VersionS3M:=2;
  If (VersionS3M=2) And (S3M^.Def_Pan=252) Then
     Pan_Present:=True;
  If (VersionS3M<=1) Then Musique^.Volume_Sl_rapide:=True;

     { Gestion des Flag... }
  IF (S3M^.Flags AND 16 )>0 Then
     Begin        { Limites Amiga }
     Musique^.Octave_Min:=3;
     Musique^.Octave_Max:=5;
     End
     Else
     Musique^.Octave_Min:=0;
     Musique^.Octave_Max:=7;
     Begin
     End;
  IF (S3M^.Flags AND 64 )>0 Then Musique^.Volume_Sl_rapide:=True;

  If (S3M^.NbSampl>99) Or (S3M^.NbPatt>100) Then Erreur_de_chargement:=Err_Format
     Else
     Begin
     f_module.Lit(Instrofs,S3M^.NbSampl*2);
     f_module.Lit(Pattofs,S3M^.NbPatt*2);
     If Pan_Present Then f_module.Lit(Table_Pan,32);

     Charge_pattern(Pattofs,S3M^.NbPatt);       { Charger la partition }
     Musique^.Ch_Number:=Nb_reel_voies;       { Nombre r‚el de voies }
     End;

  If Erreur_de_chargement=Ok Then
     Charge_Sampl(Instrofs,S3M^.NbSampl);    { Charger les samples  }

  If Erreur In [Ok,Err_samples] Then
   Begin
   Fixer_Panning(False);   { Initialise Gauche et Droite }
   FillChar(MMSS_Table^.Type_Voie,Musique^.Ch_Number,1); { Voies num‚riques... }
   For i:=1 to Nb_reel_voies do
       If S3M^.ChannMaps[i]<8 Then MPanning[i]:=P_Gauche
          Else If S3M^.ChannMaps[i]<16 Then MPanning[i]:=P_Droite
                  Else If S3M^.ChannMaps[i]<25 Then
                          Begin
                          MMSS_Table^.Type_Voie[i]:=2;
                          MMSS_Table^.Voies_Adlib[S3M^.ChannMaps[i]-15]:=i;
                          End
                          Else MMSS_Table^.Type_Voie[i]:=0;

   If Pan_Present And Panning_Utilisable Then     { Table de panning }
      For i:=1 to Nb_reel_voies do
          If (Table_Pan[i] AND 32)>0 Then
             Begin
             MMSS_CFG^.Calculer_Panning:=True;
             MPanning[i]:=Panning_GUS_SB(Table_Pan[i] AND $0F);
             End;
   Compter_Voies;
   End;
FinChS3M:
  Convertir_signe:=False;
  Dispose(S3M);
  f_module.Ferme;
  Erreur:=Erreur_de_chargement;
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then Musique_Chargee:=True
   Else Init_Module;
End; {Charge_S3M}

END.