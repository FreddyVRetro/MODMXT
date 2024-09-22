Mod Master 2.2 XT Beta Release 27

BLOG : https://freddyv.over-blog.com/

It is a "Downgraded" and Optimized version of Mod Master 2.2
I keep the Mod Master 2.2 Doc inside for reference. (Modified for Mod Master XT)

Output devices supported:
- PC Speaker
- Covox
- Sound Blaster Auto initializes DMA - Mono Up to 45KHz (Does not work on SB 1.0, 1.5)
 (Tested on Sound Galaxy NX 2, Sound Blaster 2.0, Sound Blaster Pro 2, DosBox)
- Sound Blaster Pro Stereo
 (Tested on a Sound Blaster Pro 2.0, DosBox)
- Sound Blaster 16 (8 and 16 Bit Mixing)
- Gravis UltraSound (Yes, even on XT Computer !)

I removed all the other sound output support for the moment.

Some advices:
- Delete MODMXT.CFG in case of problem to reset to the default values.


- Why I did it ?
----------------

I started a Retro computers collection in 2018 and I purchased again my First PC (An Amstrad PC1640)

After seing 8086 Corruption and discovered GLX Player (Yes, I did not know it before), I decided to test My First Mod Master on the PC1640.
Using a 4 Channel module, on an Amstrad PC1640 (8086 8MHz)
- Mod Master 1 is working at 4KHz. (PC Speaker)
- Mod Master 2.0 working at 8KHz. (Sound Blaster)

Then I teted GLX and I was of course surprized by its speed !

Looking back into the code, I saw the horrible Mod Master 1 and 2 mixing code, and the quite nice Mod Master 2.2 Code...

- How I did it ?
----------------

I decided to downgrade the Mod Master 2.2 code.

The more complicated part was the VGA Interface to downgrade to CGA.

First test gave me a lower overall performance than GLX Player, but close anyway.

After some optimization and the add of 4 Mixing buffer (2 were used before), the result was far better.
My goal was to be close to GLX, but also to try to keep a good mixing and replay quality.

My mixing code is a little slower than GLX one, but GLX use some trick that reduce the sound quality.

Finally, Mod Master can play the modules faster than GLX: The first mixed channel use a MOV, instead of an ADD, this is not done in GLX.

This now make Mod Master faster than GLX with 4 Channels .MOD (Probably not 8) with a better sound quality.
The Stereo replay code is also faster.

Thanks to Carlo Vogelsang for Galaxy Player, It did show me it was possible to have great sound on XT.
Thanks to Trixter for supporting me and for Bug Reports.

Projects for the Future:
- Put Back the Adlib code, for S3M ans SAT
- Implement Other Adlib File Format
- Do a Sound system API to be able to develop demos or why not games.
- Put the Mod Master XT Sound system in the Mod Master 2.3 Interface for 286/386 Computers. (VGA)

FreddyV

Known Bug / Not complete:
-------------------------
- MOd Master Crash at the begining on > 486 CPU, Use CRTFix to correct this.
- Exotic file formats (MTM, FAR...) replay may be not correct.
- The Samples replay is stoped when volume is 0. (Sound Blaster, not a bug, programmed like this)
- Some .XM Volume commands, instruments envelop not supported.
- Crash while loading some .XM files
- If we load the Controle.S3M (Dune/Orange) With the GUS, samples loading is bugged after this.
- Crash with some .RAW

To do List:
-----------
- Display only 6 Channels in OPL2 Drum Mode.
- Display the WaveForm name for OPL2/3.
- Stop the sound during pause (OPL2/3)
- Display the VGM Infos and more infos on other formats.

Rev History:

29/05/19 
- Vibrato Corrected.
- You can increase / Decrease the frequency in the output device with the Left and Right keys
- You can activate/Desactivate Autoinit DMA with Space
-> No more Mouse needed if your BLASTER env variable is correct
- Mixing Code SpeedUp : 16% faster on 8086 (Mix 2 Samples at the same time)
- No more supported output device no more highlighted in the output device menu

18/06/19
- Now use 5 Buffers for the mixing
- Use the /C command to display the cursor (Used by some mouse drivers)
- Correction in FAR and ULT Loaders for less crash.
- Reduced the number of file supported in a folder to 255 (10Kb of memory saved)
- Modules volume now saved correctly and programs can be loaded.
- You can change the frequency for each module (With Left/Right)

