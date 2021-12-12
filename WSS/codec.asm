
		.model tiny, PASCAL
		
	INCLUDE COMPAT.INC

IFNDEF  ISCOM
	IFNDEF  ISEXE
		ISCOM 	EQU 	1
		ISEXE	EQU	0
	ELSE
		ISCOM 	EQU 	0
	ENDIF
ENDIF

	.code
	.386
	assume es:nothing, ss:nothing

	public	MSSNDSYS_ptr		
	public	MSSNDSYS_API_version 	
	public	x_bVersionCODEC		
	public	x_lpDMABufferPhys 	
	public	x_dwDMABufferLen 	
	public	x_wFlags		
	public	x_wIOAddress		
	public	x_bIRQ			
	public	x_bDMADAC		
	public	x_bDMAADC		
	public	is_eisa			
	public	gbMode		
	public	gbMute		

MSSNDSYS_ptr		dd 0			
MSSNDSYS_API_version 	dw 0		
x_bVersionCODEC		dw 0			
x_lpDMABufferPhys 	dd 0			
x_dwDMABufferLen 	dd 0			
x_wFlags		dw 0			
x_wIOAddress		dw 0FFFFh		
x_bIRQ			dw 0FFFFh		
x_bDMADAC		dw 0FFFFh		
x_bDMAADC		dw 0FFFFh		
is_eisa			dw 0			
gbMode			db 0			
gbMute			db 0			
sbvr_bCurrentRate 	db 0FFh		
			db    0
			db    0
			db  8Fh	; ?
			db  8Fh	; ?
			db  8Fh	; ?
			db  8Fh	; ?
			db  3Fh	; ?
			db  3Fh	; ?
			db  4Bh	; K
			db    0
			db  40h	; @
			db    0
			db    0
			db 0FCh	; ?
			db 0FFh
			db 0FFh
CODEC_SavedRegs		db 8 dup(0),1,0Fh,0,0Eh,3,2,5,7	
			db    4
			db    6
			db  0Dh
			db    9
			db  0Bh
			db  0Ch
CODEC_Rates		dd 1C8E17B1h		
			dd 28482260h
			dd 442A34C8h
			dd 609F4FFBh
			dd 7F19740Eh
			dd 1FF60A6Dh
			dd 0FFFF33E2h

CODEC_WaitForReady proc	NEAR PASCAL USES AX CX DX		
		mov	dx, x_wIOAddress
		add	dx, 4
		mov	cx, 2000h
loc_9C4:				
		in	al, dx
		or	al, al
		jns	short loc_9CC
		loop	loc_9C4
		stc
loc_9CC:				
		ret
CODEC_WaitForReady endp

CODEC_RegRead	proc NEAR PASCAL		
		call	CODEC_WaitForReady
		jb	short locret_9EB
		pushf
		cli
		push	dx
		mov	dx, x_wIOAddress
		add	dx, 4
		mov	al, ah
		or	al, gbMode
		out	dx, al
		inc	dx
		in	al, dx
		pop	dx
		popf
		clc
locret_9EB:				
		retn
CODEC_RegRead	endp

CODEC_RegWrite	proc NEAR PASCAL		
		call	CODEC_WaitForReady
		jb	short locret_A0B
		pushf
		cli
		push	ax
		push	dx
		mov	dx, x_wIOAddress
		add	dx, 4
		xchg	ah, al
		or	al, gbMode
		out	dx, al
		inc	dx
		mov	al, ah
		out	dx, al
		pop	dx
		pop	ax
		popf
		clc
locret_A0B:				
		retn
CODEC_RegWrite	endp

CODEC_EnterMCE	proc NEAR PASCAL USES AX CX DX SI		
		pushf
		cli
		mov	cx, 6
		xor	si, si
loc_A17:				
		mov	ax, si
		mov	ah, al
		call	CODEC_RegRead
		mov	CODEC_SavedRegs[si], al
		or	al, 80h
		call	CODEC_RegWrite
		inc	si
		loop	loc_A17
		mov	cx, 2
loc_A2D:				
		mov	ax, si
		mov	ah, al
		call	CODEC_RegRead
		mov	CODEC_SavedRegs[si], al
		push	ax
		and	al, 0Fh
		cmp	al, 0Dh
		pop	ax
		jbe	short loc_A44
		mov	al, 0Dh
		jmp	short loc_A46
