{=======================================================================}
{º                         --==  PMUnit ==--                            }
{º                                                                      }
{º PicoMEM Board functions                                              }
{º                                                                      }
{-----------------------------------------------------------------------}
{º For 8088                                                             } 
{º                                                     By Freddy VETELE }
{=======================================================================}

UNIT PMUnit;

{$A+,G-,Q-,R-,S-}

INTERFACE

CONST

 PM_BasePort : Word = $220;

 PORT_PM_CMD_STATUS = 0;  { Write Command, Read Status            }
 PORT_PM_CMD_DATAL  = 1;
 PORT_PM_CMD_DATAH  = 2;	  
 PORT_PM_REG        = 3;  { Write/Read the register number        }
 PORT_PM_REG_DATA   = 4;  { Write/Read the selected Register Data }
 PORT_TEST          = 5;  { Test port                             }

 STAT_READY         = $00;
 STAT_CMDINPROGRESS = $01;
 STAT_CMDERROR      = $10;

 CMD_Reset        = $00;
 CMD_GetBasePort  = $01;
 CMD_SetBasePort  = $02;
 CMD_GetDEVType   = $03;
 CMD_SetDEVType   = $04;
 CMD_GetMEMType   = $05;
 CMD_SetMEMType   = $06;

 CMD_SetMEM       = $22;  { Set the First 64Kb of RAM to the SetRAMVal }
 CMD_TestMEM      = $23;
	  


{==========================================================}

PROCEDURE PM_Init;
FUNCTION  PM_IsAlive:BOOLEAN;
FUNCTION  PM_TestPort(PortNb:Word):Boolean;
FUNCTION  PM_ReadStatus: Byte;
FUNCTION  PM_TestReadPort(Count:WORD): BOOLEAN;

FUNCTION PM_SetMEM(Value : Byte) :BOOLEAN;

PROCEDURE PM_DisplayRAMMAP;

{==========================================================}

IMPLEMENTATION

USES UTIL;

{==========================================================}

procedure PM_Init;
begin

end; {InitTexte}

PROCEDURE PM_DisplayError(ErrorNb:Byte);
Begin
End;

PROCEDURE PM_CMD_WaitEnd;
Begin

repeat
until Port[PM_BasePort]<>STAT_CMDINPROGRESS;

End;

FUNCTION PM_ReadStatus: Byte;
Begin
PM_ReadStatus:=Port[PM_BasePort];
End;

{ Test the incrementing read counter "count" times }
FUNCTION PM_TestReadPort(Count:WORD): BOOLEAN; Assembler;
ASM
  MOV DX,PM_BasePort
  ADD DX,PORT_TEST
  MOV CX,Count
  IN AL,DX
  MOV AH,AL
@TestReadLoop:
  IN AL,DX
  INC AH
  CMP AL,AH
  JNE @TestRead_Fail
  LOOP @TestReadLoop
  MOV AX,1
  JMP @TestReadEnd
@TestRead_Fail:
  XOR AX,AX
@TestReadEnd:
END;

{==========================================================}

FUNCTION PM_IsAlive:BOOLEAN;
Begin
PM_IsAlive:= PM_TestReadPort(5);
End;

FUNCTION PM_TestPort(PortNb:Word):Boolean;
Var
 Result : Boolean;
Begin
Result:=True;
Port[PortNb]:=$AA;
If (Port[PortNb])<>$AA then Result:=False;
Port[PortNb]:=$AA;
If (Port[PortNb])<>$AA then Result:=False;
PM_TestPort:=Result;
End;

FUNCTION PM_SetMEM(Value : Byte) :BOOLEAN;
Begin
If PM_IsAlive then
   Begin
    Writeln('Alive : SetMEM');
    Port[PM_BasePort+PORT_PM_CMD_DATAH]:=0;      {0 RAM Low}
	Port[PM_BasePort+PORT_PM_CMD_DATAL]:=Value;
	Port[PM_BasePort]:=CMD_SetMEM;
	PM_CMD_WaitEnd;
    Writeln('SetMEM End');

	PM_SetMEM:=True
    end
    else PM_SetMEM:=False;
End;

PROCEDURE PM_DisplayRAMMAP;
Var
i,j : Byte;

Begin
For i:=0 to 15 do 
  Begin
   Port[PM_BasePort+PORT_PM_CMD_DATAL]:=i;
   Port[PM_BasePort]:=CMD_GetMEMType;
   PM_CMD_WaitEnd;
   if i=10 then Writeln('');
   Write(' ',EntierHexa(i,2),':');
   Case Port[PM_BasePort+PORT_PM_CMD_DATAH] of
     0 : Write('N/A');
     1 : Write('RAM');
     2 : Write('PSR');
     4 : Write('ROM');
     3 : Write('EMS');
   end;

  end;

end;


END.
