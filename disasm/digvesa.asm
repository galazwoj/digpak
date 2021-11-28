;
;	nop opcodes and padding at the end of file can be removed
;
		.model tiny, C

VERSION_NUMBER	equ	340

	INCLUDE COMPAT.INC
        INCLUDE PROLOGUE.MAC          ;; common prologue
	INCLUDE SOUNDRV.INC
	INCLUDE VBEAI.INC

CPROC 	equ	<Proc near C>

BUILD 	EQU 21

IF	BUILD EQ 21
DIG_VBEAI	=	1
DIG_PAUDIO      =     	1
BACKFILL	=	1
ENDIF
		.code
		.386
		org 100h
		assume es:nothing, ss:nothing

start:
		jmp	LoadSound

       		db 'DIGPAK',0,0Dh,0Ah
IDENTIFIER	db 'VESA DIGPAK Wave Driver',0,0Dh,0Ah 
		db 'The Audio Solution, Copyright (c) 1993',0,0Dh,0Ah
		db 'Written by John W. Ratcliff',0,0Dh,0Ah

		org 200h
		jmp	near ptr InstallInterupt
		jmp	near ptr DeInstallInterupt
DUMMYBASE	dw	-1
DUMMYIRQ	dw	-1
DUMMYEXTRA	dw	-1

DPMI		dw	0	; Default 32 bit addressing mode is off.

JumpTable	dw offset FUNCT1	
		dw offset FUNCT2
		dw offset FUNCT3
		dw offset fUNCT4
		dw offset fUNCT5
		dw offset fUNCT6
		dw offset fUNCT7
		dw offset fUNCT8
		dw offset fUNCT9
		dw offset fUNCTA
		dw offset FUNCTB
		dw offset FUNCTC
		dw offset FUNCTD
		dw offset FUNCTE
		dw offset FUNCTF
		dw offset FUNCT10
		dw offset fUNCT11
		dw offset fUNCT12
		dw offset fUNCT13
		dw offset fUNCT14
		dw offset fUNCT15
		dw offset fUNCT16
		dw offset fUNCT17
		dw offset fUNCT18
		dw offset fUNCT19

IF      BACKFILL
BACKF	dw	0	; Backfill defaults to off
ENDIF

JumpPtr		dw 0			

CallBacks	dw	0	; Callback to application flag.
CallBack	LABEL DWORD	     ; Callback address label.
CallLow 	dw	0	; Low word of callback address.
CallHigh	dw	0	; High word of callback address.
CallDS		dw	0	; Value of DS register at callback time.
DivisorRate	dw	0	; Default divisor rate.
RecordMode	dw	0		; set audio recording flag.
PlayMode	dw	PCM_8_MONO	; Default play mode is 8 bit PCM.

;; Data used by Kernel interupt
KJUMP		FARPTR	<>		; Address
OLDIN		FARPTR	<>		; Original interupt vector.
ID      	db      'KERN'          ; 4B45524Eh Interupt identifier string.
IND     	db      'KR'            ; 4B52h indicates a kernel installed interupt.
				
SoundInterupt	proc far	
;;; Usage: DS:SI -> point to sound structure to play.
;; FUNCT1  AX = 0688h	 DigPlay
;; FUNCT2  AX = 0689h	 Sound Status
;; FUNCT3  AX = 068Ah	 Massage Audio
;; FUNCT4  AX = 068Bh	 DigPlay2, pre-massaged audio.
;; FUNCT5  AX = 068Ch	 Report audio capabilities.
;; FUNCT6  AX = 068Dh	 Report playback address.
;; FUNCT7  AX = 068Eh	 Set Callback address.
;; FUNCT8  AX = 068Fh	 Stop Sound.
;; FUNCT9  AX = 0690h	 Set Hardware addresses.
;; FUNCTA  AX = 0691h	 Report Current callback address.
;; FUNCTB  AX = 0692h	 Restore hardware vectors.
;; FUNCTC  AX = 0693h	 Set Timer Divisor Sharing Rate
;; FUNCTD  AX = 0694h	 Play preformatted loop
;; FUNCTE  AX = 0695h	 Post Pending Audio
;; FUNCTF  AX = 0696h	 Report Pending Status
;; FUNCT10 AX = 0697h	 Set Stereo Panning value.
;; FUNCT11 AX = 698h	 Set DigPak Play mode.
;; FUNCT12 AX = 699h	 Report Address of pending status flag.
;; FUNCT13 AX = 69Ah	 Set Recording mode 0 off 1 on.
;; FUNCT14 AX = 69Bh	 StopNextLoop
;; FUNCT15 AX = 69Ch	 Set DMA backfill mode.
;; FUNCT16 AX = 69Dh	 Report current DMAC count.
;; FUNCT17 AX = 69Eh	 Verify DMA block.
;; FUNCT18 AX = 69Fh	 Set PCM volume.
;; FUNCT19 AX = 6A0h	 Set 32 bit addressing interface on/off
	cmp	ax, 688h
	jb	short loc_28C
	cmp	ax, 6A0h
	ja	short loc_28C
	SetSemaphore		; Set the inside DigPak semaphore
	sti
	sub	ax, 688h
	push	ax
	call	Debugging
	shl	ax, 1
	add	ax, offset JumpTable
	xchg	ax, bx
	mov	bx, cs:[bx]
	xchg	ax, bx
	mov	cs:JumpPtr, ax
	jmp	cs:JumpPtr
loc_28C:			
	cmp	word ptr cs:OLDIN.XPTR.POFF, 0
	jnz	short loc_29C
	cmp	word ptr cs:OLDIN.XPTR.PSEG, 0
	jz	short loc_2A1
loc_29C:		
	jmp	cs:OLDIN.DPTR
loc_2A1:		
	ClearSemaphoreIRET
SoundInterupt	endp

FUNCT1:			
;;**************************************************************************
;:Function #1: DigPlay, Play an 8 bit digitized sound.
;:
;:	  INPUT:  AX = 688h    Command number.
;:		  DS:SI        Point to a sound structure that
;:			       describes the sound effect to be played.
;;**************************************************************************
	PushCREGS
	ConvertDPMI ds,esi
loc_2C7:				
	call	CompleteSound
	call	SetAudio
	call	PlaySound
	PopCREGS
	ClearSemaphoreIRET

FUNCT2:					
;;**************************************************************************
;:Function #2: SoundStatus, Check current status of sound driver.
;:
;:	  INPUT:  AX = 689h
;:	  OUTPUT: AX = 0       No sound is playing.
;:		     = 1       Sound effect currently playing.
;;		    DX = 1	 Looping a sound effect
;;		  BX = Version numer, in decimal, times 100, so that 3.00
;;		       would be 300.  Version number begins with version 3.10
;;		       which includes the DigPak semaphore.
;;**************************************************************************
	mov	bx,VERSION_NUMBER      	; Return VERSION NUMBER in BX! 3.40
	cmp	cs:LOOPING,1		; Looping a sample?
	jnz	short loc_2F4
	xor	ax, ax
	mov	dx,1			; Return high word looping flag.
	ClearSemaphoreIRET
loc_2F4:			
	mov	ax, cs:PlayingSound
	xor	dx,dx		; Not looping
	ClearSemaphoreIRET

FUNCT3:				
;;**************************************************************************
;:Function #3: MassageAudio, Preformat audio data into ouptut hardware format.
;:
;:	  INPUT:  AX = 68Ah
;:		  DS:SI        Point to address of sound structure.
;;**************************************************************************
	PushCREGS
	ConvertDPMI ds,esi
loc_320:				
	cmp	cs:PlayMode, PCM_16_MONO
	jz	short loc_32B
	call	SetAudio
loc_32B:				
	PopCREGS
	ClearSemaphoreIRET

fUNCT4:				
;;**************************************************************************
;:Function #4: DigPlay2, Play preformatted audio data.
;:
;:	  INPUT:  AX = 68Bh
;:		  DS:SI        Point to address of sound structure.
;;**************************************************************************
	PushCREGS
	ConvertDPMI ds,esi
