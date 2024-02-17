{************************************************************************}
{                               MEMOIRE.PAS                              }
{                                                                        }
{  Basic Memory procedures (DOS, UMB et EMS)                             }
{                                                                        }
{  AUTEUR: Freddy Vetele.                                                }
{                                                                        }
{  Rq: Les allocations en memoire DOS et UMB sont en paragraphes !!!     }
{  MAX_Bloc_UMB 256>16                                                   }
{  DOS 2.0 or More                                                       }
{                               D‚but d'‚criture le 27/03/95             }
{                               DerniŠres modifications le 08/10/95      }
{************************************************************************}

UNIT Memoire;
{$A+,G-,Q-,R-,S-}

INTERFACE

CONST {Num‚ros des fonctions du DOS}
      GET_MEM     =$48;    { Reserve de la memoire vive              }
      FREE_MEM    =$49;    { Libere de la memoire vive               }
      CHANGE_MEM  =$4A;    { Modifie la taille d'une zone de memoire }
      GET_STRATEGY=$5800;  { Lit la strategie d'allocation           }
      SET_STRATEGY=$5801;  { Fixe la strategie d'allocation          }
      GET_UMB     =$5802;  { Lit l'etat d'inclusion des blocs UMB    }
      SET_UMB     =$5803;  { Fixe l'inclusion des blocs UMB          }

      {Strat‚gies de recherche de m‚moire}
      CHERCHE_EN_BAS  =$00; { premier bloc de memoire libre          }
      CHERCHE_MEILLEUR=$01; { meilleur bloc de memoire libre         }
      CHERCHE_EN_HAUT =$02; { dernier bloc de memoire libre          }
      SEARCH_UMB      =$40; { Chercher dans la zone UMB              }
      FIRST_UMB       =$80; { Chercher dans la zone UMB              }

      EMS_INT  =$67;        { Nø d'interruption pour l'accŠs … l'EMM }
      EMS_ERR  =-1;         { Est renvoye en cas d'erreur }
      W_EMS_ERR=$FFFF;      { Code d'erreur en format WORD }

      MCB_DETRUIT     =7;
      PAS_ASSEZ_DE_MEM=8;


      Memoire_Initialisee:Boolean=False;
      MAX_Handle_EMS=64;
      MAX_Bloc_DOS=256;
      MAX_Bloc_UMB=64;
TYPE 

     T_MCB=Record
           Id       : Char;
           MCB_PSP  : Word;
           Size     : Word;
           Unused   : Array[1..3] of Byte;
           ProgName : Array[1..8] of Char; {DOS 4+}
           End;
{ PSP https://en.wikipedia.org/wiki/Program_Segment_Prefix }
     T_PSP=Record
	       P_Exit   : Word;
		   P_EndSeg : Word; {Segment of the first byte beyond the memory allocated to the program}
		   P_Res1   : Byte;
		   P_Res2   : Array[1..5] of Byte;
		   P_PrevTerm   : Pointer;
		   P_PrevBreak  : Pointer;
		   P_PrevCritic : Pointer;
		   P_ParentPSP  : Word;
		   P_JFT        : Array[1..20] of Byte;
		   P_EnvSeg     : Word;
		   P_LastInt21  : Pointer;
		   P_JFTSize    : Word;
		   
		   end;

VAR LastEMS:Word;
    EMSUtilise:Boolean;

    Nb_Handle_EMS:Integer;
    Nb_Pages_EMS:Integer;
    Nb_Bloc_DOS :Word;
    Nb_Bloc_UMB :Word;
    Table_Handle_EMS:Array[1..Max_Handle_EMS] of Word;   { This need to be removed }
    Table_Pointeurs_DOS:Array[1..Max_Bloc_DOS] of Pointer;
    Table_Pointeurs_UMB:Array[1..Max_Bloc_UMB] of Pointer;


    MemStatus: Byte;       { code d'erreur m‚moire DOS et UMB }
    EMSStatus: Byte;       { code d'erreur EMM }
	
    Nb_pages_EMS_Libres: Integer;
    Segment_EMS: Word;     { segment du Page Frame EMS }
	
    PtrMCB: ^T_MCB;

{
Format of DOS memory control block:
Offset	Size	Description	(Table 01628)
 00h	BYTE	block type: 5Ah if last block in chain, otherwise 4Dh
 01h	WORD	PSP segment of owner or special flag value (see #01629)
 03h	WORD	size of memory block in paragraphs
 05h  3 BYTEs	unused by MS-DOS
		(386MAX) if locked-out block, region start/prev region end
---DOS 2.x,3.x---
 08h  8 BYTEs	unused
---DOS 4.0+ ---
 08h  8 BYTEs	ASCII program name if PSP memory block or DR DOS UMB,
		  else garbage
		null-terminated if less than 8 characters
Notes:	the next MCB is at segment (current + size + 1)}


{==========================================================}

{**** M‚moire DOS ****}
FUNCTION  MemoireDOSLibre: Word;
FUNCTION  ReserveDOS(Var adresse: Pointer; Taille: Word): Word;
FUNCTION  ModifieDOS(Var adresse: Pointer; Taille: Word): Word;
PROCEDURE LibereDOS(Var adresse: Pointer);
PROCEDURE FixeRecherche(strategie: Byte);
FUNCTION MEMSizeDOS(Var Segm: Word):Word;

{**** M‚moire UMB ****}
FUNCTION  ReserveUMB(Var adresse: Pointer; Taille: Word): Word;
PROCEDURE LibereUMB(Var adresse: Pointer);
PROCEDURE ReduceDOSUMB(Var adresse: Pointer; Taille: Word);

{**** M‚moire EMS ****}
FUNCTION EMSInst: Boolean;
FUNCTION EmsVersion : Byte;
FUNCTION PagesEMSLibres: Integer;
FUNCTION EMSFrameSeg: Word;
FUNCTION ReserveEMS(Pages: Integer): Integer;
FUNCTION LibereEMS(handle: Integer): Boolean;
FUNCTION EMSMap(handle,PLog: Integer; PPhys: Byte): Boolean;
FUNCTION SaveMapEMS(handle: Integer): Boolean;


PROCEDURE DetecteUMB(affiche: Boolean);
PROCEDURE DetecteMemoire(affiche: Boolean);

FUNCTION TestMem16K(Segment:Word): Boolean;
FUNCTION TestROM16K(Segment:Word): Boolean;
FUNCTION GetFirstMCB: Word;  { Get the First UMB Block @ }


{==========================================================}

IMPLEMENTATION

USES Crt,VarUnit;

{==========================================================}

FUNCTION MemoireDOSLibre: Word; Assembler;
ASM
 MOV AH,Get_Mem
 MOV BX,0FFFFh             {Allouer toute la m‚moire     }
 INT 21h                   {=> le Dos nous donne la m‚moire disponible}
 MOV AX,BX                 {M‚moire libre en paragraphes}
End; {MemoireDOSLibre}

{----------------------------------------------------------}

FUNCTION ReserveDOS(Var adresse: Pointer; Taille: Word): Word;
Var Taille_Libre: Word;
Begin
 ASM
  MOV MemStatus,0
  MOV BX,Taille
  MOV AH,GET_MEM
  INT 21H
  JNC @Ok
  MOV MemStatus,AL
  MOV AX,0
 @Ok:
  LES DI,adresse
  MOV ES:[DI+2],AX
  XOR AX,AX
  MOV ES:[DI],AX
  MOV Taille_Libre,BX
 End;
 If MemStatus=MCB_DETRUIT Then Taille_Libre:=0;
 ReserveDOS:=Taille_Libre
End; {ReserveDOS}

{----------------------------------------------------------}

FUNCTION ModifieDOS(Var adresse: Pointer; Taille: Word): Word; Assembler;
ASM
 MOV MemStatus,0
 LES DI,adresse
 MOV AX,ES:[DI+2]
 MOV ES,AX             { ES <- segment de la zone   }
 MOV BX,Taille         { Nouvelle taille de la zone }
 MOV AH,CHANGE_MEM
 INT 21H
 JNC @Ok
 MOV MemStatus,AL      { Code d'erreur }
@Ok:
 MOV AX,BX             { Taille libre si m‚moire insuffisante }
End; {ModifieDOS}

{----------------------------------------------------------}

PROCEDURE LibereDOS(Var adresse: Pointer); Assembler;
{ The offset must be nul !!! }
ASM
 MOV MemStatus,0
 LES DI,adresse
 MOV AX,ES:[DI+2]
 CMP AX,0
 JE @Fin
 MOV ES,AX         { ES <- Segment de la Zone }
 MOV AH,FREE_MEM
 INT 21h
 JNC @OK
 MOV MemStatus,AL
 JMP @Fin
@OK:
 LES DI,adresse
 XOR BX,BX         { Zone lib‚r‚e => Pointeur <- NIL }
 MOV ES:[DI+2],BX
 MOV ES:[DI],BX
@Fin:
End; {LibereDOS}

{----------------------------------------------------------}

PROCEDURE FixeRecherche(strategie: Byte); Assembler;
ASM
 MOV AX,SET_STRATEGY
 XOR BH,BH
 MOV BL,strategie
 INT 21H
End; {FixeRecherche}

{----------------------------------------------------------}

FUNCTION MEMSizeDOS(Var Segm: Word):Word;
Begin
PtrMCB:=Ptr(Segm-1,0); { Point to the MCB }
MemSizeDOS:=PtrMCB^.Size;
End;

{----------------------------------------------------------}

FUNCTION LierUMB(Lier: Boolean): Boolean; Assembler;
ASM
 MOV AX,GET_UMB
 INT 21h
 MOV AH,0
 JC @Fin
 MOV AH,AL
 PUSH AX
 MOV AX,SET_UMB
 XOR BH,BH
 MOV BL,Lier
 INT 21h
 POP AX
@Fin:
 MOV AL,AH
End; {LierUMB}

{----------------------------------------------------------}

FUNCTION ReserveUMB(Var adresse: Pointer; Taille: Word): Word;
Var Memoire_Allouee: Word;
Begin
 LierUMB(True);              { UBM Blocks are linked to DOS Blocks }
 FixeRecherche(FIRST_UMB);     { Search in UMB                       }
 Memoire_Allouee:=ReserveDOS(adresse,Taille);
 If Memoire_Allouee=Taille Then
  If Seg(adresse^)<$A000 Then { Zone Allouee en m‚moire DOS !!! }
   Begin
    Memoire_Allouee:=0;
    LibereDOS(adresse);
    MemStatus:=PAS_ASSEZ_DE_MEM;
   End;
 FixeRecherche(CHERCHE_EN_BAS);
 LierUMB(False);
 ReserveUMB:=Memoire_Allouee
End;

{----------------------------------------------------------}

PROCEDURE LibereUMB(Var adresse: Pointer);
Var SaveLink: Boolean;
BEGIN
 SaveLink:=LierUMB(True);
 LibereDOS(adresse);
 LierUMB(SaveLink)
End;  {LibereUMB}

{----------------------------------------------------------}

PROCEDURE ReduceDOSUMB(Var adresse: Pointer; Taille: Word);
Begin
  If Seg(adresse^)>=$A000 Then { Zone Allouee en m‚moire UMB !!! }
   Begin
    LierUMB(True);                { UBM Blocks are linked to DOS Blocks }
	ModifieDOS(adresse,Taille);
	LierUMB(False)
	End
	Else ModifieDOS(adresse,Taille);
End;


FUNCTION EMSInst: Boolean;
Type Char8=Array[1..8] of Char;
     Char8Ptr=^Char8;
Const EMMid: Char8='EMMXXXX0';
Begin
 EMSInst:=(Char8Ptr(Ptr(MemW[0:4*EMS_Int+2],10))^=EMMid)
End; {EMSInst}

{----------------------------------------------------------}

FUNCTION EmsVersion: Byte; Assembler;
ASM
 MOV EMSStatus,0
 MOV AH,46h           { D‚terminer la version de l'EMS       }
 INT EMS_INT
 CMP AH,0
 JZ  @Ok
 MOV EMSStatus,AH     { Erreur => Renvoyer le code d'erreur  }
 MOV AX,W_EMS_ERR     { EMSVersion=EMS_ERR                   }
@Ok:
end;

{----------------------------------------------------------}

FUNCTION PagesEMSLibres: Integer; Assembler;
ASM
 MOV EMSStatus,0
 MOV AH,42h           { D‚terminer le nombre de pages        }
 INT EMS_INT
 CMP AH,0
 JZ  @Ok
 MOV EMSStatus,AH     { Erreur => Renvoyer le code d'erreur  }
 MOV AX,W_EMS_ERR     { PagesEMSLibres=EMS_ERR               }
 JMP @Fin
@Ok:
 MOV AX,DX            { Renvoyer le nb de pages libres       }
@Fin:
End; {PagesEMSLibres}

{----------------------------------------------------------}

FUNCTION EMSFrameSeg: Word; Assembler;
ASM
 MOV EMSStatus,0
 MOV AH,41h           { Nø fct.: Rech segment de Page Frame     }
 INT EMS_INT
 CMP AH,0
 JZ  @Ok
 MOV EMSStatus,AH     { Erreur => Renvoyer le code d'erreur     }
 MOV AX,W_EMS_ERR
 JMP @Fin
@Ok:
 MOV AX,BX            { Renvoyer adresse segment de Page Frame  }
@Fin:
End; {EMSFrameSeg}

{----------------------------------------------------------}

FUNCTION ReserveEMS(Pages: Integer): Integer; Assembler;
ASM
 MOV EMSStatus,0
 MOV AH,43h           { Nø fct.: Allouer pages                  }
 MOV BX,Pages         { Nb de pages … allouer                   }
 INT EMS_INT          { Appeler EMM (ou QEMM ...)               }
 CMP AH,0
 JZ  @Ok
 MOV EMSStatus,AH     { Erreur => Renvoyer le code d'erreur     }
 MOV AX,W_EMS_ERR
 JMP @Fin
@Ok:
 MOV AX,DX            { Renvoyer le handle                      }
@Fin:
End; {ReserveEMS}

{----------------------------------------------------------}

FUNCTION LibereEMS(handle: Integer): Boolean; Assembler;
ASM
 MOV AH,45h           { Nø fct.: Lib‚rer pages   }
 MOV DX,handle        { Fixer handle EMS         }
 INT EMS_INT          { Appeler EMM              }
 MOV EMSStatus,AH     { Ranger le code d'erreur  }
 CMP AH,0
 JE  @Ok
 XOR AX,AX            { Erreur => False          }
 JMP @Fin
@Ok:
 MOV AX,1             { Ok => True               }
@Fin:
End;  {LibereEMS}

{----------------------------------------------------------}

FUNCTION EMSMap(handle,PLog: Integer; PPhys: Byte): Boolean; Assembler;
ASM
 MOV AH,44h           { Nø fct.: Fixer Mapping   }
 MOV AL,PPhys         { Fixer la page physique   }
 MOV BX,PLog          { Fixer la page logique    }
 MOV DX,handle        { Fixer handle EMS         }
 INT EMS_INT          { Appeler EMM              }
 MOV EMSStatus,AH     { Ranger le code d'erreur  }
 CMP AH,0
 JE  @Ok
 XOR AX,AX            { Erreur => False          }
 JMP @Fin
@Ok:
 MOV AX,1             { Ok => True               }
@Fin:
End; {EMSMap}

{----------------------------------------------------------}

FUNCTION SaveMapEMS(handle: Integer): Boolean; Assembler;
ASM
 MOV AH,47h           { Nø fct.: Sauver Mapping  }
 MOV DX,handle        { Fixer handle EMS         }
 INT EMS_INT          { Appeler EMM              }
 MOV EMSStatus,AH     { Ranger le code d'erreur  }
 CMP AH,0
 JE  @Ok
 XOR AX,AX            { Erreur => False          }
 JMP @Fin
@Ok:
 MOV AX,1             { Ok => True               }
@Fin:
End; {SaveMapEMS}

{---------------------------------------------------------}

Function AllouerB_EMS(Var B:TBlocMem;Taille:WORD):Boolean;
Var i:Integer;
    Resultat:Boolean;
Begin
B.Handle_EMS:=$FFFF;
B.Nb_Pages_EMS:=0;
B.Segment:=0;

Resultat:=False;

IF (Nb_Pages_EMS<=Nb_Pages_EMS_Libres) AND (Nb_Handle_EMS<=Max_Handle_EMS) Then
   Begin
   B.Nb_Pages_EMS:=(Taille DIV 1024)+1;
   B.Handle_EMS:=ReserveEMS(B.Nb_Pages_EMS);

   If B.Handle_EMS<>W_EMS_ERR Then  { Test si Erreur EMS (Plus de Handle) }
      Begin
      For i:=1 to B.Nb_Pages_EMS do     { Attribuer les Pages Frame }
          EmsMap(B.Handle_EMS,i-1,i-1);

      Nb_Pages_EMS:=Nb_Pages_EMS+B.Nb_Pages_EMS; { Nb de pages allou‚es au total }
      INC(Nb_Handle_EMS);
      For i:=1 to Max_Handle_EMS do
          If Table_Handle_EMS[i]=$FFFF Then Break; { Place libre dans le tableau }
      Table_Handle_EMS[i]:=B.Handle_EMS;
      B.Segment:=Segment_EMS;
      LastEMS:=B.Handle_EMS;
      EMSUtilise:=True;
      Resultat:=True;
      {Writeln('Alloue en EMS');}
      End
   End;

AllouerB_EMS:=Resultat;
End;  { Allouer_EMS }

{---------------------------------------------------------}

Function AllouerB_UMB(Var B:TBlocMem;Taille:WORD):Boolean;
Var
   Pointeur_UMB:Pointer;
   Resultat:Boolean;
Begin
B.Handle_EMS:=$FFFF;
B.Nb_Pages_EMS:=1;
B.Segment:=0;

Resultat:=False;

If ReserveUMB(Pointeur_UMB,Taille)=Taille Then
   Begin
    B.Segment:=Seg(Pointeur_UMB);
    Resultat:=True;
    {Writeln('Alloue en UMB');  }
   End
   Else
   Begin
    If MemStatus=MCB_DETRUIT Then
       Begin
       Writeln ('UMB Memory Corrupted (Enter)');
       Repeat until readkey=#13;
       End;
    {Writeln('Pas UMB');        }
   End;

AllouerB_UMB:=Resultat;
End;  { Allouer_UMB }

{---------------------------------------------------------}

Function AllouerB_DOS(Var B:TBlocMem;Taille:WORD):Boolean;
Var
   Pointeur_DOS:Pointer;
   Resultat:Boolean;
Begin
B.Handle_EMS:=$FFFF;
B.Nb_Pages_EMS:=0;
B.Segment:=0;

Resultat:=False;
If ReserveDOS(Pointeur_DOS,Taille)=Taille Then
   Begin
    B.Segment:=Seg(Pointeur_DOS);
    Resultat:=True;
    {Writeln('Alloue en DOS');}
   End
   Else
   Begin
    If MemStatus=MCB_DETRUIT Then
       Begin
       Writeln ('DOS Memory Corrupted (Enter)');
       Repeat until readkey=#13;
       End;
    {Writeln('Pas DOS');  }
   End;

AllouerB_DOS:=Resultat;
End;  {AllouerB_DOS}

{---------------------------------------------------------}

FUNCTION AllouerB_Memoire(VAR B:TBlocMem;Taille:WORD;UseUMB,
                         UseEMS:Boolean):Boolean;

{ Allouer de la m‚moire dans les UMB, l'EMS et la m‚moire conventionelle }
{ la taille m‚moire … allouer est en paragraphes (Blocs de 16 Octets)    }

VAR
   Resultat:Boolean;

BEGIN
Resultat:=False;

    { Allouer en EMS }

If (UseEMS) AND (EMS_Presente) {AND (Utilise_EMS)} Then
   Resultat:=AllouerB_EMS(B,Taille);

    { Allouer en memoire UMB }

If (UseUMB) {AND (Utilise_UMB)} AND (Not Resultat) Then
   Resultat:=AllouerB_UMB(B,Taille);

    { Allouer en m‚moire DOS }

If (Not Resultat) Then
   Resultat:=AllouerB_DOS(B,Taille);
{Writeln('Segment Zone: ',EntierHexa(Seg(Pointeur^),4));
Repeat until Readkey=#13; }

AllouerB_Memoire:=Resultat;
End;  {MMSS_MemAlloc}

{----------------------------------------------------------}

PROCEDURE DetecteDOS(affiche: Boolean);
Begin
 If affiche Then Write(MemoireDOSLibre SHR 6,'kb DOS. ')
End; {DetecteDOS}

{----------------------------------------------------------}

PROCEDURE DetecteUMB(affiche: Boolean);
Var Pointeur_TestUMB: Pointer;
    FreeMem: Word;
Begin
 UMB_Presente:=(ReserveUMB(Pointeur_TestUMB,64)=64);
 If UMB_Presente Then
  Begin
   LibereUMB(Pointeur_TestUMB);
   If affiche Then Write('UMB. ');  
  End
End; {DetecteUMB}

{----------------------------------------------------------}

PROCEDURE DetecteEMS(affiche: Boolean);
Begin
 EMS_Presente:=EMSInst;
 If EMS_Presente Then
  Begin
   Nb_pages_EMS_Libres:=PagesEMSLibres;
   If Nb_pages_EMS_Libres<>EMS_ERR Then
    Begin
     Segment_EMS:=EMSFrameSeg;
     If affiche Then Write(Nb_pages_EMS_Libres*16,'kb EMS. ')
    End
	Else EMS_Presente:=False;
  End
End; {DetecteEMS}

{----------------------------------------------------------}

PROCEDURE DetecteMemoire(affiche: Boolean);
Begin
 If affiche Then Write('Memory: ');
 DetecteDOS(affiche); DetecteUMB(affiche); DetecteEMS(affiche);
 If affiche Then Writeln
End; {DetecteMemoire}

{----------------------------------------------------------}
{ **   Check if a 16Kb Memory block is RAM ** }

FUNCTION TestMem16K(Segment:Word): Boolean; Assembler;
ASM
  PUSH DS
  MOV AX,1
  MOV DS,Segment
  XOR SI,SI
  CLI
  MOV CX,15
@MemTest16KLoop:  { Backup the value }
  MOV DX,DS:[SI]
  MOV WORD Ptr DS:[SI],$AA55
  MOV BX,DS:[SI]
  MOV DS:[SI],DX  { Restore the Value }
  CMP BX,$AA55
  JNE @MemError
  MOV DX,DS:[SI]
  MOV WORD Ptr DS:[SI],$55AA
  MOV BX,DS:[SI]
  MOV DS:[SI],DX
  CMP BX,$55AA
  JNE @MemError

  ADD SI,1024
  LOOP @MemTest16KLoop
  JMP @MemOk
@MemError:
  MOV AX,0
@MemOk:
  STI         
  POP DS
End;

{----------------------------------------------------------}
{ **   Check if a 16Kb Memory block is ROM ** }

FUNCTION TestROM16K(Segment:Word): Boolean; Assembler;
ASM
  PUSH DS
  MOV AX,1
  MOV DS,Segment
  XOR SI,SI
  CLI
  MOV CX,15
@ROMTest16KLoop:
  MOV DX,DS:[SI]
  MOV WORD Ptr DS:[SI],$AA55
  MOV BX,DS:[SI]
  MOV DS:[SI],DX
  CMP BX,DX        { Read the same as the first Word Read ? }
  JNE @ROMError
  MOV DX,DS:[SI]
  MOV WORD Ptr DS:[SI],$55AA
  MOV BX,DS:[SI]
  MOV DS:[SI],DX
  CMP BX,DX
  JNE @ROMError

  ADD SI,1024
  LOOP @ROMTest16KLoop
  JMP @ROMOk
@ROMError:
  MOV AX,0
@ROMOk:
  STI         
  POP DS
End;

FUNCTION GetFirstMCB: Word; Assembler;
ASM
 MOV AH,52h                { }
 INT 21h                   {ES:BX -> DOS list of lists}
 CMP BX,$1000
 JB @GetMCBDecSeg          {Get the ES:BX-2 @         }
 DEC BX
 DEC BX
 JMP @GetMCB_Test
@GetMCBDecSeg:
 MOV AX,ES
 DEc AX
 MOv ES,AX
 ADD BX,14
@GetMCB_Test:              { Test if it is an MCB }
 MOV AX,ES:[BX]            { Fist MCB Segment }
 MOV ES,AX
 MOV BL,ES:[0]
 CMP BL,4Dh                { 4D if not the first Block }
 JNE @GetMCBNotMCB
 RET
@GetMCBNotMCB:
 XOR AX,AX                 { Return 0 : Not Found }
End; {GetFirstMCB}

{==========================================================}

END.