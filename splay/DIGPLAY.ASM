;; DIGPLAY.ASM			August 15, 1991, John W. Ratciff
;;
;; This piece of source provides C procedure call hooks down into
;; the resident TSR sound driver.  Use the call CheckIn to find out
;; if the sound driver is in memory.  See the C header file DIGPLAY.H
;; for prototype information.
;;
;; This file is in the format for Turbo Assembler's IDEAL mode.  The
;; IDEAL mode syntax makes a lot more sense for 8086 than the old
;; MASM format.  MASM has recently been updated to provide some of the
;; functions that Turbo Assembler has had for a number of years.  I prefer
;; to consider Turbo Assembler the standard for 8086 assemblers.
;; IDEAL mode functionality includes true local labels, real data structures,
;; typecasting, automatic argument passing and local memory.
;; Converting any of this code into MASM format is an excercise left for
;; the student.

;;
;; The MIT license:
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is furnished
;; to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;

IFNDEF	LOADABLE_DRIVERS		; If not already defined.
LOADABLE_DRIVERS	equ	1	; Set true to enable
ENDIF
	; Driver load and unload calls.  Requires that the application provide
	; memory allocation functions and access to DOSCALLS.OBJ.

	.xlist
        INCLUDE PROLOGUE.MAC          		;; common prologue
	.list

	.MODEL LARGE, C
	.CODE 
;	ASSUME	DS: _TEXT, ES: NOTHING

IF	LOADABLE_DRIVERS
;; These external procedures are required for the Load and Unload sound
;; driver calls.  The need access to memory allocation functions.
;; The application must provide memory allocation through the functions
;; memfree and memalloc.  The user may redirect these either through DOSCALLS
;; which uses the standard DOS memory allocate, or through their C compiler's
;; memory allocation functions.
	extrn	memfree:far	 ; Application controlled memory allocation.
	extrn	memalloc:far	; Application controlled memory allocation.
	extrn	floadpara:far	    ; File load procedure, found in DOSCALLS!
ENDIF

        	
IF @CodeSize
CPROC equ	<Proc far  C>
ELSE
CPROC equ	<Proc near C>
ENDIF
;; 1 if declaring C procedures as far, so that you can link any memory model to theme. 
;; They are prototyped as well in DIGPLAY.H header file.

;;	int  DigPlay(SNDSTRUC far *sndplay);	     // 688h -> Play 8 bit digitized sound.
DigPlay	CPROC USES DS SI MYDATA:DWORD
	call	CheckInLocal    ; Is sound driver in memory?
	or	ax,ax		; no-> don't invoke interupt...
	jz	@@EXT		;
	mov	ax,0688h	; Function #1, DigPlay
	lds	si,[MYDATA]	; Data structure.
	int	66h		; Do sound interupt.
	mov	ax,1		; Return sound played.
@@EXT:
	ret
DigPlay	endp

;;	int  SoundStatus(void); 					 // 689h -> Report sound driver status.
SoundStatus	CPROC
	mov	ax,0689h	; Check sound status.
	int	66h		; Sound driver interrupt.
	ret
SoundStatus	endp

;;	void MassageAudio(SNDSTRUC far *sndplay);// 68Ah -> Preformat 8 bit digitized sound.
MassageAudio	CPROC USES DS SI MYDATA:DWORD
	mov	ax,068Ah	; Identity
	lds	si,[MYDATA]	; Data structure.
	int	66h		; Do sound interupt.
	ret
MassageAudio	endp

;;	int  DigPlay2(SNDSTRUC far *sndplay);  // 68Bh -> Play preformatted data.
DigPlay2	CPROC USES DS SI MYDATA:DWORD
	mov	ax,068Bh	; Identity
	lds	si,[MYDATA]	; Data structure.
	int	66h		; Do sound interupt.
	ret
DigPlay2	endp

;;	int  DigPlayLoop(SNDSTRUC far *sndplay);  // 6894 -> Play preformatted data.
DigPlayLoop	CPROC USES DS SI MYDATA:DWORD
	mov	ax,0694h	; Identity
	lds	si,[MYDATA]	; Data structure.
	int	66h		; Do sound interupt.
	ret
DigPlayLoop	endp

;;	int  AudioCapabilities(void);		 // 68Ch -> Report audio driver capabilities.
AudioCapabilities CPROC
	mov	ax,068Ch	; Check sound status.
	int	66h
	ret
AudioCapabilities endp