12/07/19
- Gravis Ultrasound support added back, and working on 8088 machines !
- Corrected the Pattern Jump effect.
- Covox I/O port no more Hardcoded, and optimized.

16/07/19
- Corrected a Key Off bug in S3M
- Added BlasterBoard detection (Trial)
- Increase the Max Frequency to 48KHz (For BlasterBoard test only)

19/07/19
- BlasterBoard detection Ok.
- Max Frequency for BlaserBoard : 62KHz
- Correct the Sound Blaster env variable Read
- Correct the Gravis Ultrasound Volume (Used 33 values instead of 65)
- Music notes no more displayed out of the screen (Sample display mode)
- Various display bug and french text removed.
- Improve mixing speed (Again) +5% for 4 Channels MOD. (Now Mod MAster is Faster than GLX for 4 Channels)

24/07/19
- Corrected the notes frequency calculation. (The notes changed with the mixing frequency)
- Change the File open function parameters. (File open sometimes bug)

30/07/19 - Beta 9
- Stereo replay is back (Faster than GLX)
- Improved samples increment precision (Trixter)
- Pattern not used are not loaded in .MOD Files

20/09/19
- Now work with Hercule (With some bugs) use the /H command line parameter to activate.
- Covox output working again, Set the Mixing speed to a correct value ! 
  (Be carefull about the Files individual frequency)
- PC Speaker support is Back (And Much Faster)
- The Volume channel is no more used for .MOD Files (Pattern size reduced)
- Now use the Note instead of Period in the internal patterns (Pattern size reduced as well)
- Module time calculation removed, it takes really too many time on 8086 and it was finally useless as not correct :-)
- Small Mixing performance increase. (Buffer Signed to Unsigned conversion optimized)
- Up to 6 Octaves for .MOD Files, with default at 6.(Alvaro84, EHA-CH07.MOD)
- Arpeggio is Back and Corrected for LIVE.MOD (Trixter)
- Tested to work with DOPE.MOD, if the machine has 640Kb + UMB
- .MOD Files with Samples >64Kb are now loaded correctly (And Played on GUS) (DevanWolf, BINARY.MOD)
- .S3M Files With 16Bit Samples are now Loaded correctly (DevanWolf)
- '3CHN' .MOD Files loading Corrected (DevanWolf, 3CHN-C64.MOD)
- Tandy DAC Detection Added
- Display Screen added to show Up to 14 Channels (Press F4)
- .MTM Pattern loading Corrected
- Note Delay was no more working (Corrected)
- Custom DAC Added (Put the Custom DAC @ in the command line)

10/10/19 Beta 11
- Fast Tracker 2 support Added. (.XM, Beta)
  -> No Volume effect, Instrument envelop, multiple sample instr
- Monotone Support Added, PC Speaker. (.MON)
- Pause in Stereo Corrected.
- GSLINGER.MOD Does not crash anymore.
- Added the Effect name and Left/Right display in the multi channel display. (F3)
- Some minor bug Corrected.
- .S3M Files loading Speed increased. (Faster Pattern Unpack)
- GUS Samples Loading Speed increased.
 -> 2ND_PM.S3M Loads in 24s instead of 40s on a 8088 8MHz
 
22/12/19 Beta 12
 - Corrected a .MOD File loading problem (Sequence With patterns=255)
 - Increased the UMB Block numbers from 16 to 64. (Memory)
 - 16Bit samples loading corrected.
 - .MOD, S3M and XM Files Pattern compressed: Loading DOPE.MOD Patterns is no more a problem
 - Lot of .XM Files Loading bug corrected and Extra Fine portamento Up/Down Added
 - Added the Free DOS Memory size on the Option Menu.

04/01/2020 Beta 13
 - Sound Blaster detection code modified. (Use the Env Variable Port first)

8/01/2020 Beta 14
 - Sound Blaster detection code improved a little
 - Sound Blaster 16 command added. (Increased replay frequency precision)
 - Sound Blaster 16 Adds 8 Bit Mono signed (8% Faster in 4 Channels) and Stereo > 22KHz (Not more than 32KHz)
 - Detected Sound Blaster card name written during the replay.
 - .MOD : Octave 6 and 7 were misssing (Bug added after period precision increase) (DOPE.MOD Bugged)
 - I Added SBSET.EXE, The Software I wrote to configure the SB16 CT2230 on XT Computer.

