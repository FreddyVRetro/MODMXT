{************************************************************************}
{                              MODMUNIT.PAS V2.2                         }
{                                                                        }
{  Interface entre le pascal et les routines sonores de Mod Master.      }
{                                                                        }
{  AUTEUR: Freddy V�tel�.                                                }
{                                                                        }
{                                                                        }
{                               Dernieres modifications le 28/01/2020    }
{************************************************************************}

{$DEFINE MODM}     { Define for the Full Mod Master }

{$IFDEF MODM}
UNIT MODMUNIT; {Unit for MODM.PAS}
{$ELSE}
UNIT MODM_SS; {Unit for Standalone Sound System}
{$ENDIF}

{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

{$UNDEF  DEBUG }
INTERFACE

TYPE String80=String[80];

VAR  SauveExit   : POINTER;        { Sauvegarde de l'ancienne routine de fin }
     DisplayText : Boolean;

{=========================================================}
{$IFDEF MODM}
PROCEDURE Affiche_Ecran_Texte;
PROCEDURE MM_ASM_UpdateInterface;
{$ENDIF}

PROCEDURE WaveOut_SetDefault(W_Number: Byte); { Configure the default values and the output number }
FUNCTION  MMSS_Start_Output: Byte;         { Start Audio Output   }
PROCEDURE MMSS_Stop_Output;                { Stop audio Output    }
FUNCTION  MMSS_Start_Music: Word;          { Init Music Variables }
PROCEDURE MMSS_Stop_Musique;
PROCEDURE MMSS_Init(ShowMem:Boolean;ShowDevice:Boolean);

{$IFNDEF MODM}  { Functions for Mod Master Sound System Only }
PROCEDURE MMSS_StartIRQ;
PROCEDURE MMSS_StopIRQ;
FUNCTION  MMSS_TestIRQ:Byte;
{$ENDIF}

{=========================================================}

IMPLEMENTATION

USES Fichiers,Util,BIOSEQU,MMSS_Var,MMSS_CMD,VarUnit,Memoire,CHUtil,Texte,Clavier,
     SBUnit,TDYUnit,PSGUnit,
{$IFNDEF NoGUS}
     GusUnit,
{$ENDIF}
     CRT,MMSS_Mem;

{ MODMPAS.OBJ External Variables definition }

{$F+}

{PROCEDURE Affiche_Ecran_Graphique; External;}

{$IFDEF MODM}
PROCEDURE Affiche_Ecran_Texte;     External;
PROCEDURE MM_ASM_UpdateInterface;  External;
PROCEDURE MMSS_Refresh_Debug;      External;
{$ENDIF}

PROCEDURE PInit_Tables(Var dest); External;
FUNCTION  PStart_Output:Word;     External;
FUNCTION  PStart_Music:Word;      External;

{$IFNDEF MODM}
PROCEDURE MMSS_StartIRQ;          External;
PROCEDURE MMSS_StopIRQ;           External;
FUNCTION  MMSS_TestIRQ:Byte;      External;
{$ENDIF}
{$F-}

{$IFDEF MODM}
{$L MODMPAS}
{$ELSE}
{$L MODM_SS}
{$ENDIF}

{=========================================================}

{---------------------------------------------------------}
{ Mod Master XT : Removed Adlib, sound Master > No more needed }
PROCEDURE WaveOut_Init;
Var Panning_GUS : Byte;

Begin

 Case MMSS_CFG^.Wave_Output of
{$IFNDEF NoGUS} 
  GUS: Begin        { Init and configure the Panning }
        If Musique^.Ch_Number_Digit>14 Then UltraReset(Musique^.Ch_Number,MMSS_CFG^.GUS_InterWave)
           Else UltraReset(14,MMSS_CFG^.GUS_InterWave);
       End;
{$ENDIF}
  SB,SBPro: Init_DSP;
{$IFNDEF ModeXT}
{$IFNDEF NoOPL}
{  Adlib: Begin
          InitOPL2;
          Musique^.Ch_Number_Adlib:=0;
          If Musique^.Ch_Number_Digit>0 Then
           Begin
            EcrireOPL2(OPL2Test    ,$20);
            EcrireOPL2(OPL2FB_FM   ,$01);
            EcrireOPL2(OPL2AM_VIB  ,$00);
            EcrireOPL2(OPL2AM_VIB+3,$27);
            EcrireOPL2(OPL2KSL_TL  ,$00);
            EcrireOPL2(OPL2KSL_TL+3,$00);
            EcrireOPL2(OPL2AR_DR   ,$00);
            EcrireOPL2(OPL2AR_DR+3 ,$FF);
            EcrireOPL2(OPL2SL_RR   ,$00);
            EcrireOPL2(OPL2SL_RR+3 ,$0F);
            EcrireOPL2(OPL2WS      ,$00);
            EcrireOPL2(OPL2WS+3    ,$02);
            EcrireOPL2(OPL2Fnum    ,$0C);
            EcrireOPL2(OPL2Key     ,$3F);
            EcrireOPL2($BD         ,$20);
           End
          Else Erreur_Modm:=Err_Adlib;
         End;}
{$ENDIF}		 
        End;
{$ENDIF}
     End;
End; {WaveOut_Init}

{---------------------------------------------------------}

PROCEDURE SoundEnd;
Begin
{$IFNDEF NoOPL}
 If (Musique^.Ch_Number_Adlib>0) and ((OPL_Model<>0) or (OPL_LPT_Model<>0)) Then InitOPL2;
{$ENDIF} 
{$IFNDEF NoGUS}
 Case MMSS_CFG^.Wave_Output Of
  GUS: UltraReset(14,FALSE);
 End;
{$ENDIF}
End; {SoundEnd}

{---------------------------------------------------------}

FUNCTION MMSS_Start_Output:Byte;
Var Err_Sort:Word;
    i:Word;
Begin

{ No 16Bit Mixing for PC Speaker, No 16Bit output for Stereo }
If (MMSS_CFG^.Wave_Output=HPint) and (MMSS_CFG^.Mix_16Bit) then MMSS_CFG^.Mix_16Bit:=False;
{If (MMSS_CFG^.Utilise_Stereo) and (MMSS_CFG^.Mix_16Bit) and then 
   If }

If MMSS_CFG^.Output_Stopped Then
   Begin
   
    If Musique^.Ch_Number_Digit<>0 then
	 Begin
      If MMSS_CFG^.Wave_Output<>GUS Then Init_Tables_Modm; { Initialize the Volume and Buffer Tables }
      MMSS_Adjust_Vol(Musique^.Ch_Number);
      WaveOut_Init; { Init the GUS Panning }
	 End;
	 
   {$IFNDEF NoOPL}
   If (Musique^.Ch_Number_Adlib>0) and ((OPL_Model<>0) or (OPL_LPT_Model<>0)) Then InitOPL2;
   {$ENDIF} 

   Musique^.Note_Delta:=Musique^.Note_Size*(Musique^.Ch_Number_patt-Musique^.Ch_Number);
 
   Err_Sort:=PStart_Output;
   If Err_Sort<>Ok Then
      Begin
       MMSS_CFG^.Stop_Output:=False;
       MMSS_CFG^.Output_Stopped:=True;
      End;
	  
   End
   Else Err_Sort:=Ok;
{Writeln;
Writeln('Mix_16Bit:',MMSS_CFG^.Mix_16Bit);
Writeln('Out_16Bit:',MMSS_CFG^.Out_16Bit);}
{Writeln('DMA Buffer '+EntierHexa(MMSS_CFG^.Seg_Table_Volume,4)+':'++EntierHexa(MMSS_CFG^.Offset_DMA_Buffer,4));
Writeln('Debug1 '+EntierHexa(MMSS_CFG^.debug1,4));
Writeln('Debug2 '+EntierHexa(MMSS_CFG^.debug2,4));
Writeln('Debug3 '+EntierHexa(MMSS_CFG^.debug3,4));
Writeln('Debug4 '+EntierHexa(MMSS_CFG^.debug4,4));
Writeln('Debug5 '+EntierHexa(MMSS_CFG^.debug5,4));
Writeln('Debug6 '+EntierHexa(MMSS_CFG^.debug6,4));}
{Repeat Until Readkey=#13;}
MMSS_Start_Output:=Err_Sort;
End; {Start_Output}

{---------------------------------------------------------}

PROCEDURE MMSS_Stop_Output;
Begin
 If Not MMSS_CFG^.Output_Stopped Then { Si musique termin�e, ne pas l'arr�ter }
  Begin
   InitTexte;
   MMSS_CFG^.Stop_Output:=True;
   Repeat Until MMSS_CFG^.Output_Stopped;  { Can Crash }
  End;
SoundEnd;
MMSS_CFG^.Stop_Output:=False;
Fin_Tables_Modm;
End;  {MMSS_Stop_Output}

{---------------------------------------------------------}

FUNCTION MMSS_Start_Music:Word;
Begin

Move(Musique^.M_CH_Panning,MMSS_Info^.CH_Panning,Max_Channels);  { Copy the Default Panning }
With MMSS_CFG^ do If Not(Use_Panning_CMD) Then Calculer_Panning:=False;

{$IFDEF DEBUG}
Writeln('PStart_Music;');
{$ENDIF}
MMSS_Start_Music:=PStart_Music;
End; {MMSS_Start_Music}

{---------------------------------------------------------}

PROCEDURE MMSS_Stop_Musique;
Begin
If Not MMSS_CFG^.Musique_Term Then MMSS_CFG^.Musique_Term:=True;
End; {MMSS_Stop_Musique}

{---------------------------------------------------------}

(*PROCEDURE ChangerConfigModm;
{ Changer la fr�quence et la sortie sonore sans arr�ter la musique }
Begin
If Not (MMSS_CFG^.Musique_Terminee) Then
   Begin
   MMSS_CFG^.Stop_Player:=True;
   Repeat Until MMSS_CFG^.Musique_terminee;
   If MMSS_CFG^.Wave_Output=GUS Then
   If Musique^.Ch_Number>14 Then UltraOpen(Ultra_Config,Musique^.Ch_Number)
                              Else UltraReset(14);
   MMSS_CFG^.Stop_Player:=False;
   Ajuster_Out_Frequency;   { Ajuster la fr�quence }
   PStart_Output;      { Relancer la sortie   }
   End;
End; {ChangerConfigModm} *)

{---------------------------------------------------------}

{
PROCEDURE Tester_Vitesse;
BEGIN
 If MMSS_CFG^.Wave_Output<>GUS Then Init_Tables_Modm;
 AjusterVolume;
 Test_Vitesse;
 If MMSS_CFG^.Wave_Output<>GUS Then Fin_Tables_Modm;
END;} {Tester_Vitesse}


{---------------------------------------------------------}


{---------------------------------------------------------}

{$F+}
PROCEDURE Routine_Fin;
{ Stopper la musique si fin du programme (en cas d'erreur) }
Begin
 ExitProc:=SauveExit;
 MMSS_Stop_Output;
 MMSS_Stop_Musique;
 If MMSS_MUS_Loaded Then MMSS_FreeMemory;
End; {Routine_Fin}
{$F-}

{---------------------------------------------------------}

PROCEDURE WaveOut_SetDefault(W_Number: Byte); { Configure the default values and the output number }
Begin
 With MMSS_CFG^ do
  Begin
   Case W_Number of
    Hpint,
    LPT1,
    LPT2,
    TDY_DAC,
    C_DAC   : Out_Frequency:=10000;
    SB     : With SBConfig do
              Begin
               Out_Frequency:=16000;
               Utilise_DC:=(Type_>1);
               Use_DMA:=True;
               SB_BasePort:=Port;
               IRQ_SB:=IRQ;
               DMA_SB8:=DMA8;
               DMA_SB16:=DMA16;
               MMType_SB:=Type_; { Type de carte }
              End;
    SBPro  : Begin
              WaveOut_SetDefault(SB);
			  Out_Frequency:=16000;
              Utilise_Stereo:=False;
              {Utilise_Mixage:=False;}
              Utilise_Filtre:=False;
              SBP_Filtre(False);
              SBP_MasterVolume(15,15);             { Master Volume      }
              SBMixerWrite(mxrMasterVolume,$FF)    { Maximum DAC Volume }
             End;
{$IFNDEF NoGUS}
    GUS    : Begin
              MMSS_CFG^.GUS_BasePort:=Ultra_Base_Port;
              MMSS_CFG^.GUS_InterWave:=False;
              GUS_LineIn:=False;
              {MMSS_CFG^.GUS_IRQ:=Ultra_Config.GF1_IRQ_Num;}
              Taille_GUS:=UltraSizeDRAM
             End;
{$ENDIF}
   End;
   Wave_Output:=W_Number  { Init the Default selected Audio Output number }
  End
End; {WaveOut_SetDefault}

{---------------------------------------------------------}

PROCEDURE Init_Output_Devices(ShowDevice:Boolean); { Executed only at the player Start }
Var i:Byte;
    j:Word;

Begin {Init_Config_Sonore}

SB_LeftVol:=15; SB_RightVol:=15;
MMSS_Def_LeftPan:=$20; MMSS_Def_RightPan:=$60;
MMSS_Volume:=5*50;

LPT_Nb:=0;
j:=BiosSeg.LptBase[1];
If j <>0 Then
    Begin
     MMSS_CFG^.LPT1_Port:=j;
     MMSS_W_Output_Available[LPT1]:=True;
     If ShowDevice then Writeln('LPT1: ',EntierHexa(j,4)+'h ');
     LPT_Nb:=1
    End;

j:=BiosSeg.LptBase[2];
If j <>0 Then
    Begin
     MMSS_CFG^.LPT2_Port:=j;
     MMSS_W_Output_Available[LPT2]:=True;
     If ShowDevice then Writeln('LPT2: ',EntierHexa(j,4)+'h ');
     LPT_Nb:=2
    End;

If LPT_Nb=0 Then OPL_LPT_Nb:=0
   Else OPL_LPT_Nb:=1;
TDY_LPT_Nb:=OPL_LPT_Nb;
CMS_LPT_Nb:=OPL_LPT_Nb;

{$IFNDEF ModeXT}   { Crash on MegaEM }
 {Writeln('Detecte_DSS');
 Detecte_DSS(True);}
{$ENDIF}

{ Tandy Detection }
{Writeln('TDY_DetectDAC');}
 TDY_DetectDAC;
 If TDY_DACPort<>0 Then
   Begin
    If ShowDevice then Writeln('Tandy DAC Detected: ',EntierHexa(TDY_Port,3));
    MMSS_W_Output_Available[TDY_DAC]:=True;
    MMSS_CFG^.TDYDAC_Port:=TDY_DACPort
   End
  Else
   Begin
    If TDY_Type<>1 Then 
	   Begin
	   {Writeln('TDY_DetectOld');}
	   TDY_DetectOld;
	   End;
    If TDY_Type=1 Then 
	   If ShowDevice then Writeln('Tandy 1000/PC Junior Detected: ',EntierHexa(TDY_Port,3));
    MMSS_W_Output_Available[TDY_DAC]:=False;
   End;
   
{ Check for the Port Nb in the list }
 TDY_PortNb:=0;
 If TDY_Type<>0 then
    For i:=0 to TDY_PortTotal do
       If TDY_Port=TDY_PortList[i] then TDY_PortNb:=i;  
if TDY_PortNb=0 then 
   begin
   TDY_PortNb:=3;  { By default, Port 2C0 }
   TDY_Port:=TDY_PortList[TDY_PortNb]
   end;

 MMSS_CFG^.TDY_Type:=TDY_Type; 
 MMSS_CFG^.TDY_Port:=TDY_Port;

 {$IFNDEF NoGUS}
 {Writeln('GUS_Detect(ShowDevice);');}
 GUS_Detect(ShowDevice);
 MMSS_W_Output_Available[GUS]:=GUS_Presente;
 {$ELSE}
 MMSS_W_Output_Available[GUS]:=False;
 {$ENDIF}
 
 {Writeln('SB_Detect(ShowDevice);');}
 SB_Detect(ShowDevice); { Detect the OPL and SB to SB16 }

 MMSS_CFG^.OPL_Model:=OPL_Model;
 MMSS_W_Output_Available[HPint]  :=True;
 MMSS_W_Output_Available[C_DAC]  :=False; {Declared in the Command Line or Config File}
 If SB_presente and Not SBPro_Presente then MMSS_W_Output_Available[SB]:=True
    Else MMSS_W_Output_Available[SB]:=False;
 MMSS_W_Output_Available[SBPro]  :=SBPro_presente;

 For i:=0 to (MMSS_Out_Nb_W-1) do If MMSS_W_Output_Available[i] Then WaveOut_SetDefault(i);

{$IFNDEF NoGUS}
 If GUS_presente Then MMSS_BestOutput:=GUS
 Else 
{$ENDIF} 
 If SBPro_presente Then MMSS_BestOutput:=SBPro
    Else If SB_presente Then MMSS_BestOutput:=SB
	  Else If TDY_Port<>0 Then MMSS_BestOutput:=TDY_DAC
        Else MMSS_BestOutput:=HPint;
 
 MMSS_CFG^.Wave_Output:=MMSS_BestOutput;
End; {Init_Config_Sonore}

{==========================================================}
{              Initialisation de MODM_U                    }
{==========================================================}

PROCEDURE MMSS_Init (ShowMem:Boolean;ShowDevice:Boolean);

Begin
{ Init the Memory management code }
 Memoire_Initialisee:=False;   { First Start !!! }
 DetecteMemoire(ShowMem);
 MMSS_FreeMemory;

 MMSS_EMS_First:=False; {EMS_presente;}
 MMSS_Use_UMB:=UMB_presente;

{ Detect and initialize the audio devices }
 Init_Output_Devices(ShowDevice);
End;

BEGIN
{ Writeln('InitModm'); }

{ Initialise les pointeurs Mod Master }
 PInit_Tables(TablePtr);

 MMSS_Table:=TablePtr.Table;
 MMSS_CFG:=TablePtr.Variables;
 MMSS_Info:=TablePtr.Info;
 Musique:=TablePtr.Musique;
 

 If MMSS_Table^.Controle<>73 Then
  Begin
   Writeln('MMSS_Table^ Err'); Halt(1)
  End;

 If MMSS_CFG^.Controle<>73 Then
  Begin
   Writeln('MMSS_CFG^ Err'); Halt(1)
  End;

 If  MMSS_Info^.Controle<>73 Then
  Begin
   Writeln('MMSS_Info^ Err'); Halt(1)
  End;

 If Musique^.Controle<>73 Then
  Begin
   Writeln('Musique^ Err'); Halt(1)
  End;

 MMSS_Info^.DMA_Buffers_Max_Size:=Max_Buffer_Samples_Nb;

 SauveExit:=ExitProc;    { Mise en place de la routine de fin }
 ExitProc:=@Routine_Fin;
END.