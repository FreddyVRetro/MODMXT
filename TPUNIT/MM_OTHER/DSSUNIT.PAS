{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                       --==ðð DSSUnit.PAS ðð==--                      º}
{º                                                                      º}
{º Unite pour la gestion de la Disney SS.                               º}
{º                                                                      º}
{º AUTEUR: Freddy Vetele.                                               º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilite: 8086          Debut d'ecriture               05/11/95 º}
{º                              DerniŠres modification         05/11/95 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}
UNIT DSSUnit;

{$G-}

INTERFACE

USES VarUnit,Hardware;

Const SSOn=$04;
      SSOff=$0C;

TYPE T_DSSConfig=Record
               DataP:Word;
               StatusP:Word;
               ControlP:Word;
               End;

VAR DSSConfig:T_DSSConfig;

PROCEDURE Detecte_DSS(affiche: Boolean);

IMPLEMENTATION

PROCEDURE DSSOn;
Begin
Port[DSSConfig.DataP]:=SSOn;  { Disney sound source On  }
End;

PROCEDURE DSSOff;
Begin
Port[DSSConfig.DataP]:=SSOff;  { Disney sound source Off }
End;

PROCEDURE DSS_Ecrire(Valeur:Byte); Assembler;
ASM
  MOV DX,DSSConfig.DataP    { Envoyer la valeur           }
  MOV AL,Valeur
  OUT DX,AL

  MOV DX,DSSConfig.ControlP { Envoyer Printer Select      }
  MOV AL,SSOff
  OUT DX,AX
  PUSH AX
  POP AX
  MOV AL,SSOn
  OUT DX,AL
                            { Attendre                    }
  PUSH AX
  POP AX
  PUSH AX
  POP AX
END;


FUNCTION DSS_FIFO_Vide:Boolean; Assembler;
ASM
  MOV DX,DSSConfig.StatusP
  IN AL,DX
  TEST AL,40h
  JZ @Ok
  MOV AX,0          { FIFO pleine }
  JMP @Fin
@Ok:
  MOV AX,1          { FIFO vide   }
@Fin:
END;

PROCEDURE Detecte_DSS(affiche: Boolean);
Var i:Byte;
    DSS_Detectee:Boolean;

Begin
Detecte_Hardware(Affiche);  { Detecte les ports paralleles }
DSS_Detectee:=False;

For i:=1 to 3 do
 If LPT_Present[i] Then
    With DSSConfig do
    Begin
    DataP:=Port_LPT[i];
    StatusP:=Port_LPT[i]+1;
    ControlP:=Port_LPT[i]+2;
    DSSOn;
    If DSS_FIFO_Vide Then                           { FIFO vide => Continuer }
       Begin
       For i:=1 to 32 do DSS_Ecrire($80);           { Remplire la FIFO       }
       If Not DSS_FIFO_Vide Then DSS_Detectee:=True;{ FIFO non vide => Ok    }
       End;

    If DSS_Detectee Then
       Begin
       DSS_Presente:=True;
       Writeln('Disney Sound Source found.');
       Break;
       End;
    End;
End;

End.