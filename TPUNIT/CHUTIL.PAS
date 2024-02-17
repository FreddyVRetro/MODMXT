{************************************************************************}
{                               CHUTIL.PAS                               }
{                                                                        }
{  Routines pour le chargement des modules (Sample, Gestion des voies...)}
{                                                                        }
{  AUTEUR: Freddy Vetele.                                                }
{                                                                        }
{                               Debut d'ecriture le --/10/94             }
{                               Dernieres modifications le 19/11/2020    }
{************************************************************************}
{$I MODMCFG.INI}

{$UNDEF  Groupe  }
{$UNDEF  AFF     }

{$IFNDEF Groupe}
UNIT ChUtil;       { Procedures pour simplifier le chargement des modules }
{$ELSE}
UNIT ChUtil_G;
{$ENDIF}

{$A+,Q-,R-,S-,G-}

INTERFACE

{$IFNDEF NoGUS}
{$IFNDEF Groupe}
USES MMSS_Var,Fichiers,GUSUnit,Memoire,CRT,MMSS_MEM;
{$ELSE}
USES MMSS_Var,Fich_grp,GusUnit,Memoire,CRT,MMSS_MEM;
{$ENDIF}
{$ELSE}
{$IFNDEF Groupe}
USES MMSS_Var,Fichiers,Memoire,CRT,MMSS_MEM;
{$ELSE}
USES MMSS_Var,Fich_grp,Memoire,CRT,MMSS_MEM;
{$ENDIF}
{$ENDIF}

Const
    Avec_EMS=True;
    Nb_Smp_Sup_XM   = 16;

    GF1_REG_SELECT  = $103;  (* 3X3 *)

    SET_DRAM_LOW    = $43;
    SET_DRAM_HIGH   = $44;

    TailleFinSample = 512;
    TailleMaxSample = 65535-16*4-TailleFinSample;
    SizeLBlock = 16 * 1024; { Buffer pour la Gravis }
	
	CPM_Compressed  = $80;
	CPM_Empty       = $40;
	CPM_Note        = $20;
	CPM_Instr       = $10;
	CPM_Cmd         = $08;
	CPM_Param       = $04;
	CPM_Vol         = $02;


Type TTSample=Array[0..65000] of Shortint;
     CPPattern=Array[0..65000] of Byte;
     TTampon_GUS=Array[1..SizeLBlock+16] of Byte;
     TTInstr = Array[1..Max_Samples] of T_Instr;

VAR
   f_module: Fichier;        { fichier actuel }
   Deplacement_pointeur_fichier:WORD;

   Pointeur_actuel: Pointer;  { Pointeur des zones m‚moires pour le chargement }
   Erreur_de_chargement:WORD;

   CHU_NSmp :Word;                   { Nø du sample actuel     }
   Nb_Samples_Allocated : Word;
   Convertir_signe:Boolean;

   Smp:T_Sample;                 { Informations sur le sample a charger }
   Smp_Rep_Fin:LongInt;
   Ancien_Delta:Word;            { Pour les samples codes en Delta !!!  }
   C_Note:T_Note;
   NV_Note:T_Note_NV;

   Nb_Instruments: Byte;         { Gestion du nombre de samples         }
   Nb_Pas_charge : Byte;
   SamplFlags:Array[1..Max_Samples] of Boolean; { Used to check the Samples/Instruments in the partition }
   PtrInstrument : ^TTInstr;

{$IFNDEF MMMONLY}
   CP_Pattern : ^CPPattern;
   CP_Index  : Word;      { Compressed Pattern Index           }
   CP_AllocatedSize : Word;
   CP_PrevIndex : Word;
   CP_Channel: Byte;
   CP_ValCnt : Byte;      { Number of Valid Value in a channel }
   CP_PrevEmpty : Byte;   { 0 if Previous Channel was Empty }
{$ENDIF}

PROCEDURE Init_Panning; { Init la position des voies  }
FUNCTION  Panning_GUS_SB(Panning:Byte):Byte;
PROCEDURE New_Sample;
FUNCTION  Allouer_Samples(Nb_Samples:Byte):Boolean;
FUNCTION Allocate_Instruments(Nb_Instr:Byte):Boolean; { Allocate memory for the Instruments information tables }
PROCEDURE Init_Charge_Sample;
PROCEDURE Ajuster_Sample;
PROCEDURE Charger_Sample;
PROCEDURE Fin_Charge_Sample;
PROCEDURE Compter_Voies;
FUNCTION  Check_Used_Pattern:Byte;
PROCEDURE Init_Module;                        { Effacer les tables du module }

{ Pattern Compression Code }
{$IFNDEF MMMONLY}
FUNCTION CP_NewPattern(CP_Size:integer):Boolean;
PROCEDURE CP_End;
PROCEDURE CP_NextRow;
PROCEDURE CP_AddEmptyCh(Nb_Empty_Ch:Byte);
PROCEDURE CP_AddVal;
{$ENDIF}
{ CP_AddEmpty }

{====================================================}

IMPLEMENTATION

VAR
   Pointeur_Tampon_GUS:^TTampon_GUS;  { Variables pour la GUS }

   Taille_GUS    : Word;
   Taille_pas_transferee:Word;
   Memoire_Gravis: Longint;
   BlockSize     : Word;

{$IFNDEF MMMONLY}
Function CP_NewPattern(CP_Size:integer):Boolean;
Begin
CP_Index:=1;     { First index is 1 as the first Byte is the Delta to next Row }
CP_PrevIndex:=0;
CP_PrevEmpty:=0; { Previous Channel Not Empty}
CP_NewPattern:=MMSS_MemAlloc(Pointeur_Actuel,CP_Size+16,True,False);
CP_Pattern:=Pointeur_Actuel;
CP_AllocatedSize:=(CP_Size+16)*16;
{Writeln('Size:',CP_Size*16,' Seg: ',Seg(Pointeur_Actuel^),' UMB:',Nb_Bloc_UMB,' DOS:',Nb_Bloc_DOS);}
End;

PROCEDURE CP_NextRow;
VAR IndexDelta : Word;
Begin
IndexDelta:=CP_Index-CP_PrevIndex-1;
If IndexDelta=1 Then
   Begin
    CP_Pattern^[CP_PrevIndex]:=0; { Row is Empty }
	CP_PrevIndex:=CP_PrevIndex+1;
   End
   Else
   Begin
    CP_Pattern^[CP_PrevIndex]:=IndexDelta;
    CP_PrevIndex:=CP_Index;
    CP_Index:=CP_Index+1;
   End;
CP_PrevEmpty:=0 { Previous Channel Not Empty}
End;

PROCEDURE CP_AddEmptyCh(Nb_Empty_Ch:Byte); { Nb_Empty is the real Nb-1 }
Begin
{Write ('i',Nb_Empty_Ch,',');}
If CP_PrevEmpty=0 Then
   Begin
   CP_Pattern^[CP_Index]:=CPM_Compressed+CPM_Empty+Nb_Empty_Ch;
   CP_Index:=CP_Index+1;
   End
   Else CP_Pattern^[CP_Index-1]:=CP_Pattern^[CP_Index-1]+Nb_Empty_Ch+1;
CP_PrevEmpty:=1;
End;

PROCEDURE CP_AddVal;  Assembler;
ASM
      PUSH ES
      CLD
      XOR AX,AX
      XOR BX,BX
      XOR CX,CX
      XOR DX,DX            { Clear Values Counter   }
	  MOV DH,255           { Default volume         }
      LEA SI,C_Note        { DS SI / Channel Values }
      LES DI,CP_Pattern
      ADD DI,CP_Index      { ES was 0 }

      LODSB
      TEST AL,AL
      JZ @CP_NoNote
      MOV BL,AL     { Note BL }
      OR AH,CPM_Note
      INC DL        { Values Count DL }
@CP_NoNote:
      LODSB
      TEST AL,AL
      JZ @CP_NoInstr
      MOV BH,AL    { Instr BH}
      OR AH,CPM_Instr	  
      INC DL
@CP_NoInstr:
      LODSB
      TEST AL,AL
      JZ @CP_NoCmd
      MOV CL,AL    { Cmd CL }
      OR AH,CPM_Cmd
      INC DL
@CP_NoCmd:
      LODSB
      TEST AL,AL
      JZ @CP_NoParam
      MOV CH,AL   { Param CH }
      OR AH,CPM_Param
      INC DL
@CP_NoParam:
      LODSB
      CMP AL,0FFh
      JZ @CP_NoVol
      MOV DH,AL   { Vol DL }
      OR AH,CPM_Vol
      INC DL
@CP_NoVol:
      TEST DL,DL
      JZ @CP_NoteEmpty
      CMP DL,4
      JB @CP_Compress
{4 ou 5 Values / Store All}
      MOV ES:[DI],BX
      MOV ES:[DI+2],CX
      MOV ES:[DI+4],DH
      ADD DI,5
      MOV CP_Index,DI
      MOV CP_PrevEmpty,0 { Previous Channel Not Empty}
      POP ES
      RET      { RETURN (Store All) }
@CP_Compress:
      MOV AL,AH
      OR AL,CPM_Compressed
      STOSB      { Store the Compression infos Mask Byte }
      TEST BL,BL
      JZ @CP_NoNote2
      MOV AL,BL
      STOSB  { Store Note }
@CP_NoNote2:
      TEST BH,BH
      JZ @CP_NoInstr2
      MOV AL,BH
      STOSB  { Store Instrument }
@CP_NoInstr2:
      TEST CL,CL
      JZ @CP_NoCmd2
      MOV AL,CL
      STOSB  { Store Command }
@CP_NoCmd2:
      TEST CH,CH
      JZ @CP_NoParam2
      MOV AL,CH
      STOSB  { Store Parameter }
@CP_NoParam2:
      CMP DH,0FFh
      JE @CP_NoVol2
      MOV AL,DH
      STOSB  { Store Volume }
@CP_NoVol2:
      MOV CP_Index,DI
      MOV CP_PrevEmpty,0 { Previous Channel Not Empty}
      POP ES
      RET      { RETURN }
@CP_NoteEmpty:
{ Current Channel Values are empty}
      MOV AL,CP_PrevEmpty
      TEST AL,AL
      JNZ @CP_PrevWasEmpty
{ Add an Empty Note (Value 0) }
      MOV AL,CPM_Compressed+CPM_Empty
      STOSB
      INC CP_Index
      MOV CP_PrevEmpty,1
      POP ES
      RET      { RETURN }
@CP_PrevWasEmpty:
{ Previous note was also Empty }
      DEC DI
      ADD Byte Ptr ES:[DI],1
      POP ES
      RET      { RETURN }
{Empty}  
      MOV CP_PrevEmpty,DL

End;

PROCEDURE CP_End;
Begin
{ Resize the Memory Block }
{Writeln('Compressed Size:',CP_Index);
Repeat until Readkey=#13;}
If CP_Index>CP_AllocatedSize then Writeln('S3M Pattern too Big'); { Will Crash... }
Pointeur_Actuel:=CP_Pattern;
ReduceDOSUMB(Pointeur_Actuel,(CP_Index DIV 16)+1);
End;
{$ENDIF}

{$IFNDEF NoGUS}
PROCEDURE RAMTODRAM(Valeur_XOR:Byte;Adresse:Longint);
VAR Port_Base:Word;
    Seg_DRAM:Word;
    Offs_DRAM:Word;
    Seg_Tampon:Word;
    Offs_Tampon:Word;

Begin
Port_Base:=Ultra_Base_Port+GF1_REG_SELECT;
Seg_DRAM:=Adresse SHR 16;
Offs_DRAM:=Adresse AND $FFFF;

{ Dump sample to DRAM                        }
{   DS:SI - Max 64k sample to dump to RAM.   }
{   BL:DI - DRAM location to dump to.        }
{   CX    - Max bytes to dump.               }
{   BH    - Xor value.                       }

ASM
   CLI
   CLD
   PUSH CX
   MOV BX,SEG_DRAM
   MOV BH,Valeur_XOR
   MOV DI,Offs_DRAM
   MOV CX,BlockSize
   MOV DX,Port_Base
   PUSH DS
   LDS SI,Pointeur_Tampon_GUS
   MOV AL,SET_DRAM_HIGH{ Dump upper byte, only do it on carry from now}
   OUT DX,AL           { on.                                          }
   ADD DX,2
   MOV AL,BL           { BL Partie haute de l'adresse }
   OUT DX,AL           { 3x5 Data High }
   SUB DX,2
   MOV AL,SET_DRAM_LOW
   OUT DX,AL           { 3x3 Select Register }
   INC DX     
@MainLoop:
   MOV AX,DI
   OUT DX,AX           { 3x4 Data Low, Set the @}
   LODSB
   XOR AL,BH
   ADD DX,3
   OUT DX,AL           { 3x7 DRAM, send the Data }
   SUB DX,3
   INC DI
   JNZ @DoLoop         { Move to the next bank (SI>65536)}
   DEC DX
   INC BL
   MOV AL,SET_DRAM_HIGH
   OUT DX,AL           { 3x3 Select Register }
   MOV AL,BL           { BL Partie haute de l'adresse }
   ADD DX,2
   OUT DX,AL           { 3x5 Data High }
   SUB DX,2
   MOV AL,SET_DRAM_LOW
   OUT DX,AL           { 3x3 Select Register }
   INC DX   
@DoLoop:
   LOOP @MainLoop
   POP DS
   POP CX
   STI
End;

End;  {RAMTODRAM}
{$ENDIF}

{-------------------------------------------------------------------}

PROCEDURE Init_Panning;
Var i:Byte;
Begin
 With Musique^ do
    Begin
    M_CH_Panning[1]:=MMSS_Def_LeftPan;
    For i:=2 to Musique^.Ch_Number do
        If Odd(i DIV 2) Then M_CH_Panning[i]:=MMSS_Def_RightPan Else M_CH_Panning[i]:=MMSS_Def_LeftPan;
    End;
End;  {Init_Panning}

{-------------------------------------------------------------------}

PROCEDURE Convertir_Delta8(Var Tampon;Taille:Word);  Assembler;
ASM
   MOV AL,Byte(Ancien_Delta)
   MOV CX,Taille
   LES DI,Tampon
@Boucle_Delta:
   ADD AL,ES:[DI]
   STOSB
   LOOP @Boucle_Delta
   MOV Byte(Ancien_Delta),AL
End; {Convertir_Delta8}

{-------------------------------------------------------------------}

PROCEDURE Convertir_Delta16(Var Tampon;Taille:Word); Assembler;
ASM
   MOV AX,Ancien_Delta
   MOV CX,Taille
   SHR CX,1           { Buffer Real Size -> /2 }
   LES DI,Tampon
@Boucle_Delta:
   ADD AX,ES:[DI]
   STOSW
   LOOP @Boucle_Delta
   MOV Ancien_Delta,AX
End; {Convertir_Delta16}

{-------------------------------------------------------------------}

Function Panning_GUS_SB(Panning:Byte):Byte;
{ Panning 0-F -> Panning 0-$80 }
Var val:Byte;
Begin
If Panning>15 Then Panning:=15;
Val:=8*(Panning+1);
If Val=8 Then Val:=0;
Panning_GUS_SB:=Val;
End; {Panning_GUS_SB}

{-------------------------------------------------------------------}

PROCEDURE SMP_Load_RAM;  { Charge le sample dans la RAM }
VAR 
    j:Integer;
    SizeDone:Longint;
    LoadSize:Longint;
    PosFSample:Integer;
    Pointeur_Bouclage:Pointer;
    Pointeur_Fin:Pointer;
    Pointeur_Trans:Pointer;
    TailleTransFin:Integer;
    HoldBite:Shortint;
    SRep_Len:Word;

{$IFNDEF MMMONLY}
PROCEDURE Convertir16to8(Var Source,Destination;Taille,OffsetT:Word); Assembler; { Only used with Memory Load }
Asm
  PUSH DS
  MOV CX,Taille
  LDS SI,Source
  LES DI,Destination
  ADD DI,OffsetT
@Boucle_convert:
  INC SI
  MOVSB
  LOOP @Boucle_convert
  POP DS
End;
{$ENDIF}

Begin
{Writeln('Demande: ',((Smp.len+TailleFinSample) DIV 16)+2);}
With MMSS_Table^ do                                                                  {UMB,EMS}
If Not MMSS_MemAlloc(Pointeur_actuel,((Smp.len+TailleFinSample) DIV 16)+3,True,Avec_EMS) Then
   Begin   { Pas assez de m‚moire }
    INC(Nb_Pas_Charge);
    INC(Deplacement_pointeur_fichier,Smp.Len);
    If (Smp.Info And M_16Bit>0) Then INC(Deplacement_pointeur_fichier,Smp.Len);
   End
   Else  { Pas Erreur de m‚moire }
   Begin
    Smp.Mem.Segment:=SEG(Pointeur_actuel^);
    Smp.Mem.Handle_EMS:=Handle_EMS_Actuel;
    Smp.Mem.Nb_Pages_EMS:=Nb_Pages_EMS_Actuel;

    Ancien_Delta:=0; { Init the Delta conversion value }

{$IFNDEF MMMONLY} { No 16B Sample in MMM }
    If (Smp.Info AND M_16Bit)>0 Then
       Begin             { Convertir 16 bit => 8 Bit }
       New(Pointeur_Tampon_GUS);   { Allocate the temp buffer in TP Heap }
       SizeDone:=0;
       LoadSize:=Smp.Len SHL 1;
       While SizeDone < LoadSize  DO
         Begin
         If ((LoadSize-SizeDone) > SizeLBlock) THEN
              BlockSize := SizeLBlock
              ELSE
              BlockSize := LoadSize-SizeDone;

         f_module.Lit(Pointeur_Tampon_GUS^,BlockSize);
	     If (Smp.Info AND M_Delta)>0 Then 
		     BEGIN
			 {Writeln('Convertir_Delta16(Pointeur_Tampon_GUS^,BlockSize);');}
			 Convertir_Delta16(Pointeur_Tampon_GUS^,BlockSize);
			 End;
         Convertir16to8(Pointeur_Tampon_GUS^,Pointeur_actuel^,Blocksize SHR 1,SizeDone SHR 1);
         INC(SizeDone, BlockSize);

         End;
       Dispose(Pointeur_Tampon_GUS);
       Smp.Info:=Smp.Info AND Not (M_16Bit+M_Delta); { No more 16 Bit and Delta }
       End
       Else 
{$ENDIF}
	   f_module.Lit(Pointeur_actuel^,Smp.Len);  { Lire le sample dans le fichier }

{$IFNDEF MMMONLY} { No Delta and Signe in MMM }
    If (Smp.Info AND M_Delta)>0 Then 
	    Begin
		{Writeln('Convertir_Delta8(Pointeur_actuel^,Smp.Len);');}
		Convertir_Delta8(Pointeur_actuel^,Smp.Len);
		Smp.Info:=Smp.Info AND Not (M_Delta); { No More Delta }
		End;

    If Convertir_signe Then
       ASM
        PUSH DS
        MOV CX,WORD(Smp.len)
        LDS SI,Pointeur_actuel
        MOV AX,8080h
        SHR CX,1
        JNC @Boucle_convert
       @Boucle_convert:
        XOR [SI],AX
        ADD SI,2
        DEC CX
        JNE @Boucle_convert
        POP DS
       End;
    PosFSample:=0;
{$ENDIF}

{ Extend Sample end for a faster MIX }
    Pointeur_Fin:=Ptr(Seg(Pointeur_actuel^)+(Smp.Len) SHR 4,Ofs(Pointeur_actuel^)+(Smp.Len) MOD 16);
    If Smp_Rep_Fin=0 Then
       FillChar(Pointeur_Fin^,TailleFinSample,0)  { Extend Samples with no Loop with 0 }
       Else
       Begin                                      { Extend Samples with Loop }
       SRep_Len:=Smp.Rep_Len;
       PosFSample:=0;
       Pointeur_Bouclage:=Ptr(Seg(Pointeur_actuel^)+Smp.Rep SHR 4,Ofs(Pointeur_actuel^)+Smp.Rep MOD 16);
       Pointeur_Trans:=Pointeur_Fin;
       Repeat
       If SRep_Len>=TailleFinSample Then
          TailleTransFin:=TailleFinSample
          Else
          If PosFSample+SRep_Len<TailleFinSample Then
             TailleTransFin:=SRep_Len
             Else TailleTransFin:=TailleFinSample-PosFSample;
       PosFSample:=PosFSample+TailleTransFin;
       Move(Pointeur_Bouclage^,Pointeur_Trans^,TailleTransFin);
       Pointeur_Trans:=Ptr(Seg(Pointeur_Trans^)+TailleTransFin SHR 4,Ofs(Pointeur_Trans^)+TailleTransFin MOD 16);
       Until PosFSample>=TailleFinSample;

       End;    { Fin de l'extension du sample }
    Smp.Info:=(Smp.Info OR M_Charge);
    End;
End;  {SMP_Load_RAM}

{-------------------------------------------------------------------}
{$IFNDEF NoGUS}
PROCEDURE SMP_Load_GUS;

VAR IMemLoc:Longint;
    SizeDone:Longint;
    LoadSize:Longint;
    HoldByte:Byte;
    i:Integer;
    Test:Shortint;

Begin

With MMSS_Table^ do
Begin

If NOT UltraMemAlloc(Smp.Len+2,IMemLoc) Then
   Begin
   IMemLoc := 0;
   INC(Nb_Pas_Charge);
   INC(Deplacement_pointeur_fichier,Smp.Len);
   If (Smp.Info And M_16Bit>0) Then INC(Deplacement_pointeur_fichier,Smp.Len);
   End
  Else
  Begin
  Smp.Info:=(Smp.Info OR M_Charge);
  Smp.Adresse_GUS:=IMemLoc;
  LoadSize := Smp.Len;
  SizeDone := 0;
  Ancien_Delta:=0;

  WHILE SizeDone < LoadSize DO  { Boucle de chargement }
   BEGIN
   IF ((LoadSize-SizeDone) > SizeLBlock) THEN
        BlockSize := SizeLBlock
        ELSE
        BlockSize := LoadSize-SizeDone;

   f_module.Lit(Pointeur_Tampon_GUS^,BlockSize);

{$IFNDEF MMMONLY}    { No Delta, 16 Bit and Signed Samples }
   If (Smp.Info And M_Delta)>0 Then
      If (Smp.Info And M_16Bit)>0 Then
	     Begin
		 {Writeln('Convertir_Delta16(Pointeur_Tampon_GUS^,BlockSize)');}
         Convertir_Delta16(Pointeur_Tampon_GUS^,BlockSize)
		 End
         Else
		 Begin
		 {Writeln('Convertir_Delta8(Pointeur_Tampon_GUS^,BlockSize);');}
		 Convertir_Delta8(Pointeur_Tampon_GUS^,BlockSize);
		 End;

   IF Convertir_signe Then
      RAMTODRAM($80,IMemLoc+SizeDone)
       Else
{$ENDIF}
      RAMTODRAM(0,IMemLoc+SizeDone);
	  
   INC(SizeDone, BlockSize);
   END;
            { Set New Start Position }

  If (Smp.Info And M_16Bit>0) Then
    Begin
    If Smp_Rep_Fin>0 Then
       Begin
                 { Fin du bouclage:=Debut du bouclage }
       HoldByte := UltraPeekData(IMemLoc+Smp.Rep-1);
       UltraPokeData(IMemLoc+Smp_Rep_Fin,HoldByte);
       HoldByte := UltraPeekData(IMemLoc+Smp.Rep);
       UltraPokeData(IMemLoc+Smp_Rep_Fin,HoldByte);
       End
       Else
       Begin       { Fin+1 := Fin }
       HoldByte := UltraPeekData(IMemLoc+Smp.Len-2);
       UltraPokeData(IMemLoc+Smp.Len,HoldByte);
       HoldByte := UltraPeekData(IMemLoc+Smp.Len-1);
       UltraPokeData(IMemLoc+Smp.Len+1,HoldByte);
       End;
    End
    Else
    Begin
    If Smp_Rep_Fin>0 Then
       Begin
                   { Fin du bouclage:=Debut du bouclage }
       HoldByte := UltraPeekData(IMemLoc+Smp.Rep);
       UltraPokeData(IMemLoc+Smp_Rep_Fin,HoldByte);
       UltraPokeData(IMemLoc+Smp_Rep_Fin+1,HoldByte);
       End
       Else
       Begin       { Fin+1 := Fin }
       HoldByte := UltraPeekData(IMemLoc+Smp.Len-1);
       UltraPokeData(IMemLoc+Smp.Len,HoldByte);
       End;
    End;
  Smp.Info:=(Smp.Info OR M_Charge);
  End;
End;

End;  {SMP_Load_GUS}
{$ENDIF}
{-------------------------------------------------------------------}

PROCEDURE New_Sample;
Var Anc_Smp:Pointer;
Begin
FillChar(Smp,SizeOf(Smp),0); { CLeanup the Temp Sample }
If CHU_NSmp>1 Then
   Begin
   Anc_Smp:=MMSS_Table^.PtrSamples[CHU_NSmp-1];
   MMSS_Table^.PtrSamples[CHU_NSmp]:=Ptr(Seg(Anc_Smp^),Ofs(Anc_Smp^)+SizeOf(Smp));
   End;
End;  {New_Sample}

{-------------------------------------------------------------------}

FUNCTION Allouer_Samples(Nb_Samples:Byte):Boolean; { Allocate memory for the samples information tables }
Var Pointeur_Smp:Pointer;
    Taille_a_allouer:Longint;

Begin
CHU_NSmp:=0;
{ Fast Tracker 2, Allocate more memory for Samples }

If Musique^.Type_Module=T_XM Then Nb_Samples_Allocated:=Nb_Samples+Nb_Smp_Sup_XM
   Else Nb_Samples_Allocated:=Nb_Samples;
If Nb_Samples_Allocated > Max_Samples then Nb_Samples_Allocated:=Max_Samples;

Taille_a_allouer:=((Nb_Samples_Allocated*SizeOf(Smp)) DIV 16) +1;
   
IF Not MMSS_MemAlloc(Pointeur_Smp,Taille_a_allouer,True,False) Then
   Begin
   Erreur_de_chargement:=Err_Memoire;
   Allouer_Samples:=False;
   MMSS_Table^.PtrSamples[1]:=NIL;
   End
   Else
   Begin
   MMSS_Table^.PtrSamples[1]:=Pointeur_Smp;
   Allouer_Samples:=True;
   Musique^.Nb_Total_Samples:=Nb_Samples;
   {FillChar(Pointeur_Smp^,Taille_a_allouer*16,0);}

{ Allocate the samples names table }   
   Taille_a_allouer:=(24*Nb_Samples  DIV 16) +1;
    If Not MMSS_MemAlloc(Pointeur_Smp,Taille_a_allouer,True,False) Then
     Begin
      Erreur_de_chargement:=Err_Memoire;
      Allouer_Samples:=False;
     End
     Else
     Begin
      Musique^.PtrInstrNameTable:=Pointeur_Smp;
	  FillChar(Pointeur_Smp^,Taille_a_allouer*16,' ');
     End;  
   End;

End; {Allouer_Samples}

FUNCTION Allocate_Instruments(Nb_Instr:Byte):Boolean; { Allocate memory for the Instruments information tables }
Var Taille_a_allouer:Longint;

Begin
CHU_NSmp:=0;
Taille_a_allouer:=((Nb_Instr*8) DIV 16) +1;
IF Not MMSS_MemAlloc(pointer(PtrInstrument),Taille_a_allouer,True,False) Then
   Begin
    Erreur_de_chargement:=Err_Memoire;
    Allocate_Instruments:=False;
   End
   Else
   Begin
    FillChar(PtrInstrument^,Taille_a_allouer*16,0); { Clean the Instrument table }
    Musique^.Seg_Instr:=Seg(PtrInstrument^);
    Allocate_Instruments:=True;
   End;

End; {Allocate_Instruments}

{-------------------------------------------------------------------}

PROCEDURE Init_Charge_Sample;
Var i:Byte;
    adr_reelle:Longint;
    Segm,offs:Longint;
    Pointeur_Temp:Pointer;

Begin
 Nb_instruments:=0;
 Nb_Pas_charge:=0;

 { Pr‚paration pour le chargement dans la gravis }
{$IFNDEF NoGUS}
 If MMSS_CFG^.Wave_Output=GUS Then
     Begin
     {Clrscr;}
     Memoire_Gravis:=0;
     UltraMemInit;
     New(Pointeur_Tampon_GUS);   { Allouer la Tampon pour la Gravis }
                                 {Tampon de 32 Ko}
     End;
{$ENDIF}
End; {Init_Charge_Sample}

{-------------------------------------------------------------------}

PROCEDURE Ajuster_Sample;
Begin

{$IFDEF AFF}
Writeln('Avant Ajustement (Sample Nø',CHU_NSmp,')');
Write('Info: ',Smp.Info,' ');
If (Smp.Info And M_Charge)>0 Then Write('Charg‚ ');
If (Smp.Info And M_Bidi)>0 Then Write('Bidi ');
If (Smp.Info And M_Boucle)>0 Then Write('Boucle ');
If (Smp.Info And M_16Bit)>0 Then Write('16 bit ');
If (Smp.Info And M_Delta)>0 Then Write('Delta ');
Writeln;
Writeln('Smp.Len: ',Smp.Len);
Writeln('Smp.Rep: ',Smp.Rep);
Writeln('Smp.Rep_Len: ',Smp.Rep_Len);
Writeln('Smp_Rep_Fin: ',Smp_Rep_Fin);
Writeln('Volume: ',Smp.Volume);
Writeln('C4Spd: ',Smp.C4Spd);
Writeln('Rel Note: ',Smp.Rel_Note);
Writeln('Deplacement Fichier: ',Deplacement_Pointeur_Fichier);
{$ENDIF}

If Smp_Rep_fin>0 Then Smp.rep_len:=Smp_rep_fin-Smp.rep;  { BUG +1 enleve }

Deplacement_pointeur_fichier:=0;

{ Can't Load Sample >64Kb }
If (Smp.len>TailleMaxSample) And (MMSS_CFG^.Wave_Output<>GUS)
   Then  { Tester si sample >TailleMaxSample Octets }
   Begin
   Deplacement_Pointeur_fichier:=Deplacement_Pointeur_fichier+(Smp.len-TailleMaxSample);
   Smp.len:=TailleMaxSample;     { Couper le sample               }
   Smp.rep:=0;
   Smp.rep_Len:=0;
   Smp_rep_fin:=0;
   Smp.Info:=Smp.Info AND Not(M_Boucle); { Sample sans bouclage... }
   End;     { charger les TailleMaxSample Premiers octets }

{ Adjust Sample Loop }
If Smp_rep_fin>Smp.len Then
   Begin
   Smp_rep_fin:=Smp.len;{ Smp.fin et pas Smp.len !!! }
   Smp.rep_len:=Smp_rep_fin-Smp.rep;
   End;
   
If (Smp_rep_fin<3) OR (Smp.rep_len<3) OR (Smp.rep>(Smp.len-1)) Then
   Begin
   Smp.rep:=0; Smp_rep_fin:=0; Smp.rep_len:=0;
   End
   Else
   Begin
   If (Smp.Len)>Smp_Rep_fin Then     { Fin du sample=fin du bouclage }
      Begin
      Deplacement_Pointeur_fichier:=Smp.Len-Smp_Rep_fin;
      Smp.Len:=Smp_Rep_fin;
      End;
   Smp.Info:=Smp.Info OR M_Boucle; { Sample avec bouclage... }
   End;

End;  {Ajuster_Sample}

{-------------------------------------------------------------------}

PROCEDURE Charger_Sample;
VAR
  j:Integer;
  Inst:^T_Sample;
Begin
 Smp.Mem.Handle_EMS:=$FFFF;
{$IFNDEF MMMONLY}  
 Ajuster_Sample;
{$ENDIF}

If SamplFlags[CHU_NSmp] Then
  Begin
  Inc(Nb_instruments);
  If Smp.Len<>0 Then
{$IFNDEF NoGUS}
   If MMSS_CFG^.Wave_Output=GUS Then
       Begin
        If (Smp.Info And M_16Bit>0) Then  {Si instrument 16 bit, taille*2 ! }
           Begin
           Smp.Len:=Smp.Len SHL 1;
           Smp.Rep:=Smp.Rep SHL 1;
           Smp.Rep_Len:=Smp.Rep_Len SHL 1;
           Smp_Rep_Fin:=Smp_Rep_Fin SHL 1;
           SMP_Load_GUS;
           Smp.Len:=Smp.Len SHR 1;
           Smp.Rep:=Smp.Rep SHR 1;
           Smp.Rep_Len:=Smp.Rep_Len SHR 1;
           Smp.Adresse_GUS:=Smp.Adresse_GUS SHR 1;
           Smp_Rep_Fin:=Smp_Rep_Fin SHR 1;
           End
           Else SMP_Load_GUS;
       End
       Else 
{$ENDIF}	   
	   SMP_Load_RAM;
  End
  Else
  Begin  { Ne pas charger le sample => D‚placement dans le fichier... }
  Inc(Deplacement_pointeur_fichier,Smp.Len);
  If (Smp.Info And M_16Bit>0) Then Inc(Deplacement_pointeur_fichier,Smp.Len);
  End;

If Deplacement_pointeur_fichier>0 Then f_module.DeplacePointeur(Deplacement_pointeur_fichier);
   
            {Sauter un sample ou la fin d'un gros sample }

{$IFDEF AFF}
Writeln('AprŠs Ajuster (Sample Nø',CHU_NSmp,')');
Write('Info: ',Smp.Info,' ');
If (Smp.Info And M_Charge)>0 Then Write('Charg‚ ');
If (Smp.Info And M_Bidi)>0 Then Write('Bidi ');
If (Smp.Info And M_Boucle)>0 Then Write('Boucle ');
If (Smp.Info And M_16Bit)>0 Then Write('16 bit ');
If (Smp.Info And M_Delta)>0 Then Write('Delta ');
Writeln;
Writeln('Smp.Len: ',Smp.Len);
Writeln('Smp.Rep: ',Smp.Rep);
Writeln('Smp.Rep_Len: ',Smp.Rep_Len);
Writeln('Smp_Rep_Fin ',Smp_Rep_Fin);
Writeln('Volume: ',Smp.Volume);
Writeln('C4Spd: ',Smp.C4Spd);
Writeln('Rel Note: ',Smp.Rel_Note);
Writeln('Deplacement Fichier: ',Deplacement_Pointeur_Fichier);
Repeat until Readkey=#13;
{$ENDIF}

End;  { Charger_sample }

{-------------------------------------------------------------------}

PROCEDURE Fin_Charge_Sample;
Begin
{$IFNDEF NoGUS}
If MMSS_CFG^.Wave_Output=GUS Then
  Begin
  UltraMemClose;
  Dispose(Pointeur_Tampon_GUS);
  End;
{$ENDIF}  
Musique^.Nb_Samples:=Nb_instruments;
If Erreur_de_Chargement=Ok Then
   Begin
   If Nb_Pas_charge<>0 Then Erreur_de_chargement:=Err_Samples;
   If Nb_instruments-Nb_Pas_charge=0 Then Erreur_de_chargement:=Err_No_Sample;
   End;
Musique^.Nb_Samples_Loaded:=Nb_instruments-Nb_Pas_charge;

End;  {Fin_Charge_sample}

{-------------------------------------------------------------------}
PROCEDURE Compter_Voies;
Var i:Byte;
Begin
Musique^.Ch_Number_Digit:=0;
Musique^.Ch_Number_Adlib:=0;
For i:=1 to Musique^.Ch_Number do
    If Musique^.M_CH_Type[i]=1 Then INC(Musique^.Ch_Number_Digit)
       Else If Musique^.M_CH_Type[i]=2 Then INC(Musique^.Ch_Number_Adlib);
End;  {Compter_Voies}

{ Put 0 in the Pattern Size table if the pattern is not used }
{ Return the Highest pattern number+1                        }

FUNCTION Check_Used_Pattern:Byte;
Var i,NPatt:Byte;
BEGIN
NPatt:=0;
For i:=1 to Musique^.Sequence_Len do
    With Musique^ do
	 Begin
 {        Write(Sequence[i],',');}
	 If NPatt<Sequence[i] Then NPatt:=Sequence[i];
	 Taille_Pattern[Sequence[i]+1]:=64
	 End;
NPatt:=NPatt+1;
{Writeln('Nb Patt 2: ',NPatt);
Repeat until Readkey=#13;}
Check_Used_Pattern:=NPatt;
End;

{-------------------------------------------------------------------}

PROCEDURE Init_Module;  { Effacer les tables du module }
Var Inst:^T_Sample;
    i:Integer;

Begin

{Affiche_Mem;}
 MMSS_FreeMemory;

 With MMSS_Table^ do { Samples and Pattern Ptr Cleanup }
  Begin
   FillChar(Seg_Pattern,Sizeof(Seg_Pattern),0);
   FillChar(PtrSamples,Sizeof(PtrSamples),0);
  End;

{$IFNDEF MMMONLY}
 With Musique^ do
  Begin
   PtrInstrNameTable:=NIL; { Sample names Ptr Cleanup }
     
   FillChar(Musique^.Tempo_Pattern[1],Max_Pattern,0);
   FillChar(Titre,Sizeof(Titre),0);
   Vitesse_Ticks:=50;      { Nb de ticks par seconde }
   BPM_Start:=$7D;
   Tempo_Start:=6;
   Note_Size:=5;
   Volume_General_depart:=64;
   Volume_Sl_rapide:=False;
   Nb_Total_Samples:=0;
   Ch_Number:=0;
   Ch_Number_Digit:=0;
   Ch_Number_Adlib:=0;
   FillChar(Taille_Pattern,Max_Pattern,64);
   FillChar(M_CH_Type,Sizeof(M_CH_Type),0);
   FillChar(Voies_Adlib,11,0);
  End;
{$ENDIF}

 With MMSS_CFG^ do
  Begin
   OtherMUS_Ptr:=NIL;

   Panning_Utilisable:=(Wave_Output=GUS) OR ((Use_Panning_CMD And Utilise_Stereo) And (Wave_Output=SBPro));
   Calculer_Panning:=False;
   OtherMUS_DataEnd:=0;
   OtherMUS_Out:=0;    
  End;

 FillChar(SamplFlags,SizeOf(SamplFlags),0);
 Erreur_de_Chargement:=Ok;
 Convertir_signe:=False;
 MMSS_MUS_Loaded:=False;

{Affiche_Mem;}

End; {Init_Module}

END.