;;int  far DigPakIdentityString(char far *str);
;; 68Ch -> reports ID string of resident driver.
;; returns length of string.
DigPakIdentityString CPROC string:DWORD
	PushCREGS
	mov	ax,68Ch
	int	66h
	les	di,[string]
	mov	ds,bx
	mov	si,cx
	mov	cx,-1
@@MV:	lodsb
	stosb
	inc	cx
	or	al,al
	jnz	@@MV
	mov	ax,cx		; Return string length.
	PopCREGS
	ret
DigPakIdentityString endp

;;	int  ReportSample(void);					 // 68Dh -> Report current sample address.
ReportSample	CPROC
	mov	ax,068Dh	; Report audio sample.
	int	66h
	ret
ReportSample	endp

;; void SetCallBackAddress(void far *proc); // 68Eh -> Set procedure callback address.
SetCallBackAddress CPROC COFF:WORD,CSEG:WORD
	mov	bx,[COFF]
	mov	dx,[CSEG]
	mov	ax,68Eh
	int	66h
	ret
SetCallBackAddress endp

;; void StopSound(void);    // 68Fh -> Stop current sound from playing.
StopSound	CPROC
	mov	ax,68Fh
	int	66h
	ret
StopSound	endp

SetAudioHardware CPROC IRQ:WORD,BASEADR:WORD,OTHER:WORD
	mov	ax,690h
	mov	bx,[IRQ]
	mov	cx,[BASEADR]
	mov	dx,[OTHER]
	int	66h
	ret
SetAudioHardware endp

ReportCallbackAddress CPROC
	mov	ax,691h
	int	66h
	ret
ReportCallbackAddress endp

WaitSound	CPROC
@@WS:	mov	ax,689h
	int	66h
	or	ax,ax
	jnz	@@WS
	ret
WaitSound	endp

PostAudioPending CPROC USES DS SI SOUND:DWORD
	lds	si,[SOUND]
	mov	ax,0695h
	int	66h
	ret
PostAudioPending endp

AudioPendingStatus CPROC
	mov	ax,696h
	int	66h
	ret
AudioPendingStatus endp

SetStereoPan	CPROC PAN:WORD
	mov	dx,[PAN]
	mov	ax,697h
	int	66h
	ret
SetStereoPan	endp

SetPlayMode	CPROC MODE:WORD
	mov	dx,[MODE]
	mov	ax,698h
	int	66h
	ret
SetPlayMode	endp

ReportPendingAddress CPROC
	mov	ax,699h
	int	66h
	ret
ReportPendingAddress endp

ReportSemaphoreAddress CPROC
	mov	ax,699h
	int	66h
	mov	ax,bx		; Move semaphore address into AX
	ret
ReportSemaphoreAddress endp

ReportVersionNumber CPROC
	xor	bx,bx		; Default version number.
	mov	ax,0689h	; Get version number/status call.
	int	66h
	mov	ax,bx		; Return version number.
	ret
ReportVersionNumber endp

StopNextLoop	CPROC
	mov	ax,69Bh
	int	66h
	ret
StopNextLoop	endp

SetTimerDivisorRate CPROC RATE:WORD
	mov	ax,693h
	mov	dx,[RATE]
	int	66h
	ret
SetTimerDivisorRate endp

SetRecordMode	CPROC MODE:WORD
	mov	dx,[MODE]
	mov	ax,69Ah
	int	66h
	ret
SetRecordMode	endp

SetBackFillMode	CPROC MODE:WORD
	mov	dx,[MODE]
	mov	ax,69Ch
	int	66h
	ret
SetBackFillMode	endp

ReportDMAC	CPROC
	mov	ax,69Dh
	int	66h
	ret
ReportDMAC	endp


NullSound	CPROC SOUND:DWORD,SNDLEN:WORD
	PushCREGS
	les	di,[SOUND]
	mov	al,80h
	mov	cx,[SNDLEN]
	rep	stosb
	PopCREGS
	ret
NullSound	endp

VerifyDMA	CPROC USES ES SDATA:DWORD,SLEN:WORD
	les	bx,[SDATA]
	mov	cx,[SLEN]
	mov	ax,69Eh
	int	66h
	ret
VerifyDMA	endp

SetPCMVolume	CPROC LEFT:WORD,RIGHT:WORD
	mov	ax,69Fh
	mov	bx,[LEFT]
	mov	cx,[RIGHT]
	int	66h
	ret
SetPCMVolume	endp

;;	int  CheckIn(void);							 // Is sound driver available?
CheckIn	CPROC
	call	CheckInLocal
	ret
CheckIn	endp

