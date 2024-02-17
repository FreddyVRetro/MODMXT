{                                                                            }
{                   ---------------------------------------                  }
{                   Gravis Ultrasound driver - Version 2.11                  }
{                   ---------------------------------------                  }
{                                                                            }
{   Copyright <C> 1993,1994 Ingenuity Software                               }
{   Copyright <C> 1993,1994 Advanced Gravis                                  }
{                                                                            }
{   Modifi‚ par Freddy V‚tel‚                                                }
{                                                                            }

UNIT GUSUnit                                                                 ;

{$A+,Q-,R-,S-}

INTERFACE

CONST
  Volume_GUS1:Array[0..64] of Word=($0E00,$B000,$B800,$BC00,$BE00,$C000,$C400,$C800,$CC00,
                $D000,$D200,$D400,$D600,$D800,$DA00,$DC00,$DE00,
                $E000,$E100,$E200,$E300,$E400,$E500,$E600,$E700,
                $E800,$E900,$EA00,$EB00,$EC00,$ED00,$EE00,$EF00,
                $F080,$F100,$F180,$F200,$F280,$F300,$F380,$F400,
                $F480,$F500,$F580,$F600,$F680,$F700,$F780,$F800,
                $F880,$F900,$F980,$FA00,$FA80,$FB00,$FB80,$FC00,
                $FC80,$FD00,$FD80,$FE00,$FE80,$FF00,$FF80,$FFF0);

  Init_Voices = 14;    { # of voices to init the card for }

  { Volume Control bit Values (OR together TO form Volume control BYTE) }
  Loop_Volume           = 08;
  Bi_Directional_Volume = 16;
  Enable_Volume_Handler = 32;


  { Voice Control bit Values (OR together TO form Voice control BYTE) }
  Voice_Data_16Bit        = 04;
  Loop_Voice              = 08;
  Bi_Directional_Voice    = 16;
  Enable_VoiceEnd_Handler = 32;


  { DMA control bit values (OR together TO form DMA control BYTE) }
  DMA_Data_16Bit = 64;
  Convert_Data   = 128;


  { ULTRASND environment variable readable OR NOT }
  Ultra_Installed : BOOLEAN = FALSE;


VAR
  Ultra_Base_Port : WORD;  
  UltraOk         : BOOLEAN;
  UltraError      : INTEGER;
  GUS_LineIn      : BOOLEAN;

{ Base routines }

FUNCTION  UltraClose : BOOLEAN;
{PROCEDURE UltraDisableLineIn;
PROCEDURE UltraDisableMicIn;
PROCEDURE UltraDisableOutput;
PROCEDURE UltraEnableLineIn;
PROCEDURE UltraEnableMicIn;}
PROCEDURE UltraEnableOutput;
{FUNCTION  UltraGetLineIn : BOOLEAN;
FUNCTION  UltraGetMicIn : BOOLEAN;
FUNCTION  UltraGetOutput : BOOLEAN;}

PROCEDURE UltraMemInit;
PROCEDURE UltraMemClose;
FUNCTION  UltraMaxAvail : LONGINT;
FUNCTION  UltraMaxAlloc : LONGINT;
FUNCTION  UltraMemAvail : LONGINT;
FUNCTION  UltraMemAlloc(    Size     : LONGINT;
                        VAR Location : LONGINT) : BOOLEAN;
FUNCTION  UltraMemFree(Size     : LONGINT;
                       Location : LONGINT) : BOOLEAN;
					   
FUNCTION  UltraOpen(Voices : INTEGER) : BOOLEAN;
FUNCTION  UltraPeekData(Address : LONGINT) : BYTE;
FUNCTION  UltraPing      : BOOLEAN;
PROCEDURE UltraPokeData(Address : LONGINT;
                        Data    : BYTE);
FUNCTION  UltraProbe(BPort : WORD) : BOOLEAN;
FUNCTION UltraReset(Voices : INTEGER; iw:Boolean) : BOOLEAN;
{PROCEDURE UltraSetBalance(Voice : INTEGER;
                          Data  : BYTE);}
FUNCTION  UltraSizeDRAM : INTEGER;
FUNCTION  GUS_Detect(Affichage:Boolean):Boolean;           {*}

IMPLEMENTATION

USES
  DOS,CRT,VARUnit,Util;

CONST

  { Error codes }
  ULTRA_OK             = 1;
  BAD_NUM_OF_Voices    = 2;
  NO_MEMORY            = 3;
  CORRUPT_MEM          = 4;
  NO_Ultra             = 5;
  DMA_BUSY             = 6;
  BAD_DMA_ADDR         = 7;
  BAD_ENV_VAR          = 8;
  VOICE_NOT_VALID      = 9;
  NO_FREE_VOICES       = 10;
  VOICE_ALREADY_USED   = 11;
  FILE_NOT_FOUND       = 12;
  INSUFFICIENT_GUS_MEM = 13;
  NOT_BLOCK_DATA       = 18;
  NOT_INTERLEAVED_DATA = 19;

  JOYSTICK_TIMER  = $201;  (* 201 *)
  JOYSTICK_DATA   = $201;  (* 201 *)

  GF1_MIDI_CTRL   = $100;  (* 3X0 *)
  GF1_MIDI_DATA   = $101;  (* 3X1 *)

  GF1_PAGE        = $102;  (* 3X2 *) { Voice Select }
  GF1_REG_SELECT  = $103;  (* 3X3 *)
  GF1_DATA_LOW    = $104;  (* 3X4 *)
  GF1_DATA_HI     = $105;  (* 3X5 *)
  GF1_IRQ_STAT    = $006;  (* 2X6 *) { R, SB 2x6 W }
  GF1_DRAM        = $107;  (* 3X7 *)

  GF1_MIX_CTRL    = $000;  (* 2X0 *)
  GF1_TIMER_CTRL  = $008;  (* 2X8 *)
  GF1_TIMER_DATA  = $009;  (* 2X9 *)
  GF1_IRQ_CTRL    = $00B;  (* 2XB *)

  (* The GF1 Hardware clock. *)
  Clock_Rate      = 9878400;

  (* Mixer control bits. *)
  ENABLE_LINE		= $01;
  ENABLE_DAC		= $02;
  ENABLE_MIC		= $04;

  (* interrupt controller 1 *)
  CNTRL_8259		= $21;
  OCR_8259		= $20;
  EOI			= $20;
  REARM3		= $2F3;
  REARM5		= $2F5;

  (* interrupt controller 2 *)
  CNTRL_M_8259	    = $21;
  CNTRL_M2_8259	    = $A1;
  OCR_2_8259		= $A0;

  (* DMA *)
  DMA_CONTROL		= $41;
  SET_DMA_ADDRESS	= $42;
  SET_DRAM_LOW		= $43;
  SET_DRAM_HIGH		= $44;

  (* TIMER *)
  TIMER_CONTROL		= $45; {Adlib Sound Blaster Control}
  TIMER1		= $46;
  TIMER2		= $47;

  (* SAMPLING *)
  SET_SAMPLE_RATE	= $48;
  SAMPLE_CONTROL	= $49;

  (* MISC *)
  SET_JOYSTICK		= $4B;
  MASTER_RESET		= $4C;

  (* Voice register mapping. *)
  SET_CONTROL		= $00; {SACI}  {B}
  SET_FREQUENCY		= $01;         {W}
  SET_START_HIGH	= $02; {SASLI} {W}
  SET_START_LOW		= $03; {SASLI}
  SET_END_HIGH		= $04; {SAEHI}
  SET_END_LOW		= $05; {SAELI}
  SET_VOLUME_RATE	= $06;
  SET_VOLUME_START	= $07;
  SET_VOLUME_END	= $08;
  SET_VOLUME		= $09;
  SET_ACC_HIGH		= $0a; {SAHI}
  SET_ACC_LOW		= $0b; {SALI}
  SET_BALANCE		= $0c;
  SET_VOLUME_CONTROL = $0d;
  SET_VOICES		 = $0e;  {SAVI} {B}
  SET_UPPER_ADDR_IW  = 0;    {SUAI} {B}
  SET_FXADDR_HIGH_IW = $11;  {SEAHI} { Interwave Effect }
  SET_FXADDR_LOW_IW  = $12;  {SEAHI}
  SET_SYNTHMODE      = $15;  {SMSI}  { Interwave        }
  SET_IW_MODE        = $19;

  GET_CONTROL		= $80;
  GET_FREQUENCY		= $81;
  GET_START_HIGH	= $82;
  GET_START_LOW		= $83;
  GET_END_HIGH		= $84;
  GET_END_LOW		= $85;
  GET_VOLUME_RATE	= $86;
  GET_VOLUME_START	= $87;
  GET_VOLUME_END	= $88;
  GET_VOLUME		= $89;
  GET_ACC_HIGH		= $8a;
  GET_ACC_LOW		= $8b;
  GET_BALANCE		= $8c;
  GET_VOLUME_CONTROL 	= $8d;
  GET_VOICES		= $8e;
  GET_IRQV		    = $8f;
  GET_FXADDR_HIGH_IW = $91; {SEAHI} { Interwave Effect }
  GET_FXADDR_LOW_IW =  $92; {SEAHI}
  

  (* MIDI *)
  MIDI_RESET	    = $03;
  MIDI_ENABLE_XMIT	= $20;
  MIDI_ENABLE_RCV	= $80;
  MIDI_RCV_FULL		= $01;
  MIDI_XMIT_EMPTY	= $02;
  MIDI_FRAME_ERR	= $10;
  MIDI_OVERRUN		= $20;
  MIDI_IRQ_PEND		= $80;

  (* JOYSTICK *)
  JOY_POSITION		= $0f;
  JOY_BUTTONS		= $f0;

  (* GF1_IRQ_STATUS (PORT 3X6) *)
  MIDI_TX_IRQ		= $01;
  MIDI_RX_IRQ		= $02;
  GF1_TIMER1_IRQ	= $04;
  GF1_TIMER2_IRQ	= $08;
  WAVETABLE_IRQ		= $20;
  ENVELOPE_IRQ		= $40;
  DMA_TC_IRQ		= $80;

  (* GF1_MIX_CTRL (PORT 2X0) *)
  ENABLE_LINE_IN	= $01;
  ENABLE_OUTPUT		= $02;
  ENABLE_MIC_IN		= $04;
  ENABLE_GF1_IRQ	= $08;
  GF122			    = $10;
  ENABLE_MIDI_LOOP	= $20;
  SELECT_GF1_REG	= $40;

  (* DMA control register (41)*)
  DMA_ENABLE		= $01;
  DMA_READ		    = $02;
  DMA_WIDTH_16		= $04;
  DMA_RATE		    = $18;
  DMA_IRQ_ENABLE	= $20;
  DMA_IRQ_PENDING	= $40;
  DMA_DATA_16		= $40;
  DMA_TWOS_COMP		= $80;

  (* These are the xfer rate bits ... *)
  DMA_R0		= $00;
  DMA_R1		= $08;
  DMA_R2		= $10;
  DMA_R3		= $18;

  (* SAMPLE control register *)
  ENABLE_ADC		= $01;
  ADC_MODE		    = $02;
  ADC_DMA_WIDTH		= $04;
  ADC_IRQ_ENABLE	= $20;
  ADC_IRQ_PENDING	= $40;
  ADC_TWOS_COMP		= $80;

  (* RESET control register *)
  GF1_MASTER_RESET	= $01;
  GF1_OUTPUT_ENABLE	= $02;
  GF1_MASTER_IRQ	= $04;

  (* Voice specific registers *)
  VOICE_STOPPED		= $01;
  STOP_VOICE		= $02;
  VC_DATA_TYPE		= $04;
  VC_LOOP_ENABLE	= $08;
  VC_BI_LOOP		= $10;
  VC_WAVE_IRQ		= $20;
  VC_DIRECT		    = $40;
  VC_IRQ_PENDING	= $80;

  (* Volume specific registers *)
  VL_RATE_MANTISSA	= $3f;
  VL_RATE_RANGE		= $C0;
  VL_START_MANT	    = $0F;
  VL_START_EXP		= $F0;
  VL_END_MANT		= $0F;
  VL_END_EXP		= $F0;

  (* Volume control register *)
  VOLUME_STOPPED	= $01;
  STOP_VOLUME		= $02;
  VC_ROLLOVER       = $04;
  VL_LOOP_ENABLE	= $08;
  VL_BI_LOOP		= $10;
  VL_WAVE_IRQ		= $20;
  VL_DIRECT		    = $40;
  VL_IRQ_PENDING	= $80;

  (* Voice IRQ *)
  VOICE_VOLUME_IRQ	= $40;
  VOICE_WAVE_IRQ	= $80;

  (* Memory / Misc *)
  DMA_AUTO_INIT   = $01;
  DMA_16          = $40;
  DMA_8           = $00;
  DMA_CVT_2       = $80;
  DMA_NO_CVT      = $00;
  USE_ROLLOVER    = $01;

  ULTRA_PRESENT	  = $0001;
  DRAM_DMA_BUSY   = $0002;
  ADC_DMA_BUSY    = $0004;
  DRAM_DMA_NOWAIT = $0008;
  ADC_DMA_NOWAIT  = $0010;

  READ_DMA        = 1;
  WRITE_DMA       = 2;
  INDEF_READ      = 3;
  INDEF_WRITE     = 4;

  { For memory control scheme }
  MaxNumBanks = 4;
  BlockSizeK  = 256;
  OneK        = 1024;
  UMemInited  : BOOLEAN = FALSE;


TYPE
  ULTRA_DATA = RECORD
     Flags               : WORD;
     DRAM_DMA_Chan       : WORD;
     ADC_DMA_Chan        : WORD;
     GF1_IRQ_Num         : WORD;
     MIDI_IRQ_Num        : WORD;
     Mix_Image           : BYTE;
     Used_Voices         : LONGINT;
     Voice_Select        : INTEGER;
     Reg_Select          : INTEGER;
     Data_LOW            : INTEGER;
     Data_Hi             : INTEGER;
     IRQ_Status          : INTEGER;
     DRAM_Data           : INTEGER;
     Mix_Control         : INTEGER;
     {IRQ_Control         : INTEGER;}
    { Timer_Control       : INTEGER;}
     {Timer_Data          : INTEGER;}
     Ultra_ErrNo         : INTEGER;
     GF1_SEMA4           : INTEGER;
    { IRQ_Pending         : INTEGER;}
   END;

  { FOR new memory control scheme }
  PNode = ^Node;
  Node = RECORD
    StartLoc : LONGINT;
    EndLoc   : LONGINT;
    Prev,
    Next     : PNode;
   END;

  FreeList = RECORD
    BaseOffset : LONGINT;
    List       : PNode;
   END;


{ ---------------------------------------------------------- }


VAR
  GUSData   : ULTRA_DATA;
  UMemBlock : ARRAY[1..MaxNumBanks] OF FreeList;
  UMemStruc : LONGINT;
  SaveExit : POINTER;  { Old Exit Procedure address }

{ ---------------------------------------------------------- }

PROCEDURE ClearError;
  BEGIN
    UltraOk := TRUE;
    UltraError := ULTRA_OK;
  END;

PROCEDURE Default_Proc; FAR;
  BEGIN
    { Dummy PROCEDURE that does NOThing }
  END;

PROCEDURE Default_Int_Proc(V : INTEGER); FAR;
  BEGIN
    { Dummy PROCEDURE that does NOThing }
  END;

PROCEDURE Default_WORD_Proc(M : WORD); FAR;
  BEGIN
    { Dummy PROCEDURE that does NOThing }
  END;

PROCEDURE Default_TwoWord_Proc(MS : WORD; MD : WORD); FAR;
  BEGIN
    { Dummy PROCEDURE that does NOThing }
  END;

{ ---------------------------------------------------------- }

FUNCTION Make_MS_WORD(x : WORD) : LONGINT;
  BEGIN
    Make_MS_WORD := (LONGINT(X) SHL 16);
  END;

FUNCTION LSW(x : LONGINT) : WORD;
  BEGIN
    LSW := WORD(X);
  END;

FUNCTION MSW(x : LONGINT) : WORD;
  BEGIN
    MSW := WORD(X SHR 16);
  END;

FUNCTION MSB(x : WORD) : BYTE;
  BEGIN
    MSB := BYTE(X SHR 8);
  END;

FUNCTION LSB(x : WORD) : BYTE;
  BEGIN
    LSB := BYTE(x);
  END;

(* Make GF1 address FOR direct chip i/o. *)
FUNCTION Addr_HIGH(x : LONGINT) : WORD;
  BEGIN
    Addr_HIGH := WORD(LONGINT(X SHR LONGINT(7)) AND LONGINT($1FFF));
  END;

FUNCTION Addr_LOW(x : LONGINT) : WORD;
  BEGIN
    Addr_LOW := WORD(LONGINT(X AND LONGINT($7F)) SHL 9);
  END;

FUNCTION UltraPeekData(Address : LONGINT) : BYTE;
  BEGIN
    ASM
      PUSHF
      CLI
    END;
    PORT[Ultra_Base_Port+GF1_REG_Select] := SET_DRAM_LOW;   (* 16 bits *)
    PORTW[Ultra_Base_Port+GF1_DATA_LOW] := WORD(Address);
    PORT[Ultra_Base_Port+GF1_REG_Select] := SET_DRAM_HIGH;  (* 8 bits *)
    PORT[Ultra_Base_Port+GF1_DATA_HI] := BYTE(Address SHR 16);
    UltraPeekData := PORT[Ultra_Base_Port+GF1_DRAM];
    ASM
      POPF
    END;
    ClearError;
  END;


PROCEDURE UltraPokeData(Address : LONGINT;
                        Data    : BYTE);
  BEGIN
    PORT[Ultra_Base_Port+GF1_REG_Select] := SET_DRAM_LOW;   (* 16 bits *)
    PORTW[Ultra_Base_Port+GF1_DATA_LOW] := WORD(Address);
    PORT[Ultra_Base_Port+GF1_REG_Select] := SET_DRAM_HIGH;  (* 8 bits *)
    PORT[Ultra_Base_Port+GF1_DATA_HI] := BYTE(Address SHR 16);
    PORT[Ultra_Base_Port+GF1_DRAM] := Data;
    ClearError;
  END;


PROCEDURE GF1_Delay;
{ This FUNCTION is used as a 1.6*3 microsecond (OR longer) delay.
  This is needed when trying TO change any OF the 'self-modifying'
  bits in the voice registers. }
  VAR
    I : INTEGER;
    M : BYTE;
  BEGIN
    FOR I := 0 TO 6 DO
      M := PORT[GUSData.DRAM_data];
  END;


FUNCTION Make_Physical_Address(LOW  : WORD;
                               HIGH : WORD;
                               Mode : BYTE) : LONGINT;
{ This FUNCTION will convert the value read from the GF1 registers
  back TO a 'real' address. }
  VAR
    Lower_16,
    Upper_16 : WORD;
    Ret_Address,
    Bit_19_20 : LONGINT;
  BEGIN
    Upper_16 := HIGH SHR 9;
    Lower_16 := ((HIGH AND $01FF) SHL 7) OR ((LOW SHR 9) AND $007F);

    Ret_Address := Make_MS_WORD(Upper_16) OR LONGINT(Lower_16);

    IF (Mode AND VC_DATA_TYPE) <> 0 THEN
      BEGIN
        Bit_19_20 := Ret_Address AND $C0000;
        Ret_Address := Ret_Address SHL 1;
        Ret_Address := Ret_Address AND $3FFFF;
        Ret_Address := Ret_Address OR Bit_19_20;
      END;

    Make_Physical_Address := Ret_Address;
  END;

FUNCTION ParseToHex(VAR FromStr : STRING; VAR ToWord : WORD) : BOOLEAN;
  (* Take the first number found.  Disregard ',' AND ' ' chars *)
  BEGIN
    ParseToHex := FALSE;
    WHILE ((fromstr[1] = ' ') OR
           (fromstr[1] = ',') OR
           (fromstr[1] = '$')) AND
           (length(fromstr)<>0) DO
      delete(fromstr,1,1);
    IF (ord(fromstr[1]) > 47) AND
       (ord(fromstr[1]) < 58) AND
       (fromstr <> '') THEN
      BEGIN
        ParseToHex := TRUE;  (* a number was found *)
        ToWord := 0;
        WHILE (ord(fromstr[1]) > 47) AND
              (ord(fromstr[1]) < 58) AND
              (FromStr <> '') DO
          BEGIN
            ToWord := (ToWord * $10) + (Ord(FromStr[1]) - Ord('0'));
            delete(FromStr,1,1);
          END;
        ParseToHex := TRUE;
      END;
  END;

FUNCTION UltraGetCfg(VAR BPort:WORD) : BOOLEAN;
  VAR
    EnvStr : STRING;
  BEGIN
    UltraGetCfg := FALSE;
    UltraOk := FALSE;
    UltraError := BAD_ENV_VAR;
    EnvStr := GetEnv('ULTRASND');
    IF EnvStr <> '' THEN
      IF ParseToHex(EnvStr, BPort) THEN
        BEGIN
          UltraGetCfg := TRUE;
          ClearError;
        END;
  END;

{ Ultra_Base_Port need to be init First }
FUNCTION UltraPing : BOOLEAN;
  VAR
    Val0,
    Val1      : BYTE;
    Save_Val0 : BYTE;
    Save_Val1 : BYTE;
  BEGIN
    { Save Current Values }

    Save_Val0 := UltraPeekData(0);
    Save_Val1 := UltraPeekData(1);

    UltraPokeData(0, $AA);
    UltraPokeData(1, $55);

    Val0 := UltraPeekData(0);
    Val1 := UltraPeekData(1);

    { Restore data TO old values }
    UltraPokeData(0, Save_Val0);
    UltraPokeData(1, Save_Val1);

    IF (Val0 = $AA) AND
       (Val1 = $55) THEN
      BEGIN
        UltraPing := TRUE;
        ClearError;
      END
    ELSE
      BEGIN
        UltraPing := FALSE;
        UltraOk := FALSE;
        UltraError := No_Ultra;
      END;
  END;

FUNCTION UltraProbe(BPort : WORD) : BOOLEAN;
  BEGIN
    Ultra_Base_Port := BPort;
   { GUSData.MIDI_Data := Ultra_Base_Port + GF1_MIDI_Data;
    GUSData.MIDI_Control := Ultra_Base_Port + GF1_MIDI_CTRL;}
    GUSData.Voice_Select := Ultra_Base_Port + GF1_PAGE;
    GUSData.Reg_Select := Ultra_Base_Port + GF1_REG_SELECT;
    GUSData.Data_LOW := Ultra_Base_Port + GF1_Data_LOW;
    GUSData.Data_Hi := Ultra_Base_Port + GF1_Data_HI;
    GUSData.IRQ_Status := Ultra_Base_Port + GF1_IRQ_STAT;
    GUSData.DRAM_Data := Ultra_Base_Port + GF1_DRAM;
    GUSData.Mix_Control := Ultra_Base_Port + GF1_MIX_CTRL;

    { Pull a Reset }
    PORT[GUSData.Reg_Select] := MASTER_RESET;
    PORT[GUSData.Data_Hi] := $00;

    GF1_Delay;
    GF1_Delay;

    { Release the reset }
    PORT[GUSData.Reg_Select] := MASTER_RESET;
    PORT[GUSData.Data_Hi] := GF1_MASTER_RESET;

    GF1_Delay;
    GF1_Delay;

    UltraProbe := UltraPing; { Test Memory }
  END;



PROCEDURE UltraEnableOutput;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image AND (NOT ENABLE_OUTPUT);
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

{
FUNCTION UltraGetOutput : BOOLEAN;
  BEGIN
    UltraGetOutput := (GUSData.Mix_Image AND ENABLE_OUTPUT) = 0;
  END;

PROCEDURE UltraDisableOutput;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image OR ENABLE_OUTPUT;
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

FUNCTION UltraGetLineIn : BOOLEAN;
  BEGIN
       := (GUSData.Mix_Image AND ENABLE_LINE_IN) = 0;
  END;

PROCEDURE UltraEnableLineIn;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image AND (NOT ENABLE_LINE_IN);
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

PROCEDURE UltraDisableLineIn;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image OR ENABLE_LINE_IN;
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

FUNCTION UltraGetMicIn : BOOLEAN;
  BEGIN
    UltraGetMicIn := (GUSData.Mix_Image AND ENABLE_MIC_IN) <> 0;
  END;

PROCEDURE UltraEnableMicIn;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image OR ENABLE_MIC_IN;
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

PROCEDURE UltraDisableMicIn;
  BEGIN
    GUSData.Mix_Image := GUSData.Mix_Image AND (NOT ENABLE_MIC_IN);
    PORT[GUSData.Mix_Control] := GUSData.Mix_Image;
  END;

}
FUNCTION UltraReset(Voices : INTEGER; iw:Boolean) : BOOLEAN;
  VAR
    V         : BYTE;
    Select,
    Data_LOW,
    Data_Hi : INTEGER;
  BEGIN
{    IF (Voices < 14) OR (Voices > 32) THEN
      BEGIN
        UltraReset := FALSE;
        UltraOk := FALSE;
        UltraError := Bad_Num_OF_Voices;
        EXIT;
      END;}

    Select := GUSData.Reg_Select;
    Data_LOW := GUSData.Data_LOW;
    Data_Hi := GUSData.Data_Hi;

    { Set these TO zero so the they don't get summed in FOR voices that are
      NOT running. IF their volumes are NOT at zero, whatever value they
      are pointing at, will get summed into the output. By setting that
      location TO 0, that voice will have no contribution TO the output
      (2 locations are done in case voice is set TO 16 bits ... ) }
    UltraPokeData(0,0);
    UltraPokeData(1,0);

    ASM
      PUSHF
      CLI
    END;
    { Pull a register-level reset on the card. }
    PORT[Select] := MASTER_RESET;
    PORT[Data_Hi] := $00;              { 0 to RESET Port }
    FOR V := 0 TO 9 DO GF1_Delay;	
    PORT[Select] := MASTER_RESET;
    PORT[Data_Hi] := GF1_MASTER_RESET; { 1 to RESET Port }

    FOR V := 0 TO 9 DO GF1_Delay;

    If iw then   { Activate the Interwave Mode }
	   Begin
	    PORT[Select]:=SET_IW_MODE;
	    PORT[DATA_Hi]:=1;
		Voices:=32;
	   End;

    FOR V := 0 TO 9 DO GF1_Delay;


    { Clear all interrupts }
    PORT[Select] := DMA_Control;
    PORT[Data_Hi] := $00;
    PORT[Select] := TIMER_Control;
    PORT[Data_Hi] := $00;
    PORT[Select] := SAMPLE_Control;
    PORT[Data_Hi] := $00;

    { Set the number OF active voices }
    PORT[Select] := SET_VOICES;
    PORT[Data_Hi] := Lo((Voices-1) OR $C0);

    { Clear interrupts on voices }
    { Reading the status ports will clear the irqs }
    V := PORT[GUSData.IRQ_Status];
    PORT[Select] := DMA_Control;
    V := PORT[Data_Hi];
    PORT[Select] := SAMPLE_Control;
    V := PORT[Data_Hi];
    PORT[select] := GET_IRQV;
    V := PORT[Data_Hi];

    FOR V := 0 TO Voices-1 DO
      BEGIN
        { Select the proper voice }
        PORT[GUSData.Voice_Select] := V;

        If iw then   { Enable the channel }
          Begin
           PORT[Select]:=SET_SYNTHMODE;
           PORT[DATA_Hi]:=$20; { 20 for Advanced panning }
          End;

        { Stop the voice AND volume }
        PORT[Select] := SET_Control;
        PORT[Data_Hi] := (VOICE_STOPPED OR STOP_VOICE);
        PORT[Select] := SET_VOLUME_CONTROL;
        PORT[Data_Hi] := (VOLUME_STOPPED OR STOP_VOLUME);

        { Wait 4.8 Microseconds OR more }
        GF1_Delay;

        { Initialize each voice specific registers.  This is NOT really
          necessary, but is nice FOR completeness sake.  Each application
          will set up these TO whatever values it needs }
        PORT[Select] := SET_FREQUENCY;
        PORTW[Data_LOW] := $0400;

        PORT[Select] := SET_START_HIGH;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_START_LOW;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_END_HIGH;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_END_LOW;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_VOLUME_RATE;
        PORT[Data_HI] := $01;

        PORT[Select] := SET_VOLUME_START;
        PORT[Data_HI] := $10;

        PORT[Select] := SET_VOLUME_END;
        PORT[Data_HI] := $E0;

        PORT[Select] := SET_VOLUME;
        PORTW[Data_LOW] := $0000;

        PORT[Select] := SET_ACC_HIGH;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_ACC_LOW;
        PORTW[Data_LOW] := $0;

        PORT[Select] := SET_BALANCE;
        PORT[Data_Hi] := $07;

      END;

    V := PORT[GUSData.IRQ_STATUS];
    PORT[Select] := DMA_CONTROL;
    V := PORT[Data_Hi];
    PORT[Select] := SAMPLE_CONTROL;
    V := PORT[DATA_Hi];
    PORT[Select] := GET_IRQV;
    V := PORT[Data_Hi];

    { Enable DAC }
    PORT[Select] := MASTER_RESET;
    PORT[Data_Hi] := (GF1_MASTER_RESET OR GF1_OUTPUT_ENABLE );
    { Restore the IRQ state }
    ASM
      POPF
    END;

    UltraReset := TRUE;
    ClearError;
  END;



{ This FUNCTION returns the # OF K found on the card }
FUNCTION UltraSizeDRAM : INTEGER;
  VAR
    I,
    Loc       : LONGINT;
    Val,
    Save0,
    Save1     : BYTE;
    BreakOut  : BOOLEAN;
  BEGIN
    UltraSizeDRAM := 0;

    { Save First Location }
    Save0 := UltraPeekData(0);

    { See IF there is first block there ... }
    UltraPokeData(0, $AA);
    IF (UltraPeekData(0) <> $AA) THEN
        EXIT;

    BreakOut := FALSE;
    I := 0;
    WHILE (NOT BreakOut) AND
          (I < 2048) DO
      BEGIN
        I:=I+64; { Test all the 64Kb }
        { Check FOR mirroring }

        Loc := (LONGINT(I) SHL 10)-1;
            { Save Location so its a non-destructive sizing }
        Save1 := UltraPeekData(Loc);
        UltraPokeData(Loc, $AA);
        IF (UltraPeekData(Loc) <> $AA) THEN
             BreakOut := TRUE;
        UltraPokeData(Loc, $55);
        IF (UltraPeekData(Loc) <> $55) THEN
              BreakOut := TRUE;
        UltraPokeData(Loc, Save1);
      END;

    { Now restore location zero ... }
    UltraPokeData(0,Save0);

    UltraSizeDRAM := I-64;
  END;


{ ------------------------------------------------------------------------- }
{ This is the new memory control system by Kurt Kennett                     }
{ ------------------------------------------------------------------------- }

PROCEDURE UltraMemInit;
  VAR
    Runner : BYTE;
    Maker  : PNode;
  BEGIN
    {
    UMemStruc := SizeOf(UMemBlock);
    report heap space used only. }
    FillChar(UMemBlock, SizeOf(UMemBlock), 0);
    FOR Runner := 0 TO 3 DO
      WITH UMemBlock[Runner+1] DO
        BEGIN
          BaseOffset := Runner * (BlockSizeK*OneK);
          New(List);
          INC(UMemStruc, SizeOf(List^));
          FillChar(List^, SizeOf(List^), 0);
          List^.EndLoc := BlockSizeK*OneK-1;
          List^.Next   := NIL;
          List^.Prev   := NIL;
        END;
    UMemInited := TRUE;
  END;

PROCEDURE UltraMemClose;
  VAR
    Runner : BYTE;
    Killer,
    MList  : PNode;
  BEGIN
    FOR Runner := 1 TO 4 DO
      BEGIN
        MList := UMemBlock[Runner].List;
        WHILE MList <> NIL DO
          BEGIN
            Killer := MList;
            MList := MList^.Next;
            DEC(UMemStruc, SizeOf(Killer^));
            Dispose(Killer);
          END;
      END;
  END;

FUNCTION UltraMaxAvail : LONGINT;
  VAR
    Largest : LONGINT;
    MList   : PNode;
    Count   : BYTE;
  BEGIN
    Largest := 0;
    FOR Count := 1 TO 4 DO
      BEGIN
        MList := UMemBlock[Count].List;
        WHILE MList <> NIL DO
          BEGIN
            IF (MList^.EndLoc-MList^.StartLoc+1) > Largest THEN
              Largest := (MList^.EndLoc-MList^.StartLoc+1);
            MList := MList^.Next;
          END;
      END;
    UltraMaxAvail := Largest;
  END;

FUNCTION UltraMaxAlloc : LONGINT;
  BEGIN
    UltraMaxAlloc := UltraMaxAvail;
  END;

FUNCTION UltraMemAvail : LONGINT;
  VAR
    MemCount : LONGINT;
    MList    : PNode;
    Count    : BYTE;
  BEGIN
    MemCount := 0;
    FOR Count := 1 TO 4 DO
      BEGIN
        MList := UMemBlock[Count].List;
        WHILE MList <> NIL DO
          BEGIN
            INC(MemCount, (MList^.EndLoc-MList^.StartLoc+1));
            MList := MList^.Next;
          END;
      END;
    UltraMemAvail := MemCount;
  END;

FUNCTION UltraMemAlloc(    Size     : LONGINT;
                       VAR Location : LONGINT) : BOOLEAN;
  VAR
    BlockUse : BYTE;
    BlockEnd : LONGINT;
    MList    : PNode;
  BEGIN
    UltraMemAlloc := FALSE;
    IF NOT UMemInited THEN
      BEGIN
        { Memory structures NOT initialized }
        Location := -1;
        EXIT;
      END;
    IF (Size MOD 32) <> 0 THEN
      INC(Size, 32 - (Size MOD 32)); { bring size up TO a 32 BYTE boundary }
    IF Size > BlockSizeK*OneK THEN
      BEGIN
        { Size is bigger than allowed sample size }
        Location := -1;
        EXIT;
      END;
    BlockUse := 1;
    WHILE BlockUse <= MaxNumBanks DO
      BEGIN
        MList := UMemBlock[BlockUse].List;
        { Scan the list FOR a free space TO use }
        WHILE MList <> NIL DO
          BEGIN
            IF (MList^.EndLoc-MList^.StartLoc+1) >= Size THEN
              BEGIN
                { Set the END OF the block TO allocate }
                BlockEnd := MList^.StartLoc + Size - 1;

                { Prepare the location parameter WITH the actual address }
                Location := UMemBlock[BlockUse].BaseOffset + MList^.StartLoc;

                { Set the free block's new start position }
                MList^.StartLoc := BlockEnd+1;

                { EXIT WITH a TRUE result }
                UltraMemAlloc := TRUE;
                ClearError;
                EXIT;
              END;
            MList := MList^.Next;
          END;
        INC(BlockUse);
      END;

    { No memory left FOR block OF specified size }
    UltraOk := FALSE;
    UltraError := INSUFFICIENT_GUS_MEM;
  END;


FUNCTION UltraMemFree(    Size : LONGINT;
                      Location : LONGINT) : BOOLEAN;
  VAR
    BlockUse : BYTE;
    NextNext,
    MList,
    Temp     : PNode;
  BEGIN
    UltraMemFree := FALSE;
    IF NOT UMemInited THEN
      BEGIN
        { Memory structures NOT initialized }
        EXIT;
      END;
    IF (Size MOD 32) <> 0 THEN
      INC(Size, 32 - (Size MOD 32)); { bring size up TO a 32 BYTE boundary }
    IF Size > BlockSizeK*OneK THEN
      BEGIN
        { Size is bigger than allowed sample size }
        EXIT;
      END;

    { find appropriate block }
    BlockUse := BYTE((Location DIV (BlockSizeK*OneK))+1);

    { create a temporary block at the specified position }
    New(Temp);
    INC(UMemStruc, SizeOf(Temp^));
    FillChar(Temp^, SizeOf(Temp^), 0);
    Temp^.StartLoc := Location - UMemBlock[BlockUse].BaseOffset;
    Temp^.EndLoc := Temp^.StartLoc + Size - 1;

    { Insert it at the correct position in the list }
    MList := UMemBlock[BlockUse].List;
    WHILE (MList <> NIL) AND
          (MList^.StartLoc < Temp^.StartLoc) DO
      MList := MList^.Next;
    IF MList= NIL THEN
      BEGIN
        DEC(UMemStruc, SizeOf(Temp^));
        Dispose(Temp);
        { Inappropriate location passed TO freemem }
        EXIT;
      END;
    Temp^.Next := MList;
    Temp^.Prev := MList^.Prev;
    IF Temp^.Prev <> NIL THEN
      Temp^.Prev^.Next := Temp;
    MList^.Prev := Temp;
    IF Temp^.StartLoc < UMemBlock[BlockUse].List^.StartLoc THEN
      UMemBlock[BlockUse].List := Temp;

    { merge consecutive blocks }
    MList := UMemBlock[BlockUse].List;
    WHILE MList <> NIL DO
      BEGIN
        IF MList^.Next <> NIL THEN
          BEGIN
            IF (MList^.Next^.StartLoc-1) = MList^.EndLoc THEN
              BEGIN
                MList^.EndLoc := MList^.Next^.EndLoc;
                NextNext := MList^.Next^.Next;
                DEC(UMemStruc,SizeOf(MList^.Next^));
                Dispose(MList^.Next);
                MList^.Next := NextNext;
                IF NextNext <> NIL THEN
                  NextNext^.Prev := MList;
              END
            ELSE
              MList := MList^.Next;
          END
        ELSE
          MList := MList^.Next;
      END;

    UltraMemFree := TRUE;
  END;


FUNCTION UltraOpen(Voices : INTEGER) : BOOLEAN;
  VAR
    Temp : BOOLEAN;
  BEGIN
{    UltraDisableLineIn;
    UltraDisableMicIn;
    UltraDisableOutput; }

    Temp := UltraReset(Voices,FALSE);
    IF NOT Temp THEN
      BEGIN
        UltraOpen := FALSE;
        EXIT;
      END;

    UltraEnableOutput;

    UltraOpen := TRUE;
    ClearError;
  END;


FUNCTION UltraClose : BOOLEAN;
  BEGIN

    UltraReset(14,FALSE);

    UltraClose := TRUE;
    ClearError;
  END;


PROCEDURE Setup_GUSData;

  BEGIN
    FillChar(GUSData, SizeOf(GUSData), 0);
    WITH GUSData DO
      BEGIN
        Flags              := ULTRA_PRESENT;
        DRAM_DMA_Chan      := 1;
        ADC_DMA_Chan       := 1;
        GF1_IRQ_Num        := 11;
        MIDI_IRQ_Num       := 5;
        Mix_Image          := $08;
        Used_Voices        := 0;
      END;
  END;


{PROCEDURE UltraSetBalance(Voice : INTEGER;
                          Data  : BYTE);
  VAR
    Temp : BYTE;
  BEGIN
    Temp := Data AND $0F;

    ASM
      PUSHF
      CLI
    END;
    PORT[GUSData.Voice_Select] := Lo(Voice);
    PORT[GUSData.Reg_Select] := SET_BALANCE;
    PORT[GUSData.Data_Hi] := Temp;
    ASM
      POPF
    END;
  END;}

{ ------------------------------------------------------------------------- }

{ Exit Procedure }
PROCEDURE ShutDown; FAR;
  BEGIN
    ExitProc := SaveExit;    { restore old Exit Procedure }
    UltraClose;
  END;

{ ------------------------------------------------------------------------- }

Function GUS_Detect(Affichage:Boolean):Boolean;

Begin
GUS_Presente:=False;

UltraOk := FALSE;
Setup_GUSData;
{Writeln('UltraGetCfg(Ultra_Base_Port)');}
If UltraGetCfg(Ultra_Base_Port) Then { Lire la variable ULTRASND }
   Begin
    Ultra_Installed := TRUE;
    {Writeln('UltraProbe(Ultra_Base_Port) ',Ultra_Base_Port);}
   If UltraProbe(Ultra_Base_Port) Then
     Begin

      UltraOpen(32);

      SaveExit := ExitProc;
      ExitProc := @ShutDown;

      GUS_Presente:=True;
     If Affichage Then Writeln('Gravis UltraSound found at ',EntierHexa(Ultra_Base_Port,3),'h :-)');
     End;
   End;

GUS_Detect:=GUS_Presente;

End;

END.