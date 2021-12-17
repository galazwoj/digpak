
		.model tiny

VERSION_NUMBER	equ	340

	INCLUDE COMPAT.INC
        INCLUDE PROLOGUE.MAC          ;; common prologue
	INCLUDE SOUNDRV.INC

ConvertDPMI Macro myseg,indx
	LOCAL	@@HOP
	cmp	[cs:DPMI],0	; In 32 bit DPMI mode?
	je	short @@HOP
	nope
	nope
	push	eax		; Save EAX
	mov	eax,indx	; Get the entire 32 bit flat-model address.
	shr	eax,4		; leave just the segment portion.
	mov	myseg,ax		 ; place the segment into DS
	and	indx,0Fh	 ; leave just the offset portion.
	pop	eax
@@HOP:
	endm

CPROC 	equ	<Proc near C>

		.code
		.386
		org 100h
		assume es:nothing, ss:nothing
start:
		jmp	LoadSound

        	db 'DIGPAK',0,0Dh,0Ah
IDENTIFIER	db 'Sound Blaster 16',0,0Dh,0Ah 
		db 'The Audio Solution, Copyright (c) 1994',0,0Dh,0Ah
		db 'Written by John W. Ratcliff',0,0Dh,0Ah

		org 200h
		jmp	near ptr InstallInterupt
		jmp	near ptr DeInstallInterupt
_io_addx	dw 220h			
_intr_num	dw 0FFFFh		
DSP_DMA		dw 0FFFFh		
Used_DMA	dw 0FFFFh		
					
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
		dw offset FUNCT11
		dw offset FUNCT12
		dw offset FUNCT13
		dw offset FUNCT14
		dw offset FUNCT15
		dw offset FUNCT16
		dw offset FUNCT17
		dw offset FUNCT18
		dw offset FUNCT19

BACKF		dw 0			
JumpPtr		dw 0			
					
_voice_status	dw 0			
					
_lastIntFlag	dw 0
CallBacks	dw 0			
CallLow		dw 0			
					
CallHigh	dw 0			
CallDS		dw 0			
RecordMode	dw 0			
PlayMode	dw 0			
					
DPMI		dw 0			
currentBuf	db 1		
					
maxVol		dw 0			
KJUMP		FARPTR	<>
OLDIN		FARPTR	<>			
					
ID 		db 'KERN'
IND		db 'KR'

SoundInterupt	proc far		
	cmp	ax, 688h
	jb	short loc_293
	nope
	nope
	cmp	ax, 6A0h
	ja	short loc_293
	nope
	nope
	SetSemaphore		; Set the inside DigPak semaphore
	sti
	sub	ax, 688h
	shl	ax, 1
	add	ax, offset JumpTable
	xchg	ax, bx
	mov	bx, cs:[bx]
	xchg	ax, bx
	mov	cs:JumpPtr, ax
	jmp	cs:JumpPtr
loc_293:				
	cmp	word ptr cs:OLDIN.XPTR.POFF, 0
	jnz	short loc_2A7
	nope
	nope
	cmp	word ptr cs:OLDIN.XPTR.PSEG, 0
	jz	short loc_2AC
	nope
	nope
loc_2A7:				
	jmp	cs:OLDIN.DPTR
loc_2AC:				
	ClearSemaphoreIRET
SoundInterupt	endp

FUNCT1:					
	PushCREGS
	ConvertDPMI ds,esi
	call	CompleteSound
	call	SetAudio
	call	PlaySound
	PopCREGS
	ClearSemaphoreIRET

FUNCT2:					
	mov	bx,VERSION_NUMBER      	; Return VERSION NUMBER in BX! 3.40
	cmp	cs:LOOPING, 1
	jnz	short loc_303
	nope
	nope
	xor	ax, ax
	mov	dx, 1
	ClearSemaphoreIRET
loc_303:				
	mov	ax, cs:_voice_status
	xor	dx, dx
	ClearSemaphoreIRET

FUNCT3:					
	ClearSemaphoreIRET

fUNCT4:					
	PushCREGS
	ConvertDPMI ds,esi
	call	CompleteSound
	call	DoSoundPlay
	mov	cs:FROMLOOP, 0
	PopCREGS
	ClearSemaphoreIRET

fUNCT5:					
	mov	ax, 101h
	cmp	cs:AUTOALLOWED,	1
	jnz	short loc_362
	nope
	nope
	or	ax, 200h
loc_362:				
	or	ax, STEREOPAN
	or	ax, STEREOPLAY
	or	ax, PCM16
	or	ax, PCM16STEREO
	mov	bx, cs
	mov	cx, offset IDENTIFIER
	ClearSemaphoreIRET

fUNCT6:					
	xor	ax, ax
	ClearSemaphoreIRET

fUNCT7:					
	or	bx, bx
	jnz	short loc_3A2
	nope
	nope
	or	dx, dx
	jnz	short loc_3A2
	nope
	nope
	xor	ax, ax
	mov	cs:CallBacks, ax
	mov	cs:CallLow, ax
	mov	cs:CallHigh, ax
	jmp	short loc_3B8
	nope
loc_3A2:				
	mov	cs:CallLow, bx
	mov	cs:CallHigh, dx
	mov	cs:CallDS, ds
	mov	cs:CallBacks, 1
loc_3B8:				
	ClearSemaphoreIRET

fUNCT8:					
	mov	cs:PENDING, 0
	mov	cs:LOOPING, 0
	call	StopSound
	ClearSemaphoreIRET

fUNCT9:					
	ClearSemaphoreIRET

fUNCTA:					
	mov	ax, cs:CallLow
	mov	dx, cs:CallHigh
	mov	bx, cs:CallDS
	ClearSemaphoreIRET

FUNCTB:					
	mov	cs:CallBacks, 0
	mov	cs:CallLow, 0
	mov	cs:CallHigh, 0
	push	ds
	push	cs
	pop	ds
	call	ctv_uninstall
	pop	ds
	ClearSemaphoreIRET

FUNCTC:					
	ClearSemaphoreIRET

