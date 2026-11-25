{************************************************************************}
{                                CHSXM.PAS                               }
{                                                                        }
{  XM Files Loader. (Fast Tracker 2)                                     }
{                                                                        }
{  AUTEUR: Freddy V�tel�.                                                }
{                                                                        }
{                               D�but d'�criture le --/10/19             }
{                               Derni�res modifications le --/10/19      }
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

     XM_Identifier:String[17]='Extended Module: ';

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
     { XM records must match their byte layout exactly. }
     T_En_tete_XM=Packed Record
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

    T_XM_Instrument=Packed Record
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

	 T_XM_Sample=Packed Record
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

	 T_XM_PattHeader=Packed Record
                     HeaderSize:LongInt;
                     PType:Byte;  {Always 0}
                     Rows:Word;   {1..255 supported; 256-row patterns are rejected}
                     PatternSize:Word;
                     End;

     T_Pattern_XM=Array[1..32000] of Byte;
     Ptr_patt_XM=^T_Pattern_XM;

VAR
     XMFilePtr : Longint;
     XMFileSize : Longint;

FUNCTION XM_RangeValid(Position,Count,FileSize:Longint):Boolean;
Begin
 XM_RangeValid:=(Position>=0) and (Count>=0) and (Position<=FileSize) and
                (Count<=FileSize-Position);
End;

FUNCTION XM_NoteToPeriod(Note:Byte):Byte;
Begin
 If Note=0 then XM_NoteToPeriod:=0
 Else If Note=97 then XM_NoteToPeriod:=127
 Else If Note<=96 then XM_NoteToPeriod:=Note-1
 Else XM_NoteToPeriod:=0;
End;

FUNCTION XM_ReadPatternByte(Pattern:Ptr_Patt_XM; Var Index:Longint;
                            PatternSize:Word; Var Value:Byte):Boolean;
Begin
 XM_ReadPatternByte:=(Index<Longint(PatternSize));
 If XM_ReadPatternByte then
  Begin
   Value:=Pattern^[Index+1];
   Inc(Index);
  End
 Else
  Erreur_de_chargement:=Err_Format;
End;

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
    PattHeader : T_XM_PattHeader;
    NbRows     : Byte;
    FirstByte: Byte;
    Value: Byte;
    p,r,c: Word;
    ixm: Longint;

Begin
 Erreur_de_chargement:=Err_memoire;    { If EXIT, Memory Error }

 For p:=1 to Nb_Patt do
  Begin
   If not XM_RangeValid(XMFilePtr,Sizeof(PattHeader),XMFileSize) Then
    Begin
     Erreur_de_chargement:=Err_lecture;
     Exit;
    End;
   f_module.LitPos(XMFilePtr,PattHeader,Sizeof(PattHeader));
   If f_erreur<>f_ok Then
    Begin
     Erreur_de_chargement:=Err_lecture;
     Exit;
    End;
   If (PattHeader.HeaderSize<Sizeof(PattHeader)) or
      (PattHeader.Rows=0) or (PattHeader.Rows>255) or
      (PattHeader.PType<>0) or
      not XM_RangeValid(XMFilePtr,PattHeader.HeaderSize,XMFileSize) Then
    Begin
     Erreur_de_chargement:=Err_Format;
     Exit;
    End;
   XMFilePtr:=XMFilePtr+PattHeader.HeaderSize;
   If not XM_RangeValid(XMFilePtr,PattHeader.PatternSize,XMFileSize) Then
    Begin
     Erreur_de_chargement:=Err_lecture;
     Exit;
    End;
   NbRows:=PattHeader.Rows;
   Musique^.Taille_Pattern[p]:=NbRows;

   Pattern_XM:=Nil;
   If PattHeader.PatternSize>0 Then
    Begin
     If PattHeader.PatternSize>=MaxAvail-1024 Then Exit;
     GetMem(Pattern_XM,PattHeader.PatternSize);
     f_module.LitPos(XMFilePtr,Pattern_XM^,PattHeader.PatternSize);
     If f_erreur<>f_ok Then
      Begin
       FreeMem(Pattern_XM,PattHeader.PatternSize);
       Erreur_de_chargement:=Err_lecture;
       Exit;
      End;
    End;
   XMFilePtr:=XMFilePtr+PattHeader.PatternSize;

   If Not CP_NewPattern((5*NbRows*Musique^.Ch_Number_Patt DIV 16)+1) Then
    Begin
     If Pattern_XM<>Nil Then FreeMem(Pattern_XM,PattHeader.PatternSize);
     Erreur_de_chargement:=Err_memoire;
     Exit;
    End;
   MMSS_Table^.Seg_Pattern[p]:=SEG(CP_Pattern^);

   ixm:=0;
   for r:=1 to NbRows do
    Begin
     for c:=0 to Musique^.Ch_Number_Patt-1 do
      Begin
       C_Note.Periode:=0;
       C_Note.Instrument:=0;
       C_Note.Volume:=$FF;
       C_Note.Commande:=Rien;
       C_Note.Parametre:=0;
       If PattHeader.PatternSize>0 Then
        Begin
         If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,FirstByte) Then
          Begin
           FreeMem(Pattern_XM,PattHeader.PatternSize);
           Exit;
          End;
         If FirstByte<128 Then
          Begin
           C_Note.Periode:=XM_NoteToPeriod(FirstByte);
           If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Instrument) Then
            Begin
             FreeMem(Pattern_XM,PattHeader.PatternSize);
             Exit;
            End;
           If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Volume) Then
            Begin
             FreeMem(Pattern_XM,PattHeader.PatternSize);
             Exit;
            End;
           If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,Value) Then
            Begin
             FreeMem(Pattern_XM,PattHeader.PatternSize);
             Exit;
            End;
           C_Note.Commande:=Value+1;
           If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Parametre) Then
            Begin
             FreeMem(Pattern_XM,PattHeader.PatternSize);
             Exit;
            End;
          End
         Else If FirstByte<>$80 Then
          Begin
           If (FirstByte AND $01)<>0 Then
            Begin
             If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,Value) Then
              Begin
               FreeMem(Pattern_XM,PattHeader.PatternSize);
               Exit;
              End;
             C_Note.Periode:=XM_NoteToPeriod(Value);
            End;
           If (FirstByte AND $02)<>0 Then
            If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Instrument) Then
             Begin
              FreeMem(Pattern_XM,PattHeader.PatternSize);
              Exit;
             End;
           If (FirstByte AND $04)<>0 Then
            Begin
             If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Volume) Then
              Begin
               FreeMem(Pattern_XM,PattHeader.PatternSize);
               Exit;
              End;
            End
           Else C_Note.Volume:=0;
           If (FirstByte AND $08)<>0 Then
            Begin
             If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,Value) Then
              Begin
               FreeMem(Pattern_XM,PattHeader.PatternSize);
               Exit;
              End;
             C_Note.Commande:=Value+1;
            End;
           If (FirstByte AND $10)<>0 Then
            If not XM_ReadPatternByte(Pattern_XM,ixm,PattHeader.PatternSize,C_Note.Parametre) Then
             Begin
              FreeMem(Pattern_XM,PattHeader.PatternSize);
              Exit;
             End;
          End;
         AdjustVol_Commands;
        End;
       CP_AddVal;
      End;
     CP_NextRow;
    End;
   CP_End;
   If Pattern_XM<>Nil Then FreeMem(Pattern_XM,PattHeader.PatternSize);
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
    ISampleOffset : LongInt; { Current Sample Data Offset inside the instrument }
    ISampleSize   : LongInt;
    InstrumentOffset: LongInt;
    Inst : Integer;
    Fine : Byte;
    ISmpCnt,ISmpLoaded : Byte;
    T_SmpLoaded : Array[0..15] of Boolean; { List the sample loaded inside an instrument }
	
    i:Byte;
