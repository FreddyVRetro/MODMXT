PROGRAM TestMMD;
{$A+,G+,Q-,R-,S-}

USES CRT,Clavier,Texte_V,Util,VGA,FFT_U,
     MMSS_Var,Modm_SS,MMSS_CMD,
     ChMOD,ChSTM,ChS3M,ChXM,ChMMM;

{$M 16384,0,56000}

{$UNDEF COL132}

CONST Freq=22100;  { Fr‚quence de sortie      }
      Vol=250;     { Volume de sortie   0-500 } {0-1024}
      Nb_Oct_Mod=7;

      repert_mod='C:\MOD\';
      Signed_XOR=0;

      {paramŠtres FFT}
      mode_FFT: Word=FFT_directe+FFT_trapeze+FFT_module;
      log2_taille_tampon_FFT=log2_nbr_points_max;
      taille_tampon_FFT=1 SHL log2_taille_tampon_FFT;
      ampl_FFT: Byte=4;


CMDChar:Array[0..40] of Array[1..6] of Char =
           (' ---- ','Arpegg','Porta','Porta','TonePr','Vibrat','TnPrVs','VibrVs',
            'Tremol','Panng ','SmpOff','VolSld','PosJmp','SetVol','PatBrk','-Ext.-',
            'Tempo ',' -E0- ','FineP','FineP','Gliss ','VibCtr','FineTn','LoopPt',
            'TreCtr',' -E8- ','Retrig','VolFn','VolFn','NotCut','NotDel','PatDel',
            'FunkIt','SetBPM','GlbVol','Tremor','FrqAdj','-ULTS-','-VbSw-','Rel   ','EFPort');
TYPE T_Oscillo=Array[0..639] of Shortint;


VAR erreur: Word;
    Nb_Voies_Aff: Byte;
    TailleDMAMin,TailleDMAMax: Word;
    PositionDMAMin,PositionDMAMax: Word;
    TPMin,TPMax: Word;
    TailleDMA,PositionDMA: Word;
    DMABuffAddr : Longint;
    i:Byte;
    KeyVal:Word;

    Type_Affichage: Byte;
    Afficher: Boolean;

    oscillo   : Record gauche,droite: T_Oscillo End;
    tampon_FFT: Record gauche,droite: T_FFT End;
    top_FFT,cpt_FFT: Longint;
    min_FFT,max_FFT: Byte;
    x_FFT: Word;

    DB_Offset : Word;
    DB_Size : Word;
    DB_16Bit : Boolean;



FUNCTION Lire_Taille_DMA(DMA:Byte):word; assembler;
ASM
    XOR  AL,AL
    OUT  0Ch,AL           { Clear flipflop }
    MOV  DL,DMA
    XOR  DH,DH
    SHL  DX,1
    INC  DX               { DX = channel * 2 + 1 = base counter }
    IN   AL,DX            { AL = lower byte }
    MOV  BL,AL
    IN   AL,DX            { AL = higher byte }
    MOV  BH,AL
    MOV  AX,BX            { AX = high and low part together ;) - return that }
                          { bytes left to send = ax + 1 }
END;

FUNCTION Lire_DMA_Page1:word; ASSEMBLER;
ASM
    XOR AL,AL
    OUT 0Ch,AL           { clear flipflop }

    MOV DX,83h
    IN  AL,DX            { al = lower byte           }
    XOR AH,AH
END;

FUNCTION Lire_DMA_Page5:word; ASSEMBLER;
ASM
    XOR AL,AL
    OUT 0Ch,AL           { clear flipflop }

    MOV DX,83h
    IN  AL,DX            { al = lower byte           }
    XOR AH,AH
END;


FUNCTION Read_DMA_Offset(DMA:Byte):word; ASSEMBLER;
ASM
    XOR  AL,AL
    OUT  0Ch,AL           { clear flipflop }
    MOV  DL,DMA
    XOR  DH,DH
    SHL  DX,1
                          { dx = channel * 2 = Offset }
    IN   AL,DX            { al = lower byte           }
    MOV  BL,AL
    IN   AL,DX            { al = higher byte          }
    MOV  BH,AL
    MOV  AX,BX            { AX = high and low part together ;) - return that }
                          { bytes left to send = ax + 1                      }
END;

FUNCTION Lire_Position_DMA5:word; ASSEMBLER;
ASM
    XOR  AL,AL
    OUT  0D8h,AL           { clear flipflop 0D8h: DMA 5}
    MOV  DL,1

	MOV DX,0C4h           { 0C4h :  DMA 5 Addr }
                          { dx = channel * 2 = Offset }
    IN   AL,DX            { al = lower byte           }
    MOV  BL,AL
    IN   AL,DX            { al = higher byte          }
    MOV  BH,AL
    MOV  AX,BX            { AX = high and low part together ;) - return that }
                          { bytes left to send = ax + 1                      }
END;

