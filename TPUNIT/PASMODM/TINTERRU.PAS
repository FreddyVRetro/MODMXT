{$F+,O-}
{$R-,S-} {must NOT have stack checking!}
{
Trixter's interrupt and timer unit.  Version 0.4 20160424
This unit wouldn't be possible without the hard work and writing of:
  Mark Feldman
  Kris Heidenstrom (RIP)
  Klaus Hartnegg
Thank you gentlemen!

See tinttest.pas for example usage.

Version 0.3 20130503 added PCjr vint stuff
}

{$DEFINE HIDDEN} {define if CGAVINT needs to start in vertical retrace only}

{$DEFINE NOTRACKER}

unit TInterrupts;

interface

const
  sysclockfreq=(315/22) * 1000000; {system clock derived from NTSC 14.318182 MHz }
  PITFreq=round(sysclockfreq / 12); {Programmable Interrupt Timer frequency, should be $1234de}
  usecPerTick=1000000 / PITFreq; {# of microseconds per system tick}
  CGAFrameCycles=(912*262) div 12; {# of PIT cycles per CGA display frame}
  SystemTimerInt=8;
  CTCModeCommandReg=$43; {write only; reads are ignored}

  {Some constants to help make sense of the 8253.  Values are listed for
  BCD/Binary mode, operating mode, command/access mode, and channel select.
  Implied "zero" values are also listed for completeness.}

  {BCD or Binary mode:}
  iMC_BinaryMode=0;
  iMC_BCDMode=1;

  {Operating modes 0 through 5 (extended duplicates for 2 and 3 not listed)}
  iMC_OpMode0=0;                       {Interrupt on terminal count}
  iMC_OpMode1=2;                       {Hardware-retriggerable one-shot}
  iMC_OpMode2=4;                       {Rate generator}
  iMC_OpMode3=iMC_OpMode1+iMC_OpMode2; {Square wave generator}
  iMC_OpMode4=8;                       {Software-triggered strobe}
  iMC_OpMode5=iMC_OpMode4+iMC_OpMode1; {Hardware-triggered strobe}

  {Command/Access mode: value, lobyte only, hibyte only, lowbyte/hibyte}
  iMC_LatchCounter=0;
  iMC_AMLB=16;
  iMC_AMHB=32;
  iMC_AMLH=iMC_AMLB+iMC_AMHB;

  {Channel select:}
  iMC_Chan0=0;
  iMC_Chan1=64;
  iMC_Chan2=128;
  iMC_ReadBack=iMC_Chan1+iMC_Chan2; {8254 only!}

{The PITcycles variable will keep track of how many cycles the PIT has
had, it'll be intialised to 0. The Chan0Counter variable will hold the new
channel 0 counter value. We'll also be adding this number to PITcycles
every time our handler is called.}


type
  {Thanks to Jason Burgon for the idea: this record allows us to get away
  with 16-bit math when dealing with longint counters in handlers.  See the
  example handler code in TINTTEST.PAS for example usage.}
  LongRec=packed record
    lo:word;
    hi:integer;
  end;

var
  BIOSTimerHandler:procedure;
  VINTsave:pointer;
  PITcycles,
  Chan0Counter:longint;

procedure InitChannel(channel,accessMode,mode:byte;divisor:word);
{Inits a channel -- mostly used internally but public interface
provided in case you want to do something custom}

procedure SetTimerHz(TimerHandler:pointer;frequency:word);
procedure SetTimerExact(TimerHandler:pointer;cycles:word);
{$IFNDEF NOTRACKER}
procedure SetTimerCGAVINT(TimerHandler:pointer);
{$ENDIF}
{
Save the address of the BIOS handler, install our own, set up the
variables we'll use and program PIT channel 0 for the divide-by-N mode
at the frequency we need.

In the case of CGAVINT, we simulate a vertical retrace interrupt that
fires "early", directly after the last drawn scanline.  This gives us
some extra time to do things before we start retracing back up the screen.
}

procedure HookPCjrVINT(newVINTHandler:pointer);
procedure unHookPCjrVINT;
{Hooks an interrupt handler to the PCjr hardware vertical retrace interrupt}

procedure CleanUpTimer;
{Reset everything back to the way we left it}

Procedure Chan2SquarewaveOn(newfreq:word);
{ties the speaker input to CTC channel 2 and programs it for square wave output}

Procedure Chan2SquarewaveChange(newfreq:word);
{Reprograms CTC channel 2 only}

Procedure Chan2SquarewaveOff;
{unhooks the speaker from CTC channel 2}

Function ticks2usec(l:longint):longint;
{Converts tick counts from the 8253 into microseconds}

implementation

(*

The Mode/Command register at I/O address 43h is defined as follows:

	7 6 5 4 3 2 1 0
	* * . . . . . .  Select channel:   0 0 = Channel 0
                                     0 1 = Channel 1
                                     1 0 = Channel 2
                                     1 1 = Read-back command (8254 only) (Illegal on 8253) (Illegal on PS/2)
	. . * * . . . .  Cmd./Access mode: 0 0 = Latch count value command
                                     0 1 = Access mode: lobyte only
                                     1 0 = Access mode: hibyte only
                                     1 1 = Access mode: lobyte/hibyte
	. . . . * * * .  Operating mode: 0 0 0 = Mode 0
                                   0 0 1 = Mode 1
                                   0 1 0 = Mode 2
                                   0 1 1 = Mode 3
                                   1 0 0 = Mode 4
                                   1 0 1 = Mode 5
                                   1 1 0 = Mode 2
                                   1 1 1 = Mode 3
	. . . . . . . *  BCD/Binary mode:    0 = 16-bit binary
                                       1 = four-digit BCD

The SC1 and SC0 (Select Channel) bits form a two-bit binary code which tells
the CTC which of the three channels (channels 0, 1, and 2) you are talking to,
or specifies the read-back command.  As there are no 'overall' or 'master'
operations or configurations, every write access to the mode/command register,
except for the read-back command, applies to one of the channels.  These
bits must always be valid on every write of the mode/command register,
regardless of the other bits or the type of operation being performed.

The RL1 and RL0 bits (Read/write/Latch) form a two-bit code which tells the CTC
what access mode you wish to use for the selected channel, and also specify the
Counter Latch command to the CTC.  For the Read-back command, these bits have a
special meaning.  These bits also must be valid on every write access to
the mode/command register.

The M2, M1, and M0 (Mode) bits are a three-bit code which tells the selected
channel what mode to operate in (except when the command is a Counter Latch
command, i.e. RL1,0 = 0,0, where they are ignored, or when the command is a
Read-back command, where they have special meanings).
These bits must be valid on all mode selection commands (all writes to the
mode/command register except when RL1,RL0 = 0,0 or when SC1,0 = 1,1).

*)

uses
{  m6845ctl,}
  dos;

const
  lastSpeakerFreq:word=$ffff;

function ticks2usec(l:longint):longint;
{converts number of 8253 ticks to microseconds}
begin
  ticks2usec:=trunc(l / usecPerTick);
end;

Procedure InitChannel(channel,accessMode,mode:byte;divisor:word);
const
  chan0base=$40;
var
  modecmd,lobyte,hibyte,chanport:byte;
begin
  {check for valid input allowed:
  only channels 0 and 2 (1 is for DRAM REFRESH, do NOT touch!)
  only accessmodes 1 through 3 (0 is not an access mode)}
  if not (channel in [0,2]) or not (accessMode in [1..3]) then exit;
  {precalc how we're going to set the channel, so we don't tie up too much
  time with interrupts turned off}
  modecmd:=(channel shl 6) + (accessMode shl 4) + ((mode AND $7) shl 1); {bit 0 always 0 for 16-bit mode}
  lobyte:=lo(divisor);
  hibyte:=hi(divisor);
  chanport:=chan0base+channel;
  {must make these changes atomic, so disable interrupts before starting}
  asm pushf; cli end;
  port[CTCModeCommandReg]:=modecmd;
  port[chanport]:=lobyte;   (* Reload reg lobyte *)
  port[chanport]:=hibyte;   (* Reload reg hibyte *)
  asm popf end;
end;

{$IFNDEF NOTRACKER}
Procedure InitChannelCGAVINT(channel,accessMode,mode:byte;divisor:word);
const
  chan0base=$40;
var
  modecmd,lobyte,hibyte,chanport:byte;
begin
  {check for valid input allowed:
    only channels 0 and 2 (1 is for DRAM REFRESH, do NOT touch!)
    only accessmodes 1 through 3 (0 is not an access mode)}
	if not (channel in [0,2]) or not (accessMode in [1..3]) then exit;
  {precalc how we're going to set the channel, so we don't tie up too much
  time with interrupts turned off}
  modecmd:=(channel shl 6) + (accessMode shl 4) + ((mode AND $7) shl 1); {bit 0 always 0 for 16-bit mode}
  lobyte:=lo(divisor);
  hibyte:=hi(divisor);
  chanport:=chan0base+channel;
  {must make these changes atomic, so disable interrupts before starting}
	asm
    {get to end of display cycle}
    mov   dx,m6845_status
    mov   bl,c_vertical_sync
    mov   bh,c_display_enable or c_vertical_sync
    mov   ah,c_display_enable
    mov   cx,199
    pushf
    cli
    {$IFNDEF HIDDEN}
  @WDR:
    in    al,dx
    test  al,bl
    jz    @WDR  {wait if not vertically retracing}
    {Now we are tracing back up the screen.  Wait until first scanline.}
  @hor1:
    in    al,dx
    test  al,bh
    jnz   @hor1 {wait until not horizontally or vertically retracing}
    {Now we are drawing our first scanline.}
  @hor2:
    in    al,dx
    test  al,ah
    jz    @hor2 {wait until horizontally retracing}
    loop  @hor1 {loop 199 more times}
    {$ELSE}
  @WDR: {wait during retrace, because we don't know where we are in the cycle}
    in    al,dx
    test  al,bl {if our bit is 1, then we're already in retrace; we missed it}
    jnz   @WDR  {jump if 1 (not 0) = keep looping as long as we're retracing}
  @WDD: {wait for display to be over}
    in    al,dx
    test  al,bl
    jz    @WDD  {loop until we aren't drawing any more (ie. retracing)}
    {$ENDIF}

    {set new rate}
    mov     al,modecmd
    out     CTCModeCommandReg,al
    xor     dx,dx
    mov     dl,chanport
    mov     al,lobyte
    out     dx,al
    mov     al,hibyte
    out     dx,al
    popf
  end;
end;
{$ENDIF}

procedure SetTimerHz(TimerHandler : pointer; frequency : word);
begin
  { Do some initialization }
  PITcycles := 0;
  Chan0Counter := PITFreq div frequency;

  { Store the current BIOS handler and set up our own }
  GetIntVec(SystemTimerInt, @BIOSTimerHandler);
  SetIntVec(SystemTimerInt, TimerHandler);

  {init channel 0, 3=access mode lobyte/hibyte, mode 2, 16-bit binary}
  InitChannel(0,3,2,Chan0Counter);
end;

procedure SetTimerExact(TimerHandler : pointer; cycles : word);
begin
  { Do some initialization }
  PITcycles := 0;
  Chan0Counter := cycles;

  { Store the current BIOS handler and set up our own }
  GetIntVec(SystemTimerInt, @BIOSTimerHandler);
  SetIntVec(SystemTimerInt, TimerHandler);

  {init channel 0, 3=access mode lobyte/hibyte, mode 2, 16-bit binary}
  InitChannel(0,3,2,Chan0Counter);
end;


{$IFNDEF NOTRACKER}
procedure SetTimerCGAVINT(TimerHandler : pointer);
begin
  { Do some initialization }
  PITcycles := 0;
  Chan0Counter := CGAFrameCycles;

  { Store the current BIOS handler and set up our own }
  GetIntVec(SystemTimerInt, @BIOSTimerHandler);
  SetIntVec(SystemTimerInt, TimerHandler);

  {init channel 0, 3=access mode lobyte/hibyte, mode 2, 16-bit binary}
  InitChannelCGAVINT(0,3,2,Chan0Counter);
end;
{$ENDIF}

procedure CleanUpTimer;
begin
  { Restore the normal clock frequency to original BIOS tick rate }
  {init channel 0, 3=access mode lobyte/hibyte, mode 2, 16-bit binary}
  InitChannel(0,3,2,$0000);

  { Restore the normal tick handler }
  SetIntVec(SystemTimerInt, @BIOSTimerHandler);
end;

Procedure Chan2SquarewaveOn;
begin
  {if we're not already sounding the new requested frequency, and the new
  frequency is large enough that it won't result in a divisor of 1, proceed:}
  if (lastSpeakerFreq<>newFreq) and (newfreq>18) then begin
    lastSpeakerFreq:=newFreq;
    {Set CTC Channel 2, 16-bit, mode 3, squarewave frequency}
    InitChannel(2, 3, 3, PITFreq div newfreq);
    asm pushf; cli end;
    {Enable speaker and tie input pin to CTC Chan 2 by setting bits 1 and 0}
    port[$61]:=(port[$61] OR $3);
    asm popf end;
  end;
end;

Procedure Chan2SquarewaveChange;
{A bit of assembler and specialization here because 1. we know exactly what
channel we're changing, and 2. we need speed here since changing the speaker's
frequency is something that happens a lot if playing music or sound effects}
var
  divisor:word;
begin
  {if we're not already sounding the new requested frequency, and the new
  frequency is large enough that it won't result in a divisor of 1, proceed:}
  if (lastSpeakerFreq<>newFreq) and (newfreq>18) then begin
    lastSpeakerFreq:=newFreq;
    divisor:=PITFreq div newfreq;
    asm
      mov   dx,$42 {channel 2}
      mov   ax,divisor
      pushf        {save flags because we don't know who/what is calling us}
      cli          {must be atomic, so disable interrupts before starting}
      out   dx,al  {output lowbyte}
      mov   al,ah  {copy highbyte to AL}
      out   dx,al  {output highbyte}
      popf
    end;
  end;
end;

Procedure Chan2SquarewaveOff;
begin
  asm pushf; cli end;
  {Disable speaker and CTC Chan 2 tie by clearing bits 1 and 0}
  port[$61]:=(port[$61] AND (NOT $3));
  asm popf end;
  lastSpeakerFreq:=$ffff; {set to some value the user will never enter}
end;

procedure HookPCjrVINT(newVINTHandler:pointer);
begin
  { Store the current BIOS handler and set up our own }
  GetIntVec(5+8, VINTsave);
  SetIntVec(5+8, newVINTHandler);

  {Enable hardware interrupt 5 in PIC}
  asm
    mov     dx,$21
    in      al,dx           {bring in current PIC mask}
    and     al,not (1 SHL 5){AND to enable, OR to disable}
    out     dx,al           {update PIC mask}
  end;
end;

procedure unHookPCjrVINT;
begin
  {Disable hardware interrupt 5 in PIC}
  asm
    mov     dx,$21
    in      al,dx           {bring in current PIC mask}
    or      al,1 SHL 5      {AND to enable, OR to disable}
    out     dx,al           {update PIC mask}
  end;

  {Restore old handler}
  SetIntVec(5+8, VINTsave);

  {Enable hardware interrupt 5 in PIC}
  asm
    mov     dx,$21
    in      al,dx           {bring in current PIC mask}
    and     al,not (1 SHL 5){AND to enable, OR to disable}
    out     dx,al           {update PIC mask}
  end;

  {There's actually no point in turning the PCjr VINT IRQ5 back on because
  the default handler at f000:f815 in a real PCjr disables it on first call,
  implying that the vint is for user programs only.  But we do it here to
  be an example of best practices.}
end;

end.

(*
While you could write a small procedure that is called by the interrupt
handler, that would just kill the purpose of the handler because you'd
be doing two CALLs instead of one.  You'll just have to write the handler
yourself, but since that sucks, there is an example you can steal in
the program TINTTEST.PAS which should be in the same location as this code.
*)
