
BINARY_COMPATIBLE	EQU 1
; binary compatible except
;    pop_f macro nonsense
;    add sp, -n vs sub sp, n 
;

POP_F   MACRO                   ;avoid POPF bug on brain-dead 80286's
	POPF
IFDEF	BINARY_COMPATIBLE
	nop
	nop
	nop
	nop
	nop
	nop
ENDIF	
     	ENDM

um_sound_struct	struc ;	(sizeof=0x1C)
um_sound_data	dd ?
um_stereo_mem	dd ?
um_sound_len	dd ?
um_gf1mem	dd ?
um_pan		db ?
um_volume	dw ?
um_sample_rate	dw ?
um_priority	dw ?
um_data_type	db ?
um_callback_addr dd ?
um_sound_struct	ends

sbuffer		struc ;	(sizeof=0xC)
pack_type	dw ?
sample_rate	dw ?
mydata		dd ?
len_l		dw ?
len_h		dw ?
sbuffer		ends


		.model tiny, C
		assume cs:_TEXT, es:nothing, ss:nothing, ds:nothing
		.code

     		dw offset driver_index
               	db 'Copyright (C) 1991,1992 Miles Design, Inc.',1Ah
driver_index	dw 64h, offset describe_driver
		dw 65h, offset detect_device
		dw 66h, offset init_driver
		dw 68h, offset shutdown_driver
		dw 7Bh, offset play_VOC_file
		dw 7Dh, offset start_d_pb
		dw 7Eh, offset stop_d_pb
		dw 7Fh, offset pause_d_pb
		dw 80h, offset cont_d_pb
		dw 7Ch, offset get_VOC_status
		dw 81h, offset set_d_pb_vol
		dw 82h, offset get_d_pb_vol
		dw 83h, offset set_d_pb_pan
		dw 84h, offset get_d_pb_pan
		dw 78h, offset index_VOC_blk
		dw 79h, offset register_sb
		dw 7Ah, offset get_sb_status
		dw 0FFFFh
min_API_version	dw 0C8h			
driver_type	dw 2
data_suffix	db 'VOC',0
device_name_o	dw offset devnames	
device_name_s	dw 0			
default_IO	dw -1
default_IRQ	dw -1
default_DMA	dw -1
default_DRQ	dw -1
service_rate	dw -1
display_size	dw 0
devnames	db 'Forte UltraSound(TM) Digital Sound',0 
		db 0
default_vol	dw 7Fh
st_mem		db 800h	dup(0)		

playing		dw 0			
stop_voc_mode	dw 0			
db_playing	dw 0			
block_ptr	dd 0			
packing		dw 0			
current_rate	dw 0			
current_pan	dw 0			
current_volume	dw 0			
pack_byte	dw 0			
blk_len		dw 0
loop_ptr	dd 0			
loop_cnt	dw 0			

buff_data_o	dw 2 dup( 0)		
buff_data_s	dw 2 dup( 0)		
buff_len_l	dw 2 dup( 0)		
buff_len_h	dw 2 dup( 0)		
buff_pack	dw 2 dup( 0)		
buff_sample	dw 2 dup( 0)		
buff_status	dw 2 dup( 0)		
buff_time	dw 2 dup( 0)		
time		dw 0			

buffer_mode	dw 0			
DAC_status	dw 0			

xblk_status	dw 0			
xblk_tc		db 0			
xblk_pack	db 0			

		INCLUDE vol.inc

umss		um_sound_struct	<0>	
					
chk_hook_str	db 'ULTRAMID',0         
gf1hook		dd 0			
					
CPROC 	equ	<PROC FAR C>
LPROC 	equ	<PROC FAR C>

block_type      LPROC 	USES DS SI DI 
		lds	si, block_ptr
		lodsb
		mov	ah, 0
		ret
block_type	endp

set_xblk        LPROC  	USES DS SI DI
		lds	si, block_ptr
		cmp	byte ptr [si+0], 8
		jnz	short loc_A58
		mov	al, [si+5]
		mov	xblk_tc, al
		mov	ax, [si+6]
		cmp	ah, 1
		jnz	short loc_A4D
		or	al, 80h
