; Modified for Mod Master
;
;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
;          ?
;          . 栢幡賞? 蔔幡賽? 蔔賽? 栢?    栢?栢栢白  栢  栢??
;          : 栢白蔔? 栢白?  査白蔔?栢?    栢?   賞百 賞複栢?:
;          ?栢?賞白 栢?    栢? 栢 査白    栢?    栢?    栢?|
;  ??켐켐?賽?  賽?賽賽賽 賽? 賽  賽賽賽 賽?    賽?賽賽賽  읕??-컴커
;  ?蔔賽?栢賽?栢    栢 栢賽?  賽賞?栢賽?蔔賽?蔔賽?栢  ?蔔賽?栢賽?:
;  | 栢賽?栢  ?栢    栢 栢賽?     栢 栢賽?栢賽?栢  ?栢賽?栢?  栢賽?.
;  : 賽  ?賽賽   賽賽 賽 賽賽       賽 賽  ?賽  ? 賽? 賽  ? 賽賽 賽  ??
;                       Play-routine Code  version 1.1a
;
;                        by SHAYDE/REALITY Feb, Apr 95
;
;                                    - * -
;
; Feel free to use/hack this code about as much as you like.  In the good old
; dayz of Amiga, ALL tracker writers gave away player source-code so that the
; coder could do what he/she wanted with it.  On PC every tracker writer thinks
; their player code should be protected and they either don't release a player
; or they release it in .OBJ format which means if you need to make changes to
; the code to fit in with your demo/intro you're fucked!!!  So message to all
; tracker writers out there:
; FOR THE SAKE OF CODER SANITY, ALWAYS RELEASE PLAYER CODE FOR YOUR TRACKERS!!
; OTHERWISE WOT'S THE POINT OF WRITING A TRACKER?!?!??!?!  And release it in
; source-code form to reduce head-aches!
;
;				     - * -
;
; This source-code doesn't contain any segment directives so it is only
; INCLUDEable in other source-code.  Also it requires a minimum of a 286
; to run.  I avoided using ASSUMEs so that the code that INCLUDEs this code
; doesn't lose it's ASSUMEs, hence variables are accessed via CS:.  You can
; save a few bytes by dropping them (which you'll need to do if you want to
; use this player in protected-mode), although I use DS: to reference the
; tune segment.
;
;				     - * -
;
; Hey, 'scuse the ugliness of the listing.  I'm a coder, not an artist!
;
;				     - * -
;
; INSTRUCTIONS FOR USE:
;
;	To initialise the player, call "InitPlayer".
;	To stop play, call "EndPlayer".
;	To play music, call "PlayMusic" 50 times a second (18.2/sec for a
;					"slow-timer" tune).
;
;				     - * -
;
; BUG FIXES (Arrrrrghhhh!!! :-)
;
;   V1.1a Apr95:
;	Fuck!  Sorry dudez!  Real stupid bug.  You see, RAD itself plays the
;	note and then does the effect straight away.  But this 'ere source
;	code played the note then did the effect one beat later.  I didn't
;	notice it in testing cos it's marginal, but it fucks up the slides
;	slightly and with real complex slides (like in some of Void's latest
;	AWESOME tunez) it can stick out like elephant's balls!  I've now moved
;	the call to UpdateNotes to the end of the routine so it's executed
;	EVERY beat instead of every beat except note beats (make sense?  No?
;	GOOD! :-)
;
;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께

		locals
		jumps



; Tracker commands
cmPortamentoUp	=	1		; Portamento up
cmPortamentoDwn	=	2		; Portamento down
cmToneSlide	=	3		    ; Tone Slide: xx is speed of slide
cmToneVolSlide	=	5		; Tone slide of 00 + Vol. Slide
cmRADVolSlide	=	10		; Volume Slide: <50=down, >50=up
cmSetVol	=	12		    ; set volume
cmJumpToLine	=	13		; Jump to line in next track
cmSetSpeed	=	15		    ; set speed

FreqStart	=	156h		; low end of frequency in each octave
FreqEnd		=	2aeh		; high end of frequency in each octave
FreqRange	=	FreqEnd-FreqStart


