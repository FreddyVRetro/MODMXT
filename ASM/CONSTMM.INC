;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ CONSTMM.INC ÷÷÷÷÷÷÷÷÷÷÷÷÷÷     º
;            º                                                   º
;            º          --==ğğ Mod Master v2.2á ğğ==--           º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   Auteurúúúúúúúúúúúúúúúúúúúúúúúú Freddy V‚tel‚    º
;            º                                                   º
;            º   DerniŠre modificationúúúúúúúúú 29/08/1995       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
;                ** Tableaux de constantes pour Mod Master **

b Equ Byte Ptr
w Equ Word Ptr
d Equ DWord Ptr

InstrS Struc
	  ISample_Nb     DB ? ; Number of the First Sample , FFh No Samples
      ISamples_Total DB ? ; Number of samples loaded
      IVolumeType    DB ? ; Volume Envelope Type
      IPanningType   DB ? ;
	  IRelNote       DB ? ; Relative Note
      IFill          DB ? ; Not used
      IInstrDataSeg  DW ? ; Segment of the Note to Sample and Envelope data
InstrS Ends

Sampl struc
      SInfo          DB ?
      SLen           DD ?
      SRep           DD ?
      SRep_len       DD ?
      SVolume        DB ?
	  SRel_Note      DB ?   ; Relative Note, Signed (XM)
      SDadj          DW ?
      SAdresse_GUS   DD ?
      SSegment       DW ?   ;\
      SHandle_EMS    DW ?   ; |-- Bloc de M‚moire...
      SNb_Pages_EMS  DB ?   ;/
Sampl ends

Adlb struc
      AInfo          DB ?
;     ANom           DB 32 DUP (?)
      AVolume        DB ?
      ADadj          DW ?
      AM1            DB ?    ; Modulateur (1 ø ParamŠtre)
      AP1            DB ?    ; Porteuse   (1 ø ParamŠtre)
      AM2            DB ?
      AP2            DB ?
      AM3            DB ?
      AP3            DB ?
      AM4            DB ?
      AP4            DB ?
      AM5            DB ?    ; Modulateur (5 ø ParamŠtre)
      AP5            DB ?    ; Porteuse   (5 ø ParamŠtre)
      AFeedBack      DB ?
      AFill          DB 12 DUP (?)
Adlb ends

; Masque pour les Infos sur le sample

M_Adlib  EQU 1
M_NSigne EQU 2
M_16bit  EQU 4
M_Boucle EQU 8
M_Bidi   EQU 16
M_Charge EQU 128

; Masques pour les modifications des voies (Pour GUS et Adlib)

M_ChSample  EQU 1   ; Change the Sample
M_ChPeriode EQU 2   ; Change the Period
M_ChVolume  EQU 4   ; Change the Volume
M_ChPanning EQU 8   ; Change the Panning

; VControl Byte Mask, for Channels control

CM_Stopped    EQU 1   ; Set to 1 When the Channel is Stopped (Key Off, Sample end...)
CM_Disabled   EQU 2   ; Set to 1 When the channel is disables
CM_KeyOff     EQU 4   ; Set to 1 When Key Off
M_VolChanged  EQU 8   ; For the Volume Pitch Display
CM_NoteCut    EQU 16  ; Set to 1 Stop the sound
M_FadeVol     EQU 32  ; Volume Fading (XM Envelope)
CM_FStop      EQU 64  ; 1 if the Disable was forced (Red spot on Display)
CM_FPause     EQU 128 ; 1 if the sample mix is Paused (Brown spot on Display)

; Envelope Type Mask (XM)

E_On      EQU 1
E_Sustain EQU 2
E_Loop    EQU 4

; ** Channel Control masques ** (USMPlay, for Reference)

CC_Stopped   EQU 1      ; Active/Stopped channel                 (0)
CC_Playing   EQU 2      ; A sample is played on this channel     (1)
CC_StopVoice EQU 4      ; Stop the sample                        (2)
CC_FadeVol   EQU 8      ; Fading active                          (3)
CC_Release   EQU 16     ; Channel is released                    (4)

CC_ChSample   EQU 32     ; Change channel sample                  (5)
CC_ChPeriod   EQU 64     ; Change channel period                  (6)
CC_ChVolume   EQU 128    ; Change channel volume                  (7)
CC_CH_Panning EQU 256    ; Change channel panning                 (8)
CC_DoRelease  EQU 512    ; Stop sustain loop                      (9)
CC_Surround   EQU 1024   ; Surround                               (10)
CC_Backgrnd   EQU 2048   ; Background channel


b Equ Byte Ptr
w Equ Word Ptr
d Equ DWord Ptr

;Erreurs Mod Master...