loc_A4D:				
		mov	xblk_pack, al
		mov	xblk_status,	1
loc_A58:				
		ret
set_xblk	endp

marker_num      LPROC  	USES DS SI DI
		lds	si, block_ptr
		cmp	byte ptr [si+0], 4
		mov	ax, 0FFFFh
		jnz	short loc_A6F
		mov	ax, [si+4]
loc_A6F:				
		ret
marker_num	endp

um_callback	LPROC USES DS SI DI reason:WORD,voice:WORD,buff:FAR PTR,bufflen:FAR PTR,bufrate:FAR PTR
		cmp	reason, 0
		jnz	short loc_A82
		jmp	loc_B7F
loc_A82:				
		cmp	reason, 1
		jz	short loc_A94
		cmp	reason, 2
		jnz	short loc_A91
		jmp	loc_B35
loc_A91:				
		jmp	loc_BC1
loc_A94:				
		cmp	buffer_mode,	0
		jnz	short loc_AFB
		cmp	stop_voc_mode, 1
		jnz	short loc_AA7
		jmp	loc_BC1
loc_AA7:				
		push	cs
		call	near ptr next_block
		push	cs
		push	ax
		push	bp
		mov	bp, sp
		mov	word ptr [bp+2], offset	umss
		pop	bp
		push	cs
		call	near ptr process_block
		add	sp, 4
		cmp	ax, 0
		jnz	short loc_ACC
		mov	stop_voc_mode, 1
		jmp	loc_BC1
loc_ACC:				
		les	di, buff
		lds	si, umss.um_sound_data
		mov	es:[di], si
		mov	word ptr es:[di+2], ds
		les	di, bufflen
		lds	si, umss.um_sound_len
		mov	es:[di], si
		mov	word ptr es:[di+2], ds
		les	di, bufrate
		mov	bx, umss.um_sample_rate
		mov	es:[di], bx
		mov	ax, 1
		jmp	loc_BC4
loc_AFB:				
		push	cs
		call	near ptr next_buffer
		cmp	ax, 0FFFFh
		jnz	short loc_B07
		jmp	loc_BC1
loc_B07:				
		mov	si, ax
		shl	si, 1
		push	ax
		push	cs
		push	ax
		push	bp
		mov	bp, sp
		mov	word ptr [bp+2], offset	umss
		pop	bp
		push	ax
		push	cs
		call	near ptr process_buffer
		add	sp, 6
		pop	ax
		mov	buff_status[si], 4
		cmp	db_playing, 0FFFFh
		jnz	short loc_ACC
		mov	db_playing, ax
		jmp	short loc_ACC
loc_B35:				
		cmp	buffer_mode,	0
		jnz	short loc_B40
		jmp	loc_BC1
loc_B40:				
		mov	bx, db_playing
		shl	bx, 1
		mov	buff_status[bx], 3
		or	bx, bx
		jnz	short loc_B5A
		mov	bx, 2
		mov	si, 1
		jmp	short loc_B60
loc_B5A:				
		mov	bx, 0
		mov	si, 0
loc_B60:				
		cmp	buff_status[bx], 4
		jnz	short loc_B76
		mov	buff_status[bx], 2
		mov	db_playing, si
		jmp	short loc_BC1
loc_B76:				
		mov	db_playing, 0FFFFh
		jmp	short loc_BC1
loc_B7F:				
		mov	playing, 0
		mov	db_playing, 0FFFFh
		cmp	buff_status,	0
		jz	short loc_B9C
		mov	buff_status,	3
loc_B9C:				
		cmp	buff_status+2, 0
		jz	short loc_BAB
		mov	buff_status+2, 3
loc_BAB:				
		cmp	buffer_mode,	0
		jnz	short loc_BC1
		mov	DAC_status, 3
		mov	stop_voc_mode, 0
