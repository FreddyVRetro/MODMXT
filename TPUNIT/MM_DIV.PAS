{************************************************************************}
{                                MM_DIV.PAS                              }
{                                                                        }
{  Unit� pour Mod Master: routines diverses                              }
{                                                                        }
{  AUTEURS: Fabrice Couteau et Freddy V�tel�.                            }
{                                                                        }
{                                                                        }
{                               Debut d'ecriture le --/--/93             }
{                               Dernieres modifications le 08/10/95      }
{************************************************************************}
UNIT MM_DIV;
{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

{$UNDEF DEBUG}

INTERFACE

USES 
{$IFDEF MONOTONE}	 
     mt_edit,
{$ENDIF}
     Texte;

{$I Types}

{==========================================================}

PROCEDURE InitModeTexte;

PROCEDURE EffaceZoneCoins(xg,yh,xd,yb,attr: Byte);
PROCEDURE LigneHorizBouts(y,xg,xd,attr: Byte);
PROCEDURE LigneVerticBouts(x,yh,yb,attr: Byte);
PROCEDURE OmbreZoneCoins(xg,yh,xd,yb: Byte; Var z: Zone; attr: Byte);

PROCEDURE EchangeModules(i,j: Word);
FUNCTION  Extension(nom_fichier: String12): Byte;
FUNCTION  IndiceModule(nom: String12): Word;
FUNCTION  Indice(n: Word): Word;

FUNCTION  TestIdentModM(ident: String20; suffixe,v_min: String3): Boolean;
PROCEDURE SauveFichierDIR;
PROCEDURE AnalyseFichierDIR;
PROCEDURE LitFichierCFG;
PROCEDURE EcritFichierCFG;

PROCEDURE MM_ChargeModule(chemin: String80; Var erreur: Word);
PROCEDURE Play(chemin: String80);

PROCEDURE InitCarteSonore;
PROCEDURE CorrigeParametres(sortie,TypeSB: Byte; Var freq: Word;
                            Var utDMA,utSte,utMix,utFilt,utDC: Boolean; Var IRQ: Byte);
PROCEDURE Initialisation;

PROCEDURE DBG_DisplaySmp(CHU_NSmp:Byte);
PROCEDURE DBG_DisplayInsAdl(CHU_NSmp:Byte);

{==========================================================}

{$IFDEF MONOTONE}
VAR  { Public variable }

	MT_Player:PPlayer;
{$ENDIF}

IMPLEMENTATION

USES Crt,DOS,BiosEqu,VARUnit,Fichiers,Util,UtilC,Souris,
     MODMUnit,MM_VAR,MM_Play,CHUtil,MMSS_Var,MMSS_CMD,SBUnit,TDYUnit
{$IFDEF MONOTONE}
     ,mt_glob,mt_play
{$ENDIF}
{$IFNDEF NoGUS}
     ,GUSUnit
{$ENDIF}
{$IFNDEF MODMTINY}
     ,ChMOD,ChS3M,ChXM
{$ENDIF}
	 ,ChMMM
{$IFNDEF MODMLITE}
     ,ChSTM,Ch669,ChDTM,ChMTM,ChULT,ChFAR{,ChPTM}
{$ENDIF}
{$IFNDEF NoSAT}
     ,ChSAT,ChRAD,ChADL,ChVGM
{$ENDIF}
	 ;

VAR  Erreur_Modm: Byte;


{==========================================================}

PROCEDURE InitModeTexte; { Interface Text Mode }
Begin
 InitTexte;
 If Cursor_On Then Curseur(Rect) else Curseur(Off);
 Clignotement(False);
 {Repeat until Readkey=#13;}
End; {InitModeTexte}

{----------------------------------------------------------}

PROCEDURE EffaceZoneCoins(xg,yh,xd,yb,attr: Byte);
Var attr_sup_g,attr_sup_d,attr_inf_g,attr_inf_d: Byte;
Begin
{$IFNDEF CGAOnly}
 SauveAttrCoins(xg,yh,xd,yb,attr_sup_g,attr_sup_d,attr_inf_g,attr_inf_d);
{$ENDIF}
 EffaceZone(0,xg,yh,xd,yb,attr);
{$IFNDEF CGAOnly}
 AfficheCoins(xg,yh,xd,yb,attr_sup_g,attr_sup_d,attr_inf_g,attr_inf_d)
{$ENDIF}
End; {EffaceZoneCoins}

{----------------------------------------------------------}

PROCEDURE LigneHorizBouts(y,xg,xd,attr: Byte);
Begin
 LigneHorizontale(0,1,y,xg+1,xd-1,attr);
 AffCarXY(0,xg,y,chr(195),attr);
 AffCarXY(0,xd,y,chr(180),attr)
 End; {LigneHorizBouts}

{----------------------------------------------------------}

PROCEDURE LigneVerticBouts(x,yh,yb,attr: Byte);
Begin
 LigneVerticale(0,1,x,yh+1,yb-1,attr);
 AffCarXY(0,x,yh,chr(195),attr);
 AffCarXY(0,x,yb,chr(195),attr)
End; {LigneVerticBouts}

{----------------------------------------------------------}

PROCEDURE OmbreZoneCoins(xg,yh,xd,yb: Byte; Var z: Zone; attr: Byte);
Var attr_sup_g,attr_sup_d,attr_inf_g,attr_inf_d,
    attr_o_sup_g,attr_o_sup_d,attr_o_inf_g,attr_o_inf_d: Byte;
Begin
 {$IFNDEF CGAOnly}
 SauveAttrCoins(xg,yh,xd,yb,attr_sup_g,attr_sup_d,attr_inf_g,attr_inf_d);
 SauveAttrCoins(xg+2,yh+1,xd+2,yb+1,attr_o_sup_g,attr_o_sup_d,attr_o_inf_g,attr_o_inf_d);
 {$ENDIF}
 z.Ombre(0,xg,yh,xd,yb,attr);
 {$IFNDEF CGAOnly}
 AfficheCoins(xg,yh,xd,yb,attr_sup_g,attr_sup_d,attr_inf_g,0);
 AfficheCoins(xg+2,yh+1,xd+2,yb+1,attr,attr_o_sup_d,attr_o_inf_g,attr_o_inf_d);
 {$ENDIF}
 AffCarXY(0,xg+2,yh+1,' ',attr)
End; {OmbreZoneCoins}

{----------------------------------------------------------}

PROCEDURE EchangeModules(i,j: Word);
Var module_aux: T_module;
Begin
 module_aux:=Module[i]; Module[i]:=Module[j]; Module[j]:=module_aux
End; {EchangeModules}

{----------------------------------------------------------}

FUNCTION Extension(nom_fichier: String12): Byte;
Var i: Byte;
Begin
 Extension:=0;
 For i:=1 to nbr_extensions do
  If Pos('.'+Extensions[i],nom_fichier)>0 Then
   Begin Extension:=i; Exit End
End; {Extension}

{----------------------------------------------------------}

FUNCTION IndiceModule(nom: String12): Word;
{retourne l'indice du module 'nom' dans le tableau Module.Nom (0 si absent)}
Var i: Word;
Begin
 IndiceModule:=0;
 If nom[1]<'M' Then
  Begin  {recherche du premier au dernier module}
   For i:=premier_module to nbr_fich do
    If Module[i].Nom=nom Then Begin IndiceModule:=i; Exit End
  End
 Else
  Begin  {recherche du dernier au premier module}
   For i:=nbr_fich downto premier_module do
    If Module[i].Nom=nom Then Begin IndiceModule:=i; Exit End
  End
End; {IndiceModule}

{----------------------------------------------------------}

FUNCTION Indice(n: Word): Word;
{retourne l'indice dans le tableau Module.Nom dont le module porte le num�ro 'n'}
Var i: Word;
Begin
 i:=1;
 Repeat
  Inc(i)
 Until (Module[i].Numero=n) or (i=nbr_fich);
 Indice:=i
End; {Indice}

{----------------------------------------------------------}

FUNCTION TestIdentModM(ident: String20; suffixe,v_min: String3): Boolean;
Begin
 TestIdentModM:=(Copy(ident,1,12)=Copy(ident_ModM,1,12)) and  {Mod Master v}
                (Copy(ident,13,3)>=v_min) and  {x.x}
                (Copy(ident,16,5)=' '+suffixe+' ')  { xxx }
End; {TestIdentModM}

{----------------------------------------------------------}

PROCEDURE SauveFichierDIR;
Var i: Word;
    chaine: String20;
    f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),repert+'MODM.DIR');
   If f_erreur<>f_ok Then Exit;

   i:=1;
   Ecrit(i,2); {1 for V1}
   For i:=premier_module to nbr_fich do With Module[i] do
    Begin
     Ecrit(Nom[0],13);
     Ecrit(Titre[1],20);
     Ecrit(Volume,2);
	 Ecrit(Frequency,2);
     Ecrit(Default_Mask,1)
    End;
   Ferme
  End
End; {SauveFichierDIR}

{----------------------------------------------------------}

PROCEDURE AnalyseFichierDIR;

Var i,j,k: Word;
    chaine: String[14];
    creefichierDIR: Boolean;
    z: Zone;
    f: Fichier;

Begin
 With f do
  Begin
   Ouvre(lecture,repert+'MODM.DIR');
   If f_erreur=f_ok Then
    Begin
      Lit(i,2);     { Read Version number}
	 If i=1 Then
      Begin
       j:=2;
       k:=(Taille-2) Div 38; {nombre de modules dans MODM.DIR}
       creefichierDIR:=(k<>nbr_modules);
       For i:=1 to k do
        Begin
         LitPos(j,chaine[0],13); Inc(j,38);
         k:=IndiceModule(chaine);
         If k>0 Then With Module[k] do
          Begin
           Lit(Titre[1],20); Titre[0]:=#20;
           Lit(Volume,2);
		   Lit(Frequency,2);
           Lit(Default_Mask,1)
          End
         Else creefichierDIR:=True  {module absent}
        End
      End
     Else creefichierDIR:=True; {mauvais identificateur}
     Ferme
    End
   Else creefichierDIR:=True; {le fichier MODM.DIR n'existe pas}

  If creefichierDIR Then
   Begin
   {$IFNDEF NoMOUSE}
    CacheCursSouris;
   {$ENDIF}
    OmbreZoneCoins(27,11,54,13,z,19);
    Cadre(0,1,28,11,53,13,19,'',0,'');
    AffChXY(0,30,12,'Analyzing modules...',31);
{$IFNDEF NoMOUSE}
 AffCursSouris;
{$ENDIF}
    For i:=premier_module to nbr_fich do With Module[i] do
     If Titre='?' Then
      Begin
       Ouvre(lecture,repert+Nom);
	   Frequency:=0;
       If f_erreur=f_ok Then
        Begin
		 Titre:='                    ';
         Case Extension(Nom) of
          ext_MOD,
          ext_SD0,
          ext_NST,
          ext_WOW,
          ext_OCT,
          ext_STM,
          ext_S3M: LitPos( 0,Titre[1],20);
		  ext_MMM: LitPos( 11,Titre[1],20);
		  ext_XM:  LitPos( 17,Titre[1],20);
          ext_669: LitPos( 2,Titre[1],20);
          ext_DTM: LitPos(22,Titre[1],20);
          ext_MTM: LitPos( 4,Titre[1],20);
          ext_ULT: LitPos(15,Titre[1],20);
          ext_FAR: LitPos( 4,Titre[1],20);
          ext_VGZ,ext_VGM: Titre:='Video Game Music';
		  ext_MID: Titre:='MIDI';
          ext_RAD: Begin
		    Titre:=RAD_String;
	            Default_Mask:=M_NoFreq;
		   End;		  
          ext_IMF: Begin
                    Titre:=IMF_String;
                    Frequency:=560;
                    Default_Mask:=M_IMF;
                   End;
          ext_WLF: Begin
                    Titre:=IMF_String;
                    Frequency:=700;
                    Default_Mask:=M_IMF;
                   End;
          ext_RAW: Begin
		            Titre:=RAW_String;
				    Default_Mask:=M_NoFreq;
				   End;
          ext_DRO: Begin
		            Titre:=DRO_String;
				    Default_Mask:=M_NoFreq;
				   End;				   
          {ext_PTM: LitPos( 0,Titre[1],20); }
{$IFNDEF NoSAT}
          ext_SAT: Begin
		            Titre:=DRO_String;
				    Default_Mask:=M_NoFreq;
				   End;					
{$ENDIF}
{$IFDEF MONOTONE}
          ext_MON: Titre:='Monotone Tracker'; {LitPos(8,Titre[1],20);}
{$ENDIF}		  
		  End;
         Titre[0]:=#20;
         Ferme
        End;
       Volume:=MM_Default_Volume;
       If Frequency=0 then 
         Begin
          Frequency:=MM_Default_Frequency;
          Default_Mask:=Default_Mask OR (M_DefVol+M_DefFreq)
         End
          Else Default_Mask:=Default_Mask OR M_DefVol;

      End;
    RestaureZoneSuppr(0,z);
    SauveFichierDIR
   End
  End
End; {AnalyseFichierDIR}

{----------------------------------------------------------}

PROCEDURE LitFichierCFG;
Var i:Byte;
    ident : String[7];
    buffer: Array[1..30] of Byte;
    f: Fichier;
Begin
 With f do
  Begin
   Ouvre(lecture,'MODMXT.CFG');
   CFG_present:=(f_erreur=f_ok);
   If Not(CFG_present) Then Exit;

  Lit(ident[0],8);
{  Writeln('Taille : ',Taille);}
  If Taille=38 Then { Read the config file if the size is correct }
    Begin
     LitPos(8,buffer,30);
     With MMSS_CFG^ do
      Begin
       Wave_Output:=buffer[1];
       Move(buffer[2],MM_Default_Frequency,2);
       Move(buffer[4],MM_Default_Volume,2);
       duree_IntroScan:=buffer[6];
       car_barre_pitch:=buffer[7];
       coul_barre_pitch:=buffer[8] AND $0F;
       coul_bout_pitch :=buffer[8] SHR 4;
       car_barre_periode:=buffer[9];
       coul_barre_periode:=buffer[10];
       MMSS_W_Output_Available[C_DAC]:=BOOLEAN(buffer[12] AND $01);
       {Mode_a_afficher :=(buffer[12] SHR 1) AND $01;}
       Center_Display:=(buffer[12] SHR 2) AND $01;
       Utilise_Stereo  :=BOOLEAN((buffer[12] SHR 3) AND $01);
       Utilise_Mixage  :=BOOLEAN((buffer[12] SHR 4) AND $01);
       Utilise_Filtre  :=BOOLEAN((buffer[12] SHR 5) AND $01);
       MMSS_EMS_First  :=BOOLEAN((buffer[12] SHR 6) AND $01) AND EMS_presente;
       MMSS_Use_UMB    :=BOOLEAN((buffer[12] SHR 7) AND $01) AND UMB_presente;
       Use_FineTune_CMD:=BOOLEAN( buffer[13] AND $01);
       Use_Panning_CMD :=BOOLEAN((buffer[13] SHR 1) AND $01);
       Use_BPM_CMD     :=BOOLEAN((buffer[13] SHR 2) AND $01);
{$IFDEF MIX16} 
       Mix_16Bit       :=BOOLEAN((buffer[13] SHR 3) AND $01);
{$ENDIF}	   
       Utilise_DC      :=BOOLEAN((buffer[13] SHR 4) AND $01);
       Utiliser_Interpolation:=BOOLEAN((buffer[13] SHR 5) AND $01);
	   GUS_Interwave   :=BOOLEAN((buffer[13] SHR 6) AND $01);
	   GUS_LineIn      :=BOOLEAN((buffer[13] SHR 7) AND $01);	   
       Mix_ChLimit_Type:=buffer[14];
       Mix_ChLimit_Nb  :=buffer[15];	
       SB_LeftVol :=buffer[16] AND $0F;
       SB_RightVol:=buffer[16] SHR 4;
       MMSS_Def_LeftPan:=buffer[17];
       MMSS_Def_RightPan:=buffer[18];
       Nb_Octaves_MOD:=buffer[19];
	  End; 
	   OPL_Model:=buffer[20];
       OPL_LPT_Model:=buffer[21];
       OPL_LPT_Nb:=buffer[22];
       TDY_Type:=buffer[23]; 
       TDY_PortNb:=buffer[24];
       TDY_LPT_Nb:=buffer[25];
       CMS_Type:=buffer[26]; 
       CMS_PortNb:=buffer[27];
       CMS_LPT_Nb:=buffer[28];       
	   
	     MMSS_CFG^.CDAC_Port:=(BYTE(buffer[30]) SHL 8) + buffer[29];
	   
       MMSS_CFG^.OPL_Model:=OPL_Model;
       MMSS_CFG^.OPL_LPT_Model:=OPL_LPT_Model;
       MMSS_CFG^.OPL_LPT_Nb:=OPL_LPT_Nb;

       MMSS_CFG^.TDY_Type:=TDY_Type;
       MMSS_CFG^.TDY_LPT_Nb:=TDY_LPT_Nb;	   
       If TDY_Type<>0 then TDY_Port:=TDY_PortList[TDY_PortNb];
       MMSS_CFG^.TDY_Port:=TDY_Port;

       MMSS_CFG^.CMS_Type:=CMS_Type;
       MMSS_CFG^.CMS_LPT_Nb:=CMS_LPT_Nb;
       If CMS_Type<>0 then CMS_Port:=CMS_PortList[CMS_PortNb];	   
       MMSS_CFG^.CMS_Port:=CMS_Port
    End;
   Ferme
  End
End; {LitFichierCFG}

{----------------------------------------------------------}

PROCEDURE EcritFichierCFG;
Var ident : String[7];
    buffer: Array[1..30] of Byte;
    f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),'MODMXT.CFG');
   If f_erreur<>f_ok Then Exit;

   ident:='MMXTb20';
   Ecrit(ident[0],8);
   With MMSS_CFG^ do
    Begin
     buffer[1]:=Wave_Output;
     Move(MM_Default_Frequency,buffer[2],2);
     Move(MM_Default_Volume,buffer[4],2);
     buffer[6] :=duree_IntroScan;
     buffer[7] :=car_barre_pitch;
     buffer[8] :=coul_barre_pitch+(coul_bout_pitch SHL 4);
     buffer[9] :=car_barre_periode;
     buffer[10]:=coul_barre_periode;
    {buffer[11]}
     buffer[12]:=(BYTE(MMSS_W_Output_Available[C_DAC])+
                 (Center_Display AND $01) SHL 2)+
                 (BYTE(Utilise_Stereo) SHL 3)+
                 (BYTE(Utilise_Mixage) SHL 4)+
                 (BYTE(Utilise_Filtre) SHL 5)+
                 (BYTE(MMSS_EMS_First) SHL 6)+
                 (BYTE(MMSS_Use_UMB) SHL 7);
     buffer[13]:= BYTE(Use_FineTune_CMD)+
                 (BYTE(Use_Panning_CMD) SHL 1)+
                 (BYTE(Use_BPM_CMD) SHL 2)+
{$IFDEF MIX16}
                 (BYTE(Mix_16Bit) SHL 3)+
{$ENDIF}
                 (BYTE(Utilise_DC) SHL 4)+
                 (BYTE(Utiliser_Interpolation) SHL 5)+
				 (BYTE(GUS_Interwave) SHL 6)+
				 (BYTE(GUS_LineIn) SHL 7);
     buffer[14]:=Mix_ChLimit_Type;
     buffer[15]:=Mix_ChLimit_Nb;
     buffer[16]:=SB_LeftVol+(SB_RightVol SHL 4);
     buffer[17]:=MMSS_Def_LeftPan;
     buffer[18]:=MMSS_Def_RightPan;
     buffer[19]:=Nb_Octaves_MOD
    End;
   buffer[20]:=OPL_Model;
   buffer[21]:=OPL_LPT_Model;
   buffer[22]:=OPL_LPT_Nb;
   buffer[23]:=TDY_Type;
   buffer[24]:=TDY_PortNb;
   buffer[25]:=TDY_LPT_Nb;
   
   buffer[26]:=CMS_Type;
   buffer[27]:=CMS_PortNb;
   buffer[28]:=CMS_LPT_Nb;
   buffer[29]:=BYTE(MMSS_CFG^.CDAC_Port);
   buffer[30]:=BYTE(MMSS_CFG^.CDAC_Port SHR 8);

   Ecrit(buffer,30);
   Ferme
  End
End; {EcritFichierCFG}

{----------------------------------------------------------}

PROCEDURE MM_ChargeModule(chemin: String80; Var erreur: Word);
Type TTestS3M=Record
               Version: Word;
               Ident: Array[1..4] of Char;
              End;
Var f: Fichier;
    TestS3M: TTestS3M;
Begin
{Writeln('Memoire libre (Avant Chargement): ',Memavail);}
 {Stop_Output; }{ Stopper la musique }
 erreur:=Ok;

 Case Extension(NomFichierSeul(chemin)) of
{$IFNDEF MODMTINY}
  ext_MOD: Begin
            f.Ouvre(lecture,chemin);
            If f_erreur=f_ok then
             Begin
              f.LitPos(42,TestS3M,Sizeof(TestS3M));
              With TestS3M do
               If (Ident='SCRM') and (Version<3) Then Charge_S3M(chemin,erreur)
                                                 Else Charge_MOD(chemin,erreur);
              f.Ferme
             End
            Else erreur:=Err_lecture
           End;
  ext_NST,
  ext_WOW,
  ext_SD0,
  ext_OCT: Charge_MOD(chemin,erreur);
  ext_S3M: Charge_S3M(chemin,erreur);
  ext_XM : Charge_XM (chemin,erreur);
{$ENDIF}  
{$IFNDEF MODMLITE}
  ext_669: Charge_669(chemin,erreur);
  ext_DTM: Charge_DTM(chemin,erreur);
  ext_MTM: Charge_MTM(chemin,erreur);
  ext_ULT: Charge_ULT(chemin,erreur);
  ext_FAR: Charge_FAR(chemin,erreur);
  ext_STM: Charge_STM(chemin,erreur);
 { ext_PTM: Charge_PTM(chemin,erreur);}
{$ENDIF}
  ext_MMM: Charge_MMM(chemin,erreur);
  ext_RAD: Charge_RAD(chemin,erreur);
  ext_VGM: Begin
            Charge_VGM(chemin,erreur);
			{Writeln('Load Error:',erreur);}
            MMSS_MUS_Loaded:=True;
            Musique^.Type_Module:=T_VGM;
            Nom_fichier:=NomFichierSeul(chemin);
            If ((erreur=Ok) and (Erreur <> Err_Memoire)) then Use_SBVGM:=False
              Else 
               Begin { If not able to load, Use SBVGM }
                Use_SBVGM:=True; { Failed to Load : Try SBVGM }
                erreur:=Ok;
               End;
              End;
  ext_MID: Begin
            MMSS_MUS_Loaded:=True;
            Musique^.Type_Module:=T_MID;
            Nom_fichier:=NomFichierSeul(chemin);
		   End;		   
  ext_VGZ: Begin
            Use_SBVGM:=True;
            MMSS_MUS_Loaded:=True;
            Musique^.Type_Module:=T_VGM;
            Nom_fichier:=NomFichierSeul(chemin);
           End;
  ext_IMF,ext_RAW,ext_WLF,ext_DRO: Charge_ADL(chemin,erreur);
{$IFNDEF NoSAT}
  ext_SAT: Charge_SAT(chemin,erreur);
{$ENDIF}
{$IFDEF MONOTONE}
  ext_MON: Begin
		   Init_Module;
		   new(MT_Player,init(PIT,3));
		   If Not MT_Player^.Load(chemin) Then 
		      Begin
			   MMSS_MUS_Loaded:=False;
			   MT_Player^.Done;
			  End
			  else 
			  Begin
			   MMSS_MUS_Loaded:=True;
			   Musique^.Type_Module:=T_MON;
			   Nom_fichier:=NomFichierSeul(chemin);
              end;
		   End;		   
{$ENDIF}		   
   else Erreur:=Err_Non_Gere;
 End;
{Writeln('Memoire libre: (Apres Chargement)',Memavail);
Repeat until Readkey=#13;}
End; {ChargeModule}

{---------------------------------------------------------}

Function DosShell(ProgName:String; CommandLine:String):Integer;
Var
 OldHeapEnd,
 NewHeapEnd: Word;
 Error:Integer;
Begin
   
 Writeln('DosShell Start: ',ProgName,commandline);
 Writeln(' PrefixSeg , OldHeapEnd , NewHeapEnd : ',PrefixSeg,',', OldHeapEnd ,',', NewHeapEnd);
 Error:=0;
 {If MemAvail<$1000 then Error:=8;}
 If Error=0 then Begin
  NewHeapEnd:=Seg(HeapPtr^)-PrefixSeg;
  OldHeapEnd:=Seg(HeapEnd^)-PrefixSeg;
   asm
    mov ah,4Ah
    mov bx,NewHeapEnd
    mov es,PrefixSeg
    Int 21h
    mov Error,ax
   end; {asm}
 Writeln('DosShell 2, Error:',Error);
 If Error=0 then begin
 Writeln('DosShell 3');
   SwapVectors;
 Writeln('DosShell 4');
   Writeln(ProgName,commandline);
   Exec(ProgName,commandline);
   SwapVectors;
 Writeln('DosShell 5');
    asm
     mov ah,4Ah
     mov bx,OldHeapEnd
     mov es,PrefixSeg
     Int 21h

     mov Error,ax

    end; {asm}
  end;   {If}
 end;    {If}
 DosShell:=Error;
 Writeln('DosShell End')   
end;     {Function}

{---------------------------------------------------------}

PROCEDURE DoExecError(ExecNb : Integer);
 
Begin 
 If DOSError<>0 then
    Begin
     Writeln('DOS Error:',DOSError);
     If DosError=2 then
     If ExecNb=0 then Writeln('SBVGM.EXE Needed')
                 else Writeln('DOSMID.EXE Needed');
     Writeln('Press Return');
     Repeat until Readkey=#13;
    End;
End;

PROCEDURE Start_SBVGM(chemin: String80);
Var
   Args: String[80];
Begin
 TextMode(LastMode);       { Mode texte DOS                      }
 Mode_Actuel:=Autre_Mode;  { Indique le changement de mode vid�o }
 Curseur(plat);
 ClrScr;
 Args:='SBVGM.EXE ';
 If TDY_Type=1 then Args := Concat(Args,'-t',EntierHexa(TDY_Port,3),' ');
 If TDY_Type=2 then Args := Concat(Args,'-tndlpt',EntierHexa(BiosSeg.LptBase[TDY_LPT_Nb],3),' ');
 If OPL_LPT_Model=1 then Args := Concat(Args,'-opl2lpt',EntierHexa(BiosSeg.LptBase[OPL_LPT_Nb],3),' ');
 If OPL_LPT_Model=2 then Args := Concat(Args,'-opl3lpt',EntierHexa(BiosSeg.LptBase[OPL_LPT_Nb],3),' ');

 Writeln('* Mod Master XT : Starting SBVGM *');
 Writeln('Press Escape to quit');
 Writeln;
 Writeln(Args);

 SwapVectors;
 Exec(Args,chemin);
 SwapVectors;

 DoExecError(0);

End;

{---------------------------------------------------------}

PROCEDURE Start_DOSMID(chemin: String80);
Var
   Args: String[80];
Begin
 TextMode(LastMode);       { Mode texte DOS                      }
 Mode_Actuel:=Autre_Mode;  { Indique le changement de mode video }
 Curseur(plat);
 ClrScr;
 Args:='DOSMID.EXE';
 Chemin := Concat(Chemin,' /noxms /mpu');
{DosShell(Args,chemin);}
{Writeln (Args,Chemin);
 Repeat until Readkey=#13;}
 SwapVectors;
 Exec(Args,chemin);
 SwapVectors;

 DoExecError(1);

End;

{---------------------------------------------------------}

PROCEDURE Play(chemin: String80);
Var i: Integer;
Begin
 MMSS_CFG^.MMSS_Error:=0;

 If MMSS_MUS_Loaded Then
  Begin

  Centrer_Titre;

  {$IFDEF DEBUG}
  InitTexte;
  Writeln('MMSS_Start_Music');
  Writeln('UseSBVGM ',Use_SBVGM);
  {$ENDIF}

  If ((Musique^.Type_Module=T_VGM) or (Musique^.Type_Module=T_VGZ)) and Use_SBVGM then
     Begin
      Init_Module; { Free the memory for the Module }
      Start_SBVGM(chemin);
      recharge_module:=True;
      Exit;
     End;
  
  If (Musique^.Type_Module=T_MID) then
     Begin
      Init_Module; { Free the memory for the Module }
      Start_DOSMID(chemin);
      recharge_module:=True;
      Exit;
	  
     End;	 

{$IFDEF MONOTONE}
  If Musique^.Type_Module=T_MON then
     Begin
{     Writeln(nom_module); }
{     Writeln('Playing Monotone : Hi Trixter ! :-) ');}
      MT_Player^.MyPlayer^.Send(pa_PlaySongCur);

      MMSS_Start_Music;                        { Init the Module Variables (To reset the display) }
      MMSS_CFG^.Output_Stopped:=False;

      MMSS_Info^.Ch_Volume[1]:=$40;  { No volume for the moment, set all the channels volume to 40h }
      MMSS_Info^.Ch_Volume[2]:=$40;
      MMSS_Info^.Ch_Volume[3]:=$40;
      MMSS_Info^.Ch_Final_Vol[1]:=$40;
      MMSS_Info^.Ch_Final_Vol[2]:=$40;
      MMSS_Info^.Ch_Final_Vol[3]:=$40;
      MMSS_Info^.Pos_sequence:=1;

      MM_Playing_Interface;
	  
      MT_Player^.MyPlayer^.Send(pa_Stop);
      MT_Player^.Done;
      recharge_module:=True;
      Exit;
     end;
{$ENDIF} {MONOTONE}

 If (Musique^.Type_Module=T_IMF) or (Musique^.Type_Module=T_RAW) or
    (Musique^.Type_Module=T_DRO) or (Musique^.Type_Module=T_VGM) or
	(Musique^.Type_Module=T_VGZ) or (Musique^.Type_Module=T_MID) then recharge_module:=True;

  MMSS_Start_Music; { Init the Module Variables }
 
  {DBG_DisplaySmp(18);}
  
  {$IFDEF DEBUG}
   Writeln('MMSS_Error: ',MMSS_CFG^.MMSS_Error); 
  {$ENDIF}

  If MMSS_CFG^.MMSS_Error=Ok Then 
     Begin
      {$IFDEF DEBUG}
      Writeln('MMSS_Start_Output');
      {$ENDIF}	 
	  MMSS_Start_Output;  { Start the Module }
	 End;

  {MMSS_CFG^.Output_Stopped:=True;}

  {$IFDEF DEBUG}
  Writeln('MMSS_Error: ',MMSS_CFG^.MMSS_Error);
  Writeln('MM_Playing_Interface');
  Writeln('Press Return');
  Repeat until Readkey=#13;
  {$ENDIF}

  If MMSS_CFG^.MMSS_Error=Ok Then MM_Playing_Interface;

  MMSS_Stop_Output;
  MMSS_Stop_Musique

  End
 Else MMSS_CFG^.MMSS_Error:=PErr_MOD_NotLoaded;

End; {Play}

{----------------------------------------------------------}

PROCEDURE InitCarteSonore;
Var meilleure_sortie: Byte;
    i: Byte;
Begin  {InitCarteSonore}
 If GUS_presente Then meilleure_sortie:=GUS
 Else If SBPro_presente Then meilleure_sortie:=SBPro
      Else If SB_presente Then meilleure_sortie:=SB
           Else meilleure_sortie:=HPint;

 With MMSS_CFG^ do
  Begin
   If Not(CFG_present) Then WaveOut_SetDefault(meilleure_sortie)
   Else If Not MMSS_W_Output_Available[Wave_Output] Then WaveOut_SetDefault(meilleure_sortie);

   CorrigeParametres(Wave_Output,MMType_SB,Out_Frequency,Use_DMA,Utilise_Stereo,
                     Utilise_Mixage,Utilise_Filtre,Utilise_DC,IRQ_SB);

   If Wave_Output=SBPro then
     Begin
      SBP_MasterVolume(SB_LeftVol,SB_RightVol);   { Master Volume      }
      SBP_Filtre(Utilise_Filtre)
     End;
  End;

End; {InitCarteSonore}

{----------------------------------------------------------}

{----------------------------------------------------------}

PROCEDURE CorrigeParametres(sortie,TypeSB: Byte; Var freq: Word;
                            Var utDMA,utSte,utMix,utFilt,utDC: Boolean; Var IRQ: Byte);
Begin
 utDMA:=(sortie in [SB,SBPro]);
 If sortie<>SBPro Then
  Begin
   utSte:=False; utMix:=False; utFilt:=False;
   If IRQ>7 Then IRQ:=7
  End;
 If freq>Get_MaxFreq(sortie,TypeSB,utSte,UtDC) Then freq:=Get_MaxFreq(sortie,TypeSB,utSte,utDC)
End; {CorrigeParametres}

{----------------------------------------------------------}

PROCEDURE Initialisation;
Var i: Byte;
Begin
 CheckBreak:=False;
  
 MM_Default_Volume:=5*50;     { Init the Default Main Volume }
 MM_Default_Frequency:=16000;
 MMSS_Volume:=MM_Default_Volume;

 Nb_Octaves_MOD:=7;
{ Utilise_economiseur:=True;
 delai_economiseur:=1;} {en minutes !!}

 Boucler_MOD:=False;
 car_barre_pitch   :=9;
 coul_barre_pitch  :=2;
 coul_bout_pitch   :=12;
 car_barre_periode :=11;
 coul_barre_periode:=14;

 Center_Display:=0;
 Mode_a_afficher:=Mode_texte;
 MMSS_CFG^.Touche_fin:=Tfin_normale;
 
 If MM_Hercule then MMSS_CFG^.Seg_Video:=$B000;

{Volume_Total:=0; } {Volume r�glable avec +/- No more shared between ASM and TP}

 duree_IntroScan:=10;
 recharge_module:=True;

 Randomize;
 InitRepert;
 nom_programme:='';
 erreur_fin:=0;
 affiche_titre:=True
End; {Initialisation}

{DEFINE NoDebug}
{$IFNDEF NoDebug}
PROCEDURE DBG_DisplaySmp(CHU_NSmp:Byte);
Begin
Write('Sample N�',CHU_NSmp);

With MMSS_Table^.PtrSamples[CHU_NSmp]^ Do
Begin
Write(' Info: ',Info,' ');
If (Info And M_Charge)>0 Then Write('Charg� ');
If (Info And M_Bidi)>0 Then Write('Bidi ');
If (Info And M_Boucle)>0 Then Write('Boucle ');
If (Info And M_16Bit)>0 Then Write('16 bit ');
Writeln;
Writeln('Smp.Len: ',Len);
Writeln('Smp.Rep: ',Rep);
Writeln('Smp.Rep_Len: ',Rep_Len);
Writeln('Volume: ',Volume);
Writeln('C4Spd: ',C4Spd);
Writeln('Rel Note: ',Rel_Note);
End;
Repeat until Readkey=#13;
End;

PROCEDURE DBG_DisplayInsAdl(CHU_NSmp:Byte);
Begin
Write('Sample N�',CHU_NSmp);

With MMSS_Table^.PtrSamples[CHU_NSmp]^ Do
Begin
Write(' Info: ',Info,' ');
If (Info And M_Charge)>0 Then Write('Charg� ');
Writeln;
Write('Seg: ',Seg(MMSS_Table^.PtrSamples[CHU_NSmp]^),'Offs: ',Ofs(MMSS_Table^.PtrSamples[CHU_NSmp]^));
Writeln('AM1: ',AData.AM1,'AP1: ',AData.AP1);    { AM_VIB_EG + Rythm (Batterie) }
Writeln('AM2: ',AData.AM1,'AP2: ',AData.AP1);    { KSL_VOLUM }
Writeln('AM3: ',AData.AM1,'AP3: ',AData.AP1);    { ATTCK_DEC }
Writeln('AM4: ',AData.AM1,'AP4: ',AData.AP1);    { SUSTN_REL }
Writeln('AM5: ',AData.AM1,'AP5: ',AData.AP1);    { WAVEFORM  }
Writeln('AFeedback: ',AData.AFeedBack);
End;
Repeat until Readkey=#13;
End;
{$ENDIF}

{==========================================================}

END.