;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; This routine initialises the player.
; IN:
;	ES:	- points to .RAD module to play
; OUT:
;	Carry	- set on error (such as invalid module)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
RAD_Start Proc Near
		
If Mod_Master eq yes
        DS_TP
        MOV Center_Display,CD_Bar
	    DS_ASM
Endif

        MOV AL,31
		MOV Nb_Total_Samples,AL
		MOV Nb_Samples_Loaded,AL
		MOV Nb_Samples ,AL
        MOV Chrono_50,50

        LES DI,OtherMUS_Ptr

	; initialise certain Adlib registers that aren't changed

		mov	ax,0120h	; allow waveforms
		call WriteOPL
		mov	ax,0800h
		call WriteOPL
		mov	ah,0bdh		; no drums, etc.
		call WriteOPL

	; check to see if it is a RAD file first
		cmp	word ptr es:[0],'AR'
		jnz	@@err
		cmp	word ptr es:[2],' D'
		jnz	@@err
		cmp	byte ptr es:[16],10h		; correct version?
		jnz	@@err

		mov	cs:ModSeg,es		; keep the segment of module

	; read initial speed
		mov	al,es:[17]          ; Bit 6 for Slow Tempo
		mov	Tempo,al
		mov	ah,al

	; see if there's a description to skip
		mov	si,18
		test ah,80h			; description flag
		jz	@@lc			; no description

		xor	al,al
		jmp	@@le

	@@ld:	
	    inc si
	@@le:
        cmp es:[si],al		; look for null-termination
		jnz	@@ld
		inc	si			; move past null

	; create table of instrument pointers
	@@lc:	
	    xor bx,bx

	@@la:	
	    mov bl,es:[si]		; instrument no.
		inc	si
		add	bx,bx
		jz	@@lb			; no more instruments

		mov	cs:InstPtrs-2[bx],si	; record pointer to instrument
		add	si,11
		jmp	@@la

	; record offset of order list
	@@lb:	
	    xor ax,ax
		mov	al,es:[si]		    ; no. of orders in order-list
		mov	cs:Sequence_Len,al
		inc	si
		mov	cs:OrderList,si
		xor	bx,bx
		mov	bl,es:[si]		    ; first pattern to play
		add	bx,bx
		add	si,ax			    ; move to end of list

	; record table of pattern offsets
		mov	cs:PatternList,si
		mov	ax,es:[si+bx]		; first pattern offset
		mov	cs:PatternPos,ax	; pointer to first pattern

	; initial pointers
	
        PUSH CS
		POP DS
		
		xor	ax,ax
		mov	C_Sequence,al		; start at position 0.
		mov	C_Row,al		    ; start at line 0
		mov	Cmpt_Tempo,al		

     ; Start the IRQ

        MOV IRQ50_Partition,Offset PlayMusic
        MOV DX,OFFSET IRQ_Timer_50
        CALL Start_Timer_50     ; Start the IRQ Timer at 50 Hz

		TEST Tempo,01000000b    ; Bit 6 Slow tempo
		JZ RAD_FastTimer
        XOR AX,AX
        CALL Set_Timer0_Period  ; Change Timer to 18,6KHz
RAD_FastTimer:
        AND Tempo,1Fh
        
		RET                     ; successful initialisation

	@@err:
	    PUSH CS
		POP DS
		MOV Erreur_Modm,7
		RET
RAD_Start Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; This stops music playback (stops sound channels).
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Stop_RAD Proc Near

        RET