loc_355:	
	call	CompleteSound
	call	DoSoundPlay
	mov	[cs:FROMLOOP],0    	; Turn from loop semephore off.
	PopCREGS
	ClearSemaphoreIRET

fUNCT5:				
;;**************************************************************************
;:Function #5: AudioCapabilities, Report capabilities of hardware device.
;:
;:	  INPUT:  AX = 68Ch
;:	  OUTPUT: AX = Bit 0 -> On, supports background playback.
;:				Off, driver only plays as a foreground process.
;:		       Bit 1 -> On, source data is reformatted for output device.
;:				 Off, device handles raw 8 bit unsigned audio.
;:		       Bit 2 -> On, Device plays back at a fixed frequency, but
;:				    the audio driver will downsample input data
;:				    to fit.
;:				Off, device plays back at user specified frequency.
;:				(NOTE: You can still playback an audio sample at
;:				       whatever frequency you wish.  The driver
;:				       will simply downsample the data to fit
;:				       the output hardware.  Currently it does
;:				       not support upsampling though.)
;:		       Bit 3 -> On, this device uses the timer interrupt vector
;:				during sound playback.
;:		  DX = If this device plays back at a fixed frequency the DX
;:		       register will contain that fixed frequency playback rate.
;;**************************************************************************
	mov	ax, PLAYBACK
	mov	bx, cs
	mov	cx, offset IDENTIFIER 	;	"VESA DIGPAK Wave Driver\r\n"
	ClearSemaphoreIRET

fUNCT6:					
;;**************************************************************************
;:Function #6: ReportSample, Report current playback address.
;:
;:	  INPUT:  AX = 68Dh
;:	  OUTPUT: AX = Current playback address.  Obviously this only
;:		       applies to background drivers.  Note that for some
;:		       drivers this playback address is an aproximation
;:		       and not necessarily the EXACT sample location.
;:		       You can use this service to synchronize
;:		       animation or video effects temporaly with the
;:		       audio output.
;;**************************************************************************
	ClearSemaphoreIRET

fUNCT7:	
;;**************************************************************************
;:Function #7: SetCallBackAddress, sets a user's sound completion
;:		       callback addess.
;:
;:	  INPUT: AX = 068Eh
;:		 BX = Offset portion of far procedure to callback.
;:		 DX = Segment portion of far procedure to callback.
;:		 DS = Data Segment register value to load at callback time.
;:	  OUTPUT: None.
;:
;:		 This function allows the user to specify a callback
;:		 address of a far procedure to be invoked when a sound
;:		 effect has completed being played.  This function is
;:		 disabled by default.  Sending a valid address to this
;:		 function will cause a callback to occur whenever a sound
;:		 sample has completed being played.  The callers DS register
;:		 will be loaded for him at callback time.  Be very careful
;:		 when using this feature.  The application callback procedure
;:		 is being invoked typically during a hardware interupt.
;:		 Your application should spend a small an amount of time
;:		 as possible during this callback.  Remember that the
;:		 callback must be a far procedure.  The sound driver
;:		 preserves ALL registers so your callback function does
;:		 not need to do so.  Do not perform any DOS functions
;:		 during callback time because DOS is not re-entrent.
;:		 Keep in mind that your own application has been interupted
;:		 by the hardware it this point.  Be very careful when making
;:		 assumptions about the state of your application during
;:		 callback time.  Hardware callbacks are generally used
;:		 to communicate sound event information to the application
;:		 or to perform a technique called double-buffering, whereby
;:		 your application immediatly posts another sound effect to
;:		 be played at the exact time that the last sound effect
;:		 has completed.
;:
;:		 WARNING!!! Be sure to turn off hardware callbacks when
;:		 your application leaves!!! Otherwise, harware callbacks
;:		 will be pointing off into memory that no longer contains
;:		 code.	This function is for advanced programmers only.
;;**************************************************************************
	or	bx, bx
	jnz	short loc_39E
	or	dx, dx
	jnz	short loc_39E
	xor	ax, ax
	mov	cs:CallBacks, ax	; Callbacks disabled.   	
	mov	cs:CallLow, ax          ; Low address.          
	mov	cs:CallHigh, ax
	jmp	short loc_3B4
loc_39E:				
	mov	cs:CallLow, bx
	mov	cs:CallHigh, dx
	mov	cs:CallDS, ds
	mov	cs:CallBacks, 1
loc_3B4:
	ClearSemaphoreIRET	

fUNCT8:					
;;**************************************************************************
;:Function #8: StopSound, stop currently playing sound.
;:
;:	  INPUT: AX = 68Fh
;:	  OUTPUT: None.
;:
;:		Will cause any currently playing sound effect to be
;:		terminated.
;;**************************************************************************
	mov	cs:PENDING, 0
	mov	cs:LOOPING, 0
	call	StopSound
	ClearSemaphoreIRET

fUNCT9:					
;;**************************************************************************
;:Function #9: SetAudioHardware, set up hardware information.
;:
;:	  INPUT: AX = 690h
;:		 BX = IRQ if device needs one set.
;:		 CX = BASE I/O Address, if device needs one set.
;:		 DX = OTHER, some other possible information the hardware might need.
;:
;:	  OUTPUT: NONE.
;:
;:
;:	  Certain harware can be reconfigured to different IRQ and base
;:	  address settings.  This function call allows the application
;:	  programmer to overide these default settings.  The interpretation
;:	  of these parameters might change from driver to driver.  Currently
;:	  only the SBLASTER (Creative Labs SoundBlaster) driver can be
;:	  reconfigured, upon request of Derek Smart.
;;**************************************************************************
	ClearSemaphoreIRET

fUNCTA:				
;;**************************************************************************
;;FUNCTION #10: ReportCallbackAddress
;;
;;	  INPUT: AX = 691h
;;	  OUTPUT: AX:DX -> far pointer to current callback address.
;;		  BX -> original caller's DS register.
;;
;;	  This function should probably never need to be used by your
;;	  application software.  It is provided because the MIDPAK,
;;	  MIDI driver, needs to revector hardware callbacks so that
;;	  it can handle hardware contention problems between digitized
;;	  sound playback and synthesized sound playback.
;;**************************************************************************
	mov	ax, cs:CallLow
	mov	dx, cs:CallHigh
	mov	bx, cs:CallDS
	ClearSemaphoreIRET

FUNCTB:		
;;**************************************************************************
;;FUNCTION #11: RestoreHardware
;;
;;	  INPUT: AX = 692h
;;	  OUTPUT:
;;
;;		Put hardware back to initial state.  Invoked by the
;;		DeInstall code.  Not to be called by an application program!
;;**************************************************************************		
	mov	cs:CallBacks, 0
	mov	cs:CallLow, 0
	mov	cs:CallHigh, 0
	push	ds
	push	cs
	pop	ds
	call	VesaRemove
	pop	ds
	ClearSemaphoreIRET

FUNCTC:		
;;**************************************************************************
;; FUNCTION #12: SetTimerDivsorRate
;;
;;	   INPUT: AX = 693h
;;		  DX = Countdown timer divisor rate, so that timer based
;;		       drivers can service application timer interrupts
;;		       at their previous rate.	Service rate will be an
;;		       aproximation, that is fairly close.  To reset timer
;;		       divisor to default of 18.2 pass a 0 in the DX register.
;;**************************************************************************
	mov	cs:DivisorRate,	dx	; Set timer divisor rate.
	ClearSemaphoreIRET

