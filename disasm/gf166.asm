
		.model tiny, C

VERSION_NUMBER	equ	320

	INCLUDE COMPAT.INC
        INCLUDE PROLOGUE.MAC          ;; common prologue
	INCLUDE SOUNDRV.INC

CPROC 	equ	<Proc near C>

		.code
		assume es:nothing, ss:nothing;, ds:nothing
		org 100h

start:
		jmp	LoadSound

aDIGPAK		db 'DIGPAK',0,0Dh,0Ah		
IDENTIFIER	db 'Advanced Gravis UltraSound',0,0Dh,0Ah
		db 'The Audio Solution, Copyright (c) 1993',0,0Dh,0Ah
		db 'Written by John W. Ratcliff',0,0Dh,0Ah,0

		org 200h
		jmp	near ptr InstallInterupt
		jmp	near ptr DeInstallInterupt
DUMMYBASE	dw -1
DUMMYIRQ	dw -1
DUMMYEXTRA	dw -1

JumpTable	dw offset FUNCT1	
		dw offset FUNCT2
		dw offset FUNCT3
		dw offset FUNCT4
		dw offset FUNCT5
		dw offset FUNCT6
		dw offset FUNCT7
		dw offset FUNCT8
		dw offset FUNCT9
		dw offset FUNCTA
		dw offset FUNCTB
		dw offset FUNCTC
		dw offset FUNCTD
		dw offset FUNCTE
		dw offset FUNCTF
		dw offset FUNCT10
		dw offset FUNCT11
		dw offset FUNCT12
		dw offset FUNCT13
		dw offset FUNCT14
		dw offset FUNCT15
		dw offset FUNCT16
		dw offset FUNCT17
		dw offset FUNCT18
JumpPtr		dw 0			
					
ultramid_buffer	db 800h	dup(0)		
		include VOL.INC

um_sound_struct	struc 
  um_sound_data		dd ?
  um_stereo_mem		dd ?
  um_sound_len		dd ?
  um_gf1mem		dd ?
  um_pan		db ?
  um_volume		dw ?
  um_sample_rate	dw ?
  um_priority		dw ?
  um_data_type		db ?
  um_callback_addr 	dd ?
um_sound_struct	ends
;um_sound_length	equ  0x1C

GUSSound	um_sound_struct	<>	
					
GUS_voice	dw 0			
GUS_sound_data_seg dw 0			
					
aUltramid	db 'ULTRAMID',0         
ultramid_intr	dd 0			
_voice_status	dw 0			
					
CallBacks	dw 0			
CallLow		dw 0			
					
CallHigh	dw 0			
CallDS		dw 0			
DivisorRate	dw 0			
PlayMode	dw 0			
					
INDIGPAK	dw 0			

KJUMP		FARPTR	<>		; Address
OLDIN		FARPTR	<>		; Original interupt vector.
					
ID 		db 'KERN'
IND		db  'KR'

SoundInterupt	proc far		
	cmp	ax, 688h
	jb	short loc_BB1
	cmp	ax, 69Fh
	ja	short loc_BB1
	SetSemaphore
	sti
	sub	ax, 688h
	shl	ax, 1
	add	ax, offset JumpTable
	xchg	ax, bx
	mov	bx, cs:[bx]
	xchg	ax, bx
	mov	cs:JumpPtr, ax
	jmp	cs:JumpPtr
loc_BB1:				
	cmp	word ptr OLDIN.XPTR.POFF, 0
	jnz	short loc_BBF
	cmp	word ptr OLDIN.XPTR.PSEG, 0
	jz	short loc_BC4

loc_BBF:				
	jmp	cs:OLDIN.DPTR
loc_BC4:				
	ClearSemaphoreIRET
SoundInterupt	endp

FUNCT1:					
	PushCREGS
	call	CompleteSound
	call	SetAudio
	call	PlaySound
	PopCREGS
	ClearSemaphoreIRET

FUNCT2:					
	mov	bx,VERSION_NUMBER
	cmp	cs:LOOPING, 1
	jnz	short loc_BFF
	mov	ax, 1
	mov	dx, 1
	ClearSemaphoreIRET
loc_BFF:				
	mov	ax, cs:_voice_status
	xor	dx, dx
	ClearSemaphoreIRET

