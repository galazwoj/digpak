
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

SNDSYSINFO3	struc ;	(sizeof=0x58)
ssi_wFlags		dw ?
ssi_wIOAddress		dw ?
ssi_bIRQ		db ?
ssi_bDMADAC		db ?
ssi_bDMAADC		db ?
ssi_bVersionCODEC 	db ?
ssi_wVersionVxD		dw ?
ssi_wVersionPAL		dw ?
ssi_dwDMABufferHandle 	dd ?
ssi_lpDMABufferPhys 	dd ?
ssi_lpDMABufferLinear 	dd ?
ssi_dwDMABufferLen 	dd ?
ssi_wDMABufferSelector 	dw ?
ssi_wIOAddressOPL3 	dw ?
ssi_dwCODECOwnerCur 	dd ?
ssi_dwCODECOwnerLast 	dd ?
ssi_dwIRQHandle		dd ?
ssi_dwOPL3OwnerCur 	dd ?
ssi_dwOPL3OwnerLast 	dd ?
ssi_dwDMADACHandle 	dd ?
ssi_dwDMAADCHandle 	dd ?
ssi_wIOAddressSB 	dw ?
ssi_wCODECBase		dw ?
ssi_hlPipe		dd ?
ssi_wSCSIStatus		dw ?
ssi_wReserved		dw ?
ssi_wCODECClass		dw ?
ssi_wAGABase		dw ?
ssi_wOEM_ID		dw ?
ssi_wHardwareOptions 	dw ?
ssi_dn			dd ?
ssi_hAutoSelectStubs 	dd ?
SNDSYSINFO3	ends

SNDSYSINFO4	struc ;	(sizeof=0x5C)
ssi_dwSize		dd ?
ssi_wFlags		dw ?
ssi_wIOAddress		dw ?
ssi_bIRQ		db ?
ssi_bDMADAC		db ?
ssi_bDMAADC		db ?
ssi_bVersionCODEC 	db ?
ssi_wVersionVxD		dw ?
ssi_wVersionPAL		dw ?
ssi_dwDMABufferHandle 	dd ?
ssi_lpDMABufferPhys 	dd ?
ssi_lpDMABufferLinear 	dd ?
ssi_dwDMABufferLen 	dd ?
ssi_wDMABufferSelector 	dw ?
ssi_wIOAddressOPL3 	dw ?
ssi_dwCODECOwnerCur 	dd ?
ssi_dwCODECOwnerLast 	dd ?
ssi_dwIRQHandle		dd ?
ssi_dwOPL3OwnerCur 	dd ?
ssi_dwOPL3OwnerLast 	dd ?
ssi_dwDMADACHandle 	dd ?
ssi_dwDMAADCHandle 	dd ?
ssi_wIOAddressSB 	dw ?
ssi_wCODECBase		dw ?
ssi_hlPipe		dd ?   	
ssi_wSCSIStatus		dw ?
ssi_wReserved		dw ?
ssi_wCODECClass		dw ?
ssi_wAGABase		dw ?
ssi_wOEM_ID		dw ?
ssi_wHardwareOptions 	dw ?
ssi_dn			dd ?
ssi_hAutoSelectStubs 	dd ?
SNDSYSINFO4	ends

WSSCONFIG	struc ;	(sizeof=0x2C)
field_0			dw ?
field_2			dw ?
IOAddress		dw ?
VersionCODEC		dw ?
OPL3_IOAddress		dw ?
IRQ			dw ?
DMADAC			dw ?
DMAADC			dw ?
field_10		dw ?
MSSNDSYS_API_version 	dw ?
DMABufferPhys		dd ?
DMABufferLen		dd ?
field_1C		dw ?
field_1E		dw ?
field_20		dw ?
field_22		dw ?
field_24		dw ?
field_26		dw ?
field_28		dw ?
field_2A		dw ?
WSSCONFIG	ends

	.code
	.386
	assume es:nothing, ss:nothing

	extern MSSNDSYS_ptr		:dword	
	extern MSSNDSYS_API_version 	:word
	extern x_bVersionCODEC		:word	
	extern x_lpDMABufferPhys 	:dword	
	extern x_dwDMABufferLen 	:dword	
	extern x_wFlags			:word	
	extern x_wIOAddress		:word	
	extern x_bIRQ			:word	
	extern x_bDMADAC		:word	
	extern x_bDMAADC		:word	
	extern is_eisa			:word	
	extern gbMode			:byte	
	extern gbMute			:byte

	extern	PASCAL CODEC_ExtMute:near
	extern 	PASCAL CODEC_EnterTRD:near
	extern	PASCAL CODEC_LeaveTRD:near