FUNCTD:		
;;**************************************************************************
;; FUNCTION #13: DigPlayLoop
;;
;;	   INPUT: AX = 694h
;;		  DS:SI ->sound structure, preformated data.
;; Here's the process...
;;	Remember the current callback address.
;;	Set new callback address to US!
;;	Save sound structure.
;;	Call DigPlay.
;;	At call back, keep playing.
;;	This gets done until StopSound is called.
;;	Stop sound checks to see if we need to restore the callback address.
;;	If PlaySound is invoked, and we are currently looping a sound then
;;	stopsound is invoked.
;;**************************************************************************
	PushAll 	; Save all registers.
	ConvertDPMI ds,esi
	push	cs
	pop	es
	mov	di, offset LOOPSND
	mov	cx, SIZE LOOPSND
	rep movsb
	mov	ax, 68Fh         	; Stop any currently playing sound.     
	int	66h		        ; do it.                                
	mov	cs:LOOPING, 1           ; We are now looping a sound sample.    
	mov	ax, cs
	mov	ds, ax
	mov	dx, ax
	mov	ax, 68Eh        	   
	mov	bx, offset LoopBack        
	int	66h		        ; Set loop callback.	
	PopAll
	push	cs
	pop	ds
	mov	si, offset LOOPSND
	mov	word ptr cs:LOOPSOUND, si
	mov	word ptr cs:LOOPSOUND+2, ds
	mov	cs:FROMLOOP, 1		; Set from looping semephore    
	mov	ax, 68Bh                ; Do FUNCT4                     
	jmp	fUNCT4                  ; Do a DigPlay2                 

FUNCTE:					
;;**************************************************************************
;; FUNCTION #14: PostAudioPending
;;
;;	   INPUT: AX = 695h
;;		  DS:SI ->sound structure, preformated data.
;;	   OUTPUT: AX = 0  Sound was started playing.
;;		   AX = 1  Sound was posted as pending to play.
;;**************************************************************************
	PushCREGS
	ConvertDPMI ds,esi
	cli				; Turn off interupts while making this determination.
	mov	ax, cs:PlayingSound
	or	ax, ax			; Currently playing a sound?           
	jnz	short loc_4C8           ; yes->try to post pending.            
	sti                             ; We can play it now.                  
	call	DoSoundPlay             ;                                      
	xor	ax, ax                  ; Return, audio sample is now playing. 
	PopCREGS
	ClearSemaphoreIRET
loc_4C8:				
	cmp	cs:PENDING, 1		; Already have a pending sound effect? 
	jnz	short loc_4DF           ; no, post it for pending play.        
	mov	ax, 2                   ; return code of two.                  
	PopCREGS
	ClearSemaphoreIRET
loc_4DF:				
	mov	cs:PENDING, 1		; Pending sound.
	push	es
	push	di
	push	cs
	pop	es
	mov	di, offset PENDSND
	mov	cx, SIZE PENDSND
	rep movsb
	mov	cs:PENDING, 1
	mov	cs:CallBacks, 1
	mov	cs:CallLow, offset PlayPending
	mov	cs:CallHigh, cs
	mov	cs:CallDS, cs
	pop	di
	pop	es
	mov	ax,1			; Posted as pending.
	PopCREGS
	ClearSemaphoreIRET

FUNCTF:					
;;**************************************************************************
;; FUNCTION #15: AudioPendingStatus
;;
;;	   INPUT: AX = 696h
;;	  OUTPUT: AX = 0 No sound is playing.
;;		  AX = 1 Sound playing, sound pending.
;;		  AX = 2 Sound playing, no sound pending.
;;**************************************************************************
	cli
	mov	ax, cs:PlayingSound
	or	ax, ax			; Currently playing a sound?
	jnz	short loc_533           ; yes->try to post pending. 
	ClearSemaphoreIRET
loc_533:				
	cmp	cs:PENDING, 1		; Have a sound pending?                       
	jz	short loc_546           ; yes, return pending status.                 
	mov	ax, 1                   ; Sound is playing, but no sound is pending.  
	ClearSemaphoreIRET
loc_546:				
	mov	ax, 2
	ClearSemaphoreIRET

FUNCT10:				
;;**************************************************************************
;; FUNCTION #16: SetStereoPan
;;
;;	   INPUT: AX = 697h
;;		  DX = stereo pan value. 0 full volume right.
;;					64 full volume both.
;;				       127 full volume left.
;;	 OUTPUT: AX = 0 command ignored, driver doesn't support stereo panning.
;;		 AX = 1 pan set.
;;**************************************************************************
	xor	ax, ax			; Doesn't support stereo panning.
	ClearSemaphoreIRET

fUNCT11:				
;;**************************************************************************
;; FUNCTION #17: SetPlayMode
;;
;;	   INPUT: AX = 698h
;;		  DX = Play Mode function.
;;			  DX = 0 -> 8 bit PCM
;;			     = 1 -> 8 bit Stereo PCM (left/right)
;;			     = 2 -> 16 bit PCM
;;			     = 3 -> 16 bit PCM stereo.
;;
;;	 OUTPUT: AX = 1 -> mode set.
;;		 AX = 0 -> mode not supported by this driver.
;;
;;**************************************************************************
	cmp	dx,PCM_8_MONO		; ALL drivers support 8 bit PCM mono sound.
	jnz	short loc_570   	; Non supported sound playback mode.
	mov	cs:PlayMode, dx	
	mov	ax, 1
	ClearSemaphoreIRET
loc_570:				
	xor	ax, ax
	ClearSemaphoreIRET

fUNCT12:				
;;**************************************************************************
;; FUNCTION #18: Report Address of Pending Flag
;;
;;	   INPUT: AX = 699h
;;
;;	 OUTPUT: AX:DX -> form far address of pending status flag.
;;		 BX:DX -> form address of DigPak interrupt semaphore.
;;
;;**************************************************************************
	mov	dx, cs			; Code segment.                     
	mov	ax, offset PENDING      ; Address of pending flag.          
	mov	bx, offset INDIGPAK     ; Address of semaphore address.     
	ClearSemaphoreIRET

fUNCT13:				
;;**************************************************************************
;; FUNCTION #19: Set audio recording mode.
;;
;;	   INPUT: AX = 69Ah
;;		  DX = 0 turn audio recording ON.
;;		     = 1 turn audio recording OFF.
;;
;;	 OUTPUT: AX = 0 sound driver doesn't support audio recording.
;;		 AX = 1 audio recording mode is set.
;;
;;**************************************************************************
	mov	ax, 0
	ClearSemaphoreIRET

fUNCT14:				
;;**************************************************************************
;; FUNCTION #20: StopNextLoop
;;
;;	   INPUT: AX = 69Bh
;;
;;	   OUTPUT: NOTHING, Stop Looped sample, next time around.
;;
;;**************************************************************************
	mov	cs:CallBacks, 0
	mov	cs:LOOPING, 0
	ClearSemaphoreIRET

fUNCT15:				
;;**************************************************************************
;; FUNCTION #21: Set DMA back fill mode.
;;
;;	   INPUT: AX = 69Ch
;;		  DX = backfill mode 0 means turn it off.
;;		       and a 1 means to turn it on.
;;
;;	   OUTPUT: AX = 1 -> back fill mode set.
;;			0 -> driver doesn't support DMA backfill.
;;
;;**************************************************************************
	push	ds
	push	di
	push	si
	push	cs
	pop	ds
	push	dx
	call	StopSound
	pop	dx
	mov	cs:BACKF, dx
	mov	ax, 1			; Back fill mode was set
	pop	si
	pop	di
	pop	ds
	ClearSemaphoreIRET

fUNCT16:				
;;**************************************************************************
;; FUNCTION #22: Report current DMAC count.
;;
;;	   INPUT: AX = 69Dh
;;
;;	   OUTPUT: AX = Current DMAC count.
;;
;;**************************************************************************
	call	ReportDMAC
	ClearSemaphoreIRET

fUNCT17:				
;;**************************************************************************
;; FUNCTION #23: Verify DMA block, check to see if it crosses a 64k page
;;		 boundary for the user.
;;
;;	   INPUT: AX = 69Eh
;;		  ES:BX -> address of sound.
;;		  CX	-> length of sound effect.
;;
;;	   OUTPUT: AX = 1 Block is ok, DOESN'T cross 64k bounadary.
;;		   AX = 0 block failed, DOES cross 64k boundary.
;;
;;**************************************************************************
	PushCREGS
	ConvertDPMI es,ebx
	push	cx
	push	es
	push	bx
	call	CheckBoundary
	add	sp, 6
	PopCREGS
	ClearSemaphoreIRET