FUNCTD:					
	PushAll 	; Save all registers.
	ConvertDPMI ds,esi
	push	cs
	pop	es
	mov	di, offset LOOPSND
	mov	cx, SIZE LOOPSND
	rep movsb
	mov	ax, 68Fh
	int	66h		
	mov	cs:LOOPING, 1
	mov	ax, cs
	mov	ds, ax
	mov	dx, ax
	mov	ax, 68Eh
	mov	bx, offset LoopBack
	int	66h		
	PopAll
	push	cs
	pop	ds
	mov	si, offset LOOPSND
	mov	word ptr cs:LOOPSOUND, si
	mov	word ptr cs:LOOPSOUND+2, ds
	mov	cs:FROMLOOP, 1
	mov	ax, 68Bh
	jmp	fUNCT4

FUNCTE:			
	PushCREGS
	ConvertDPMI ds,esi
	cli
	mov	ax, cs:_voice_status
	or	ax, ax
	jnz	short loc_4CD
	nope
	nope
	sti
	call	DoSoundPlay
	xor	ax, ax
	PopCREGS
	ClearSemaphoreIRET
loc_4CD:				
	cmp	cs:PENDING, 1
	jnz	short loc_4E6
	nope
	nope
	mov	ax, 2
	PopCREGS
	ClearSemaphoreIRET
loc_4E6:				
	mov	cs:PENDING, 1
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
	mov	ax, 1
	PopCREGS
	ClearSemaphoreIRET

FUNCTF:					
	cli
	mov	ax, cs:_voice_status
	or	ax, ax
	jnz	short loc_53C
	nope
	nope
	ClearSemaphoreIRET
loc_53C:				
	cmp	cs:PENDING, 1
	jz	short loc_551
	nope
	nope
	mov	ax, 1
	ClearSemaphoreIRET
loc_551:				
		mov	ax, 2
	ClearSemaphoreIRET

FUNCT10:				
	xor	ax, ax
	push	cx
	mov	cl, 7Eh
	mov	ax, dx
	mov	dx, cs:maxVol
	cmp	ax, 40h
	jge	short loc_57E
	nope
	nope
	mul	dh
	shl	ax, 1
	add	ax, 3Fh
	div	cl
	mov	ah, al
	mov	al, dl
	jmp	short loc_58D
loc_57E:				
	mul	dl
	shl	ax, 1
	add	ax, 3Fh
	div	cl
	xchg	dl, al
	sub	al, dl
	mov	ah, dh
loc_58D:				
	mov	cl, 3
	shr	al, cl
	shr	ah, cl
	mov	dx, cs:_io_addx
	add	dx, 4
	mov	bx, ax
	mov	al, 32h
	out	dx, al
	jmp	short $+2
	mov	al, bh
	inc	dx
	out	dx, al
	dec	dx
	mov	al, 33h
	out	dx, al
	jmp	short $+2
	mov	al, bl
	inc	dx
	out	dx, al
	mov	ax, 1
	pop	cx
	pop	cx
	ClearSemaphoreIRET

FUNCT11:				
	cmp	dx, PCM_8_MONO
	jz	short loc_5DC
	nope
	nope
	cmp	dx, PCM_16_STEREO
	jz	short loc_5DC
	nope
	nope
	cmp	dx, PCM_16_MONO
	jz	short loc_5DC
	nope
	nope
	cmp	dx, PCM_8_STEREO
	jz	short loc_5DC
	nope
	nope
	jmp	short loc_5EC
	nope
loc_5DC:				
	mov	cs:PlayMode, dx
	mov	ax, 1
	ClearSemaphoreIRET
loc_5EC:				
	xor	ax, ax
	ClearSemaphoreIRET

FUNCT12:				
	mov	dx, cs
	mov	ax, offset PENDING
	mov	bx, offset INDIGPAK
	ClearSemaphoreIRET

FUNCT13:				
	mov	cs:RecordMode, dx
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT14:				
	mov	cs:CallBacks, 0
	mov	cs:LOOPING, 0
	ClearSemaphoreIRET

FUNCT15:				
	push	ds
	push	di
	push	si
	push	cs
	pop	ds
	push	dx
	mov	dx, cs:_voice_status
	call	StopSound
	pop	dx
	mov	cs:BACKF, dx
	or	dx, dx
	mov	ax, 1
	pop	si
	pop	di
	pop	ds
	ClearSemaphoreIRET

FUNCT16:				
	call	ReportDMAC
	ClearSemaphoreIRET

FUNCT17:				
	PushCREGS
	ConvertDPMI es,ebx
	push	cx
	push	es
	push	bx
	call	CheckBoundary
	add	sp, 6
	PopCREGS
	ClearSemaphoreIRET

FUNCT18:				
	xor	ax, ax
	push	dx
	mov	al, cl
	mov	ah, bl
	mov	cs:maxVol, ax
	mov	cl, 3
	shr	al, cl
	shr	ah, cl
	mov	dx, cs:_io_addx
	add	dx, 4
	mov	bx, ax
	mov	al, 32h
	out	dx, al
	jmp	short $+2
	mov	al, bh
	inc	dx
	out	dx, al
	dec	dx
	mov	al, 33h
	out	dx, al
	jmp	short $+2
	mov	al, bl
	inc	dx
	out	dx, al
	mov	ax, 1
	ClearSemaphoreIRET

FUNCT19:				
	mov	cs:DPMI, dx
	ClearSemaphoreIRET

GET20BIT	Macro	
	push	cx
	mov	cl, 4
	rol	dx, cl
	mov	cx, dx
	and	dx, 0Fh
	and	cx, 0FFF0h
	nope ;
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
	nope
	nope
	xor	ax, ax			; Didn't work.
loc_662:
	nope ;
	nope ;
	ret
CheckBoundary	endp

PlayPending	proc far		
	cmp	PENDING, 1
	jnz	short loc_73E
	nope
	nope
	mov	PENDING, 0
	mov	cs:CallBacks, 0
	mov	si, offset PENDSND
	call	DoSoundPlay
	retf