gabDMAValid		db 0, 1, 3, 0FFh
gabIRQValid		db 7, 9, 0Ah, 0Bh, 0FFh
gabIRQConfigCodes 	db 8, 10h, 18h, 20h, 0FFh
PortPossibilities 	dw 530h, 604h, 0E80h, 0F40h, 0FFFFh
EISA_data		db  0Eh, 11h, 5, 9

wssPresenceDetection proc near PASCAL USES DX		
;		push	dx
		xor	ax, ax
		mov	x_wFlags, ax
		not	ax
		mov	x_wIOAddress, ax
		mov	x_bIRQ,	ax
		mov	x_bDMADAC, ax
		mov	x_bDMAADC, ax
		call	MSSNDSYS_Get_API
		jb	short loc_1339
		or	x_wFlags, 8
		call	MSSNDSYS_Get_Info
		jmp	short loc_136B
loc_1339:				
		call	Validate_CODEC
		jb	short loc_136B
		mov	x_wIOAddress, dx
		mov	x_bVersionCODEC, ax
		or	x_wFlags, 2
		call	CODEC_ACK_And_Disable_Interrupt
		jb	short loc_1354
		or	x_wFlags, 1
loc_1354:				
		call	Detect_EISA
		jb	short loc_1361
		mov	is_eisa, ax
		or	x_wFlags, 10h
loc_1361:				
		call	MSSNDSYS_Force_OPL3_Into_OPL2_Mode
		jb	short loc_136B
		or	x_wFlags, 4
loc_136B:				
		mov	ax, x_wFlags
;		pop	dx
		ret
wssPresenceDetection endp

wssConfigureHardware proc near PASCAL USES DX DI ES IRQ:WORD,DMA:WORD,ww_config:DWORD
		cmp	x_wIOAddress, 0FFFFh
		jnz	short loc_1387
		call	wssPresenceDetection
		or	ax, ax
		jnz	short loc_1387
		jmp	loc_1489
loc_1387:				
		test	x_wFlags, 8
		jnz	short loc_13DF
		mov	dx, x_wIOAddress
		test	x_wFlags, 1
		jz	short loc_13C3
		mov	ax, [IRQ]
		call	Validate_AutoSel_IRQ
		jnb	short loc_13AB
		call	Validate_Intr
		jnb	short loc_13AB
		jmp	loc_1489
loc_13AB:				
		xor	ah, ah
		mov	x_bIRQ,	ax
		mov	ax, [DMA]
		call	dsp_read_PIOData
		jnb	short loc_13BB
		jmp	loc_1489
loc_13BB:				
		mov	x_bDMADAC, ax
		mov	x_bDMAADC, ax
		jmp	short loc_13DF
loc_13C3:				
		call	IRQ_set_vect
		jnb	short loc_13CB
		jmp	loc_1489
loc_13CB:				
		mov	x_bIRQ,	ax
		mov	ax, [DMA]
		call	Validate_AutoSel_DMA
		jnb	short loc_13D9
		jmp	loc_1489
loc_13D9:				
		mov	x_bDMADAC, ax
		mov	x_bDMAADC, ax