PROCEDURE Display_Main_Infos;
BEGIN
 If Afficher Then
   Begin
   InitTexte(50);   
   AffChXY(0,2,1,'Freq: '+EntierTexte(Freq,4),7);

  If MMSS_CFG^.Mix_16Bit then AffChXY(0,14,1,'Mix: 16bit',7)
                          else AffChXY(0,14,1,'Mix: 8bit',7);

  If MMSS_CFG^.Out_16Bit then AffChXY(0,24,1,'Out: 16bit',7)
                          else AffChXY(0,24,1,'Out: 8bit',7);

  If MMSS_CFG^.Utilise_Stereo then AffChXY(0,34,1,'Stereo',7)
                               else AffChXY(0,34,1,'Mono',7);
   AffChXY(0,2,3,'Row:',2);
   AffChXY(0,10,3,'Seq/Patt:   /',2);
   AffChXY(0,27,3,'GVol: ',2);
   AffChXY(0,36,3,'Tempo:',2);
   AffChXY(0,50,3,'BPM:',2);
   End;
 AffChXY(0,6,3,EntierTexte( MMSS_Info^.Pos_Note,3),7);
 AffChXY(0,19,3,EntierTexte( MMSS_Info^.Pos_Sequence,3),7);
 AffChXY(0,23,3,EntierTexte( MMSS_Info^.Num_Pattern,3),7);
 AffChXY(0,32,3,EntierTexte( MMSS_Info^.Volume_General,2),7);
 AffChXY(0,41,3,EntierTexte( MMSS_Info^.Tempo,4)+'/'+EntierTexte( MMSS_Info^.Cmpt_tempo,3),3);
 AffChXY(0,55,3,EntierTexte( MMSS_Info^.BPM,4)+'/'+EntierTexte( MMSS_Info^.Cmpt_BPM,3),3);
 
 AffChXY(0,70,1,EntierTexte(TP_Chrono_min,2),7);
 AffChXY(0,73,1,EntierTexte(TP_Chrono_sec,2),7);


End;

PROCEDURE Afficher_Vars;
BEGIN

 If Afficher Then
  Begin
   Afficher:=False;
   InitTexte(50);   
   With Musique^ do
    Begin
	 Writeln('Musique^');
     Writeln('Ch_Number: ',Ch_Number,' Ch_Number_patt: ',Ch_Number_patt,' Ch_Number_Digit:',Ch_Number_Digit,
             ' Ch_Number_Adlib: ',Ch_Number_Adlib);
     Writeln('Note_Delta: ',Note_Delta,' C_Pattern: ',C_Pattern,' Note_Size : ',Note_Size);
     Writeln('Nb_Instr: ',Nb_Instr,' Nb_Total_Samples: ',Nb_Total_Samples,' Nb_Samples: ',Nb_Samples,
             ' Nb_Reel_Samples: ',Nb_Reel_Samples);
     Writeln('Sequence_Len: ',Sequence_Len,' Pos_de_restart: ',Pos_de_restart,' Tempo_depart: ',Tempo_Start,
	         ' BPM_depart: ',BPM_Start,' Volume_General_depart: ',Volume_General_depart);
     Writeln('Octave_Min: ',Octave_Min,' Octave_Max: ',Octave_Max,' Type_Module: ',Type_Module,
             ' Volume_Sl_rapide: ',Volume_Sl_rapide,' Vitesse_Ticks: ',Vitesse_Ticks);
     Writeln('Seg_Instr: ',Seg_Instr, ' PtrInstrNameTable ');
     {PtrInstrNameTable : ^T_InstrNameTable;}
     Write ('Type_Voie: ');
     For i:=1 to Max_Channels do Write(M_Ch_Type[i],',');
     Writeln;
     Write ('Voies_Adlib: ');
     For i:=1 to 11 do Write(Voies_Adlib[i],',');
     Writeln;
     Write ('Sequence: ');
     For i:=1 to Max_Channels do Write(Sequence[i],',');
     Writeln;
     Write ('Taille_Pattern: ');
     For i:=1 to Max_Channels do Write(Taille_Pattern[i],',');
     Writeln;
    End;
	
	With MMSS_Table^ do
	  Begin
	  Writeln;
	  Writeln('MMSS_Table^');
      Write ('Seg_Pattern: ');
	  For i:=1 to Max_Channels do Write(EntierHexa(Seg_Pattern[i],4),',');
	  End;
	

 End;

End;

PROCEDURE Afficher_Infos;
BEGIN

