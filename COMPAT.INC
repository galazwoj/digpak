
USE_TASM_CODES	equ	1	;define to generate tasm compatible opcodes
;USE_LEA	equ	1	;define to be 100% accurate with code, slower, not tasm compatible

xlea	macro	v1, v2
IFDEF	USE_LEA
	lea	v1, v2
ELSE
	mov	v1, offset v2
ENDIF
	endm

cmp_al_bl 	macro 
IFDEF	USE_TASM_CODES
	db	3ah,0c3h
ELSE
	cmp	al, bl
ENDIF
	endm	

cmp_al_bh 	macro 
IFDEF	USE_TASM_CODES
	db	3ah,0c7h
ELSE
	cmp	al, bh
ENDIF
	endm	

cmp_bl_dl 	macro 
IFDEF	USE_TASM_CODES
	db	3ah,0dah
ELSE
	cmp	bl, dl
ENDIF
	endm	

cmp_ax_n macro n
IFDEF	USE_TASM_CODES
	db	3dh
	dw 	n
ELSE
	cmp	ax, n
ENDIF
	endm	

and_ax_n macro n
IFDEF	USE_TASM_CODES
	db	25h
	dw 	n
ELSE
	and	ax, n
ENDIF
	endm	

sub_ax_n macro n
IFDEF	USE_TASM_CODES
	db	2Dh
	dw	n
ELSE
	sub	ax, n
ENDIF
	endm	

or_ax_n macro n
IFDEF	USE_TASM_CODES
	db	0Dh 
	dw	n
ELSE
	or	ax, n
ENDIF
	endm	

add_ax_n macro n
IFDEF	USE_TASM_CODES
	db	05h 
	dw	n
ELSE
	add	ax, n
ENDIF
	endm	

IFDEF MODEL		;NOT A GOOD IDEA, true for small / tiny models only 
% ECHO MODEL
ELSE
@CodeSize 	EQU 0
@DataSize	EQU 0
ENDIF