fUNCT18:				
;;**************************************************************************
;; FUNCTION #24: Set PCM volume.
;;
;;	   INPUT: AX = 69Eh
;;		  BX = Left channel volume (or both if mono) 0-256
;;		  CX = Right channel volume (or both if mono) 0-256
;;
;;	   OUTPUT: AX = 1 Volume set
;;		   AX = 0 Device doesn't support volume setting.
;;
;;**************************************************************************
	xor	ax, ax		; Default, volume not set.
	ClearSemaphoreIRET

fUNCT19:				
;; Set 32 bit DPMI compliant address passing on.
	mov	cs:DPMI, dx
	ClearSemaphoreIRET

GET20BIT	Macro	
	push	cx
	mov	cl, 4
	rol	dx, cl
	mov	cx, dx
	and	dx, 0Fh
	and	cx, 0FFF0h
	nope 
	add	ax, cx
	adc	dx, 0
	pop	cx
	endm

CheckBoundary	CPROC SOURCE:DWORD,SLEN:WORD
	mov	ax, word ptr SOURCE
	mov	dx, word ptr SOURCE+2
	GET20BIT			; Into 20 bit mode.
	mov	bx, dx			; Save DMA page.
	mov	ax, word ptr SOURCE
	mov	dx, word ptr SOURCE+2
	add	ax, SLEN		; Point to end.
	GET20BIT
	mov	ax, 1			; Default is OK.
	cmp	bl, dl			; Same DMA page?
	je	loc_662
	xor	ax, ax			; Didn't work.
loc_662:
	nope 
	nope 
	ret
CheckBoundary	endp

PlayPending	proc far		
	cmp	PENDING, 1		; Pending?
	jnz	short loc_681
	mov	PENDING, 0
	mov	cs:CallBacks, 0   	; No longer have one pending.. 
	mov	si, offset PENDSND      ; Address of pending sound.    
	call	DoSoundPlay             ; Do a sound play call.        
	retf
loc_681:				
	mov	cs:CallBacks, 0       	; Disable callbacks.
locret_688:
	retf
PlayPending	endp


DoSoundPlay	proc near		
	PushCREGS			; Save all of the important C registers.
	call	SetAudio
	call	PlaySound
	PopCREGS
	ret
DoSoundPlay	endp


CheckCallBack	proc near		
	cmp	cs:CallBacks, 0 	; Callbacks enabled?	
	jz	short locret_6BD	; no, exit.               
	PushAll                         ; Save all registers      
	mov	ds, cs:CallDS           ; Get DS register.        
	call	dword ptr cs:CallLow    ; far call to application.
	PopAll                          ; Restore all registers.  
locret_6BD:	
	ret
CheckCallBack	endp

INDIGPAK	dw    0			; Inside DigPak semaphore.                          			                                                    
FROMLOOP	dw    0			                                                    
SAVECALLBACK	dd    0                 ; Saved callback address.                           
SAVECALLDS	dw    0                                                                     
LOOPING		dw    0			; True if we were looping.                          
                                                                                            
LOOPSOUND	dd    0			                                                    
LOOPSND		SOUNDSPEC	<>                                                          
                                                                                            
PENDING		dw    0			; True, when second sound sample is pending.        			
PENDSND		SOUNDSPEC	<>      ; Sound structure of pending sound.                 

LoopBack	proc far		
	mov	ax, 68Bh		; Play preformated data.
	mov	cs:FROMLOOP, 1
	lds	si, LOOPSOUND
	int	66h			; Start playing the sound again
	retf
LoopBack	endp

SetAudio	proc near	
	mov	(SOUNDSPEC ptr [si]).ISPLAYING.XPTR.POFF,offset PlayingSound
	mov	(SOUNDSPEC ptr [si]).ISPLAYING.XPTR.PSEG,cs
	les	bx,(SOUNDSPEC ptr [si]).PLAYADR.DPTR
	mov	cx,(SOUNDSPEC ptr [si]).PLAYLEN
	mov	dx,(SOUNDSPEC ptr [si]).FREQUENCY
	push	cs			; DS = Code group.
	pop	ds
	ret
SetAudio	endp

EndLoop		proc near	
	mov	cs:CallBacks, 0
	mov	cs:CallLow, 0
	mov	cs:CallHigh, 0
	mov	cs:LOOPING, 0
	call	StopSound
	ret
EndLoop		endp

CompleteSound	proc near	
	cmp	cs:FROMLOOP, 1		; In loop callback?
	jnz	short loc_737
	call	EndLoop            	; don't wait for loop to complete, end it!
loc_737:			
	cmp	cs:PlayingSound, 0	; Wait until last sound completed.
	jnz	short loc_737
	ret
CompleteSound	endp

PlayingSound	dw 0			; Holds current status:            	
					                                   
StereoMono	db 0FFh			; Default is mono flag 0FFh.       
                                                                           
hWAVE		dw 0			; handle to the wave device        
CallBackRoutine	dd 0                    ; User's callback routine          
ServicesPtr	dd 0			; holds the original routine       
	
SERVICESLEN	equ	2048		   ; size of the services structure
hServices	db	SERVICESLEN dup(0) ; info & services structure address
					
blockoffset dw	0		

.386
;
;   /*\
;---|*|----------------------====< VesaPresent >====---------------------------
;---|*|
;---|*| Queries the presence of a VESA wave driver.
;---|*|
;---|*|   AX = 0, no VESA Wave driver found.
;---|*|   AX nonzero, VESA Wave driver found.
;---|*|
;   \*/

VesaPresent	CPROC
	sub	cx, cx
loc_F51:						
	inc	cx      		; move to the next handle                      
        mov     ax, VESAFUNCID                                                         
	mov	bl, VESAFUNC2                                                          
	mov	dx, 1                   ; query #1 get the info struct. length         
	int	INTHOOK                                                                
	sub	ax, 4Fh                 ; good?                                        
	jnz	short loc_FA6           ; no, bail out                                 
	cmp	di, SERVICESLEN                                                        
	ja	short loc_F51           ; too big?                                     
        mov     ax, VESAFUNCID                                                         
	mov	bl, VESAFUNC2                                                          
	mov	dx, 2                                                                  
	mov	si, cs                  ; query #2 get the info structure              
	mov	di, offset hServices    ; si:di points to the info structure           
	int	INTHOOK                                                                
	sub	ax, 4Fh                                                                
	jnz	short loc_FA6           ; good call?                                   
	cmp	cs:[di.GeneralDeviceClass.gdcclassid],WAVDEVICE ; DAC?
	jnz	short loc_F51
	cmp	cs:[di.GeneralDeviceClass.gdcu][WAVEInfo.wimemreq],SERVICESLEN-16 ; enough memory?
	ja	short loc_F51
	mov	ax,VESAFUNCID
	mov	bl,VESAFUNC2
	mov	dx,WAVESETPREFERENCE	; query #2 get the info structure
	mov	si, 0FFFFh
	mov	di, si
	int	INTHOOK
	or	di, di   		; highest priority?             
	jnz	short loc_F51           ; no, go for more...            
	mov	hWAVE, cx               ; yes, this is our handle       
;
; all done, return with FM and DAC found
;
        mov     ax,0110b                ; returns FM and DAC available
	ret
loc_FA6:				
	sub	ax, ax			; not found...
	ret
VesaPresent	endp

;
;   /*\
;---|*|-----------------------====< VesaInit >====-----------------------------
;---|*|
;---|*| Initialize VESA Wave interface.
;---|*|
;---|*|   Returns
;---|*|     NZ failed to init VESA interface.
;---|*|      Z successfully initialized VESA interface.
;---|*|
;   \*/

VesaInit	CPROC
	push	es
	push	si
