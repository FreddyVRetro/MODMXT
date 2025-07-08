{************************************************************************}
{                                CHVGM.PAS                               }
{  Support only SN76489, OPL2, OPL3                                      }
{  Loader pour les fichiers Stream VGM                                   }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{************************************************************************}

{$IFNDEF Groupe}
UNIT ChVGM; {unit� pour charger les fichiers MOD }
{$ELSE}
UNIT ChVGM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE


{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ENDIF}

CONST

VGM_String : String20 = 'Video Game Music    ';

PROCEDURE Charge_VGM(chemin: String80; Var erreur: Word);
{ Return Error if not supported }

IMPLEMENTATION

TYPE
				
	T_VGMHeader=Record
	             ID : Array[1..4] of Char;
				 Size : Longint;
				 VerL : Byte; { Version Low BCD  }
				 VerH : Byte; { Version High BCD }
				 VerD : Word;
				 SN76489Clk : Longint;   { Tandy Chip }
				 YM2413Clk  : LongInt;
				 DG3TagOffset : Longint; { Information Tag Offset }
				 TotSamples : Longint;
				 LoopOffset : Longint;
				 LoopSamp   : Longint;
				 { v1.01 }
				 Rate : Longint;
				 { v1.10 }
				 SNFeedback : Longint;
				 YM2612Clk  : Longint;
				 YM2151Clk  : Longint;
				 { v1.50 }
				 DataOffset : Longint;
             f1 : Array[1..6] of Longint;
				 YM3812Clk : Longint; { OPL2 v1.51 }
				 f2 : Longint;
				 f3 : Longint;
				 YMF262Clk  : Longint; { OPL3 v1.51 }
				 YMF278BClk : Longint;
				 YMF271Clk  : Longint;
				 YMZ280BClk : Longint;
				 RC52C164Clk: Longint;
             PWMClk: Longint;
             AY8910Clk: Longint;   {PSG AY-3-8910/YM2149}
             AY8910Type: Byte;
             AY8910Flags:Array[1..3] of Byte;
				 f4: Array[1..19] of Longint;
				 SAA1099Clk: Longint; { CMS }
				End;
				

	 

{---------------------------------------------------------}

PROCEDURE Charge_VGM(chemin: String80; Var erreur: Word);

Var
 Ptr_Load:Pointer;
 FSize:LongInt;
 VGMHeader:^T_VGMHeader;
 DataOffset : LongInt;
 
 Tmp:Word;
 FirstWord: Word;

Begin  {Charge_VGM}

 Erreur:=Ok;
 Init_Module;

 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  Init_Module;

  FSize:=f_module.Taille;
  Tmp:=MemoireDOSLibre;
  
  If (FSize DIV 16)>=Tmp then  { Check if sufficient DOS Memory free }
     Begin
      Erreur:=Err_Memoire;
      EXIT;
	 End;

  Musique^.Type_Module :=T_VGM;
  Nom_fichier:=NomFichierSeul(chemin);
  Musique^.Ch_Number_Digit :=0;
  { Load the file in Memory }

  If Not MMSS_MemAlloc(Ptr_Load,(FSize DIV 16)+1,False,False) Then { No UMB }
     Begin
      erreur:=Err_Memoire;
      EXIT;
     End
      Else
     Begin
      f_module.LitPosL(0,Ptr_Load,FSize); { Load the Header }
      VGMHeader:=Ptr_Load;
       If VGMHeader^.ID<>'Vgm ' then
             Begin
              Erreur:=Err_format;
              { Liberer memoire }
              EXIT;
             End;

      Move(VGM_String[1],Musique^.Titre,20);

       If ((VGMHeader^.VerH=1) and (VGMHeader^.VerL>=$51)) or (VGMHeader^.VerH>1) then
          Begin
           DataOffset:=VGMHeader^.DataOffset+$34;
          End
		  Else DataOffset:=$40;

   If VGMHeader^.DG3TagOffset<>0 then 
      MMSS_CFG^.OtherMUS_DataEnd:=VGMHeader^.DG3TagOffset
	  Else MMSS_CFG^.OtherMUS_DataEnd:=FSize;

   MMSS_CFG^.OtherMUS_Ptr:=Ptr(SEG(Ptr_Load^),DataOffset); { Save the Pointer to the .VGM Stream }

 {  Writeln('VGM Version: ',VGMHeader^.VerH,' ',VGMHeader^.VerL);
   Writeln('FSize :',FSize);
   Writeln('DG3 Offset :',VGMHeader^.DG3TagOffset);
   Writeln('DataOffset :',DataOffset);
   Writeln('DataEnd : ',MMSS_CFG^.OtherMUS_DataEnd);
   Writeln('Ptr_Load: ',Seg(Ptr_Load^),':',Ofs(Ptr_Load^));
   Writeln('MMSS_CFG^.OtherMUS_Ptr: ',Seg(MMSS_CFG^.OtherMUS_Ptr^),':',Ofs(MMSS_CFG^.OtherMUS_Ptr^));}

	 { V 1.0 Support only the SN76489 }
       If ((VGMHeader^.VerH=1) and (VGMHeader^.VerL>=$51)) or (VGMHeader^.VerH>1) then
          Begin
          {Writeln(' Version >= 1.51 ');}
          If VGMHeader^.SN76489Clk<>0 then
             Begin
              {Writeln('SN76489');}
              MMSS_CFG^.OtherMUS_Out:=MMSS_CFG^.OtherMUS_Out OR M_SN76489;
              Musique^.Ch_Number :=4;
             End;
          If VGMHeader^.YM3812Clk<>0 then
             Begin
              {Writeln('OPL2');}
	          MMSS_CFG^.OtherMUS_Out:=MMSS_CFG^.OtherMUS_Out OR M_OPL2;
              Musique^.Ch_Number :=9;
              Musique^.Ch_Number_Adlib :=9;			  
             End;
          If VGMHeader^.YMF262Clk<>0 then
             Begin
              {Writeln('OPL3');}
              MMSS_CFG^.OtherMUS_Out:=MMSS_CFG^.OtherMUS_Out OR M_OPL3;
              Musique^.Ch_Number :=9;
              Musique^.Ch_Number_Adlib :=9;	
             End;
          If VGMHeader^.AY8910Clk<>0 then
             Begin
              Writeln('PSG',VGMHeader^.AY8910Clk);
              MMSS_CFG^.OtherMUS_Out:=MMSS_CFG^.OtherMUS_Out OR M_PSG;
              Musique^.Ch_Number :=6;
              Repeat until Readkey=#13;
             End;             
          If (VGMHeader^.SAA1099Clk<>0) and (VGMHeader^.VerL>=$71) then		 
		     Begin
             {Writeln('SAA1099');
			  Writeln('VGMHeader^.SAA1099Clk',VGMHeader^.SAA1099Clk);}
              MMSS_CFG^.OtherMUS_Out:=MMSS_CFG^.OtherMUS_Out OR M_SAA1099;
              Musique^.Ch_Number :=9;		   
	{		 Writeln('MMSS_CFG^.OtherMUS_Out:',MMSS_CFG^.OtherMUS_Out);}
             End;				 
          End
           Else
          Begin
           Erreur:=Err_Unknown_Version;
           EXIT;
          End;

	   {DataOffset}
	   
 End;  { VGM }

  f_module.Ferme;
  End
 Else
  Begin
   Writeln(chemin+', File Open Error:',f_erreur);
   Erreur:=Err_lecture
  End;
  
If Erreur=Ok Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_MMM}

END.