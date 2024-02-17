{ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป}
{บ                      --==๐๐ MMSS_CMD.PAS ๐๐==--                       บ}
{บ                                                                      บ}
{บ Unit de commande de Mod Master.                                     บ}
{บ                                                                      บ}
{บ AUTEUR: Freddy Vtel.                                               บ}
{วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ}
{บ Compatibilite: 8086          Debut d'ecriture๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚04/11/95 บ}
{บ                              Dernires modifications๚๚๚๚๚๚๚๚04/11/95 บ}
{ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ}
UNIT MMSS_CMD;
{$G-}
{$I MODMCFG.INI}

INTERFACE
{$IFNDEF NoGUS}
USES CRT,MMSS_Var,GUSUnit,SBUnit;
{$ELSE}
USES CRT,MMSS_Var,SBUnit;
{$ENDIF}

PROCEDURE Init_Tables_Modm;
PROCEDURE Fin_Tables_Modm;
PROCEDURE MMSS_Adjust_Vol(Channels_Nb:Byte); { Adjust the Volume Table volume with the Number of channels }
FUNCTION Get_MaxFreq(sortie,TypeSB: Byte; stereo,DC: Boolean): Word;

{ Gestion de la sequence }

PROCEDURE MMSS_PrevPattern;            { Recule d'une MMSS_Pattern dans la sequence }
PROCEDURE MMSS_NextPattern;            { Avance d'une MMSS_Pattern dans la sequence }
PROCEDURE MMSS_SetPattern(Numero:Byte);{ Se placer … la MMSS_Pattern 'Numero'       }

IMPLEMENTATION

{=========================================================}

Var Segment_Table_Volume: Word;

{---------------------------------------------------------}

PROCEDURE Init_Tables_Modm;
Var PSegment_Tampon1: Word;
    Offset_Test : WORD;

Begin

{Write('Init_Tables_Modm ');
Writeln(MaxAvail);}

 If MaxAvail<VolumeMix_Table_Size Then
  Begin
   ASM
    MOV AX,03h
    INT 10h
   End;
   Writeln('Vol Table OOM (',MaxAvail-VolumeMix_Table_Size,')');
   Halt
  End;

 GetMem(Tables_Modm,VolumeMix_Table_Size);
 Segment_Table_Volume:=Seg(Tables_Modm^);
 PSegment_Tampon1:=Segment_Table_Volume+(Volume_Table_Size) DIV 16;

 With MMSS_CFG^ do
  Begin
  If (4096-(PSegment_Tampon1 MOD 4096)) < (Max_Buffer_Samples_Nb) DIV 16 Then  { Max Buffers size}
      Begin
	   Buffer_Start_Offs:=(Volume_Table_Size)+Max_Buffer_Samples_Nb;   { Cross Boundary -> Use 2nd part         }
	   Left_Buffer_Offs:=(Volume_Table_Size)                   { First part for Stereo Mix Temp Buffer  }
      End
     Else 
	  Begin
	  Buffer_Start_Offs:=(Volume_Table_Size);                    { Ok             -> Use First part    }
	  Left_Buffer_Offs:=(Volume_Table_Size)+Max_Buffer_Samples_Nb;   { 2nd part for Stereo Mix Temp Buffer }
	  End;
  Right_Buffer_Offs:=Left_Buffer_Offs+(Max_Buffer_Samples_Nb DIV 2);
  Seg_Table_Volume:=Seg(Tables_Modm^)
  End;
  
{Writeln('Memoire Dispo :', MaxAvail);
Repeat until Readkey=#13;}
End; {Init_Tables_Modm}

{---------------------------------------------------------}

PROCEDURE Fin_Tables_Modm;
Begin
 If Tables_Modm<>NIL Then
    Begin
    FreeMem(Tables_Modm,VolumeMix_Table_Size);
    Tables_Modm:=NIL;
    End;
End; {Fin_Tables_Modm}

{---------------------------------------------------------}

PROCEDURE Calcul_Table_Volume(Precision:Boolean; Volume:Word); Assembler;
Var Coef: Word;
    Compt_Volume: Byte;
ASM
 PUSH DS

 MOV Compt_Volume,0
 MOV AX,Volume
 MOV Coef,AX
 MOV ES,Segment_table_volume
 XOR DI,DI              { ES:DI Volume Table }
{$IFDEF MIX16} 
 CMP Precision,0
 JNE @Table_16Bit
{$ENDIF} 
                        { * 8 bit Volume Table * }

@Boucle_table_volume:
 MOV BL,Compt_volume
 XOR BH,BH              { 0 to 40h * Volume }
 MOV AX,BX
 MUL Coef               { Max Coef Value : 1024    }
 MOV BX,AX              { BX=Volume*Volume Counter }
 XOR CX,CX
@Calcul_Table_vol:
 MOV AX,CX
 CBW                    { Convert the Signed Byte to Word   }
 IMUL BX                { DX-AX = Smp Value * Volume*Volume Counter }
 MOV AL,DL
 STOSB                   { Store DL }
 INC CL
 OR CL,CL
 JNE @Calcul_Table_vol  { 256 Loop              }
 INC Compt_volume
 CMP Compt_volume,41h
 JNE @Boucle_table_volume
{$IFDEF MIX16}
 JMP @Fin_Calcul_Table_Volume

@Table_16Bit:           { * 16 bit Volume Table * }
@Boucle_table_volume16:
 MOV BL,Compt_volume
 XOR BH,BH              { 0 to 40h * Volume }
 MOV AX,BX
 MUL Coef               { Max Coef Value : 1024    }
 MOV BX,AX              { BX=Volume*Volume Counter }
 XOR CX,CX
@Calcul_Table_vol16:
 MOV AX,CX
 CBW                    { Convert the Signed Byte to Word   }
 IMUL BX                { DX-AX = Smp Value * Volume*Volume Counter }
 MOV AL,AH
 MOV AH,DL
 STOSW                  { Store DL }
 INC CL
 OR CL,CL
 JNE @Calcul_Table_vol16 { 256 Loop              }
 INC Compt_volume
 CMP Compt_volume,41h
 JNE @Boucle_table_volume16
 
@Fin_Calcul_Table_Volume:
{$ENDIF}
 POP DS
End; {Calcul_Table_Volume}

{---------------------------------------------------------}

{$IFNDEF NoGUS}
PROCEDURE AjusterTableGUS(Volume:Word);
VAR Coef: Real;
    i   : Byte;
Begin
 If Volume>480 Then Volume:=480;
 If Volume>0 Then Coef:=Ln(Volume)/6.21461  { Ln(500) } Else Coef:=0;
  For i:=0 to 64 do MMSS_Table^.Volume_GUS[i]:=Round(Volume_GUS1[i]*Coef);
End; {AjusterTableGUS}
{$ENDIF}

{---------------------------------------------------------}

PROCEDURE MMSS_Adjust_Vol(Channels_Nb:Byte);  { Ajuster le volume selon le nombre de voies }
Var N_Chann: Byte;
Begin
If MMSS_CFG^.Output_Stopped Then
 Begin
 
 If MMSS_Volume<=5 then MMSS_Adj_Volume:=0 { Adjust the initial value }
    Else MMSS_Adj_Volume:=MMSS_Volume-5;  

{ Adjust for Stereo }
 With MMSS_CFG^ do
  Begin
   If Utilise_Stereo Then
    If Utilise_Mixage Then MMSS_Adj_Volume:=Round(MMSS_Adj_Volume*4/3)    { Volume*1.333.. }
                      Else MMSS_Adj_Volume:=Round(MMSS_Adj_Volume*11/8);  { Volume*1.375   }

{ Adjust for Channels Nb }
    N_Chann:=Channels_Nb; {Musique^.Ch_Number;}
    If N_Chann<4 Then N_Chann:=4
     Else
      If Wave_Output<>GUS Then N_Chann:=4+(N_Chann-4) DIV 3
                          Else {N_Chann:=4;} N_Chann:=4+(N_Chann-4) DIV 4;

    MMSS_Adj_Volume:=Round(MMSS_Adj_Volume*4/N_Chann);

{$IFNDEF NoGUS}
    If Wave_Output<>GUS Then Calcul_Table_Volume(MMSS_CFG^.Mix_16Bit,MMSS_Adj_Volume)
                          Else AjusterTableGUS(MMSS_Adj_Volume);
{$ELSE}  
    Calcul_Table_Volume(MMSS_CFG^.Mix_16Bit,MMSS_Adj_Volume);
{$ENDIF}
  End
 End;
End; {MMSS_Adjust_Vol}

{---------------------------------------------------------}

FUNCTION Get_MaxFreq(sortie,TypeSB: Byte; stereo,DC: Boolean): Word;
Begin
 Case sortie of
  {Adlib: FreqMax:=21000;}
  LPT1,LPT2,C_DAC:Get_MaxFreq:=44100;
  TDY_DAC:Get_MaxFreq:=48000;
  SB,SBPro : Get_MaxFreq:=SB_MaxFreq[TypeSB,Byte(Stereo)];
  Else Get_MaxFreq:=22100
 End
End; {Get_MaxFreq}

{---------------------------------------------------------}

PROCEDURE MMSS_PrevPattern;

Begin
If Not MMSS_CFG^.Musique_Term Then
   With  MMSS_Info^ do
   Begin
   If Pos_sequence>1 Then Dec(Pos_sequence);
   ModifierPattern:=True;
   Cmpt_tempo:=0;
   End;
End;

{---------------------------------------------------------}

PROCEDURE MMSS_NextPattern;

Begin
If Not MMSS_CFG^.Musique_Term Then
   With  MMSS_Info^ do
   If Pos_sequence<Musique^.Sequence_Len Then
      Begin
      Inc(Pos_sequence);
      ModifierPattern:=True;
      Cmpt_tempo:=0;
      End;
End;

{---------------------------------------------------------}

PROCEDURE MMSS_SetPattern(Numero:Byte);
Begin
If Not MMSS_CFG^.Musique_Term Then
   With  MMSS_Info^ do
   If (Numero<Musique^.Sequence_Len) And (Numero>0) Then
      Begin
      Pos_sequence:=Numero;
      ModifierPattern:=True;
      Cmpt_tempo:=0;
      End;
End;
END.