;
; open the VBE/AI driver
;
	mov	si, offset hServices	; offset/16                    	
	mov	cl, 4                                                  
	shr	si, cl                                                 
	mov	ax, cs                                                 
	add	si, ax                  ; + segment                    
	inc	si                      ; + 16                         
	mov	ax, VESAFUNCID		; open function                
	mov	bl, VESAFUNC3                                          
	mov	cx, hWAVE               ; device handle is required    
	sub	dx, dx                  ; select 16 bit interface      
	int	INTHOOK		        ; open the device              
	sub	ax, 4Fh                 ; did it work?                 
	jnz	short loc_FEB           ; no, bail                     
	mov	word ptr ServicesPtr, cx	; yes, save it & say we're open for 
	mov	word ptr ServicesPtr+2,	si      ; business                          
	mov	es, si
	mov	si, cx
	mov	wptr es:[si.WAVEService.wsApplPSyncCB+0],offset VBECallback
	mov	wptr es:[si.WAVEService.wsApplPSyncCB+2],cs
	mov	wptr es:[si.WAVEService.wsApplRSyncCB+0],offset VBECallback
	mov	wptr es:[si.WAVEService.wsApplRSyncCB+2],cs
	sub	ax, ax			; return okay
loc_FEB:	
	pop	si
	pop 	es		
	ret
VesaInit	endp

;
;   /*\
;---|*|----------------------====< VesaRemove >====----------------------------
;---|*|
;---|*|
;---|*|
;   \*/

VesaRemove	CPROC
	mov	ax,VESAFUNCID		; close function
	mov	bl,VESAFUNC4
	mov	cx, hWAVE		; device handle is required     
	sub	dx, dx                  ; select 16 bit interface       
	int	INTHOOK	                ; open the device               
	sub	ax, 4Fh                 ; NZ if                         
	neg	ax                                                      
	sbb	ax, ax                  ; FFFF if not good, else 0000   
	neg	ax                      ; 0001 if not good, else 0000   
	ret
VesaRemove	endp

;
;   /*\
;---|*|---------------------====< VesaContinue >====---------------------------
;---|*|
;---|*| Continue previous transfer.
;---|*|
;   \*/

VesaContinue	CPROC
	push	es
	push	di
	mov	ax, 1				; prepair for failure          
	cmp	word ptr ServicesPtr+2,	0       ; get the services structure   
	jz	short loc_101D
	sub	ax, ax
	push	ax
	les	di, ServicesPtr			; get the services structure
	call	es:[di.WAVEService.wsResumeIO]
	inc	ax				; go from ffff to 0 or 0 to 01
loc_101D:
	pop	di
	pop	es		
	ret
VesaContinue	endp

;
;   /*\
;---|*|-----------------------====< VesaHalt >====-----------------------------
;---|*|
;---|*|
;---|*|
;   \*/

VesaHalt CPROC 
	push	es
	push	di
	cmp	BACKF, 1
	jnz	short loc_102F
	mov	BACKF, 0
loc_102F:				
	mov	ax, 1				; prepair for failure        
	cmp	word ptr ServicesPtr+2,	0       ; get the services structure 
	jz	short loc_1046
	sub	ax, ax
	push	ax
	les	di, ServicesPtr		; get the services structure	
	call	es:[di.WAVEService.wsStopIO]
	sub	ax, ax               	; it is stopped, no matter what
loc_1046:				
	pop	di
	pop	es
	ret
VesaHalt	endp

;
;   /*\
;---|*|---------------====< VesaOutput >====---------------
;---|*|
;---|*| Play a block of Data
;---|*|
;---|*| Entry Conditions:
;---|*|     dParm1 is the far block pointer
;---|*|     wParm3 is the block  length
;---|*|     wParm4 is the sample rate
;---|*|     DS points to our data segment
;---|*|
;---|*| Exit Conditions:
;---|*|     AX = 1 if not running
;---|*|     AX = 0 if now paused
;---|*|
;   \*/

VesaOutput CPROC SOUND:DWORD,SNDLEN:WORD,FREQ:WORD
	push	es
	push	si
	mov	cs:PlayingSound, 1
	les	si, ServicesPtr			; get the services structure
	mov	dx,[word ptr SOUND+2]	; get the buffer far *
	mov	ax,[word ptr SOUND]
	call	makelinear
	add	ax, SNDLEN
	mov	cs:blockoffset, ax
	mov	ax, 1                    	; mono                       
	cmp	word ptr ServicesPtr+2,	0       ; get the services structure 
	jz	short loc_10C9
;
; set the sample rate
;
	mov	cs:StereoMono, 0FFh
	push	ax
	cwd
	push	dx
	push	FREQ				; get the sample rate
	push	dx 
	push	dx 
	push	8				; no compression, 8 bit pcm       
	call	es:[si.WAVEService.wsPCMInfo]	; set the sample rate
;
; see which type of playback we need
;
	cmp	BACKF, 1			; In DMA backfill mode?
	jz	short loc_10B1                  ; yes, do 'playcont'   
;
; start the block

	push	[word ptr SOUND+2]	; far *
	push	[word ptr SOUND]
	sub	ax, ax                                      
	push	ax                              ; length    
	push	SNDLEN                          ; length    
	call	es:[si.WAVEService.wsWaveRegister]	; select register
	or	ax, ax
	jz	short loc_10C7
	push	ax
	sub	ax, ax
	push	ax
	push	ax
	call	es:[si.WAVEService.wsPlayBlock]	; start the block
	neg	ax				; FFFF=1, 0=0   
	xor	al, 1                           ; 1=BAD, 0=GOOD 
	jmp	short loc_10C9
loc_10B1:				
;
; start the block
;
	push	[word ptr SOUND+2]	; far *
	push	[word ptr SOUND]
	sub	ax, ax                                  
	push	ax                      	; full length   
	push	SNDLEN                  	; full length   
	push	ax                      	; second length 
	push	SNDLEN                  	; second length 
	call	es:[si.WAVEService.wsPlayCont]	; start the block
	neg	ax              		; FFFF is now 1, 0 is now 0
loc_10C7:				
	xor	al, 1				; 1=BAD, 0=GOOD            
loc_10C9:	
	pop	si
	pop	es			
	ret
VesaOutput	endp

;
;   /*\
;---|*|-----------------------====< VesaPause >====----------------------------
;---|*|
;---|*|
;---|*|
;   \*/

VesaPause	CPROC
	push	es
	push	di
	mov	ax, 1                   	; prepair for failure         
	cmp	word ptr ServicesPtr+2,	0       ; get the services structure  
	jz	short loc_10E5
	sub	ax, ax
	push	ax
	les	di, ServicesPtr			; get the services structure
	call	es:[di.WAVEService.wsPauseIO]
	inc	ax				; go from ffff to 0 or 0 to 01
loc_10E5:	
	pop	di
	pop	es			
	ret
VesaPause	endp

;
;   /*\
;---|*|----------------------====< VBECallback >====---------------------------
;---|*|
;---|*| VBECallback  --  End of block interrupts are handed to this routine
;---|*|
;   \*/

VBECallback	proc far		
	SetSemaphore
	push	ds
	push	es
	push	di
	push	cs
	pop	ds
	cmp	BACKF, 1			; In DMA backfill mode?    
	jz	short loc_110F                  ; yes, we don't do anying  
	sub	ax, ax
	mov	PlayingSound, ax
	push	ax
	push	ax
	push	ax
	push	ax
	les	di, ServicesPtr
	call	es:[di.WAVEService.wsWaveRegister]	; select register
	call	CheckCallBack
loc_110F:			
	pop	di
	pop	es
	pop	ds
	ClearSemaphore
	retf	0Eh
VBECallback	endp

;
;   /*\
;---|*|------====< void far * makelinear() >====------
;---|*|
;---|*| Convert a segment:offset into a linear address
;---|*|
;---|*| Entry Conditions:
;---|*|     dx:ax is the segment:offset to the DMA buffer
;---|*|
;---|*| Exit Conditions:
;---|*|     dx:ax is the linear address to the DMA buffer
;---|*|
;   \*/

