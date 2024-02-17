UNIT MM_VAR;
{unit‚ pour Mod Master: types, constantes et variables}
{ Change output names}
{ 19/06/19 Max files reduced to 255 }

{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

INTERFACE

{$IFNDEF CGAOnly}
USES Texte,SourisSSm;
{$ELSE}
USES Texte,Sourisc;
{$ENDIF}

CONST REGISTERED=True;    {pour le bridage...}
      LONG_PROG_LIMIT=10; {nombre de modules max. dans un programme brid‚}

      Anglais=0; Francais=1;
	  
      M_DefVol  = 1;
      M_DefFreq = 2;
	  M_NoFreq  = 4;
	  M_IMF     = 8;
	  
	  D_Name   = 0;
	  D_Volume = 1;
	  D_Freq   = 2;

TYPE langues=Anglais..Francais;

     T_module=Record
               Numero: Byte;            { Number in the program }
               Taille,Volume: Word;
			   Frequency:Word;
               Default_Mask: Byte;      { Volume_defaut    }
               Nom: String[14];         { File Name        }
               Titre: String20;
               Valide: Boolean
              End;


CONST version_min_PRG: Array[1..3] of Char='2.0';
      version_min_DIR: Array[1..3] of Char='2.1';

      {version: Array[1..3] of Char='2.2';}
      ident_ModM: Array[1..18] of Char='Mod Master XT 1.01';

      MODM: Array[1..4] of Char='MODM';

      copyright_String: Array[1..30] of Char= {'- (c) Copyright 1995 Freddy V‚tel‚ & Fabrice Couteau -'}
       '- (c) Copyright 2022 FreddyV -';

      ext_MOD=1;  ext_SD0=2; ext_NST=3; ext_WOW=4; ext_OCT=5;
      ext_STM=6;  ext_S3M=7; ext_669=8; ext_DTM=9; ext_MTM=10;
      ext_ULT=11; ext_FAR=12; ext_SAT=13; ext_XM=14; ext_MMM=15;
      ext_VGM=16; ext_VGZ=17; ext_RAD=18;
      ext_IMF=19; ext_WLF=20; ext_RAW=21; ext_DRO=22; ext_MID=23;

{$IFDEF MONOTONE}
      nbr_extensions=24;
      ext_MON=24;
{$ELSE}
      nbr_extensions=23;
{$ENDIF}

      Extensions: Array[1..nbr_extensions] of String3
                   =('MOD','SD0','NST','WOW','OCT',
                     'STM','S3M','669','DTM','MTM',
                     'ULT','FAR','SAT','XM','MMM',
                     'VGM','VGZ','RAD','IMF','WLF',
                     'RAW','DRO','MID'
{$IFDEF MONOTONE}
                    ,'MON'
{$ENDIF}
                     );
      CouleursExt: Array[1..nbr_extensions] of Byte
                    =(   1,  1,  1,  1, 1,
                        10, 10,  5,  5, 9,       { 4 rouge 9 Bleu Fonce }
                         9,  9,  4, 11, 8,       { 2,3 Trop clair}
                        13, 12,  6,  9, 9,
			             9, 9 ,  9
{$IFDEF MONOTONE}
                       , 4
{$ENDIF}
                      );

      nbr_fich_max=255; {nombre maximal de fichiers dans un r‚pertoire (Previously 512)}
      nbr_boutons=11;   {nombre de boutons dans le menu}

      bt_Sortie   =1;
      bt_Options  =2;
      bt_IntroScan=3;
      bt_Shuffle  =4;
      bt_Lecture  =5;
      bt_Tout     =6;
      bt_Efface   =7;
      bt_Charge   =8;
      bt_Sauve    =9;
      bt_Aide     =10;
      bt_Quitte   =11;

      Erreurs: Array[1..23] of String[26] =(
          'Drive','not ready','Insert a disk','Insert a CD-Rom',
          'Disk read error','Change the disk',
          'Disk write error',
          'Disk is write-','protected',
          'Path','not found','File(s) not found',
          'Not enough memory','to load',
          'Format error in',
          'Error while opening',
          'does not exist anymore',
          'the program',
          'New drive',
          'Can''t load samples from',
          'Version not supported in',
          'Format not supported in',
          'File Protected');

      Play_Err:Array[1..12] of String[17] = (
          'Output Not Found',
          'SB Timeout',
          'Invalid Freq',
          'Computer too Slow',
          'Music Not Loaded',
          'Invalid Ch Number',
		  'Invalid Format',
		  'Adlib Not Found',
		  'OPL3 Not Found',
		  'TDY Not Found',
		  'Bad VGM Command',
		  'CMS Not Found');


      lecteur_txt         =1;
      pas_pret_txt        =2;
      inserez_disq_txt    =3;
      inserez_CDRom_txt   =4;
      err_lecture_txt     =5;
      changez_disq_txt    =6;
      err_ecriture_txt    =7;
      disq_protegee_txt   =8;
      en_ecriture_txt     =9;
      chemin_txt          =10;
      introuvable_txt     =11;
      fich_introuv_txt    =12;
      mem_insuff_txt      =13;
      pour_charger_txt    =14;
      err_format_txt      =15;
      err_pendant_lect_txt=16;
      nexiste_plus_txt    =17;
      le_prog_txt         =18;
      nouveau_lecteur_txt =19;
      pas_instrument_txt  =20;
      version_inconnue_txt=21;
      format_non_gere_txt =22;
      Fichier_Protege_txt =23;

VAR boutons: Array[1..nbr_boutons] of Bouton;
    nbr_fich,nbr_modules,premier_module,
    erreur_fin: Word;
    Module: Array[1..nbr_fich_max] of T_module;    { Table used to store the files/Folders information }
    nom_programme: String[8];
    page_menu: Ecran;

    duree_IntroScan,SB_LeftVol,SB_RightVol,
    delai_economiseur : Byte;
    MM_Default_Volume    : Word; { Default Volume    }
	MM_Default_Frequency : Word; { Default Frequency }
	Use_SBVGM : Boolean;   { Set to true when Mod Master does not support the VGM File }

    mode_interactif,affiche_syntaxe,recharge_module,
    CFG_present,PRG_present,Utilise_economiseur,
    affiche_titre,volume_modifie: Boolean;
	File_Display_Mode : Byte;
	MM_Hercule : Boolean;

{==========================================================}

IMPLEMENTATION

END.