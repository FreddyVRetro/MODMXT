{************************************************************************}
{                                CHSXM.PAS                               }
{                                                                        }
{  XM Files Loader. (Fast Tracker 2)                                     }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                               D‚but d'‚criture le --/10/19             }
{                               DerniŠres modifications le --/10/19      }
{************************************************************************}

{$UNDEF Groupe}

{$IFNDEF Groupe}
UNIT ChXM;
{$ELSE}
UNIT ChXM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES VARUnit,Fichiers,Util,Chutil,MemUnit,MMSS_Var,CRT;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MemUnit,MMSS_Var,CRT;
{$ENDIF}

PROCEDURE Charge_XM(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE
     Char4=Array[0..3] of Char;
     Char28=Array[1..28] of Char;

CONST

     Max_Samples_XL=99;

     XMFineTune:Array[0..127] of Word=
       (8363,8370,8378,8385,8393,8400,8408,8416,
        8423,8431,8438,8446,8454,8461,8469,8476,
        8484,8492,8499,8507,8515,8523,8530,8538,
        8546,8553,8561,8569,8577,8584,8592,8600,
        8608,8615,8623,8631,8639,8646,8654,8662,
        8670,8678,8686,8693,8701,8709,8717,8725,
        8733,8741,8749,8756,8764,8772,8780,8788,
        8796,8804,8812,8820,8828,8836,8844,8852,
        7893,7900,7907,7915,7922,7929,7936,7943,
        7950,7958,7965,7972,7979,7986,7993,8001,
        8008,8015,8022,8030,8037,8044,8051,8059,
        8066,8073,8081,8088,8095,8102,8110,8117,
        8124,8132,8139,8146,8154,8161,8169,8176,
        8183,8191,8198,8205,8213,8220,8228,8235,
        8243,8250,8257,8265,8272,8280,8287,8295,
        8302,8310,8317,8325,8332,8340,8347,8355);

TYPE
     T_En_tete_XM=Record
                    Ident     : Array[1..17] of Char;
                    Name      : Array[1..20] of Char;
                    ID1A      : Byte;                {1A}
                    TrkName   : Array[1..20] of Char;
                    Version   : Word;
                    HeadSize  : LongInt;
					SeqLen    : Word;
					Restart   : Word;
					NbChannel : Word;
					NbPattern : Word; { Max 256}
					NbInstr   : Word;
                    Flags     : Word;      { 0 Amiga 1 Linear   }
                    Tempo     : Word;      { Initial Tempo      }
                    BPM       : Word;      { Initial BPM        }
                    PattSequ  : Array[1..256] of Byte;
                   End;

    T_XM_Instrument=Record
                    Size      : LongInt;
                    Name      : Array[1..22] of Char;
                    IType     : Byte;       {always 0}
                    NbSamples : Word;
		    End;

     Ptr_En_tete_XM=^T_En_tete_XM;

	 T_XM_Sample=Record
               Length  : LongInt;
               Loop    : LongInt;
               LoopLen : LongInt;
               Volume  : Byte;
               Fine    : Byte; { Finetune (signed byte -16..+15) }
               SType   : Byte; { Type: Bit 0-1: 0 = No loop,
			                                    1 = Forward loop,
                                                2 = Ping-pong loop;
                                            4: 16-bit sampledata }
               Panning : Byte; { Panning (0-255) }
               RelNote : Byte; { Relative note number (signed byte) }
               Res     : Byte; { Reserved        }
               Name   : Array[1..22] of Char;
	           End;

	 T_XM_PattHeader=Record
                     HeaderSize:LongInt;
                     PType:Byte;  {Always 0}
                     Rows:Word;   {1..256 ! 255 max supported by Mod Master as 0 means not loaded }
                     PatternSize:Word;
                     End;

     T_Pattern_XM=Array[1..32000] of Byte;
     Ptr_patt_XM=^T_Pattern_XM;

VAR
     XMFilePtr : Longint;

{---------------------------------------------------------}

PROCEDURE Charge_pattern( Nb_Patt: Word);
Var Pattern_XM : Ptr_Patt_XM;
    Pattern : Ptr_Patt;
    PattHeader : T_XM_PattHeader;
    NbRows : Byte;
    FirstByte:Byte;
    p,i,ixm: Word;


Begin
 {Writeln('----- Read Pattern ------ / Nb Patt: ',Nb_Patt);
 Repeat until Readkey=#13;}
 Erreur_de_chargement:=Err_memoire;    { If EXIT, Memory Error }
 
 For p:=1 to Nb_Patt do
  Begin
  { Writeln('Pattern :',n); }

   {Write('Pattern:',P,' Offs: ',XMFilePtr);}
   f_module.LitPos(XMFilePtr,PattHeader,Sizeof(PattHeader));
   XMFilePtr:=XMFilePtr+Sizeof(PattHeader);
   If f_erreur=f_ok Then
      Begin
	{  Writeln(' Rows: ',PattHeader.Rows,' Size: ',PattHeader.PatternSize);}
      If PattHeader.Rows>255 then NbRows:=255 else NbRows:=PattHeader.Rows;
      MMSS_Table^.Taille_Pattern[p]:=NbRows;

      If PattHeader.PatternSize<MaxAvail-1024
	     Then GetMem(Pattern_XM,PattHeader.PatternSize)
		 Else 
		 Begin
{		 Writeln('Out of memory for pattern Load');
		 Repeat until Readkey=#13;}
		 Exit;
		 end;
      f_module.LitPos(XMFilePtr,Pattern_XM^,PattHeader.PatternSize);                {Lire le pattern}
      XMFilePtr:=XMFilePtr+PattHeader.PatternSize;

	  { Add exit if too many patterns }

      If Not MMSS_MemAlloc(Pointeur_actuel,(5*NbRows*Musique^.Ch_Number_Patt DIV 16)+1,True,False)
         Then EXIT;  { Quit the function }
      Pattern:=Pointeur_actuel;
      MMSS_Table^.Seg_Pattern[p]:=Seg(Pointeur_actuel^);

{      Fillchar(pattern^,((5*NbRows*Musique^.Ch_Number_Patt) DIV 16),0);
       For i:=1 to Musique^.Ch_Number_Patt*NbRows do Pattern^[i].Volume:=255;}

	  ixm:=1;
	  for i:=1 to Musique^.Ch_Number_Patt*NbRows do
		  Begin
           FirstByte:=Pattern_XM^[ixm];
           if FirstByte<128 then
            Begin
             C_Note.Periode:=FirstByte-1;
             C_Note.Instrument:=Pattern_XM^[ixm+1];
             C_Note.Volume:=Pattern_XM^[ixm+2];
             C_Note.Commande:=Pattern_XM^[ixm+3]+1;
             C_Note.Parametre:=Pattern_XM^[ixm+4];
             ixm:=ixm+5;
            End
	       else
            Begin
             INC(iXM);
             if FirstByte<>$80 then  { If Empty, skip directly }
                Begin
                if (FirstByte AND $01)<>0 then  { 1 Note follow ? }
                  Begin
                   C_Note.Periode:=Pattern_XM^[ixm]-1;
                   If C_Note.Periode>95 Then C_Note.Periode:=127; { Note Cut if >95 }
                   INC(iXM);
                  End
                  else C_Note.Periode:=0;  { 0 : No Note, $FF : Key Off }
                if (FirstByte AND $02)<>0 then   { 2 Instrument follow ? }
                  Begin
                   C_Note.Instrument:=Pattern_XM^[ixm];
                   INC(iXM);
                  End
                   else C_Note.Instrument:=0;
                if (FirstByte AND $04)<>0 then   { 3 Volume follow ? }
  	              Begin
                   C_Note.Volume:=Pattern_XM^[ixm];
                   INC(iXM);
                  End
                   else C_Note.Volume:=$FF;
                if (FirstByte AND $08)<>0 then   { 4 Command follow ? }
  	              Begin
                   C_Note.Commande:=Pattern_XM^[ixm]+1;
                   INC(iXM);
                  End
                   else C_Note.Commande:=Rien;
                if (FirstByte AND $10)<>0 then  { 5 Parameter follow ? }
  	              Begin
                   C_Note.Parametre:=Pattern_XM^[ixm];
                   INC(iXM);
                  End
                   else C_Note.Parametre:=0;

                   { Convert Volume Command }
                   C_Note.Volume:=C_Note.Volume-$10;
                   If C_Note.Volume>=$F0 then C_Note.Volume:=$FF;
          
                   {XM Commands are Protracker Commands except some extended commands }
                   If (C_Note.Commande=Rien) and (C_Note.Parametre<>0) then C_Note.Commande:=Arpeggio;

		   If C_Note.Commande=$E+1 Then {Extended Command}
                      Begin
                       C_Note.Commande:=$11+C_Note.Parametre SHR 4;
		               C_Note.Parametre:=C_Note.Parametre AND $0F;
                      End
					  Else
           If (C_Note.Commande=SetTempo) Then
                      Begin
                       If (C_Note.Parametre>$1F) Then C_Note.Commande:=SetBPM;
                       If (C_Note.Parametre=0  ) Then C_Note.Commande:=Rien;
                      End
                      Else
           If C_Note.Commande>$10 Then   {XM extended Commands}
                      Begin
{					  Write(' C',C_Note.Commande,' P ',C_Note.Parametre);
					  Repeat until Readkey=#13;}
                       Case C_Note.Commande of
                        $11: C_Note.Commande:=SetGVolume;
                        21: C_Note.Commande:=NoteCut;    { Key Off     }
                        28: C_Note.Commande:=RetrigNote; { Multi Retrig }
						34: C_Note.Commande:=EFPortamento; { Extra Fine Portamento (Period incr / 4) }
                        Else
				          Begin
{                           Write(' C',C_Note.Commande,' P ',C_Note.Parametre);}
{					  Repeat until Readkey=#13;}
				           C_Note.Commande:=Rien;
				           C_Note.Parametre:=0
				          End;
					   End; { Case Command }
                     End;

               end
              else
               Begin
                C_Note.Commande:=Rien;
                C_Note.Parametre:=0; C_Note.Instrument:=0;
                C_Note.Periode:=0; C_Note.Volume:=$FF;
               End;
           End;

        Pattern^[i]:=C_Note;
      end;{ Notes Loop }
      FreeMem(Pattern_XM,PattHeader.PatternSize);	  
    End
     else
    Begin { Fail to Load the Pattern from file }
      Erreur_de_chargement:=Err_lecture;;
      EXIT;
    End;
  End; {Pattern Loop}
 Erreur_de_chargement:=Ok;
End; {Charge_pattern}

{---------------------------------------------------------}

PROCEDURE Charge_Sampl(NbInstr: Word);

Var XMInstr: T_XM_Instrument;
    XMSample : T_XM_Sample; 
    NextInstrOffset: LongInt;
    MSampleSize: LongInt;
	Inst : Integer;
    Fine,SmpCnt : Byte;
	

Begin
 {Writeln('----- Read Samples ------ / Nb :',NbInstr);}
 If NbInstr>Max_Samples Then NbInstr:=Max_Samples;

 Init_Charge_Sample;
 { R‚serve l'espace DOS pour la d‚finition de samples }
 If not Allouer_Samples(NbInstr) Then EXIT;

 CHU_NSmp:=1; { Used by the CHUTIL Unit }
 For Inst:=1 to NbInstr do
  Begin
   {Write('Instr: ',Inst,' Offset: ',XMFilePtr);}
   f_module.LitPos(XMFilePtr,XMInstr,Sizeof(XMInstr));
   XMFilePtr:=XMFilePtr+XMInstr.Size;
   
  { Writeln('Nb Smp: ',XMInstr.NbSamples,' Name: ',XMInstr.Name);}
{   Repeat until Readkey=#13;}

   New_Sample;
   Move(XMInstr.Name,Smp.Nom,22);

   if XMInstr.NbSamples=1 then
      Begin
	  f_module.LitPos(XMFilePtr,XMSample,Sizeof(XMSample));
	  XMFilePtr:=XMFilePtr+Sizeof(XMSample); {the sample name we don't load}

      Smp.Rel_Note:=XMSample.RelNote;
      Smp.rep:=XMSample.Loop;
      Smp.rep_len:=XMSample.LoopLen;

      Smp.Info:=M_Delta;                   { Sample Coded in Delta }
       Case XMSample.SType AND $03 of
        0: Begin
            Smp.rep:=0;
            Smp.rep_len:=0;
           End;
        1: Smp.Info:=Smp.Info+M_Boucle;
        2: Smp.Info:=Smp.Info+M_Boucle+M_Bidi;
       end;
          If (XMSample.SType AND $10) <>0 then
         Begin
           Smp.Info:=Smp.Info+M_16bit;
           Smp.len:=XMSample.Length SHR 1;
           Smp.rep:=Smp.rep SHR 1;
           Smp.rep_len:=Smp.rep_len SHR 1
          End
           Else
          Begin
	       Smp.len:=XMSample.Length;
          End;

      Smp_rep_fin:=Smp.rep+Smp.rep_len;
      Smp.Volume:=XMSample.Volume;
      Fine:=XMSample.Fine;
       ASM
        MOV AL,Fine
        SAR AL,1
        AND AL,$7F
        MOV Fine,AL
       END;
      Smp.C4Spd:=XMFineTune[Fine];
      Smp.Rel_Note:=XMSample.RelNote;
	  { SType, Res }

      SamplFlags[CHU_NSmp]:=True; { Flag to not load unused samples }
      Charger_sample;
      XMFilePtr:=XMFilePtr+XMSample.Length;
      End;

   If XMInstr.NbSamples>1 then
      Begin  { Move into the file to skip the samples }
	  MSampleSize:=0;
	  for SmpCnt:=1 to XMInstr.NbSamples do
	      Begin
		  f_module.LitPos(XMFilePtr,XMSample,Sizeof(XMSample));
{		  Writeln('Offs: ',XMFilePtr,'Size: ',XMSample.Length,' Name: ',XMSample.Name);}
	      XMFilePtr:=XMFilePtr+Sizeof(XMSample);
		  MSampleSize:=MSampleSize+XMSample.Length;
		  End;
      XMFilePtr:=XMFilePtr+MSampleSize;
	  End;
	  
   Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copier le sample... }
   INC(CHU_NSmp);
   
  End;

  Fin_Charge_Sample;
End; {Charge_Sampl}

{---------------------------------------------------------}

PROCEDURE Charge_XM(chemin: String80; Var erreur: Word);

Var XM: Ptr_En_tete_XM;
    Pan_Present:Boolean;
	Nb_pattern:Byte;
    i:Integer;
Begin
 erreur:=Ok;
 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok Then
  Begin
  Init_Module;
  Musique^.Type_Module:=T_XM;            { Type de module  }
  Musique^.C_Pattern:=False;
  Nom_fichier:=NomFichierSeul(chemin);

  New(XM);
  
  Pan_Present:=True;
  f_module.LitPos(0,XM^,Sizeof(XM^));
  XMFilePtr:=Sizeof(XM^);
  Erreur_de_chargement:=Ok;
  
  If XM^.Version<=$0104 Then
   Begin

   Move(XM^.Name,Musique^.Titre,20);               { Read Title }
   Move(XM^.PattSequ,MMSS_Table^.Sequence,Max_Pattern); {Read Sequence}


   If XM^.SeqLen>Max_Pattern then Musique^.Sequence_Len:=Max_Pattern 
      else Musique^.Sequence_Len:=XM^.SeqLen;
   
   Musique^.Pos_de_restart:=XM^.Restart;      { Restart Position             }
   Musique^.Ch_Number_Patt:=XM^.NbChannel;  { Nb de voies dans un pattern  }
   Musique^.Ch_Number:=XM^.NbChannel;   
   Musique^.Tempo_depart:=XM^.Tempo;          { Start Tempo                  }
   Musique^.BPM_depart:=XM^.BPM;              { Start BPM                    }
   Musique^.Volume_General_depart:=$40;       { Volume g‚n‚ral Initial       }
                                              { No Panning Table }
   FillChar(MMSS_Table^.Type_Voie,Musique^.Ch_Number,1); { Voies num‚riques... }
   Init_Panning;

   { ADD Flag Management (Linear Freq) }
   Musique^.Octave_Min:=0;
   Musique^.Octave_Max:=8;

   Nb_pattern:=Check_Used_Pattern; 

{   Writeln('XM^.NbPattern',XM^.NbPattern,' Nb_pattern: ',Nb_pattern,' Nb Instr : ',XM^.NbInstr);}
   
   If (XM^.NbPattern>128) Then Erreur_de_chargement:=Err_TooManyPat
      Else Charge_pattern(XM^.NbPattern);             { Charger la partition }

   If Erreur_de_chargement=Ok Then Charge_Sampl(XM^.NbInstr);    { Charger les samples  }

  End
  Else { XM Version >104 Not Supported }
   Begin
	Writeln('Erreur Version');
	Erreur_de_chargement:=Err_Format;
   End;
  
   Dispose(XM);
   f_module.Ferme;
   Erreur:=Erreur_de_chargement;
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}

If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;

End; {Charge_XM}

END.