makelinear	proc near		
	mov	bx, dx		; convert it to a linear address              
	mov	cl, 4                                                         
	rol	dx, cl                                                        
	and	dx, 0Fh                                                       
	shl	bx, cl          ; add offset portion of seg to offset         
	add	ax, bx                                                        
	sbb	bx, bx          ; bx = ffff if ax wrapped                     
	sub	dx, bx          ; increment dx if ax wrapped                  
	ret
makelinear	endp

;
;   /*\
;---|*|----====< ReportDMAC >====----
;---|*|
;---|*| Report the current position of the DMA controller
;---|*|
;   \*/

ReportDMAC	CPROC 
	push	bx
	push	cx
	push	dx
	push	es
	sub	ax, ax				; prepair for failure   
	cmp	word ptr cs:ServicesPtr+2, 0    ; any servicces?        
	jz	short loc_1153                  ; no, bail out          
	mov	ax,WAVEGETCURRENTPOS
	push	ax
	push	ax
	push	ax
	les	bx, cs:ServicesPtr		; get the services structure	
	call	es:[bx.WAVEService.wsDeviceCheck]
	mov	dx, cs:blockoffset
	sub	dx, ax
	xchg	ax, dx
loc_1153:			
	pop	es
	pop	dx
	pop	cx
	pop	bx
	ret
ReportDMAC	endp

;; CX ->number of bytes in sound sample.
;; ES:BX -> far address of sound sample to be played.
;; DX ->rate to play at.
PlaySound	proc near						
	cmp	cs:PlayMode, PCM_8_STEREO
	jnz	short loc_1162
	shl	dx, 1		; Times 2 playback frequency, when in stereo.  
loc_1162:	
	push	dx              ; Save sampling rate.                         
	push	cx              ; Number of bytes.                            
	push	es              ; Segment                                     
	push	bx              ; Offset                                      
	mov	ax, cs                                                        
	mov	ds, ax          ; DS=CS                                       
	call	VesaOutput      ; Send it.                                    
	add	sp, 8           ; Balance stack.                              
	ret
PlaySound	endp

StopSound	proc near		
	push	ds
	push	cs
	pop	ds
	call	VesaHalt
	pop	ds
	ret
StopSound	endp

DoCallBacks	proc near
	cmp	cs:CallBacks, 0
	jz	short locret_119D
	PushAll				; Save all registers         
	mov	ds, cs:CallDS           ; Get DS register.           
	call	dword ptr cs:CallLow    ; far call to application.   
	PopAll                          ; Restore all registers.     
locret_119D:			
	ret
DoCallBacks	endp

;; ***********************************************************************
;; ** Monochrome debugging code.
;; ***********************************************************************
MONOSCR equ 1

if MONOSCR

;   /*\
;---|*|---------------------====< mono_output >====-------------------------
;---|*|
;---|*| This routine is included only if DEBUG and MONOSCR are set TRUE.
;---|*| This code allows all calls the driver to be printed on the mono
;---|*| screen for debugging.
;---|*|
;   \*/

dbstr_table     label   word
	dw	offset dbg_msg0 	;  0 DigPlay
	dw	offset dbg_msg1 	;  1 Sound Status
	dw	offset dbg_msg2 	;  2 Massage Audio
	dw	offset dbg_msg3 	;  3 DigPlay2, pre-massaged audio.
	dw	offset dbg_msg4 	;  4 Report audio capabilities.
	dw	offset dbg_msg5 	;  5 Report playback address.
	dw	offset dbg_msg6 	;  6 Set Callback address.
	dw	offset dbg_msg7 	;  7 Stop Sound.
	dw	offset dbg_msg8 	;  8 Set Hardware addresses.
	dw	offset dbg_msg9 	;  9 Report Current callback address.
	dw	offset dbg_msga 	; 10 Restore hardware vectors.
	dw	offset dbg_msgb 	; 11 Set Timer Divisor Sharing Rate
	dw	offset dbg_msgc 	; 12 Play preformatted loop
	dw	offset dbg_msgd 	; 13 Post Pending Audio
	dw	offset dbg_msge 	; 14 Report Pending Status
	dw	offset dbg_msgf 	; 15 Set Stereo Panning value.
	dw	offset dbg_msg10	; 16 Set DigPak Play mode.
	dw	offset dbg_msg11	; 17 Report Address of pending status flag.
	dw	offset dbg_msg12	; 18 Set Recording mode 0 off 1 on.
	dw	offset dbg_msg13	; 19 StopNextLoop
	dw	offset dbg_msg14	; 20 Set DMA backfill mode.
	dw	offset dbg_msg15	; 21 Report current DMAC count.
	dw	offset dbg_msg16	; 22 Verify DMA block.
	dw	offset dbg_msg17	; 23 Set PCM volume.

dbg_msg0	db	'DigPlay     ',0
dbg_msg1	db	'Sound Stat  ',0
dbg_msg2	db	'MassageAudio',0
dbg_msg3	db	'DigPlay2    ',0
dbg_msg4	db	'Get Aud Cap ',0
dbg_msg5	db	'Get PB Addr ',0
dbg_msg6	db	'Set CB Addr ',0
dbg_msg7	db	'Stop Sound  ',0
dbg_msg8	db	'Set HW Addr ',0
dbg_msg9	db	'Get CB Addr ',0
dbg_msga	db	'Rst HW vect ',0
dbg_msgb	db	'Set TMR Div ',0
dbg_msgc	db	'Play loop   ',0
dbg_msgd	db	'PostPendAud ',0
dbg_msge	db	'Get Pnd Stat',0
dbg_msgf	db	'Set Pan val ',0
dbg_msg10	db	'Set Play mde',0
dbg_msg11	db	'Get flag add',0
dbg_msg12	db	'Set RCD mode',0
dbg_msg13	db	'StopNextLoop',0
dbg_msg14	db	'Set BACKF md',0
dbg_msg15	db	'Get DMAC cnt',0
dbg_msg16	db	'CHK DMA blk ',0
dbg_msg17	db	'Set PCM vol ',0

DBG_AX		equ	00000001b
DBG_BX		equ	00000010b
DBG_CX		equ	00000100b
DBG_DX		equ	00001000b
DBG_SI		equ	00010000b
DBG_DI		equ	00100000b
DBG_BP		equ	01000000b
DBG_ES		equ	10000000b

dbrstr_table    label   word
	dw	offset dbg_rax	; 0
	dw	offset dbg_rbx	; 1
	dw	offset dbg_rcx	; 2
	dw	offset dbg_rdx	; 3
	dw	offset dbg_rsi	; 4
	dw	offset dbg_rdi	; 5
	dw	offset dbg_rbp	; 6
	dw	offset dbg_res	; 7

dbg_rax 	db	'AX=',0
dbg_rbx 	db	'BX=',0
dbg_rcx 	db	'CX=',0
dbg_rdx 	db	'DX=',0
dbg_rsi 	db	'SI=',0
dbg_rdi 	db	'DI=',0
dbg_rbp 	db	'BP=',0
dbg_res 	db	'ES=',0

; PUSHA stack frame, plus ES & DS

regwset struc
 _regDS dw	?
 _regES dw	?
 _regDI dw	?
 _regSI dw	?
 _regBP dw	?
 _regSP dw	?
 _regBX dw	?
 _regDX dw	?
 _regCX dw	?
 _regAX dw	?
regwset ends

;
; mask indicating which registers to print on the screen
;