loc_13DF:				
		mov	ax, word ptr [ww_config]
		or	ax, word ptr [ww_config+2]
		jz	short loc_1458
		les	di, [ww_config]
		assume es:nothing
		cld
		xor	ax, ax
		mov	cx, 2Ch
		shr	cx, 1
		rep stosw
		adc	cl, cl
		rep stosb
		les	di, [ww_config]
		mov	ax, x_bDMADAC
		mov	es:[di+WSSCONFIG.DMADAC], ax
		mov	ax, x_bDMAADC
		mov	es:[di+WSSCONFIG.DMAADC], ax
		mov	ax, x_bIRQ
		mov	es:[di+WSSCONFIG.IRQ], ax
		mov	ax, x_wIOAddress
		mov	es:[di+WSSCONFIG.IOAddress], ax
		mov	ax, x_bVersionCODEC
		mov	es:[di+WSSCONFIG.VersionCODEC],	ax
		test	x_wFlags, 8
		jz	short loc_1449
		mov	ax, MSSNDSYS_API_version
		mov	es:[di+WSSCONFIG.MSSNDSYS_API_version],	ax
		mov	ax, word ptr x_lpDMABufferPhys
		mov	word ptr es:[di+WSSCONFIG.DMABufferPhys], ax
		mov	ax, word ptr x_lpDMABufferPhys+2
		mov	word ptr es:[di+(WSSCONFIG.DMABufferPhys+2)], ax
		mov	ax, word ptr x_dwDMABufferLen
		mov	word ptr es:[di+WSSCONFIG.DMABufferLen], ax
		mov	ax, word ptr x_dwDMABufferLen+2
		mov	word ptr es:[di+(WSSCONFIG.DMABufferLen+2)], ax
loc_1449:				
		test	x_wFlags, 4
		jz	short loc_1458
		mov	ax, 388h
		mov	es:[di+WSSCONFIG.OPL3_IOAddress], ax
loc_1458:				
		test	x_wFlags, 1
		jz	short loc_146C
		mov	ah, byte ptr x_bIRQ
		mov	al, byte ptr x_bDMADAC
		call	set_dsp_dacaddress
		jb	short loc_1489
loc_146C:				
		cmp	x_bIRQ,	7
		jnz	short loc_1483
		mov	al, 0Bh
		out	20h, al		; Interrupt controller,	8259A.
		in	al, 20h		; Interrupt controller,	8259A.
		in	al, 20h		; Interrupt controller,	8259A.
		or	al, al
		jz	short loc_1483
		mov	al, 67h
		out	20h, al		; Interrupt controller,	8259A.
loc_1483:				
		mov	ax, 1
		jmp	short loc_148C
		nop
loc_1489:				
		mov	ax, 0
loc_148C:				
		nope
		nope
		ret	
wssConfigureHardware endp

MSSNDSYS_Get_API proc near		
		mov	ax, 1600h
		int	2Fh		; - Multiplex -	MS WINDOWS - ENHANCED WINDOWS INSTALLATION CHECK
					; Return: AL = anything	else
					; AL = Windows major version number >= 3
					; AH = Windows minor version number
		test	al, 7Fh
		jz	short loc_14C7
		xchg	ah, al
		cmp	ax, 30Ah
		jb	short loc_14C7
		mov	ax, 1684h
		mov	bx, 45Fh	; MSSNDSYS.VXD - MICROSOFT Windows Sound System	VXD Driver
		int	2Fh		; - Multiplex -	MS WINDOWS - GET DEVICE	API ENTRY POINT
					; BX = virtual device (VxD) ID,	ES:DI =	0000h:0000h
					; Return: ES:DI	-> VxD API entry point,	or 0:0 if the VxD does not support an API
		mov	ax, es
		or	ax, di
		jz	short loc_14C7
		mov	word ptr MSSNDSYS_ptr, di
		mov	word ptr MSSNDSYS_ptr+2, es
		mov	dx, 0
		call	MSSNDSYS_ptr
		mov	MSSNDSYS_API_version, ax
		clc
		retn
loc_14C7:				
		stc
		retn
MSSNDSYS_Get_API endp

MSSNDSYS_Get_Info proc near PASCAL USES BX ES 
		LOCAL   var_5C:SNDSYSINFO4	;= word ptr -5Ch
;		push	bp
;		mov	bp, sp
;		sub	sp, 5Ch
;		push	bx
;		push	es
		push	ss
		pop	es
		lea	bx, var_5C
		mov	word ptr es:[bx+SNDSYSINFO4.ssi_dwSize], 5Ch
		mov	word ptr es:[bx+(SNDSYSINFO4.ssi_dwSize+2)], 0
		xor	ax, ax
		mov	dx, 1
		call	MSSNDSYS_ptr
		jnb	short loc_14EF
		jmp	loc_1579