FUNCT3:					
	ClearSemaphoreIRET

FUNCT4:					
	PushCREGS
	call	CompleteSound
	call	DoSoundPlay
	PopCREGS
	ClearSemaphoreIRET                   
	                                     
FUNCT5:					     
	mov	ax, PCM16STEREO OR PCM16 OR STEREOPLAY OR STEREOPAN OR LOOPEND OR PLAYBACK  ;0CE1H
	mov	bx, cs
	mov	cx, offset IDENTIFIER
	ClearSemaphoreIRET

FUNCT6:					
	mov	ax, 8
	call	cs:ultramid_intr
	sub	ax, cs:GUS_sound_data_seg
	shl	ax, 1
	shl	ax, 1
	add	ax, dx
	ClearSemaphoreIRET

FUNCT7:					
	or	bx, bx
	jnz	short loc_C6F
	or	dx, dx
	jnz	short loc_C6F
	xor	ax, ax
	mov	cs:CallBacks, ax
	mov	cs:CallLow, ax
	mov	cs:CallHigh, ax
	jmp	short loc_C85
loc_C6F:				
	mov	cs:CallLow, bx
	mov	cs:CallHigh, dx
	mov	cs:CallDS, ds
	mov	cs:CallBacks, 1
loc_C85:				
	ClearSemaphoreIRET

FUNCT8:					
	mov	cs:PENDING, 0
	mov	cs:LOOPING, 0
	call	ctv_uninstall
	ClearSemaphoreIRET

FUNCT9:					
	ClearSemaphoreIRET

FUNCTA:					
	mov	ax, cs:CallLow
	mov	dx, cs:CallHigh
	mov	bx, cs:CallDS
	ClearSemaphoreIRET

FUNCTB:					
	mov	cs:CallBacks, 0
	mov	cs:CallLow, 0
	mov	cs:CallHigh, 0
	mov	cs:PENDING, 0
	mov	cs:LOOPING, 0
	call	ctv_uninstall
	mov	ax, 14h
	mov	dx, word ptr cs:GUSSound.um_gf1mem
	mov	bx, word ptr cs:GUSSound.um_gf1mem+2
	call	cs:ultramid_intr
	mov	ax, 19h
	mov	bx, cs
	mov	dx, offset INDIGPAK
	call	cs:ultramid_intr
	mov	ax, 1Bh
	call	cs:ultramid_intr
	ClearSemaphoreIRET

FUNCTC:					
	mov	cs:DivisorRate,	dx
	ClearSemaphoreIRET

FUNCTD:					
	PushCREGS
	push	cs
	pop	es
	mov	di, offset LOOPSND
	mov	cx, 0Ch
	rep movsb
	mov	ax, 68Fh
	int	66h		
	mov	cs:LOOPING, 1
	push	cs
	pop	ds
	mov	si, offset LOOPSND
	mov	ax, 68Bh
	PopCREGS
	jmp	FUNCT4

FUNCTE:		
	PushCREGS			
	cli
	mov	ax, cs:_voice_status
	or	ax, ax
	jnz	short loc_D70
	sti
	call	DoSoundPlay
	xor	ax, ax
	PopCREGS
	ClearSemaphoreIRET
loc_D70:				
	cmp	cs:PENDING, 1
	jnz	short loc_D87
	mov	ax, 2
	PopCREGS
	ClearSemaphoreIRET
loc_D87:				
	mov	cs:PENDING, 1
	push	cs
	pop	es
	mov	di, offset PENDSND
	mov	cx, 0Ch
	rep movsb
	mov	cs:PENDING, 1
	mov	ax, 1
	PopCREGS
	ClearSemaphoreIRET

FUNCTF:					
	cli
	mov	ax, cs:_voice_status
	or	ax, ax
	jnz	short loc_DBF
	ClearSemaphoreIRET
loc_DBF:				
	cmp	cs:PENDING, 1
	jz	short loc_DD2
	mov	ax, 2
	ClearSemaphoreIRET
loc_DD2:				
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT10:				
	mov	ax, 7Fh
	sub	ax, dx
	mov	cl, 3
	shr	ax, cl
	mov	cs:GUSSound.um_pan, al
	cmp	cs:GUS_voice, 0
	jz	short loc_E00
	mov	ax, 2
	mov	cx, cs:GUS_voice
	dec	cx
	call	cs:ultramid_intr