loc_BC1:				
		mov	ax, 0
loc_BC4:				
		ret
um_callback	endp

next_block      LPROC 	USES DS SI DI
		lds	si, block_ptr
		inc	si
		lodsw
		mov	dl, [si+0]
		mov	dh, 0
		inc	si
		push	bx
		push	cx
		mov	bx, ds
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, ax
		adc	cx, dx
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		mov	word ptr block_ptr, si
		mov	word ptr block_ptr+2, ds
		ret
next_block	endp

process_block   LPROC USES DS DI ssp:FAR PTR
loc_C23:				
		push	cs
		call	near ptr block_type
		cmp	ax, 0
		jz	short loc_C5A
		cmp	ax, 1
		jnz	short loc_C34
		jmp	loc_D1A
loc_C34:				
		cmp	ax, 2
		jz	short loc_CB3
		cmp	ax, 3
		jz	short loc_CB1
		cmp	ax, 4
		jz	short loc_C5A
		cmp	ax, 6
		jz	short loc_C66
		cmp	ax, 7
		jz	short loc_C87
		cmp	ax, 8
		jz	short loc_C54
		jmp	short loc_C60
loc_C54:				
		push	cs
		call	near ptr set_xblk
		jmp	short loc_C60
loc_C5A:				
		mov	ax, 0
		jmp	loc_DDD
loc_C60:				
		push	cs
		call	near ptr next_block
		jmp	short loc_C23
loc_C66:				
		lds	si, block_ptr
		mov	ax, [si+4]
		mov	loop_cnt, ax
		push	cs
		call	near ptr next_block
		lds	si, block_ptr
		mov	word ptr loop_ptr, si
		mov	word ptr loop_ptr+2,	ds
		jmp	short loc_C23
loc_C87:				
		cmp	loop_cnt, 0
		jz	short loc_C60
		lds	si, loop_ptr
		mov	word ptr block_ptr, si
		mov	word ptr block_ptr+2, ds
		cmp	loop_cnt, 0FFFFh
		jnz	short loc_CA9
		jmp	loc_C23
loc_CA9:				
		dec	loop_cnt
		jmp	loc_C23
loc_CB1:				
		jmp	short loc_C60
loc_CB3:				
		les	di, ssp
		mov	ax, current_rate
		mov	es:[di+um_sound_struct.um_sample_rate],	ax
		lds	si, block_ptr
		mov	ax, [si+1]
		mov	word ptr es:[di+um_sound_struct.um_sound_len], ax
		mov	al, [si+3]
		mov	ah, 0
		mov	word ptr es:[di+(um_sound_struct.um_sound_len+2)], ax
		push	bx
		push	cx
		mov	bx, ds
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, 4
		adc	cx, 0
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		mov	word ptr es:[di+(um_sound_struct.um_sound_data+2)], ds
		mov	word ptr es:[di+um_sound_struct.um_sound_data],	si
		mov	ax, 1
		jmp	loc_DDD
loc_D1A:				
		lds	si, block_ptr
		les	di, ssp
		mov	bl, [si+4]
		mov	al, [si+5]
		mov	bh, 0
		mov	ah, 0
		cmp	xblk_status,	0
		jz	short loc_D44
		mov	al, xblk_pack
		mov	bl, xblk_tc
		mov	xblk_status,	0
loc_D44:				
		mov	pack_byte, ax
		mov	packing, ax
		and	packing, 7Fh
		and	ax, 80h
		mov	cx, 6
		shr	ax, cl
		and	ax, 2
		mov	al, 5
		jnz	short loc_D63
		jmp	short loc_D65
loc_D63:				
		or	al, 8