loc_14EF:				
		cmp	MSSNDSYS_API_version, 100h
		jz	short ver_4
		mov	ax, es:[bx+SNDSYSINFO4.ssi_wIOAddress]
		mov	x_wIOAddress, ax
		xor	ah, ah
		mov	al, es:[bx+SNDSYSINFO4.ssi_bIRQ]
		mov	x_bIRQ,	ax
		mov	al, es:[bx+SNDSYSINFO4.ssi_bDMADAC]
		mov	x_bDMADAC, ax
		mov	al, es:[bx+SNDSYSINFO4.ssi_bDMAADC]
		mov	x_bDMAADC, ax
		mov	al, es:[bx+SNDSYSINFO4.ssi_bVersionCODEC]
		mov	x_bVersionCODEC, ax
		or	x_wFlags, 2
		cmp	es:[bx+SNDSYSINFO4.ssi_wIOAddressOPL3],	0
		jz	short loc_152D
		or	x_wFlags, 4
loc_152D:				
		mov	ax, word ptr es:[bx+SNDSYSINFO4.ssi_lpDMABufferPhys]
		mov	word ptr x_lpDMABufferPhys, ax
		mov	ax, word ptr es:[bx+(SNDSYSINFO4.ssi_lpDMABufferPhys+2)]
		mov	word ptr x_lpDMABufferPhys+2, ax
		mov	ax, word ptr es:[bx+SNDSYSINFO4.ssi_dwDMABufferLen]
		mov	word ptr x_dwDMABufferLen, ax
		mov	ax, word ptr es:[bx+(SNDSYSINFO4.ssi_dwDMABufferLen+2)]
		mov	word ptr x_dwDMABufferLen+2, ax
		jmp	short loc_1575
ver_4:					
		mov	ax, es:[bx+SNDSYSINFO3.ssi_wIOAddress]
		mov	x_wIOAddress, ax
		xor	ah, ah
		mov	al, es:[bx+SNDSYSINFO3.ssi_bIRQ]
		mov	x_bIRQ,	ax
		mov	al, es:[bx+SNDSYSINFO3.ssi_bDMADAC]
		mov	x_bDMADAC, ax
		mov	al, es:[bx+SNDSYSINFO3.ssi_bDMAADC]
		mov	x_bDMAADC, ax
		mov	al, es:[bx+SNDSYSINFO3.ssi_bVersionCODEC]
		mov	x_bVersionCODEC, ax
		or	x_wFlags, 6
loc_1575:				
		clc
		jmp	short loc_157A
		nop
loc_1579:				
		stc
loc_157A:				
;		pop	es
;		pop	bx
;		mov	sp, bp
;		pop	bp
;		nope
;		nope
		ret
MSSNDSYS_Get_Info endp

Detect_EISA	proc near		
		push	bx
		push	cx
		push	dx
		mov	ax, 0E800h
		int	15h
		pop	dx
		jb	short loc_15DF
		or	ah, ah
		jnz	short loc_15BE
		mov	bh, bl
		and	bh, 0F0h
		cmp	bh, 30h
		jz	short loc_15B4
		cmp	bh, 10h
		jnz	short loc_15DF
		test	bl, 2
		jnz	short loc_15DF
		test	bl, 1
		jnz	short loc_15AF
		mov	ax, dx
		add	ax, 3
		jmp	short loc_15DC
loc_15AF:				
		mov	ax, 0C47h
		jmp	short loc_15DC
loc_15B4:				
		test	bl, 3
		jnz	short loc_15DF
		mov	ax, 0C47h
		jmp	short loc_15DC
loc_15BE:				
		push	si
		push	dx
		mov	cx, 4
		lea	si, EISA_data
		mov	dx, 0C80h
loc_15CA:				
		in	al, dx
		cmp	al, [si]
		jnz	short loc_15D3
		inc	dx
		inc	si
		loop	loc_15CA
loc_15D3:				
		pop	dx
		pop	si
		or	cx, cx
		jnz	short loc_15DF
		mov	ax, 0C47h
loc_15DC:				
		clc
		jmp	short loc_15E2
loc_15DF:				
		xor	ax, ax
		stc