loc_E00:				
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT11:				
	mov	cs:PlayMode, dx
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT12:				
	mov	dx, cs
	mov	ax, offset PENDING
	mov	bx, offset INDIGPAK
	ClearSemaphoreIRET

FUNCT13:				
	mov	ax, 0
	ClearSemaphoreIRET

FUNCT14:				
	mov	cs:CallBacks, 0
	mov	cs:LOOPING, 0
	ClearSemaphoreIRET

FUNCT15:				
	xor	ax, ax
	ClearSemaphoreIRET

FUNCT16:				
	ClearSemaphoreIRET

FUNCT17:				
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT18:				
	shl	bx, 1
	mov	ax, cs:gf1_volumes[bx]
	mov	cs:GUSSound.um_volume, ax
	cmp	cs:GUS_voice, 0
	jz	short loc_E8C
	mov	bx, ax
	mov	ax, 3
	mov	cx, cs:GUS_voice
	dec	cx
	call	cs:ultramid_intr
loc_E8C:				
	mov	ax, 1
	ClearSemaphoreIRET

; Attributes: bp-based frame

ultramid_handler PROC FAR C USES DS SI DI reason:WORD,voice:WORD,buff:FAR PTR,buff_len:FAR PTR,bufrate:FAR PTR
	push	cs
	pop	ds
	cmp	reason, 0
	jnz	short loc_EA8
	jmp	loc_F3E
loc_EA8:				
	cmp	reason, 1
	jz	short loc_EBA
	cmp	reason, 2
	jnz	short loc_EB7
	jmp	loc_F3C
loc_EB7:				
	jmp	loc_F53
loc_EBA:				
	cmp	cs:LOOPING, 0
	jnz	short loc_ECD
	cmp	cs:PENDING, 1
	jz	short loc_F01
	jmp	loc_F53
loc_ECD:				
	les	di, buff
	lds	si, cs:LOOPSND.PLAYADR
	mov	cs:GUS_sound_data_seg, ds
	mov	es:[di], si
	mov	word ptr es:[di+2], ds
	les	di, buff_len
	mov	cx, cs:LOOPSND.PLAYLEN
	mov	es:[di], cx
	mov	word ptr es:[di+2], 0
	les	di, bufrate
	mov	ax, cs:LOOPSND.FREQUENCY
	mov	es:[di], ax
	mov	ax, 1
	jmp	short loc_F56
loc_F01:				
	mov	cs:PENDING, 0
	les	di, buff
	lds	si, cs:PENDSND.PLAYADR
	mov	cs:GUS_sound_data_seg, ds
	mov	es:[di], si
	mov	word ptr es:[di+2], ds
	les	di, buff_len
	mov	cx, cs:PENDSND.PLAYLEN
	mov	es:[di], cx
	mov	word ptr es:[di+2], 0
	les	di, bufrate
	mov	ax, cs:PENDSND.FREQUENCY
	mov	es:[di], ax
	mov	ax, 1
	jmp	short loc_F56
loc_F3C:				
	jmp	short loc_F53
loc_F3E:				
	mov	cs:GUS_voice, 0
	mov	cs:_voice_status, 0
	mov	cs:LOOPING, 0
loc_F53:				
	mov	ax, 0
loc_F56:				
	ret
ultramid_handler endp

DoSoundPlay	proc near		
	PushCREGS
	call	SetAudio
	call	PlaySound
	PopCREGS
	retn
DoSoundPlay	endp

CheckCallBack	proc near		
	cmp	cs:CallBacks, 0
	jz	short locret_F8F
	PushAll
	mov	ds, cs:CallDS
	call	dword ptr cs:CallLow
	PopAll
locret_F8F:			
	retn
CheckCallBack	endp

SAVECALLBACK	dd    0
SAVECALLDS	dW    0

LOOPING		dw 0			
LOOPSND		SOUNDSPEC <>		

PENDING		dw 0			
PENDSND		SOUNDSPEC <>		
					