loc_D65:				
		mov	es:[di+um_sound_struct.um_data_type], al
		mov	bh, 0
		mov	ax, 100h
		xchg	ax, bx
		sub	bx, ax
		mov	dx, 0Fh
		mov	ax, 4240h
		div	bx
		mov	current_rate, ax
		mov	es:[di+um_sound_struct.um_sample_rate],	ax
		mov	ax, [si+1]
		mov	dl, [si+3]
		mov	dh, 0
		sub	ax, 2
		sbb	dx, 0
		mov	word ptr es:[di+um_sound_struct.um_sound_len], ax
		mov	word ptr es:[di+(um_sound_struct.um_sound_len+2)], dx
		push	bx
		push	cx
		mov	bx, ds
loc_D9B:
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, 6
		adc	cx, 0
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		mov	ax, ds
		mov	word ptr es:[di+(um_sound_struct.um_sound_data+2)], ax
		mov	word ptr es:[di+um_sound_struct.um_sound_data],	si
		mov	ax, 1
loc_DDD:				
		ret
process_block	endp

next_buffer     LPROC 	USES DS SI DI
		cmp	buff_status,	0
		jz	short loc_E00
		cmp	buff_status+2, 0
		jz	short loc_E0D
		mov	DAC_status, 3
		mov	ax, 0FFFFh
		jmp	short loc_E20
loc_E00:				
		cmp	buff_status+2, 0
		jz	short loc_E12
		mov	ax, 0
		jmp	short loc_E20
loc_E0D:				
		mov	ax, 1
		jmp	short loc_E20
loc_E12:				
		mov	ax, buff_time
		cmp	ax, buff_time+2
		ja	short loc_E0D
		mov	ax, 0
loc_E20:				
		ret
next_buffer	endp

process_buffer  LPROC USES DS DI Buf:WORD,ssp:FAR PTR
		les	di, ssp
		mov	si, Buf
		shl	si, 1
		mov	ax, buff_pack[si]
		mov	pack_byte, ax
		mov	packing, ax
		and	packing, 7Fh
		and	ax, 80h
		mov	cx, 6
		shr	ax, cl
		and	ax, 2
		mov	al, 5
		jnz	short loc_E55
		jmp	short loc_E57
loc_E55:				
		or	al, 8
loc_E57:				
		mov	es:[di+um_sound_struct.um_data_type], al
		mov	ax, buff_sample[si]
		mov	bx, 100h
		sub	bx, ax
		mov	dx, 0Fh
		mov	ax, 4240h
		div	bx
		mov	current_rate, ax
		mov	es:[di+13h], ax
		mov	dx, buff_len_h[si]
		mov	bx, buff_len_l[si]
		mov	word ptr es:[di+um_sound_struct.um_sound_len], bx
		mov	word ptr es:[di+(um_sound_struct.um_sound_len+2)], dx
		mov	bx, buff_data_s[si]
		mov	dx, buff_data_o[si]
		mov	word ptr es:[di+(um_sound_struct.um_sound_data+2)], bx
		mov	word ptr es:[di+um_sound_struct.um_sound_data],	dx
		ret
process_buffer	endp

describe_driver CPROC USES DS SI DI H:WORD       ;Return far ptr to DDT
		pushf
		cli
		mov	dx, cs
		mov	device_name_s, dx
		mov	ax, offset min_API_version
		POP_F
		ret
describe_driver	endp

shutdown_driver CPROC USES DS SI DI H:WORD, SignOff:FAR PTR
		pushf
		cli
		push	cs
		call	near ptr stop_d_pb
		mov	ax, 14h
		mov	dx, word ptr umss.um_gf1mem
		mov	bx, word ptr umss.um_gf1mem+2
		call	gf1hook
		mov	ax, 1Bh
		call	gf1hook
		POP_F
		ret
shutdown_driver	endp 

set_d_pb_pan    CPROC USES DS SI DI hH:WORD, Pan:WORD
		pushf
		cli
		mov	ax, Pan
		mov	current_pan,	ax
		mov	ax, 7Fh
		sub	ax, Pan
		mov	cl, 3
		shr	ax, cl
		mov	umss.um_pan,	al
		cmp	playing, 0
		jz	short loc_F21
		mov	bx, ax
		mov	ax, 2
		mov	cx, playing
		dec	cx
		call	gf1hook
