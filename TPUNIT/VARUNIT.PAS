{************************************************************************}
{                               VARUNIT.PAS                              }
{                                                                        }
{  Ensemble de variables, constantes, et types 'd'utilit‚s publique'     }
{                                                                        }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                                                                        }
{                               D‚but d'‚criture le 22/08/95             }
{                               DerniŠres modifications le 04/01/20      }
{************************************************************************}
UNIT VarUnit;

INTERFACE

CONST

   { 'Constantes' initialis‚es pas DSSUnit }

   DSS_Presente   : Boolean = False;      { Disney Sound Source ?  }

   { 'Constantes' initialis‚es pas SBUnit }

   Mixer_SBPro_Present : Boolean = False; { Mixer Sound Blaster Pro ?       }
   Mixer_SB16_Present  : Boolean = False; { Mixer Sound Blaster 16 ?        }
   SB_Presente    : Boolean = False;      { Sound Blaster ?       }
   BB_Presente    : Boolean = False;      { BlasterBoard ?        }
   SBPro_Presente : Boolean = False;      { Sound Blaster Pro ?   }
   SB16_Presente  : Boolean = False;      { Sound Blaster 16 ?    }

   OPL_Model      : Byte = 0;             { 0: Not Present,1:OPL2 2:OPL3    }
   OPL_LPT_Model  : Byte = 0;             { 0: Not Present,1:OPL2 2:OPL3    }

   { 'Constantes' initialis‚es pas GUSUnit }

   GUS_Presente   : Boolean = False;   { Pr‚sence de la Gravis Ultrasound     }

   { 'Constantes' initialis‚es pas Memoire }

   EMS_Presente : Boolean = False;
   UMB_Presente : Boolean = False;

   { 'Constantes' initialis‚es pas Hardware }

   LPT_Present : Array[1..4] of Boolean = (False,False,False,False);
   LPT_Nb      : Byte=0;    {  Number of LPT Ports Init in MODMUNIT.PAS}
{   COM_Present : Array[1..4] of Boolean = (False,False,False,False); }

TYPE

     TBlocMem = Record
                Segment      : Word;
                Handle_EMS   : Word;  { $FFFF, Pas en EMS }
                Nb_Pages_EMS : Byte;
                End;

IMPLEMENTATION

{==========================================================}

END.