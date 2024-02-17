{************************************************************************}
{                               MM_INIT.PAS                              }
{                                                                        }
{  Initialisation de Mod Master                                          }
{                                                                        }
{  AUTEURS: Freddy V‚tel‚ et Fabrice Couteau.                            }
{                                                                        }
{                               D‚but d'‚criture le 27/03/95             }
{                               DerniŠres modifications le 01/11/95      }
{************************************************************************}

UNIT MM_Init;

{$A+,G-,Q-,R-,S-}

{$DEFINE ModeXT}
{$DEFINE CGAOnly}

INTERFACE

IMPLEMENTATION

USES Memoire,SBUnit,Util,Texte,Souris,MM_VAR,MMSS_VAR;

CONST MemoireMinimale=65000;

FUNCTION Modm: Boolean; Assembler;
{renvoie TRUE si Mod Master est actif (shell...)}
ASM
 MOV AX,60FFh
 XOR DL,DL
 MOV BX,5344h   { SD }
 MOV CX,4D50h   { MP }
 INT 2Fh        { Multiplex }
 CMP AX,1234h
 MOV AL,True
 JE @fin
 MOV AL,False
@fin:
End; {Modm}

{CONST CPU_Name: Array[_386..Pentium] of String[7]=('386','486','Pentium');
VAR   CPU: Byte;}

{ ** Initialistion de l'unite ** }
BEGIN
{$IFDEF MODMTINY}
 Writeln('Initializing '+Ident_Modm+'(Tiny : MMM Only)'+#13#10);
{$ELSE}
{$IFDEF MODMLITE}
 Writeln('Initializing '+Ident_Modm+'(Light : MMM, MOD, S3M, XM Only)'+#13#10);
{$ELSE}
 Writeln('Initializing '+Ident_Modm+'(Full)'+#13#10);
{$ENDIF}
{$ENDIF}

{ If Modm Then
  Begin
   WriteLn('Can''t re-run Mod Master when in its DOS shell!'); Halt(1)
  End; }

 MM_Hercule:=False;
 If Detect_Mono then
    Begin
     Writeln('Monochrome Display');
     MM_Hercule:=True;
     SetHerculeAddr;
    End;

 If MaxAvail<MemoireMinimale Then
  Begin
   WriteLn('Not enough memory to run Mod Master.'); Halt(1)
  End;

 {*******}

 If InitSouris Then Writeln('Mouse found');

END.