loc_F21:
		POP_F
		ret
set_d_pb_pan	endp

get_d_pb_pan    CPROC USES DS SI DI hH:WORD
		pushf
		cli
		mov	ax, current_pan
		POP_F
		ret
get_d_pb_pan	endp

set_d_pb_vol    CPROC USES DS SI DI H:WORD, Vol:WORD
		pushf
		cli
		mov	bx, Vol
		mov	current_volume, bx
		shl	bx, 1
		mov	ax, gf1_volumes[bx]
		mov	umss.um_volume, ax
		cmp	playing, 0
		jz	short loc_F78
		mov	bx, ax
		mov	ax, 3
		mov	cx, playing
		dec	cx
		call	gf1hook
loc_F78:				
		POP_F
		ret
set_d_pb_vol	endp

get_d_pb_vol    CPROC USES DS SI DI H:WORD
		pushf
		cli
		mov	ax, current_volume
		POP_F
		ret
get_d_pb_vol	endp

detect_device   CPROC USES DS SI DI H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD 
		push	ds
		push	cs
		pop	ds
		mov	al, 78h
		mov	cx, 8
loc_FAA:				
		mov	ah, 35h
		int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
					; AL = interrupt number
					; Return: ES:BX	= value	of interrupt vector
		mov	di, 103h
		mov	si, offset chk_hook_str	; "ULTRAMID"
		push	cx
		mov	cx, 7
		cld
		repe cmpsb
		jcxz	short loc_FC4
		pop	cx
		inc	al
		loop	loc_FAA
		jmp	short loc_FD9
loc_FC4:				
		pop	cx
		pop	ds
		mov	ah, 35h
		int	21h		; DOS -	2+ - GET INTERRUPT VECTOR
					; AL = interrupt number
					; Return: ES:BX	= value	of interrupt vector
		mov	word ptr gf1hook, bx
		mov	word ptr gf1hook+2, es
		mov	ax, 1
		jmp	short loc_FDD
loc_FD9:				
		pop	ds
		mov	ax, 0
loc_FDD:				
		ret
detect_device	endp

init_driver     CPROC USES DS SI DI H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD  
		mov	playing, 0
		mov	db_playing, 0FFFFh
		mov	stop_voc_mode, 0
loc_FFD:
		mov	time, 0
		mov	word ptr umss.um_stereo_mem+2, cs
		mov	word ptr umss.um_stereo_mem,	offset st_mem
		mov	word ptr umss.um_callback_addr+2, cs
		mov	word ptr umss.um_callback_addr, offset um_callback
		mov	umss.um_pan,	7
		mov	umss.um_volume, 4095
		mov	current_volume, 7Fh
		mov	loop_cnt, 0
		mov	DAC_status, 0
		mov	buffer_mode,	1
		mov	buff_status,	3
		mov	buff_status+2, 3
		mov	ax, 1Ah
		call	gf1hook
		xor	bx, bx
		mov	dx, 2000h
		mov	ax, 13h
		call	gf1hook
		mov	word ptr umss.um_gf1mem, ax
		mov	word ptr umss.um_gf1mem+2, dx
		or	ax, dx
		ret
init_driver	endp

index_VOC_blk   CPROC USES DS SI DI H:WORD,File:FAR PTR,Block:WORD,SBuf:FAR PTR   
IFDEF BINARY_COMPATIBLE            
               LOCAL 	x_status:WORD,dummy1:BYTE,x_pack:BYTE,dummy2:BYTE,x_tc:BYTE
;	MASM GENERATES ADD SP, -6
;	TASM GENERATES SUB SP,  6
ELSE
               LOCAL 	x_status:WORD,x_pack:BYTE,x_tc:BYTE
ENDIF
		pushf
		cli
		cld
		mov	x_status, 0
		lds	si, File
		mov	ax, [si+14h]
		push	bx
		push	cx
		mov	bx, ds
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, ax
		adc	cx, 0
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		mov	bx, Block
loc_10CB:				
		mov	al, [si]
		mov	ah, 0
		cmp	ax, 0
		jnz	short loc_10D7
		jmp	loc_11D5
