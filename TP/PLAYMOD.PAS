{  Minimal Code to use MODM Sound System  }

PROGRAM PlayMOD;
{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

USES CRT,Clavier,texte,Modm_SS,MMSS_Var,MMSS_CMD,ChMOD;

{ Use ChMOD to Load . MOD and so on }

{$IFDEF MIX16}
{$M 16384,0,51000} { Do not use all the DOS Memory for the Heap }
{$ELSE}
{$M 16384,0,38000} { Do not use all the DOS Memory for the Heap }
{$ENDIF}

VAR
 Error  : Word;
 KeyVal : Word;


 CONST

 MODFile : String = 'C:\MOD\STARDUST.MOD';

BEGIN

 MMSS_Init(True,True); {Always place this first }

 Writeln('Loading ',MODFile);

{ Example: Force the SBPro Output }
{ Don't force the output to a not existing Output }

{ WaveOut_SetDefault(SBPro);}
 MMSS_CFG^.Out_Frequency:=22000;

{ Charge_xm('C:\JT_POOLS.XM',Error);}
 Charge_mod(MODFile,Error);
 {Charge_mmm('C:\MOD\STARDUST.MMM',Error);}

 If Error<>0 then { Loader Error Code Test }
    Begin
     Writeln(' Error Starting the Module: ',Error);
     Halt;
    End;

 If MMSS_MUS_Loaded Then
  If MMSS_Start_Music=0 Then
     Begin
	  Writeln('');
	  Writeln('Output: ',MMSS_Output_Name[MMSS_CFG^.Wave_Output]);
	  If MMSS_CFG^.Wave_Output<>GUS Then Writeln('Frequency: ',MMSS_CFG^.Out_Frequency);
      MMSS_Start_Output;  { Start the Module }
     End;

 If MMSS_CFG^.MMSS_Error<>0 then { MMSS Error Code Test }
    Begin
     Writeln(' Error Starting the Module: ',Error);
     Halt;
    End;

 Repeat
 If Keypressed Then
  Begin
   KeyVal:=UpCase(ReadKey);
   Case KeyVal of
    Esc     : Break;
    End;
  End;
 Until MMSS_CFG^.Output_Stopped;

 MMSS_Stop_Output;            { Stopper la sortie sonore }
 MMSS_Stop_Musique;           { Stopper la musique       }
 Writeln('The End...');
END.