dbstr_regs      label   word
		dw	0				   ; DigPlay
		dw	0				   ; Sound Status
		dw	DBG_AX				   ; Massage Audio
		dw	DBG_AX+DBG_BX+DBG_CX+DBG_DX	   ; DigPlay2, pre-massaged audio.
		dw	DBG_AX				   ; Report audio capabilities.
		dw	DBG_AX				   ; Report playback address.
		dw	DBG_AX+DBG_BX+DBG_CX+DBG_DX+DBG_SI ; Set Callback address.
		dw	DBG_AX				   ; Stop Sound.
		dw	DBG_AX+DBG_BX+DBG_CX+DBG_DX+DBG_SI ; Set Hardware addresses.
		dw	DBG_AX				   ; Report Current callback address.
		dw	0				   ; Restore hardware vectors.
		dw	0				   ; Set Timer Divisor Sharing Rate
		dw	0				   ; Play preformatted loop
		dw	0				   ; Post Pending Audio
		dw	0				   ; Report Pending Status
		dw	0				   ; Set Stereo Panning value.
		dw	0				   ; Set DigPak Play mode.
		dw	0				   ; Report Address of pending status flag.
		dw	0				   ; Set Recording mode 0 off 1 on.
		dw	0				   ; StopNextLoop
		dw	0				   ; Set DMA backfill mode.
		dw	0				   ; Report current DMAC count.
		dw	0				   ; Verify DMA block.
		dw	0				   ; Set PCM volume.

;   /*\
;---|*|-----------------------====< reportmono >====---------------------------
;---|*|
;---|*| do the screen output
;---|*|
;   \*/

IFDEF 	DEBUG_MONO
VIDEOSEG	EQU	0B000h 
ELSE
VIDEOSEG        EQU     0B800h
ENDIF

Debugging       proc    near ; mono screen output
DBG_PARM1       equ     <bp.regwset._regAX+6>
	pushf
        pusha
	push	es
	push	ds
        mov     bp,sp
	shl	[DBG_PARM1],1		; double the number
        push    cs
        push    cs
	pop	ds
	pop	es
        mov     di, VIDEOSEG
	mov	es,di
	call	dbg_scroll		; scroll the screen 1 line
	mov	di,24*80*2		; point to the bottom of the screen
        mov     bx,[DBG_PARM1]
	mov	bx,dbstr_table[bx]
        call    dbg_strout              ; print the string
	mov	si,[DBG_PARM1]
	mov	si,dbstr_regs[si]
	sub	bx,bx
	test	si,DBG_AX
	jz	@F_01
	mov	ax,[bp.regwset._regAX]
	call	dbg_regreport
    @F_01:
	inc	bx
	test	si,DBG_BX
	jz	@F_02
	mov	ax,[bp.regwset._regBX]
	call	dbg_regreport
    @F_02:
	inc	bx
        test    si,DBG_CX
	jz	@F_03
	mov	ax,[bp.regwset._regCX]
	call	dbg_regreport
    @F_03:
	inc	bx
        test    si,DBG_DX
	jz	@F_04
	mov	ax,[bp.regwset._regDX]
	call	dbg_regreport
    @F_04:
	inc	bx
        test    si,DBG_SI
	jz	@F_05
	mov	ax,[bp.regwset._regSI]
	call	dbg_regreport
    @F_05:
	inc	bx
        test    si,DBG_DI
	jz	@F_06
	mov	ax,[bp.regwset._regDI]
	call	dbg_regreport
    @F_06:
	inc	bx
        test    si,DBG_BP
	jz	@F_07
	mov	ax,[bp.regwset._regBP]
	call	dbg_regreport
    @F_07:
	inc	bx
        test    si,DBG_ES
	jz	@F_08
	mov	ax,[bp.regwset._regES]
	call	dbg_regreport
    @F_08:
	pop	ds
	pop	es
	popa
	popf
        ret     2
Debugging	endp

dbg_regreport   proc   near
	push	bx
	shl	bx,1
        mov     bx,dbrstr_table[bx]     ; get the register string
	call	dbg_strout		; print the string
	push	ax			; save copies
        push    ax
	xchg	ah,al
	push	ax
	shr	al,4
	call	@dbg_nout		; print the 4th nibble
	pop	ax
	call	@dbg_nout		; print the 3rd nibble
	pop	ax
	shr	al,4
	call	@dbg_nout		; print the 2nd nibble
	pop	ax
	call	@dbg_nout		; print the 1st nibble
	add	di,2
        pop     bx
	ret
dbg_regreport	endp

@dbg_nout       proc   near
	push	ax
	and	al,0Fh
	add	al,90h
	daa
	adc	al,0
	add	al,40h
	daa
	mov	ah,0Fh
	stosw
	pop	ax
	ret
@dbg_nout	endp

dbg_scroll      proc   near
	push	ds
        push    cx
	push	si
	mov	si,80*2
	sub	di,di
	push	es
	pop	ds
	mov	cx,24*80
	cld
        rep movsw
	sub	ax,ax
	mov	di,24*80*2
	mov	cx,80
	rep stosw
	pop	si
	pop	cx
	pop	ds
        ret
dbg_scroll	endp

dbg_strout      proc  near
	push	ax
	push	bx
	mov	ah,0Fh
	cld
    @F_A1:
	mov	al,cs:[bx]
	inc	bx
	or	al,al
	jz	@F_A2
	stosw
	jmp short @F_A1
    @F_A2:
	pop	bx
	pop	ax
	ret
dbg_strout	endp
endif

SUICIDE LABEL	byte		;; Where to delete ourselves from memory

hard		db "VESA Wave Driver not found.",0Dh,0Ah,'$' 
msg0		db "VESA Wave Audio DIGPAK Driver"
		db " - Copyright (c) 1993, THE Audio Solution:v3.30",0Dh,0Ah,'$'
msg1		db "DIGPAK Sound Driver is already resident.",0Dh,0Ah,'$'
msg1a		db "DIGPAK Sound Driver is resident, through MIDPAK.",0Dh,0Ah,'$'
msg1b		db "A Sound Driver cannot be loaded on top of MIDPAK.  Unload MIDPAK first.",0Dh,0Ah,'$'
msg2		db "Unable to install Sound Driver interupt vector",0Dh,0Ah,'$'
msg3		db "Invalid command line",0Dh,0Ah,'$'
msg4		db "Sound Driver isn't in memory",0Dh,0Ah,'$'
msg5		db "DIGPAK Sound Driver unloaded",0Dh,0Ah,'$'
msg5a		db "Sound Driver can't be unloaded, unload MIDPAK first.",0Dh,0Ah,'$'
param		dw 4 dup(0)		;; Used for parameter passing.			
Installed	dw 0			
				
LoadSound	proc near		
	mov	ax, cs          	;                          
	mov	ds, ax                  ; establish data segment   
	mov	es, ax			; point ES to PSP
	call	CheckIn
	mov	Installed, ax		; Save in installed flag.  
	call	ParseCommandLine        ; Build a command line.    
	cmp	_argc, 0
	jz	short loc_16B4
	cmp	_argc, 1
	jnz	short loc_1670
	mov	bx, _argv
	mov	al, [bx]
	cmp	al, 75h
	jz	short loc_167D
	cmp	al, 55h
	jz	short loc_167D
loc_1670:				
	Message msg3			; Invalid command line
	DOSTerminate
loc_167D:						
	mov	ax, Installed
	or	ax, ax
	jnz	short loc_1691
	Message msg4			; wasn't loaded.
	DOSTerminate			; Terminate with message.
loc_1691:			
	cmp	ax, 2
	jnz	short loc_16A3
	Message msg5a
	DOSTerminate
loc_16A3:		
	CALLF	DeInstallInterupt
	Message msg5			; Display message
	DOSTerminate			; terminate
loc_16B4:				
	or	ax, ax
	jz	short loc_16EB
	cmp	ax, 2
	jnz	short loc_16CA
	Message msg1a
	DOSTerminate
loc_16CA:				
	cmp	ax, 3
	jnz	short loc_16DE
	jmp	short loc_16EB
	Message msg1b
	DOSTerminate
loc_16DE:				
	Message msg1			; message
	DOSTerminate			;
loc_16EB:		
	CALLF	InstallInterupt
	or	ax, ax         		; Was there an error?      
	jz	short loc_1709          ; no->continue             
	Message msg2			; display the error message
	Message hard			; Hardware error message if there is one.
	DOSTerminate			; exit to dos