loc_73E:				
	mov	cs:CallBacks, 0
	retf
PlayPending	endp

DoSoundPlay	proc near	
	PushCREGS			; Save all of the important C registers.
	call	SetAudio
	call	PlaySound
	PopCREGS
	retn
DoSoundPlay	endp

CheckCallBack	proc near
	cmp	cs:CallBacks, 0
	jz	short locret_77C
	nope
	nope
	PushAll                         ; Save all registers      
	mov	ds, cs:CallDS
	call	dword ptr cs:CallLow
	PopAll                          ; Restore all registers.  
locret_77C:				
	retn
CheckCallBack	endp

INDIGPAK	dw 0			
					
FROMLOOP	dw 0			
SAVECALLBACK	dd 0
SAVECALLDS	dw 0
LOOPING		dw 0			

LOOPSOUND	dd 0			
LOOPSND		SOUNDSPEC <>		

PENDING		dw 0			
PENDSND		SOUNDSPEC <>		
					
LoopBack	proc far	
	mov	ax, 68Bh
	mov	cs:FROMLOOP, 1
	lds	si, LOOPSOUND
	int	66h		
	retf
LoopBack	endp

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
	call	StopSound
	retn
EndLoop		endp

CompleteSound	proc near		
	cmp	cs:FROMLOOP, 1
	jnz	short loc_7F8
	nope
	nope
	call	EndLoop
loc_7F8:			
	cmp	cs:_voice_status, 0
	jnz	short loc_7F8
	retn
CompleteSound	endp

ORG_INT_ADDX	dd 0			
INT2		dd 0
INT3		dd 0
INT5		dd 0
INT7		dd 0

;---------------------
;      DMA DATA      |
;---------------------
DMA_CURRENT_PAGE db 0			
DMA_CURRENT_ADDX dw 0			
DMA_CURRENT_COUNT dw 0			
PAGE_TO_DMA	db 0			
LEN_L_TO_DMA	dw 0			
LEN_H_TO_DMA	dw 0			
LAST_DMA_OFFSET	dw 0			

WAIT_TIME        	EQU    0ffffh
DMA_VOICE_IN	 	EQU	44H
DMA_VOICE_OUT	 	EQU	48H

DSP_ID_CMD              EQU    0E0H
DSP_VER_CMD             EQU    0E1H
DSP_VI8_CMD             EQU    24H
DSP_VO8_CMD             EQU    14H
DSP_VO2_CMD             EQU    17H
DSP_VO4_CMD             EQU    75H
DSP_VO25_CMD            EQU    77H
DSP_MDAC1_CMD           EQU    61H
DSP_MDAC2_CMD           EQU    62H
DSP_MDAC3_CMD           EQU    63H
DSP_MDAC4_CMD           EQU    64H
DSP_MDAC5_CMD           EQU    65H
DSP_MDAC6_CMD           EQU    66H
DSP_MDAC7_CMD           EQU    67H
DSP_TIME_CMD            EQU    40H
DSP_SILENCE_CMD         EQU    80H
DSP_PAUSE_DMA_CMD       EQU    0D0H
DSP_ONSPK_CMD           EQU    0D1H
DSP_OFFSPK_CMD          EQU    0D3H
DSP_CONT_DMA_CMD        EQU    0D4H
DSP_INTRQ_CMD           EQU    0F2H

DSP_AUTO_OFF		equ	0DAh

DSP_AUTO8               equ     1Ch     ; DSP auto init 8 bit.

DSP_BLK_SIZE		equ	48h	; SES - used for all but low
					; SES -  speed non-auto init

DSP_STEREO_CMD		equ	84h	; DMA stereo!!

CMS_TEST_CODE           EQU         0C6H
RESET_TEST_CODE         EQU         0AAH

CMS_EXIST               EQU         1
FM_MUSIC_EXIST          EQU         2
CTV_VOICE_EXIST         EQU         4

FM_WAIT_TIME      	EQU         40H

PortPossibilities dw 220h		
		dw 210h 		;  Aa -	Base Address	     0210h, 0220h, 0230h, 0240h,
		dw 230h 		;			     0250h, 0260h, 0280h
		dw 240h 		;  Ii -	Interrupt Request    2,	3, 5, 7, 10
		dw 250h 		;  Dd -	DMA Channel, 8-bit   0,	1, 3
		dw 260h 		;  Hh -	DMA Channel, 16-bit  5,	6, 7
IRQPossibilities dw 0Ah		;  Pp -	Base MIDI Address    0300h, 0330h
		dw 7     		;  Tt -	Model		     1(1.x), 2(Pro), 3(2.0), 4(Pro2.0),
		dw 5     		;			     5(ProMCV),	6(16, AWE32)
		dw 3     		; NOTE:	16-bit DMA definition may actually refer to an 8-bit DMA alias.
DMAPossibilities dw 7			
		dw 6
		dw 5
		dw 0FFFFh
		dw 3
		dw 0FFFFh
		dw 1
		dw 0
origDMA	db 0			
					
InitBlaster	proc near		
	PushCREGS
	push	ds
	push	cs
	pop	ds
	push	cx
	call	DetectBlaster
	jz	short loc_85D
	nope
	nope
	stc
	mov	ax, 1
	jmp	short loc_8C3
	nope
loc_85D:				
	xor	ah, ah
	mov	dx, _io_addx
	add	dx, 4
	mov	al, 80h		; mixer, IRQ Select
	out	dx, al
	inc	dx
	in	al, dx
	and	al, 0Fh
	mov	cx, 4
loc_870:				
	shr	al, 1
	loopne	loc_870
	mov	di, cx
	shl	di, 1
	mov	ax, IRQPossibilities[di]
	mov	_intr_num, ax
	dec	dx
	mov	al, 81h		; mixer, DMA Select
	out	dx, al
	inc	dx
	in	al, dx
	mov	origDMA,	al
	and	al, 0Fh
	out	dx, al
	push	ax
	and	al, 0Bh
	mov	cx, 8