30/01/2020 Beta 15
 - Corrected the Note Delay command (It was no more working)
 - Corrected a problem in DOPE.MOD (One Octave was missing)
 - Improved the Options menu
 - All the options can be changed with the keyboard (first letter of the option name)
 - Corrected the Command line help.
 - Remove some french words here and there.
 - 8 Bit Volume table precision improved. The volume level needs to be reduced (If you already adjusted it)
 - 16 Bit Mixing Added, for 8 Bit output, and 16 Bit output on Sound Blaster 16. (Use mode memory: 16Kb)
 - Stereo replay up to 44KHz (22KHz in 16 Bit)
 - Number of Octave option now correctly loaded/Saved.
 - Config file renamed (MODMXT.CFG)

I believe it is close to become Mod Master XT 1.0 :-)

09/03/2020 Beta 16
 - If you copy the SBVGM.EXE Player by OPLx in the same folder as MODM.EXE, you can play VGM and VGZ Files
 - MODML.EXE is the "Light" version of the player, removing these format: 669, FAR, DTM, MTM, ULT and MON
 - Change the modules memory structure to support XM Instruments.
 - XM: Added Volume column effects: Volume Slide, Fine Volume Slide and Set Panning.
 - XM: Added support for multiple samples instruments.
 - XM: Panning corrected.
 - XM: Set BPM Corrected.
 - XM: Lot of Effects bug corrected (Wrong effect or no effect selected)
 - Put back the GUS Volume table adjust (Main Volume)
 - Help page corrected.
 - Various interface correction
 - Big changes in the mixing adjustment code (When the mixing is too slow)

07/04/2020 Beta 17
 - Stop the music if not able to even mix one channel. (To avoid crash)
 - Display of the module number during program play corrected. (root42)
 - Small volume table adjustment. (2nd_pm.S3M at default volume)
 - Corrected a bug in .MOD Loader (zyga64)
 - Corrected a .XM File Loader Bug (Module with >14 Channels)
 - Adlib Replay is now back, for .S3M and .SAT; .SAT replay may be a little bugged. (Portamento)
 - OPL3 detection added.
 - Added the Max mixing Channels code, to Limit the number of channels mixed to a Fixed or Automatic Value
   This part can be improved and can be nice to test on 286 to play modules with a big nb of channels.
   (On 8086, we need to reduce the mixing frequency too much)
   On the multi channel view, Channels paused has a Yellow Spot and Channels stopped a Red Spot.
   -> In the Option Menu, you can set the Channels Limit to Disables/Auto and Manual.
      Set the Max number of channels in Manual Mode.
      Delete the MODMXT.CFG file before using
 - In debug mode(F6), press Up/Down to change the channels displayed

14/04/2020 Beta 18
 - Correct a bug in the FT2 Volume Commande Code, preventing some module to start (zyga64)
 - S3M : Pattern nb 254 now ignored. DATAJACK.S3M (root42)
 - Improved the error management code.

27/05/2020 Beta 19
 - Internal variables removal and rename.
 - S3M : Corrected a problem in the Adlib instruments loader (OLD S3M Version files)
 - Adlib replay code changed to use a Timer IRQ only.
 - Correct problems in Adlib volume. (S3M / SAT)
 - Added support for the internal file format (.MMM) (No converter Yet, otherwise I will never release this version)
 - Added the support for .IMF, .RAW and .DRO Version 2
 - Added support for .RAD version 1, RAD Tracker code integrated for perfect support.
 - Fix: ESS Audiodrive Model detection and can be used as a SB Pro.
 - Started OPL LPT Support (Not active yet)

29/05/2020 Beta 20
 - OPL3 Init was incorrect after .DRO replay
 - Increased the delay for OPL3 Write (Bug on 486)

13/09/2020 Beta 21
Warning : Delete MODMXT.CFG as its format changed.

 - OPL3: Increased the delay for OPL3 Write again (Bug on 486) 
 - MDA: Autodetect Monochrome text mode
 - MDA: Corrected the display during replay in Hercule and MDA (Sinclair PC200)
 - Gravis: Corrected the Sample Offset when > Sample size on the GUS. (Bug on PANIC.S3M)
 - Bug fix for tone portamento when it is started with no note defined.
 - S3M: The Sample cut when the pitch is too high was no more working. (Root42, bug on PANIC.S3M)
 - S3M: Bug corrected in the pattern loader (MJay99, PASSTIME.S3M)
 - .XM: Corrected a Loader problem, when too many commets aare added in samples name.

 - ! .VGM: Read on OPL2 / OPL3 and Tandy Added
 - Added OPLLPT Config menu and support (Not Tested)
 - Added the Tandy chip Config menu and detection (PCJr, T1000 and DAC).
 - TDYLPT Code Added (Provided by Benedikt)
 - -t -tdylpt -opl2lpt and -opl3 arguments sent to SBGVM
 - Various internal changes, for Pause during replay, display...
 - The GUS Replay Frequency is now displayed in the Debug Menu. (F6)

