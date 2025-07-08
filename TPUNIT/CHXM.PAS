{************************************************************************}
{                                CHSXM.PAS                               }
{                                                                        }
{  XM Files Loader. (Fast Tracker 2)                                     }
{                                                                        }
{  AUTEUR: Freddy Vetele.                                                }
{                                                                        }
{                               Debut d'ecriture le --/10/19             }
{                               Dernieres modifications le --/10/19      }
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
USES VARUnit,Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem;
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
                    SHSize    : LongInt;
	                Smp_NbTable : Array[1..96] of Byte;
		            VolEnvelope : Array[1..48] of Byte;
                    PanEnvelope : Array[1..48] of Byte;
					VolPtNb : Byte;
                    PanPtNb : Byte;
                    VolSustain : Byte;
                    VolLoop    : Byte;
                    VolLoopEnd : Byte;
                    PanSustain : Byte;
                    PanLoopStart : Byte;
                    PanLoopEnd   : Byte;
                    VolType  : Byte; {type: bit 0: On; 1: Sustain; 2: Loop}
                    PanType  : Byte; {type: bit 0: On; 1: Sustain; 2: Loop}
                    VibrType : Byte;
                    VibrSweep: Byte;
                    VibDepth : Byte;
                    VibRate  : Byte;
                    VolFadeOut: Word;
                    Reserv: Word;
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

Procedure AdjustVol_Commands;
Begin
 { Convert Volume Value }
 
 {Write ('S ',C_Note.Instrument,'N ',C_Note.Periode,'V ',C_Note.Volume,'E ',C_Note.Commande,'P ',C_Note.Parametre);}
 C_Note.Volume:=C_Note.Volume-$10;
 If C_Note.Volume>=$F0 then C_Note.Volume:=$FF;



{XM Commands are Protracker Commands except some extended commands }

  If  (C_Note.Commande=Arpeggio) and (C_Note.Parametre=0) then 
    Begin
     C_Note.Commande:=Rien;
     Exit;
    End;

  If C_Note.Commande=SetTempo Then
    Begin
{     Writeln('Tempo',C_Note.Parametre);
     Repeat until Readkey=#13;}
     If (C_Note.Parametre>$1F) Then C_Note.Commande:=SetBPM;
     If (C_Note.Parametre=0  ) Then C_Note.Commande:=Rien;
     Exit;
    End;

  If C_Note.Commande=$E+1 Then {Extended Command}
    Begin
     C_Note.Commande:=$11+C_Note.Parametre SHR 4;
     C_Note.Parametre:=C_Note.Parametre AND $0F;
     Exit;
    End;
	
  If (C_Note.Commande=CPanning) Then
     Begin
      C_Note.Parametre:=C_Note.Parametre SHR 1; { Panning 0 to FFh > 0 to 80h }
      MMSS_CFG^.Calculer_Panning:=True; 
      Exit;
     End;

  If C_Note.Commande>$10 Then   {XM extended Commands}
    Begin
{   Write(' C',C_Note.Commande,' P ',C_Note.Parametre);
	Repeat until Readkey=#13;}
     Case C_Note.Commande of
         17: C_Note.Commande:=SetGVolume;
        {18: Global Volume Slide }
         21: C_Note.Commande:=NoteCut;      { Key Off     }
        {22: Set Envelope position }
        {26: Panning Slide }
         28: C_Note.Commande:=RetrigNote;   { Multi Retrig }
        {30: Tremor }
        34: C_Note.Commande:=EFPortamento; { Extra Fine Portamento (Period incr / 4) }
         Else
          Begin
{           Write(' C',C_Note.Commande,' P ',C_Note.Parametre);}
{			Repeat until Readkey=#13;}
            C_Note.Commande:=Rien;
            C_Note.Parametre:=0
          End;
         End; { Case Command }
     End;

End;

PROCEDURE XM_LoadPatterns( Nb_Patt: Word);
Var Pattern_XM : Ptr_Patt_XM;
    Pattern    : Ptr_Patt;
    PattHeader : T_XM_PattHeader;
    NbRows     : Byte;
    FirstByte: Byte;
    p,r,c,ixm: Word;

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
      Musique^.Taille_Pattern[p]:=NbRows;

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

      If Not CP_NewPattern((5*NbRows*Musique^.Ch_Number_Patt DIV 16)+1) Then
        Begin
	 {    Writeln('Last Pattern Loaded:',i,'/',n);}
         {Repeat until Readkey=#13;        }
         EXIT;
        End;
      MMSS_Table^.Seg_Pattern[p]:=SEG(CP_Pattern^);

    ixm:=1;
    for r:=1 to NbRows do { Row Loop }
      Begin
	  {Write('Row ',r,' ');}
        for c:=0 to Musique^.Ch_Number_Patt-1 do { Channels Loop }	  
		  Begin
		  {Write('Col ',c,' ');}
           FirstByte:=Pattern_XM^[ixm];
           if FirstByte<128 then
            Begin
             C_Note.Periode:=FirstByte-1;
             C_Note.Instrument:=Pattern_XM^[ixm+1];
             C_Note.Volume:=Pattern_XM^[ixm+2];
             C_Note.Commande:=Pattern_XM^[ixm+3]+1;
             C_Note.Parametre:=Pattern_XM^[ixm+4];
             ixm:=ixm+5;
             AdjustVol_Commands; { Adjust Volume and Commands values }
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
                   else C_Note.Volume:=0;        { 0 for FT2 Before Conversion }
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
				AdjustVol_Commands;  { Adjust Volume and Commands values }
                End
              Else
               Begin
                C_Note.Commande:=Rien;
                C_Note.Parametre:=0; C_Note.Instrument:=0;
                C_Note.Periode:=0; C_Note.Volume:=$FF;
               End;
           End;

        CP_AddVal;
		{Pattern^[i]:=C_Note;}
      end;{ Channels Loop }
      CP_NextRow 
  	 end; { Rows Loop }
      CP_End;
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

PROCEDURE XM_LoadInstruments(NbInstr: Word);

Var XMInstr: T_XM_Instrument;
    XMSample : T_XM_Sample; 
    InstrDataPtr : ^T_InstrData;
	InstrDataSize: Word;
	Ptr_Temp : Pointer;
    NextInstrOffset: LongInt;
    ISampleOffset : LongInt; { Current Sample Data Offset inside the instrument }
    ISampleSize   : LongInt;
    Inst : Integer;
    Fine : Byte;
    ISmpCnt,ISmpLoaded : Byte;
    T_SmpLoaded : Array[0..15] of Boolean; { List the sample loaded inside an instrument }
	
    i:Byte;
Begin
 {Writeln('----- Read Samples ------ / Nb :',NbInstr);}
 If NbInstr>(Max_Samples-Nb_Smp_Sup_XM) Then NbInstr:=Max_Samples-Nb_Smp_Sup_XM;

 Init_Charge_Sample;
 { Allocate Memory in DOS For samples and Instruments tables }
 If not Allocate_Instruments(NbInstr) Then EXIT;
 If not Allouer_Samples(NbInstr) Then EXIT;  { Allocate Sample pointer table and Instr Name Table }
 Convertir_signe:=False;

 CHU_NSmp:=1; { Used by the CHUTIL Unit }
 For Inst:=1 to NbInstr do  { ** Instruments Load Loop ** }
  Begin
   f_module.LitPos(XMFilePtr,XMInstr,Sizeof(XMInstr)); { Load the XM Instrument Header }
   {Writeln('*** Instr: ',Inst,'Nb Smp: ',XMInstr.NbSamples,' Name: ',XMInstr.Name,' Offset: ',XMFilePtr);}
 
   XMFilePtr:=XMFilePtr+XMInstr.Size;
   Move(XMInstr.Name,Musique^.PtrInstrNameTable^[Inst,1],22);
   PtrInstrument^[NbInstr].Sample_Nb:=CHU_NSmp; { Store the first sample number in the instrument }

{   If XMInstr.NbSamples>1 then Writeln('Nb Smp: ',XMInstr.NbSamples,' Name: ',XMInstr.Name);}
   If XMInstr.NbSamples>0 then FillChar(T_SmpLoaded,SizeOf(T_SmpLoaded),0);
   ISmpLoaded:=0;

   If (XMInstr.NbSamples>0) then
    Begin
    ISampleOffset:=XMFilePtr+XMInstr.NbSamples*Sizeof(XMSample);
    ISampleSize:=0;
    PtrInstrument^[Inst].Sample_Nb:=CHU_NSmp-1;
    PtrInstrument^[Inst].RelNote:=XMSample.RelNote;
	
{	Writeln(' First Sample: ',PrtInstrument^[Inst].Sample_Nb);}
	
    For ISmpCnt:=1 to XMInstr.NbSamples do  { ** Sample Load Loop ** }
      Begin  { The Sample headers are stored first, then samples Data }

      f_module.LitPos(XMFilePtr,XMSample,Sizeof(XMSample)); { Load the XM Sample Header }
{      Writeln ('* Instr: ',Inst,' Sub Sample: ',ISmpCnt,' Name: ',XMSample.Name,'Length: ',
                       XMSample.Length,' Offset: ',XMFilePtr);}
      XMFilePtr:=XMFilePtr+Sizeof(XMSample);
      
	  If CHU_NSmp=Nb_Samples_Allocated then
         Begin
          Writeln('Too many Samples');
          {Repeat until Readkey=#13;}
		  EXIT;
         End;
	  If XMSample.Length<>0 then 
	    Begin
        New_Sample;

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
           Begin {16 Bit}
             Smp.Info:=Smp.Info+M_16bit;
             Smp.len:=XMSample.Length SHR 1;
             Smp.rep:=Smp.rep SHR 1;
             Smp.rep_len:=Smp.rep_len SHR 1
            End
             Else
            Begin {8 Bit }
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
	    f_module.PlacePointeur(ISampleOffset); { Move the file pointer to the sample data Start }
        Charger_sample;
	    ISampleOffset:=ISampleOffset+XMSample.Length; { Move Sample Data Offset pointer  }
	    ISampleSize:=ISampleSize+XMSample.Length;
	  
  	  If (Smp.Info And M_Charge)>0 then 
	       Begin
		   ISmpLoaded:=ISmpLoaded+1; {Sample Loaded > Inc the value }
		   T_SmpLoaded[ISmpCnt-1]:=True;
		   End;
  	  
        Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copy the sample Header }
        INC(CHU_NSmp);
      End; { If (XMInstr.NbSamples>0) }
		 
      End; { Sample Loop }
	  
	XMFilePtr:=XMFilePtr+ISampleSize;
	
	End; { XMInstr.NbSamples>0 }
	
   PtrInstrument^[Inst].Samples_Total:=ISmpLoaded; { Store the number of Loaded sample in the instrument }

   If XMInstr.NbSamples=0 then
      Begin
	   PtrInstrument^[Inst].Sample_Nb:=$FF;
       New_Sample;
       Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copy the sample Header }
       INC(CHU_NSmp);
      End;

   If ISmpLoaded<>0 then { No Sample Loaded, no need to load the envelopes }
      Begin
      InstrDataSize:=6; { Note Table Size }

      If (XMInstr.VolType>0) then InstrDataSize:=6+4; { Load Vol envelope as well }

      If (XMInstr.VolType>0) or (XMInstr.NbSamples>1) then
         Begin { Allocate Instr Data Anyway }
          IF Not MMSS_MemAlloc(Ptr_Temp,InstrDataSize,True,False) Then { Allocate the Note to Sample Table }
             Begin
              Erreur_de_chargement:=Err_Memoire;
              EXIT;
             End;
          InstrDataPtr:=Ptr_Temp;
          PtrInstrument^[Inst].InstrDataSeg:=Seg(InstrDataPtr^); { Store the pointer to the instrument Data }
         End
		  Else PtrInstrument^[Inst].InstrDataSeg:=0;

      If XMInstr.NbSamples>1 then
        Begin  { Allocate and fill the Note to Sample Table }
         ISmpCnt:=PtrInstrument^[Inst].Sample_Nb; { Re use the variable }
         With XMInstr do
              For Fine:=1 to 96 do Smp_NbTable[Fine]:=Smp_NbTable[Fine]+ISmpCnt; { Put the "Real" Sample number in the table }
         Move(XMInstr.Smp_NbTable[1],InstrDataPtr^.NoteSmpTable[1],96); { Copy the table }
        End;

      If XMInstr.VolType>0 then
         Begin { Copy the Volume Env Data}
          PtrInstrument^[Inst].VolumeType:=XMInstr.VolType;
          InstrDataPtr^.VolSust:=XMInstr.VolSustain;
          InstrDataPtr^.VolLoopStart:=XMInstr.VolLoop;
          InstrDataPtr^.VolLoopEnd:=XMInstr.VolLoopEnd;
          Move(XMInstr.VolEnvelope[1],InstrDataPtr^.VolEnvTable[1],48);
	     End;
      End; 		{ISmpLoaded<>0} 

   {If XMInstr.NbSamples>1 then Repeat until Readkey=#13;}

  End; { Instr Loop }

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
  Musique^.Type_Module:=T_XM;
  Musique^.C_Pattern:=True;      { Compressed Pattern }
  Nom_fichier:=NomFichierSeul(chemin);

  New(XM);
  
  Pan_Present:=True;
  f_module.LitPos(0,XM^,Sizeof(XM^));
  XMFilePtr:=Sizeof(XM^);
  Erreur_de_chargement:=Ok;
  
  If XM^.Version<=$0104 Then
   Begin

   Move(XM^.Name,Musique^.Titre,20);                 {Read Title }
   Move(XM^.PattSequ,Musique^.Sequence,Max_Pattern); {Read Sequence}

   If XM^.SeqLen>Max_Pattern then Musique^.Sequence_Len:=Max_Pattern 
      else Musique^.Sequence_Len:=XM^.SeqLen;
   
   Musique^.Pos_de_restart:=XM^.Restart;    { Restart Position             }
   Musique^.Ch_Number_Patt:=XM^.NbChannel;  { Nb de voies dans un pattern  }
   Musique^.Ch_Number:=XM^.NbChannel;
   Musique^.Ch_Number_Digit:=XM^.NbChannel;
   Musique^.Tempo_Start:=XM^.Tempo;         { Start Tempo                  }
   Musique^.BPM_Start:=XM^.BPM;             { Start BPM                    }
   Musique^.Volume_General_depart:=$40;     { Volume g�n�ral Initial       }
   Musique^.Nb_Instr:=XM^.NbInstr;
                                            { No Panning Table }
   FillChar(Musique^.M_CH_Type,Musique^.Ch_Number,1); { Voies num�riques... }
   Init_Panning;

   { ADD Flag Management (Linear Freq) }
   Musique^.Octave_Min:=0;
   Musique^.Octave_Max:=8;

   Nb_pattern:=Check_Used_Pattern; 

{   Writeln('XM^.NbPattern',XM^.NbPattern,' Nb_pattern: ',Nb_pattern,' Nb Instr : ',XM^.NbInstr);}
   
   If (XM^.NbPattern>128) Then Erreur_de_chargement:=Err_TooManyPat
      Else XM_LoadPatterns(XM^.NbPattern);             { Charger la partition }

   If Erreur_de_chargement=Ok Then XM_LoadInstruments(XM^.NbInstr);    { Charger les samples  }

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