loc_15E2:				
		pop	cx
		pop	bx
		retn
Detect_EISA	endp

CODEC_ACK_And_Disable_Interrupt	proc near 
		push	dx
		add	dx, 3
		in	al, dx
		pop	dx
		and	al, 3Fh
		cmp	al, 4
		jnz	short loc_15F5
		xor	ah, ah
		clc
		retn
loc_15F5:				
		stc
		retn
CODEC_ACK_And_Disable_Interrupt	endp

Validate_CODEC	proc near USES CX SI		
;		push	cx
;		push	si
		xor	cx, cx
loc_15FB:				
		mov	si, cx
		shl	si, 1
		mov	dx, PortPossibilities[si]
		cmp	dx, 0FFFFh
		jnz	short loc_160A
		jmp	short loc_1612
loc_160A:				
		call	Is_CODEC_Valid
		jnb	short loc_1616
		inc	cx
		jmp	short loc_15FB
loc_1612:				
		stc
		jmp	short loc_1617
		nop
loc_1616:				
		clc
loc_1617:				
;		pop	si
;		pop	cx
		ret
Validate_CODEC	endp

Is_CODEC_Valid	proc near USES CX DX		
;		push	cx
;		push	dx
		xor	cx, cx
		add	dx, 4
		in	al, dx
		test	al, 80h
		jnz	short loc_165B
		mov	cl, al
		and	al, 40h
		or	al, 0Ch
		out	dx, al
		inc	dx
		in	al, dx
		cmp	al, 9
		jz	short loc_163D
		cmp	al, 0Ah
		jz	short loc_163D
		cmp	al, 89h
		jz	short loc_163D
		jmp	short loc_1657
loc_163D:								
		mov	ch, cl
		mov	cl, al
		mov	ah, al
		not	ah
		and	ah, 0Fh
		and	al, 0F0h
		or	al, ah
		out	dx, al
		in	al, dx
		cmp	al, cl
		jz	short loc_1660
		mov	al, cl
		out	dx, al
		mov	cl, ch
loc_1657:				
		dec	dx
		mov	al, cl
		out	dx, al
loc_165B:				
		xor	ax, ax
		stc
		jmp	short loc_166C
loc_1660:				
		and	ch, 40h
		mov	gbMode, ch
		xor	ax, ax
		mov	al, cl
		clc
loc_166C:				
;		pop	dx
;		pop	cx
		ret
Is_CODEC_Valid	endp

MSSNDSYS_Force_OPL3_Into_OPL2_Mode proc	near USES AX DX
;		push	ax
;		push	dx
		mov	dx, 4
		mov	al, 60h
		call	OPL3_RegWrite
		mov	dx, 4
		mov	al, 80h
		call	OPL3_RegWrite
		mov	dx, 1
		mov	al, 1
		call	OPL3_RegWrite
		mov	dx, 4
		mov	al, 1
		call	OPL3_RegWrite
		mov	cx, 4000h
		mov	dx, 388h
loc_1697:				
		in	al, dx
		test	al, 40h
		jnz	short loc_169E
		loop	loc_1697
loc_169E:				
		push	ax
		mov	dx, 4
		mov	al, 60h
		call	OPL3_RegWrite
		mov	dx, 4
		mov	al, 80h
		call	OPL3_RegWrite
		pop	ax
		test	al, 40h
		jz	short loc_16BB
		test	al, 6
		jnz	short loc_16BB
		clc
		jmp	short loc_16BC
loc_16BB:				
		stc
loc_16BC:				
;		pop	dx
;		pop	ax
		ret
MSSNDSYS_Force_OPL3_Into_OPL2_Mode endp

OPL3_RegWrite	proc near USES DX		
;		push	dx
		push	ax
		mov	ax, dx
		shl	ah, 1
		mov	dx, 388h
		add	dl, ah
		out	dx, al
		sub	dl, ah
		call	OPL3_IODelay
		pop	ax
		inc	dl
		out	dx, al
		call	OPL3_IODelay
;		pop	dx
		ret
OPL3_RegWrite	endp

OPL3_IODelay	proc near USES AX DX		
;		push	ax
;		push	dx
		mov	dx, 388h
		in	al, dx
		jmp	short $+2
		jmp	short $+2
		in	al, dx
		jmp	short $+2
		jmp	short $+2