loc_891:				
	shr	al, 1
	loopne	loc_891
	mov	di, cx
	shl	di, 1
	mov	ax, DMAPossibilities[di]
	mov	DSP_DMA, ax
	pop	ax
	and	ax, 0E0h
	mov	cx, 8
loc_8A7:				
	shr	al, 1
	loopne	loc_8A7
	mov	di, cx
	shl	di, 1
	mov	ax, DMAPossibilities[di]
	mov	Used_DMA, ax
	mov	al, byte ptr _intr_num
	mov	dx, offset DMA_OUT_INTR
	mov	bx, offset ORG_INT_ADDX
	call	SETUP_INTERRUPT
	clc
loc_8C3:				
	pop	cx
	pop	ds
	PopCREGS
	retn
InitBlaster	endp

DetectBlaster	proc near		
	call	reset_dsp
	jnz	short locret_8E1
	nope
	nope
	call	verify_io_chk
	jnz	short locret_8E1
	nope
	nope
	call	chk_dsp_version
	jnz	short locret_8E1
	nope
	nope
	sub	ax, ax
locret_8E1:				
	retn
DetectBlaster	endp

verify_io_chk	proc near		
	mov	bx, 2
	mov	al, 0E0h		;DSP_ID_CMD
	call	write_dsp
	jb	short loc_906
	nope
	nope
	mov	al, 0AAh
	call	write_dsp
	jb	short loc_906
	nope
	nope
	call	read_dsp
	jb	short loc_906
	nope
	nope
	cmp	al, 55h
	jnz	short loc_906
	nope
	nope
	sub	bx, bx
loc_906:				
	mov	ax, bx
	or	ax, ax
	retn
verify_io_chk	endp

AUTOALLOWED	dw 0		

chk_dsp_version	proc near		
	mov	al, 0E1h		;DSP_VER_CMD
	call	write_dsp
	call	read_dsp
	mov	ah, al
	call	read_dsp
	mov	bx, 1
	cmp	ax, 200h
	jb	short loc_92A
	nope
	nope
	mov	AUTOALLOWED, 1
loc_92A:				
	cmp	ax, 101h
	jb	short loc_933
	nope
	nope
	sub	bx, bx
loc_933:				
	mov	ax, bx
	or	ax, ax
	retn
chk_dsp_version	endp

write_dsp	proc near	
	push	ax
	push	cx
	push	dx
	mov	dx, cs:_io_addx
	add	dl, 0Ch
	mov	cx, WAIT_TIME
	mov	ah, al
loc_948:				
	in	al, dx
	or	al, al
	jns	short loc_954
	nope
	nope
	loop	loc_948
	stc
	jmp	short loc_958
loc_954:				
	mov	al, ah
	out	dx, al
	clc
loc_958:				
	pop	dx
	pop	cx
	pop	ax
	retn
write_dsp	endp

read_dsp	proc near		
	push	cx
	push	dx
	mov	dx, cs:_io_addx
	add	dl, 0Eh
	mov	cx, WAIT_TIME
loc_969:				
	in	al, dx
	or	al, al
	js	short loc_975
	nope
	nope
	loop	loc_969
	stc
	jmp	short loc_97A
loc_975:				
	sub	dl, 4
	in	al, dx
	clc
loc_97A:				
	pop	dx
	pop	cx
	retn
read_dsp	endp

reset_dsp	proc near		
	mov	dx, cs:_io_addx
	add	dl, 6
	mov	al, 1
	out	dx, al
	mov	cx, 14h
loc_98B:				
	in	al, dx
	loop	loc_98B
	mov	al, 0
	out	dx, al
	mov	cl, 20h
loc_993:				
	call	read_dsp
	cmp	al, 0AAh
	jz	short loc_9A5
	nope
	nope
	dec	cl
	jnz	short loc_993
	mov	ax, 2
	jmp	short loc_9A7
loc_9A5:				
	sub	ax, ax
loc_9A7:				
	or	ax, ax                	
	retn
reset_dsp	endp

DMA_PAGE_REG 	db  87h		; DMA_PAGE0_ADDR_REG = 0x87   	
		db  83h		; DMA_PAGE1_ADDR_REG = 0x83   
		db  81h		; DMA_PAGE2_ADDR_REG = 0x81   
		db  82h		; DMA_PAGE3_ADDR_REG = 0x82   
		db 0FFh 	; DMA_PAGE4_ADDR_REG = 0x87   
		db  8Bh		; DMA_PAGE5_ADDR_REG = 0x83   
		db  89h		; DMA_PAGE6_ADDR_REG = 0x81   
		db  8Ah		; DMA_PAGE7_ADDR_REG = 0x82   	
					
dmaChannel db 1			
dmaPageReg db 83h		
dmaAddrReg db 2			
dmaCntReg  db 3			
dmaMaskReg db 0Ah		
dmaModeReg db 0Bh			
dmaFFReg   db 0Ch		

SETUP_DMA proc near		
	push	ds
	push	cs
	pop	ds
	push	ax
	push	bx
	cmp	PlayMode, 2
	jb	short loc_9E4
	nope
	nope
	mov	bx, Used_DMA
	cmp	bx, 4
	jb	short loc_9E4
	nope
	nope
	mov	dmaMaskReg, 0DCh
	mov	dmaModeReg, 0D6h
	mov	dmaFFReg, 0D8h
	jmp	short loc_9F7
	nope
loc_9E4:				
	mov	bx, DSP_DMA
	mov	dmaMaskReg, 0Ah
	mov	dmaModeReg, 0Bh
	mov	dmaFFReg, 0Ch
loc_9F7:				
	mov	dmaChannel, bl
	mov	al, DMA_PAGE_REG[bx]
	mov	dmaPageReg, al
	and	bl, 3
	shl	bl, 1
	cmp	dmaChannel, 4
	jb	short loc_A15
	nope
	nope
	shl	bl, 1
	add	bl, 0C0h
loc_A15:				
	mov	dmaAddrReg, bl
	inc	bl
	cmp	dmaChannel, 4
	jb	short loc_A26
	nope
	nope
	inc	bl