Display_Main_Infos;

 If Afficher Then
  Begin
   Afficher:=False;

   AffChXY(0,2,5,'Out Buffer @   : '+EntierHexa(MMSS_CFG^.Seg_Table_Volume,4)+':'
                                    +EntierHexa(MMSS_CFG^.Offset_DMA_Buffer,4),2);
   AffChXY(0,18,6,'='+EntierHexa(DMABuffAddr,5),2);
   AffChXY(0,2,7,'Mix Buffer Size: '+EntierTexte( MMSS_Info^.Buffer_Size,4),2);
   AffChXY(0,2,8,'Mix Buffer Nb  :',2);
   AffChXY(0,2,9,'Mix Buffer Ind :',2);

   AffChXY(0,32,5,'DMA Offs Min :',2);
   AffChXY(0,32,6,'DMA Offs Max :',2);
   AffChXY(0,32,8,'DMA Buff Size: '+EntierTexte( MMSS_Info^.Taille_Sortie_DMA,3),2);
   AffChXY(0,32,9,'DMA Index    :',2);
 {  AffChXY(0,2,15,'Offset Tampon2 : '+EntierTexte(MMSS_CFG^.Offset_Tampon2,4),2);}
 {  AffChXY(0,40,2,'Buffer Size:',2); }
 {  AffChXY(0,40,3,'Taille DMA Mesuree:',2);
    AffChXY(0,40,4,'Position DMA:',2); }

    {AffChXY(0,40,7,'Diff Adresses:',2);}
	

	

  End;

 {AffChXY(0,60,2,EntierTexte(TailleDMA,2)+'  ',7);
 AffChXY(0,60,3,EntierTexte(TailleDMAMax,3)+'  ',7);

 AffChXY(0,60,5,EntierTexte(PositionDMA,4)+'  ',7);}
 {AffChXY(0,60,8,EntierTexte(PositionDMAMax-PositionDMAMin,5)+' ',7);}
 
 AffChXY(0,60,8,EntierTexte(MMSS_Volume,3),3);
 AffChXY(0,60,9,EntierTexte(MMSS_Adj_Volume,3),3);

 AffChXY(0,19,8,EntierTexte(MMSS_Info^.Tampon_Actif,1),3);
 AffChXY(0,19,9,EntierHexa (MMSS_Info^.Pointeur_Tampon_Joue,4),3);
 
 AffChXY(0,47,5,EntierHexa(PositionDMAMin,4),7);
 AffChXY(0,47,6,EntierHexa(PositionDMAMax,4),7); 
 AffChXY(0,47,9,EntierHexa(Read_DMA_Offset(1),4),3);
 {AffChXY(0,47,9,EntierHexa(Lire_DMA_Page5,4),3);
 AffChXY(0,52,9,EntierHexa(Lire_Position_DMA5,4),3);}
 
  AffChXY(0,2,10,EntierHexa(MMSS_CFG^.Offset_Left_Buffer,4),3);
  AffChXY(0,2,11,EntierHexa(MMSS_CFG^.Offset_Right_Buffer,4),3);

End;


Procedure Afficher_Voies;
Var i: Byte;
Begin

 Display_Main_Infos;

 If Afficher Then
  Begin
   Afficher:=False;   
   AffChXY(0,1,10,'Smp Vl Vf Nt Per  C4Ad  Incr  Offs  Pan Ctr Command',5);
   
  End;

{ Chrono }

 For i:=1 to Nb_Voies_Aff do
  Begin
   AffChXY(0,1,11+i,EntierTexte( MMSS_Info^.Ch_Smp_Pla[i],3),3);
   AffChXY(0,5,11+i,EntierTexte( MMSS_Info^.VVolume[i],2),3);
   AffChXY(0,8,11+i,EntierTexte( MMSS_Info^.VVolume_re[i],2),3);
   AffChXY(0,10,11+i,EntierTexte( MMSS_Info^.Ch_Note[i],3),3);
   AffChXY(0,14,11+i,EntierHexa( MMSS_Info^.CH_Per_part[i],3),3);
   AffChXY(0,19,11+i,EntierTexte( MMSS_Info^.VDadj[i],4),3);
   AffChXY(0,24,11+i,EntierHexa( MMSS_Info^.VPart_entiere[i],2),3);
   AffChXY(0,26,11+i,EntierHexa( MMSS_Info^.VPart_decimaleh[i],2),3);
   AffChXY(0,28,11+i,EntierHexa( MMSS_Info^.VPart_decimalel[i],2),3);   
   AffChXY(0,31,11+i,EntierHexa( MMSS_Info^.VOffset_Actuel[i],4),3);
   AffChXY(0,37,11+i,EntierTexte( MMSS_Info^.CH_Panning[i],2),3);
   AffChXY(0,40,11+i,EntierTexte( MMSS_Info^.GUS_Controle[i],3),3);
   AffChXY(0,44,11+i,EntierTexte( MMSS_Info^.VCurrent_CMD[i],3),3);
   AffChXY(0,48,11+i,CMDChar[ MMSS_Info^.VCurrent_CMD[i]],3);
   AffChXY(0,55,11+i,EntierHexa( MMSS_Info^.VCurrent_PAR[i],2),3)

  End;
End;

Procedure Afficher_Samples;
Var i,CHU_NSmp: Byte;
    
Begin

