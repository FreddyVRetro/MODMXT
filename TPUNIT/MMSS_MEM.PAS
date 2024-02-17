{************************************************************************}
{                               MEMUNIT.PAS                              }
{                                                                        }
{  Unit‚ pour la gestion de la m‚moire (DOS,UMB et EMS) pour Mod Master  }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{                                                                        }
{                               DerniŠres modifications le 14/09/95      }
{************************************************************************}

UNIT MMSS_MEM; {unit‚ pour la gestion de la m‚moire (DOS,UMB et EMS)}

{$A+,Q-,R-,S-}

INTERFACE
Uses DOS,CRT,VarUnit,MMSS_Var,Memoire,Util;

VAR Nb_Pages_EMS_Actuel:Word;
    Handle_EMS_Actuel:Word;

{---------------------------------------------------------}

FUNCTION  MMSS_MemAlloc(VAR Pointeur:Pointer;Taille:WORD;UseUMB,
                              UseEMS:Boolean):Boolean;

PROCEDURE Affiche_Mem;

PROCEDURE MMSS_FreeMemory;

IMPLEMENTATION

{---------------------------------------------------------}

Function MMSS_EMSMemAlloc(Var Pointeur:Pointer;Taille:WORD):Boolean;
Var i:Integer;
    Resultat:Boolean;
Begin
Resultat:=False;
Pointeur:=NIL;
IF (Nb_Pages_EMS<=Nb_Pages_EMS_Libres) AND (Nb_Handle_EMS<=Max_Handle_EMS) Then
   Begin
   Nb_Pages_EMS_Actuel:=(Taille DIV 1024)+1;
   Handle_EMS_Actuel:=ReserveEMS(Nb_Pages_EMS_Actuel);

   If Handle_EMS_Actuel<>W_EMS_ERR Then  { Test si Erreur EMS (Plus de Handle) }
      Begin
      Resultat:=True;
      For i:=1 to Nb_Pages_EMS_Actuel do     { Attribuer les Pages Frame }
          EmsMap(Handle_EMS_Actuel,i-1,i-1);

      Nb_Pages_EMS:=Nb_Pages_EMS+Nb_Pages_EMS_Actuel;
      INC(Nb_Handle_EMS);
      Table_Handle_EMS[Nb_Handle_EMS]:=Handle_EMS_Actuel;
      Pointeur:=Ptr(Segment_EMS,0);
 {     MMSS_CFG^.Handle_EMS:=Handle_EMS_Actuel;
      MMSS_CFG^.Mus_Utilise_EMS:=1;}
      {Writeln('Alloue en EMS');}
      End
   End;
MMSS_EMSMemAlloc:=Resultat;
End;  { MMSS_EMSMemAlloc }

{---------------------------------------------------------}

Function MMSS_UMBMemAlloc(Var Pointeur:Pointer;Taille:WORD):Boolean;
Var
   Pointeur_UMB:Pointer;
   Resultat:Boolean;
Begin
Resultat:=False;
Pointeur:=NIL;
If Nb_Bloc_UMB<Max_Bloc_UMB Then
    Begin
    If ReserveUMB(Table_Pointeurs_UMB[Nb_Bloc_UMB+1],Taille)=Taille Then
       Begin
       INC(Nb_Bloc_UMB);
       Pointeur:=Table_Pointeurs_UMB[Nb_Bloc_UMB];
       Resultat:=True;
       {Writeln('Alloue en UMB');  }
       End
       Else
       Begin
       If MemStatus=MCB_DETRUIT Then
          Begin
          Writeln ('UMB Mem Corrupted (Enter)');
          Repeat until readkey=#13;
          End;
       {Writeln('Pas UMB');        }
       End;
    End;
MMSS_UMBMemAlloc:=Resultat;
End;  { MMSS_UMBMemAlloc }

{---------------------------------------------------------}

Function MMSS_DOSMemAlloc(Var Pointeur:Pointer;Taille:WORD):Boolean;
Var
   Pointeur_DOS:Pointer;
   Resultat:Boolean;
Begin
Resultat:=False;
If Nb_Bloc_DOS<Max_Bloc_DOS Then
    Begin
    If ReserveDOS(Table_Pointeurs_DOS[Nb_Bloc_DOS+1],Taille)=Taille Then
       Begin
       INC(Nb_Bloc_DOS);
       Pointeur:=Table_Pointeurs_DOS[Nb_Bloc_DOS];
       Resultat:=True;
       {Writeln('Alloue en DOS');}
       End
       Else
       Begin
       If MemStatus=MCB_DETRUIT Then
          Begin
          Writeln ('DOS Mem Corrupted (Enter)');
          Repeat until readkey=#13;
          End;
       {Writeln('Pas DOS');  }
       End;
    End;
MMSS_DOSMemAlloc:=Resultat;
End;  {MMSS_DOSMemAlloc}

{---------------------------------------------------------}

FUNCTION MMSS_MemAlloc(VAR Pointeur:Pointer;Taille:WORD;UseUMB,
                         UseEMS:Boolean):Boolean;