Stop_RAD Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; This routine does the actual playing.  It MUST be called 50 times a second
; to maintain accurate music playback.  Refer to accompanying timer source-code
; for ways of providing a 50/sec timer service.
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; DS=CS at the begining
; Then, DS=ModSeg
PlayMusic Proc Near
		push	ds

        CALL Chrono_Fading

		mov	ds,ModSeg	; segment of module

		sub al,CS:Tempo
		cmp	cs:Cmpt_Tempo,0
		jz	@@la		; play a line of music
		CMP cs:Cmpt_Tempo,al
		ja 	@@la		; Bug, sometine at the start Cmpt_Tempo =128
		dec	cs:Cmpt_Tempo
		jmp	@@lx		; no new line, so just update effects

	; switch off any effects that are in operation
	@@la:	
	    mov si,8
		xor al,al

	@@laa:	
	    mov cs:RADPortSlide[si],al	; reset any slides
		mov cs:RADVolSlide[si],al	; reset any slides
		mov cs:RADToneSlide[si],al	; reset any slides
		dec si
		jns	@@laa

	; playing a new line, PatternPos should have been set-up already
		mov	si,cs:PatternPos
		or	si,si
		jz	@@lb		; rest of this pattern is blank

		mov	al,[si]		; line indicator
		and	al,7fh		; eliminate bit 7
		cmp	al,cs:C_Row	; is this current line?
		jnz	@@lb		; haven't reached it yet

		test	byte ptr [si],80h	; last line?
		jz	@@lc		; no, still more to check
		mov	cs:PatternPos,0	; mark rest of pattern as blank

	@@lc:	
	    inc si		; move to first channel

	; play channels
	@@lf:	
	    mov cl,[si]		; channel we are processing
		push cx
		and	cl,7fh		; get rid of bit 7
		mov	ax,1[si]	; AL=octave/note, AH=inst/command
		add	si,3

		XOR CH,CH       ; Clear the Parameter
		test ah,15		; if there's a cmd, there'll be a param.
		jz @@le		    ; no parameter byte
		mov	ch,[si]		; read parameter
		inc	si

	@@le:	
	    call PlayNote	; play the note

		pop	cx
		jc	@@lg		; skip rest of line, AX has new line

		test	cl,80h	; last channel to play?
		jz	@@lf		; not yet

		mov	cs:PatternPos,si; keep position in crunched track

	; update pointers
	@@lb:
        mov al,cs:Tempo	; needs to be set AFTER note playing
		dec	al
		mov	cs:Cmpt_Tempo,al	;    for new speeds to take effect!

        CMP CS:Cmd_ModifyPattern,0
		JE RAD_Continue
        MOV CS:Cmd_ModifyPattern,0
		JMP RAD_ChangePattern
RAD_Continue:

		inc	cs:C_Row
		cmp	cs:C_Row,64	; end of pattern?
		jb	@@lx		; nope

        inc cs:C_Sequence
RAD_ChangePattern:
        mov bl,cs:C_Sequence
		mov	cs:C_Row,0	; top of next pattern		
		call RADNextPattern

	; now update effects (effect is acted upon straight away)
	@@lx:	
	    call UpdateNotes

        DS_TP
        MOV Tick_50Hz,1    ; Pour l'affichage

		POP	DS
		RET
	
		
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
	; jump to line AX
	@@lg:	
	    mov bl,cs:Tempo	; needs to be set AFTER note playing
		mov cs:Cmpt_Tempo,bl	;    for new speeds to take effect!

		mov	cs:C_Row,al

		; find start of next pattern
        mov	bl,cs:C_Sequence
		inc	bl		
		call RADNextPattern
		jz	@@lx		; there isn't any data in next pattern

		; find line that is greater or equal to the current line
	@@ll:	mov	cl,[si]		; line id.
		and	cl,7fh		; ignore bit 7
		cmp	cl,al
		jae	@@lh		; found line

		test	byte ptr [si],80h
		jz	@@li		; not last line
		xor	si,si
		jmp	@@lh		; ignore rest of pattern as it's last

		; skip to next line definition
	@@li:	inc	si
	@@lj:	mov	cl,[si]
		add	si,3
		test	byte ptr cs:[si-1],15	; is there a valid command?
		jz	@@lk
		inc	si		; skip parameter

	@@lk:	add	cl,cl
		jnc	@@lj		; wasn't last channel spec.
		jmp	@@ll		; check next line

	@@lh:	mov	cs:PatternPos,si
		jmp	@@lx