Display_Main_Infos;

 If Musique^.Nb_Total_Samples>40 then CHU_NSmp:=40 else CHU_NSmp:=Musique^.Nb_Total_Samples;

 If Afficher Then
  Begin
   Afficher:=False;
   AffChXY(0,1,6,'Smp Inf Vl  Len   Rep  RepL  C4Ad Addr  EMS   GUS  Name',5);

   AffChXY(0,1,5,'Instr:    Samples Total:    Samples Loaded:',6);
   AffChXY(0,7,5,EntierTexte(Musique^.Nb_Instr,3),3);
   AffChXY(0,25,5,EntierTexte(Musique^.Nb_Total_Samples,3),3);
   AffChXY(0,44,5,EntierTexte(Musique^.Nb_Reel_Samples,3),3);
  End;

 For i:=1 to CHU_NSmp do
  Begin
   With MMSS_Table^.PtrSamples[i]^ do
    Begin
	If (Info And M_Adlib)=1 then
	   BEGIN
	    AffChXY(0,1,6+i,EntierTexte(i,2),3);
	    AffChXY(0,1,6+i,'Adlib',3);
	   End
	   else
           Begin
	    If (Info And M_16Bit)=1 then AffChXY(0,70,6+i,'16b',3);
            AffChXY(0,2,6+i,EntierTexte(i,2),3);
            AffChXY(0,5,6+i,EntierTexte(Info,2),3);
            AffChXY(0,9,6+i,EntierTexte(Volume,2),3);
            AffChXY(0,11,6+i,EntierTexte(Len,6),3);
            AffChXY(0,17,6+i,EntierTexte(Rep,6),3);
            AffChXY(0,23,6+i,EntierTexte(Rep_Len,6),3);
            AffChXY(0,30,6+i,EntierTexte(C4Spd,4),3);
            AffChXY(0,35,6+i,EntierHexa(Mem.Segment,4),3);

            If Mem.Handle_EMS=65535 then AffChXY(0,40,6+i,'N/A',3)
               Else AffChXY(0,40,6+i,EntierTexte(Mem.Handle_EMS,3),3);
            AffChXY(0,43,6+i,EntierTexte(Mem.Nb_Pages_EMS,2),3);

            AffChXY(0,46,6+i,EntierHexa(Adresse_GUS,5),3);
	    AffChXY(0,52,6+i,Musique^.PtrInstrNameTable^[i],6)
	   end;
    End;

{   AffChXY(0,1,16+i,EntierTexte( MMSS_Info^.VSample[i],3),3);
   AffChXY(0,5,16+i,EntierTexte( MMSS_Info^.VVolume[i],2),3);
   AffChXY(0,8,16+i,EntierTexte( MMSS_Info^.VVolume_re[i],2),3);
   AffChXY(0,10,16+i,EntierTexte( MMSS_Info^.Ch_Note[i],3),3);
   AffChXY(0,14,16+i,EntierHexa( MMSS_Info^.CH_Per_part[i],3),3);
   AffChXY(0,19,16+i,EntierTexte( MMSS_Info^.VDadj[i],4),3);
   AffChXY(0,24,16+i,EntierHexa( MMSS_Info^.VPart_entiere[i],2),3);
   AffChXY(0,26,16+i,EntierHexa( MMSS_Info^.VPart_decimale[i],4),3);
   AffChXY(0,32,16+i,EntierHexa( MMSS_Info^.VOffset_Actuel[i],4),3);
   AffChXY(0,36,16+i,EntierTexte( MMSS_Info^.CH_Panning[i],2),3);
   AffChXY(0,38,16+i,EntierTexte( MMSS_Info^.GUS_Controle[i],3),3);}
  End;

End;

PROCEDURE Init640x480; Assembler;
ASM
 MOV AX,gr640x480_16c
 INT 10h
End;


PROCEDURE Point(x,y: Word; couleur: Byte); Assembler;
{640x480 16c}
ASM
 MOV AX,0A000h
 MOV ES,AX

 MOV AX,y
 MOV DX,80
 MUL DX
 MOV BX,x
 MOV CL,BL
 SHR BX,3
 ADD BX,AX

 AND CL,00000111b
 XOR CL,00000111b
 MOV AH,1
 SHL AH,CL

 MOV DX,GraphControl
 MOV AL,BitMask
 OUT DX,AX
 MOV AX,(00000010b SHL 8)+GraphicsMode
 OUT DX,AX

 MOV AL,ES:[BX]
 MOV AL,couleur
 MOV ES:[BX],AL

{ MOV AX,(11111111b SHL 8)+BitMask
 OUT DX,AX
 MOV AX,(00000000b SHL 8)+GraphicsMode
 OUT DX,AX}
End;


PROCEDURE Afficher_Oscillo;

Var i: Word;
    c: Byte;
	x0:Word;
	Offset_Buffer:WORD;

Begin
 If Afficher {or ( MMSS_Info^.Pos_Note Mod  MMSS_Info^.Tempo=0)} Then
  Begin
   Afficher:=False;
   Init640x480;
  End;

Offset_Buffer:= MMSS_Info^.Pointeur_Tampon_Joue;

x0:=(639-MinEntier(639, MMSS_Info^.Buffer_Size-1)) DIV 2;

If MMSS_CFG^.Utilise_stereo Then
    Begin
    With MMSS_CFG^ do
      For i:=0 to MinEntier(639, MMSS_Info^.Buffer_Size-1) do
      Begin
       Point(i,120+oscillo.gauche[i],8);
       Point(i,360+oscillo.droite[i],8);
       Point(i,120,7);
       Point(i,360,7);

       oscillo.gauche[i]:=Mem[Seg_Table_Volume:Offset_DMA_Buffer+2*i  ]-Signed_XOR;
       oscillo.droite[i]:=Mem[Seg_Table_Volume:Offset_DMA_Buffer+2*i+1]-Signed_XOR;

       Case Abs(oscillo.gauche[i]) of
         0.. 49: c:=10;
        50.. 79: c:=14;
        80..128: c:=12;
       End;
       Point(i,120+oscillo.gauche[i],c);

       Case Abs(oscillo.droite[i]) of
         0.. 49: c:=10;
        50.. 79: c:=14;
        80..128: c:=12;
       End;
       Point(i,360+oscillo.droite[i],c);
      End;
    End
    Else
    Begin
    With MMSS_CFG^ do
      For i:=0 to MinEntier(639, MMSS_Info^.Buffer_Size-1) do
      Begin
       Point(i+x0,240+oscillo.gauche[i],0);
       Point(i+x0,240,7);

       If Out_16Bit then oscillo.gauche[i]:=Mem[Seg_Table_Volume:Offset_Buffer+2*i+1]-Signed_XOR
	      Else oscillo.gauche[i]:=Mem[Seg_Table_Volume:Offset_Buffer+i]-Signed_XOR;

       Case Abs(oscillo.gauche[i]) of
         0.. 49: c:=10;
        50.. 79: c:=14;
        80..128: c:=12;
       End;
       Point(i+x0,240+oscillo.gauche[i],c);
      End;
   End;

