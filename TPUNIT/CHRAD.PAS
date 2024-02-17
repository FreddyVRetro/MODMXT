{************************************************************************}
{                                CHRAD.PAS                               }
{                                                                        }
{  Loader pour les fichiers RAD (Reality Adlib Tracker)     }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{************************************************************************}

{$IFNDEF Groupe}
UNIT ChRAD; {unit‚ pour charger les fichiers MOD }
{$ELSE}
UNIT ChRAD_G;
{$ENDIF}

{$A+,Q-,R-,S-}

INTERFACE

{$IFNDEF Groupe}
USES Fichiers,Util,Chutil,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ELSE}
USES Fich_grp,Util,Chutil_G,MMSS_Var,CRT,MMSS_Mem,Memoire;
{$ENDIF}

CONST

RAD_String : String20 = 'Reality Adlib Track ';

PROCEDURE Charge_RAD(chemin: String80; Var erreur: Word);

IMPLEMENTATION

TYPE
     Byte100 = Array[1..100] of Byte;

     T_RADHeader=Record
            ID     : Array[1..16] of Char;
			Version: Byte;
			Speed  : Byte; { Speed value and infos }
           End;

{---------------------------------------------------------}

PROCEDURE Charge_RAD(chemin: String80; Var erreur: Word);

Var
 Ptr_Load:Pointer;
 Ptr_Load2:^Byte100;
 FSize:LongInt;
 Tmp:Word;

Begin  {Charge_RAD}

 Erreur:=Ok;
 Init_Module;

 f_module.Ouvre(lecture,chemin);

 If f_erreur=f_ok then
  Begin
  FSize:=f_module.Taille;
  If FSize>65535 then
     Begin
      Erreur:=Err_lecture;
      EXIT;
     End;

  Musique^.Type_Module :=T_RAD;       { Type de module }
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
            f_module.LitPos(0,Ptr_Load^,FSize); { Load the Header }
            Ptr_Load2:=Ptr_Load;
			MMSS_CFG^.OtherMUS_Ptr:=Ptr_Load; { Save the Pointer to the .RAD File }
            Move(RAD_String[1],Musique^.Titre,20);
			
			{ Allocate and Clean the Samples names }

            Tmp:=(24*31 DIV 16) +1;
            If Not MMSS_MemAlloc(Ptr_Load,Tmp,True,False) Then
               Begin
                erreur:=Err_Memoire;
                EXIT;
               End
              Else
               Begin
                Musique^.PtrInstrNameTable:=Ptr_Load;
				FillChar(Ptr_Load^,24*31,' ');
               End;  
			
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