PlayMusic Endp	

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Advances pointers to next pattern in order list.
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
RADNextPattern Proc Near

		cmp	bl,cs:Sequence_Len
		jb	@@ld
		xor	bx,bx		  ; end of tune, move back to start
		
		MOV CS:Stop_Output,1 ; No music Loop > Stop the Music

	@@ld:	
	    mov	cs:C_Sequence,bl
		mov	si,cs:OrderList
		mov	bl,[si+bx]	; no. of next pattern

		test	bl,80h
		jz	@@lda
		and	bl,7fh
		jmp	@@ld		; bit 7 = jump to new order

	@@lda:	mov	si,cs:PatternList
		add	bx,bx
		mov	si,[si+bx]	; offset of next pattern
		mov	cs:PatternPos,si
		or	si,si
		ret
RADNextPattern Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Plays a note on a channel.
; IN:
;	AL	- Octave (high nibble), Note (low nibble)
;	AH	- instrument (high nibble), command (low nibble)
;	CL	- channel to play note on (0..8)
;	CH	- parameter byte if command is non-zero
; OUT:
;	CARRY	- set if a line is to be jumped to
;	AX	- line to jump to if CARRY set
; Note: don't use SI or segment regs., otherwise registers do not need saving.
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
PlayNote Proc Near
      
        mov	di,cx
		and	di,15
		mov	dh,ah
		and	dh,15		; command
		
        PUSH DX
		TEST DH,DH
		JE NoIncCmd
		INC DH
NoIncCMD:		
		MOV CS:VCurrent_CMD[DI],dh ; Save for Display
		MOV CS:VCurrent_PAR[DI],ch
        POP DX

        MOV CS:VPart_entiere[DI],AL	; Save Note+Oct (Debug)

        PUSH AX         ; Mod Master Store the Note 1and Period for display
        PUSH BX
        PUSH DX
		OR AL,AL
		JZ @@NoSaveNote
		MOV BL,AL
		AND BL,0Fh
		SHR AL,1
		SHR AL,1		
		SHR AL,1
		SHR AL,1	; BL Note AL
        CMP AL,9
		JA @@NoSaveNote
		
        MOV BH,12
        MUL BH      ; AL*12 > Octave*12
        ADD BL,AL   ; Add Note
        MOV AL,BL   ; AL > Note+Octave*12
        MOV CS:Ch_Note[DI],AL  ; Save Note
		
        XOR BH,BH
        MOV BL,AL
		SHL BL,1
        MOV DX,CS:T_per0[BX]
		MOV BX,DI
        SHL BX,1
        MOV CS:CH_Per_part[BX],DX ; Save Period
		
