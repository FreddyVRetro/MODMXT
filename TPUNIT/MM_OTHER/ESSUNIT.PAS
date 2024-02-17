{************************************************************************}
{                               ESSUNIT.PAS                              }
{                                                                        }
{  ESS Audio Drive                                                       }
{                                                                        }
{  AUTEURS: Freddy Vételé                                                }
{                                                                        }
{                               Write Start 10/02/20                     }
{                               Last Update 23/04/20                     }
{************************************************************************}
UNIT ESSUNIT;
{$A+,Q-,G-,R-,S-}

INTERFACE

CONST

VAR

FUNCTION ESS_InitPort(BasePort:Word):Boolean; { Initialize the DAC in direct I/O Mode }


IMPLEMENTATION

{=========================================================}

FUNCTION ESS_InitPort(BasePort:Word):Boolean; { Initialize the DAC in direct I/O Mode }
Begin
{ ESS I/O Port Init Sequence}
ASM
  MOV DX,22Bh
  IN AL,DX
  MOV DX,229h
  IN AL,DX
  MOV DX,22Fh
  IN AL,DX
  MOV DX,22Dh
  IN AL,DX
  MOV DX,22Dh
  IN AL,DX
  MOV DX,22Fh
  IN AL,DX
  MOV DX,229h
  IN AL,DX
  MOV DX,BasePort  {I/O Base Port     }
  IN AL,DX
  MOV DX,0h
  IN AL,DX         { No Joystick Port }
  MOV DX,388h      { FM BAse Port     }
  IN AL,DX
End;

END.