SetAudio	proc near		
	mov	[si.SOUNDSPEC.ISPLAYING.XPTR.POFF], offset _voice_status
	mov	[si.SOUNDSPEC.ISPLAYING.XPTR.PSEG], cs
	les	bx, [si.SOUNDSPEC.PLAYADR]
	mov	cx, [si.SOUNDSPEC.PLAYLEN]
	mov	dx, [si.SOUNDSPEC.FREQUENCY]
	push	cs
	pop	ds
	retn
SetAudio	endp

EndLoop		proc near		
	mov	cs:CallBacks, 0
	mov	cs:CallLow, 0
	mov	cs:CallHigh, 0
	mov	cs:LOOPING, 0
	call	ctv_uninstall
	retn
EndLoop		endp

CompleteSound	proc near		
	cmp	cs:LOOPING, 1
	jnz	short loc_FF0
	call	EndLoop
loc_FF0:				
	cmp	cs:_voice_status, 0
	jnz	short loc_FF0
	retn
CompleteSound	endp

		dd    0
StereoMono	db 0FFh

PlaySound	proc near		
	mov	al, 0
	test	PlayMode, PCM_8_STEREO
	jz	short loc_100A
	or	al, 8
loc_100A:				
	test	PlayMode, PCM_16_MONO 
	jnz	short loc_1014
	or	al, 5
loc_1014:				
	mov	cs:GUSSound.um_data_type, al
	mov	cs:GUSSound.um_sample_rate, dx
	mov	word ptr cs:GUSSound.um_sound_data+2, es
	mov	cs:GUS_sound_data_seg, es
	mov	word ptr cs:GUSSound.um_sound_data, bx
	mov	word ptr cs:GUSSound.um_sound_len, cx
	mov	word ptr cs:GUSSound.um_sound_len+2, 0
	mov	cs:GUSSound.um_priority, 0
	mov	ax, cs
	mov	es, ax
	mov	di, offset GUSSound
	mov	ax, 0
	call	cs:ultramid_intr
	add	ax, 1
	mov	cs:GUS_voice, ax
	jz	short locret_105E
	mov	cs:_voice_status, 1
locret_105E:		
	retn
PlaySound	endp

ctv_uninstall	proc near		
	push	ds
	push	cs
	pop	ds
	mov	ax, 1
	cmp	cs:_voice_status, 0
	jz	short loc_1080
	mov	cx, cs:GUS_voice
	dec	cx
	mov	ax, 7
	call	cs:ultramid_intr
	call	CheckCallBack
	sub	ax, ax
loc_1080:	
	pop	ds
	retn
ctv_uninstall	endp

DoCallBacks	proc near
	cmp	cs:CallBacks, 0
	jz	short locret_10A6
	PushAll
	mov	ds, cs:CallDS
	call	dword ptr cs:CallLow
	PopAll
locret_10A6:	
	retn
DoCallBacks	endp

SUICIDE LABEL	byte		;; Where to delete ourselves from memory

hard		db "UltraMID TSR not detected.",0Dh,0Ah,'$' 
msg0		db "UltraSound DIGPAK Sound Driver - Copyright (c) 1992, THE Audio Solution:v3.2",0Dh,0Ah,'$'
msg1		db "The Sound Driver is already resident.",0Dh,0Ah,'$'
msg1a		db "The Sound Driver is resident, through MIDPAK.",0Dh,0Ah,'$'
msg1b		db "A Sound Driver cannot be loaded on top of MIDPAK.  Unload MIDPAK first.",0Dh,0Ah,'$'
msg2		db "Unable to install Sound Driver interrupt vector",0Dh,0Ah,'$'
msg2a		db "UltraSound card out of memory.  Load digpak before midi,",0Dh,0Ah
		db "or use -c option with UltraMID",0Dh,0Ah,'$'
msg3		db "Invalid command line",0Dh,0Ah,'$'
msg4		db "Sound Driver isn't in memory",0Dh,0Ah,'$'
msg5		db "Sound Driver unloaded",0Dh,0Ah,'$'
msg5a		db "Sound Driver can't be unloaded, unload MIDPAK first.",0Dh,0Ah,'$'
param		dw 4 dup( 0)		
					
Installed	dw 0			
					
