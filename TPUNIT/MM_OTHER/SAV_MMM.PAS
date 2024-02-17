{************************************************************************}
{                                SAV_MMM.PAS                             }
{                                                                        }
{  Save the Module from memory to a .MMM File                            }
{                                                                        }
{************************************************************************}

{$UNDEF SAVDEBUG}

{$IFNDEF Groupe}
UNIT SAV_MMM; {unit‚ pour charger les fichiers MOD }
{$ELSE}
UNIT ChMOD_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ENDIF}

PROCEDURE Save_MMM(chemin: String80; Fext:String3; Var erreur: Word);

IMPLEMENTATION

Type Byte100 = Array[1..100] of Byte;

T_Header_MMM=Record
              Ident     : Array[1..3] of Char;
              Version   : Word;
              FileExt   : String3;
              Reserved  : Word;
             End;
CONST

MMMHeader: T_Header_MMM=(Ident:'MMM';Version:1;FileExt:'   ';Reserved:0);

{---------------------------------------------------------}

PROCEDURE Save_MMM(chemin: String80; Fext:String3; Var erreur: Word);

Var
 i,j:Byte;
 Ptr_Save: ^Byte100;
 tmp:Word;
 PtrDBG : Longint;
 
 PtrInst: ^TTInstr;
 PtrInstData: Pointer;
 InstrDataSize: Byte;
 
Begin  {Charge_MOD}


 erreur:=Ok;
{$IFDEF SAVDEBUG} 
 PtrDBG:=0;
{$ENDIF}

If MMSS_MUS_Loaded=False then
   Begin
   Writeln('File Not Loaded : Can''t save the file.');
   Halt;
   End;

 f_module.Cree(False,chemin);

 If f_erreur=f_ok then
  Begin
   
   MMMHeader.FileExt:=Fext;
  { Save the MMM Header }
  f_module.EcritPos(0,MMMHeader,Sizeof(MMMHeader));
  { Save the Header }

{$IFDEF SAVDEBUG} 
PtrDBG:=PtrDBG+Sizeof(MMMHeader);
Writeln('** Save Header**');
Writeln('Name: ',Musique^.Titre);
{$ENDIF}

  f_module.Ecrit(Musique^,Sizeof(Musique^)); { Save the Header }
 
  { Save the Patterns }
{$IFDEF SAVDEBUG} 
PtrDBG:=PtrDBG+Sizeof(Musique^);  
Writeln('** Save Patterns**');
{$ENDIF}
   For i:=1 to Max_Pattern do
    Begin
     If MMSS_Table^.Seg_Pattern[i]<>0 Then
        Begin
         Tmp:=MMSS_Table^.Seg_Pattern[i];
         Ptr_Save:=Ptr(Tmp,0);
         Tmp:=MEMSizeDOS(Tmp);
{$IFDEF SAVDEBUG} 		 
		 Writeln('Pattern: ',i,'Size: ',Tmp,'Ptr: ',PtrDBG);
		 PtrDBG:=PtrDBG+Tmp*16+2+1;
{$ENDIF}
		 f_module.Ecrit(i,1);   { Write the Pattern Number }
         f_module.Ecrit(Tmp,2); { Write the Pattern Size (In 16 byte Block) }
         f_module.Ecrit(Ptr_Save^,Tmp*16); { Write the Pattern }
        End;
    End;
   i:=0;
   f_module.Ecrit(i,1); { Write '0' End Of Patterns }
   
{$IFDEF SAVDEBUG} 	   
   PtrDBG:=PtrDBG+1;
{$ENDIF}

   { Save the Instruments (For .XM Only) }
    If Musique^.Type_Module=T_XM then
	   Begin
	   PtrInst:=Ptr(Musique^.Seg_Instr,0);
{$IFDEF SAVDEBUG}  
  Writeln(' Instruments Headers Ptr: ',PtrDBG);
  Writeln(' Nb Instruments: ',Musique^.Nb_Instr);
  PtrDBG:=PtrDBG+Musique^.Nb_Instr*8;
{$ENDIF}	   
	   f_module.Ecrit(PtrInst^,Musique^.Nb_Instr*8); {8 Byte per Instrument }
	   
	   for i:=1 to Musique^.Nb_Instr do { Save the Instruments additional Data }
	    If PtrInstrument^[i].InstrDataSeg<>0 then
	      Begin
		  PtrInstData:=Ptr(PtrInstrument^[i].InstrDataSeg,0);
          InstrDataSize:=6*16; { Note Table Size }
          If (PtrInstrument^[i].VolumeType>0) then InstrDataSize:=(6+4)*16; { Load Vol envelope as well }
{$IFDEF SAVDEBUG}  
  Writeln(' Inst Nb: ',i);
  Writeln(' DataSize: ',InstrDataSize);
  PtrDBG:=PtrDBG+InstrDataSize;
{$ENDIF}
		  f_module.Ecrit(PtrInstData^,InstrDataSize);
		  End;
	   End;
	   
{$IFDEF SAVDEBUG}  	   
Writeln(' Sample Name/Header Ptr: ',PtrDBG);
Repeat until Readkey=#13;
{$ENDIF}	   
   { Save the Samples names }
  
   f_module.Ecrit(Musique^.PtrInstrNameTable^,Musique^.Nb_Total_Samples*24);
{$IFDEF SAVDEBUG} 	   
   PtrDBG:=PtrDBG+Musique^.Nb_Total_Samples*24;
{$ENDIF}
   { Save the Samples Headers }
   
   f_module.Ecrit(MMSS_Table^.PtrSamples[1]^,(Musique^.Nb_Total_Samples*SizeOf(Smp)));
{$IFDEF SAVDEBUG} 	   
   PtrDBG:=PtrDBG+(Musique^.Nb_Total_Samples*SizeOf(Smp));
{$ENDIF}
   { Save the Samples Data }
{$IFDEF SAVDEBUG}
Writeln('** Save Samples**');
{$ENDIF}
   For i:=1 to Musique^.Nb_Total_Samples do
   With MMSS_Table^.PtrSamples[i]^ do
    Begin
	 If  (Mem.Segment)<>0 Then
	    Begin
{$IFDEF SAVDEBUG}		
		Writeln('Sample: ',i,' Length: ',Len,'Ptr: ',PtrDBG);
{$ENDIF}		
	    If (Mem.Handle_EMS=-1) Then
		   Begin { Sample not in EMS }
		    Ptr_Save:=Ptr(Mem.Segment,0);
			f_module.Ecrit(Ptr_Save^,Len);
{$IFDEF SAVDEBUG}			
			PtrDBG:=PtrDBG+Len;
{$ENDIF}			
		   End
		    Else { Sample in EMS }
		   Begin
{$IFDEF SAVDEBUG}		   
		   Writeln('Sample en EMS');
{$ENDIF}			   
            For j:=0 to Mem.Nb_Pages_EMS do     { Map Sample in Memory }
                EmsMap(Mem.Handle_EMS,j,j);
		    Ptr_Save:=Ptr(Mem.Segment,0);
			f_module.Ecrit(Ptr_Save^,Len);
{$IFDEF SAVDEBUG}			
            PtrDBG:=PtrDBG+Len;
{$ENDIF}			
		   End;
        End;
    End; { Sample Data Loop}
{$IFDEF SAVDEBUG}	  
  Repeat until Readkey=#13;
 {$ENDIF} 
  f_module.Ferme;
  End
 Else
  Begin
   Writeln(chemin+', File Open Error:',f_erreur);
   Erreur:=Err_lecture  {Impossible d'ouvrir le fichier}
  End;

End; {Save_MMM}

END.