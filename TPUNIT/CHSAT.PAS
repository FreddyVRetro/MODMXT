{************************************************************************}
{                                CHSAT.PAS                               }
{                                                                        }
{  Loader pour les fichiers SAT ( Surprise Adlib Tracker )               }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le 21/09/95             }
{                               DerniŠres modifications le 04/10/95      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChSAT;
{$ELSE}
UNIT ChSAT_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Mem,MMSS_Var,GusUnit,CRT;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Mem,MMSS_Var,GusUnit,CRT;
{$ENDIF}

{==========================================================}

PROCEDURE Charge_SAT(chemin: String80; Var erreur: Word);

{==========================================================}

IMPLEMENTATION

CONST NbInstSAT=31;
      Nb_VoiesSAT=9;
	  
      SAT_String : String20 = 'Surp Adlib Tracker';
	  
TYPE
    TInstrDT=RECORD
             SFeedBack : Byte;
             SM1,SP1   : Byte;
             SM3,SP3   : Byte;
             SM4,SP4   : Byte;
             SM5,SP5   : Byte;
             SM2,SP2   : Byte;
             END;

     TInstrData=Array[1..31] of TInstrDT;


     TInstrNom=Array[1..29] of
               RECORD
               b1  : Byte;
               Nom : Array[1..16] of Char;
               End;

     TSATHeader=RECORD
                Ident : Array[1..4] of Char;
                Vers  : Byte;
                END;

    PtrSATInstr = ^TInstrData;
    PtrSATNom   = ^TInstrNom;

    T_Note_SAT=Record
               No,Ins,Co,P1,P2:Byte;
               End;

    T_Pattern_SAT=Array[1..576] of T_Note_SAT;
    Ptr_patt_SAT=^T_Pattern_SAT;


CONST InstrVide:TInstrDT=(SFeedback:$01;SM1:$00;SP1:$00;SM3:$00;SP3:$00;
                          SM4:$F0;SP4:$F0;SM5:$00;SP5:$00;SM2:$3F;SP2:$3F);

VAR Nb_Pattern:Byte;
    Version   :Byte;

{---------------------------------------------------------}

PROCEDURE ChargePatt;
VAR i,j:Word;
    Pattern_SAT:Ptr_patt_SAT;
    Pattern: Ptr_Patt;
Begin
GetMem(Pattern_SAT,64*Nb_VoiesSAT);

For i:=1 to Nb_pattern do
  Begin
   IF Not MMSS_MemAlloc(Pointeur_actuel,24*Nb_VoiesSAT,True,False) Then
      Begin
      FreeMem(Pattern_SAT,64*Nb_VoiesSAT);
      EXIT;
      End;
   MMSS_Table^.Seg_Pattern[i]:=SEG(Pointeur_actuel^);
   Pattern:=Pointeur_actuel;

   f_module.Lit(Pattern_SAT^,320*Nb_VoiesSAT);
{   Writeln('Pattern: ',i);}
   C_Note.Volume:=255;
    For j:=1 to 64*Nb_VoiesSAT do
     With Pattern_SAT^[j] do
      Begin
{       Write('Note: ',No,'Instr: ',Ins,'Commande: ',Co,'P1: ',P1,'P2: ',P2);}
{       Repeat until Readkey=#13;}
       C_Note.Periode:=0;
       C_Note.Commande:=Co+1;
       C_Note.Parametre:=(P1 SHL 4)+P2;

       If (No<>0) Then              { P‚riode        }
          If (Version<5) Then
             C_Note.Periode:=No+2*11+1
             Else
             If No>1 Then C_Note.Periode:=No-1;

       If C_Note.Commande=$E+1 Then {Commande ‚tendue}
        Begin
         C_Note.Commande:=$11+P1;
         C_Note.Parametre:=P2
        End;
       If (C_Note.Commande=CPanning) Then
          Begin
          C_Note.Periode:=$FF;
          C_Note.Commande:=0;
          End;
       If (C_Note.Commande=Arpeggio) And (C_Note.Parametre=0) Then C_Note.Commande:=Rien;
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

       C_Note.Instrument:=Ins;      { Instrument     }

       If C_Note.Instrument <>0 Then SamplFlags[C_Note.Instrument]:=True;
       Pattern^[j]:=C_Note;    { Ecrire la note dans la partition }
      End

  End;
FreeMem(Pattern_SAT,64*Nb_VoiesSAT);
END;

{---------------------------------------------------------}

PROCEDURE ChargeInstr(SATInstr:PtrSATInstr;SATNom:PtrSATNom);
BEGIN

{ Init_Charge_Sample;}
 { R‚serve l'espace DOS pour la d‚finition de samples }

 Nb_instruments:=0;
 If Allouer_Samples(NbInstSAT) Then
  Begin
  For CHU_NSmp:=1 to NbInstSAT do
   Begin
    New_Sample;
    If CHU_NSmp<30 Then Move(SATNom^[CHU_NSmp].Nom,Musique^.PtrInstrNameTable^[CHU_NSmp,1],16);

    Smp.Info:=1;           { 1 => 'Sample' Adlib }
    INC(Nb_instruments);
    {Smp.AVolume:=64;}  { Changer le Def Volume a la valeur du volume du sample }
    Smp.AC4Spd :=8363;
    With SATInstr^[CHU_NSmp] do
        Begin
        Smp.AData.AM1:=SM1;
        Smp.AData.AP1:=SP1;
        Smp.AData.AM2:=SM2;
        Smp.AData.AP2:=SP2;
        Smp.AData.AM3:=SM3;
        Smp.AData.AP3:=SP3;
        Smp.AData.AM4:=SM4;
        Smp.AData.AP4:=SP4;
        Smp.AData.AM5:=SM5;
        Smp.AData.AP5:=SP5;
       {Smp.AData.AM1:=SP1;
        Smp.AData.AP1:=SM1;
        Smp.AData.AM2:=SP2;
        Smp.AData.AP2:=SM2;
        Smp.AData.AM3:=SP3;
        Smp.AData.AP3:=SM3;
        Smp.AData.AM4:=SP4;
        Smp.AData.AP4:=SM4;
        Smp.AData.AM5:=SP5;
        Smp.AData.AP5:=SM5;}
        Smp.AData.AFeedBack:=SFeedBack;
		Smp.AVolume:=63-(SM2 and $7F);
        End;
{	Writeln(CHU_NSmp,' Vol ',Smp.AVolume);
    Repeat until Readkey=#13;	}
{    If CHU_NSmp<10 then
       Begin}
        {Writeln(' :');}
{        With SMP.AData do Writeln('Ptr:',Seg(SATInstr^[CHU_NSmp]),':',Ofs(SATInstr^[CHU_NSmp]),' ',
         AM1,' ',AP1,' ',AM2,' ',AP2,' ',AM3,' ',AP3,' ',AM4,' ',AP4,' ',AM5,' ',AP5,' ',AFeedback);
        Repeat until Readkey=#13;
       end;}

    Smp.Info:=(Smp.Info OR M_Charge);
    Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)) { Copier le sample... }
   End
  End;

Musique^.Nb_Samples:=Nb_instruments;
Musique^.Nb_Samples_Loaded:=Nb_instruments;
{  Fin_Charge_Sample;}

END; {ChargeInstr}

{---------------------------------------------------------}

PROCEDURE Charge_SAT(chemin: String80; Var erreur: Word);
Var FichSAT  : TSATHeader;
    nom_fich : String12;
    SATInstr : PtrSATInstr;
    SATNom   : PtrSATNom;
    i        : Byte;
    freq     : Byte;
    Rest,SeqLen : Byte;
    Bidon : Array[1..200] of Byte;

Begin  {Charge_SAT}
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;
  New(SATInstr);
  New(SATNom);

  f_module.LitPos(0,FICHSAT,Sizeof(FICHSAT));
  Version:=FichSAT.Vers;

  Musique^.Type_Module:=T_SAT;
  Musique^.C_Pattern:=False;  
  Move(SAT_String[1],Musique^.Titre,20);
  Nom_fichier:=NomFichierSeul(chemin);
  { Titre du module }

  Musique^.Tempo_Start:=6;
  Musique^.Ch_Number:=9;        { 9 voies m‚lodiques Adlib...         }
  Musique^.Ch_Number_Patt:=9;
  Musique^.BPM_Start:=125;

{  Writeln('Version: ',FichSAT.Vers);}
  If Version<5 Then
     Begin
     f_module.Lit(SATInstr^,Sizeof(SATInstr^));
     f_module.Lit(SATNom^,Sizeof(SATNom^));
     End
     Else
     Begin
     For i:=1 to 31 do Begin
                       f_module.Lit(SATInstr^[i],11);
                       f_module.DeplacePointeur(4);
                       End;
     f_module.Lit(SATNom^,Sizeof(SATNom^));
     End;
  f_module.DeplacePointeur(3);
  f_module.Lit(Musique^.Sequence,128);  { Lire la s‚quence }
  If Version>5 Then
     Begin
     f_module.lit(Rest,1);
     f_module.DeplacePointeur(1);
     f_module.lit(SeqLen,1);
     f_module.DeplacePointeur(1);
     f_module.Lit(Freq,1);
     f_module.DeplacePointeur(513);
     End
     Else
     Begin
     f_module.DeplacePointeur(127);
     f_module.lit(Rest,1);
     f_module.DeplacePointeur(1);
     f_module.lit(SeqLen,1);
     f_module.DeplacePointeur(1);
     f_module.Lit(Freq,1);
     f_module.DeplacePointeur(1);
     End;

  For i:=128 downto 1 do
   if Musique^.Sequence[i]<>0 Then
      Begin
      Musique^.Sequence_len:=i;
      Break;
      End;

  Nb_Pattern:=0;
  For i:=1 to Musique^.Sequence_Len do
      if Musique^.Sequence[i]>Nb_Pattern Then Nb_Pattern:=Musique^.Sequence[i];
  Inc(Nb_Pattern);

  ChargePatt;

  ChargeInstr(SATInstr,SATNom);

  For i:=1 to 9 do Musique^.Voies_Adlib[i]:=i; { Allouer les voies Adlib }
  Musique^.Octave_Min:=0;
  Musique^.Octave_Max:=7;
  Init_Panning;
  FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,2); { Voies Adlib... }
  Compter_Voies;

  Erreur:=Erreur_de_chargement;
  Dispose(SATInstr);
  Dispose(SATNom);
  f_module.Ferme
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module; { Initialiser le Module, il est incorrect... }
End; {Charge_SAT}

END.