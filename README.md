# Mod Master XT

Mod Master XT is a DOS tracker-music player descended from Mod Master 2.2 and
optimized to run on IBM PC-compatible systems, including 8088/8086 XT computers.
It can play sample-based tracker modules as well as music made for FM, Tandy,
CMS/Game Blaster, and other PC sound hardware.

## What it can do

- Play tracker modules and classic PC music files, including multichannel
  modules with up to 32 voices where supported by the format and build.
- Mix sample-based music for the PC speaker, parallel-port DACs, Sound Blaster
  cards, and Gravis UltraSound cards.
- Play music through FM (AdLib/OPL), Tandy, and CMS/Game Blaster-compatible
  devices, including supported parallel-port adapters.
- Browse files with the keyboard or a two-button mouse, build playlists, and
  save or load playlists.
- Repeat, shuffle, or IntroScan tracks; adjust playback volume and mix frequency.
- Display playback information such as the module title, position, tempo,
  elapsed time, voice activity, samples, and the pattern data for four voices.
- Run interactively or play modules and playlists from the DOS command line.

## Supported music formats

Formats documented for Mod Master XT include:

- **Sample-based tracker modules:** MOD and MOD-like variants (including NST,
  SD0, WOW, and multichannel MODs), 669, STM, S3M, MTM, DTM, FAR, ULT, XM, and
  Mod Master MMM files.
- **AdLib/OPL and PC music:** SAT, RAD, IMF, RAW, and DRO.
- **Video game music:** VGM files containing supported OPL2, OPL3, Tandy, or
  CMS playback data.

Support varies by executable build. XM playback is partial: global-volume
slides, envelope-position, panning-slide, and tremor effects are not handled;
volume-envelope handling is limited, and panning envelopes and linear-frequency
mode are not implemented. XM patterns with 256 rows and modules with more
patterns than the player can store are rejected rather than silently
truncated. The DTM support is for Digital Tracker F030 files; Digital Trekker
(PC) files are detected but are not played. In S3M, channel volume (M), channel
volume slide (N), pan slide (P), global-volume slide (W), panbrello (Y), MIDI
macro (Z), and tempo-slide (Txx below $20) effects are not handled. PTM support
was removed. Some less common formats or format-specific effects may also be
unsupported.

## Sound output

Depending on the selected build and hardware, playback can use:

- PC speaker
- Covox-style and custom DACs on the parallel port
- Tandy DAC and Tandy 3-channel audio
- Sound Blaster and compatible cards, including Sound Blaster Pro and 16-bit
  mixing modes
- Gravis UltraSound and AMD InterWave (Gravis Plug and Play)
- AdLib/OPL2/OPL3, including OPL2LPT and OPL3LPT
- CMS/Game Blaster, including CMSLPT
- TNDLPT Tandy audio

Output settings include playback frequency and device-specific options such as
Sound Blaster DMA/IRQ configuration and UltraSound mixing. The Sound Blaster
IRQ and DMA can be detected from the `BLASTER` environment variable; UltraSound
configuration uses `ULTRASND`.

## Using the player

Run `MODM` without arguments to open the interactive file browser. Select
individual modules or make a playlist, then configure the output device and
player options from the menus. The interface supports keyboard navigation and
an optional mouse.

The command-line interface can open the menu, play module files, or play
playlists (`.PRG`):

```text
MODM [options]
MODM module_name.ext [options]
MODM program_name[.PRG] [options]
```

Module and playlist names can include paths and wildcards. The documented
options are:

| Option | Function |
| --- | --- |
| `/C` | Always display the cursor |
| `/R` | Repeat playback |
| `/I` | Enable IntroScan |
| `/S` | Shuffle playback |
| `/D:xxx` | Set the custom DAC I/O port |
| `/V:xxx` | Set volume from 1 to 100 percent |

Type `MODM ?` for the command-line help.

## System requirements

The documented minimum is an 8088 processor, 300 KB of conventional memory, an
MDA or CGA display, and a PC speaker. A 286, more available memory, and a
dedicated sound card are recommended. EMS and UMB memory can be used to help
load larger modules.

The player has been tested on 8086/8088, 286, 386, and 486 systems, as well as
in DOSBox and PCem. Actual playback quality and maximum mix frequency depend
on the processor, number of voices, and selected output device.

## Demos and evolution

Watch [Mod Master XT demos and development videos on the FreddyV Retro Zone YouTube channel](https://www.youtube.com/@freddyvretrozone2849).

## Source and documentation

See [Update history](CHANGELOG.md) for ongoing changes and unreleased updates.

This repository contains the Mod Master XT source code. The English manual and
additional release files are in [`RELEASES`](RELEASES/); see
[`MODM_EN3.TXT`](RELEASES/MODM_EN3.TXT) for detailed format, interface,
configuration, and compatibility information.