loc_A44:				
		and	al, 0F0h
loc_A46:				
		call	CODEC_RegWrite
		loop	loc_A2D
		mov	al, gbMode
		or	al, 40h
		mov	gbMode, al
		call	CODEC_WaitForReady
		jb	short loc_A64
		mov	dx, x_wIOAddress
		add	dx, 4
		out	dx, al
		popf
		clc
		jmp	short loc_A66
loc_A64:				
		popf
		stc
loc_A66:				
		ret
CODEC_EnterMCE	endp

CODEC_LeaveMCE	proc NEAR PASCAL USES AX CX DX SI		
		pushf
		cli
		mov	al, gbMode
		and	al, 0BFh
		mov	gbMode, al
		call	CODEC_WaitForReady
		jb	short loc_AB9
		or	al, 9
		mov	dx, x_wIOAddress
		add	dx, 4
		out	dx, al
		inc	dx
		in	al, dx
		test	al, 8
		jz	short loc_AA2
		mov	cx, 1388h
loc_A91:				
		in	al, dx
		test	al, 20h
		jnz	short loc_A98
		loop	loc_A91
loc_A98:				
		mov	cx, 1388h
loc_A9B:				
		in	al, dx
		test	al, 20h
		jz	short loc_AA2
		loop	loc_A9B
loc_AA2:				
		mov	cx, 8
		xor	si, si
loc_AA7:				
		mov	ax, si
		mov	ah, al
		mov	al, CODEC_SavedRegs[si]
		call	CODEC_RegWrite
		inc	si
		loop	loc_AA7
		popf
		clc
		jmp	short loc_ABB
loc_AB9:				
		popf
		stc
loc_ABB:				
		ret
CODEC_LeaveMCE	endp

CODEC_ExtMute	proc NEAR PASCAL
		push	ax
		push	cx
		push	dx
		test	x_wFlags, 10h
		jz	short loc_AF0
		mov	cl, 0Ah
		or	ax, ax
		jnz	short loc_AD3
		mov	cl, 8
loc_AD3:				
		mov	dx, is_eisa
		cmp	dx, 0C47h
		jz	short loc_ADF
		xor	al, al
loc_ADF:				
		in	al, dx
		and	al, 0F0h
		or	al, cl
		out	dx, al
		push	cx
		mov	cx, 1200h
loc_AE9:				
		in	al, 84h
		loop	loc_AE9
		pop	cx
		jmp	short loc_B2B
loc_AF0:				
		mov	dx, ax
		mov	ah, 0Ah
		call	CODEC_RegRead
		and	al, 3Fh
		mov	ah, gbMute
		or	dx, dx
		jz	short loc_B11
		or	ah, 40h
		mov	gbMute, ah
		or	al, ah
		mov	ah, 0Ah
		call	CODEC_RegWrite
		jmp	short loc_B2B
loc_B11:				
		push	ax
		mov	cx, 1200h
		mov	ah, 0Ah
loc_B17:				
		call	CODEC_RegRead
		loop	loc_B17
		pop	ax
		and	ah, 0BFh
		mov	gbMute, ah
		or	al, ah
		mov	ah, 0Ah
		call	CODEC_RegWrite
loc_B2B:				
		pop	dx
		pop	cx
		pop	ax
		clc
		retn
CODEC_ExtMute	endp

CODEC_EnterTRD	proc NEAR PASCAL USES AX BX CX DX		
		mov	al, gbMode
		or	al, 40h
		mov	gbMode, al
		mov	ax, 4Bh
		add	dx, 4
		out	dx, al
		sub	dx, 4
		xor	ax, ax
		mov	ah, 0Fh
		call	CODEC_RegWrite
		dec	ah
		call	CODEC_RegWrite
		mov	ah, 0Ah
		mov	al, 2
		or	al, gbMute
		call	CODEC_RegWrite
		mov	ah, 9
		mov	al, 41h
		call	CODEC_RegWrite
		mov	al, gbMode
		and	al, 0BFh
		mov	gbMode, al
		or	al, 0Bh
		add	dx, 4
		out	dx, al
		add	dx, 3
		xor	ax, ax
		out	dx, al
		sub	dx, 7
		add	dx, 6
		mov	cx, 1F4h