loc_10D7:				
		cmp	ax, 8
		jnz	short loc_10F6
		mov	al, [si+5]
		mov	x_tc, al
		mov	ax, [si+6]
		cmp	ah, 1
		jnz	short loc_10EC
		or	al, 80h
loc_10EC:				
		mov	x_pack, al
		mov	x_status, 1
		jmp	short loc_110F
loc_10F6:				
		cmp	ax, 1
		jnz	short loc_1102
		cmp	bx, 0FFFFh
		jz	short loc_1151
		jmp	short loc_110F
loc_1102:				
		cmp	ax, 4
		jnz	short loc_110F
		cmp	bx, [si+4]
		jnz	short loc_110F
		mov	bx, 0FFFFh
loc_110F:				
		inc	si
		lodsw
		mov	dl, [si]
		mov	dh, 0
		inc	si
		push	bx
		push	cx
		mov	bx, ds
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, ax
		adc	cx, dx
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		jmp	loc_10CB
loc_1151:				
		les	di, SBuf
		mov	bl, [si+4]
		mov	al, [si+5]
		mov	bh, 0
		mov	ah, 0
		cmp	x_status, 0
		jz	short loc_116F
		mov	al, x_pack
		mov	bl, x_tc
		mov	x_status, 0
loc_116F:				
		mov	es:[di+sbuffer.sample_rate], bx
		mov	es:[di+sbuffer.pack_type], ax
		mov	ax, [si+1]
		mov	dl, [si+3]
		mov	dh, 0
		sub	ax, 2
		sbb	dx, 0
		mov	es:[di+sbuffer.len_l], ax
		mov	es:[di+sbuffer.len_h], dx
		mov	dx, ds
		mov	ax, si
		push	bx
		push	cx
		mov	bx, dx
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, ax
		adc	cx, 0
		add	bx, 6
		adc	cx, 0
		mov	ax, bx
		and	ax, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	dx, bx
		pop	cx
		pop	bx
		mov	word ptr es:[di+sbuffer.mydata], ax
		mov	word ptr es:[di+(sbuffer.mydata+2)], dx
		mov	ax, 1
loc_11D5:				
		POP_F
		ret
index_VOC_blk	endp

register_sb     CPROC USES DS SI DI H:WORD,BufNum:WORD,SBuf:FAR PTR
		pushf
		cli
		cmp	buffer_mode,	0
		jnz	short loc_11FE
		push	cs
		call	near ptr stop_d_pb
		mov	buffer_mode,	1
loc_11FE:				
		mov	di, BufNum
		shl	di, 1
		lds	si, SBuf
		mov	ax, [si+sbuffer.pack_type]
		mov	buff_pack[di], ax
		mov	ax, [si+sbuffer.sample_rate]
		mov	buff_sample[di], ax
		les	bx, [si+sbuffer.mydata]
		mov	buff_data_o[di], bx
		mov	buff_data_s[di], es
		mov	ax, [si+sbuffer.len_l]
		mov	buff_len_l[di], ax
		mov	ax, [si+sbuffer.len_h]
		mov	buff_len_h[di], ax
		mov	ax, time
		inc	time
		mov	buff_time[di], ax
		mov	buff_status[di], 0
loc_1247:				
		POP_F
		ret
register_sb	endp 

get_sb_status   CPROC USES DS SI DI H:WORD,HBuffer:WORD
		pushf
		cli
		mov	bx, HBuffer
		shl	bx, 1
		mov	ax, buff_status[bx]
		cmp	ax, 4
		jnz	short loc_126D
		mov	ax, 0

loc_126D:				
		POP_F
		ret
get_sb_status	endp 

