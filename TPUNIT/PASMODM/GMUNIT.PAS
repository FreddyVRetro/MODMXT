UNIT GMUnit;

{
Public domain.  Do whatever you want with it.
Colin Buckley.
}

INTERFACE
{$F+}

Const
  GMPort        = $331;
  Send          = $80;
  Receive       = $40;

FUNCTION  GMDetecte:Boolean;
PROCEDURE GMActive;

IMPLEMENTATION
USES VarMidi;



{ AL:=Command; }
PROCEDURE WriteGMCommand; Assembler;
ASM
    MOV   DX,GMPort                   {;DX:=GMStatusPort;                 }
    PUSH  AX                          {;Save AX                           }
    XOR   AX,AX                       {;AH:=TimeOutValue;                 }
@@WaitLoop:
    { ;Prevent Infinite Loop with Timeout }
    DEC   AH                          {; |If TimeOutCount=0 then          }
    JZ    @@TimeOut                   {;/   TimeOut;                      }
    {; Wait until GM is ready }
    IN    AL,DX                       {; |If Not Ready then               }
    AND   AL,Receive                  {; |  WaitLoop;                     }
    JNZ   @@WaitLoop                  {;/                                 }
@@TimeOut:
    POP   AX                          {;Restore AX                        }

    OUT   DX,AL                       {;Send Data                         }
End;

{ ; AL:=Data }
PROCEDURE WriteGM; Assembler;
ASM
    MOV   DX,GMPort                   {;DX:=GMStatusPort;                 }
    PUSH  AX                          {;Save AX                           }
    XOR   AX,AX                       {;AH:=TimeOutValue;                 }
@@WaitLoop:
    { ; Prevent Infinite Loop with Timeout }
    DEC   AH                          {; |If TimeOutCount=0 then          }
    JZ    @@TimeOut                   {;/   TimeOut;                      }
    { ; Wait until GM is ready }
    IN    AL,DX                       {; |If Not Ready then               }
    AND   AL,Receive                  {; |  WaitLoop;                     }
    JNZ   @@WaitLoop                  {;/                                 }
@@TimeOut:
    POP   AX                          {;Restore AX                        }

    DEC   DX                          {;DX:=DataPort                     }
    OUT   DX,AL                       {;Send Data                        }
End;

{ ;Returns Data }
FUNCTION ReadGM:Byte; Assembler;
ASM
    MOV   DX,GMPort                   {;DX:=GMStatusPort;                 }
    PUSH  AX                          {;Save AX                           }
    XOR   AX,AX                       {;AH:=TimeOutValue;                 }
@@WaitLoop:
    { ; Prevent Infinite Loop with Timeout }
    DEC   AH                          {; |If TimeOutCount=0 then          }
    JZ    @@TimeOut                   {;/   TimeOut;                      }
    { ; Wait until GM is ready }
    IN    AL,DX                       {; |If Not Ready then               }
    AND   AL,Send                     {; |  WaitLoop;                     }
    JNZ   @@WaitLoop                  {;/                                 }
@@TimeOut:
    POP   AX                          {;Restore AX                        }

    DEC   DX                          {;DX:=DataPort                      }
    IN    AL,DX                       {;Receive Data                      }
End;

PROCEDURE ResetGM; Assembler;
ASM
    { ;Reset GM }
    MOV   DX,GMPort
    MOV   AL,0FFh
    OUT   DX,AL
    {; Get ACK }
    CALL  ReadGM
    {; UART Mode }
    MOV   AL,03Fh
    CALL  WriteGMCommand
End;

PROCEDURE GMSendMidi2(V1,V2:Byte); Assembler;
ASM
    MOV   AL,V1
    Call  WriteGM
    MOV   AL,V2
    Call  WriteGM
END;

PROCEDURE GMSendMidi3(V1,V2,V3:Byte); Assembler;
ASM
    MOV   AL,V1
    Call  WriteGM
    MOV   AL,V2
    Call  WriteGM
    MOV   AL,V3
    Call  WriteGM
END;

{----------------------------------------------------------}


{==========================================================}

PROCEDURE GMNoteOff(Channel,Note,Velocity:Byte);
Begin
GMSendMidi3(Channel+CNoteOff,Note,Velocity);
End; {NoteOff}

{----------------------------------------------------------}

PROCEDURE GMNoteOn(Channel,Note,Volume:Byte);
Begin
GMSendMidi3(Channel+CNoteOn,Note,Volume);
End;

{----------------------------------------------------------}

PROCEDURE GMKeyPressure(Channel,Note,Pressure:Byte);
Begin
GMSendMidi3(Channel+CKeyPressure,Note,Pressure);
End;

{----------------------------------------------------------}

PROCEDURE GMControl(Channel,Control,Value:Byte);
Begin
GMSendMidi3(Channel+CControl,Control,Value);
End;

{----------------------------------------------------------}

PROCEDURE GMPGMChange(Channel,Prog:Byte);
Begin
GMSendMidi2(Channel+CPGMChange,Prog);
End;

{----------------------------------------------------------}

PROCEDURE GMAfterTouch(Channel,pressure:Byte);
Begin
GMSendMidi2(Channel+CAfterTouch,pressure);
End;

{----------------------------------------------------------}

PROCEDURE GMPitchBend(Channel,MSB,LSB:Byte);
Begin
GMSendMidi3(Channel+CPitchBend,MSB,LSB);
End; {PitchBend}

{----------------------------------------------------------}

FUNCTION GMLoadPatch(Instrument:Byte):Boolean;
Begin
GMLoadPatch:=True;
End; {LoadPatch}

{----------------------------------------------------------}

PROCEDURE GMSendMidi(Valeur:Byte); Assembler;
ASM
    MOV   AL,Valeur
    Call  WriteGM
END;

PROCEDURE GMStartMidi;
Begin
ResetGM;
End; {StartMidi}

{----------------------------------------------------------}

PROCEDURE GMStopMidi;
Begin
ResetGM;
End; {StopMidi}

{----------------------------------------------------------}

FUNCTION  GMDetecte:Boolean;
Begin
GMDetecte:=True;
End; {GMDetecte}

{----------------------------------------------------------}

PROCEDURE GMActive;
Begin
MNoteOff     := GMNoteOff;
MNoteOn      := GMNoteOn;
MKeyPressure := GMKeyPressure;
MControl     := GMControl;
MPGMChange   := GMPGMChange;
MAfterTouch  := GMAfterTouch;
MPitchBend   := GMPitchbend;
MLoadPatch   := GMLoadPatch;
MSend        := GMSendMidi;
MStart       := GMStartMidi;
MStop        := GMStopMidi;
End;

End.