

Unit PlMidi;
{$UNDEF AFF}
{$DEFINE TIMER}

INTERFACE
Uses DOS,Crt,VarMidi,GMUnit;

Var Tempo:Longint;
    Valeur_Midi:Byte;
    Midi_Event:Byte;	
    P_Actuelle:Byte;
    OldTimer:Pointer;

Procedure Jouer_Midi;

IMPLEMENTATION

Var Commande_Midi:Byte;  { Derniäre valeur>128 envoyÇe vers la sortie Midi }

PROCEDURE ChangerPeriodeTimer(Periode_Timer:Word); ASSEMBLER;
ASM
  CLI
  MOV AX,Periode_Timer;
  PUSH AX
  MOV  AL,54       { Timer 0, accäs sÇquenciel, mode continu }
  OUT  43h,AL
  POP  AX
  OUT  40h,AL      { Partie basse de la freq                 }
  XCHG Ah,AL
  OUT  40h,AL      { Partie Haute de la Freq                 }
  STI
END;

{---------------------------------------------------------}

PROCEDURE ChangerFreqTimer(Frequence:Word);
Var Periode_Timer:Word;
Begin
{$IFDEF TIMER}
Periode_Timer:=Round(1193182/Frequence);
ChangerPeriodeTimer(Periode_Timer);
{$ENDIF}
End;

{---------------------------------------------------------}

PROCEDURE Envoyer(Val:Byte);
Begin
If Val>128 Then Commande_Midi:=Val;

MSend(Val);
{$IFDEF AFF}
Write(Val);
{$ENDIF}
End;

{---------------------------------------------------------}

PROCEDURE SysexMsg;  { Message Exclusif }
Var i,Taille:Byte;
Begin
{$IFDEF AFF}
Write('SysexMsg');
{$ENDIF}
Envoyer(Midi_Event);
Taille:=Lire_Midi;
For i:=1 to Taille do Envoyer(Lire_Midi);
End; {SysexMsg}

{---------------------------------------------------------}

PROCEDURE MetaEvent; { Evänements meta }
Var Long:Byte;
    i:Integer;
    Tem:Longint;
