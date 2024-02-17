{************************************************************************}
{                                MM_PLAY.PAS                             }
{                                                                        }
{  Manage Mod Master during the Replay (Display, Dos Shell...)           }
{                                                                        }
{  AUTEUR: Freddy V‚tel‚.                                                }
{                                                                        }
{                                                                        }
{                               Code Start the 30/08/95                  }
{                               Last Update the 10/19                    }
{************************************************************************}

UNIT MM_PLAY;

{$A+,G-,Q-,R-,S-}
{$I MODMCFG.INI}


INTERFACE

USES Crt,Dos,Texte,Util,Memoire,Clavier,SBUnit,ModmUnit,MM_Var,MM_DIV,
     MMSS_Var
{$IFDEF MONOTONE}
     ,mt_edit,mt_play
{$ENDIF} ;


{$IfNDEF CGAOnly}
PROCEDURE Affiche_Boule(Position:Word; Couleur:Byte);
PROCEDURE Aff_Graph;
PROCEDURE Init_Palette_Graphique;
{$ENDIF}
PROCEDURE MM_Playing_Interface;  { Affichage pendant la musique... }
PROCEDURE MM_Init_PlayingScreen_Text;
PROCEDURE MM_Display_PlayingScreen_Text;
PROCEDURE Display_ModInfo_Frame;
PROCEDURE Display_AdlInfo_Frame;
PROCEDURE Shell;
PROCEDURE Centrer_Titre;

IMPLEMENTATION

VAR TitreCentre27: Array[1..27] of Char;
    OldInt2F : Pointer;

CONST
      position_msg:String[22]='Pattern           Line';
      tempo_msg   :String[22]='Tempo    BPM      Gvol';
      volume_msg  :String[6] ='Volume';

{=========================================================}


PROCEDURE MM_Playing_Interface;  { Affichage pendant la musique... }
Begin

 Changer_Affichage:=True;
 Clignotement(True);
 Curseur(off);
 
 Repeat
  If Activer_Shell Then
   Begin
    Shell;            { Lancer le Shell }
    Changer_Affichage:=True;
    Activer_Shell:=False;
   End;
  If Changer_Affichage Then
   Begin
    MM_Init_PlayingScreen_Text;
    Changer_Affichage:=False;
   End;
  MM_ASM_UpdateInterface;   { Read Keys and Update the Display, in the Assembly code }
  { Manage the Keys in case of .MON file replay}
{$IFDEF MONOTONE}
  if Musique^.Type_Module=T_MON then
     Case Key_ScanCode of
       01: MMSS_CFG^.Output_Stopped:=True;
       57: If MMSS_Info^.Pause then
	      Begin                  { Disable Pause }
               MT_Player^.MyPlayer^.Send(pa_PlaySongCur);
               MMSS_Info^.Pause:=False;
	      End
	       else
              Begin                  { Enable Pause  }
	           MT_Player^.MyPlayer^.Send(pa_Stop);
               MMSS_Info^.Pause:=True;
              End;
		77: MT_Player^.MyPlayer^.Send(pa_NextOrder);
		75: MT_Player^.MyPlayer^.Send(pa_PrevOrder);
{scanLeft   EQU 75       ;retour rapide }
     End;
{$ENDIF}
  { Attente du 50ø de seconde       }
  Repeat Until (Tick_50Hz=1) OR MMSS_CFG^.Output_Stopped OR KeyPressed;

  Tick_50Hz:=0;
 Until MMSS_CFG^.Output_Stopped; { Attente de la fin de la musique }

{ If Fading Then Volume_Total:=Volume_Saved; }
 VideBufferClavier;
End; {MM_Playing_Interface}

{=========================================================}

PROCEDURE MM_Init_PlayingScreen_Text;
Begin
 Mode_Actuel:=Mode_Texte;
 MM_Display_PlayingScreen_Text; { PASCAL }
 If MMSS_Info^.MUS_OPLStream then Display_AdlInfo_Frame
    Else Display_ModInfo_Frame;
 Affiche_Ecran_Texte; { ASM }
 Change_aff_centre:=True;	
End;

{---------------------------------------------------------}

PROCEDURE LigneDessus(x,y,xfin: Byte);
Var Pos,Cmpt:Word;
Begin
 Pos:=2*(x-1)+160*(y-1);
 Cmpt:=xfin-x;
 ASM
  PUSH DS
  MOV AX,SegTexte
  MOV ES,AX
  MOV DI,Pos  
  MOV AX,256*112+'Ü'
  MOV CX,Cmpt
  INC CX
  REP STOSW
  POP DS
 End
End; {LigneDessus}

{---------------------------------------------------------}

PROCEDURE LigneH(x,y,xfin: Byte; Caractere:Char);
Var Pos,Cmpt:Word;
Begin
 Pos:=2*(x-1)+160*(y-1);
 Cmpt:=xfin-x;
 ASM
  PUSH DS
  MOV AX,SegTexte
  MOV ES,AX
  MOV DI,Pos  
  MOV AH,112
  MOV AL,Caractere
  MOV CX,Cmpt
  INC CX
  REP STOSW
  POP DS
 End