LoadSound	proc near				
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	call	CheckIn
	mov	Installed, ax
	call	ParseCommandLine
	cmp	_argc, 0
	jz	short loc_1340
	cmp	_argc, 1
	jnz	short loc_12FC
	mov	bx, _argv
	mov	al, [bx]
	cmp	al, 'u'
	jz	short loc_1309
	cmp	al, 'U'
	jz	short loc_1309
loc_12FC:				
	Message msg3			
	DOSTerminate
loc_1309:				
	mov	ax, Installed
	or	ax, ax
	jnz	short loc_131D
	Message msg4			
	DOSTerminate			
loc_131D:				
	cmp	ax, 2
	jnz	short loc_132F
	Message msg5a
	DOSTerminate
loc_132F:				
	CALLF	DeInstallInterupt
	Message msg5			
	DOSTerminate			
loc_1340:				
	or	ax, ax
	jz	short loc_1377
	cmp	ax, 2
	jnz	short loc_1356
	Message msg1a
	DOSTerminate
loc_1356:				
	cmp	ax, 3
	jnz	short loc_136A
	jmp	short loc_1377
	Message msg1b
	DOSTerminate
loc_136A:				
	Message msg1			
	DOSTerminate			
loc_1377:				
	CALLF	InstallInterupt
	or	ax, ax
	jz	short loc_13A3
	cmp	ax, 2
	jnz	short loc_138D
	Message msg2a			
loc_138D:				
	Message msg2			
	Message hard			
	DOSTerminate			
loc_13A3:				
;;; The Kernel is now installed.
;;; Announce the Kernel's presence.
	Message msg0
	DosTSR  SUICIDE         	
LoadSound endp

InstallInterupt	proc far		
	IN_TSR
	call	HardwareInit
	or	ax, ax
	jnz	short loc_13DC
	mov	param, 66h
	mov	param+2, offset	SoundInterupt
	mov	param+4, cs
	PushEA	param
	call	InstallINT
	add	sp, 2
loc_13DC:				
	OUT_TSR
	retf
InstallInterupt	endp

DeInstallInterupt proc far		
	IN_TSR
	mov	param, 66h
	PushEA	param
	call	UnLoad
	add	sp, 2
	OUT_TSR
	retf
DeInstallInterupt endp

CheckIn		proc near		
	push	ds
	push	si
	mov	si, 66h*4h
	xor	ax, ax
	mov	ds, ax
	lds	si, [si]
	or	si, si
	jz	short loc_1445
	sub	si, 6
	cmp	word ptr [si], 'IM'
	jnz	short loc_1432
	cmp	word ptr [si+2], 'ID'
	jnz	short loc_1432
	mov	ax, 701h
	int	66h		
	or	ax, ax
	jnz	short loc_142D
	mov	ax, 3
	jmp	short loc_1442
loc_142D:				
	mov	ax, 2
	jmp	short loc_1442
loc_1432:				
	cmp	word ptr [si], 'EK'
	jnz	short loc_1445
	cmp	word ptr [si+2], 'NR'
	jnz	short loc_1445
	mov	ax, 1
loc_1442:				
	pop	si
	pop	ds
	retn
loc_1445:				
	xor	ax, ax
	jmp	short loc_1442
CheckIn		endp


InstallINT	CPROC MYDATA:WORD	
	PushCREGS
	mov	bx, MYDATA
	mov	ax, [bx]
	mov	di, ax
	mov	si, [bx+2]
	mov	ds, word ptr [bx+4]
	mov	ah, 35h
	int	21h			; DOS -	2+ - GET INTERRUPT VECTOR
	mov	[si-0Ah], bx
	mov	word ptr [si-8], es
	cld
	xor	ax, ax
	mov	es, ax
	ShiftL	di,2			                
	mov	ax, si
	cli
	stosw
	mov	ax, ds
	stosw
	sti
	xor	ax, ax
	PopCREGS
	nop ;
	nop ;
	ret
InstallINT	endp