loc_B81:				
		in	al, dx
		test	al, 1
		jnz	short loc_B88
		loop	loc_B81
loc_B88:				
		ret
CODEC_EnterTRD	endp

CODEC_LeaveTRD	proc NEAR PASCAL USES AX BX		
		add	dx, 6
		in	al, dx
		sub	dx, 6
		test	al, 1
		jz	short loc_BA3
		xor	ax, ax
		add	dx, 6
		out	dx, al
		sub	dx, 6
loc_BA3:				
		add	dx, 4
		mov	al, gbMode
		or	al, 40h
		mov	gbMode, al
		or	al, 0Bh
		out	dx, al
		sub	dx, 4
		mov	ah, 9
		mov	al, 4
		call	CODEC_RegWrite
		add	dx, 4
		mov	al, gbMode
		and	al, 0BFh
		mov	gbMode, al
		or	al, 0Bh
		out	dx, al
		sub	dx, 4
		mov	ah, 0Ah
		mov	al, gbMute
		call	CODEC_RegWrite
		ret
CODEC_LeaveTRD	endp

CODEC_Save	proc near PASCAL USES BX CX DI ES savearea:FAR PTR	
		pushf
		cli
		les	di, [savearea]
		mov	cx, 0Fh
		mov	ah, cl
		xor	bx, bx
loc_BEA:				
		call	CODEC_RegRead
		mov	bl, ah
		mov	es:[bx+di], al
		dec	ah
		loop	loc_BEA
		popf
		nope
		nope
		ret	
CODEC_Save	endp

CODEC_Reset	proc near PASCAL USES BX CX DI ES arg_0:FAR PTR
		pushf
		cli
		mov	ax, 1
		call	CODEC_ExtMute
		call	CODEC_EnterMCE
		les	di, [arg_0]
		mov	cx, 8
		mov	ah, 0Fh
		xor	bx, bx
loc_C1D:				
		mov	bl, ah
		mov	al, es:[bx+di]
		cmp	ah, 0Ah
		jnz	short loc_C2D
		or	al, gbMute
		jmp	short loc_C3D
loc_C2D:				
		cmp	ah, 9
		jnz	short loc_C36
		and	al, 0Ch
		jmp	short loc_C3D
loc_C36:				
		cmp	ah, 0Ah
		jnz	short loc_C3D
		and	al, 0FDh
loc_C3D:				
		call	CODEC_RegWrite
		dec	ah
		loop	loc_C1D
		call	CODEC_LeaveMCE
loc_C47:
		mov	cx, 7
		mov	ah, cl
		xor	bx, bx
loc_C4E:				
		mov	bl, ah
		mov	al, es:[bx+di]
		call	CODEC_RegWrite
		dec	ah
		loop	loc_C4E
		xor	ax, ax
		call	CODEC_ExtMute
		nope
		nope
		ret	
CODEC_Reset	endp

CODEC_SetFormat	proc near PASCAL USES AX DX SI arg_2:WORD, arg_0:WORD 
		mov	ax, [arg_2]
		xor	si, si
loc_C74:				
		cmp	ax, word ptr CODEC_Rates[si]
		jbe	short loc_C87
		add	si, 2
		cmp	word ptr CODEC_Rates[si], 0FFFFh
		jnz	short loc_C74
		sub	si, 2
loc_C87:				
		shr	si, 1
		mov	al, (CODEC_SavedRegs+8)[si]
		mov	dx, [arg_0]
		test	dx, 1
		jz	short loc_C98
		or	al, 10h
loc_C98:				
		test	dx, 2
		jz	short loc_CA0
		or	al, 40h
loc_CA0:				
		test	dx, 4
		jz	short loc_CA8
		or	al, 20h
loc_CA8:				
		test	dx, 8
		jz	short loc_CB0
		or	al, 60h
