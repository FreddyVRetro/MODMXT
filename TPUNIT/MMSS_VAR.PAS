{************************************************************************}
{                              MMSS_VAR.PAS                              }
{                                                                        }
{  Types, const and Var for Mod Master SS                                }
{                                                                        }
{  AUTEUR: Freddy Vetele                                                 }
{                                                                        }
{                                                                        }
{                               Derni�res modifications le 16/04/20      }
{************************************************************************}
UNIT MMSS_Var;
{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}

INTERFACE

USES VARUnit;

CONST 
      { If You change these values, change them in the ASM Code as well }
	  { Also generate another .MMM File }
	  Max_Channels = 32;
      Max_Samples = 99;
      Max_Pattern = 128;  { Max 256 for ULT and FAR }

      { Volume and DMA Buffers Size }
{$IFDEF MIX16}
	  Max_Buffer_Samples_Nb = 5*1764;  {1280 : Max 32000 16 Bit, 64000 8 Bit /2 in Stereo}
	                                   {1764 : Max 44100 16 Bit, 88200 8 Bit /2 in Stereo}
      Volume_Table_Size = 512*65;      { 256*65 8 Bit / 512*65 16 Bit (32Kb)}
{$ELSE}
	  Max_Buffer_Samples_Nb = 5*1764;  {1280 : Max 32000 16 Bit, 64000 8 Bit /2 in Stereo}
	                                   {1764 : Max 44100 16 Bit, 88200 8 Bit /2 in Stereo}
      Volume_Table_Size = 256*65;      { 256*65 8 Bit(16Kb) }
{$ENDIF}

      VolumeMix_Table_Size=Volume_Table_Size+Max_Buffer_Samples_Nb*2;  { Memory table lenght + DMA buffers size }	  

      Max_Sample_Name = 31;

      { Samples Info Mask }
      M_Adlib   = $01;   { instrument Adlib }
      M_NSigne  = $02;   { Signed / Unsigned }
      M_16bit   = $04;   { 8 bits / 16 bits }
      M_Boucle  = $08;   { Loop / no Loop }
      M_Bidi    = $10;   { monodirectionnel(normal) / bidirectionnel(ping-pong) GUS Only}
      M_Delta   = $20;   { codage normal / codage delta }
      M_Charge  = $80;   { Loaded / Not Loaded }