{ Allouer de la m‚moire dans les UMB, l'EMS et la m‚moire conventionelle }
{ la taille m‚moire … allouer est en paragraphes (Blocs de 16 Octets)    }

VAR
   Resultat:Boolean;

BEGIN
Resultat:=False;
Nb_Pages_EMS_Actuel:=0;
Handle_EMS_Actuel:=$FFFF;

    { Allocate in EMS (If First) }

If (UseEMS) AND (EMS_Presente) AND (MMSS_EMS_First) Then
   Resultat:=MMSS_EMSMemAlloc(Pointeur,Taille);

    { Allocate in UMB }
If (UseUMB) AND (MMSS_Use_UMB) AND (Not Resultat) Then
   Resultat:=MMSS_UMBMemAlloc(Pointeur,Taille);

    { Allocate in DOS }
If (Not Resultat) Then
   Resultat:=MMSS_DOSMemAlloc(Pointeur,Taille);
 
    { Allocate in EMS (If not First) }
	 
If (UseEMS) AND (EMS_Presente) AND (Not MMSS_EMS_First) AND (Not Resultat) Then
   Resultat:=MMSS_EMSMemAlloc(Pointeur,Taille);
 
{Writeln('Segment Zone: ',EntierHexa(Seg(Pointeur^),4));
Repeat until Readkey=#13; }

MMSS_MemAlloc:=Resultat;
End;  {MMSS_MemAlloc}

{---------------------------------------------------------}

PROCEDURE Affiche_Mem;
Begin
Writeln('Heap: ',Maxavail);
Repeat Until Readkey=#13;
End;

PROCEDURE MMSS_FreeModule;

VAR i:Byte;

PROCEDURE FreeMemDOSUMB(Segm:Word);
Var MemPtr:Pointer;
Begin
MemPtr:=Ptr(Segm,0);
If Segm>=$A000 then
   Begin { Sample in UMB }
    LibereUMB(MemPtr);
    Writeln(' UMB: ',Segm);
    Nb_Bloc_UMB:=Nb_Bloc_UMB-1
   End
    Else
   Begin { Sample in DOS }
    LibereDOS(MemPtr);
    Writeln(' DOS: ',Segm);
    Nb_Bloc_DOS:=Nb_Bloc_DOS-1
   End;
End;

Begin

{ Free the Sample/Instrument name table }
If Musique^.PtrInstrNameTable<>NIL then
   FreeMemDOSUMB(Seg(Musique^.PtrInstrNameTable^));

{ Free OtherMus or Module }
If MMSS_CFG^.OtherMUS_Ptr<>NIL Then FreeMemDOSUMB(Seg(MMSS_CFG^.OtherMUS_Ptr^))
 Else
Begin { Free Module }

{ Free the Partition DOS/UMB }
For i:=1 to Max_Pattern do FreeMemDOSUMB(MMSS_Table^.Seg_Pattern[i]);

Writeln('Free Samples ',Musique^.Nb_Total_Samples);

{ Free the Samples EMS/DOS/UMB }
For i:=1 to Musique^.Nb_Total_Samples do
 With MMSS_Table^.PtrSamples[i]^ do
  Begin
   If (Mem.Segment <> 0) Then
    If (Mem.Segment <> Segment_EMS) Then
     If (Mem.Handle_EMS<>-1) then
         Begin { Sample in EMS }
          {LibereEMS(Mem.Handle_EMS);}
          Writeln(' EMS: ',Mem.Handle_EMS);
          Nb_Handle_EMS:=Nb_Handle_EMS-1;
          Nb_Pages_EMS:=Nb_Pages_EMS-Mem.Nb_Pages_EMS;
         End
        else { Sample in DOS/UMB }
         FreeMemDOSUMB(Mem.Segment);
   End; {With }
   
{ Free Samples definition table }
FreeMemDOSUMB(Seg(MMSS_Table^.PtrSamples[1]^));

{ Free Instruments }

If Musique^.Nb_Instr>0 then
 For i:=1 to Musique^.Nb_Instr do
  Begin
  
  End;

End;

Repeat until Readkey=#13;
End;

Procedure MMSS_FreeMemory;
VAR i:Byte;
    Pointeur_Test:Pointer;

Begin
MMSS_MUS_Loaded:=False;
If Not Memoire_Initialisee Then
   Begin             { 1er appel d'MMSS_FreeMemory }
   Nb_Handle_EMS:=0;
   Nb_Pages_EMS:=0;
   Nb_Bloc_UMB:=0;   { Init le nombre de blocs UMB allou‚s }
   Nb_Bloc_DOS:=0;   { Init le nombre de blocs DOS allou‚s }
   Memoire_Initialisee:=True;
   End;

If Nb_Bloc_UMB <>0 Then
   Begin
   For i:=Nb_Bloc_UMB downto 1 do LibereUMB(Table_Pointeurs_UMB[i]);
   End;
If Nb_Bloc_DOS <>0 Then
   Begin
   For i:=1 to Nb_Bloc_DOS do LibereDOS(Table_Pointeurs_DOS[i]);
   End;
If Nb_Handle_EMS <>0 Then
   For i:=1 to Nb_Handle_EMS do LibereEMS(Table_Handle_EMS[i]);

Nb_Bloc_UMB:=0;   { Init le nombre de blocs UMB allou‚s }
Nb_Bloc_DOS:=0;   { Init le nombre de blocs DOS allou‚s }
Nb_Handle_EMS:=0;
Nb_Pages_EMS:=0;
{MMSS_CFG^.Handle_EMS:=0;
MMSS_CFG^.Mus_Utilise_EMS:=0;}   { Pour dire de sauver les pages EMS }
End;  {MMSS_FreeMemory}

END.