;		pop	dx
;		pop	ax
		ret
OPL3_IODelay	endp

Validate_Intr	proc near		
		push	si
		xor	si, si
loc_16EE:				
		xor	ah, ah
		mov	al, gabIRQValid[si]
		cmp	al, 0FFh
		jnz	short loc_16FB
		pop	si
		stc
		retn
loc_16FB:				
		call	Validate_AutoSel_IRQ
		jnb	short loc_1703
		inc	si
		jmp	short loc_16EE
loc_1703:				
		pop	si
		clc
		retn
Validate_Intr	endp

Validate_AutoSel_IRQ proc near		
		push	ax
		push	cx
		push	dx
		push	si
		xor	si, si
loc_170C:				
		mov	ah, gabIRQConfigCodes[si]
		cmp	ah, 0FFh
		jz	short loc_173D
		cmp	gabIRQValid[si], al
		jz	short loc_171E
		inc	si
		jmp	short loc_170C
loc_171E:				
		or	ah, 40h
		xchg	al, ah
		out	dx, al
		add	dx, 3
		in	al, dx
		test	al, 40h
		jz	short loc_173D
		mov	dx, 1
		mov	cl, ah
		shl	dx, cl
		test	al, 80h
		jz	short loc_173B
		and	dx, 2FFh
loc_173B:				
		or	dx, dx

loc_173D:				
		pop	si
		pop	dx
		pop	cx
		pop	ax
		jz	short loc_1745
		clc
		retn
loc_1745:				
		stc
		retn
Validate_AutoSel_IRQ endp

dsp_read_PIOData proc near		
		mov	ah, al
		push	dx
		add	dx, 3
		in	al, dx
		pop	dx
		cmp	ah, 1
		jz	short loc_1761
		cmp	ah, 3
		jz	short loc_1761
		mov	ah, 0
		test	al, 80h
		jz	short loc_1761
		inc	ah
loc_1761:				
		mov	al, ah
		xor	ah, ah
		clc
		retn
dsp_read_PIOData endp

set_dsp_dacaddress proc	near USES AX DX SI		
;		push	ax
;		push	dx
;		push	si
		xor	si, si
loc_176C:				
		mov	dh, gabIRQConfigCodes[si]
		cmp	dh, 0FFh
		jz	short loc_1792
		cmp	gabIRQValid[si], ah
		jz	short loc_177E
		inc	si
		jmp	short loc_176C
loc_177E:				
		cmp	al, 2
		jz	short loc_1792
		ja	short loc_1786
		inc	al
loc_1786:				
		and	al, 3
		or	al, dh
		mov	dx, x_wIOAddress
		out	dx, al
		clc
		jmp	short loc_1793
loc_1792:				
		stc
loc_1793:				
;		pop	si
;		pop	dx
;		pop	ax
		ret
set_dsp_dacaddress endp

IRQ_set_vect	proc near USES BX CX DX SI		
;		push	bx
;		push	cx
;		push	dx
;		push	si
		mov	ax, 1
		call	CODEC_ExtMute
		xor	ax, ax
		xor	si, si
		xor	cx, cx
loc_17A7:				
		cmp	gabIRQValid[si], 0FFh
		jz	short loc_17BC
		mov	cl, gabIRQValid[si]
		mov	bx, 1
		shl	bx, cl
		or	ax, bx
		inc	si
		jmp	short loc_17A7
loc_17BC:				
		mov	cx, ax
		pushf
		cli
		in	al, 0A1h	; Interrupt Controller #2, 8259A
		mov	ah, al
		in	al, 21h		; Interrupt controller,	8259A.
		push	ax
		or	ax, cx
		xchg	al, ah
		out	0A1h, al	; Interrupt Controller #2, 8259A
		xchg	al, ah
		out	21h, al		; Interrupt controller,	8259A.
		call	CODEC_EnterTRD
		xor	ax, ax
		mov	al, 0Ah
		out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
		jmp	short $+2
		jmp	short $+2
		out	20h, al		; Interrupt controller,	8259A.
		jmp	short $+2
		jmp	short $+2
		in	al, 0A0h	; PIC 2	 same as 0020 for PIC 1
		mov	ah, al
		in	al, 20h		; Interrupt controller,	8259A.
		and	ax, cx
		jnz	short loc_17F1
		jmp	loc_1891