End;


PROCEDURE Display_Buffer_GFX;

Var i: Word;
    c: Byte;
	x0:Word;
	Offset_Buffer:WORD;

Begin
 If Afficher {or ( MMSS_Info^.Pos_Note Mod  MMSS_Info^.Tempo=0)} Then
  Begin
   Afficher:=False;
   Init640x480;
  End;

x0:=(639-MinEntier(639,DB_Size-1)) DIV 2;

For i:=0 to MinEntier(639,DB_Size-1) do
    Begin
     Point(i+x0,240+oscillo.gauche[i],0);

     If DB_16Bit then oscillo.gauche[i]:=Mem[MMSS_CFG^.Seg_Table_Volume:(DB_Offset+2*i+1)]
	      Else oscillo.gauche[i]:=Mem[MMSS_CFG^.Seg_Table_Volume:(DB_Offset+i)];

     Point(i+x0,240+oscillo.gauche[i],10);
    End;

End;


PROCEDURE Afficher_SpectreTexte;

Const hauteur_barre_max=24;
      valeur_max=64;

Var temps,position: Word;
    fenetre: String[8];
    i,FFT_par_sec: Byte;


Procedure AffSpectre(x,y: Byte; spectre: T_FFT_module); Assembler;
ASM
 PUSH DS

 MOV DX,0B800h
 MOV ES,DX

 XOR DH,DH
 MOV DL,largeur_ecran_txt

 XOR AH,AH
 MOV AL,x
 MOV DI,AX
 DEC DI
 MOV AL,y
 DEC AL
 MUL DL
 ADD DI,AX
 SHL DI,1            {ES:DI -> B800:2*((x-1)+largeur_ecran_txt*(y-1))}

 SHL DX,1            {DX=2*largeur_ecran_txt}

 LDS SI,spectre

 {$IFDEF COL132}
 MOV CH,taille_tampon_FFT/2
 {$ELSE}
 MOV CH,80
 {$ENDIF}
@boucle_barres:
  PUSH DI

  MOV AL,'ð'

  MOV CL,[SI]
  OR  CL,CL
  JZ  @barre_gris
  XOR BX,BX
 @boucle_barre_couleur:
   MOV AH,Byte(CS:[@couleurs+BX])
   MOV Word(ES:[DI]),AX
   SUB DI,DX
   INC BL
   DEC CL
  JNZ @boucle_barre_couleur

 @barre_gris:
  MOV CL,hauteur_barre_max
  SUB CL,[SI]
  OR  CL,CL
  JZ  @fin_barre
  MOV AH,8
 @boucle_barre_gris:
   MOV Word(ES:[DI]),AX
   SUB DI,DX
   DEC CL
  JNZ @boucle_barre_gris

 @fin_barre:
  ADD SI,2
  POP DI
  ADD DI,2
  DEC CH
 JNZ @boucle_barres

 JMP @fin

@couleurs:
 DB 10,10,10,10,10,10
 DB 10,10,10,10,10,10
 DB 14,14,14,14,14,14
 DB 12,12,12,12,12,12

@fin:
 POP DS
End;


