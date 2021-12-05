;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;лл                                                                        лл
;лл   MPU401.INC                                                           лл
;лл                                                                        лл
;лл   IBM Audio Interface Library -- Roland MPU-401 I/O routines           лл
;лл                                                                        лл
;лл   Version 1.00 of 27-Sep-91: Initial version for AIL V2.0 release      лл
;лл                                                                        лл
;лл   8086 ASM source compatible with Turbo Assembler v2.0 or later        лл
;лл   Author: John Miles                                                   лл
;лл                                                                        лл
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;лл                                                                        лл
;лл   Copyright (C) 1991, 1992 Miles Design, Inc.                          лл
;лл                                                                        лл
;лл   Miles Design, Inc.                                                   лл
;лл   10926 Jollyville #308                                                лл
;лл   Austin, TX 78759                                                     лл
;лл   (512) 345-2642 / FAX (512) 338-9630 / BBS (512) 454-9990             лл
;лл                                                                        лл
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

                INCLUDE ultramid.inc

DATA_IO         dw ?                    ;IO_addr
STAT_COM        dw ?                    ;IO_addr+1

set_IO_parms    CPROTO IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
detect_device   CPROTO H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD 
send_byte       CPROTO DataByte:WORD
send_cmd        CPROTO CmdByte:WORD
reset_interface CPROTO 
init_interface  CPROTO 


;****************************************************************************
set_IO_parms    CPROC USES DS SI DI IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
                mov ax,[IO_ADDR]
                mov DATA_IO,ax
                inc ax
                mov STAT_COM,ax
                ret
set_IO_parms    ENDP

;****************************************************************************
detect_device   CPROC USES DS SI DI H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD  ;Attempt to detect MPU-401 card
                pushf
                cli
GF1_AIL_STR_SIZE	EQU		6
GF1_VECTORS		EQU		8
HOOK_STR_SIZE		EQU		8
		push	ds
		push	cs
		pop	ds
; Get the segment and offset for the GF1 hook calls
; Loop from vector 78 to 7f checking for the stamp.
; Set es to first vectors segment.
		mov	al,078h
		mov	cx,GF1_VECTORS
next_vector:
		mov	ah,035h
		int	21h
; es is segment of gf1 driver.
; di is Offset into GF1AIL.COM's vector stamp.
		mov	di,0103H

; ds:si is gf166.com string es:di is hook vectors'
		mov	si,offset chk_hook_str
		push	cx
		mov	cx,HOOK_STR_SIZE
		cld
		repe	cmpsb
		jcxz	vector_valid
; Setup for next vector check.
		pop	cx
		inc	al
		loop	next_vector
		jmp	gf1ail_not_found
vector_valid:
		pop	cx
		pop	ds
		mov	ah,035h
		int	21h
		mov     cs:hookoff, bx
		mov     cs:hookseg, es
		jmp	ok_detect
gf1ail_not_found:
		pop	ds
		mov	ax,0h
		jmp	bail_out
ok_detect:
                push DATA_IO              ;preserve current I/O address
                push STAT_COM
                INVOKE set_IO_parms,[IO_ADDR],[IRQ],[DMA],[DRQ]
                INVOKE reset_interface      ;attempt to reset card
                pop STAT_COM
                pop DATA_IO
bail_out:
                POP_F                     ;return AX=0 if not found
                ret
detect_device   ENDP

;****************************************************************************
send_byte       CPROC DataByte:WORD
		mov ax,TSR_MIDI_OUT
		mov ch,0h
                mov cl,BYTE PTR [DataByte]

		call cs:gf1hook

                ret
send_byte       ENDP

;****************************************************************************
send_cmd        CPROC CmdByte:WORD
                pushf
                cli

		mov ax,1
		POP_F
                ret
send_cmd        ENDP

;****************************************************************************
reset_interface CPROC USES DS SI DI                    ;Returns 1 if MPU interface available
                pushf                   ;don't allow interruption
                cli

                INVOKE send_cmd,0ffh    ;reset MPU-401 interface
                or ax,ax
                jne __exit_reset        ;(worked the first time)

                INVOKE send_cmd,0ffh    ;try again in case UART mode active

__exit_reset:   POP_F
                ret
reset_interface ENDP

;****************************************************************************
init_interface  CPROC USES DS SI DI                    ;Init MPU-401-compatible interface
                pushf                   ;don't allow interruption
                cli

                INVOKE send_cmd,03fh    ;assert UART mode

                POP_F
		ret

;****************************************************************************
init_interface  ENDP
