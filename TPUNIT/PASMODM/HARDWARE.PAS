{ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป}
{บ                      --==๐๐ HARDWARE.PAS ๐๐==--                      บ}
{บ                                                                      บ}
{บ Unit pour la gestion matrielle (LPT).                              บ}
{บ                                                                      บ}
{บ AUTEUR: Freddy Vtel.                                               บ}
{วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ}
{บ Compatibilit: 8086          Dbut d'criture๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚05/11/95 บ}
{บ                              Dernires modifications๚๚๚๚๚๚๚๚05/11/95 บ}
{ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ}
UNIT Hardware;

INTERFACE
USES VarUnit,Util,BIOSEQU;

CONST Hardware_Init:Boolean=False;

      Port_LPT:Array[1..4] of WORD=(0,0,0,0);
      Port_COM:Array[1..4] of WORD=(0,0,0,0);

PROCEDURE Detecte_Hardware(affiche: Boolean);

IMPLEMENTATION

PROCEDURE Detecte_COM(affiche: Boolean);
Var COM_detecte:Boolean;
    i:Byte;
Begin
COM_Detecte:=False;
For i:=1 to 4 do
    Begin
    Port_COM[i]:=BiosSeg.ComBase[i];
    If (Port_COM[i]<>0) Then
       Begin
       COM_Present[i]:=True;
       COM_Detecte:=True;
       End;
    End;

If affiche and COM_Detecte Then
   Begin
    Write('Serial ports: ');
    If COM_Present[1] Then Write('COM1 at ',EntierHexa(Port_COM[1],4)+'h. ');
    If COM_Present[2] Then Write('COM2 at ',EntierHexa(Port_COM[2],4)+'h. ');
    If COM_Present[3] Then Write('COM3 at ',EntierHexa(Port_COM[3],4)+'h. ');
    If COM_Present[4] Then Write('COM4 at ',EntierHexa(Port_COM[4],4)+'h. ');
    Writeln
   End;
End;

PROCEDURE Detecte_LPT(affiche: Boolean);
Var LPT_detecte:Boolean;
    i:Byte;
Begin
LPT_Detecte:=False;
For i:=1 to 3 do
    Begin
    Port_LPT[i]:=BiosSeg.LptBase[i];
    If (Port_LPT[i]<>0) Then
       Begin
       LPT_Present[i]:=True;
       LPT_Detecte:=True;
       End;
    End;

If affiche and LPT_Detecte Then
   Begin
    Write('Parallel ports: ');
    If LPT_Present[1] Then Write('LPT1 at ',EntierHexa(Port_LPT[1],4)+'h. ');
    If LPT_Present[2] Then Write('LPT2 at ',EntierHexa(Port_LPT[2],4)+'h. ');
    If LPT_Present[3] Then Write('LPT3 at ',EntierHexa(Port_LPT[3],4)+'h. ');
    If LPT_Present[4] Then Write('LPT4 at ',EntierHexa(Port_LPT[4],4)+'h. ');
    Writeln
   End;
End;

PROCEDURE Detecte_Hardware(affiche: Boolean);
Begin
If Not Hardware_Init Then
   Begin
   Hardware_Init:=True;
   Detecte_COM(affiche);
   Detecte_LPT(affiche);
   End;
End; {Detecte_Hardware}

END.