loc_A26:				
	mov	dmaCntReg, bl
	pop	bx
	pop	ax
	pop	ds
	retn
SETUP_DMA endp

PROG_DMA	proc near		
	push	ds
	push	cs
	pop	ds
	push	bx
	push	dx
	push	ax
	mov	bx, dx
	xor	dh, dh
	call	STOP_DMA
	mov	dl, dmaFFReg
	out	dx, al
	pop	ax
	mov	dl, dmaAddrReg
	out	dx, al
	mov	al, ah
	out	dx, al
	mov	ax, cx
	mov	dl, dmaCntReg
	out	dx, al
	mov	al, ah
	out	dx, al
	mov	al, bl
	mov	dl, dmaPageReg
	out	dx, al
	mov	al, dmaChannel
	and	al, 3
	or	al, bh
	mov	dl, dmaModeReg
	out	dx, al
	pop	dx
	pop	bx
	pop	ds
	retn
PROG_DMA	endp

;-------------------------------------------------------------------------
; START_DMA - unmasks the DMA channel.
;
; inputs: none.
; output: none
;
; note: you must call SETUP_DMA and PROG_DMA before calling this function.
;-------------------------------------------------------------------------
START_DMA	proc near		
	push	ax
	push	dx
	xor	dh, dh
	mov	al, cs:dmaChannel
	and	al, 3
	mov	dl, cs:dmaMaskReg
	out	dx, al		; DMA controller, 8237A-5.
				; single mask bit register
				; 0-1: select channel (00=0; 01=1; 10=2; 11=3)
				; 2: 1=set mask	for channel; 0=clear mask (enable)
	pop	dx
	pop	ax
	retn
START_DMA	endp

;-------------------------------------------------------------------------
; STOP_DMA - masks the DMA channel.
;
; inputs: none.
; output: none
;
; note: you must call SETUP_DMA and PROG_DMA before calling this function.
;-------------------------------------------------------------------------
STOP_DMA	proc near	
	push	ax
	push	dx
	xor	dh, dh
	mov	al, dmaChannel
	and	al, 3
	or	al, 4
	mov	dl, dmaMaskReg
	out	dx, al		; DMA controller, 8237A-5.
				; single mask bit register
				; 0-1: select channel (00=0; 01=1; 10=2; 11=3)
				; 2: 1=set mask	for channel; 0=clear mask (enable)
	pop	dx
	pop	ax
	retn
STOP_DMA	endp

ReportDMAC	proc near	
	mov	ax, 1
	cmp	cs:currentBuf, 0
	jz	short locret_AA6
	nope
	nope
	mov	ax, cs:DMA_CURRENT_COUNT
	add	ax, 3
	shr	ax, 1
locret_AA6:			
	retn
ReportDMAC	endp

CALC_20BIT_ADDX	proc near		
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
	retn
CALC_20BIT_ADDX	endp

PIC0_val	db 0			
PIC1_val	db 0			

SETUP_INTERRUPT	proc near		
	push	ds
	push	cs
	pop	ds
	push	bx
	push	cx
	push	dx
	cli
	xor	ah, ah
	mov	cl, al
	cmp	al, 8
	jb	short loc_AD1
	nope
	nope
	add	al, 60h
loc_AD1:			
	add	al, 8
	shl	ax, 1
	shl	ax, 1
	mov	di, ax
	push	es
	sub	ax, ax
	mov	es, ax
	mov	ax, es:[di]
	mov	[bx], ax
	mov	es:[di], dx
	mov	ax, es:[di+2]
	mov	[bx+2],	ax
	mov	word ptr es:[di+2], cs
	pop	es
	mov	bx, 1
	shl	bx, cl
	not	bx
	in	al, 0A1h	; Interrupt Controller #2, 8259A
	mov	PIC1_val, al
	and	al, bh
	out	0A1h, al	; Interrupt Controller #2, 8259A
	in	al, 21h		; Interrupt controller,	8259A.
	mov	PIC0_val, al
	and	al, bl
	out	21h, al		; Interrupt controller,	8259A.
	sti
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	retn
SETUP_INTERRUPT	endp

RESTORE_INTERRUPT proc near		
	cli
	push	ds
	push	cs
	pop	ds
	mov	cl, al
	mov	al, PIC1_val
	out	0A1h, al	; Interrupt Controller #2, 8259A
	mov	al, PIC0_val
	out	21h, al		; Interrupt controller,	8259A.
	mov	al, cl
	xor	ah, ah
	cmp	al, 8
	jb	short loc_B2D
	nope
	nope
	add	al, 60h
loc_B2D:				
	add	al, 8
	shl	ax, 1
	shl	ax, 1
	mov	di, ax
	push	es
	sub	ax, ax
	mov	es, ax
	mov	ax, [bx]
	mov	es:[di], ax
	mov	ax, [bx+2]
	mov	es:[di+2], ax
	pop	es
	pop	ds
	sti
	retn
RESTORE_INTERRUPT endp

DUMMY_ISR	proc far
DUMMY_DMA_INT2  LABEL   word
	push	dx
	mov	dl, 2
	jmp	short loc_B5C
DUMMY_DMA_INT3  LABEL   word
	push	dx
	mov	dl, 3
	jmp	short loc_B5C
DUMMY_DMA_INT5  LABEL   word
	push	dx
	mov	dl, 5
	jmp	short loc_B5C
DUMMY_DMA_INT7  LABEL   word
	push	dx
	mov	dl, 7
loc_B5C:				
	push	ax
	mov	byte ptr cs:_intr_num, dl
	mov	dx, cs:_io_addx
	add	dx, 0Eh
	in	al, dx
	mov	al, 20h
	out	20h, al		; Interrupt controller,	8259A.
	pop	ax
	pop	dx
	iret
DUMMY_ISR	endp ; sp = -6