@@NoSaveNote:	
        POP DX
        POP BX
        POP AX

		or	al,al
		jz	@@lb		; no note playing, process command

	; check to see if we are actually performing a tone slide
		cmp	dh,cmToneSlide
		jnz	@@lt		; nope, play note

		; note/octave are used as parameters then (instrument ignored)
		mov	bx,ax
		and	bx,15		; note
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1		
		and	ax,7		; octave
		dec	bx	        ; we want 1..12
		cmp	bx,12
		jae	@@lx        ; not a valid note (probably KEY-OFF)

        push bx
		mov bx,FreqRange
		imul bx         ; scale octave
		pop bx
		add	bx,bx
		add	ax,cs:NoteFreq[bx]	   ; add frequency of this note
		sub	ax,FreqStart	       ; so range starts from zero
		mov	cs:ToneSlideFreqL[di],al	; destination frequency
		mov	cs:ToneSlideFreqH[di],ah

		; set tone slide speed
		mov	byte ptr cs:RADToneSlide[di],1	; switch tone slide on
		or	ch,ch
		jz	@@lx		; use last speed setting
		mov	cs:ToneSlideSpeed[di],ch
		jmp	@@lx

	; KEY-OFF the previous note
	@@lt:
	
        OR CS:Ch_Control[di],CM_Stopped
		
	    push ax
		mov	al,cs:OldB0[di]	; old register value
		and	al, not 20h	; clear KEY-ON bit
		mov	cs:OldB0[di],al	; so slides after KEYOFF work correctly
		mov	ah,cl
		add	ah,0b0h
		call WriteOPL
		pop	ax

	; load instrument (if any)
		mov	dl,ah
		add	al,al
		rcr	dl,1
		shr	dl,1		; instrument no.
		shr	dl,1
		shr	dl,1
		jz	@@la		; no instrument to load
		call	LoadInst

	; load note into channel
	@@la:	
	    mov bl,al
		and	bx,15*2		; note * 2
		cmp	bx,15*2
		jz	@@lb		; just a KEY-OFF so we're done

		mov	bx,cs:NoteFreq-2[bx]	; frequency of note (BX-1)
		shr	al,1		; octave
		shr	al,1
		shr	al,1
		and	al,7*4
		or	al,20h		; KEY-ON
		or	al,bh		; Frequency high byte
		mov	ah,0b0h
		add	ah,cl
		mov	cs:OldB0[di],al	; record the register value
		push	ax

		sub	ah,10h
		mov	al,bl		; Frequency low byte
		mov	cs:OldA0[di],al
		call	WriteOPL

		pop	ax
		call	WriteOPL

	; process command (if any), DH has command, CH has parameter
	@@lb:	
	    xor bx,bx
		mov	bl,dh		; command
		add	bx,bx
		jmp	cs:Effects[bx]

	@@lx:	clc
	@@lxx:	ret
	
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Portamento up
@@RPortUp:	mov	cs:RADPortSlide[di],ch
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Portamento down
@@RPortDown:	neg	ch
		mov	cs:RADPortSlide[di],ch
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Tone slide to note (no note supplied)
@@RToneSlide:	or	ch,ch		; parameter has speed of tone slide
		jz	@@lja		; keep last tone slide speed
		mov	cs:ToneSlideSpeed[di],ch

	@@lja:	mov	byte ptr cs:RADToneSlide[di],1	; tone slide on
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Volume slide & Volume + Tone Slide
@@RToneVolSlide:
@@RVolSlide:	
        cmp	ch,50		; <50 = slide down, >50 = slide up
		jb	@@lga
		sub	ch,50
		neg	ch

	@@lga:
      	mov	cs:RADVolSlide[di],ch

		cmp	dh,cmToneVolSlide	; just plain volume slide
		jnz	@@lx
		mov	byte ptr cs:RADToneSlide[di],1	; tone slide on
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Set volume
@@RSetVolume:
        call RADSetVolume	; CH has volume, CL has channel
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; jump to line in next pattern
@@RJumpToLine:	
        cmp ch,64
		jae	@@lx		; ignore as it is invalid
		xor	ax,ax
		mov	al,ch
		stc
		ret			; skip rest of channels
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Set speed
@@RSetSpeed:	
        mov cs:Tempo,ch
		jmp	@@lx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Effects	dw	@@lx
		dw	@@RPortUp
		dw	@@RPortDown
		dw	@@RToneSlide
		dw	@@lx
		dw	@@RToneVolSlide
		dw	@@lx
		dw	@@lx
		dw	@@lx
		dw	@@lx
		dw	@@RVolSlide
		dw	@@lx
		dw	@@RSetVolume
		dw	@@RJumpToLine
		dw	@@lx
		dw	@@RSetSpeed

PlayNote Endp

NoteFreq	dw	16bh,181h,198h,1b0h,1cah,1e5h	; 156h = C
		    dw	202h,220h,241h,263h,287h,2aeh