loc_17F1:				
		xor	cx, cx
loc_17F3:				
		mov	bx, 1
		shl	bx, cl
		test	ax, bx
		jnz	short loc_1805
		inc	cx
		cmp	cx, 10h
		jnz	short loc_17F3
		jmp	loc_1891
loc_1805:				
		not	bx
		and	ax, bx
		or	ax, ax
		jz	short loc_1810
		jmp	loc_1891
loc_1810:				
		mov	ax, bx
		xchg	al, ah
		out	0A1h, al	; Interrupt Controller #2, 8259A
		xchg	al, ah
		out	21h, al		; Interrupt controller,	8259A.
		mov	ax, 0Bh
		out	20h, al		; Interrupt controller,	8259A.
		out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
		xor	ax, ax
		jmp	short $+2
		jmp	short $+2
		in	al, 0A0h	; PIC 2	 same as 0020 for PIC 1
		mov	ah, al
		in	al, 20h		; Interrupt controller,	8259A.
		cmp	cx, 7
		ja	short loc_185B
		not	bx
		and	ax, bx
		jz	short loc_183F
		mov	ax, 60h
		or	ax, cx
		out	20h, al		; Interrupt controller,	8259A.
loc_183F:				
		mov	ax, 0Ch
		out	20h, al		; Interrupt controller,	8259A.
		jmp	short $+2
		jmp	short $+2
		in	al, 20h		; Interrupt controller,	8259A.
		test	al, 80h
		jz	short loc_1894
		call	CODEC_LeaveTRD
		and	ax, 7
		or	ax, 60h
		out	20h, al		; Interrupt controller,	8259A.
		jmp	short loc_1894
loc_185B:				
		not	bx
		and	ax, bx
		jz	short loc_1870
		mov	ax, cx
		and	ax, 7
		or	ax, 60h
		out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
		mov	ax, 62h
		out	20h, al		; Interrupt controller,	8259A.
loc_1870:				
		mov	ax, 0Ch
		out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
		jmp	short $+2
		jmp	short $+2
		in	al, 0A0h	; PIC 2	 same as 0020 for PIC 1
		test	al, 80h
		jz	short loc_1894
		call	CODEC_LeaveTRD
		and	ax, 7
		or	ax, 60h
		out	0A0h, al	; PIC 2	 same as 0020 for PIC 1
		mov	ax, 62h
		out	20h, al		; Interrupt controller,	8259A.
		jmp	short loc_1894
loc_1891:				
		mov	cx, 0FFFFh
loc_1894:				
		call	CODEC_LeaveTRD
		pop	ax
		xchg	al, ah
		out	0A1h, al	; Interrupt Controller #2, 8259A
		xchg	al, ah
		out	21h, al		; Interrupt controller,	8259A.
		popf
		cmp	cx, 0FFFFh
		jz	short loc_18B2
		cmp	cx, 9
		jz	short loc_18B2
		and	ax, bx
		jnz	short loc_18B2
		mov	cx, 0FFFEh
loc_18B2:				
		mov	ax, cx
		or	ax, ax
		jns	short loc_18BB
		stc
		jmp	short loc_18BC
loc_18BB:				
		clc
loc_18BC:				
		push	ax
		xor	ax, ax
		call	CODEC_ExtMute
		pop	ax
;		pop	si
;		pop	dx
;		pop	cx
;		pop	bx
		ret
IRQ_set_vect	endp

Validate_AutoSel_DMA proc near		
		push	ax
		push	si
		xor	si, si
loc_18CC:				
		mov	ah, gabDMAValid[si]
		cmp	ah, 0FFh
		jz	short loc_18DF
		cmp	al, ah
		jz	short loc_18DC
		inc	si
		jmp	short loc_18CC
loc_18DC:				
		clc
		jmp	short loc_18E0
loc_18DF:				
		stc

loc_18E0:				
		pop	cx
		pop	ax
		retn
Validate_AutoSel_DMA endp

	end
