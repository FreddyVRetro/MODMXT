UNIT VARMIDI;

INTERFACE

Const

       CNoteOff     =$80;
       CNoteOn      =$90;
       CKeyPressure =$A0;
       CControl     =$B0;
       CPGMChange   =$C0;
       CAfterTouch  =$D0;
       CPitchBend   =$E0;

       Midi_Charge:Boolean=False;

Type T_Table=Array[0..1000] of Byte;

     T_Piste=Record
             Pointeur:Pointer;
             Taille:Longint;         { Taille de la piste           }
             Offset:Longint;         { Offset de d‚part de la piste }
             Current_Index:Word;     { Offset Actuel                }
             Compteur_Delta:Longint;
             Terminee:Boolean;
             LastEvent:Byte;           { DerniŠre Commande...         }
             End;

     T_MIDI=Record
            Ident:Array[1..4] of Char;
            Taille:Longint;
            Format:Word;
            NbPistes:Word;
            Division:Integer;        { Attention si <0 !!!          }
            End;

Var
    MIDI:T_MIDI;             { En tˆte du fichier MIDI                   }

    PPiste      :^T_Table;  { Currently playing Track Pointer }
    Index_Midi  :Word;      { Currently playing Tack Index    }
    Tempo_Depart:Word;
    Tempo_Actuel:Word;       { Fr‚quence en Hz du timer                  }
    Taille_Midi :Longint;
    Piste:Array[1..128] of T_Piste;
    Stopper_Midi:Boolean;    { Mettre … vrai pour couper la musique Midi }
    Fin_Midi    :Boolean;    { Music finished if True                    }

{ Fonctions MIDI }

MNoteOff     : PROCEDURE(Channel,Note,Velocity:Byte);
MNoteOn      : PROCEDURE(Channel,Note,Volume:Byte);
MKeyPressure : PROCEDURE(Channel,Note,Pressure:Byte);
MControl     : PROCEDURE(Channel,Control,Value:Byte);
MPGMChange   : PROCEDURE(Channel,Prog:Byte);
MAfterTouch  : PROCEDURE(Channel,pressure:Byte);
MPitchBend   : PROCEDURE(Channel,MSB,LSB:Byte);

MLoadPatch   : FUNCTION(Instrument:Byte):Boolean;
MSend        : PROCEDURE(Valeur:Byte);
MStart       : PROCEDURE;
MStop        : PROCEDURE;

{----------------}

FUNCTION  Lire_Midi:Byte;
FUNCTION  Lire_Delta:Longint;
PROCEDURE Efface_Midi;

IMPLEMENTATION

{---------------------------------------------------------}

FUNCTION Lire_Midi:Byte;
Var Val:Byte;
Begin
{Val:=PPiste^[Index_Midi];
Inc(Index_Midi);
Lire_Midi:=Val;}
Lire_Midi:=PPiste^[Index_Midi];
Inc(Index_Midi);
End;

{---------------------------------------------------------}

Function Lire_Delta:Longint; { Lire le Delta Time }
Var Delta : Longint;
    Val   : Byte;
Begin
Delta:=Lire_Midi;
If (Delta And $80)=$80 then
   Begin
   Delta:=Delta And $7F;
    Repeat
     Val:=Lire_Midi;
     Delta:=(Delta Shl 7)+(Val And $7F)
    Until (Val And $80)<>$80;
   End;

Lire_Delta:=Delta;
End; { Lire_Delta }

{---------------------------------------------------------}

PROCEDURE Efface_Midi;   { Efface le fichier Midi de la m‚moire }
Var i:Byte;
Begin
For i:=1 to 128 do
    If Piste[i].Pointeur<>NIL Then Freemem(Piste[i].Pointeur,Piste[i].Taille);
End; {Efface_Midi}

PROCEDURE Init_Midi;
Var i:Byte;
Begin
For i:=1 to 128 do
    Begin
    Piste[i].Pointeur:=NIL;
    Piste[i].Taille:=0;
    End;
End; {Init_Midi}

BEGIN
Init_Midi;
END.