loc_1709:	
;;; The Kernel is now installed.
;;; Announce the Kernel's presence.
	Message msg0
	DosTSR  SUICIDE         	; Terminate ourselves bud.
LoadSound	endp			
					
InstallInterupt	proc far	
	IN_TSR
	call	HardwareInit			; Initialize hardware.          
	or	ax, ax                  	; Error initializing hardware?  
	jnz	short loc_1742
	mov	param, KINT              	; The interupt kernel is going into.      
	mov	param+2, offset	SoundInterupt   ; offset of interupt routine              
	mov	param+4, cs                     ; Our code segment.                       
	PushEA	param			        ; push the address of the parameter list  
	call	InstallINT                      ; Install the interupt.                   
	add	sp, 2                           ; clean up stack                          
loc_1742:	
	OUT_TSR
	retf
InstallInterupt	endp

DeInstallInterupt proc far	
	IN_TSR
	mov	param, KINT		; Interupt requested to be unloaded.   
	PushEA	param                   ; pass parameter.                      
	call	UnLoad                  ; Unload it                            
	add	sp, 2                   ; clean up stack                       
	OUT_TSR
	retf
DeInstallInterupt endp

CheckIn	proc near		
	push	ds              	; Save ds register.                 
	push	si                                                          
	mov	si, 66h*4h              ; get vector number                 
	xor	ax, ax                  ; zero                              
	mov	ds, ax                  ; point it there                    
	lds	si, [si]                ; get address of interupt vector    
	or	si, si                  ; zero?                             
	jz	short loc_17AB          ; exit if zero                      
	sub	si, 6                   ; point back to identifier          
	cmp	word ptr [si], 'IM'  	; Midi driver?                     
	jnz	short loc_1798                                             
	cmp	word ptr [si+2], 'ID'   ; full midi driver identity string?
	jnz	short loc_1798
;; Ok, a MIDI driver is loaded at this address.
	mov	ax, 701h              	; Digitized Sound capabilities request.      
	int	66h		        ; Request.                                   
	or	ax, ax                  ; digitized sound driver available?          
	jnz	short loc_1793          ; yes, report that to the caller.            
	mov	ax, 3                   ; Not available, but mid pak is in!          
	jmp	short loc_17A8          ; exit with return code.                     
loc_1793:				                                            
	mov	ax, 2                   ; Sound driver resident, through MIDPAK.     
	jmp	short loc_17A8
loc_1798:				
	cmp	word ptr [si], 454Bh 	; equal?             
	jnz	short loc_17AB          ; exit if not equal  
	cmp	word ptr [si+2], 4E52h  ; equal?             
	jnz	short loc_17AB
	mov	ax, 1
loc_17A8:				
	pop	si
	pop	ds
	ret
loc_17AB:				
	xor	ax, ax			; Zero return code.
	jmp	short loc_17A8
CheckIn	endp
 	
;; Usage: IntallINT(&parms)
;; offset 0: interupt
;;        2: offset of interupt code
;;        4: segment of interupt code
InstallINT	CPROC MYDATA:WORD	
	PushCREGS
	mov	bx, [MYDATA]      	; Get address of parameter table        
	mov	ax, [bx]                ; get the interupt vector.              
	mov	di, ax                  ; save interupt vector into DI as well  
	mov	si, [bx+2]              ; get offset                            
	mov	ds, word ptr [bx+4]     ; get segment.                          
	mov	ah, 35h                 ; Get interupt vector                   
	int	21h	                ; Do DOS call to get vector.            
	mov	[si-0Ah], bx            ; Save the old offset.                  
	mov	word ptr [si-8], es     ; Save the old segment                  
	cld
	xor	ax, ax
	mov	es, ax
	ShiftL	di,2			;                
	mov	ax, si                  ; get offset.    
	cli                                              
	stosw                                            
	mov	ax, ds                  ; code segment   
	stosw                           ; store it.      
	sti                                              
	xor	ax, ax                  ; Success        
	PopCREGS
	nope 
	nope 
	ret
InstallINT	endp

;; Usage: UnLoad(&vector)
;; Returns: AX = 0 success
;           AX nonzero, couldn't unload interupt vector.
UnLoad 	CPROC MYDATA:WORD
	PushCREGS
	mov	ax, 68Fh		; Stop sound playback!          
	int	KINT                    ; Invoke interrupt.             
	WaitSound                                                       
	mov	ax, 692h                ; Deinstall hardware vectors.   
	int	KINT		
	mov	bx, [MYDATA]    	; get address of interupt vector       
	mov	bx, [bx]                ; get the interupt vector.             
	mov	dx, bx                  ; put it into DX as well               
	ShiftL	bx,2		        ;                                      
	xor	ax, ax                                                         
	mov	ds, ax                  ; Segment zero                         
	lds	si, [bx]                ; get address of interupt vector       
	or	si, si                  ; zero?                                
	jz	short loc_1845          ; exit if zero                         
	cmp	word ptr [si-2], 'RK'  	;'KR' Is this a kernel installed interupt?
	push	ds              	; save DS                         
	mov	ax, dx                  ; Get interupt vector.            
	mov	ah, 25h                 ; Do DOS 25h set interupt vector. 
	mov	dx, [si-0Ah]            ; get old offset                  
	mov	ds, word ptr [si-8]     ; get old segment                 
	int	21h			; set interupt vector.            		
	pop	ax                      ; get back segment of program.    
	mov	es, ax
	push	es
	mov	es, word ptr es:2Ch 	; Environment space.                 
	mov	ah, 49h                                                      
	int	21h			; Free it up.                        		
	pop	es                                                           
	mov	ah, 49h                 ; free memory.                       
	int	21h		        ; free up the memory used by us.     
loc_183D:				
	PopCREGS
	nope 
	nope 
	ret
loc_1845:				
	mov	ax, 1
	jmp	short loc_183D
UnLoad		endp

; This procedure parses the command line and builds an array of
; pointers to each argument.  Arguments are seperated by space's.
; these spaces get replaced by zero bytes.
_argc		dw 0			; The argument count       	
_argv		dw 10h dup( 0)		; Up to 16 arguments.      
command		db 80h dup(0)		

ParseCommandLine proc near		
	mov	_argc, 0
	cmp	byte ptr es:80h, 2
	jb	short locret_1934
	xor	cx, cx
	mov	cl, es:80h		; Get length.
	SwapSegs
	dec	cx              	; Less one
	mov	di, offset command
	mov	si, 82h
	rep movsb
	push	cs
	pop	ds
	mov	di, offset _argv	; Argument list.
	mov	si, offset command      ; Start address.
loc_1916:				
	inc	_argc               	; Increment argument counter.    
	mov	ax, si                  ; Base argument addres.          
	stosw                                                            
loc_191D:				
	lodsb				; Get characters until we hit space of eol
	cmp	al, 20h
	jnz	short loc_1928
	mov	byte ptr [si-1], 0	; Turn space into a zero byte.
	jmp	short loc_1916
loc_1928:				
	cmp	al, 0Dh
	jz	short loc_1930
	or	al, al
	jnz	short loc_191D		; Keep skipping to next arg.    
loc_1930:				
	mov	byte ptr [si-1], 0      ; Zero byte terminate last arg  
locret_1934:				
	ret
ParseCommandLine endp

;;************************************************************************
;; Unique harware init code.
;;************************************************************************
HardwareInit	proc near		
	xor	ax, ax			
	call	VesaPresent    		; Is there a card present?          
	test	ax, 4                   ; Access to digitized sound?        
	jnz	short loc_1944          ; Yes->continue.                    
	mov	ax, 1                                                        
	jmp	short locret_1947                                            
loc_1944:				
	call	VesaInit          	; Detect if it's okay to play.                                                
locret_1947:				
	ret
HardwareInit	endp

	db 8 dup(0)			;padding

	end start