DMA_OUT_INTR	proc far		
	SetSemaphore
	push	ds
	push	cs
	pop	ds
	push	ax
	push	dx
	mov	dx, _io_addx
	add	dx, 4
	mov	al, 82h		; MIXER, IRQ Status
	out	dx, al
	inc	dx
	in	al, dx
	and	al, 7
	cmp	al, 4
	jz	short loc_BEE
	nope
	nope
	mov	al, byte ptr _intr_num
	cmp	al, 7
	jnz	short loc_BA7
	nope
	nope
	mov	al, 0Bh
	out	20h, al		; Interrupt controller,	8259A.
	in	al, 20h		; Interrupt controller,	8259A.
	test	al, 80h
	jz	short loc_BEE
	nope
	nope
loc_BA7:			
	cmp	PlayMode, 2
	jb	short loc_BBB
	nope
	nope
	mov	dx, _io_addx
	add	dl, 0Fh
	in	al, dx
	jmp	short loc_BC3
	nope
loc_BBB:			
	mov	dx, _io_addx
	add	dl, 0Eh
	in	al, dx
loc_BC3:				
	cmp	_voice_status, 0
	jz	short loc_BEE
	nope
	nope
	cmp	BACKF, 1
	jnz	short loc_BDD
	nope
	nope
	xor	currentBuf, 1
	jmp	short loc_BEE
	nope
loc_BDD:				
	mov	ax, LEN_L_TO_DMA
	or	ax, ax
	jnz	short loc_BEB
	nope
	nope
	call	END_DMA_TRANSFER
	jmp	short loc_BEE
loc_BEB:				
	call	DMA_OUT_TRANSFER
loc_BEE:				
	mov	al, 20h
	cmp	_intr_num, 7
	jbe	short loc_BFB
	nope
	nope
	out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
loc_BFB:			
	out	20h, al		; Interrupt controller,	8259A.
	pop	dx
	pop	ax
	pop	ds
       	ClearSemaphoreIRET
DMA_OUT_INTR	endp

INISR	Macro
	push	es		; Save registers that are used
	push	ds
	push	di
	push	si
	push	cx
	push	bx
	cld
	mov	ax,cs
	mov	es,ax
	mov	ds,ax		; Establish data addressability.
	endm

OUTISR	Macro	
	pop	bx
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es
	endm

DMA_OUT_TRANSFER proc near	
	INISR
	mov	cx, 0FFFFh
	cmp	PAGE_TO_DMA, 0
	jnz	short loc_C29
	nope
	nope
	inc	PAGE_TO_DMA
	mov	cx, LAST_DMA_OFFSET
loc_C29:	
	sub	cx, DMA_CURRENT_ADDX
	mov	DMA_CURRENT_COUNT, cx
	inc	cx
	jz	short loc_C41
	nope
	nope
	sub	LEN_L_TO_DMA, cx
	sbb	LEN_H_TO_DMA, 0
	jmp	short loc_C45
loc_C41:				
	dec	LEN_H_TO_DMA
loc_C45:				
	cmp	BACKF, 1
	jnz	short loc_C5E
	nope
	nope
	mov	dh, 58h
	cmp	RecordMode, 1
	jnz	short loc_C6B
	nope
	nope
	mov	dh, 54h
	jmp	short loc_C6B
	nope
loc_C5E:				
	mov	dh, DMA_VOICE_OUT 	;48h
	cmp	RecordMode, 1
	jnz	short loc_C6B
	nope
	nope
	mov	dh, DMA_VOICE_IN	;44h
loc_C6B:				
	mov	dl, DMA_CURRENT_PAGE
	mov	ax, DMA_CURRENT_ADDX
	mov	cx, DMA_CURRENT_COUNT
	cmp	dmaChannel, 4
	jb	short loc_C89
	nope
	nope
	shr	dl, 1
	rcr	ax, 1
	shl	dl, 1
	inc	cx
	shr	cx, 1
	dec	cx
loc_C89:				
	call	PROG_DMA
	dec	PAGE_TO_DMA
	inc	DMA_CURRENT_PAGE
	mov	DMA_CURRENT_ADDX, 0
	cmp	PlayMode, 1
	ja	short loc_CA8
	nope
	nope
	mov	al, 0C2h
	jmp	short loc_CAA
	nope
loc_CA8:				
	mov	al, 0B2h
loc_CAA:				
	cmp	BACKF, 1
	jnz	short loc_CB5
	nope
	nope
	or	al, 4
loc_CB5:				
	cmp	RecordMode, 1
	jnz	short loc_CC0
	nope
	nope
	or	al, 8
loc_CC0:				
	call	write_dsp
	sub	al, al
	test	PlayMode, 1
	jz	short loc_CD1
	nope
	nope
	or	al, 20h
loc_CD1:				
	mov	dx, PlayMode
	cmp	PlayMode, 2
	jb	short loc_CE0
	nope
	nope
	or	al, 10h
loc_CE0:				
	call	write_dsp
	mov	ax, DMA_CURRENT_COUNT
	cmp	PlayMode, 2
	jb	short loc_CF3
	nope
	nope
	inc	ax
	shr	ax, 1
	dec	ax
loc_CF3:				
	cmp	BACKF, 1
	jnz	short loc_D00
	nope
	nope
	inc	ax
	shr	ax, 1
	dec	ax
loc_D00:				
	call	write_dsp
	mov	al, ah
	call	write_dsp
	call	START_DMA
	OUTISR			; Restore registers for ISR routines.
	retn
DMA_OUT_TRANSFER endp

END_DMA_TRANSFER proc near		
       	INISR
	call	STOP_DMA
	cmp	dmaChannel, 4
	jb	short loc_D36
	nope
	nope
	mov	dx, _io_addx
	add	dl, 0Fh
	in	al, dx
	jmp	short loc_D3E
	nope
loc_D36:				
	mov	dx, _io_addx
	add	dl, 0Eh
	in	al, dx  		
loc_D3E:				
	mov	_voice_status, 0
	call	DoCallBacks
       	OUTISR
	retn
END_DMA_TRANSFER endp

ctv_output CPROC DATAL:WORD,DATAH:WORD,SNDLEN:WORD,FREQ:WORD
	PushCREGS
	push	ds
	push	cs
	pop	ds
	mov	ax, ds
	mov	es, ax
