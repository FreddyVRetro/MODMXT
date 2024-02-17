UNIT DOSStruc;

 {(C) Copyright 1991, Earl F. Glynn, Overland Park, KS.  Compuserve
73257,3527.

  All Rights Reserved.  This Turbo Pascal UNIT may be freely distributed
  only for non-commercial use.}

INTERFACE

  USES
    DOS;

  TYPE
                              {DOS control blocks follow}
    DiskParameterBlockPointer = ^DiskParameterBlock;
      {See pp. 743-744, "Waite Group's MS-DOS Developer's Guide, Second
       Edition, and pp. 129-133, "PC Tech Journal", February 1989}
    DiskParameterBlock      =
      RECORD                                             { offset }
        Drive               :  BYTE;   {0=A,1=B}         {  0 $00 }
        UnitWithinDriver    :  BYTE;   {0,1,2,...}       {  1 $01 }
        BytesPerSector      :  WORD;                     {  2 $02 }
        SectorsPerCluster   :  BYTE;   {SPC - 1}         {  4 $04 }
        ClusterToSectorShift:  BYTE;                     {  5 $05 }
        ReservedSectors     :  WORD;                     {  6 $06 }
        FATTables           :  BYTE;                     {  8 $08 }
        RootDirEntries      :  WORD;                     {  9 $09 }
        FirstDataSector     :  WORD;                     { 11 $0B }
        Clusters            :  WORD;   {Clusters + 1}    { 13 $0D }
        SectorsPerFAT       :  WORD;   {BYTE in DOS 3.X} { 15 $0F }
        RootDirSector       :  WORD;                     { 17 $11 }
        DeviceHeader        :  pointer;                  { 19 $13 }
        MediaType           :  BYTE;                     { 23 $17 }
        Valid               :  BYTE;                     { 24 $18 }
        NextDPB             :  DiskParameterBlockPointer { 25 $19 }
      END;

    DOSListOfLists      =  {DOS 3.X.  See Waite Group's Guide, p. 746}
      RECORD                                             { offset  }
        FirstMCBSegment :  WORD;                         { -2 -$02 }
        misc1           :  ARRAY[1..16] OF BYTE;         {  0  $00 }
        MaxBytesPerBlock:  WORD;                         { 16  $10 }
        misc2           :  ARRAY[1..4]  OF BYTE;         { 18  $12 }
        BaseDA          :  Pointer;                      { 22  $16 }
        misc3           :  ARRAY[1..6]  OF BYTE;         { 26  $1A }
        NumBlockDevices :  BYTE;                         { 32  $20 }
        LastDrive       :  BYTE  {from CONFIG.SYS}       { 33  $21 }
      END;

  VAR
    ListOfLists:  ^DOSListOfLists;
    MaxDrive   :  WORD;
    MinDrive   :  WORD;
    ValidDrive :  ARRAY[1..26] OF BOOLEAN;

  FUNCTION  NumberOfFloppyDrives:  BYTE;
  FUNCTION  FirstFloppyDrive:  BYTE;         {1=A, 2=B}
  PROCEDURE MakeFirstFloppy (drive:  BYTE);  {1=A, 2=B}

  PROCEDURE DetermineValidDrives;

  FUNCTION DiskLocation (Drive:  BYTE):  STRING;

  FUNCTION DefaultDrive:  BYTE;  {1=A, 2=B, ..., 26=Z}

  FUNCTION DriveLetter (Drive:  BYTE):  CHAR;

  FUNCTION GetCurrentDirectory (Drive:  BYTE):  STRING;

  PROCEDURE GetFreeDiskSpace
                      (Drive:  BYTE;   {1=A, 2=B, ..., 26=Z}
                       VAR Valid                 :  BOOLEAN;
                       VAR SectorSize,ClusterSize:  WORD;
                       VAR Capacity, Available   :  LongInt);

  PROCEDURE GetDPB (Drive:  BYTE;  VAR Valid:  BOOLEAN;
                                   VAR DPB:  DiskParameterBlock);

{??????????????????????????????????????????????????????????????????????}

IMPLEMENTATION

  CONST
    ByteArraySize  =  50000;

  TYPE
    ByteArray      =  ARRAY[0..ByteArraySize] OF BYTE;
    ByteArrayPtr   =  ^ByteArray;

  VAR
    buffer                 :  ARRAY[1..64] OF CHAR;
    DefaultFloppy          :  BYTE;
    ExitSave               :  Pointer;
    r                      :  Registers;
    SingleDriveLogicalDrive:  BYTE ABSOLUTE $0000:$0504;

{?????  Floppy Drives  ????????????????????????????????????????????????}

  {The next two FUNCTIONs and PROCEDURE were derived from ONEDRIVE.PAS,
   PC Magazine, Sept. 26, 1989, pp. 380-381, and Appendix A, "Memory Map",
   "Compute!'s Mapping the IBM PC", pp. 234-235, 246, and Ray Duncan's
   "IBM ROM BIOS".}

  FUNCTION  NumberOfFloppyDrives:  BYTE;
    VAR r:  Registers;
  BEGIN   {BIOS interrupt is "safer" than absolute memory reference}
    Intr ($11,r);       {r.AX contains equipment list code word}
    IF   (r.AX AND $0001) = 1
    THEN NumberOfFloppyDrives := ((r.AX SHR 6) AND $0003)+1
    ELSE NumberOfFloppyDrives := 0
  END {NumberOfFloppyDrives};

  FUNCTION  FirstFloppyDrive:  BYTE;         {1=A, 2=B}
  BEGIN
    IF   NumberOfFloppyDrives > 1
    THEN FirstFloppyDrive := 1
    ELSE FirstFloppyDrive := SingleDriveLogicalDrive + 1
  END {FirstFloppyDrive};

  PROCEDURE MakeFirstFloppy (drive:  BYTE); {1=A, 2=B}
  BEGIN
    IF   NumberOfFloppyDrives = 1
    THEN SingleDriveLogicalDrive := drive-1
  END {MakeFirstFloppy};

{?????  DetermineValidDrives  ?????????????????????????????????????????}

  PROCEDURE DetermineValidDrives;
    VAR
      drive :  BYTE;
      floppy:  BYTE;
      r     :  Registers;
  BEGIN
    MinDrive := 0;
    floppy := FirstFloppyDrive;
    FOR drive := 1 TO 26 DO BEGIN
      IF   (NumberOfFloppyDrives = 1) AND (drive IN [1..2])
      THEN BEGIN
        ValidDrive[drive] := (drive = floppy);
        MakeFirstFloppy (drive)
      END
      ELSE ValidDrive[drive] := TRUE;

      IF   ValidDrive[drive]
      THEN BEGIN
        r.AH := $36;             {DOS 2,3:  Get Free Disk Space}
        r.DL := drive;
        INTR ($21,r);
        ValidDrive[drive] := (r.AX <> $FFFF)
      END;

      IF   ValidDrive[drive]
      THEN BEGIN
        IF   MinDrive  = 0
        THEN MinDrive := drive;
        MaxDrive := drive
      END

    END;
    MakeFirstFloppy (floppy)
  END {DetermineValidDrives};

{?????  Determine if Drive is Local/LAN ???????????????????????????????}

  FUNCTION DiskLocation (Drive:  BYTE):  STRING;
    VAR r:  Registers;
  BEGIN
    r.AH := $44;
    r.AL := $09;    {DOS 3.1 and after}
    r.BL := drive;
    INTR ($21,r);
    IF   (FCarry AND r.Flags) <> 0
    THEN DiskLocation := '??????'
    ELSE
      IF   (r.DX AND $1000) = $1000
      THEN DiskLocation := 'LAN'
      ELSE DiskLocation := 'Local'
  END {DiskLocation}; 