CheckInLocal proc	near
	push	ds		; Save ds register.
	push	si

	mov	si,66h*4h	; get vector number
        xor     ax,ax           ; zero
        mov     ds,ax           ; point it there
	lds	si,[si]	        ; get address of interupt vector
        or      si,si           ; zero?
        jz      @@CIOUT         ; exit if zero
        sub     si,6            ; point back to identifier

	cmp	word ptr [si],'IM'  ; Midi driver?
	jne	@@NEX
	cmp	word ptr [si+2],'ID'  ; full midi driver identity string?
	jne	@@NEX
;; Ok, a MIDI driver is loaded at this address.
	mov	ax,701h 	; Digitized Sound capabilities request.
	int	66h		; Request.
	or	ax,ax		; digitized sound driver available?
	jnz	@@OK		; yes, report that to the caller.
	jz	@@CIOUT 	; exit, sound driver not available.
@@NEX:
	cmp	word ptr [si],454Bh ; equal?
        jne     @@CIOUT         ; exit if not equal
	cmp	word ptr [si+2],4E52h    ; equal?
        jne     @@CIOUT
@@OK:	mov	ax,1
@@EXT:
	pop	si
	pop	ds
	ret
@@CIOUT: xor	ax,ax		; Zero return code.
	jmp short @@EXT
CheckInLocal	endp

IF	LOADABLE_DRIVERS
;; Local data area for calling into a loadable sound driver.
LoadAddress	dw	0,0	; Allocate memory load address.
LoadSeg dw	0	; Segment driver was loaded into.
InstallDriver	LABEL	DWORD
InstOff dw	0200h	; Offset of first jump.
InstSeg dw	?	; Segment of audio driver.
DeInstallDriver LABEL	DWORD
DeInstOff dw	0203h	; Offset of deinstall jump
DeInstSeg dw	?	; Segment of audio driver.

;;int  LoadSoundDriver(char *name);  // Load a sound driver by filename, 1 success 0 fail.
LoadSoundDriver	CPROC FNAME:DWORD
	PushCREGS
	push	cs		; Code segment
	PushEA	LoadSeg 	; Segment portion of load address.
	xor	ax,ax
	push	ax
	push	ax		; Don't care about the size, pass zero.
	les	dx,[FNAME]
	push	es
	push	dx
	call	floadpara	; Load file on paragraph boundary.
	add	sp,12		; Balance stack.
	or	dx,dx		; Able to load the file?
	jz	@@EXT
	mov	[cs:LoadAddress],ax
	mov	[cs:LoadAddress+2],dx
	mov	ax,[cs:LoadSeg] ; Save segment loaded at.
	mov	es,ax		; Into ES
	sub	ax,10h		; Less 10 paragraphs for the org 100h
;; Check Identity string 'DIGPAK' if not located starting 3 bytes into
;; the file loaded, then this is not a compatible digitized sound driver.
	cmp	byte ptr [es:3],'D' ; D in DIGPAK?
	jne	@@FREE
	cmp	byte ptr [es:4],'I' ; I in DIGPAK?
	jne	@@FREE
	cmp	byte ptr [es:5],'G' ; G in DIGPAK?
	jne	@@FREE
	cmp	byte ptr [es:6],'P' ; P in DIGPAK?
	jne	@@FREE
	cmp	byte ptr [es:7],'A' ; A in DIGPAK?
	jne	@@FREE
	cmp	byte ptr [es:8],'K' ; K in DIGPAK?
	jne	@@FREE
	mov	[cs:InstSeg],ax
	mov	[cs:DeInstSeg],ax
	call	[cs:InstallDriver]	; Install the driver.
	or	ax,ax		; Installed ok?
	jz	@@OK1
@@FREE:
	push	[cs:LoadSeg]
	xor	ax,ax
	push	ax
	call	memfree
	add	sp,4
	xor	ax,ax
	mov	[cs:LoadSeg],ax
	jmp	short @@EXT	; Exit with error.
@@OK1:	mov	ax,1		; Success!
@@EXT:
	PopCREGS
	ret
LoadSoundDriver	endp

UnloadSoundDriver	CPROC
	cmp	[cs:LoadSeg],0	   ; Ever load a sound driver?
	je	@@NOT		; no, leave.
	call	[cs:DeInstallDriver]	   ; Do indirect call to deinstall the driver.
	push	[cs:LoadAddress+2]
	push	[cs:LoadAddress]
	call	memfree		; free up the memory.
	add	sp,4
	mov	[cs:LoadSeg],0	; Zero load seg out.
@@NOT:
	ret
UnloadSoundDriver	endp
ENDIF

	end
