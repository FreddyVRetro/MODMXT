Unit CHMidi;
INTERFACE
Uses Fichiers,Util,VarMidi,Memoire;

TYPE String80=String[80];
     Char4=Array[1..4] of Char;

     T_Track=Record
            Ident : Array[1..4] of Char;
            Len   : Longint;
            End;

PROCEDURE Charge_Midi(chemin:String80;Var erreur: Word);

IMPLEMENTATION

PROCEDURE Charge_Midi(chemin:String80;Var erreur: Word);
VAR
    fMidi:Fichier;
    Taille_en_tete:Word;
    i:Byte;
    Track:T_Track;

Begin
 fMidi.Ouvre(lecture,chemin);
 Erreur:=0;

 If f_erreur=f_ok then
  Begin
  Taille_Midi:=fMidi.Taille;
  fMIDI.LitPos(0,MIDI,SizeOf(MIDI));
  If MIDI.Ident='MThd' Then
     Begin
     MIDI.Taille:=SwapLB(MIDI.Taille);
     MIDI.Format:=SWAP(MIDI.Format);
     MIDI.NBPistes:=SWAP(MIDI.NbPistes);
     MIDI.Division:=SWAP(MIDI.Division);
     Tempo_Depart:=0;

     fMIDI.PlacePointeur(MIDI.Taille+8);
     If (MIDI.Format<2) then
       Begin
        For i:=1 to MIDI.NbPistes do
          Begin
          fMIDI.Lit(Track,SizeOf(Track));
          Track.Len:=SwapLB(Track.Len);
          If (Track.Ident='MTrk') And (Track.Len<65535) Then
             Begin
              Getmem(Piste[i].Pointeur,Track.Len);
              Piste[i].Taille:=Track.Len;
              fMIDI.Lit(Piste[i].Pointeur^,Track.Len);
             End
             Else
             Begin
              Erreur:=4;
              Break;
             End;
          End;
       End
      Else Erreur:=5; { Incorrect Format }
     End
     Else Erreur:=2;
  End
  Else Erreur:=1;
If Erreur<>0 Then
   Begin
   Midi_Charge:=False;
   Efface_Midi;
   End
   Else Midi_Charge:=True;
End;

END.