{ Interrupt 13h Floppy fonctions }
{ By FreddyV }

UNIT BIOSDisk;
{$A+,Q-,R-,S-}

INTERFACE

TYPE Byte9k=Array[1..9216] of Byte;

TYPE TDOSBootSector=RECORD
       JMPCode : Array[1..3] of Byte;
	   OSName  : Array[1..8] of Char;
	   BPS            : Word;                {Bytes per Sector}
	   SPerCluster    : Byte;
	   ReservedSector : Word;
	   FATNb          : Byte;
	   RootEntries    : Word;
	   TotalSectors   : Word;
	   MediaDescription : Byte;
	   SPerFat          :Word;
	   SPerTrack        :Word;
	   Sides            :Word;
	   ZeroBytes : Array[1..10] of Byte;
	   ExtBPB    : Byte;
       END;
	   
VAR
  Floppy_error : Byte;

Function BIOS_InitFloppy(FId:Byte) : Byte;
Function BIOS_FloppyReadSector(FId:Byte;Head:Byte;Track:Byte;Sector:Byte;SectorNb:Byte;Buffer:Byte9k):Byte;

IMPLEMENTATION

{bit(s)	Description
 15-14  Number of parallel devices.
 13     Reserved.
 12     Game port installed.
 11-9   Number of serial devices.
 8      Reserved.
 7-6    Number of floppy disk drives (minus 1):
          00 single floppy disk;
          01 two floppy disks;
          10 three floppy disks;
          11 four floppy disks.
 5-4    Initial video mode:
          00 EGA,VGA,PGA, or other with on-board video BIOS;
          01 40x25 CGA color.
          10 80x25 CGA color (emulator default).
          11 80x25 mono text.
 3      Reserved.
 2      PS/2 mouse is installed.
 1      Math coprocessor installed.
 0      Set when booted from floppy. }

Function BIOS_FloppyNb : Byte; Assembler;
ASM
  INT 11h
  TEST AL,00000001b
  JZ @NoFloppy  { Bit 0=0  }
  MOV CL,6
  SHR AL,CL
  AND AL,00000011b
  INC AL
  JMP @FNEnd
@NoFloppy:
  XOR AX,AX
@FNEnd:
End; {BIOS_FloppyNb}

Function BIOS_InitFloppy(FId:Byte) : Byte; Assembler;
ASM
  XOR AH,AH
  MOV DL,FId
  INT 13h
  MOV AL,AH 
  MOV Floppy_Error,AL
End; {BIOS_InitFloppy}

Function BIOS_FloppyReadSector(FId:Byte;Head:Byte;Track:Byte;Sector:Byte;SectorNb:Byte;Buffer:Byte9k):Byte; Assembler;
ASM
  MOV AH,02h
  MOV AL,SectorNb
  MOV CH,Track
  MOV CL,Sector
  MOV DH,Head
  MOV DL,FId
  AND DL,1      { Be sure we send 0 or 1 Only as Floppy ID}
  LES BX,Buffer
  INT 13h
  MOV AL,AH 
  MOV Floppy_Error,AL { Copy the Error code }
End; {BIOS_FloppyNb}

END. { Unit End }