Begin
 If Afficher Then
  Begin
   Afficher:=False;
   {$IFDEF COL132}
   InitTexte132(50);
   {$ELSE}
   InitTexte(50);
   {$ENDIF}
   cpt_FFT:=0;
   top_FFT:=(TP_Chrono_sec+60*WORD(TP_Chrono_min));
   min_FFT:=255;
   max_FFT:=0;
  End;

 If (Timer AND $3F)=0 Then
  Begin
   cpt_FFT:=0;
   top_FFT:=(TP_Chrono_sec+60*WORD(TP_Chrono_min));
   min_FFT:=255;
   max_FFT:=0;
  End;

 With MMSS_CFG^,tampon_FFT do
  Begin
   AffChXY(0,1,1,'DMA Buffer Size:'+EntierTexte2( MMSS_Info^.Buffer_Size,4)+
                 ' Active='+EntierTexte2( MMSS_Info^.Tampon_Actif,1)+
                 ' @0='+EntierHexa(Seg_Table_Volume,4)+
                    ':'+EntierHexa(Offset_DMA_Buffer,4)+
                 ' @1='+EntierHexa(Seg_Table_Volume,4)+
                    ':'+EntierHexa(Offset_DMA_Buffer,4),7);

   AffChXY(0,62,1,EntierTexte2(TP_Chrono_min,et_zeros+2)+':'+
                  EntierTexte2(TP_Chrono_sec,et_zeros+2),11);

   Case mode_FFT AND (FFT_rect+FFT_trapeze+FFT_hanning) of
    FFT_rect   : fenetre:='rectang';
    FFT_trapeze: fenetre:='trapeze';
    FFT_hanning: fenetre:='hanning';
   End;
   AffChXY(0,70,1,'Window='+fenetre+
                 ' Amplitude='+EntierTexte2(ampl_FFT,2),15);

   temps:=(TP_Chrono_sec+60*WORD(TP_Chrono_min))-top_FFT;
   If temps<>0 Then
    Begin
     FFT_par_sec:=(50*cpt_FFT) Div temps;
     If FFT_par_sec<min_FFT Then min_FFT:=FFT_par_sec;
     If FFT_par_sec>max_FFT Then max_FFT:=FFT_par_sec;
     AffChXY(0,100,1,EntierTexte2(FFT_par_sec,3)+' FFT/sec.'+
                     ' min='+EntierTexte2(min_FFT,3)+
                     ' max='+EntierTexte2(max_FFT,3),15);
    End;

   {‚chantillonne le tampon DMA … taille_tampon_FFT points}
   For i:=0 to taille_tampon_FFT-1 do
    Begin
     position:=2*((i* MMSS_Info^.Buffer_size) Div taille_tampon_FFT);
     gauche.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position  ]-128);
     droite.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position+1]-128);
    End;
   { ^^ … refaire en ASM avec des ADD/ADC... }

   {calcule les FFT gauche & droite}
   FFT(mode_FFT,gauche,log2_taille_tampon_FFT);
   Inc(cpt_FFT);
   FFT(mode_FFT,droite,log2_taille_tampon_FFT);
   Inc(cpt_FFT);

   {normalise et ‚crŠte les modules}
   For i:=0 to (taille_tampon_FFT Div 2)-1 do
    Begin
     gauche.module[i]:=MinEntier((gauche.module[i]*hauteur_barre_max) Div valeur_max,hauteur_barre_max);
     droite.module[i]:=MinEntier((droite.module[i]*hauteur_barre_max) Div valeur_max,hauteur_barre_max);
    End;

   {affiche les barres de spectre}
   AffSpectre(1,25,gauche.module);
   AffSpectre(1,50,droite.module);
  End;
End;


PROCEDURE Afficher_SpectreGraphique;

Const hauteur_barre_max=48;
      valeur_max=64;

      pal_FFT: Palette16=(palette:(
             (R: 0; V: 0; B: 0),
             (R: 0; V:10; B:40),
             (R: 0; V:15; B:50),
             (R: 0; V:20; B:60),
             (R: 0; V:30; B:60),
             (R: 0; V:35; B:50),
             (R: 0; V:35; B:40),
             (R: 0; V:45; B:40),
             (R: 0; V:50; B:30),
             (R: 0; V:60; B:20),
             (R:35; V:60; B: 0),
             (R:50; V:60; B: 0),
             (R:60; V:60; B: 0),
             (R:60; V:50; B: 0),
             (R:60; V:35; B: 0),
             (R:60; V:10; B: 0)
            ));

Var i,j: Byte;
    position: Word;

Begin
 If Afficher Then
  Begin
   Afficher:=False;
   Init640x480;

   {initialise la palette 16 couleurs}
   For i:=0 to 15 do FixeDAC(i,pal_FFT.palette[i]);
  End;

 With MMSS_CFG^,tampon_FFT do
  Begin
   {‚chantillonne le tampon DMA … taille_tampon_FFT points}
   For i:=0 to taille_tampon_FFT-1 do
    Begin
     position:=2*((i* MMSS_Info^.Buffer_Size) Div taille_tampon_FFT);
     gauche.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position  ]-128);
     droite.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position+1]-128);
    End;

   {calcule les FFT gauche & droite}
   FFT(mode_FFT,gauche,log2_taille_tampon_FFT);
   FFT(mode_FFT,droite,log2_taille_tampon_FFT);

   {normalise et ‚crŠte les modules}
   For i:=0 to (taille_tampon_FFT Div 2)-1 do
    Begin
     gauche.module[i]:=MinEntier((gauche.module[i]*hauteur_barre_max) Div valeur_max,hauteur_barre_max);
     droite.module[i]:=MinEntier((droite.module[i]*hauteur_barre_max) Div valeur_max,hauteur_barre_max);
    End;

   {affiche le spectre graphique}
   For i:=0 to (taille_tampon_FFT Div 2)-1 do
    Begin
     For j:=1 to gauche.module[i] do Point(256+i,239-j,MinEntier((Word(j)*15) Div hauteur_barre_max,15));
     For j:=1+gauche.module[i] to hauteur_barre_max do Point(256+i,239-j,0);

     For j:=1 to droite.module[i] do Point(256+i,240+j,MinEntier((Word(j)*15) Div hauteur_barre_max,15));
     For j:=1+droite.module[i] to hauteur_barre_max do Point(256+i,240+j,0);
    End;
   { ^^ c'est TRES lent !! -> optimiser un peu tout ‡a... }

  End;
End;


PROCEDURE Afficher_SpectreProgressif;

Const valeur_max=64;

Var i: Byte;
    comp: RVB;
    position: Word;

Begin
 If Afficher Then
  Begin
   Afficher:=False;
   Init640x480;

   x_FFT:=0;

   {initialise la palette 16 couleurs}
   For i:=1 to 15 do With comp do
    Begin
     R:=3+4*i;
     V:=18+3*i;
     B:=20;
     FixeDAC(i,comp);
    End;
  End;

 With MMSS_CFG^,tampon_FFT do
  Begin
   {‚chantillonne le tampon DMA … taille_tampon_FFT points}
   For i:=0 to taille_tampon_FFT-1 do
    Begin
     position:=2*((i* MMSS_Info^.Buffer_Size) Div taille_tampon_FFT);
     gauche.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position  ]-128);
     droite.points[i]:=ampl_FFT*(Mem[Seg_Table_Volume:Offset_DMA_Buffer+position+1]-128);
    End;

   {calcule les FFT gauche & droite}
   FFT(mode_FFT,gauche,log2_taille_tampon_FFT);
   FFT(mode_FFT,droite,log2_taille_tampon_FFT);

   {normalise et ‚crŠte les modules}
   For i:=0 to (taille_tampon_FFT Div 2)-1 do
    Begin
     gauche.module[i]:=MinEntier((gauche.module[i]*15) Div valeur_max,15);
     droite.module[i]:=MinEntier((droite.module[i]*15) Div valeur_max,15);
    End;

   {affiche le spectre graphique progressif}
   For i:=0 to (taille_tampon_FFT Div 2)-1 do
    Begin
     Point(x_FFT,239-i,gauche.module[i]);
     Point(x_FFT,240+i,droite.module[i]);
    End;

   x_FFT:=(x_FFT+1) Mod 640;
  End;