18/10/2020 Beta 22
 - Fixed one bug for the Tandy Port config
 - Added OPL3LPT Support
 - Changed in the way the mixing buffers are managed.
 - ! Added the support for the Tandy DAC output (DMA)
    WARNING: Don't use Pause, it does not work.

20/11/2020 Beta 23
  - Improved the Tandy DAC Output (It was stopping with the "Too Slow" Message sometimes)
  - When you unselect EMS from the Option, it now still use EMS but use the DOS Memory in priority.
    > Speedup the mixing on 16Bit Memory machines, with an 8Bit EMS Board.
  - Tandy DAC Selected by default if detected (If no SB/GUS)
  - Corrected the Pause for SB / Tandy DAC
  - Gravis Ultrasound Notes precision improved. (More if Channels > 14)
  - Gravis Ultrasound Sample loading time reduced by 30%
  - Improved the Output menu
  - Added InterWave support (GUS PnP, Not Tested)

22/11/2020 Beta 24
  - A Bug was added on the GUS (Real Hardware, sorry, I did not test)

09/12/2020 Beta 25
  - GUS is now working, but Interwave does not work yet.
  - Corrected a Sound Blaster 16 Problem.
  - Improved the Notes frequencies for mixed outputs.
  - Improved the Speed precision for all the mixed output (With a really small performance reduction)
  - S3M Bug corrected : 64-mania.S3M (MJay99)

27/01/2021 Beta 26
 - Tandy Pause bug removed (IT was not working)
 - Tandy Audio detection improved.
 - Mod Master XT is now in Light Version by default: "Useless" File format removed : 669, STM, FAR, DTM, MTM and ULT
 - modm.exe is the "Light" Version, modmf.exe the Full Version with all the format.
 - DOSMID Used for Midi replay with the -noxms -mpu command line arguments. (Can't load >30Kb MIDI File with 512Kb memory)
 -> Place DOSMID.EXE in the same folder as Mod Master

22/08/2021 Beta 27
 - Added BlasterBoard 2.1+ Signed output support. (A Little faster)
 - AMD InterWave (GUS PnP) now working and GUS Code simplified.
 - TNDLPT Tested.
 - OPL3LPT Support added and Tested. (Does not work with SAT/S3M yet)
 - CMS and CMSLPT Support added. (For VGM)
 - Button added to enable the GUS Line in but not implemented yet.
 - Display the Sound Blaster name in the main page.
 - Display the LPT2 and Tandy DAC port in the Output menu if available.
 - Save the Custom DAC port in the Config File.
 - Does not reinit the Text Mode each time a module is played (This can affect some CRT Monitors)
 - Corrected a problem in the Vib Volume Slide effect (World of Plastic S3M)
 - Various small correction

/01/2022 v1.0
 - Removed a Debug display in GUS Panning code
 - Added some .VGM reserved Commands
 - MODMCONV.EXE Added to convert files to .MMM Format
 - Reviewed / corrected documentation.
 - Tandy detection code simplified (Crashed on some PC)
 - When using in command line, Mod Master did not clean up the screen at the end (Bug Added in b27)
 - EMS Was displayed even if EMS Size=0
 - Timer based Devices (Speaker/DAC) Timer precision improved.
 - Correct a bug in the PC Speaker/DAC Code (Corrupted Register during the IRQ)
 - Increase the PC Speaker and DAC Speed. (Remove the use of 2 Register in the interrupt)
 - You can toggle the View from Note/Sample to Period "Bar" in the F4 Display Screen.
 - All the program buttons are displayed with a Monochrome monitore.

 v1.01
 - Corrected the BlasterBoard detection code
 - Mix speed increased a little

 v1.02
 - Added Port display for CMS/DAC.
 - Corrected the Tandy DAC Port change code