;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Check each channel for ongoing effects to update.
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
UpdateNotes Proc Near 	
        xor bh,bh		; channel index
		xor si,si

	; process portamentos
	@@la:	mov	bl,cs:RADPortSlide[si]
		or	bl,bl
		jz	@@lb		; no slide for this channel
		call	GetFreq
		mov	ch,bl
		sar	cx,8		; sign extend 8bit->16bit
		add	ax,cx
		call	SetFreq

	; process volume slides
	@@lb:	mov	ch,cs:RADVolSlide[si]
		mov	cl,cs:Old43[si]	; contains current volume
		and	cl,3fh
		xor	cl,3fh
		or	ch,ch
		jz	@@lc
		jns	@@lba

		; slide volume up
		sub	cl,ch
		cmp	cl,64
		jb	@@lbb
		mov	cl,63
		jmp	@@lbb

		; slide volume down
	@@lba:	sub	cl,ch
		jns	@@lbb
		xor	cl,cl

	@@lbb:	mov	ch,cl
		mov	cl,bh		; channel to set
        call RADSetVolume

	; process tone slides
	@@lc:	cmp	cs:RADToneSlide[si],0
		jz	@@lx		; no tone slide
		mov	bl,cs:ToneSlideSpeed[si]	; shouldn't get wiped uc

		; get current absolute frequency
		call	GetFreq

		; sign extend speed/direction
		mov	dh,bl
		PUSH CX
		MOV CL,8
		sar	dx,CL
		POP CX

		; get destination frequency
		mov	cl,cs:ToneSlideFreqL[si]
		mov	ch,cs:ToneSlideFreqH[si]
		cmp	ax,cx
		jz	@@le		; already at destination?!
		ja	@@ld		; tone slide down (source > dest)

		; doing a tone slide up
		add	ax,dx
		cmp	ax,cx
		jb	@@lg		; still under destination
		jmp	@@le		; reached destination

		; doing a tone slide down
	@@ld:	sub	ax,dx
		cmp	ax,cx
		ja	@@lg		; still over destination

		; reached destination so stop tone slide
	@@le:	mov	ax,cx		; clip it onto destination
		mov	cs:RADToneSlide[si],0	; disables tone slide

		; write new frequency back to channel
	@@lg:	call	SetFreq

	@@lx:	inc	bh
		inc	si
		cmp	si,9
		jb	@@la
		ret
UpdateNotes Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Returns the current absolute frequency of channel
; IN:
;	SI	- channel
; OUT:
;	AX	- frequency
; USES:
;	CX, DX
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
GetFreq Proc Near	
        mov	cl,cs:OldA0[si]
		mov	ch,cs:OldB0[si]
		and	ch,3		; mask to get high frequency
		sub	cx,FreqStart
		mov	al,cs:OldB0[si]
		shr	al,1
		shr	al,1
		and	ax,7		; mask to get octave
		mov	dx,FreqRange
		mul	dx
		add	ax,cx
		ret
GetFreq EndP

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Sets the channel's frequency
; IN:
;	AX	- absolute frequency
;	SI	- channel
; USES:
;	CX, DX
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
SetFreq Proc Near
        mov	cx,FreqRange
		xor	dx,dx
		div	cx		; extracts octave in AX and freq. in DX
		add	dx,FreqStart

		mov	ah,cs:OldB0[si]
		and	ah,11100000b	; keep old toggles
		shl	al,1		; move octave to correct bit position
		shl	al,1
		or	al,ah		; insert octave
		or	al,dh		; insert high frequency
		mov	ah,bh
		add	ah,0b0h
		mov	cs:OldB0[si],al
		call	WriteOPL

		sub	ah,10h
		mov	al,dl		; low frequency
		mov	cs:OldA0[si],al
		jmp	WriteOPL
SetFreq Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Load in instrument data into a given channel.
; IN:
;	CL	- channel to load instrument into (0..8)
;	DL	- instrument no. (1..31)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
LoadInst Proc Near
        push	ax bx si
		
        XOR BX,BX
		MOV BL,CL
		MOV CS:CH_Smp_Pla[BX],DL	 ; MMSS Save for Display
        MOV CS:Ch_Part_I_Smp[BX],DL
		OR CS:Ch_Control[BX],M_VolChanged	
        AND CS:Ch_Control[BX],Not CM_Stopped

		mov	si,cx
		and	si,0ffh
		mov	ah,cs:ChannelOffs[si]	; Adlib register offsets

