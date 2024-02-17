{$O+,F+}
{$R-,S-,G-,Q-}
{
Generic support routines, JL19871013.
Last updated: 20180713
}

{{$DEFINE DEBUG}

unit support;

interface

uses
  DOS;

const
  HexNybble:array[0..15] of char='0123456789ABCDEF';
  vidp:pointer=ptr($b800,0);
  maxbufsize=$10000-$10;

type
  s79=string[79];
  s12=string[12];
  str2=string[2];
  s16=string[16];
  screenParamsType=record
    cursorsize,cursorpos:word;
    videomode,videopage,
    videorows,videocols:byte;
  end;

var
  TicksSinceMidnight:longint ABSOLUTE $0040:$006C;
  DriveMotorStatus:Byte ABSOLUTE $0040:$003F;
  oldScreenParams:screenParamsType;

Function FileExists(filename:String):Boolean;
Function DirExists(dirname:String):Boolean;
Function SizeOfFile(filename:string):longint;
Procedure MkDirCDir(Target : String);
Function IntToStr(I:LongInt):s12;
Function StrToInt(s:s12):LongInt;
Function RealToStr(r:real):string;
Function StrToReal(s:s79):real;
Function NumToExt(w:word):s12;
Function boolToStr(b:boolean;ys,ns:s12):s12;
Function ReadKeyChar:Char;
Function KeyPressed:Boolean;
Function upstring(s:string):string;
Function downstring(s:string):string;
Function upchar(c:char):char;
Function EXEsize(fname:string):longint;
Function DiskReady(Drive:char):boolean;
Function hex(l:longint):s12;
Function hexword(w:word):s12;
Procedure moveword(src,dst:pointer;size:word); {Built for speed, DOES NOT HANDLE OVERLAPPING BLOCKS AT ALL!}
Procedure fillword(dst:pointer;size:word;filler:byte);
Procedure FatalError(errnum:byte;s:string);
Function BuffersEqual(p1,p2:pointer;size:word):word; {compares two buffers; reports 0 if equal, or offset where not}
Function p2l(p:pointer):longint; {converts an x86 16-bit seg:ofs pointer to a 20-bit linear offset}
function l2p(l:longint):pointer; {converts a 20-bit linear offset to an x86 16-bit seg:ofs pointer}
Function SubPtr(p:Pointer;d:LongInt):Pointer;
Function AddPtr(p:Pointer;d:LongInt):Pointer;
Function NormPtr(p:pointer):pointer; {Normalizes an x86 16-bit seg:ofs pointer}
Function split(line:string;delimiter:char;position:byte):string;
Function GetTimer:word;
Procedure RecordDOSScreen;
Procedure RestoreDOSScreen;
Procedure CursorON;
Procedure CursorOFF(page:byte);
Procedure CursorMoveTo(x,y,page:byte);
procedure SlamString80x25(x,y:integer;s:string;attr:byte);
{extremely fast and compact way to put text onto an 80x25 screen at page 0}
function root(x,y:real):real; {find xth root of y}
function gcd(a,b:longint):longint; {greatest common divisor (recursive)}
function gcd_i(a,b:longint):longint; {greatest common divisor (iterative)}
function lcm(i,j:longint):longint; {least common multiple}
function ticks2micro(l:longint):longint;
function ticks2ms(l:longint):longint;
(*Function HexNybble(b:byte):char; {converts nybble to ascii hex equivalent}*)
Function ByteToHex(b:byte):str2; {converts byte to ascii hex equivalent}
Function HexCharToByte(c:char):byte;
Function HexStrToLong(s:string):longint;
Function IntPadded(l:longint;num:byte;padc:char):s12; {returns value padded with num padchars}
procedure StrPadAfter(var str:OpenString;b:byte);
{Pads a string with nulls after position b}
Procedure WaitFloppySpindown;
procedure doswrite(s:string);
procedure doswriteln(s:string);
Procedure FileToSTDOUT(filename:string);
function SearchString(var s:string; var buf; buflen:word):word; {returns position found in buffer, or $FFFF if not found}
Function SimpleMenu(title,m:string):byte;
{Simple menu.
If EXIT or anything above it is chosen, 0 is returned, signifying an exit.}
Function InV86:boolean; {returns TRUE if we are already in protected mode}
Function DosVer:word; {returns DOS version lo(major) hi(minor) number}
Function curdate:s12;
Function basename(ins:string):string; {returns filename without extension}
Procedure tSeek(Var f : Text; n : LongInt);
Function StdPath(p:PathStr):PathStr;
Procedure strReplace(var _str:string;pattern,value:string);
function byteswap(var a,b:byte):byte;
function stdDate:s16;
Function clustsize (drive : Byte) : Word;

implementation

{preserve DOS screen stuff}
var
  screenp:pointer;

{end DOS screen preserve}

Function DiskReady(Drive:char):boolean;
var
  ChkDrvBuf : array[0..512] of byte;  {for drive checking routine}

begin
  {original code by Brian Pape with mods by G. Davis}
  asm
    cmp  drive,'a'
    jb   @isupcase
    sub  drive,20H  { make it UPPER case }
    @isupcase:
    cmp  drive,'Z'
    jb   @driveok
    mov  drive,'A'  { if drive isn't between 'A' and 'Z', make it A) }
    @driveok:
    mov  ax, seg ChkDrvBuf
    mov  es, ax
    mov  bx, offset ChkDrvBuf

    mov  ah, 02  { read disk sectors }
    mov  al, 1   { number of sectors to transfer }
    mov  ch, 1   { track number }
    mov  cl, 1   { sector number }
    mov  dh, 1   { head number }

    mov  dl, drive
    sub  dl, 'A'     { subtract ORD of 'A' }

    int  13h

    mov  bl,true { assume drive is ready }
    and  ah,$80
    jz   @done   { error was something other than disk not ready }
    mov  bl,false{ disk wasn't ready. store result }
    @done:

    mov  ax,$0000  { reset drive }
    INT  13H

    xor  ax,ax   { shut off disk drive quickly }
    mov  es,ax
    mov  ax,440h
    mov  di,ax
    mov  byte ptr es:[di],01h

    mov  al,bl   { retrieve result }
  end;
end;  { diskready }

Function EXEsize(fname:string):longint;
Type
  t_size = Record
    mz:Array [1..2] of Char;
    remainder,
    pages:Word;
  end;

Var
  f:File of t_size;
  sz:t_size;

begin
  assign(f,fname);
  {$i-}
  reset(f);
  {$i+}   { io checking should be off }
  if (ioresult <> 0)
    then exesize:= 0
    else begin
      read(f,sz);
      close(f);
      With sz do exesize := remainder + (pred(pages) * 512);
    end;
end;

Function upstring(s:string):string; assembler;
asm
  push  ds
  cld
  lds   si,s
  les   di,@result
  lodsb
  stosb
  xor   ah,ah
  xchg  ax,cx
  jcxz  @done

@upstringloop:
  lodsb
  cmp   al,'a'
  jb    @noconvert
  cmp   al,'z'
  ja    @noconvert
  sub   al,20h
@noconvert:
  stosb
  loop  @upstringloop

@done:
  pop   ds
end;

Function downstring(s:string):string; assembler;
asm
  push  ds
  cld
  lds   si,s
  les   di,@result
  lodsb
  stosb
  xor   ah,ah
  xchg  ax,cx
  jcxz  @done

@upstringloop:
  lodsb
  cmp   al,'A'
  jb    @noconvert
  cmp   al,'Z'
  ja    @noconvert
  add   al,20h
@noconvert:
  stosb
  loop  @upstringloop

@done:
  pop   ds
end;

Function upchar; assembler;
asm
  mov   al,c
  cmp   al,'a'
  jb    @noconvert
  cmp   al,'z'
  ja    @noconvert
  sub   al,20h
@noconvert:
end;


Function FileExists(filename:string):boolean;
begin
  fileExists := fSearch(filename, '') <> '';
end;


Function SizeOfFile(filename:string):longint;
Var
  f:File;
  foo:LongInt;
Begin
  If fileexists(filename) Then Begin
    Assign(f,filename);
    Reset(f,1);
    foo:=FileSize(f);
    Close(f);
    sizeoffile:=foo;
  End Else SizeOfFile:=-1;
End;

Function IntToStr;
Var
  S:s12;
Begin
  Str(I,S);
  IntToStr:=S;
End;

Function StrToInt;
var
  i:LongInt;
  foo:Integer;
Begin
  Val(S,i,foo);
  strtoint:=i;
End;

Function RealToStr;

Var
  s:String;

begin
  {if exponent is bigger than 1E7 or smaller than 1E-7, perform unformatted conversion}
  if ((r>1E-7) and (r<1E7))
    then Str(r:12:12, s)
    else Str(r, s);
  {delete trailing zeros, periods and leading spaces}
  While s[ord(s[0])]='0' do Delete(s, ord(s[0]), 1);
  While (s[1]=' ') do Delete(s, 1, 1);
  if s[ord(s[0])]='.'
    then Delete(s, ord(s[0]), 1);

  RealToStr:=s;
end;

Function StrToReal;
var
  r:real;
  error:integer;
Begin
  Val(s,r,error);
  if error=0
    then StrToReal:=r
    else StrToReal:=0;
End;

Function NumToExt;
var
  s:s12;
begin
  s:=IntToStr(w);
  if w < 100 then s:='0'+s;
  if w < 10 then s:='0'+s;
  NumToExt:=s;
end;

Function KeyPressed:Boolean; Assembler;
Asm
  mov ah, 01h
  int 16h
  mov ax, 00h
  jz @1
  inc ax
  @1:
end;

Function ReadKeyChar:Char; Assembler;
Asm
  mov ah, 00h
  int 16h
  cmp al,0
  jne @endit
  mov al,ah
@endit:
end;

Function hex;
Var
  s:s12;
Begin
  s:='';
  If l=0
    Then s:='0'
    Else While l<>0 Do Begin
      s:=hexNybble[(l And $f)]+s;
      l:=l ShR 4;
    End;
  hex:=s;
End;

Function hexword;
var
  s:s12;
Begin
  s:=hex(w);
  while byte(s[0])<4 do
    s:='0'+s; {pad to 4 characters}
  hexword:=s;
End;

procedure moveword(src,dst:pointer;size:word); assembler;
{DOES NOT HANDLE OVERLAPPING BLOCKS AT ALL!}
asm
  push ds
  les  di,dst
  cld  {put cld here so it can be prefetched during the slow LES opcode}
  lds  si,src
  mov  cx,size
  shr  cx,1    {if number is odd, bit will be shifted off into carry flag}
  rep  movsw
  adc  cx,cx   {if carry set cx=1 else cx=0}
  rep  movsb   {if cx=0 nothing happens. Why we do this? To avoid costly JMP!}
  pop  ds
end;

procedure fillword;assembler;
asm
  les  di,dst
  cld  {put cld here so it can be prefetched during the slow LES opcode}
  mov  al,filler
  mov  ah,al {fill AX with filler byte}
  mov  cx,size
  shr  cx,1 {adjust for words; if number is odd, bit will be shifted off into carry flag}
  rep  stosw {fill}
(*
  jnc  @end {if no carry, we're done}
  stosb {otherwise, number was odd so we had another byte to do}
@end:
*)
  adc  cx,cx {if carry set, cx=1 else cx=0}
  rep  stosb {if cx=0, nothing happens}
end;

function BuffersEqual;assembler;
asm
  push ds
  lds si,p1
  les di,p2
  mov cx,size
  xor ax,ax {assume test will be successful}
  cld
  repe cmpsb
  cmp cx,0
  je @done
  mov ax,size {if cx<>0 then buffers are not equal}
  sub ax,cx
  dec ax {to report offset instead of absolute location}
@done:
  pop ds
end;

procedure fatalerror;
begin
  RestoreDOSScreen;
  {writeln('Fatal (',errnum,'): ',s);}
  writeln('Fatal error: ',s);
  halt(errnum);
end;

Function P2L(p: Pointer): LongInt; Assembler;
{Converts an x86 16-bit seg:ofs pointer to a linear address}
Asm
   mov ax,word ptr [p+2] {seg}
   mov dx,ax
   mov cl,12             {ssssssssssssssss:ssssssssssssssss}
   shr dx,cl             {000000000000ssss:ssssssssssssssss}
   mov cl,4
   shl ax,cl             {000000000000ssss:ssssssssssss0000}
   add ax,word ptr [p]   {000000000000ssss:oooooooooooooooo}
   adc ax,0              {000000000000sssS:oooooooooooooooo}
End;

Function L2P(l: LongInt): Pointer; Assembler;
{converts 20-bit linear offset into seg:ofs pointer}
Asm
   mov dx,word ptr [l+2]
   mov ax,word ptr [l]
   mov bx,ax
   and ax,0Fh              {so that :AX returns only remainder}
   mov cl,4
   shr bx,cl               {divide ofs by 16 to get quotient}
   mov cl,12
   shl dx,cl
   add dx,bx
End;

Function NormPtr(p: Pointer): Pointer; Assembler;
{Normalizes an x86 16-bit seg:ofs pointer.}
{  NormPtr:=l2p(p2l(p));}

Asm
   mov dx,word ptr [p+2] {seg}
   mov ax,word ptr [p]   {ofs}
   mov bx,ax             {bx=ofs}
   and ax,0Fh            {ax=offset remainder}
   mov cl,4
   shr bx,cl             {bx=ofs div 16=num paragraphs}
   add dx,bx             {increase seg by # of paragraphs}
End;

Function SubPtr(p:Pointer;d:LongInt):Pointer;
Begin
  SubPtr:=L2P(P2L(p)-d)
End;

Function AddPtr(p:Pointer;d:LongInt):Pointer;
Begin
  AddPtr:=L2P(P2L(p)+d);
End;

Function split(line:string;delimiter:char;position:byte):string;
const
  maxoffset:byte=0;
  maxsplitsperline=40;

var
  loop:byte;
  offsets:array[0..maxsplitsperline] of byte;
  tempstr:string;
begin
  maxoffset:=0;
  fillchar(offsets,0,sizeof(offsets));
  (* Get list of offsets first *)
  (* first entry is always 0 *)
  offsets[maxoffset]:=0;
  maxoffset:=1;
  for loop:=1 to length(line) do begin
    if line[loop]=delimiter
      then begin
        offsets[maxoffset]:=loop;
        inc(maxoffset);
      end;
  end;
  (* Last entry is always maximum end of string *)
  offsets[maxoffset]:=length(line)+1;
  (* Now that we have a list of offsets, use them *)
  if position<=maxoffset
  (* if the user is asking for a split part that will exist *)
    then begin
      tempstr:=copy(line,offsets[position-1]+1,offsets[position]-offsets[position-1]-1);
    end else begin
    (* else, supply bogus value as error *)
      tempstr:=#0;
    end;
  split:=tempstr;
end;

Function GetTimer:word;assembler;
{gets low word of timer and returns it in AX}
{If using this for timing, remember that it is always counting DOWN}
asm
  MOV  AL,00000110b  {Channel 0, Latch Counter, Square Wave, Binary}
  OUT  43h,AL        {Tell timer about it}
  IN   AL,40h        {Get LSB of timer counter}
  MOV  AH,AL         {Save it in AH for a second}
  IN   AL,40h        {Get MSB of timer counter}
  XCHG AH,AL         {Put things in the right order; return in AX}
end;

Procedure CursorOFF;assembler;
asm
  {first get existing cursor, then set it to disappear}
  mov ah,3
  mov bh,page
  int 10h
  mov oldScreenParams.cursorsize,cx
  mov ah,1
  mov cx,2000h
  int 10h
end;

Procedure CursorON;assembler;
{this is meant to be called after a CursorOFF, otherwise results unpredictable!}
asm
  mov ah,1
  mov cx,oldScreenParams.cursorsize
  int 10h
end;

Procedure CursorMoveTo;assembler;
asm
  mov dh,y {row}
  mov dl,x {col}
  mov ah,2
  mov bh,page
  int 10h
end;

Procedure RecordDOSScreen;
begin
  asm
    {get existing video mode and page}
    mov ah,0fh
    int 10h
    mov oldScreenParams.videomode,al
    mov oldScreenParams.videopage,bh
    mov oldScreenParams.VideoCols,ah
    {
    Number of rows not returned by BIOS.  Have to calc number of rows from:
        40:4A	word	Number of screen columns
        40:4C	word	Size of current video regen buffer in bytes
        40:84	byte	Rows on the screen (less 1, EGA+)

    Try to get from 40:84 first.  If early BIOS has that empty, then calc
    it based on the info it does give us.
    }
    mov ax,40h
    mov es,ax
    mov al,es:[84h]
    cmp al,0                            {our BIOS new enough to populate this?}
    jne @newbios                        {if so, use it}
    mov bx,es:[4ah]                     {if not, calc ourselves}
    mov ax,es:[4ch]
    shr ax,1
    div bl
    dec al
@newbios:
    inc al
    mov oldScreenParams.videoRows,al
    {get cursor size and position}
    mov ah,3
    int 10h
    mov oldScreenParams.cursorsize,cx
    mov oldScreenParams.cursorpos,dx
  end;
end;

Procedure RestoreDOSScreen;
begin
  asm
    {restore old video mode}
    mov ah,00
    mov al,oldScreenParams.videomode
    int 10h
    {put cursor back to old location}
    mov ah,2
    mov bh,oldScreenParams.videopage
    mov dx,oldScreenParams.cursorpos
    int 10h
    {put cursor back to old size}
    mov ah,1
    mov cx,oldScreenParams.cursorsize
    int 10h
  end;
end;

procedure SlamString80x25(x,y:integer;s:string;attr:byte);assembler;
{extremely fast and compact way to put text onto an 80x25 screen at page 0}
asm
  mov bx,y
  shl bx,1
  mov ax,bx
  shl bx,1
  shl bx,1
  add ax,bx
  add ax,$b800
  mov es,ax     { es:=$B800 + (Yx$80 + Yx$20) shr 4 or $B800+Y*$A }
  mov di,x
  shl di,1      { di:=x shl 1 }

  mov ah,attr
  push ds
  lds si,s
  lodsb
  mov cl,al
  xor ch,ch
@1:
  lodsb
  stosw
  loop @1

  pop ds
end;

function root(x,y:real):real;
{find the xth root of y}
begin
  root:=exp(ln(y)/x);
end;

function gcd(a,b:longint):longint;
begin
  if b = 0
    then gcd:=a
    else gcd:=gcd(b,a mod b)
end;

{!! should probably convert this to http://en.wikipedia.org/wiki/Binary_GCD_algorithm at some point}

function gcd_i(a,b:longint):longint;
var
  t:longint;
begin
  while b<>0 do begin
    t := b;
    b := a mod b;
    a := t;
  end;
  gcd_i:=a;
end;

function lcm(i,j:longint):longint;
begin
  lcm:=abs((i*j) div gcd_i(i,j));
end;

function ticks2micro(l:longint):longint;
{converts number of ticks to microseconds}
const
  ticktime=0.8381;
begin
  ticks2micro:=trunc(l / ticktime);
end;

function ticks2ms(l:longint):longint;
{converts number of ticks to milliseconds}
const
  ticktime=0.8381;
begin
  ticks2ms:=round((l/ticktime) / 1000);
end;

(*
Function HexNybble(b:byte):char; assembler;
{thanks to Norbert Juffa}
asm
  mov al,b
  cmp al,10       {if x<10, set CF=1}
  sbb al,69h      {0-9: 96h..9Fh, A-F: A1h..A6h}
  das             {0-9: subtr. 66h -> 30h-39h;
                   A-F: subtr. 60h -> 41h-46h}
end;
*)

(* if you want more speed, copy this into your module that uses it:
Function HexNybble(w:word):char;
inline(
  $58/               {pop    ax}
  $3C/$0A/           {cmp    al,0A}
  $1C/$69/           {sbb    al,69}
  $2F                {das}
); *)

Function ByteToHex(b:byte):str2; assembler;
asm
  les di,@result          {note our destination}
  mov al,2                {choose our length}
  stosb                   {write it}
  mov al,b                {grab and prepare input}
  mov ah,al               {copy to ah}
  shr ah,1                {shift ah to be a nybble}
  shr ah,1                {shift ah to be a nybble}
  shr ah,1                {shift ah to be a nybble}
  shr ah,1                {shift ah to be a nybble}
  and al,00001111b        {mask out unwanted bits}
  mov bx,offset HexNybble {point to our translation table}

  {these next four lines cannot change order:}
  xlat                    {translate al}
  xchg ah,al              {swap with ah}
  xlat                    {translate "ah"}
  stosw                   {store result to destination string}
end;

Function HexCharToByte(c:char):byte;
{ranges (ascii): 48-57, 65-70}
begin
  c:=upcase(c);
  if c in [#65..#70]
    then HexCharToByte:=byte(c)-(65-10)
    else HexCharToByte:=byte(c)-48;
end;

Function HexStrToLong(s:string):longint;
{returns hexadecimal string as decimal value - very unoptimized routine!}
VAR
  Len   : byte absolute S;
  Loop  : byte;
  Li    : longint;
  Num   : longint;

BEGIN
  {treat any leading characters in the string}
  if S [1] = '$' then delete (S, 1, 1);
  if upcase (S [Len]) = 'H' then dec (S [0]);
  Num := 0;
  for Loop := 1 to Len do begin
    Li := 0;
    while (HexNybble[Li] <> S [Loop]) and (Li < 16) do inc (Li);                            { inc counter }
    if Li = 16 then begin
      Num := -1;                           { -1 if invalid }
      exit;
    end;
    Num := Num + Li shl ((Len - Loop) * 4);   { add to Num }
  end;
  HexStrToLong := Num;                          { return value }
END;

Function IntPadded; {returns value padded with num 0's}
Var
  s:s12;
Begin
  str(l,s);
  while byte(s[0])<num do s:=padc+s; {pad to num characters}
  IntPadded:=s;
End;

Procedure WaitFloppySpindown;
{Waits for all floppy drives to spin down, or 5 seconds, whichever comes
first.  This is desirable because many 486 and lower computers slow down to
8MHz while the floppy drive is operational (for compatibility with old copy
protection schemes, amongst other reasons).}
const
  maxWaitSecs=5; {wait up to five secs for the disk drive motors to shut off}
  threshold=trunc(maxWaitSecs*18.2);
var
  l:longint;
begin
  l:=TicksSinceMidnight;
  repeat
    asm
      hlt {do nothing; wait for something interesting}
    end;
  until (DriveMotorStatus and $0F=0) or (TicksSinceMidnight-l > threshold);
  {wait an additional second, as some machines need more safety margin}
  l:=TicksSinceMidnight;
  repeat
    asm
      hlt {do nothing; wait for something interesting}
    end;
  until (TicksSinceMidnight-l > 18);
end;

Procedure FileToSTDOUT(filename:string);
var
  f:text;
  s:string[79];
begin
  assign(f,filename);
  reset(f);
  while not eof(f) do begin
    readln(f,s);
    doswriteln(s);
  end;
  close(f);
end;

procedure doswrite(s:string); assembler;
asm
  push    ds
  cld
  lds     si,s
  lodsb
  xor     ah,ah
  xchg    cx,ax           {cx=#0 of string which contains length}
  jcxz    @exit           {if string is length 0 then bail}
  mov     ah,2            {get ready for DOS func. INT 21,2 - Standard Output}
@L1:
  lodsb
  mov     dl,al           {ah=02, dl=character to output}
  int     21h             {do it}
  loop    @L1
@exit:
  pop     ds
end;

procedure doswriteln(s:string);
begin
  doswrite(s+#13#10);
end;

function SearchString(var s:string; var buf; buflen:word):word; assembler;
{returns position found in buffer, or $FFFF if not found}
ASM
  push    ds                {preserve DS (pascal requirement)}
  les     di,buf            {es:di=buffer search space}
  mov     cx,buflen         {cx=length of buffer}
  jcxz    @fail             {if buffer length 0, don't bother searching}
  lds     si,s              {ds:si=string to match}
  mov     al,[si]           {load string length}
  or      al,al             {if 0, zf=1}
  je      @fail             {if string length 0, don't bother searching}
  xor     ah,ah             {ax=string length}
  cmp     ax,cx             {compare string length to buffer size}
  ja      @fail             {if string length > buffer size, don't bother}
  mov     bx,si             {bx=string index}
  dec     cx                {}
  cld                       {search FORWARD please}
@L1:
  mov     si,bx             {reset string index pos}
  lodsw                     {load lengthbyte and firstbyte of string}
  xchg    al,ah             {ah=string length, al=search character}
  repne   scasb             {search for the character}
  jne     @fail             {didn't find it at all?  Then it's not present}
  dec     ah                {decrement string length}
  or      ah,ah             {}
  je      @finished         {if length=0, we're done searching}

  inc     cx                {}
  xchg    cx,ax             {}
  mov     cl,ch             {}
  xor     ch,ch             {cx=string length}
  mov     dx,di             {dx=buffer pos}
  repe    cmpsb             {compare string to buffer}
  mov     di,dx             {di=buffer pos}
  mov     cx,ax             {}
  loopne  @L1               {}
@finished:
  mov     ax,buflen         {}
  sub     ax,cx             {}
  dec     ax                {ax=position the string was found}
  jmp     @done             {}
@fail:
  mov     ax,0ffffh         {FFFF means failure}
@done:
  pop     ds                {restore DS (pascal requirement)}
end;

Function SimpleMenu(title,m:string):byte;
(*
Simple menu.
If EXIT or anything above it is chosen, 0 is returned, signifying an exit.

Here is example code on how to use simplemenu:

  repeat
    choice:=SimpleMenu('Main Menu',
    'Display System List~Import Result File~Save Database~Export to .CSV');
    case choice of
      1:PrintSystemList(Systems);
      2:begin
          write('File(s) to import (wildcards ok): ');
          readln(temps);
        end;
      3:SaveDatabase(Systems);
      4:SaveDatabaseCSV(Systems);
    end;
  until choice=0;
*)

var
  b:byte; curmax:byte;
begin
  write(#13#10,title,#13#10); for b:=1 to length(title) do write('-'); writeln;
  curmax:=1; write(curmax,'. ');
  for b:=1 to length(m) do begin
    case m[b] of
    '~':begin inc(curmax); write(#13#10,curmax,'. '); end;
    else write(m[b]);
    end;
  end;
  inc(curmax); write(#13#10,curmax,'. Exit');
  writeln;
  b:=strToInt(readkeychar);
  if b>=curmax then b:=0;
  SimpleMenu:=b;
end;

function InV86:boolean;assembler;
asm
  xor  ax,ax
  cmp  System.Test8086,2
  jl   @done
  db   $0f,$20,$c0 {mov eax,cr0} {get status of protected mode}
  and  al,1                      {bit 1 is protected mode flag}
(*
  test ax,1                      {test if protmode flag is up}
  mov  al,0
  jz   @done                     {if not, we're done}
  mov  al,1                      {otherwise, continue and put up a flag}
*)

@done:
end;

function DOSVer:word;assembler;
asm
  mov     ah,30h
  int     21h     {al=maj, ah=min}
end;

function curdate:s12;
var
  h, m, s, hund : Word;

  function LeadingZero(w : Word) : String;
  var
    s : String;
  begin
    Str(w:0,s);
    if Length(s) = 1 then
      s := '0' + s;
    LeadingZero := s;
  end;

begin
  GetTime(h,m,s,hund);
  curdate:=LeadingZero(h)+':'+LeadingZero(m)+':'+LeadingZero(s)+'.'+LeadingZero(hund);
end;

Function basename(ins:string):string;
{chops extension off of a filename}
var
  b:byte;
begin
  for b:=0 to 3 do if ins[length(ins)-b]='.'
    then delete(ins,length(ins)-b,b+1);
  basename:=ins;
end;

Procedure tSeek(Var f : Text; n : LongInt); Assembler;
{MARCO MILTENBURG's procedure for seeking in a text file}
Asm
  push  DS
  push  BP

  lds   SI, f
  lodsw                                 { handle }
  mov   BX, AX

  mov   CX, Word ptr [BP+8]
  mov   DX, Word ptr [BP+6]

  mov   AX, 4200h                       {AL = 2, AH = 42}
  int   21h

  les   DI, f
  mov   AX, DI
  add   AX, 8
  mov   DI, AX

  lodsw                                 { mode }
  lodsw                                 { bufsize }
  mov   CX, AX                          { CX = number of Bytes to read }
  lodsw                                 { private }
  lodsw                                 { bufpos  }
  lodsw                                 { bufend  }
  lodsw                                 { offset of Pointer to Textbuf }
  mov   DX, AX                          { DX = offset of Textbuf }
  lodsw
  mov   DS, AX                          { DS = segment of Textbuf }
  mov   AH, 3Fh
  int   21h
  push  AX                              { Save AX on stack }

  les   DI, f                           { ES:DI points to f }
  mov   AX, DI                          { Move Pointer to position 8 }
  add   AX, 8
  mov   DI, AX

  mov   AX, 0                           { Bufpos = 0 }
  stosw
  pop   AX                              { Bufend = number of Bytes read }
  stosw

  pop   BP
  pop   DS
end; { tSeek }

function DirExists(dirname:string):boolean;
var
  f:file;
  Attr:word;
begin
  {truncate trailing slashes}
  while dirname[length(dirname)] = '\' do dec(dirname[0]);
  {add directory modifier to truncated dirname}
  dirname:=dirname+ '\.';
  {try to get its attributes and report status}
  assign(f,dirname);
  getfattr(f,Attr);
  DirExists := ((Attr and Directory) = Directory );
end;

Procedure MkDirCDir(Target : String);
{ Purpose:      - Make directories where they don't exist               }
{                 ie. MkDirCDir('D:\HI.ZZZ\GEEKS\2JKD98');              }
{ Useful notes: - seems to handles even directories With extentions     }
{                 (i.e. DIRDIR.YYY)                                     }
{               - there are some defaults that have been set up :-      }
{                 change if needed                                      }
{               - doesn't check to see how legal the required directory }
{                 is (i.e. spaces, colon in the wrong place, etc.)      }
{ (original public-domain code's author unknown, enhancements by JL)    }

Var
  Slash : Array[1..(122 div 2)] of byte;
  i,
  count   : Integer;
  dir,
  home,
  tempdir,
  OurDir : String;

begin
  {Don't make a directory structure that already exists}
  if DirExists(target)
    then exit;

  GetDir(0,OurDir); { because we'll use CHDIR to confirm directories }

  { sample directory below to make }
  Dir := Target;
  { add slash at end if not given }
  if Dir[Length(Dir)] <> '\' then
    Dir := Dir + '\';
  { if colon where normally is change to that drive }
  if Dir[2] = ':' then begin
    {$IFDEF DEBUG} writeln('** Changing to drive of ',dir); {$ENDIF}
    ChDir(Copy(Dir, 1, 2))
  end else
  { assume current drive (and directory) }
  begin
    GetDir(0, Home);
    if (Dir[1] = '\') then
      Dir := Home + Dir
    else
      Dir := Home + '\' + Dir;
  end;

  {dumb fixup for if we are trying to do this in the root directory of a drive}
  if dir[4]='\' then delete(dir,4,1);

  Count := 0;
  { search directory For slashed and Record them }
  For i := 1 to Length(Dir) do
  begin
    if Dir[i] = '\' then
    begin
      Inc(Count);
      Slash[Count] := i;
    end;
  end;
  { For each step of the way, change to the directory }
  { if get error, assume it doesn't exist - make it }
  { then change to it }
  For i := 2 to Count do
  begin
    TempDir := Copy(Dir, 1, Slash[i] - 1);
    {$I-}
    ChDir(TempDir);
    if IOResult <> 0 then
    begin
      {$IFDEF DEBUG} writeln('** Making ',tempdir); {$ENDIF}
      MkDir(TempDir);
      {$IFDEF DEBUG} writeln('** Changing to ',tempdir); {$ENDIF}
      ChDir(TempDir);
    end;
  end;

  {$IFDEF DEBUG} writeln('** Changing to ',ourdir); {$ENDIF}
  ChDir(OurDir);  { log back into our starting directory }
end;

function StdPath(p:PathStr):PathStr;
{Ensure paths contain a trailing backslash.
Also ensure there are no double-backslashes.}
begin
  while pos('\\',p)<>0 do
    delete(p,pos('\\',p),1);
  if (p<>'') and (p[length(p)]<>'\')
    then p:=p+'\';
  StdPath:=p;
end;

Function boolToStr(b:boolean;ys,ns:s12):s12;
begin
  if ys='' then ys:='TRUE';
  if ns='' then ys:='FALSE';
  if b then boolToStr:=ys else boolToStr:=ns;
end;

Procedure strReplace(var _str:string;pattern,value:string);
var
  found:byte;
begin
  while pos(pattern,_str)<>0 do begin
    found:=pos(pattern,_str);
    delete(_str,found,length(pattern));
    insert(value,_str,found);
  end;
end;

function byteswap(var a,b:byte):byte;
var
  t:byte;
begin
  t:=a;
  a:=b;
  b:=t;
end;

function stdDate:s16;
var
  y,m,d,doy,hr,mi,se,s1:word;
  s:s16;
begin
  getdate(y,m,d,doy);
  s:=inttostr(y);
  if m<10 then s:=s+'0'; s:=s+inttostr(m);
  if d<10 then s:=s+'0'; s:=s+inttostr(d);
  gettime(hr,mi,se,s1);
  if hr<10 then s:=s+'0'; s:=s+inttostr(hr);
  if mi<10 then s:=s+'0'; s:=s+inttostr(mi);
  if se<10 then s:=s+'0'; s:=s+inttostr(se);
  if s1<10 then s:=s+'0'; s:=s+inttostr(s1);
  stdDate:=s;
end;

procedure StrPadAfter(var str:OpenString;b:byte); assembler;
{Pads a string with nulls after position b}
asm
        les     di,str                  {get location of temp string}
        xor     ax,ax
        mov     al,b                    {al=position to start nulling}
        xor     cx,cx
        mov     cl,es:[di]              {cx=length of string}
        sub     cx,ax                   {cx=how many nulls to write}
        inc     ax
        add     di,ax                   {es:di=starting point for nulls}
        xor     ax,ax
        shr     cx,1
        rep     stosw
        adc     cx,0
        rep     stosb
end;

Function clustsize (drive : Byte) : Word;
Var
  regs : Registers;
begin
  regs.cx := 0;         {set For error-checking just to be sure}
  regs.ax := $3600;     {get free space}
  regs.dx := drive;     {0=current, 1=a:, 2=b:, etc.}
  msDos (regs);
  clustsize := regs.ax * regs.cx;      {cluster size!}
end;


begin
  If Mem[$0000:$0449]=7 then vidp:=ptr($b000,0);
  RecordDOSScreen;
end.