loc_D5D:			
	cmp	_voice_status, 0
	jnz	short loc_D5D
	mov	currentBuf, 1
	mov	_voice_status, 1
	mov	al, 1
	cmp	RecordMode, 1
	jnz	short loc_D7C
	nope
	nope
	xor	al, al
loc_D7C:			
	call	ON_OFF_SPEAKER
	mov	al, 41h		; DSSP,	Set Sample Rate
	call	write_dsp
	mov	ax, FREQ
	xchg	al, ah
	call	write_dsp
	mov	al, ah
	call	write_dsp
	mov	dx, DATAH
	mov	ax, DATAL
	mov	cx, SNDLEN
	call	CALC_20BIT_ADDX
	mov	DMA_CURRENT_PAGE, dl
	mov	DMA_CURRENT_ADDX, ax
	mov	LEN_L_TO_DMA, cx
	mov	LEN_H_TO_DMA, 0
	add	ax, cx
	adc	dl, 0
	sub	ax, 1
	sbb	dl, 0
	mov	LAST_DMA_OFFSET, ax
	sub	dl, DMA_CURRENT_PAGE
	mov	PAGE_TO_DMA, dl
	call	DMA_OUT_TRANSFER
	sub	ax, ax
	pop	ds
	PopCREGS
	nope
	nope
	ret
ctv_output	endp

ctv_halt	proc near	
	PushCREGS
	push	cx
	push	ds
	push	cs
	pop	ds
	mov	ax, ds
	mov	es, ax
	mov	ax, 1
	cmp	_voice_status, 0
	jz	short loc_E24
	nope
	nope
	cli
	cmp	PlayMode, 1
	ja	short loc_E08
	nope
	nope
	cmp	BACKF, 1
	jnz	short loc_E03
	nope
	nope
	mov	al, 0D0h	; DSP, Halt DMA	Operation, 8-bit
	jmp	short loc_E18
	nope
loc_E03:				
	mov	al, 0D0h	; DSP, Halt DMA	Operation, 8-bit
	jmp	short loc_E18
	nope
loc_E08:				
	cmp	BACKF, 1
	jnz	short loc_E16
	nope
	nope
	mov	al, 0D5h	; DSP, Halt DMA	Operation, 16-bit
	jmp	short loc_E18
	nope
loc_E16:				
		mov	al, 0D5h	; DSP, Halt DMA	Operation, 16-bit
loc_E18:				
	call	write_dsp
	mov	_voice_status, 0
	sti
	sub	ax, ax
loc_E24:				
	pop	ds
	pop	cx
	PopCREGS
	retn
ctv_halt	endp

ctv_uninstall	proc near	
	PushCREGS
	push	ds
	push	cs
	pop	ds
	sub	al, al
	call	ON_OFF_SPEAKER
	cmp	_voice_status, 0
	jz	short loc_E47
	nope
	nope
	call	ctv_halt
	call	END_DMA_TRANSFER
loc_E47:		
	mov	al, byte ptr _intr_num
	mov	bx, 801h
	call	RESTORE_INTERRUPT
	mov	dx, cs:_io_addx
	add	dx, 4
	mov	al, 81h
	out	dx, al
	inc	dx
	mov	al, origDMA
	out	dx, al
	sub	ax, ax
	pop	ds
       	PopCREGS
	retn
ctv_uninstall	endp

ctv_status	proc near
	mov	ax, cs:_voice_status
	retn
ctv_status	endp

SPEAKERSTATE	db 0ffh

ON_OFF_SPEAKER	proc near		
	cmp	al, SPEAKERSTATE
	jz	short loc_E9A
	nope
	nope
	PushAll
	mov	SPEAKERSTATE, al
	mov	ah, DSP_ONSPK_CMD	;0D1h	; DSP, Enable Speaker
	or	al, al
	jnz	short loc_E8C
	nope
	nope
	mov	ah, DSP_OFFSPK_CMD	;0D3h	; DSP, Disable Speaker
loc_E8C:				
	mov	al, ah
	call	write_dsp
	PopAll
loc_E9A:				
	sub	ax, ax
	retn
ON_OFF_SPEAKER	endp

PlaySound	proc near		
	push	ds
	push	cs
	pop	ds
	call	SETUP_DMA
	push	dx
	push	cx
	push	es
	push	bx
	call	ctv_output
	add	sp, 8
	pop	ds
	retn
PlaySound	endp

StopSound	proc near		
	push	ds
	push	cs
	pop	ds
	call	ctv_halt
	pop	ds
	retn
StopSound	endp

DoCallBacks	proc near	
	cmp	cs:CallBacks, 0
	jz	short locret_EDD
	nope
	nope
	PushAll 		; Save all registers
	mov	ds, cs:CallDS
	call	dword ptr cs:CallLow
	PopAll			; Restore all registers.
locret_EDD:		
	retn
DoCallBacks	endp

SUICIDE LABEL	byte		;; Where to delete ourselves from memory

hard 	db 	"SoundBlaster not detected.",0Dh,0Ah,'$'
msg0	db 	"Creative Labs Sound Blaster 16 - Copyright (c) 1994, THE Audio Solution:v3.40",0Dh,0Ah,'$'
msg1	db 	"The Sound Driver is already resident.",0Dh,0Ah,'$'
msg1a	db 	"The Sound Driver is resident, through MIDPAK.",0Dh,0Ah,'$'
msg1b	db 	"A Sound Driver cannot be loaded on top of MIDPAK.  Unload MIDPAK first.",0Dh,0Ah,'$'
msg2	db 	"Unable to install Sound Driver interupt vector",0Dh,0Ah,'$'
msg3	db	 "Invalid command line",0Dh,0Ah,'$'
msg4	db 	"Sound Driver isn't in memory",0Dh,0Ah,'$'
msg5	db 	"Sound Driver unloaded",0Dh,0Ah,'$'
msg5a	db 	"Sound Driver can't be unloaded, unload MIDPAK first.",0Dh,0Ah,'$'
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
	jz	short loc_1128
	nope
	nope
	cmp	_argc, 1
	jnz	short loc_10E0
	nope
	nope
	mov	bx, _argv
	mov	al, [bx]
	cmp	al, 75h
	jz	short loc_10ED
	nope
	nope
	cmp	al, 55h
	jz	short loc_10ED
	nope
	nope