;		xor	bx,bx
		mov	bl,dl
		dec	bx
		add	bx,bx
		mov	bx,cs:InstPtrs[bx]	; get instrument offset
		or	bx,bx
		jz	@@lx		; no instrument data ?!

		mov	al,2[bx]
		
		mov	cs:Old43[si],al	; old 43.. value
        AND AL,3Fh                         ; MMSS Save the Volume
		MOV DL,64
		SUB DL,AL
        MOV CS:Ch_Part_Vol[SI],DL	           
		MOV CS:Ch_Volume[SI],DL
		OR  CS:Ch_Control[SI],M_VolChanged  ; Force the Display

		mov	dl,4

	@@la:	
	    mov al,1[bx]
		call	WriteOPL		; load carrier
		add	ah,3
		mov	al,[bx]
		call	WriteOPL		; load modulator
		add	bx,2

		add	ah,20h-3
		dec	dl
		jnz	@@la

		add	ah,40h		    ; do E0 range now
		mov	al,2[bx]
		call	WriteOPL
		add	ah,3
		mov	al,1[bx]
		call	WriteOPL

		mov	ah,0c0h
		add	ah,cl
		mov	al,[bx]
		call	WriteOPL

	@@lx:	
	    pop si bx ax
		ret
LoadInst Endp

ChannelOffs	db	20h,21h,22h,28h,29h,2ah,30h,31h,32h

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Outputs a value to an ADLIB register.
; IN:
;	CL	- channel to set volume on
;	CH	- new volume
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
RADSetVolume Proc Near
        push	ax bx

		xor	bx,bx
		mov	bl,cl

	; ensure volume is within range
		cmp	ch,64
		jb	@@la
		mov	ch,63

	; get old 43.. value
	@@la:	
		MOV AL,64
		SUB AL,CL
        MOV CS:Ch_Part_Vol[BX],AL	           ; MMSS Save for Display
		MOV CS:Ch_Volume[BX],AL
		OR CS:Ch_Control[BX],M_VolChanged
	
	    mov al,cs:Old43[bx]
		and	al,0c0h		; mask out volume bits
		xor	ch,3fh
		or	al,ch		; insert volume
		mov	cs:Old43[bx],al	; keep new 43.. value

	; write new volume into Adlib
		mov	ah,cs:ChannelOffs[bx]
		add	ah,23h
		call	WriteOPL

		pop	bx ax
		ret
RADSetVolume Endp

;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
; Outputs a value to an ADLIB register.
; IN:
;	AH	- register no.
;	AL	- value
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;Adlib:		
;        push ax dx

;		mov	dx,cs:AdlibPort
;		xchg ah,al
;		out	dx,al
;		rept 6
;		in	al,dx
;		endm

;		inc	dx
;		mov	al,ah
;		out	dx,al
;		dec	dx
;		mov	ah,22
;	@@la:	in	al,dx
;		dec	ah
;		jnz	@@la

;		pop	dx ax
;		ret


; Variables
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;AdlibPort	dw	388h		; default Adlib base port

InstPtrs dw 31 dup (0)	; offsets of instrument data
Old43 Equ Old_KSL_TL_43 ; db	9 dup (0)	; record of 43..   register values
OldA0 Equ Old_FB        ; db	9 dup (0)	; record of A0..A8 register values
OldB0 Equ Old_Key_B0    ; db	9 dup (0)	; record of B0..B8 register values

ToneSlideSpeed db 9 dup (1)	; speed of tone slide
ToneSlideFreqL db 9 dup (?)	; destination frequency of tone slide
ToneSlideFreqH db 9 dup (?)

RADToneSlide db 9 dup (?)	; tone slide flag
RADPortSlide db 9 dup (?)	; portamento slide
RADVolSlide	 db 9 dup (?)	; volume slide

ModSeg		dw	?	; segment of module (starts at offset 0)
;Speed		db	?	; speed (n/50Hz) of tune (Tempo)
;SpeedCnt	db	?	; counter used for deriving speed (Cmpt_Tempo)

;OrderSize	dw	?	; no. of entries in Order List (Sequence_Len)
OrderList	dw	?	; offset in module of Order List
;OrderPos	dw	?	; current playing position in Order List (C_Sequence)

PatternList	dw	?	; offset of pattern offset table in module
PatternPos	dw	?	; offset to current line in current pattern
;Line		db	?	; current line being played (usually +1) (C_Row)