End;

BEGIN
 TailleDMAMax:=0;
 TailleDMAMin:=$FFFF;
 PositionDMAMax:=0;
 PositionDMAMin:=$FFFF;
 Type_Affichage:=1;
 Afficher:=True;
 Nb_Octaves_MOD:=Nb_Oct_MOD;

{ Init the Sound Output before loading the music }
 {
 Writeln('Sound Blaster Pro, 21700KHz, Mono'); 
 MMSS_CFG^.Frequence:=44100;
 MMSS_CFG^.Sortie_Sonore:=GUS;
 MMSS_CFG^.Utilise_DMA:=True;
 MMSS_CFG^.Utilise_DC:=True;
 MMSS_CFG^.Utilise_Stereo:=False;
 MMSS_CFG^.Mix_16Bit:=False;
 MMSS_CFG^.Utiliser_Interpolation:=False;
 MMSS_CFG^.Calculer_Panning:=True;}

{ Init the Mod MAster variables }
 MMSS_Volume:=Vol;
 MMSS_Def_LeftPan:=$20;   { Default left panning }
 MMSS_Def_RightPan:=$80;   { Default right Panning }


 Writeln('Loading ',repert_mod,'STARDUST.MOD');

 
 {Charge_mod('C:\TEMP\TESTFFT.MOD',Erreur);}
 {Charge_mod(repert_mod+'AMBPOWER.MOD',Erreur);}
 {Charge_mod(repert_mod+'AUTOWASC.MOD',Erreur);}
 {Charge_mod(repert_mod+'DESERT.MOD'  ,Erreur);}
 {Charge_mod(repert_mod+'ELYSIUM.MOD' ,Erreur);}

 {Charge_mod(repert_mod+'CD2PART1.MOD',Erreur);}
 {Charge_mod(repert_mod+'DOPE.MOD',Erreur);}
 {Charge_xm(repert_mod+'DOPE2.XM',Erreur);}
 {Charge_s3m(repert_mod+'future_d.S3M',Erreur);} { BUG the First time }
 {Charge_mod(repert_mod+'ENIGMA.MOD',Erreur);}
 {charge_s3m(repert_mod+'future_d.S3M',Erreur); }{ BUG the First time }
  {Charge_s3m(repert_mod+'CHARIOT.S3M',Erreur);} { BUG the First time }
 {Musique^.Nb_Instr:=18;}
 {Charge_mod(repert_mod+'ELYSIUM.MOD',Erreur);}
 {Charge_mod(repert_mod+'STARDUST.MOD',Erreur);}
 
{ Charge_mmm(repert_mod+'STARDUS2.MMM',Erreur);}
  Charge_mod(repert_mod+'STARDUST.MOD',Erreur);

 { Charge_mod(repert_mod+'IRISH.MOD',Erreur);}
 {Charge_SAT(repert_mod+'AMEGAS.SAT'   ,Erreur);  }
 {Charge_669(repert_mod+'ELEMENT.669' ,Erreur);}

 If Erreur<>0 then Halt;

 {Init Buffer / Table Display var }
 DB_Offset := 0;
 DB_16Bit  := MMSS_CFG^.Mix_16Bit;
 If DB_16Bit then DB_Size:=512
    Else DB_Size:=256;