Err_Output_NotFound      EQU 1 ; {La sortie indiquee n'existe pas (Ex:LPT2)}
Err_SB                   EQU 2 ; {SB does not answer          (Disabled)   }
Err_Invalid_Freq         EQU 3 ; {Not Correct Frequency                    }
Err_Too_Slow             EQU 4 ; {The computer is too Slow to mix 1 channel}
Err_MOD_NotLoaded        EQU 5 ; {Module Not Loaded                        }
Err_Invalid_Channels     EQU 6 ; {Invalid Nb of channels                   }
Err_Invalid_MOD          EQU 7 ; {Format error or not supported            }
Err_OPL_NotFound         EQU 8 ;
Err_OPL3_NotFound        EQU 9 ;
Err_TDY_NotFound         Equ 10
Err_CMD_NotSupported     EQU 11; { VGM Command not supported               }
Err_CMS_NotFound         EQU 12;

;sorties sonores

HPint   EQU 0  ; PC Speaker
LPT1    EQU 1  ; DAC on LPT1
LPT2    EQU 2  ; DAC on LPT2
C_DAC   EQU 3  ; Custom DAC
T_DAC   EQU 4  ; Tandy DAC
SB      EQU 5
SBPro   EQU 6  ; Sound Blaster Pro/16
GUS     EQU 7
NoOut   EQU 0FFh ;

; Mask for the Synth Output used by the Music 
M_Speaker EQU 1;
M_SN76489 EQU 2;
M_CMS     EQU 4;
M_SID     EQU 8;
M_OPL2    EQU 16;
M_OPL3    EQU 32;
M_SAA1099 EQU 64;


;Type de module

T_MOD EQU 0
T_STM EQU 2   ;{ Scream Tracker 2.0 }
T_S3M EQU 3   ;{ Scream Tracker 3.x }
T_669 EQU 4   ;{ Composer 669       }
T_MTM EQU 5   ;{                    }
T_DTM EQU 6   ;{ Digital Tracker    }
T_ULT EQU 7   ;{ Ultra Tracker      }
T_FAR EQU 8   ;{ Farandole Tracker  }
T_PTM EQU 9
T_SAT EQU 10   ;{ Adlib Tracker     }
T_MON EQU 11
T_XM  EQU 12   ;{ Fast Tracker 2    }
T_VGZ EQU 13
T_VGM EQU 14
T_RAD EQU 15
T_IMF EQU 16
T_RAW EQU 17
T_DRO Equ 18
T_MID Equ 19

Ta_vib   DB   0, 24, 49, 74, 97,120,141,161,180,197,212,224,235,244,250,253
         DB 255,253,250,244,235,224,212,197,180,161,141,120, 97, 74, 49, 24
         ;Partie negative du sinus
         DB   0, 24, 49, 74, 97,120,141,161,180,197,212,224,235,244,250,253
         DB 255,253,250,244,235,224,212,197,180,161,141,120, 97, 74, 49, 24

Ta_rampe DB 255,247,239,231,223,215,207,199,191,183,175,167,159,151,143,135
         DB 127,120,112,104, 96, 88, 79, 72, 64, 56, 47, 40, 32, 24, 16,  8
         DB 0  ,  8, 16, 24, 32, 40, 47, 56, 64, 72, 79, 88, 96,104,112,120
         DB 127,135,143,151,159,167,175,183,191,199,207,210,223,231,239,247

Ta_carre DB 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
         DB 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
         DB 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
         DB 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255

Nb_Octaves_Total EQU 8

Align 2
Mini_Octaves DW 0E28h*4,0E28h*2,0E28h,0714h,038Ah,01C5h,00E2h,0071h,0038h,001Ch  ; *4
Maxi_Octaves DW 1AC0h*4,1AC0h*2,1AC0h,0D60h,06B0h,0358h,01ACh,00D6h,006Bh,0035h

Total_FineTune EQU 12*8

; Table de conversion pour le HP interne

T_bep DB 20h,1Fh,1Eh,1Dh,1Ch,1Bh,1Ah,19h,18h,17h,16h,15h,14h,13h,12h,11h
      DB 11h,10h,10h,0Fh,0Fh,0Eh,0Eh,0Dh,0Dh,0Dh,0Ch,0Ch,0Ch,0Ch,0Bh,0Bh
      DB 0Bh,0Bh,0Ah,0Ah,0Ah,0Ah,0Ah,09h,09h,09h,09h,09h,09h,09h,09h,09h
      DB 08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,07h,07h,07h,07h
      DB 07h,07h,07h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,05h,05h
      DB 05h,05h,05h,05h,05h,05h,05h,05h,04h,04h,04h,04h,04h,04h,04h,04h
      DB 04h,04h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,02h,02h,02h,02h
      DB 02h,02h,02h,02h,02h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h

      DB 40h,40h,40h,40h,40h,40h,40h,40h,40h,40h,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
      DB 3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh
      DB 3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch
      DB 3Ch,3Ch,3Ch,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Ah,3Ah,3Ah
      DB 3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,39h,39h,39h,39h,39h,39h,39h,39h,39h
      DB 39h,38h,38h,38h,38h,38h,38h,38h,38h,37h,37h,37h,37h,37h,36h,36h
      DB 36h,36h,35h,35h,35h,35h,34h,34h,34h,33h,33h,32h,32h,31h,31h,30h
      DB 30h,2Fh,2Eh,2Dh,2Ch,2Bh,2Ah,29h,28h,27h,26h,25h,24h,23h,22h,21h
; Table de conversion pour la carte Adlib (Synt‚ OPL 2)

T_Adlib DB 63,56,51,48,45,43,41,40,38,37,36,35,34,34,33,32
        DB 31,31,30,29,29,28,28,27,27,26,26,26,25,25,24,24
        DB 24,23,23,23,22,22,22,21,21,21,21,20,20,20,20,19
        DB 19,19,19,18,18,18,18,18,17,17,17,17,17,16,16,16
        DB 16,16,15,15,15,15,15,15,14,14,14,14,14,14,14,13
        DB 13,13,13,13,13,13,12,12,12,12,12,12,12,12,11,11
        DB 11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10
        DB 10, 9, 9, 9, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8
        DB  8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
        DB  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5
        DB  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4
        DB  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3
        DB  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2
        DB  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
        DB  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
        DB  1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