UnLoad 	CPROC MYDATA:WORD
	PushCREGS
	mov	ax, 68Fh
	int	KINT			
	WaitSound
	mov	ax, 692h
	int	KINT		
	mov	bx, MYDATA
	mov	bx, [bx]
	mov	dx, bx
	ShiftL	bx,2		        ;                                      
	xor	ax, ax
	mov	ds, ax
	lds	si, [bx]
	or	si, si
	jz	short loc_14DF
	cmp	word ptr [si-2], 'RK'
	push	ds
	mov	ax, dx
	mov	ah, 25h
	mov	dx, [si-0Ah]
	mov	ds, word ptr [si-8]
	int	21h		; DOS -	SET INTERRUPT VECTOR
	pop	ax
	mov	es, ax
	push	es
	mov	es, word ptr es:2Ch
	mov	ah, 49h
	int	21h		; DOS -	2+ - FREE MEMORY
				; ES = segment address of area to be freed
	pop	es
	mov	ah, 49h
	int	21h		; DOS -	2+ - FREE MEMORY
				; ES = segment address of area to be freed
loc_14D7:				
	PopCREGS
	nop ;
	nop ;
	ret
loc_14DF:				
	mov	ax, 1
	jmp	short loc_14D7
UnLoad		endp

_argc		dw 0			
_argv		dw 10h dup( 0)		
					
command		db 80h dup(0)		
					
ParseCommandLine proc near		
	mov	_argc, 0
	cmp	byte ptr es:80h, 2
	jb	short locret_15CE
	xor	cx, cx
	mov	cl, es:80h
	SwapSegs
	dec	cx
	mov	di, offset command
	mov	si, 82h
	rep movsb
	push	cs
	pop	ds
	mov	di, offset _argv
	mov	si, offset command
loc_15B0:				
	inc	_argc
	mov	ax, si
	stosw
loc_15B7:				
	lodsb
	cmp	al, 20h
	jnz	short loc_15C2
	mov	byte ptr [si-1], 0
	jmp	short loc_15B0
loc_15C2:				
	cmp	al, 0Dh
	jz	short loc_15CA
	or	al, al
	jnz	short loc_15B7
loc_15CA:				
	mov	byte ptr [si-1], 0
locret_15CE:				
	retn
ParseCommandLine endp

HardwareInit	proc near		
	xor	ax, ax
	push	ds
	push	cs
	pop	ds
	mov	al, 78h
	mov	cx, 8
loc_15D9:			
	mov	ah, 35h
	int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
	mov	di, offset aDIGPAK   ; "DIGPAK"
	mov	si, offset aUltramid ; "ULTRAMID"
	push	cx
	mov	cx, 8
	cld
	repe cmpsb
	jcxz	short loc_15F3
	pop	cx
	inc	al
	loop	loc_15D9
	jmp	short loc_1664
loc_15F3:			
	pop	cx
	pop	ds
	mov	ah, 35h
	int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
	mov	word ptr cs:ultramid_intr, bx
	mov	word ptr cs:ultramid_intr+2, es
	mov	ax, 1Ah		; ultramid application start
	call	cs:ultramid_intr
	mov	ax, 18h		; ultramid add external	semaphore
	mov	bx, cs
	mov	dx, offset INDIGPAK
	call	cs:ultramid_intr
	mov	word ptr cs:GUSSound.um_stereo_mem+2, cs
	mov	word ptr cs:GUSSound.um_stereo_mem, offset ultramid_buffer
	mov	word ptr cs:GUSSound.um_callback_addr+2, cs
	mov	word ptr cs:GUSSound.um_callback_addr, offset ultramid_handler
	mov	cs:GUSSound.um_pan, 7
	mov	cs:GUSSound.um_volume, (offset PlaySound+1)
	mov	ax, 13h		; ultramid allocate memory
	xor	bx, bx
	mov	dx, 2000h	; memory size
	call	cs:ultramid_intr
	mov	word ptr cs:GUSSound.um_gf1mem,	ax
	mov	word ptr cs:GUSSound.um_gf1mem+2, dx
	or	ax, dx
	cmp	ax, 0
	jz	short loc_165F
	mov	ax, 0
	jmp	short loc_1668
loc_165F:				
	mov	ax, 2
	jmp	short locret_1674
loc_1664:				
	pop	ds
	mov	ax, 1
loc_1668:				
	cmp	ax, 0
	jz	short loc_1672
	mov	ax, 1
	jmp	short locret_1674
loc_1672:				
	xor	ax, ax
locret_1674:				
	retn
HardwareInit	endp

	db 0Bh dup(0)

	end start