Begin
Valeur_Midi:=Lire_Midi;
Case Valeur_Midi Of
(*  1:Begin                     { Texte }
    {Write('Texte: ');  }
    Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        {Write(Chr(Valeur_Midi));}
        End;
    {Writeln; }
    End; *)
  {2:Begin                     { Copyright }
{	Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        Write(Chr(Valeur_Midi));
        End;
    Writeln;
    End;}
{  3:Begin                     { Titre }
 {   Write('Piste ',P_Actuelle,' : ');
    Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        Write(Chr(Valeur_Midi));
        End;
    Writeln;
    End;}
(*  4:Begin                     { Instrument }
    Write('Nom d''instrument: ');
    Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        Write(Chr(Valeur_Midi));
        End;
    Writeln;
    End;
   5:Begin                     { Texte }
    Write('Texte de la Chanson: ');
    Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        Write(Chr(Valeur_Midi));
        End;
    Writeln;
    End;
  6:Begin                     { Marqueur }
    Write('Texte Marqueur: ');
    Long:=Lire_Midi;
    For i:=1 to Long do
        Begin
        Valeur_Midi:=Lire_Midi;
        Write(Chr(Valeur_Midi));
        End;
    Writeln;
    End;
   7:Begin                     { Bruitage }
    Writeln('Evänement (Bruitage...)');
    Long:=Lire_Midi;
    For i:=1 to Long do Valeur_Midi:=Lire_Midi;
    End; *)
  $2F:Begin                   { Fin de piste }
      Valeur_Midi:=Lire_Midi;
      If Valeur_Midi=0 Then Piste[P_Actuelle].Terminee:=True;
      End;
  $51:Begin                   { Tempo }
      If Lire_Midi<>3 then Stopper_Midi:=True;
      Tem:=Lire_Midi;
      Tem:=Tem SHL 8 +Lire_Midi;
      Tem:=Tem SHL 8 +Lire_Midi;
	  
      Writeln('Tempo :',round(60000000/Tem));
      ChangerFreqTimer(Longint(MIDI.Division*1000000) DIV Tem);
      End;
(*  $54:Begin
      Long:=Lire_Midi;
      If Long=5 Then
         Begin
         Writeln('SMPTE');
         For i:=1 to 5 do Valeur_Midi:=Lire_Midi;
         End
         Else For i:=1 to Long do Valeur_Midi:=Lire_Midi;
      End;
   $58:Begin                   { Mesure }
      Long:=Lire_Midi;
      If Long=4 Then
         Begin
         Write('Mesure: ');
         Valeur_Midi:=Lire_Midi;
         Write(Valeur_Midi,'/');
         Valeur_Midi:=Lire_Midi;
         Tem:=1;
         For i:=1 to Valeur_Midi do Tem:=2*Tem;
         Write(Tem,' ');
         Valeur_Midi:=Lire_Midi;
         Write(Valeur_Midi,' impulsions dans un temps et ');
         Valeur_Midi:=Lire_Midi;
         Writeln(Valeur_Midi,' triples croches / noire');
         End
         Else For i:=1 to Long do Valeur_Midi:=Lire_Midi;
      End;
    $59:Begin                   { Key signature }
      Writeln('Key Signature');
      Long:=Lire_Midi;
      For i:=1 to Long do Valeur_Midi:=Lire_Midi;
      End; *)
  Else Begin
       Long:=Lire_Midi;
       {Write ('L',Long);}
	   Index_Midi:=Index_Midi+Long
       End;
  End;
End;

{---------------------------------------------------------}

PROCEDURE MidiMsg;
Var Channel:Byte;

Begin
Channel:=Midi_Event And $0F;

Case (Midi_Event And $F0) Of
     CNoteOff     :MNoteOff(Channel,Lire_Midi,Lire_Midi);
     CNoteOn      :MNoteOn(Channel,Lire_Midi,Lire_Midi);
     CKeyPressure :MKeyPressure(Channel,Lire_Midi,Lire_Midi);
     CControl     :MControl(Channel,Lire_Midi,Lire_Midi);
     CPGMChange   :MPGMChange(Channel,Lire_Midi);
     CAfterTouch  :MAfterTouch(Channel,Lire_Midi);
     CPitchBend   :MPitchBend(Channel,Lire_Midi,Lire_Midi);
     End;
End;

{---------------------------------------------------------}

PROCEDURE DoMidi;
Begin


End;

{---------------------------------------------------------}

PROCEDURE Arreter_Musique;
BEGIN
ChangerPeriodeTimer(0);
INLINE($FA);
SetIntVec(8,OldTimer);
INLINE($FB);
END;  {Arreter_Musique}


{---------------------------------------------------------}

PROCEDURE IRQ_Midi; Interrupt;
Var Delta:Longint;
Begin
Fin_Midi:=True;
Midi_Event:=0;
For P_Actuelle:=1 to MIDI.NbPistes do
    If Not Piste[P_Actuelle].Terminee Then
       Begin
       Fin_Midi:=False;   { Toujours des Çvänements => ne Pas Stopper }
       Dec(Piste[P_Actuelle].Compteur_Delta);
       PPiste:=Piste[P_Actuelle].Pointeur;
       If (Piste[P_Actuelle].Compteur_Delta=0) And (PPiste<>NIL) Then
          Begin        { Lecture de la piste }
          PPiste:=Piste[P_Actuelle].Pointeur;
          Index_Midi:=Piste[P_Actuelle].Current_Index;
          Midi_Event:=Piste[P_Actuelle].LastEvent;
          Delta:=0;

          {$IFDEF AFF}
          Writeln('Piste: ',P_Actuelle);
          {$ENDIF}

          While (Not Piste[P_Actuelle].Terminee) And (Delta=0) do
           Begin

           Valeur_Midi:=Lire_Midi;
		   If Valeur_Midi<$80 then Dec(Index_Midi)
		      Else Midi_Event:=Valeur_Midi;

            Case Midi_Event Of         { Type d'Çvänement ?   }
               $80..$EF : MidiMsg;       { - Message Midi       }
               $F0..$F7 : SysexMsg;      { - Message Exclusif   }
               $FF      : MetaEvent;     { - Evänement Meta     }
               Else
                Begin
                 { Error }
                 Writeln('Invalid Midi Event',Valeur_Midi);
                 Stopper_Midi:=True;
                End
              End;

           Delta:=Lire_Delta;

           {$IFDEF AFF}
           If Delta=0 Then Write(', ') Else Writeln(' Delta: ',Delta);
           {$ENDIF}

           End;
          Piste[P_Actuelle].LastEvent:=Midi_Event;
          Piste[P_Actuelle].Compteur_Delta:=Delta;
          Piste[P_Actuelle].Current_Index:=Index_Midi;
          End;
       End;
If Fin_Midi OR Stopper_Midi Then
   Begin
   Arreter_Musique;
   Fin_Midi:=True;
   End;
Port[$20]:=$20;
End;

{---------------------------------------------------------}

PROCEDURE Lancer_Musique(Vitesse:Word);
Begin
INLINE($FA);
GetIntVec(8,OldTimer);
SetIntVec(8,@IRQ_Midi);
INLINE($FB);
ChangerFreqTimer(Vitesse);
End; {Lancer_Musique}

{---------------------------------------------------------}

PROCEDURE Jouer_Midi;
Var Tempo:Longint;  { BPM }
    i:Longint;
    Delta:Longint;
    Touche:Char;

Begin
Tempo:=1;
For P_Actuelle:=1 to MIDI.NbPistes do
    Begin
    Index_Midi:=0;
    PPiste:=Piste[P_Actuelle].Pointeur;            { Pointeur de piste... }
    Delta:=Lire_Delta;                             { Lire le 1er Delta... }
    Piste[P_Actuelle].Compteur_Delta:=Delta+1;
    Piste[P_Actuelle].Current_Index:=Index_Midi;
    Piste[P_Actuelle].LastEvent:=0;
    Piste[P_Actuelle].Terminee:=False;
    End;
Fin_Midi:=False;

Lancer_Musique(MIDI.Division);
Repeat
If Keypressed Then Touche:=Readkey;
Until Fin_Midi Or (Touche=#27);

Stopper_Midi:=True;
Repeat until Fin_Midi;

End; {Jouer_Midi}

END.