End; {LigneH}

{---------------------------------------------------------}

PROCEDURE LigneV(x,yh,yb:Byte; Caractere:Char; Attr:Byte);
Var Pos,Cmpt:Word;
Begin
 Pos:=2*(x-1)+160*(yh-1);
 Cmpt:=yb-yh+1;
 ASM
  PUSH DS
  MOV AX,SegTexte
  MOV ES,AX
  MOV AH,Attr
  MOV AL,Caractere
  MOV DI,Pos
  MOV CX,Cmpt
 @boucle:
  STOSW
  ADD DI,160-2
  LOOP @boucle
  POP DS
 End
End; {LigneV}

{---------------------------------------------------------}
{ Display the Main Frame during the replay }

PROCEDURE MM_Display_PlayingScreen_Text;

Begin

{ Screen Cleanup and Horizontal Lines } 
 ASM
{  PUSH DS}
 PUSH ES
  MOV AX,SegTexte
  MOV ES,AX
  XOR DI,DI

  MOV AX,256*31+' '
  MOV CX,80
  REP STOSW                    {efface ligne 1 en blue            }

  MOV AH,112
  MOV CX,80*(4-2+1)
  REP STOSW                    {efface lignes 2,3 en blanc       }

  MOV AH,0
  MOV CX,80*(23-5+1)
  REP STOSW                    {efface le reste de l'‚cran en noir }

  MOV AH,112
  MOV CX,80
  REP STOSW                    {Line 24 in white                   }

  MOV AX,256*31+' '
  MOV CX,80
  REP STOSW                    {Put Last Line in Blue              }
 POP ES   
 End;

 AffChXY(0,32,1,'- MOD MASTER XT -',31); { Titre "Mod Master" }

{ Bottom line Display } 
 AffChXY(0,72,25,'F1=Help',31);
 AffChXY (0,52,25,'Free Memory: '+EntierTexte(MemoireDOSLibre SHR 6,3)+'Kb',31);

 If Musique^.Type_Module=T_MON Then AffChXY(0,2,25,'PC Speaker',31)
  Else
   If (Musique^.Type_Module=T_SAT) or (Musique^.Type_Module=T_RAD) 
      or (Musique^.Type_Module=T_RAW) or (Musique^.Type_Module=T_DRO)
      or (Musique^.Type_Module=T_IMF) then AffChXY(0,2,25,'Adlib (OPL2/OPL3)',31)
  Else 
   If (Musique^.Type_Module=T_VGM) then 
          Begin { VGM Stream Music }
           If (MMSS_CFG^.OtherMUS_Out AND M_OPL2)<>0 then AffChXY(0,2,25,'Adlib/OPL2 (YM3812)',31);
           If (MMSS_CFG^.OtherMUS_Out AND M_OPL3)<>0 then AffChXY(0,2,25,'OPL3 (YMF262)',31);
           If (MMSS_CFG^.OtherMUS_Out AND M_SN76489)<>0 then AffChXY(0,2,25,'Tandy/PC Jr (SN76489)',31);
		   If (MMSS_CFG^.OtherMUS_Out AND M_SAA1099)<>0 then AffChXY(0,2,25,'Game Blaster/CMS/SAA1099',31);
          End
  Else
   If MMSS_CFG^.Wave_Output=GUS Then AffChXY(0,2,25,'Gravis UltraSound',31)
     Else
      Begin
	   If MMSS_CFG^.Wave_Output in [SB,SBPro]
	      then AffChXY(0,18,25,SBName[SBConfig.Type_],31)
               else AffChXY(0,18,25,MMSS_Output_Name[MMSS_CFG^.Wave_Output],31);
       If MMSS_CFG^.Wave_Output=HPint then AffChXY(0,2,25,EntierTexte(MMSS_CFG^.Out_Frequency,5)+' Hz 6Bit',31)
	      Else If MMSS_CFG^.Out_16Bit then AffChXY(0,2,25,EntierTexte(MMSS_CFG^.Out_Frequency,5)+' Hz 16Bit',31)
          Else AffChXY(0,2,25,EntierTexte(MMSS_CFG^.Out_Frequency,5)+' Hz 8Bit',31);
      End;

End; {MM_Display_PlayingScreen_Text}

{ Title, Volume and period bar, Infos }

Procedure Display_ModInfo_Frame;

Begin

 LigneV(1,4,24,' ',112);   {Left Border  }
 LigneV(80,4,24,' ',112);  {Right Border }
{ LigneH(25,4,53,' ');   }          {Title / Infos Rectangle }
 
 AffChXY(0,26,4,TitreCentre27,15);
 AffChXY(0,27,6,position_msg,2);
 AffChXY(0,27,7,tempo_msg,2);
 AffChXY(0,27,8,volume_msg,2);

 LigneH(2,4,24,'Ü');              {Pitch Bar Rectangle  }
 LigneH(2,9,24,'ß');
 
 LigneH(26,3,52,'Ü');             {Title / Infos Rectangle }
 LigneH(26,9,52,'ß');             {fenetre infos           }
 
 LigneH(54,4,79,'Ü');             {fenetre barres periode  }
 LigneH(54,9,79,'ß');
 
 LigneH(2,10,79,'Ü');             {fenˆtre centrale        }
 
 LigneV(25,5,9,' ',112);   {separation fenetres pitch/centrale  }
 LigneV(53,5,9,' ',112);   {separation fenetres centrale/periode}
End;

Procedure Display_AdlInfo_Frame;
Begin

 LigneV(1,4,24,' ',112);   {Left Border  }
 LigneV(80,4,24,' ',112);  {Right Border }

 LigneH(26,3,52,'Ü');
 LigneH(26,5,52,'ß'); 
{ LigneH(2,4,79,' ');}
 LigneH(2,5,25,' ');
 LigneH(53,5,79,' ');

 AffChXY(0,26,4,TitreCentre27,15);
 End;

{---------------------------------------------------------}

{$F+}
PROCEDURE NewInt2F; Interrupt;

Begin
  ASM
      CMP AX,60FFh
      JNE @Non
      CMP DL,0
      JNE @Non
      CMP BX,5344h   { SD }
      JNE @Non
      CMP CX,4D50h   { MP }
      JNE @Non
      MOV AX,1234h   { 1234h => Mod Master pr‚sent !!! }
  @Non:
      PUSHF
      CALL OldInt2F
  End;
End;
{$F-}

{---------------------------------------------------------}

PROCEDURE Int2FOn;
Begin
 SwapIntVec($2F,OldInt2F,@NewInt2F)
End;

{---------------------------------------------------------}

PROCEDURE Int2FOff;
Begin
 SwapIntVec($2F,OldInt2F,OldInt2F)
End;

{---------------------------------------------------------}

PROCEDURE Shell;
Var Mem_DOS_Libre: Word;
    anc_prompt,nouv_prompt: String80;
Begin
 TextMode(LastMode);       { Mode texte DOS                      }
 Mode_Actuel:=Autre_Mode;  { Indique le changement de mode vid‚o }
 Curseur(plat);
 Mem_DOS_Libre:=MemoireDOSLibre DIV 64;
 ClrScr;

 If Mem_DOS_Libre>=64 Then
  Begin
   Writeln('Free memory: ',Mem_DOS_Libre-2,
           'ko - Type EXIT to return to Mod Master...',#13#10);
   anc_prompt:=GetEnv('PROMPT');
   nouv_prompt:='[Mod Master] ';
   If anc_prompt<>'' Then nouv_prompt:=nouv_prompt+anc_prompt
                     Else nouv_prompt:=nouv_prompt+'$p$g';
 {$IFNDEF CGAOnly}
   FinSourisSmooth;
 {$ENDIF}
   Int2FOn;      { Active l'IRQ de d‚tection    }
   SwapVectors;
   Exec(Getenv('COMSPEC'),'/K PROMPT '+nouv_prompt);
   SwapVectors;
   Int2FOff;     { D‚sactive l'IRQ de d‚tection }
 {$IFNDEF CGAOnly}
   InitSourisSmooth(#166,#167,#169,#170);
 {$ENDIF}
   If DosError<>0 Then
    Begin
     If DosError=8 Then Writeln('Not enough memory!')
                   Else WriteLn('DOS error #',DosError);
     Write('Hit ÄÙ...');
    { Repeat Until Readkey=#13}
    End
  End
 Else
  Begin
   Write('Not enough memory (',MemoireDOSLibre,'ko). Hit ÄÙ...');
  { Repeat Until Readkey=#13}
  End;

{ MM_InitTexte;}
End; {Shell}

{---------------------------------------------------------}

PROCEDURE Centrer_Titre;
Var i,Pos,Len:Byte;
Begin

 FillChar(TitreCentre27,27,0);
 Pos:=0;
 Len:=27;
 With Musique^ do    { Titre Centr‚ avec 27 caractŠres }
  Begin
   Repeat            { Chercher le 1ø CaractŠre        }
    Inc(Pos);
    Dec(Len);
   Until ((Titre[Pos]<>#0) AND (Titre[Pos]<>#32)) OR (Pos=27);
   Inc(Len);
   If Pos<27 Then
    Begin          { Chercher le dernier CaractŠre   }
     i:=28;
     Repeat
      Dec(i);
      Dec(Len);
     Until ((Titre[i]<>#0) AND (Titre[i]<>#32)) OR (i=1);
     Inc(Len);
    End;
   i:=1+(27-Len) SHR 1;
   Move(Titre[Pos],TitreCentre27[i],Len);
  End;

End; {Centrer_Titre}

{---------------------------------------------------------}

PROCEDURE Afficher_Nom_Samples;
Var i:Byte;
    Samp:^T_Sample;
Begin
{For i:=1 to 15 do
 Begin
  Samp:=MMSS_Table^.PtrSamples[i];
  If Samp<>NIL Then AffChXY(0,14,12+i,Samp^.Nom,3)
 End;}
End; {Afficher_Nom_Samples}

{=========================================================}

END.