{************************************************************************}
{                                CHMOD.PAS                               }
{                                                                        }
{  Loader pour les fichiers MOD (ProTracker - Amiga  4->32 voies :))     }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{  11/4/2019 Correct Portamento                                          }
{                               DerniŠres modifications le 04/10/95      }
{************************************************************************}

{$IFNDEF Groupe}
UNIT ChMMM; {unit‚ pour charger les fichiers MOD }
{$ELSE}
UNIT ChMMM_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ENDIF}

PROCEDURE Charge_MMM(chemin: String80; Var erreur: Word);

IMPLEMENTATION

Type 

Byte100 = Array[1..100] of Byte;

T_Header_MMM=Record
              Ident    : Array[1..3] of Char;
              Version  : Word;
              FileExt  : String3;
              Reserved : Word;
             End;  
CONST

 MMMIdend: Array[1..3] of Char = 'MMM';

{---------------------------------------------------------}

PROCEDURE Charge_MMM(chemin: String80; Var erreur: Word);

Var
 i,j:Byte;
 Ptr_Load:Pointer;
 Ptr_Load2:^Byte100;
 tmp:Word;
 MMMHeader:T_Header_MMM;

Begin  {Charge_MOD}

 f_module.Ouvre(lecture,chemin);
 
 If f_erreur=f_ok then
  Begin
  Init_Module;
  Nom_fichier:=NomFichierSeul(chemin);

  { Load the MMM Header }
  f_module.LitPos(0,MMMHeader,Sizeof(MMMHeader)); { Load the Header }

  If MMMHeader.Ident<>MMMIdend then 
     Begin
	 erreur:=Err_format;
	 EXIT;
	 End;
  
  { Load the Header     }
  f_module.Lit(Musique^,Sizeof(Musique^)); { Load the Header }

  { Load the Patterns }
{Writeln('** Load Patterns**');}

   i:=0;
   Repeat
    i:=i+1;
 	f_module.Lit(j,1);   { Write the Pattern Number }
	if j<>0 then
	   Begin
        f_module.Lit(Tmp,2); { Read the Pattern Size (In 16 byte Block) }
        If Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then
           Begin
            erreur:=Err_Memoire;
	        EXIT;
           End
            Else
           Begin
            MMSS_Table^.Seg_Pattern[j]:=Seg(Ptr_Load^);
            Ptr_Load2:=Ptr_Load;
            f_module.Lit(Ptr_Load^,Tmp*16); { Load the Pattern }
           End;
       End;
   Until (j=0) or (j=Max_Pattern);

   If j=Max_Pattern then erreur:=Err_TooManyPat;

   { Load the Instruments (For .XM Only) }

    If Musique^.Type_Module=T_XM then
	   Begin

{writeln('Read Instruments');}

       If not Allocate_Instruments(Musique^.Nb_Instr) Then EXIT;
	   
	   f_module.Lit(PtrInstrument^,Musique^.Nb_Instr*8); {8 Byte per Instrument }
	   
	   for i:=1 to Musique^.Nb_Instr do { Save the Instruments additional Data }
	    If PtrInstrument^[i].InstrDataSeg<>0 then
	      Begin

          Tmp:=6; { Note Table Size }
          If (PtrInstrument^[i].VolumeType>0) then Tmp:=6+4; { Load Vol envelope as well }

          IF Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then { Allocate the Instrument Data Tables }
             Begin
              Erreur_de_chargement:=Err_Memoire;
              EXIT;
             End;		  

		  f_module.Lit(Ptr_Load^,Tmp*16);
		  PtrInstrument^[i].InstrDataSeg:=Seg(Ptr_Load^); { Store the pointer to the Instrument Data }
		  End;
	   End;


{Writeln(' Sample Header Ptr: ',PtrDBG);}
{Repeat until Readkey=#13;}

  { Load the Samples names }

   Tmp:=(24*Musique^.Nb_Total_Samples DIV 16) +1;
   If Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then
     Begin
      erreur:=Err_Memoire;
      EXIT;
     End
     Else
     Begin
      f_module.Lit(Ptr_Load^,Musique^.Nb_Total_Samples*24); { Load the names }
      Musique^.PtrInstrNameTable:=Ptr_Load;
     End;  

 { Load the Samples Headers }

   If Erreur=Ok then
     Begin

     Tmp:=((Musique^.Nb_Total_Samples*SizeOf(Smp)) DIV 16) +1;
     If Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then
       Begin
        erreur:=Err_Memoire;
       End
        Else
       Begin
        f_module.Lit(Ptr_Load^,(Musique^.Nb_Total_Samples*SizeOf(Smp)));
        { Build the Samples Header Ptr List }
        Tmp:=Seg(Ptr_Load^);
	For i:=1 to Musique^.Nb_Total_Samples do
            MMSS_Table^.PtrSamples[i]:=Ptr(Tmp,(i-1)*SizeOf(Smp));
       End;  

     End
	 Else EXIT;

{Load the Samples Data }
{Writeln('** Load Samples**');}

  Erreur_de_Chargement:=Ok;
  FillChar(SamplFlags,SizeOf(SamplFlags),1);
  
  Init_Charge_Sample;

  For CHU_NSmp:=1 to Musique^.Nb_Total_Samples do
   Begin
   
    If  (MMSS_Table^.PtrSamples[CHU_NSmp]^.Info And (M_Adlib + M_Charge)=M_Charge) Then  { Not Adlib and Loaded }
     If (MMSS_Table^.PtrSamples[CHU_NSmp]^.Len<>0) Then
        Begin
         Move(MMSS_Table^.PtrSamples[CHU_NSmp]^,Smp,SizeOf(Smp));
	     Smp.Mem.Segment:=0; { Clean the Memory Addr Vars }
		 Smp.Mem.Nb_Pages_EMS:=0;
		 Smp.Mem.Handle_EMS:=0;
		 Smp.Adresse_GUS:=0;
         Smp.Info:=(Smp.Info AND NOT M_Charge); { Set Info to Not Loaded }
		 Smp_Rep_Fin:=Smp.Rep+Smp.Rep_Len;
		 
{		 Writeln('Sample: ',CHU_NSmp,' Length: ',Smp.Len,'Ptr: ',PtrDBG);     }   
		 
         Charger_Sample;
         Move(Smp,MMSS_Table^.PtrSamples[CHU_NSmp]^,SizeOf(Smp)); { Copy Back the Sample Data }
         MMSS_Table^.PtrSamples[CHU_NSmp]^.Info:=Smp.Info
        End;
   End;

  Fin_Charge_Sample; { Calculate the Samples Loaded Nb }
  Erreur:=Erreur_de_chargement;
  
  Musique^.Octave_Min:=1;

{  Repeat until Readkey=#13;}
  f_module.Ferme;
  End
 Else
  Begin
   Writeln(chemin+', File Open Error:',f_erreur);
   Erreur:=Err_lecture
  End;
  
If Erreur In [Ok,Err_samples] Then MMSS_MUS_Loaded:=True
   Else Init_Module;
End; {Charge_MMM}

END.