loc_10E0:	
	Message msg3			;; Invalid command line
	DOSTerminate
loc_10ED:				
	mov	ax, Installed
	or	ax, ax
	jnz	short loc_1103
	nope
	nope
	Message msg4			;; wasn't loaded.
	DOSTerminate			;; Terminate with message.
loc_1103:				
	cmp	ax, 2
	jnz	short loc_1117
	nope
	nope
	Message msg5a
	DOSTerminate
loc_1117:				
	CALLF	DeInstallInterupt
	Message msg5			;; Display message
	DOSTerminate			;; terminate
loc_1128:				
	or	ax, ax
	jz	short loc_1165
	nope
	nope
	cmp	ax, 2
	jnz	short loc_1142
	nope
	nope
	Message msg1a
	DOSTerminate
loc_1142:				
	cmp	ax, 3
	jnz	short loc_1158
	nope
	nope
	jmp	short loc_1165
	Message msg1b
	DOSTerminate
loc_1158:				
	Message msg1			;; message
	DOSTerminate			;;
loc_1165:				
	CALLF	InstallInterupt		
	or	ax, ax
	jz	short loc_1185
	nope
	nope
	Message msg2			;; display the error message
	Message hard			; Hardware error message if there is one.
	DOSTerminate			;; exit to dos
loc_1185:				
	Message msg0
	DosTSR  SUICIDE         	;; Terminate ourselves bud.
LoadSound	endp			
					
InstallInterupt	proc far		
	IN_TSR
	call	HardwareInit
	or	ax, ax
	jnz	short loc_11C0
	nope
	nope
	mov	param, 66h
	mov	param+2, offset	SoundInterupt
	mov	param+4, cs
	PushEA	param			;; push the address of the parameter list
	call	InstallINT
	add	sp, 2
loc_11C0:		
	OUT_TSR
	retf
InstallInterupt	endp

DeInstallInterupt proc far		
	IN_TSR
	mov	param, 66h
	PushEA	param			;; push the address of the parameter list
	call	UnLoad
	add	sp, 2
	OUT_TSR
	retf
DeInstallInterupt endp

CheckIn		proc near		
	push	ds
	push	si
	mov	si, 198h
	xor	ax, ax
	mov	ds, ax
	lds	si, [si]
	or	si, si
	jz	short loc_1235
	nope
	nope
	sub	si, 6
	cmp	word ptr [si], 'IM'
	jnz	short loc_121E
	nope
	nope
	cmp	word ptr [si+2], 'ID'
	jnz	short loc_121E
	nope
	nope
	mov	ax, 701h
	int	66h		
	or	ax, ax
	jnz	short loc_1219
	nope
	nope
	mov	ax, 3
	jmp	short loc_1232
loc_1219:			
	mov	ax, 2
	jmp	short loc_1232
loc_121E:			
	cmp	word ptr [si], 'EK'
	jnz	short loc_1235
	nope
	nope
	cmp	word ptr [si+2], 'NR'
	jnz	short loc_1235
	nope
	nope
	mov	ax, 1
loc_1232:				
	pop	si
	pop	ds
	retn
loc_1235:				
	xor	ax, ax
	jmp	short loc_1232
CheckIn		endp

InstallINT CPROC MYDATA:WORD
	PushCREGS
	mov	bx, MYDATA
	mov	ax, [bx]
	mov	di, ax
	mov	si, [bx+2]
	mov	ds, word ptr [bx+4]
	mov	ah, 35h
	int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
	mov	[si-0Ah], bx
	mov	word ptr [si-8], es
	cld
	xor	ax, ax
	mov	es, ax
	ShiftL	di,2		;
	mov	ax, si
	cli
	stosw
	mov	ax, ds
	stosw
	sti
	xor	ax, ax
	PopCREGS
	nope
	nope
	ret
InstallINT	endp

UnLoad 	CPROC MYDATA:WORD
	PushCREGS
	mov	ax, 68Fh
	int	66h		
	WaitSound
	mov	ax, 692h
	int	66h		
	mov	bx, MYDATA
	mov	bx, [bx]
	mov	dx, bx
	ShiftL	bx,2		;
	xor	ax, ax
	mov	ds, ax
	lds	si, [bx]
	or	si, si
	jz	short loc_12D1
	nope
	nope
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
	pop	es
	mov	ah, 49h
	int	21h		; DOS -	2+ - FREE MEMORY
loc_12C9:				
	PopCREGS
	nope
	nope
	ret
loc_12D1:				
	mov	ax, 1
	jmp	short loc_12C9
UnLoad		endp

_argc		dw 0			
_argv		dw 10h dup(0)		
command		db 80h dup(0)		
					
ParseCommandLine proc near		
	mov	_argc, 0
	cmp	byte ptr es:80h, 2
	jb	short locret_13C6
	nope
	nope
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
loc_13A4:				
	inc	_argc
	mov	ax, si
	stosw
loc_13AB:				
	lodsb
	cmp	al, 20h
	jnz	short loc_13B8
	nope
	nope
	mov	byte ptr [si-1], 0
	jmp	short loc_13A4
loc_13B8:				
	cmp	al, 0Dh
	jz	short loc_13C2
	nope
	nope
	or	al, al
	jnz	short loc_13AB

loc_13C2:				
	mov	byte ptr [si-1], 0
locret_13C6:				
	retn
ParseCommandLine endp

HardwareInit	proc near		
	xor	ax, ax
	call	InitBlaster
	jnb	short loc_13D5
	nope
	nope
	mov	ax, 1
	jmp	short locret_13D7
loc_13D5:				
	xor	ax, ax
locret_13D7:				
	retn
HardwareInit	endp

	end start