Begin
 {Writeln('----- Read Samples ------ / Nb :',NbInstr);}
 If NbInstr>(Max_Samples-Nb_Smp_Sup_XM) Then
  Begin
   Erreur_de_chargement:=Err_Format;
   Exit;
  End;

 Erreur_de_chargement:=Err_memoire;
 Init_Charge_Sample;
 { Allocate Memory in DOS For samples and Instruments tables }
 If not Allocate_Instruments(NbInstr) Then EXIT;
 If not Allouer_Samples(NbInstr) Then EXIT;  { Allocate Sample pointer table and Instr Name Table }
 Convertir_signe:=False;

 CHU_NSmp:=1; { Used by the CHUTIL Unit }
 For Inst:=1 to NbInstr do  { ** Instruments Load Loop ** }
  Begin
   InstrumentOffset:=XMFilePtr;
   If not XM_RangeValid(XMFilePtr,29,XMFileSize) Then
    Begin
     Erreur_de_chargement:=Err_lecture;
     Exit;
    End;
   f_module.LitPos(XMFilePtr,XMInstr,29);
   If f_erreur<>f_ok Then
    Begin
     Erreur_de_chargement:=Err_lecture;
     Exit;
    End;
   If (XMInstr.Size<29) or
      not XM_RangeValid(XMFilePtr,XMInstr.Size,XMFileSize) or
      (XMInstr.NbSamples>16) Then
    Begin
     Erreur_de_chargement:=Err_Format;
     Exit;
    End;
   If XMInstr.NbSamples>0 Then
    Begin
     If XMInstr.Size<Sizeof(XMInstr) Then
      Begin
       Erreur_de_chargement:=Err_Format;
       Exit;
      End;
     f_module.LitPos(XMFilePtr+29,XMInstr.SHSize,Sizeof(XMInstr)-29);
     If f_erreur<>f_ok Then
      Begin
       Erreur_de_chargement:=Err_lecture;
       Exit;
      End;
     If (XMInstr.SHSize<>Sizeof(XMSample)) or
        (XMInstr.VolPtNb>12) or (XMInstr.PanPtNb>12) or
        (XMInstr.VolType>7) or (XMInstr.PanType>7) Then
      Begin
       Erreur_de_chargement:=Err_Format;
       Exit;
      End;
     For i:=1 to 96 do
      If XMInstr.Smp_NbTable[i]>=XMInstr.NbSamples Then
       Begin
        Erreur_de_chargement:=Err_Format;
        Exit;
       End;
    End;
   {Writeln('*** Instr: ',Inst,'Nb Smp: ',XMInstr.NbSamples,' Name: ',XMInstr.Name,' Offset: ',XMFilePtr);}
   XMFilePtr:=InstrumentOffset+XMInstr.Size;
   Move(XMInstr.Name,Musique^.PtrInstrNameTable^[Inst,1],22);
   PtrInstrument^[Inst].Sample_Nb:=CHU_NSmp;