play_VOC_file   CPROC USES DS SI DI H:WORD,File:FAR PTR,Block:WORD
                LOCAL block_file:DWORD              
		pushf
		cli
		mov	xblk_status,	0
		push	cs
		call	near ptr stop_d_pb
		mov	buffer_mode,	0
		les	di, File
		mov	word ptr block_file, di
		mov	word ptr block_file+2, es
		mov	DAC_status, 3
		lds	si, block_file
		mov	ax, [si+14h]
		push	bx
		push	cx
		mov	bx, ds
		xor	cx, cx
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		add	bx, si
		adc	cx, 0
		add	bx, ax
		adc	cx, 0
		mov	si, bx
		and	si, 0Fh
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		shr	cx, 1
		rcr	bx, 1
		mov	ds, bx
		pop	cx
		pop	bx
		mov	word ptr block_ptr, si
		mov	word ptr block_ptr+2, ds
		cmp	Block, 0FFFFh
		jz	short loc_1311
loc_12F5:				
		push	cs
		call	near ptr block_type
		cmp	ax, 0
		jz	short loc_1318
		push	cs
		call	near ptr set_xblk
		push	cs
		call	near ptr marker_num
		mov	si, ax
		push	cs
		call	near ptr next_block
		cmp	si, Block
		jnz	short loc_12F5
loc_1311:				
		mov	DAC_status, 0
loc_1318:	
		POP_F			
		ret
play_VOC_file	endp

start_d_pb      CPROC USES DS ES SI DI H:WORD
		pushf
		cli
		cmp	playing, 0
		jz	short loc_133A
		jmp	loc_13BF
loc_133A:				
		cmp	buffer_mode,	0
		jz	short loc_139D
		push	cs
		call	near ptr next_buffer
		cmp	ax, 0FFFFh
		jz	short loc_13BF
		mov	DAC_status, 2
		mov	si, ax
		push	cs
		push	ax
		push	bp
		mov	bp, sp
		mov	word ptr [bp+2], offset	umss
		pop	bp
		push	ax
		push	cs
		call	near ptr process_buffer
		add	sp, 6
		mov	db_playing, si
		shl	si, 1
		mov	buff_status[si], 2
loc_1375:				
		mov	ax, cs
		mov	es, ax
		mov	di, offset umss
		mov	ax, 0
		call	gf1hook
		add	ax, 1
		mov	playing, ax
		jnz	short loc_13BF
		mov	DAC_status, 0
		mov	playing, 0
		jmp	short loc_13BF
loc_139D:				
		mov	stop_voc_mode, 0
		mov	DAC_status, 2
		push	cs
		push	ax
		push	bp
		mov	bp, sp
		mov	word ptr [bp+2], offset	umss
		pop	bp
		push	cs
		call	near ptr process_block
		add	sp, 4
		jmp	short loc_1375
loc_13BF:
		POP_F
		ret
start_d_pb	endp 

stop_d_pb       CPROC USES DS SI DI H:WORD
		pushf
		cli
		cmp	playing, 0
		jnz	short loc_13DE
		jmp	short loc_13EC
loc_13DE:				
		mov	cx, playing
		dec	cx
		mov	ax, 7
		call	gf1hook
loc_13EC:				
		mov	DAC_status, 0
		mov	buff_status,	3
		mov	buff_status+2, 3
		POP_F
		ret
stop_d_pb	endp

pause_d_pb      CPROC USES DS SI DI H:WORD
		pushf
		cli
		mov	ax, 5
		mov	cx, umss.um_priority
		call	gf1hook
		mov	DAC_status, 1
		POP_F
		ret
pause_d_pb	endp

cont_d_pb       CPROC USES DS SI DI H:WORD
		pushf
		cli
		cmp	DAC_status, 1
		mov	ax, 6
		mov	cx, umss.um_priority
		call	gf1hook
		POP_F
		ret
cont_d_pb	endp

get_VOC_status  CPROC USES DS SI DI H:WORD
		pushf
		cli
		mov	ax, DAC_status
		POP_F
		ret
get_VOC_status	endp 
IFDEF	BINARY_COMPATIBLE
		db 0Ch dup(0)
ENDIF
		end 