{ Erreur_Modm(Erreur); }

 Erreur:=0;
 If MMSS_MUS_Loaded Then
  Begin
  Erreur:=MMSS_Start_Music;                   { Init the Module Variables }
  If Erreur=Ok Then Erreur:=MMSS_Start_Output;  { Start the Module }
  End;
 
 DMABuffAddr:=Longint(MMSS_CFG^.Seg_Table_Volume) SHL 4+MMSS_CFG^.Offset_DMA_Buffer;
 
 Nb_Voies_Aff:=Musique^.Ch_Number;
 If Nb_Voies_Aff>20 Then Nb_Voies_Aff:=20;

 Repeat
  {Write (MMSS_CFG^.Mix_Late_Cnt);}
  TailleDMA:=Lire_Taille_DMA(1);
  If TailleDMA>TailleDMAMax Then TailleDMAMax:=TailleDMA;

  PositionDMA:=Read_DMA_Offset(1);
  {PositionDMA:=Lire_Position_DMA5;}
  If PositionDMA<=PositionDMAMin Then
   Begin
    PositionDMAMin:=PositionDMA;
   End
  Else
   If PositionDMA>=PositionDMAMax Then
    Begin
     PositionDMAMax:=PositionDMA;
    End;

  Case Type_Affichage of
   1: Afficher_Infos;
   2: Afficher_Voies;
   3: Afficher_Samples;
   4: If MMSS_CFG^.Sortie_Sonore<>GUS Then Afficher_Oscillo;
   5: Afficher_SpectreTexte;
   6: Afficher_SpectreGraphique;
   7: Afficher_SpectreProgressif;
   8: Display_Buffer_GFX;
   9: Afficher_Vars;
  End;

 If Keypressed Then
  Begin
   KeyVal:=UpCase(ReadKey);
   Case KeyVal of
    Esc     : Break;

    Del     : Begin
               TailleDMAMax:=0;
               TailleDMAMin:=$FFFF;
               PositionDMAMax:=0;
               PositionDMAMin:=$FFFF;
              End;

{    Left    : Position_Precedente;
    Right   : Position_Suivante;    <- ‡a foire... }

    Up      : If ampl_FFT<10 Then Inc(ampl_FFT);
    Down    : If ampl_FFT>1  Then Dec(ampl_FFT);

    Key('P') : DB_Offset:=DB_Offset+DB_Size; { Buffer /Table Display Keys }
    Key('O') : DB_Offset:=DB_Offset-DB_Size;
    Key('L') : Begin
	        DB_Offset:=MMSS_CFG^.Offset_Left_Buffer;
	        DB_Offset:= MMSS_Info^.Buffer_Size;
               End;
    Key('M') : Begin
	        DB_Offset:=MMSS_CFG^.Offset_Right_Buffer;
                DB_Offset:= MMSS_Info^.Buffer_Size;
               End;
    Key('B') : Begin
	        DB_Offset:=MMSS_CFG^.Offset_DMA_Buffer;
                DB_Offset:= MMSS_Info^.Buffer_Size;
               End;
    Key('V') : Begin
	           DB_Offset:=0;
               If DB_16Bit then DB_Size:=512
                   Else DB_Size:=256;
              End;
			   
			   

    Key('R'): mode_FFT:=(mode_FFT AND NOT(FFT_rect+FFT_trapeze+FFT_hanning)) OR FFT_rect;
    Key('T'): mode_FFT:=(mode_FFT AND NOT(FFT_rect+FFT_trapeze+FFT_hanning)) OR FFT_trapeze;
    Key('H'): mode_FFT:=(mode_FFT AND NOT(FFT_rect+FFT_trapeze+FFT_hanning)) OR FFT_hanning;

    Key('1'): Begin Type_Affichage:=1; Afficher:=True End;
    Key('2'): Begin Type_Affichage:=2; Afficher:=True End;
    Key('3'): Begin Type_Affichage:=3; Afficher:=True End;
    Key('4'): Begin Type_Affichage:=4; Afficher:=True End;
    Key('5'): Begin Type_Affichage:=5; Afficher:=True End;
    Key('6'): Begin Type_Affichage:=6; Afficher:=True End;
    Key('7'): Begin Type_Affichage:=7; Afficher:=True End;

	Key('8'): Begin Type_Affichage:=8; Afficher:=True End;
	Key('9'): Begin Type_Affichage:=9; Afficher:=True End;

    Key('+'): If  MMSS_Info^.Volume_General<64 Then Inc( MMSS_Info^.Volume_General);
    Key('-'): If  MMSS_Info^.Volume_General>0  Then Dec( MMSS_Info^.Volume_General);

    Key('I'): MMSS_CFG^.Utiliser_Interpolation:=Not MMSS_CFG^.Utiliser_Interpolation;
   End;
  End;
  
 Until MMSS_CFG^.Output_Stopped;

If MMSS_CFG^.MMSS_Error<>0 then
   Begin
   Writeln('MMSS_Error: ',MMSS_CFG^.MMSS_Error);
   Repeat Until ReadKey=13;
   End;

{Afficher:=True;
Afficher_Vars;
Repeat Until ReadKey=13;}

 Writeln('Stop_Sortie');
 MMSS_Stop_Output;       { Stopper la sortie sonore }
 MMSS_Stop_Musique;           { Stopper la musique       }
 TextMode(LastMode);
 Writeln('The End...');
END.