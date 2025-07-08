{************************************************************************}
{                               TDYUNIT.PAS                              }
{                                                                        }
{  Tandy SN76496 and DAC Code, Detection and Init                        }
{                                                                        }
{  AUTEURS: Freddy V�tel�                                                }
{                                                                        }
{                               Code Start 6/06/20                       }
{************************************************************************}
UNIT PSGUNIT;
{$A+,Q-,G-,R-,S-}

INTERFACE

CONST

PSG_PortTotal = 2;
PSG_PortList : Array[0..2] of Word = (0,$220,$300); { covox, mindscape}

VAR

 PSG_Type    : Byte; { 0 : Nothing 1 : Internal}
 PSG_PortNb  : Byte; { Port Nb in the list } 
 PSG_Port    : WORD; { 0 Not present otherwise, Port }

IMPLEMENTATION

END.