loc_CB0:				
		cmp	al, sbvr_bCurrentRate
		jz	short loc_CDB
		mov	sbvr_bCurrentRate, al
		mov	ax, 1
		call	CODEC_ExtMute
		call	CODEC_EnterMCE
		jb	short loc_CDB
		mov	ah, 8
		mov	al, sbvr_bCurrentRate
		call	CODEC_RegWrite
		mov	ah, 9
		mov	al, 4
		call	CODEC_RegWrite
		call	CODEC_LeaveMCE
		xor	ax, ax
		call	CODEC_ExtMute
loc_CDB:	
		nope
		nope			
		ret	
CODEC_SetFormat	endp

CODEC_SetBlockSize proc	near PASCAL USES AX DX arg_0:WORD
		mov	dx, [arg_0]
		mov	ah, 0Fh
		mov	al, dl
		call	CODEC_RegWrite
		mov	ah, 0Eh
		mov	al, dh
		call	CODEC_RegWrite
		nope
		nope
		ret	
CODEC_SetBlockSize endp

CODEC_SetDACAttenuation	proc near PASCAL USES AX arg_0:WORD
		mov	ah, 6
		mov	al, BYTE PTR [arg_0]
		call	CODEC_RegWrite
		mov	ah, 7
		mov	al, BYTE PTR [arg_0 +1]
		call	CODEC_RegWrite
		nope
		nope
		ret	
CODEC_SetDACAttenuation	endp

CODEC_GetDACAttenuation	proc NEAR PASCAL USES DX
		mov	ah, 6
		call	CODEC_RegRead
		mov	dl, al
		mov	ah, 7
		call	CODEC_RegRead
		mov	dh, al
		mov	ax, dx
		ret
CODEC_GetDACAttenuation	endp

CODEC_SetAux1	proc near PASCAL USES AX arg_0:WORD
		mov	ah, 2
		mov	al, BYTE PTR [arg_0]
		call	CODEC_RegWrite
		mov	ah, 3
		mov	al, BYTE PTR[arg_0 +1]
		call	CODEC_RegWrite
		nope
		nope
		ret	
CODEC_SetAux1	endp

CODEC_GetAux1	proc NEAR PASCAL USES DX
		mov	ah, 2
		call	CODEC_RegRead
		mov	dl, al
		mov	ah, 3
		call	CODEC_RegRead
		mov	dh, al
		mov	ax, dx
		ret
CODEC_GetAux1	endp

CODEC_SetInput	proc near PASCAL USES AX arg_0:WORD
		mov	ah, 0
		mov	al, BYTE PTR [arg_0]
		call	CODEC_RegWrite
		mov	ah, 1
		mov	al, BYTE PTR [arg_0 +1]
		call	CODEC_RegWrite
		nope
		nope
		ret
CODEC_SetInput	endp

CODEC_GetInput	proc NEAR PASCAL USES DX
		mov	ah, 0
		call	CODEC_RegRead
		mov	dl, al
		mov	ah, 1
		call	CODEC_RegRead
		mov	dh, al
		mov	ax, dx
		ret
CODEC_GetInput	endp

CODEC_StopDACDMA proc NEAR PASCAL USES AX DX						
		mov	ah, 9
		mov	al, 4
		call	CODEC_RegWrite
		mov	ah, 0Ah
		mov	al, gbMute
		call	CODEC_RegWrite
		ret
CODEC_StopDACDMA endp

reset_dsp	proc NEAR PASCAL USES AX DX		
		xor	ax, ax
		mov	dx, x_wIOAddress
		add	dx, 6
		out	dx, al
		ret
reset_dsp	endp

	PUBLIC PASCAL CODEC_ACK_SingleXfer_IRQ
CODEC_ACK_SingleXfer_IRQ proc NEAR PASCAL USES AX DX 	
		call	CODEC_StopDACDMA
		xor	ax, ax
		mov	dx, x_wIOAddress
		add	dx, 6
		out	dx, al
		ret
CODEC_ACK_SingleXfer_IRQ endp

CODEC_StartDACDMA proc NEAR PASCAL USES AX DX		
		call	CODEC_StopDACDMA
		call	reset_dsp
		mov	ah, 0Ah
		mov	al, gbMute
		or	al, 2
		call	CODEC_RegWrite
		mov	ah, 9
		mov	al, 1
		call	CODEC_RegWrite
		ret
CODEC_StartDACDMA endp

		DB 3 DUP(0)
	end
