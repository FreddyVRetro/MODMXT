{  Convert modules to the .MMM File Format  }

PROGRAM MMCONV;
{$A+,G-,Q-,R-,S-}

USES CRT,DOS,Clavier,Util,MM_VAR,MM_DIV,MMSS_Var,SAV_MMM,MODMUnit,
     ChMOD,CHS3M,CHXM,Ch669,ChDTM,ChMTM,ChFAR,ChSTM,ChULT,ChMMM;

{$M 16384,0,24576}

VAR
 MM_Error  : Word;
 KeyVal    : Word;

 i,j : Byte;
 nbr_param : Byte;
 long_repert:Byte;
 ExtNr: Byte; { Extension number from the supported extention list}
 
 erreur : Byte;

 Info      : SearchRec;
 DirStr_Size : Word; 
 Param     : String;
 Repert    : String;
 DirStr    : String;
 SearchStr : String;
 
 SourceFilename : String;
 DestFilename   : String;

 
BEGIN

Writeln('Mod Master file Converter');
Writeln('Convert any Module to .MMM');

nbr_param:=ParamCount;

If ParamCount<>1 then
   Begin
    Writeln(' Command line : MMCONV Filename');
    Writeln('  > *.MOD to convert all the .MOD files.')
   End
  Else

Begin

MMSS_Init(True,False); {Always place this first }

SearchStr:=ParamStr(1);

{ Build the Directory String }
 i:=Length(SearchStr);
 DirStr_Size:=0;
 DirStr:='';
 Repeat
  If (SearchStr[i] in ['\',':']) Then DirStr_Size:=i;
  Dec(i)
 Until (i=0) or (DirStr_Size>0);
 If DirStr_Size>0 Then DirStr:=Copy(SearchStr,1,DirStr_Size);


{ Writeln('Directory: ',DirStr);
 Writeln('Search ',SearchStr);}

 MMSS_CFG^.Wave_Output:=HPInt; { Force an Output with Samples in memory }
  
 FindFirst (SearchStr,AnyFile,Info);
  While DOSError=0 do
    Begin
      With Info do
        Begin
		If (Attr and Directory) <> Directory then
		  Begin
           SourceFilename:=DirStr+Name;

           i:=Length(Name);
           j:=0;
           Repeat
            If (Name[i]='.') Then j:=i-1;
             Dec(i)
           Until (i=0) or (j>0);
          If j>0 Then
            DestFilename:=Copy(Name,1,j) {Remove any extention}
	     Else
              Begin
               Writeln(' Filename error : No extension');
               Exit;
              End;

           Write('Load File : ',SourceFilename);

           Case Extension(Name) of
               ext_MOD,
               ext_NST,
               ext_WOW,
               ext_SD0,
               ext_OCT: Charge_MOD(SourceFilename,MM_Error);
               ext_S3M: Charge_S3M(SourceFilename,MM_Error);
               ext_XM : Charge_XM(SourceFilename,MM_Error);
               ext_669: Charge_669(SourceFilename,MM_Error);
               ext_DTM: Charge_DTM(SourceFilename,MM_Error);
               ext_MTM: Charge_MTM(SourceFilename,MM_Error);
               ext_ULT: Charge_ULT(SourceFilename,MM_Error);
               ext_FAR: Charge_FAR(SourceFilename,MM_Error);
               ext_STM: Charge_STM(SourceFilename,MM_Error);
			   {ext_MMM: Charge_MMM(SourceFilename,MM_Error);}
               Else MM_Error:=Err_Non_Gere;
              End;
			  
             If MM_Error = 0 then
                Begin
                 Writeln(' > Save File : ',DestFilename,'.MMM');

                 If MMSS_MUS_Loaded Then
                   Save_MMM(DestFilename+'.MMM',ExtensionSeule(Name),MM_Error);
                End { MM_Error=0 }
                Else If MM_Error=Err_Non_Gere then 
				        Writeln(' Not a supported file')
						else Writeln(' Error ',Erreur);

	 End; { <> Directory }

    End; { With }

   FindNext(Info);
  End; {While DOSError = 0 }

 Writeln('The End...');

End; {Nb of parameter invalid}

END.