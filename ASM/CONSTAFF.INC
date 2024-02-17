;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ CONSTAFF.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗    บ
;            บ                                                   บ
;            บ           --==๐๐ Mod Master v2.2 ๐๐==--           บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   Auteur๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚ Freddy Vtel    บ
;            บ   Avec l'aide de๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚ Fabrice Couteau  บ
;            บ                                                   บ
;            บ   Dernire modification๚๚๚๚๚๚๚๚๚ 12/09/1995       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Mode_texte     EQU 0
Mode_graphique EQU 1
Autre_Mode     EQU 2

Caract_com DB ' ---- ','Arpegg','Porta','Porta','TonePr','Vibrat','TnPrVs','VibrVs'
           DB 'Tremol','Panng ','SmpOff','VolSld','PosJmp','SetVol','PatBrk','-Ext.-'
           DB 'Tempo ',' -E0- ','FineP','FineP','Gliss ','VibCtr','FineTn','LoopPt'
           DB 'TreCtr',' -E8- ','Retrig','VolFn','VolFn','NotCut','NotDel','PatDel'
           DB 'FunkIt','SetBPM','GlbVol','Tremor','FrqAdj','-ULTS-','-VbSw-','Rel   ','EFPort'

Caract_Wav DB 'Sine  ','H-Sine','A-Sine','P-Sine','E Sine','EASine','Square','DSquar'

If ModeXT Eq No
Table_note_Fr   DB 'Do ','Do#','R ','R#','Mi ','Fa '
                DB 'Fa#','Sol','So#','La ','La#','Si '
Endif

Table_note_Angl DB 'C-','C#','D-','D#','E-','F-'
                DB 'F#','G-','G#','A-','A#','B-'

Affichage_KeyOff DB '^^  '

; Center Display values (Center_Display Var in TP Data }
CD_Samples Equ 0
CD_Part    Equ 1
CD_Help    Equ 2
CD_Debug   Equ 3
CD_Bar     Equ 4 ; Volume/Perio Bar