{   If XMInstr.NbSamples>1 then Writeln('Nb Smp: ',XMInstr.NbSamples,' Name: ',XMInstr.Name);}
   If XMInstr.NbSamples>0 then FillChar(T_SmpLoaded,SizeOf(T_SmpLoaded),0);
   ISmpLoaded:=0;

   If (XMInstr.NbSamples>0) then
    Begin
    If not XM_RangeValid(XMFilePtr,XMInstr.NbSamples*Sizeof(XMSample),XMFileSize) Then
     Begin
      Erreur_de_chargement:=Err_lecture;
      Exit;
     End;
    ISampleOffset:=XMFilePtr+XMInstr.NbSamples*Sizeof(XMSample);
    ISampleSize:=0;
    PtrInstrument^[Inst].Sample_Nb:=CHU_NSmp-1;
	
{	Writeln(' First Sample: ',PrtInstrument^[Inst].Sample_Nb);}
	
    For ISmpCnt:=1 to XMInstr.NbSamples do  { ** Sample Load Loop ** }
      Begin  { The Sample headers are stored first, then samples Data }

      f_module.LitPos(XMFilePtr,XMSample,Sizeof(XMSample)); { Load the XM Sample Header }
      If f_erreur<>f_ok Then
       Begin
        Erreur_de_chargement:=Err_lecture;
        Exit;
       End;
{      Writeln ('* Instr: ',Inst,' Sub Sample: ',ISmpCnt,' Name: ',XMSample.Name,'Length: ',
                       XMSample.Length,' Offset: ',XMFilePtr);}
      XMFilePtr:=XMFilePtr+Sizeof(XMSample);
      
	  If CHU_NSmp=Nb_Samples_Allocated then
         Begin
          Erreur_de_chargement:=Err_Format;
          Exit;
         End;
      If (XMSample.Length<0) or
         not XM_RangeValid(ISampleOffset,XMSample.Length,XMFileSize) or
         ((XMSample.SType AND $03)>2) or
         (((XMSample.SType AND $10)<>0) and ((XMSample.Length AND 1)<>0)) or
         (XMSample.Volume>64) or
         (XMSample.Loop<0) or (XMSample.LoopLen<0) or
         (XMSample.Loop>XMSample.Length) or
         (XMSample.LoopLen>XMSample.Length-XMSample.Loop) or
         (((XMSample.SType AND $10)<>0) and
          (((XMSample.Loop AND 1)<>0) or ((XMSample.LoopLen AND 1)<>0))) Then
       Begin
        Erreur_de_chargement:=Err_Format;
        Exit;
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
  Erreur_de_chargement:=Ok;
