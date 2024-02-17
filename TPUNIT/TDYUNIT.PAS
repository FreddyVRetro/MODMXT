{************************************************************************}
{                               TDYUNIT.PAS                              }
{                                                                        }
{  Tandy SN76496 and DAC Code, Detection and Init                        }
{                                                                        }
{  AUTEURS: Freddy Vételé                                                }
{                                                                        }
{                               Code Start 6/06/20                       }
{************************************************************************}
UNIT TDYUNIT;
{$A+,Q-,G-,R-,S-}

INTERFACE

CONST

 { Offset des Ports I/O}
  TDY_Port_Mode1 = 0;      { Tandy DAC Mode 1             Write Only }
  TDY_Port_Mode2 = 1;      { Tandy DAC Mode 1             Write Only }
  TDY_Port_FreqL = 2;      { Frequency Low                Read/Write }
  TDY_Port_FreqV = 3;      { Frequency High + Volume      Read/Write }

{ 

Port 0C0h (1E0h, 300h)          SN76496 3-voice tone and noise generator
Write only

  Bits
  7 6 5 4 3 2 1 0       Function
  ---------------       --------
  1 x x 0 y y y y       Set tone frequency, channel xx (0-2).  yyyy = low 4
                          bits of divider.
  0 w z z z z z z       (following the above) zzzzzz = high 6 bits of divider.
                          If extra divide enabled (port 0C4h bit 6), w = high
                          (11th) bit of divider (otherwise, w is a "don't
                          care" bit).
  1 x x 1 y y y y       Set tone attenuation, channel xx (0-2).  yyyy =
                          attenuation (1's complement of volume).  Attenuation
                          1111b = no sound.  Approximately 2 dB per level.
						  10^0.2=1.58489319... (16 Levels)
  1 1 1 0 x y z z       Set noise type/frequency.  x is a "don't care" bit.
                          y = periodic/white noise code:  0 = periodic noise,
                          1 = white noise.  zz = frequency:  0 = N/512, 1 =
                          N/1024, 2 = N/2048, 3 = Tone 3, where N = 3579545.
                          0 is highest noise frequency (see below).
  1 1 1 1 y y y y       Set noise attenuation.  Attenuation 1111b = no sound.
  
  A = 10*log10(P2/P1)     (dB)
  
  
On older Tandy 1000's and on the IBM PCjr, bits 5 and 6 at port 61h must be 
set to enable the 3-voice chip (bit 6 enables the keyboard and must always
be high).  Bit 0 at this port should be low (this disables timer channel 2 
output to the speaker).  These bits can be set/cleared by calling Int 1Ah, 
AX=8003h (see above).  Do not change the other bits; on the 1000TL, setting 
bit 4 disables the speaker.  It is not necessary to program port 61h on 
newer systems with the DAC.  

 Tandy 1000 RL +
  00C4 - 00C7      DAC Function
    C4             DAC Mode Register  (Write commands)
                   Bit 0    Bit 1
                    0        0        Joystick
                    0        1        Successive Approximation
                    1        0        Sound Channel
                    1        1        Direct Write to DAC

                   Bit 2    DMA Enabled
                   Bit 3    DMA Interrupt Clear
                   Bit 4    DMA Interrupt Enable
                   Bit 5    Sound Divider Sync Enable
                   Bit 6    Sound Chip Extra Divide Enable
                   Bit 7    Reserved

    C4             DAC Mode Register  (Read commands)
                   Bit 3    DMA Interrupt flag
                   Bit 7    Successive Approximation Done

    C5             Waveshape Model Select  (Write commands)
                   Bit 0    Bit 1     Bit 2
                    0        0         0        6.25%
                    0        0         1       12.50%
                    0        1         0       18.75%
                    0        1         1       25.00%
                    1        0         0       31.25%
                    1        0         1       37.50%
                    1        1         0       43.75%
                    1        1         1       50.00%

                   Bit 7    Bit 6     Waveshape Selected
                    0        0          Pulse
                    0        1          Ramp
                    1        0          Triangle

    C5            Read DAC Registers  (Read commands)
                  Direct Read of DAC when 00C4 Bits 0-1 = 1X
                  Direct Read of Control Register when 00C4 Bits
                  0-1 = 01

    C6            R/W Frequency LSB for DAC sound channel
                  Bit 0     F0
                  Bit 1     F1
                  Bit 2     F2
                  Bit 3     F3
                  Bit 4     F4
                  Bit 5     F5
                  Bit 6     F6
                  Bit 7     F7

    C7            R/W Amplitude/frequency MSB for DAC sound channel
                  Bit 0     F8
                  Bit 1     F9
                  Bit 2     F10
                  Bit 3     F11
                  Bit 4     Reserved
                  Bit 5     Amp 1
                  Bit 6     Amp 2
                  Bit 7     Amp 3

    Software Interrupt 1AH

    AH = 81H:  Get Sound Status
    AH = 82H:  Input Sound   (from the microphone)
    AH = 83H:  Output Sound  (to the speaker)
    AH = 84H:  Stop Sound Input and Output    }

TDY_PortTotal = 5;
TDY_PortList : Array[0..5] of Word = (0,$00C0,$01E0,$2C0,$205,$300); { 205 PCJr }

VAR

 TDY_Type    : Byte; { 0 : Nothing 1 : SNxxx 2: SNxxx LPT 3: Emulated}
 TDY_DACPort : WORD; { 0 Not present otherwise, Port }
 TDY_Port    : WORD; { 0 Not present otherwise, Port }
 TDY_PortNb  : Byte; { Port Nb in the list }
 TDY_LPT_Nb  : Byte; { 0 No, 1 LPT1 2 LPT2 }

PROCEDURE TDY_DetectDAC;
PROCEDURE TDY_InitDAC;    { Initialize the DAC in direct I/O Mode          }
PROCEDURE TDY_DetectOld;  { Detect an and Init an Old Tandy 1000 (SN76489) }

IMPLEMENTATION

{ 1 If BIOS Detected, 2 if BIOS and Port detected }

PROCEDURE TDY_DetectDAC; Assembler;
Asm

    XOR CX,CX
	MOV TDY_Port,CX
	MOV TDY_DACPort,CX
  {  MOV AX,8003h }
  {  INT 1Ah }
  {  CMP CX,5353h }
  { JE @DACDETECT_NODAC  } {Skip detecting the DAC if PCMCIA present}

    MOV AX,8100h
    INT 1Ah               {Detect the Tandy DAC BIOS          }
    CMP AX,00C4h          {Check one of the 3 possible ports  }
    JE  @DACDETECT_OK
    CMP AX,1E4h
    JE  @DACDETECT_OK
    CMP AX,304h
    JE @DACDETECT_OK
	JMP @DACDETECT_NODAC

@DACDETECT_OK:
    MOV TDY_DACPort,AX     { Save Tandy DAC Port }
    SUB AX,4
	MOV TDY_Port,AX	       { Save Tandy Port     }

{	MOV DX,TDY_DACPort}
{	ADD DX,2   }           { Frequency Low Reg (Is R/W)}
{	IN AL,DX}
{	MOV CL,AL      }       { Save de Port Value  }
{	XOR AX,AX     }        { Write 0 to the Port }
{	OUT DX,AL}
{	IN AL,DX}
{	OR AL,AL   }           { Read and Compare    }
{	JNZ @DACDETECT_NOPort}

{	NOT AX  }              { Write 0FFh to the Port }
{	OUT DX,AX}
{	IN AX,DX}
{	NOT AX}
{	JNZ @DACDETECT_NOPort}

{	MOV AL,CL     }         { Restore the Value }
{	OUT DX,AL}

	MOV TDY_Type,1         { Found -> 1 }
	JMP @DACDETECT_End
{ @DACDETECT_NOPort:}
{	MOV AL,CL  }            { Restore the Value }
{	OUT DX,AL}
{	MOV TDY_Type,1   }      { Only IRQ Found : 1  (DOSBOX With SB Activated) }
{	JMP @DACDETECT_End}
@DACDETECT_NODAC:
    MOV TDY_Type,0         { Not Found -> 0 }
@DACDETECT_End:
End; {TDY_DetectDAC}

{=========================================================}

PROCEDURE TDY_InitDAC; { Initialize the DAC in direct I/O Mode }
Begin

{
;
; Routine to set the DAC for direct mode.
;
DIRECTSET:
	PUSH	AX
	PUSH	DX
	MOV	DX,PORTBASE
	CLI
	IN	AL,DX	; set base port (DAC Control Register)
	JMP	$+2     ; Delay
	AND	AL,0E3h
	OR	AL,3
	OUT	DX,AL
	JMP	$+2
	INC	DX		; set volume at (base+2), (base+3)
	INC	DX
	MOV	AL,0
	OUT	DX,AL
	JMP	$+2
	INC	DX
	MOV	AL,0E0h
	OUT	DX,AL
	JMP	$+2
	STI
	POP	DX
	POP	AX
	RET
	}

End;

PROCEDURE TDY_DetectOld; Assembler; {  Detect a Tandy 1000 or PC Junior With Default base @ }
Asm
	MOV	AX,0FFFFh
	MOV	ES,AX
	CMP	BYTE PTR ES:[0Eh],0FDh	
	JE  @@TDY_Ok               { PC Junior Detected }
	CMP	BYTE PTR ES:[0Eh],0FFh
	JNE	@@TDY_Ko
	MOV	AX,0FC00h
	MOV	ES,AX
	CMP	BYTE PTR ES:[0],21h
	JNE	@@TDY_Ko

@@TDY_Ok:          {61h : MC14529b sound multiplexor chip in the PCjr}

	CLI            { Init                   }
	IN	AL,61h     { get byte from port 61h }
	OR	AL,60h	   { set bits 5 and 6       }
	AND	AL,0FEh	   { clear bit 0            }
	OUT	61h,AL	   { write back to enable sound chip }
	STI
	
	MOV TDY_Type,1
	MOV	TDY_Port,0C0h

@@TDY_Ko:
    XOR AX,AX
@@TDY_End:
End; {TDY_DetectOld}

END.