TYPE Char32=Array[1..32] of Char;
     Char22=Array[1..22] of Char;
     Char20=Array[1..20] of Char;
     Byte128=Array[1..128] of Byte;
     Byte256=Array[1..256] of Byte;

     Max_Channels_Byte   =Array[1..Max_Channels] of Byte;
     Max_Channels_Word   =Array[1..Max_Channels] of Word;
     Max_Channels_Longint=Array[1..Max_Channels] of Longint;
     Max_Channels_Integer=Array[1..Max_Channels] of Integer;

     Max_Samples_Byte   =Array[1..Max_Samples] of Byte;
     Max_Samples_Word   =Array[1..Max_Samples] of Word;
     Max_Samples_Longint=Array[1..Max_Samples] of Longint;
     Max_Samples_Integer=Array[1..Max_Samples] of Integer;

     Max_Pattern_Byte   =Array[1..Max_Pattern] of Byte;
     Max_Pattern_Word   =Array[1..Max_Pattern] of Word;
     Max_Pattern_Longint=Array[1..Max_Pattern] of Longint;
     Max_Pattern_Integer=Array[1..Max_Pattern] of Integer;

     T_Note=Record
             Periode    : Byte;    { 127: Key Off }
             Instrument,           { 1 to 100, 0: No Instrument }
             Commande,
             Parametre,
             Volume     : Byte;
            End;
     
     T_Note_NV=Record  { Without Volume }
             Periode: Byte;
             Instrument,Commande: Byte;
             Parametre: Byte;
            End; 	 

     T_Pattern=Array[1..2048] of T_Note;
	 T_Pattern_NV=Array[1..2048] of T_Note_NV;
	 
     Ptr_patt=^T_Pattern;
	 Ptr_patt_NV=^T_Pattern_NV; { Without Volume }

     TPeriodArray = ARRAY[0..95] OF WORD;
	 
	 T_InstrName = Array[1..24] of CHAR;
	 T_InstrNameTable = Array[1..Max_Samples] of T_InstrName;
	 
	 T_Instr=Record { Must remain 8 Bytes Long as stored in a table }
	          Sample_Nb     : Byte; { Number of the First Sample , FFh No Samples }
              Samples_Total : Byte; { Number of samples loaded }
              VolumeType    : Byte; { }
              PanningType   : Byte; { }
			  RelNote       : Byte;
	          Fill          : Byte;
              InstrDataSeg  : Word; { Instrument data Table if Sample and Volume table used }
             End;
			 
     T_InstrData=Record
                 NoteSmpTable : Array[1..96] of Byte;
				 VolSust      : Byte;
				 VolLoopStart : Byte;
				 VolLoopEnd   : Byte;
				 VolEnvTable  : Array[1..48] of Byte;
				 End;

     T_OPL2Instr=Record              { Instrument OPL2 (Adlib) }
                AM1,AP1   : Byte;    { 20-23h : AM_VIB_EG + Rythm (Batterie) }
                AM2,AP2   : Byte;    { 40-43h : KSL_VOLUM }
                AM3,AP3   : Byte;    { 60-63h : ATTCK_DEC }
                AM4,AP4   : Byte;    { 80-83h : SUSTN_REL }
                AM5,AP5   : Byte;    { E0-E3h : WAVEFORM  }
                AFeedBack : Byte;  {0Ch }
                End;                 				 
	 
     T_Sample=Record
              Case Boolean of
                True : (            { Digital sample }
                   Info    : Byte;  { Type de sample, Bouclage ... }
{                   Name     : Char32;}
                   Len     : Longint;
                   Rep     : Longint;
                   Rep_len : Longint;
                   Volume  : Byte;
				   Rel_Note  : Byte; { Relative Note XM }
                   C4Spd   : Word;
                   Adresse_GUS : Longint;
                   Mem     : TBlocMem;
                       );
                False :(           { Adlib Sample }
                   AInfo  : Byte;  { Type de sample, Bouclage ... }
{                   AName   : Char32;}
                   AVolume: Byte;
                   AC4Spd : Word;
                   AData  : T_OPL2Instr;
                   ARemplissage:Array[1..12] of Byte;
                        )
                  End;

    T_Table=Record       { Pointeurs vers les samples, Pattern et Sequence}
             Seg_Pattern    : Max_Pattern_Word;          { Pattern Segment in memory }
             PtrSamples     : Array[1..Max_Samples] of ^T_Sample; { Pointer to the sample header }
			  
             Volume_GUS   : Array[0..64] of Word;
             Table_Period : ARRAY[0..12*10] of Word;     { Note to Periods table      }
             Controle     : Byte; { Contr�le de l'int�grit� du bloc !!! }
            End;

{ * Music Data Structure, if changed, you need to re convert the .MMM Files * }
    T_Musique=Record
                Titre: Char32;
                Ch_Number,Ch_Number_patt  : Byte;
                Ch_Number_Digit,Ch_Number_Adlib : Byte;
			    Note_Delta:Word;      { (Ch_Number_patt-Ch_Number)*Note_Size }
			    C_Pattern : Boolean;  { True: Patern is compressed  }
			    Note_Size :Byte;      { 4 if no Volume, 5 otherwise }
				Nb_Instr  :Byte;      { Nb of Instruments (XM Only) }
                Nb_Total_Samples,     { Last Sample Number          }
                Nb_Samples,           { Nombre de samples non vide  }
                Nb_Samples_Loaded:Byte; { Nombre de samples charges   }
                Sequence_Len,Pos_de_restart   : Byte;
                Tempo_Start: Byte;
                BPM_Start  : Byte;
                Volume_General_depart : Byte;
                Octave_Min,Octave_Max : Byte;
                Type_Module   : Byte;
                Volume_Sl_rapide : Boolean;
                Vitesse_Ticks  : Byte;
			    Seg_Instr      : Word;                       { Instruments table Segment  }
				PtrInstrNameTable : ^T_InstrNameTable;       { Pointer to the Instrument name Table }
                M_CH_Type      : Max_Channels_Byte;          { Nothing/Sample/Adlib      }
				M_CH_Panning   : Max_Channels_Byte;          { Default Panning          }
                Voies_Adlib    : Array[1..11] of Byte;       { Map the Adlib channels to the real Channels (S3M) }
                Sequence       : Max_Pattern_Byte;           { Pattern Sequence          }
                Taille_Pattern : Max_Pattern_Byte;          { Pattern Number of Row     }
                Tempo_Pattern  : Max_Pattern_Byte;          { Pattern Default Tempo     }
                Controle       : Byte; { Controle de l'integrite du bloc !!! }
               End;

    T_Variables=Record
            Wave_Output  : Byte;             { The Selected Sound Output Number       }
            
			OPL_Model     : Byte;            { Internal OPL Type Selected / Available }
			OPL_LPT_Model : Byte;            { OPL LPT Type Selected / Available      }
			OPL_LPT_Nb    : Byte;            { Port Number for the OPL LPT            }
			
			TDY_Type     : Byte;
			TDY_LPT_Nb   : Byte;
			TDY_Port     : Word;            { Base Port for the Tandy 3 Channels     }
            TDYDAC_Port  : Word;            { Base Port for the Tandy DAC            }

            CMS_Type     : Byte;
            CMS_LPT_Nb   : Byte;
            CMS_Port     : Word;            { Base Port for the CMS                  }

            PSG_Type     : Byte;
            PSG_Port     : Word;            { Base Port for the PSG                  }
			
			LPT1_Port    : Word;
            LPT2_Port    : Word;
			CDAC_Port    : Word;
				  
			GUS_BasePort : Word;            { Gravis Ultrasound Base Port }
            GUS_InterWave :Boolean;         { False: Classic True: InterWave }
			GUS_IRQ      : Byte;
				  
            SB_BasePort  : Word;            { Sound Blaster Base Port }
            IRQ_SB,DMA_SB8,DMA_SB16: Byte;  { Sound Blaster IRQ, DMA  }
            MMType_SB  : Byte;              { Sound Blaster Type      }  {Changer Type...}
            Use_DMA,
            Utilise_DC,
            Utilise_stereo,
            Utilise_Filtre  : Boolean;
				                            { Mix Code Options }
            Utilise_Mixage,                 { Combine Left and Right in Stereo (No more implemented) }
            Utiliser_Interpolation,         { Sample interpolation  (No more implemented) }

            Mix_16Bit, Out_16Bit :Boolean;

            Out_Signed,
            Calculer_Panning: Boolean;      { Yes -> Calculate the result volumes, Needed for GUS }
            Mix_ChLimit_Type: Byte;         { 0 Off, 1: Auto 2: Manual                  }
            Mix_ChLimit_Nb  : Byte;         { FFh Off 0: Auto >0: Limit				    }

            Out_Frequency   : Word;
            Seg_Table_Volume,
            Buffer_Start_Offs: Word;
            Left_Buffer_Offs, Right_Buffer_Offs:Word;

            Musique_Term,Output_Stopped,Stop_Output: Boolean;

{            PAS_Handle_EMS: Word; }
{            Mus_Utilise_EMS: Byte;}
{            BPM_Base: Byte;}

            Use_BPM_CMD,Use_FineTune_CMD,Use_Panning_CMD : Boolean;
            Duree_intro   : Byte;  { Move to Music }
            Nb_boucles    : Byte;
            Touche_fin    : Byte;  { To move       }
            Seg_Video	  : Word;  { Video Segment }
            MMSS_Error    : Byte;

{ OtherMUS variables are for music other than module (RAD, VGM...) }
{            Mix_Late_Cnt  : Byte;}
            OtherMUS_Ptr  : Pointer; { Pointer to the Music File (VGM, RAD, RAW...) }
            OtherMUS_DataEnd : LongInt;
            OtherMUS_Out  : Byte;    { Mask with the Wave output used }
            debug1        : Word;
            debug2,debug3 : Word;

            Controle: Byte; { Controle de l'integrite du bloc }
            End;

     T_Info=Record
            Buffer_Samples_Nb       : Word;             { Single Buffer Size    }
            Buffers_Total_Size_Byte : Word;   { DMA Buffer Total Size }
			DMA_Buffers_Max_Size    : Word;        { Maximum Size we can allocate }
            Buffer_Current_Out_Offs : Word;
            Buffer_Cnt_50  : Word;

            Calcul_fini    : Byte;
            Pause          : Boolean;
			
            Pos_note       : Byte;  {Variables pour la lecture de la partition}
            Pos_sequence   : Byte;
            Num_pattern    : Byte;
            ModifierPattern: Boolean;
            Segment_pattern: Word;

            Volume_General : Byte;
            Tempo          : Byte;
            Cmpt_tempo     : Byte;
            BPM            : Byte;
            Cmpt_BPM       : Word;
			
            CH_Control    : Max_Channels_Byte;      { Channel Control Mask }
            CH_Panning    : Max_Channels_Byte;
            CH_Command    : Max_Channels_Word;
            CH_Per_part   : Max_Channels_Word;

            CH_Smp_Pla    : Max_Channels_Byte;
            CH_Note       : Max_Channels_Byte;
            Ch_Part_Vol  : Max_Channels_Byte;
            Ch_Volume    : Max_Channels_Byte;      { End volume (With Global Volume)}
            Ch_Final_Vol       : Max_Channels_Byte;      { Channel volume         }
            CH_Vol_Left   : Max_Channels_Byte;      { Left Volume (Panning)  }
            CH_Vol_Right  : Max_Channels_Byte;      { Right Volume (Panning) }
			VCurrent_CMD  : Max_Channels_Byte;
            VCurrent_PAR  : Max_Channels_Byte;
			Ch_Smp_Offs   : Max_Channels_Byte;

            Ch_Mix_Offs : Max_Channels_Word;      { Values for Mixing }
            VPart_entiere  : Max_Channels_Byte;
            VPart_decimaleh: Max_Channels_Byte;
			VPart_decimalel: Max_Channels_Byte;
            VAccumulateur  : Max_Channels_Word;

            VDadj                : Max_Channels_Word;
            Adresse_Table_periode: Max_Channels_Word;

            GUS_Frequency        : Max_Channels_Longint;
            GUS_Controle         : Max_Channels_Byte;
			MUS_OPLStream        : Boolean;
			
            Controle:Byte; { Controle de l'integrite du bloc }
            End;

CONST
      Mode_texte = 0;
      Mode_graphique = 1;
      Autre_Mode = 2;

      {Module Types}
      T_MOD = 0;
      T_STM = 2;   { Scream Tracker 2.0 }
      T_S3M = 3;   { Scream Tracker 3.x }
      T_669 = 4;   { Composer 669       }
      T_MTM = 5;   {                    }
      T_DTM = 6;   { Digital Tracker    }
      T_ULT = 7;   { Ultra Tracker      }
      T_FAR = 8;   { Farandole Tracker  }
      T_PTM = 9;
      T_SAT =10;   { Adlib Tracker      }
	  T_MON =11;
	  T_XM  =12;   { Fast Tracker 2     }
	  T_VGZ =13;
	  T_VGM =14;
	  T_RAD =15;
	  T_IMF =16;
	  T_RAW =17;
	  T_DRO =18;
	  T_MID =19;

      MMSS_Out_Nb_S=4;
	  {Synth Audio Outputs Numbers}
	  OPL     = 0;
	  OPLLPT  = 1;
	  TDY     = 2;
	  CMS     = 3;
      PSG     = 4;
	  
      { Mask for the Synth Output used by the Music }
	  M_Speaker = 1;
	  M_SN76489 = 2;
	  M_CMS     = 4;
	  M_SID     = 8;
	  M_OPL2    = 16;
	  M_OPL3    = 32;
	  M_SAA1099 = 64; { CMS }
      M_PSG     = 128;
	  
      {Commandes de la partition}
      Rien          =0;
      Arpeggio      =1;  {0 xy}
      PortUp        =2;  {1 xy}
      PortDown      =3;  {2 xy}
      TonePortamento=4;  {3 xy}
      Vibrato       =5;  {4 xy}
      Tone_VSlide   =6;  {5 xy}
      Vib_VSlide    =7;  {6 xy}
      Tremolo       =8;  {7 xy}
      CPanning      =9;  {8 xy}
      SampleOffs    =10; {9 xy}
      VolSlide      =11; {A xy}
      JumpPattern   =12; {B xy}
      SetVolume     =13; {C xy}
      EndPattern    =14; {D xy}
      Extended      =15; {E  x}
      SetTempo      =16; {F xy}

      SetFilter     =17; {E 0x}
      FinePortaUp   =18; {E 1x}
      FinePortaDown =19; {E 2x}
      GlissCtrl     =20; {E 3x}
      VibCtrl       =21; {E 4x}
      FineTune      =22; {E 5x}
      JumpLoop      =23; {E 6x}
      TremCtrl      =24; {E 7x}
      Rien2         =25; {E 8x}
      RetrigNote    =26; {E 9x} { pour S3M xy avec x, parametre volume slide }
      VolFineUp     =27; {E Ax}
      VolFineDown   =28; {E Bx}
      NoteCut       =29; {E Cx}
      NoteDelay     =30; {E Dx}
      PattDelay     =31; {E Ex}
      FunkIt        =32; {E Fx}

      SetBPM        =33;        { Fixer les BPM                 }
      SetGVolume    =34;        { Volume g�n�ral (S3M, XM)      }
      Tremor        =35;        { Tremor (STM,S3M)              }
      FreqAdj       =36;        { Ajustement de fr�quence (669) }
      ULTSpecial    =37;
      VibrSweep     =38;        { 'Profondeur' du vibrato       }
      Release       =39;        { Key Off (SAT) !!!!! A programmer !!!!! }
	  EFPortamento  =40;        { Extra Fine Portamento (XM,IT) }

      {Loading Error Codes}
      Ok             =0;
      Err_memoire    =1;   { Pas assez de m�moire pour charger le module }
      Err_format     =2;
      Err_lecture    =3;   { Fichier non trouv�           }
      Err_samples    =4;   { Fichier non charg� en entier }
      Err_No_Sample =5;    { Il n'y a pas de sample !!!   }
      Err_Unknown_Version=6;  { Version du fichier non geree ... }
      Err_Non_Gere   =7;   { Format de fichier non g�r�   }
	  Err_TooManyPat =8;

      {Erreurs non "critiques:": Ok et Err_samples}

      {Player Error Codes}

      PErr_Output_NotFound      =1; {La sortie indiqu�e n'existe pas (Ex:LPT2)}
      PErr_SB                   =2; {SB does not answer          (Disabled)   }	  
      PErr_Invalid_Freq         =3; {Not Correct Frequency                    }
      PErr_Too_Slow             =4; {The computer is too Slow to mix 1 channel}
      PErr_MOD_NotLoaded        =5; {Module Not Loaded                        }
	  PErr_Invalid_Channels     =6; {Invalid Nb of channels                   }
	  PErr_Invalid_File         =8;
	  PErr_OPL_NotFound         =9;
	  PErr_OPL3_NotFound        =10;
	  PErr_VGM_Command          =11;

      {Valeurs pour Touche_fin}
      Tfin_normale=0;
      Tfin_Esc    =1;
      Tfin_PgUp   =2;
      Tfin_PgDn   =3;

  { Table des p�riodes Amiga (et PC maintenant ;-) }
{  PeriodSet : Array[0..7] of Array[0..11] of Word = (}
    {  C     C#    D     D#    E     F     F#    G     G#    A     A#    B  }
{   ($1AC0,$1940,$17D0,$1680,$1530,$1400,$12E0,$11D0,$10D0,$0FE0,$0F00,$0E28),
    ($0D60,$0CA0,$0BE8,$0B40,$0A98,$0A00,$0970,$08E8,$0868,$07F0,$0780,$0714),
    ($06B0,$0650,$05F4,$05A0,$054C,$0500,$04B8,$0474,$0434,$03F8,$03C0,$038A),
    ($0358,$0328,$02FA,$02D0,$02A6,$0280,$025C,$023A,$021A,$01FC,$01E0,$01C5),
    ($01AC,$0194,$017D,$0168,$0153,$0140,$012E,$011D,$010D,$00FE,$00F0,$00E2),
    ($00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097,$008F,$0087,$007F,$0078,$0071),
    ($006B,$0065,$005F,$005A,$0055,$0050,$004B,$0047,$0043,$003F,$003C,$0038),
    ($0035,$0032,$002F,$002D,$002A,$0028,$0025,$0023,$0021,$001F,$001E,$001C));
}
  FineTuneConv: array[0..15] of WORD=
    (8363,8413,8463,8529,8581,8651,8723,8757,7895,7941,7985,8046,8107,8169,8232,8280);

    Tables_Modm:POINTER=NIL;    { Pointeur sur la table de volume }

{ Wave Outputs }
    MMSS_Output_Name: Array[0..7] of String[18] =
         ('PC Speaker','Covox DAC LPT1','Covox DAC LPT2','Custom DAC',
          'Tandy DAC','Sound Blaster','SB Pro/16/AWE','Gravis UltraSound');

    MMSS_Out_Nb_W=8;
{Wave Audio Outputs Numbers}
    HPint   = 0; { Haut parleur interne         }
    LPT1    = 1; { DAC (Covox) on LPT1          }
    LPT2    = 2; { DAC (Covox) on LPT2          }
    C_DAC   = 3; { Custom DAC                   }
    TDY_DAC = 4; { Tandy_DAC                    }
    { 5 and 6 Not used for the moment }
    SB      = 5; { Sound Blaster v1.X ou v2.X   }
    SBPro   = 6; { Sound Blaster Pro            }
    GUS     = 7; { Gravis UltraSound            }
    NoOut   = $0FF;
		  
{ Synth Output }
    MMSS_S_Output_Name : Array[0..3] of String[14] =
	     ('Yamaha OPL2/3','Yamaha OPL LPT','Tandy/SN76496','CMS/SAA1099');

VAR {PeriodArray: TPeriodArray ABSOLUTE PeriodSet;}


    MMSS_W_Output_Available: Array[0..MMSS_Out_Nb_W-1] of Boolean;
	MMSS_BestOutput : Byte;
	{MMSS_S_Output_Available: Array[0..MMSS_Out_Nb_S-1] of Boolean;}

    Taille_GUS: Integer;
    Panning_Utilisable:Boolean; {Si SBPro et calcul du panning ou GUS }

    MMSS_Volume     : Word;     { Volume to use for the volume table calculation }
	MMSS_Adj_Volume : Word;     { Adjuster/Real Volume used for volume table calculation  }

    TablePtr: Record
               Table,Variables,Info,Musique: Pointer
              End;

    MMSS_Table: ^T_Table;      { Various Tables                          }
    MMSS_CFG  : ^T_Variables;  { Main Variables for the config           }
    MMSS_Info : ^T_Info;       { Variables used during the replay        }
    Musique   : ^T_Musique;    { Music Datas/Header (Nb de voies...)     }

    { Global Variables used by the Music Loaders }

    MMSS_MUS_Loaded:Boolean;
    MMSS_EMS_First,MMSS_Use_UMB: Boolean;
    MMSS_Def_LeftPan,MMSS_Def_RightPan: Byte;
    Nb_Octaves_MOD:Byte;  { Number of octave to support in the .MOD Files }

    { Global Variables used by the ASM Part as well (EXTERNAL) }

    Change_Aff_Centre : Boolean;
    Changer_Affichage : Boolean;
    Mode_actuel       : Byte;
    Mode_a_afficher   : Byte;
    Cursor_On         : Boolean; { True if we want to display the cursor in the interface }

    car_barre_pitch, car_barre_periode,
    coul_barre_pitch, coul_barre_periode, coul_bout_pitch,
    Center_Display,
    TP_Duree_min, TP_Duree_sec, TP_Duree_50,
    TP_Chrono_min, TP_Chrono_sec : Byte;
    Key_ScanCode    :Byte;   {Pressed Key Scan Code}
    Activer_Shell:Boolean;
    Numero_module, Longueur_prog: Word;
    Nom_fichier: String[12];

    Shuffle,Programme: Boolean;

    Boucler_MOD : Boolean;

    Tick_50Hz :Byte;   {le 50�me de seconde pour l'affichage}
    TP_Fading:Boolean;


{==========================================================}

IMPLEMENTATION

END.