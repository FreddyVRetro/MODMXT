{************************************************************************}
{                                CHADL.PAS                               }
{                                                                        }
{  Loader pour les fichiers Stream Adlib: IMF, RAW, DRO                  }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{************************************************************************}

{$IFNDEF Groupe}
UNIT ChADL; {unit‚ pour charger les fichiers MOD }
{$ELSE}
UNIT ChADL_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE


{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ENDIF}

CONST

IMF_String : String20 = 'Apogee Music File   ';
RAW_String : String20 = 'Rdos Raw OPL Capture';
DRO_String : String20 = 'DOSBox Adlib Capture';

DROSignature : Array[1..8] of Char = 'DBRAWOPL';


PROCEDURE Charge_ADL(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE
     Byte100 = Array[1..100] of Byte;

     T_IMFExtra=Record
                Id   : Byte;
                Data : Byte; { Speed value and infos }
                End;
				
	T_DROHeader=Record
	             Signature : Array[1..8] of Char;
				 MajVer : Word;
				 MinVer : Word;
				End;
				
	T_DRO2Header=Record
	
	              StreamLength  : Longint;
				  StreamDuration : Longint; { Ignore }
				  OPLType : Byte;
				  Format  : Byte;    { Ignore }
				  Compression  : Byte; { Ignore }
				  ShortDelCode : Byte;
				  LongDelCode  : Byte;
				  CodeLen : Byte;
				  
	             End;
	
	T_RAWHeader=Record
	             ID:Array[1..8] of Char; {RAWDATA}
		         Speed:Word;
		        End;
	 

{---------------------------------------------------------}

PROCEDURE Charge_ADL(chemin: String80; Var erreur: Word);

Var
 Ptr_Load:^Byte100;
 Ptr_Load2:^Byte100;
 FSize:LongInt;
 RAWHeader:^T_RAWHeader;
 DROHeader:^DROHeader;
 Tmp:Word;
 FirstWord: Word;

Begin  {Charge_RAD}

 Erreur:=Ok;
 Init_Module;

 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  FSize:=f_module.Taille;
  If FSize>65535 then
     Begin
      Erreur:=Err_Unknown_Version;
      EXIT;
	 End;

  Musique^.Type_Module :=T_IMF;
  Nom_fichier:=NomFichierSeul(chemin);
  Musique^.Ch_Number :=9;
  Musique^.Ch_Number_Adlib :=9;
  Musique^.Ch_Number_Digit :=0;

  { Load the file in Memory }

  If Not MMSS_MemAlloc(Ptr_Load,(FSize DIV 16)+1,True,False) Then
     Begin
      erreur:=Err_Memoire;
      EXIT;
     End
      Else
     Begin
      If (ExtensionSeule(Nom_fichier)='RAW') then
         Begin
          f_module.LitPos(0,Ptr_Load^,FSize); { Load the Header }
          RAWHeader:=Ptr_Load;
          If RAWHeader^.ID<>'RAWADATA' then
             Begin
              Erreur:=Err_format;
              { Liberer memoire }
              EXIT;
             End;
          Musique^.Type_Module :=T_RAW;
          MMSS_CFG^.Ptr_OtherMus:=Ptr_Load; { Save the Pointer to the .RAD File }
          MMSS_CFG^.OtherMusSize:=FSize;
          Move(RAW_String[1],Musique^.Titre,20);		
         End  { RAD }
          Else
      If (ExtensionSeule(Nom_fichier)='DRO') then
		 Begin
          f_module.LitPos(0,Ptr_Load^,FSize); { Load the Header }
          DROHeader:=Ptr_Load;
          If (DROHeader^.ID<>'DBRAWOPL') then
             Begin
              Erreur:=Err_format;
              { Liberer memoire }
              EXIT;
             End;			   
          Musique^.Type_Module :=T_DRO;
          MMSS_CFG^.Ptr_OtherMus:=Ptr_Load; { Save the Pointer to the .RAD File }
          Writeln('DRO Header Ok', );
	      Repeat until Readkey=#13;

         End
          Else
         Begin
          f_module.LitPos(0,FirstWord,2); { Load the Header }
          Move(IMF_String[1],Musique^.Titre,20);
          If FirstWord<>0 then
             Begin {  IMF Type 2 }
            {   Writeln('Size: ',FSize,'FirstWord : ',FirstWord);
              Repeat until Readkey=#13;}
              If FirstWord<FSize Then
                 Begin
                  f_module.LitPos(2,Ptr_Load^,FSize); { Load the file }
                  MMSS_CFG^.Ptr_OtherMus:=Ptr_Load;   { Save the Pointer to the raw data }
                  MMSS_CFG^.OtherMusSize:=FirstWord;
                 End
                  Else
			     Begin
                  Erreur:=Err_format;
				  {Liberer memoire }
                  EXIT;
                 End;
             End
              Else
             Begin {  IMF Type 1 }
              f_module.LitPos(0,Ptr_Load^,FSize); { Load the file }
              MMSS_CFG^.Ptr_OtherMus:=Ptr_Load;   { Save the Pointer to the raw data }
              MMSS_CFG^.OtherMusSize:=FSize;
             End;
		End;	   
     End;
{ Allocate and Clean the Samples names }

 Tmp:=(24*31 DIV 16) +1;
 If Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then
    Begin
     Erreur:=Err_Memoire;
     EXIT;
    End
     Else
    Begin
     Musique^.PtrInstrNameTable:=Ptr_Load;
     FillChar(Ptr_Load^,24*31,' ');
    End;

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