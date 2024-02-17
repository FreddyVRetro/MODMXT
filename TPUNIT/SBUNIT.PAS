{************************************************************************}
{                                SBUNIT.PAS                              }
{                                                                        }
{  Unit‚ pour les cartes Sound Blaster, SB Pro, SB16 et compatibles      }
{                                                                        }
{  Aout 1995: Carte Adlib.                                               }
{                                                                        }
{  AUTEURS: Freddy V‚tel‚, Juan Carlos Ar‚valo (Vangelis Tracker)        }
{           et Fabrice Couteau.                                          }
{                                                                        }
{                               D‚but d'‚criture le --/11/94             }
{                               DerniŠres modifications le 05/02/19      }
{************************************************************************}
UNIT SBUNIT;
{$A+,Q-,G-,R-,S-}
{$I MODMCFG.INI}

INTERFACE

CONST

  { Offset des Ports I/O }
  MixAddrPortOffset  = $04;  { Mixer register port.             Write Only }
  MixDataPortOffset  = $05;  { Mixer data port.                 Read/Write }

  DSPResetPortOffset = $06;  { DSP Reset port.                  Write Only SB   }
  DSPReadPortOffset  = $0A;  { DSP Read data port.              Read  Only SB   }
  DSPLifePortOffset  = $0A;  { DSP Read data port.              Read  Only SB   }
  DSPWStatPortOffset = $0C;  { DSP Write buffer status port.    Write Only SB   }
  DSPWritePortOffset = $0C;  { DSP Write data port.             Write Only SB   }
  DSPRStatPortOffset = $0E;  { DSP Read buffer status port.     Read  Only SB   }
  DSP8AckPortOffset  = $0E;  {  8 bit DMA IRQ Acknowledge port. Write Only SB   }
  DSP16AckPortOffset = $0F;  { 16 bit DMA IRQ Acknowledge port. Write Only SB16 }
                      { 10}  { CD-ROM Command or Data Register  Read/Write SBPr }
		      { 11}  { CD-ROM Status Register           Read  Only SBPr }
		      { 12}  { CD-ROM Reset Register            Write Only SBPr }
		      { 13}  { CD-ROM Enable Register           Write Only SBPr }

  { Registres de la puce Mixer CT1335 (SB2 CD) }
  mxrDataReset   =$00;
  mxrMasterVol   =$02;   { 3-1 Master Volume                             }
  mxrFMControl   =$06;   { 6-Gauche On/Off 7- Droite On/On 3-1 Volume    }
  mxrCDVolume    =$06;
  mxrMicroVolume =$0A;   { 2-0 Volume Micro                              }

  {*  Left volume only for SB Pro                           }
  {** Pour SB 16, Bits 7-4 pour Gauche et 3-0 pour Droite   }

  { Registres de la puce Mixer CT1345 (SBPro) }
  mxrDACVolume   =$04;   { 7-5 Vol DAC Gauche 3-1 Vol DAC Droite    * ** }
  mxrInSetting   =$0C;   { Reglages Entr‚e et Filtre                     }
  mxrOutSetting  =$0E;   { 1- Stereo On  5- Filtre Off                   }
  mxrMasterVolume=$22;   { 7-5 Volume Gauche  3-1 Volume Droite        * }
  mxrFMVolume    =$26;   { 7-5 Volume FM Gauche  3-1 Volume FM Droite  * }
  mxrCDVolumeP   =$28;   { 7-5 Volume CD Gauche  3-1 Volume CD Droite  * }
  mxrLineVolume  =$2E;   { 7-5 Volume In Gauche  3-1 Volume In Droite  * }
  { * Pour SB 16, Bits 7-4 pour Gauche et 3-0 pour Droite  }

  { Registres de la puce Mixer ( SG NX Pro) }
  mxrBass        =$46;   { 2-0 Niveau des basses                         }
  mxrTremble     =$44;   { 2-0 Niveau des aigus                          }

  { Registres de la puce Mixer CT1745 (SB16) }
  mxrMasterVolumeG =$30; { 7-3 Volume Gauche                             }
  mxrMasterVolumeD =$31; { 7-3 Volume Droite                             }
  mxrDACVolumeG    =$32; { 7-3 Volume DAC Gauche                         }
  mxrDACVolumeD    =$33; { 7-3 Volume DAC Droite                         }
  mxrFMVolumeG     =$34;
  mxrFMVolumeD     =$35;
  mxrCDVolumeG     =$36;
  mxrCDVolumeD     =$37;
  mxrINVolumeG     =$38;
  mxrINVolumeD     =$39;
  mxrESSVersion    =$40; { ESS: Read the ESS Chip Version                }
  mxrMicroVolume16 =$3A; { 7-3 Volume Micro                              }
  mxrPCSpeakerVol  =$3B; { 7-6 Volume PC Speaker                         }
  mxrOutControl    =$3C; {                                               }
  mxrIRQ           =$80;
  mxrDMA           =$81;

  { Masques pour le Mixer ... }
  mxiFilterVal=$38;
  mxoFilterNeg=$20;      { Reg $0E bit 5=1 => Filtre Off                 }
  mxoStereoOn =$02;      { Reg $0E bit 1=1 => St‚r‚o On                  }

  { Registre de la puce OPL2  }
  OPL2Test   = $01;
  OPL2Timer1 = $02;
  OPL2Timer2 = $03;
  OPL2TimCtr = $04;      { Contr“le des Timer.                           }
  OPL2CtrlG  = $08;      { Contr“le g‚n‚ral.                             }
  OPL2AM_VIB = $20;      {                                               }
  OPL2KSL_TL = $40;      { KSL et Niveau total.                          }
  OPL2AR_DR  = $60;      { Vitesse d'attaque et Vitesse de d‚croissance. }
  OPL2SL_RR  = $80;      { Niveau soutenu et vitesse de relachement.     }
  OPL2Fnum   = $A0;
  OPL2Key    = $B0;
  OPL2FB_FM  = $C0;
  OPL2WS     = $E0;      { Wave Select.                                  }

  bKey = $20;            { Masque pour Key                               }

  { Commandes DSP   }
  sbcSendOneSample  = $10; { Sortie DAC Directe. (Mono, 20KHz Maxi)          }
  sbcStartLSpeedDMA = $14; { D‚part du transfer DMA Basse vitesse. (Mono, SB)}
                      {16} {8/2 ADPCM DMA }
  sbcStartLSDMA	    = $1C; { Low Speed Autoinit DMA                          } {1.05+}
  sbcStartLSDMA16   = $1D; { Low Speed Autoinit DMA 16Bit                    } {ESS}
  sbcReadOneSample  = $20; { Entr‚e ADC Directe. (Mono, 20KHz Maxi)          }
  sbcSetTimeConst   = $40; { Envoyer la fr‚quence. (Commandes $14 et $91)    }
  sbcSetSampleRate  = $41; { Envoyer la fr‚quence. (SB16)                    }
  sbcSetHSpeedSize  = $48; { Envoyer la taille du transfer DMA Rapide.       }
                      {90} { Transfer DMA Haute Vitesse 8Bit Auto init       } {2.01+}
  sbcStartHSpeedDMA = $91; { Transfer DMA Haute Vitesse 8Bit Single          } {2.01+}
					  {Bx} { Transfert DMA 16Bit                             } {4+}
					  {D0} { Pause DMA Transfer }
  sbcTurnOnSpeaker  = $D1; { Turn on the SB speaker.                         }
  sbcTurnOffSpeaker = $D3; { Turn off the SB speaker.                        }
					  {D4} { Resume DMA Transfer } {  }
  sbcGetDSPVersion  = $E1; { Lire la Version du DSP.                         }
  sbcGetCopyright   = $E3; { Lire la chaine copyright de la carte.           }
  sbcGetBBFirmware  = $E5; { BlasterBoard Command, to Read the Firmware Version }

CONST  { Informations sur la carte }
  VersionSBMin : BYTE       = 0;
  VersionSBMaj : BYTE       = 0;
  VersionSB    : WORD       = 0;
  VersionBBMin : BYTE       = 0;
  VersionBBMaj : BYTE       = 0;
  VersionStrSb : STRING[ 5] = '';
  CopyrightSb  : STRING[80] = '';

  SbOk           : BOOLEAN = False;
  SBName : Array[1..8] of String[20]=('Sound Blaster 1.0','Sound Blaster 1.5','Sound Blaster 2',
                                      'BlasterBoard','BlasterBoard 2.1+','Sound Blaster Pro','Sound Blaster Pro 2',
                                      'Sound Blaster 16');

  SB_MaxFreq : Array[1..8] of Array[0..1] of Word = (
  (22100,0),(22100,0),(44100,0),(62000,0),(62000,0),
  (44100,21700),(44100,21700),(44100,44100) );
  OPL_PortList : Array[1..4] of Word = ($388,$388,$388,$388);

{ SB Type :                              }
{           0-No SB                      }
{           1-Sound Blaster 1.0       SB }
{           2-Sound Blaster 1.5       SB }
{           3-Sound Blaster 2.x       SB }
{           4-BlasterBoard            SB }
{           5-BlasterBoard2           SB } { BlasterBoard with SB16 signed }
{           6-Sound Blaster Pro       SBP}
{           7-Sound Blaster Pro 2.x   SBP}
{           8-Sound Blaster 16        SBP}
{ Need to change in SBCMD.ASM as well SBP}

  T_NoSB = 0;
  T_SB1  = 1;
  T_SB15 = 2;
  T_SB2  = 3;
  T_BB   = 4;
  T_BB2  = 5;
  T_SBP  = 6;
  T_SBP2 = 7;  
  T_SB16 = 8; 

CMS_PortTotal = 7;
CMS_PortList : Array[0..7] of Word = (0,$0210,$0220,$230,$240,$250,$260,$270);

TYPE
{ DSP Version                                  }
{           0 - No DSP                         }
{           1 - DSP 1.0  (DMA Not Auto Init)   }
{           2 - DSP 1.5  (DMA AutoInit 22KHz)  }
{           3 - DSP 2.x  (Add Fast Mode 44KHz) }
{           4 - DSP 2.x  (BlasterBoard  64KHz) }
{           5 - DSP 2.x  (BlasterBoard Signed) }
{           6 - DSP 3.x  (Stereo               }
{           7 - DSP 4.x  (Stereo 16 Bit        }

    TConfigSB = Record
                 Port  : Word;
                 IRQ   : Byte;
                 DMA8  : Byte;
                 DMA16 : Byte;
                 Type_ : Byte;
				 DSP_Maj : Byte;
				 DSP_Min : Byte;
				 MIX_Version : Byte;
                End;

VAR
  Version_ESS: Word;
  SBConfig  : TConfigSB;
  SB_LeftVol,SB_RightVol:Byte;
  
  OPL_Base      : Word;
  OPL_LPT_Base  : Word; { 0, Not Present, otherwise, Contains I/O Port }
  OPL_LPT_Nb    : Byte; { LPT1/LPT2... }

  CMS_Type    : Byte; { 0 : Nothing 1 : CMS 2: CMS LPT 3: Emulated}
  CMS_Port    : WORD; { 0 Not present otherwise, Port }
  CMS_PortNb  : Byte; { Port Nb in the list }
  CMS_LPT_Nb  : Byte; { 0 No, 1 LPT1 2 LPT2 }

{==========================================================}

{ Routines DSP Sound Blaster        }
PROCEDURE Attendre_DSP;
PROCEDURE DSP_Write(Valeur: Byte);
FUNCTION  DSP_Read: Byte;
PROCEDURE GetSbDSPVersion;
PROCEDURE SbGetCopyrightString;
FUNCTION  Init_DSP: Boolean;
PROCEDURE Ecrire_DAC(Valeur:Byte);
FUNCTION  Lire_ADC:Byte;

{ Routines pour la puce Mixer SBPro }
PROCEDURE SBMixerWrite(Reg, Val: Byte);
FUNCTION  SBMixerRead(Reg: Byte): Byte;
FUNCTION  DetecteMixerSBPro: Boolean;
FUNCTION  DetecteMixerSB16 : Boolean;

{ R‚glages Mixer SBPro              }
PROCEDURE SBP_MasterVolume(VolLeft,VolRight: Byte);
PROCEDURE SBP_ReadVolume(Var VolLeft,VolRight: Byte);
PROCEDURE SBP_Filtre(Position: Boolean);

{ Gestion de la puce OPL2           }
{$IFNDEF NoOPL}
PROCEDURE WriteOPL2(Registre,Donnee: Byte);
PROCEDURE InitOPL2;
FUNCTION  DetecteOPL2 : Byte;
{$ENDIF}

{ Gestion de la variable BLASTER    }
FUNCTION  VariableBLASTER: Boolean;
PROCEDURE ChercheParametresSB;

{ D‚tection des cartes sonores et initialisation de l'unit‚ }
FUNCTION SB_Detect(Affichage: Boolean) : BOOLEAN;

{==========================================================}

IMPLEMENTATION

USES DOS,CRT,BiosEqu,VARUnit,Util;


  { Constantes et variables 'Invisibles' (Pas dans DS)    }

CONST BLASTER: Array[1..7] of Char='BLASTER';

  { Registres I/O }
  MixAddrPort  : WORD = $220 + MixAddrPortOffset;
  MixDataPort  : WORD = $220 + MixDataPortOffset;

  DSPResetPort : WORD = $220 + DSPResetPortOffset;
  DSPReadPort  : WORD = $220 + DSPReadPortOffset;
  DSPLifePort  : WORD = $220 + DSPLifePortOffset;
  DSPWStatPort : WORD = $220 + DSPWStatPortOffset;
  DSPWritePort : WORD = $220 + DSPWritePortOffset;
  DSPRStatPort : WORD = $220 + DSPRStatPortOffset;
  DSP8AckPort  : WORD = $220 + DSP8AckPortOffset;
  DSP16AckPort : WORD = $220 + DSP16AckPortOffset;

  OfsOp : Array[1..9] of Byte = ($00,$01,$02,$08,$09,$0A,$10,$11,$12);

{==========================================================}

PROCEDURE Attendre_DSP; Assembler;
ASM
 MOV SbOk,True
 MOV DX,DSPWritePort
 MOV CX,2000
@bo_att_DSP:
 IN AL,DX
 OR AL,AL
 JNS @Fin_bo_att_DSP
 LOOP @bo_att_DSP
 MOV SbOk,False   { Erreur SB }
@Fin_bo_att_DSP:

END; {Attendre_DSP}

{---------------------------------------------------------}

PROCEDURE DSP_Write(Valeur: Byte); Assembler;
ASM
 CALL Attendre_DSP
 MOV DX,DSPWritePort
 MOV AL,Valeur
 OUT DX,AL
END; {DSP_Write}

{---------------------------------------------------------}

FUNCTION DSP_Read: Byte; Assembler;
ASM
 MOV SbOk,True
 MOV DX,DSPRStatPort
 MOV CX,0
@bo_att_DSP:
 IN AL,DX
 OR AL,AL
 JS @Fin_bo_att_DSP
 LOOP @bo_att_DSP
 MOV SbOk,False   { Erreur SB }
@Fin_bo_att_DSP:
 MOV DX,DSPReadPort
 IN  AL,DX
END; {DSP_Read}

{---------------------------------------------------------}

PROCEDURE GetSbDSPVersion;
VAR  t: WORD;
     s: STRING[2];
BEGIN
 DSP_Write(sbcGetDSPVersion);
 t:=0;
 REPEAT
  VersionSbMaj:=DSP_Read;
  INC(t);
 UNTIL ((VersionSbMaj<>$AA) AND (SbOk)) OR (t>=10);
 VersionSbMin:=DSP_Read;

 STR(VersionSbMaj,VersionStrSb);
 STR(VersionSbMin,s);
 IF VersionSbMin>9 THEN VersionStrSb:=VersionStrSb+'.'+s
                   ELSE VersionStrSb:=VersionStrSb+'.0'+s;
 VersionSB:=VersionSbMin+VersionSbMaj SHL 8;
END; {GetSbDSPVersion}

FUNCTION GetBBFirmwareVersion:BOOLEAN;
VAR  s: STRING[2];
BEGIN
 DSP_Write(sbcGetBBFirmware);
 VersionBBMaj:=DSP_Read;

 If SbOk Then
    Begin
	BB_Presente :=True;
    VersionBBMin:=DSP_Read;
	End;
  GetBBFirmwareVersion:=SbOk;
END; {GetSbDSPVersion}

{---------------------------------------------------------}

PROCEDURE SbGetCopyrightString;
VAR t: WORD;
BEGIN
  DSP_Write(sbcGetCopyright); { Send command. }
  t:=0;
  REPEAT
   CopyrightSb:=CHAR(DSP_Read);
   INC(t);
  UNTIL ((CopyrightSb[1]<>#$AA) AND SbOk) OR (t=10);

  WHILE SbOk AND (Length(CopyrightSb)<80) DO
   CopyrightSb:=CopyrightSb+CHAR(DSP_Read);
  DEC(CopyrightSb[0]);
END; {SbGetCopyrightString}

{---------------------------------------------------------}

FUNCTION Init_DSP: BOOLEAN;
CONST ready = $AA;
VAR ct, donnee : BYTE;
BEGIN
 PORT[DSPResetPort]:=1;
 FOR ct:=1 TO 100 DO;
 PORT[DSPResetPort]:=0;

 donnee:=0;
 ct:=0;
 WHILE (donnee<>ready) AND (ct<100) DO BEGIN
  donnee:=PORT[DSPRStatPort];
  donnee:=PORT[DSPReadPort];
  INC(ct);
 END;
 If Donnee=Ready Then DSP_Write(sbcTurnOnSpeaker);
 Init_DSP:=Donnee=Ready;
END; {Init_DSP}

{---------------------------------------------------------}

PROCEDURE Ecrire_DAC(Valeur:Byte);
BEGIN
DSP_Write(sbcSendOneSample);   { Commande sortie directe DAC }
DSP_Write(Valeur);             { Envoyer la valeur           }
END; {Ecrire_DAC}

{---------------------------------------------------------}

FUNCTION Lire_ADC:Byte;
BEGIN
DSP_Write(sbcReadOneSample);   { Commande lecture directe ADC }
Lire_ADC:=DSP_Read;            { Lire la valeur               }
END; {Lire_ADC}

{=========================================================}

PROCEDURE SBMixerWrite(Reg, Val: Byte); Assembler;
ASM
 MOV DX,MixAddrPort
 MOV AL,Reg
 OUT DX,AL
 MOV DX,MixDataPort
 MOV AL,Val
 OUT DX,AL
End; {SBMixerWrite}

{---------------------------------------------------------}

FUNCTION SBMixerRead(Reg: Byte): Byte; Assembler;
ASM
 MOV DX,MixAddrPort
 MOV AL,Reg
 OUT DX,AL
 MOV DX,MixDataPort
 IN  AL,DX
End; {SBMixerRead}

{---------------------------------------------------------}

FUNCTION DetecteMixerSBPro: Boolean;        { Sound Blaster Pro Registers (And SB 2.2) }
Var SaveReg,NewReg: Byte;
Begin
 SaveReg:=SBMixerRead(mxrMasterVolume);
 SBMixerWrite(mxrMasterVolume,243);     {F3}
 NewReg :=SBMixerRead(mxrMasterVolume);
 SBMixerWrite(mxrMasterVolume,SaveReg);
 Mixer_SBPro_Present:=(NewReg=243);         {F3}
 DetecteMixerSBPro:=Mixer_SBPro_Present;
End; {DetecteMixerSBPro}

{---------------------------------------------------------}

FUNCTION  DetecteESS: Boolean;

Var b1,b2:Byte;
Begin
Version_ESS:=0;
ASM
 MOV DX,MixAddrPort
 MOV AL,40h
 OUT DX,AL
 MOV DX,MixDataPort
 IN  AL,DX
 MOV b1,AL
 IN AL,DX
 MOV b2,AL
End; 
If b1=$18 then
   Begin
   DetecteESS:=True;
   Version_ESS:=1868+b2-$68;
   {Write(b1,' ',b2,' ');}
   End
   Else DetecteESS:=False
End;
{---------------------------------------------------------}

FUNCTION DetecteMixerSB16: Boolean;        { Sound Blaster 16 Registers        }
Var SaveReg,SaveReg1,NewReg,NewReg1: Word;
Begin
 SaveReg:=SBMixerRead(mxrMasterVolumeG);
 SaveReg1:=SBMixerRead(mxrMasterVolumeD);
 SBMixerWrite(mxrMasterVolumeG,$F8);
 SBMixerWrite(mxrMasterVolumeD,$F8);
 NewReg :=SBMixerRead(mxrMasterVolumeG);
 NewReg1:=SBMixerRead(mxrMasterVolumeD);
 SBMixerWrite(mxrMasterVolumeG,SaveReg);
 SBMixerWrite(mxrMasterVolumeD,SaveReg1);
 Mixer_SB16_Present:=((NewReg=$F8) And (NewReg1=$F8));
 DetecteMixerSB16:=Mixer_SB16_Present;
End;  {DetecteMixerSB16}

{---------------------------------------------------------}

PROCEDURE SBP_MasterVolume(VolLeft,VolRight: Byte);
Begin
 If Mixer_SBPro_Present Then
  SBMixerWrite(mxrMasterVolume,(VolRight AND $0F)+(VolLeft SHL 4))
End; {SBP_MasterVolume}

{---------------------------------------------------------}

PROCEDURE SBP_ReadVolume(Var VolLeft,VolRight: Byte);
Begin
 VolLeft:=15; VolRight:=15;
 If Mixer_SBPro_Present Then
  Begin
   VolRight:=SBMixerRead(mxrMasterVolume);
   VolLeft :=VolRight SHR 4;
   VolRight:=VolRight AND $0F
  End
End; {SBP_ReadVolume}

{---------------------------------------------------------}

PROCEDURE SBP_Filtre(Position: Boolean); { Filtre de sortie SBPro }
Begin
 If Position Then
  SBMixerWrite(mxrOutSetting,(SBMixerRead(mxrOutSetting) AND $DF)) {11011111}
 Else
  SBMixerWrite(mxrOutSetting,(SBMixerRead(mxrOutSetting) OR  $20)) {00100000}
End; {ReglerFiltre}

{=========================================================}
{$IFNDEF NoOPL}

PROCEDURE AdLibLoop; Assembler;
ASM
 @lp:
  IN AL,DX
 LOOP @lp
END; {AdLibLoop}

{---------------------------------------------------------}

PROCEDURE WriteOPL2(Registre,Donnee: Byte); Assembler;
ASM

 MOV DX,OPL_LPT_Base
 OR DX,DX
 JNZ @WriteOPL2LPT

 MOV DX,OPL_Base
 MOV AL,Registre
 OUT DX,AL

 MOV CX,6
 CALL AdLibLoop

 INC DX
 MOV AL,Donnee
 OUT DX,AL

 DEC DX
 MOV CX,35
 CALL AdLibLoop
 JMP @WriteOPL2End

@WriteOPL2LPT:

 MOV AL,Registre
 OUT DX,AL  { LPT Data }
 
 INC DX
 INC DX     { LPT Control }
 MOV AL,13
 OUT DX,AL
 SUB AL,4
 OUT DX,AL 
 ADD AL,4
 OUT DX,AL

 DEC DX
 DEC DX
 MOV CX,6
 CALL AdLibLoop
 
 MOV AL,Donnee
 OUT DX,AL

 INC DX
 INC DX     { LPT Control }
 MOV AL,12
 OUT DX,AL
 SUB AL,4
 OUT DX,AL 
 ADD AL,4
 OUT DX,AL 

 DEC DX
 DEC DX
 MOV CX,35
 CALL AdLibLoop

@WriteOPL2End: 
END; {WriteOPL2}

{---------------------------------------------------------}

FUNCTION ReadOPL2(Registre: Byte):Byte; Assembler;
ASM
 MOV DX,OPL_LPT_Base
 CMP DX,0
 JNZ @ReadOPL2LPT

 MOV DX,OPL_Base
 MOV AL,Registre
 OUT DX,AL

 MOV CX,6
 CALL AdLibLoop

 INC DX
 IN  AL,DX
 
 PUSH AX
 DEC DX
 MOV CX,35
 CALL AdLibLoop
 POP AX
 JMP @ReadOPL2End
@ReadOPL2LPT:
 XOR AX,AX      { Can not read registers }
@ReadOPL2End: 
END; {WriteOPL2}

{----------------------------------------------------------}

FUNCTION DetecteOPL2 : Byte; { Can not detect OPLx LPT }
Var X,X2:Byte;
    Save_OPL2LPT:Word;
Begin
 Save_OPL2LPT:=OPL_LPT_Base;
 OPL_LPT_Base:= 0;           { Disable the use of OPL2LPT }

 WriteOPL2(OPL2Test,0);
 WriteOPL2(OPL2TimCtr,$60);         {Initialiser les Compteurs    }
 WriteOPL2(OPL2TimCtr,$80);         {Efface le registre de statut }
 Delay(10);
 X:=Port[OPL_Base];                 {Lire le statut               }
 WriteOPL2(OPL2Timer1,$FF);         {Regle le compteur 1 … 255    }
 WriteOPL2(OPL2TimCtr,$21);         {Envoie donn‚es + d‚marre le compteur }
 Delay(10);                         {Attendre ...                 }
 X2:=Port[OPL_Base];                {Lire le statut               }
 WriteOPL2(OPL2TimCtr,$60);         {Init les compteurs           }
 WriteOPL2(OPL2TimCtr,$80);
 X := X  AND $E0;
 X2:= X2 AND $E0;
 
{ Writeln('OPL Detect : X, X2:',X,X2, 'Base: ',EntierHexa(OPL_Base,3));}
 
 If ( ((X=$0) AND (X2=$C0)) = True ) Then
    Begin
    X:=Port[OPL_Base];  { Read Status Register }
    If (x AND $06)=0 Then DetecteOPL2:=2  {OPL3}
                     else DetecteOPL2:=1; {OPL2}
    End
    Else DetecteOPL2:=0;
 OPL_LPT_Base:=Save_OPL2LPT; { Restore the Value }
End; {DetecteOPL2}

{---------------------------------------------------------}

PROCEDURE InitOPL2;
Var i:Byte;
Begin

If OPL_LPT_Model>0 then OPL_LPT_Base:=BiosSeg.LptBase[OPL_LPT_Nb]
   Else OPL_LPT_Base:=0;
{Writeln('InitOPL2 (Base): ',EntierHexa(OPL_LPT_Base,3));
Repeat until Readkey=#13;}

 For i:=1 to 9 do 
  Begin
 WriteOPL2(OPL2Key+(i-1),0);           { Key Off }
 WriteOPL2(OPL2KSL_TL+OfsOp[i]+3,$3F); { Volume porteuse … 0   } 
 WriteOPL2(OPL2KSL_TL+OfsOp[i],$3F);   { Volume modulateur … 0 }
 WriteOPL2(OPL2KSL_TL+OfsOp[i]+3,$3F); { Volume porteuse … 0   }
  End;
 WriteOPL2($01,$20);           { Activer l'utilisations des formes d'onde }
 WriteOPL2($BD,0);             { 9 Channel FM Mode          }
 WriteOPL2($04,0);             { Disable Timer              }
 WriteOPL2($08,0);             { FM Mode (Not Speech)       } 
End;

{$ENDIF}
{=========================================================}

FUNCTION VariableBLASTER: Boolean;
Begin
 VariableBLASTER:=(GetEnv(BLASTER)<>'')
End; {VariableBLASTER}

{----------------------------------------------------------}

PROCEDURE ChercheParametresSB;
Var chaine: String[20];
    i: Byte;
Begin
 chaine:=Maj(GetEnv(BLASTER));
 i:=Pos('A',chaine)+1;
 If i>1 Then
  Begin
   SBConfig.Port:=(Ord(chaine[i])-48) SHL 8+(Ord(chaine[i+1])-48) SHL 4;
  End
  Else SBConfig.Port:=0;
 i:=Pos('I',chaine)+1;
 If i>1 Then
  Begin
   If chaine[i]='1' Then SBConfig.IRQ:=10
      Else SBConfig.IRQ:=Ord(chaine[i])-48;
   If Not(SBConfig.IRQ in [2,5,7,10]) Then SBConfig.IRQ:=7;
  End
  Else SBConfig.IRQ:=5;
 i:=Pos('D',chaine)+1;
 If i>1 Then
  Begin
   SBConfig.DMA8:=Ord(chaine[i])-48;
   If SBConfig.DMA8>3 Then SBConfig.DMA8:=1
  End
  Else SBConfig.DMA8:=1;
 i:=Pos('H',chaine)+1;
 If i>1 Then
  Begin
   SBConfig.DMA16:=Ord(chaine[i])-48;
  End
  Else SBConfig.DMA16:=1;
End; {ChercheParametresSB}

{----------------------------------------------------------}

FUNCTION Test_DSPPort(Port:Word) : BOOLEAN;
Begin

   MixAddrPort:=SBConfig.Port+MixAddrPortOffset;
   MixDataPort:=SBConfig.Port+MixDataPortOffset;

   DSPResetPort:=SBConfig.Port+DSPResetPortOffset;
   DSPReadPort :=SBConfig.Port+DSPReadPortOffset;
   DSPLifePort :=SBConfig.Port+DSPLifePortOffset;
   DSPWStatPort:=SBConfig.Port+DSPWStatPortOffset;
   DSPWritePort:=SBConfig.Port+DSPWritePortOffset;
   DSPRStatPort:=SBConfig.Port+DSPRStatPortOffset;
   DSP8AckPort :=SBConfig.Port+DSP8AckPortOffset;
   DSP16AckPort:=SBConfig.Port+DSP16AckPortOffset;

   Test_DSPPort:=Init_DSP;
END;


FUNCTION Scan_DSPPort: BOOLEAN;
BEGIN
 SB_Presente:=False;
 SBConfig.Port:=$210;

 WHILE (NOT SB_Presente) AND (SBConfig.Port<=$280) DO
  BEGIN
 {  Writeln('* Test SB Port:',EntierHexa(SBConfig.Port,3)+'h');}
   IF NOT TEST_DSPPort(SBConfig.Port) THEN INC(SBConfig.Port,$10)
      Else SB_Presente:=True;
  END;

 Scan_DSPPort:=SB_Presente;
END;

{ Return the Miver "Version" }
FUNCTION Detect_Mixer :Byte; 
Begin

End;

{----------------------------------------------------------}

FUNCTION SB_Detect(Affichage: Boolean): BOOLEAN;
Begin
 SBConfig.Type_:=T_NoSB;
 OPL_Base := $388;
 CMS_Port := $220;
 CMS_PortNb:= 2; {220h by default}
 
 {Writeln('* Detect SB start');}
 
{$IFNDEF NoOPL}
 OPL_Model:=DetecteOPL2;
{$ENDIF}

 ChercheParametresSB;
 If SBConfig.Port<>0 Then 
    Begin
{	 Writeln('* Test SB Port:',EntierHexa(SBConfig.Port,3)+'h');}
     If Test_DSPPort(SBConfig.Port) Then 
	  Begin
	  {Writeln('Port Env Ok');}
	  SB_Presente:=True
	  End
    End
     Else 
	 Begin 
	 Scan_DSPPort;
     If SB_Presente Then
        If Affichage then Writeln('No BLASTER Variable : IRQ and DMA may be incorrect');
	 End;
 
 If SB_Presente Then         { Detect the DSP }
  Begin
  { Writeln('* SB Detected');}
   Init_DSP;
   GetSBDSPVersion;
 {  Writeln('* DSP Version : ',VersionStrSb);}
   
   If (OPL_Model=0) and (VersionSBMaj>0) then
      Begin
       If Affichage then Writeln('Force OPL');
       OPL_Model:=1;
	   If VersionSBMaj>2 then OPL_Model:=2;
      End;

   If VersionSB=$100 then SBConfig.Type_:=T_SB1;
   If VersionSB=$105 then SBConfig.Type_:=T_SB15;
   If VersionSBMaj=2 then SBConfig.Type_:=T_SB2;
   If VersionSB=$300 then SBConfig.Type_:=T_SBP; { SBP  }
   If (VersionSBMaj=3) and (VersionSbMin>0) then SBConfig.Type_:=T_SBP2; { SBP2 }
   If VersionSBMaj=4 then {SB16 or More }
      Begin
	   SBConfig.Type_:=T_SB16;
	   SB16_Presente:=True;
	  End;
   If SBConfig.Type_>=T_SBP then 
      Begin
	  SBPro_Presente:=True;
	  Mixer_SBPro_Present:=True;
	  End;
	
   If GetBBFirmwareVersion Then 
	 Begin
	  SBConfig.Type_:=T_BB;
	 If Affichage then Writeln('BlasterBoard Found (',VersionBBMaj,'.',VersionBBMin,')');
	  If ((VersionBBMaj=2) and (VersionBBMin>=1)) then { 03/01/22 Corrected 2.0 detection problem }
         SBConfig.Type_:=T_BB2; { BB Supporting the SB16 Command }
	 End;
  
  Init_DSP; { Needed as the BlasterBoard command crash some SB Boards }
  End; { SB_Presente }

 If Affichage Then With SBConfig do
  Begin
{$IFNDEF NoOPL}
   If OPL_Model<>0 Then
     Begin
      Case OPL_Model of
       1: Write('OPL2');
       2: Write('OPL3');
      End;
      Writeln(' found (Port: 388h)');
	  InitOPL2;
     End;
{$ENDIF}	 
   If SB_Presente Then
    Begin
	
    Writeln('BLASTER=',Maj(GetEnv(BLASTER)));
	Writeln(SBName[SBConfig.Type_],' (DSP ' ,VersionStrSb,') found at ',EntierHexa(Port,3)+'h',
            ' (IRQ ',IRQ,',DMA ',DMA8,',HDMA ',DMA16,')');
			
    If SBConfig.Type_>=T_SBP then
	   Begin
	   	If DetecteESS then Writeln('ESS Audio Drive ',Version_ESS);
       End;
	End
{	Else If VersionSB<>0 Then Writeln('* Unknown DSP Version',VersionSB);}
  End;

 SB_Detect:=SB_Presente;
End;  { SB_Detect }

{==========================================================}

END.
