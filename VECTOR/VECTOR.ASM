
		.model tiny, C
		
	INCLUDE COMPAT.INC
        INCLUDE PROLOGUE.MAC          ;; common prologue
	INCLUDE SOUNDRV.INC

DEBUGGING equ	0

Nibble	Macro
	LOCAL	@@OK
	push	eax
	and	eax,0Fh
	add	eax,'0'
	cmp	eax,'9'
	jle	@@OK
	sub	eax,'9'+1
	add	eax,'A'
@@OK:	mov	[es:di],al
	sub	di,2
	pop	eax
	shr	eax,4		 ; down one nibble
	endm

HEXPRINT2 Macro  reg,xloc,yloc
	push	es
	pusha
	mov	eax,reg
	push	eax
	mov	ax,DEBUGADR
	mov	es,ax
	mov	ax,160
	mul	[yloc]
	mov	di,ax
	add	di,xloc*2+7*2
	pop	eax
	Nibble
	Nibble
	Nibble
	Nibble
	Nibble
	Nibble
	Nibble
	Nibble
	popa
	pop	es
	endm

	.code
	.386
	org 100h
	assume es:nothing, ss:nothing

START:
	jmp	LoadSound		; Load the digitized sound driver
	db	"VECTOR",0,13,10
IDENTIFIER:
	db	"REAL-MODE INTERUPT VECTOR TRAPPER",0,13,10
	org	200h		; Beginning address of jumps.
	jmp	InstallInterupt 	; Install the interupt vector.

JUMPLOC dd	?	; Jump location.
KJUMP	FARPTR	<>		; Address
OLDIN	FARPTR	<>		; Original interupt vector.
ID	db	'VECT'          ; Interupt identifier string.
IND     db      'KR'            ; 4B52h indicates a kernel installed interupt.

SoundInterupt Proc	far
IF	DEBUGGING
	call	DeburstLine
ENDIF
	cmp	eax,301h		; simulate far procedure call?
	jne	@@CHAIN
	mov	[word ptr cs:JUMPLOC],cx	; offset
	mov	[word ptr cs:JUMPLOC+2],bx	; segment
	call	[cs:JUMPLOC]	; Indirect far call to this location.
	iret
@@CHAIN:
	jmp	[cs:OLDIN.DPTR] 	; Chain to original interrupt vector.
SoundInterupt	endp

InstallInterupt	Proc    far
	IN_TSR
	push	cs
	xlea	ax,[SoundInterupt]
	push	ax
	mov	ax,KINT
	push	ax
	call	InstallINT		;; Install the interupt.
	add	sp,6			;; clean up stack
	OUT_TSR
	iret
InstallInterupt	endp

InstallINT PROC NEAR C INTNO:WORD,IOFF:WORD,ISEG:WORD
	PushCREGS
	mov	ax,[INTNO]	; get the interupt vector.
        mov     di,ax           ; save interupt vector into DI as well
	mov	si,[IOFF]	; get offset
	mov	ds,[ISEG]	; get segment.
        mov     ah,35h          ; Get interupt vector
	int	21h		; Do DOS call to get vector.
	mov	ds:[si-10],bx	; Save the old offset.
	mov	ds:[si-8],es	; Save the old segment
        cld
        xor     ax,ax
        mov     es,ax
	ShiftL	di,2		;
	mov	ax,si		; get offset.
        cli
        stosw
        mov     ax,ds           ; code segment
	stosw			; store it.
        sti
	xor	ax,ax		; Success
	PopCREGS
	nope
	nope
	ret
InstallINT endp

IF	DEBUGGING

DEBUGADR equ	0B000h

R_EAX	dd	?
R_EBX	dd	?
R_ECX	dd	?
R_EDX	dd	?
R_ESI	dd	?
R_EDI	dd	?

;;		 3	   4	     5	       6	 7
;;		 01234567890123456789012345678901234567890123456789
MSGDBUG db	"VECTOR    EAX=00000000 EBX=00000000 ECX=00000000"

LINENO	dw	0

GetKey	Macro	
	LOCAL	@@RET
        mov     ah,07h
        int     21h
        xor     ah,ah
	or	al,al
	jnz	@@RET
	mov	ah,07h
	int	21h
	xor	ah,ah
	add	ax,256
@@RET:
	endm

DeburstLine	Proc	near
	push	ds
	push	es
	pusha

	mov	[cs:R_EAX],eax
	mov	[cs:R_EBX],ebx
	mov	[cs:R_ECX],ecx
	mov	[cs:R_EDX],edx
	mov	[cs:R_ESI],esi
	mov	[cs:R_EDI],edi

	mov	ax,DEBUGADR
	mov	es,ax
	push	cs
	pop	ds
	mov	ax,160
	mul	[LINENO]
	add	ax,30*2
	mov	di,ax		; Into DI
	xlea	si,[MSGDBUG]
	mov	cx,size MSGDBUG
@@GO:	movsb
	inc	di
	loop	@@GO

	mov	ebx,[R_EAX]
	HEXPRINT2 ebx,44,LINENO
	mov	ebx,[R_EBX]
	HEXPRINT2 ebx,57,LINENO
	mov	ebx,[R_ECX]
	HEXPRINT2 ebx,70,LINENO

	inc	[LINENO]
	cmp	[LINENO],23
	jne	@@COOL
	mov	[LINENO],0
@@COOL:
	;;GetKey

	popa
	pop	es
	pop	ds
	ret
DeburstLine endp

ENDIF

LoadSound Proc	near
	DOSTerminate
LoadSound endp

	end	START