End; {Charge_Sampl}

{---------------------------------------------------------}

PROCEDURE Charge_XM(chemin: String80; Var erreur: Word);

Var XM: Ptr_En_tete_XM;
    HeaderOK:Boolean;
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
  
  XMFileSize:=f_module.Taille;
  Erreur_de_chargement:=Ok;
  If not XM_RangeValid(0,Sizeof(XM^),XMFileSize) Then
   Erreur_de_chargement:=Err_lecture
  Else
   Begin
    f_module.LitPos(0,XM^,Sizeof(XM^));
    If f_erreur<>f_ok Then
     Erreur_de_chargement:=Err_lecture
    Else
     Begin
      HeaderOK:=True;
      For i:=1 to 17 do
       If XM^.Ident[i]<>XM_Identifier[i] then HeaderOK:=False;
      If (XM^.ID1A<>$1A) or (XM^.Version<$0102) or (XM^.Version>$0104) or
         (XM^.HeadSize<276) or
         not XM_RangeValid(60,XM^.HeadSize,XMFileSize) or
         (XM^.SeqLen=0) or (XM^.SeqLen>256) or
         (XM^.NbChannel=0) or (XM^.NbChannel>32) or
         (XM^.NbPattern=0) or (XM^.NbPattern>256) Then HeaderOK:=False;
      If not HeaderOK Then
       Erreur_de_chargement:=Err_Format
      Else
       XMFilePtr:=60+XM^.HeadSize;
     End;
   End;

  If Erreur_de_chargement=Ok Then
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

   If (XM^.NbPattern>128) Then Erreur_de_chargement:=Err_TooManyPat
      Else XM_LoadPatterns(XM^.NbPattern);             { Charger la partition }

   If Erreur_de_chargement=Ok then
    For i:=1 to Musique^.Sequence_Len do
     If Musique^.Sequence[i]>=XM^.NbPattern then Erreur_de_chargement:=Err_Format;

   If Erreur_de_chargement=Ok Then XM_LoadInstruments(XM^.NbInstr);    { Charger les samples  }

  End
  
   Dispose(XM);
   f_module.Ferme;
   Erreur:=Erreur_de_chargement;
  End
 Else Erreur:=Err_lecture;  {Impossible d'ouvrir le fichier}

If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;

End; {Charge_XM}

END.