;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;лл                                                                        лл
;лл   MT32.INC                                                             лл
;лл                                                                        лл
;лл   IBM Audio Interface Library -- Roland MT-32-series MIDI interpreter  лл
;лл                                                                        лл
;лл   Version 1.00 of 27-Sep-91: Initial version for AIL V2.0 release      лл
;лл   Version 1.01 of 12-Mar-92: Bad seq handles rejected by get_request   лл
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

                ;
                ;Driver-specific configuration equates
                ;

MAX_REC_CHAN    equ 10                  ;Max channel recognized by synths
MAX_TRUE_CHAN   equ 9                   ;Max channel available for locking
MIN_TRUE_CHAN   equ 2                   ;Min channel # (1-based)

SYSEX_SIZE      equ 32                  ;Controller sysex queue size in bytes
SYSEX_Q_CNT     equ 3                   ;# of sysex controller queues
DEF_SYNTH_VOL   equ 90                  ;init vol=90% (avoid MT-32 distortion)
CLEAR_SYNTH     equ TRUE                ;TRUE to reset Roland on init/shutdown
ADJUST_PART_RSV equ TRUE                ;TRUE to set AIL partial reserve

                ;
                ;Driver Description Table (DDT)
                ;Returned by describe_driver() proc
                ;

DDT             LABEL WORD
min_API_version dw 200                  ;Minimum API version required = 2.00
drvr_type       dw 3                    ;Type 3: XMIDI driver
data_suffix     db 'MT',0,0             ;Native data/instrument file suffix
device_name_o   dw OFFSET devnames      ;Pointer to list of supported devices
device_name_s   dw ?
default_IO      LABEL WORD
                IFDEF MPU401
                dw -1h                 ;Factory default I/O parameters
                ELSEIFDEF SBMIDI
                dw -1h
                ENDIF
default_IRQ     dw -1
default_DMA     dw -1
default_DRQ     dw -1
service_rate    dw QUANT_RATE           ;Typically 120 calls/second 
display_size    dw 0                    ;20 char LCD display (MT-32)

devnames        db 'Advanced Gravis UltraSound Card', 0
                db 0                    ;0 to end list of device names

                ;
                ;Default setup values & constants
                ;

NUM_TIMBS       equ 64                  ;# of RAM timbres

SYSEX_BLK_SIZE  = (FINAL_BYTE_1 - START_MSB_1) + 1
SYSEX_RANGE_BEG = START_MSB_1
SYSEX_RANGE_END = SYSEX_RANGE_BEG + (SYSEX_BLK_SIZE * SYSEX_Q_CNT) - 1

                ;
                ;Misc. data
                ;

patch_bank      db 128 dup (?)

chksum          dw ?
string_buf      db 32 dup (?)

sysex_queues    db SYSEX_SIZE*SYSEX_Q_CNT dup (?)

M_ad            db SYSEX_Q_CNT dup (?)
K_ad            db SYSEX_Q_CNT dup (?)
L_ad            db SYSEX_Q_CNT dup (?)
queue_ptrs      db SYSEX_Q_CNT dup (?)

note_event_l    dw ?                            ;used for LRU counting
note_event_h    dw ?
timb_hist_l     dw NUM_TIMBS dup (?)            ;last note event count for LRU
timb_hist_h     dw NUM_TIMBS dup (?)
timb_bank       db NUM_TIMBS dup (?)            ;GTR bank
timb_num        db NUM_TIMBS dup (?)            ;GTR #
timb_attribs    db NUM_TIMBS dup (?)            ;bit 7=in use 6=protected

chan_timbs      db NUM_CHANS dup (?)            ;indexes used by channels 1-16
                                                ;(-1 if internal/uninit'd)

MIDI_bank       db NUM_CHANS dup (?)            ;Patch Bank Select values
MIDI_program    db NUM_CHANS dup (?)            ;program change # / channel

                IFDEF MPU401
                INCLUDE mpu401.inc      ;Roland MPU-401-compatible interface
                ENDIF

                IFDEF SBMIDI
                INCLUDE sbmidi.inc      ;Sound Blaster MIDI port
                ENDIF

reset_synth     	CPROTO                  
init_synth      	CPROTO 
add_sysex_addr  	CPROTO Addend:WORD,MSB:WORD,KSB:WORD,LSB:WORD
send_MIDI_sysex 	CPROTO Src:FAR PTR,XType:WORD,Len:WORD  
sysex_wait      	CPROTO Delay:WORD             
write_system    	CPROTO Index:WORD,Value:WORD  
write_rhythm_setup 	CPROTO Keynum:WORD,Offs:WORD,Value:WORD 
write_patch     	CPROTO Patch:WORD,Index:WORD,Value:WORD,MySize:WORD  
send_MIDI_message 	CPROTO Stat:WORD,D1:WORD,D2:WORD       
index_timbre    	CPROTO GNum:WORD             
setup_patch     	CPROTO Patch:WORD,Bank:WORD         
describe_driver 	CPROTO H:WORD,IntRateProc:FAR PTR   
send_sysex_msg  	CPROTO H:WORD,AddrA:WORD,AddrB:WORD,AddrC:WORD,MyData:FAR PTR,MySize:WORD,MyWait:WORD
write_display   	CPROTO H:WORD,String:FAR PTR  
send_cv_msg     	CPROTO H:WORD,Stat:WORD,D1:WORD,D2:WORD   
protect_timbre  	CPROTO H:WORD,Bank:BYTE,Num:BYTE
unprotect_timbre 	CPROTO H:WORD,Bank:BYTE,Num:BYTE        
timbre_status   	CPROTO H:WORD,Bank:BYTE,Num:BYTE        
get_cache_size  	CPROTO H:WORD
define_cache    	CPROTO H:WORD,MyAddr:FAR PTR,MySize:WORD
get_request     	CPROTO H:WORD,Sequence:WORD
install_timbre  	CPROTO H:WORD,Bank:BYTE,Num:BYTE,MyAddr:FAR PTR

;****************************************************************************
;*                                                                          *
;*  MIDI interpreter and related procedures                                 *
;*                                                                          *
;****************************************************************************

reset_synth     CPROC USES DS SI DI                  
                LOCAL chan:WORD, cont_chg:WORD                ;Channel num
                pushf                
                cli

		mov chan, 15
__reset_loop:
		mov ax, 0b0h
		or  ax, chan
		mov cont_chg, ax
                INVOKE send_MIDI_message,cont_chg,121,0 ; reset all controllers
		INVOKE send_MIDI_message,cont_chg,120,0  ; all sounds off
		INVOKE send_MIDI_message,cont_chg,100,0  ; RPN 0 = 0
		INVOKE send_MIDI_message,cont_chg,101,0  ; select PBS
		INVOKE send_MIDI_message,cont_chg,6,2  ; pitch bend sensitivity
		INVOKE send_MIDI_message,cont_chg,38,0  ; pitch bend sensitivity
		sub chan,1
		jnc __reset_loop

                POP_F
                ret
reset_synth     ENDP

;****************************************************************************
init_synth      CPROC USES DS SI DI
		LOCAL chan:WORD, cont_chg:WORD
                pushf           
                cli

		mov chan, 15
__reset_loop:
		mov ax, 0b0h
		or  ax, chan
		mov cont_chg, ax
                INVOKE send_MIDI_message,cont_chg,121,0 ; reset all controllers
		INVOKE send_MIDI_message,cont_chg,120,0  ; all sounds off
		INVOKE send_MIDI_message,cont_chg,100,0  ; RPN 0 = 0
		INVOKE send_MIDI_message,cont_chg,101,0  ; select PBS
		INVOKE send_MIDI_message,cont_chg,6,2  ; pitch bend sensitivity
		INVOKE send_MIDI_message,cont_chg,38,0  ; pitch bend sensitivity
		sub chan,1
		jnc __reset_loop

                mov bx,0
__init_sysex:   mov queue_ptrs[bx],0
                inc bx
                cmp bx,SYSEX_Q_CNT
                jne __init_sysex

                mov note_event_l,0
                mov note_event_h,0

                mov di,0
__init_tcache:  mov timb_attribs[di],00000000b
                inc di
                cmp di,NUM_TIMBS
                jne __init_tcache

                mov di,0
__init_tchans:  mov chan_timbs[di],-1
                mov MIDI_program[di],-1
                mov MIDI_bank[di],0
                inc di
                cmp di,NUM_CHANS
                jne __init_tchans

                mov di,0
__init_patches: mov patch_bank[di],0
                inc di
                cmp di,128
                jne __init_patches

                POP_F
                ret
init_synth      ENDP

;****************************************************************************
add_sysex_addr  CPROC USES DS SI DI Addend:WORD,MSB:WORD,KSB:WORD,LSB:WORD
                mov al,BYTE PTR[LSB]
                mov bl,BYTE PTR[KSB]
                mov cl,BYTE PTR[MSB]
                mov ah,0
                mov bh,0
                mov ch,0

                add ax,[Addend]

__chk_l:        cmp ax,80h
                jb __chk_k
                sub ax,80h
                inc bx
                jmp __chk_l

__chk_k:        cmp bx,80h
                jb __store_sum
                sub bx,80h
                inc cx
                jmp __chk_k

__store_sum:    mov ah,bl
                mov dl,cl
                mov dh,0
                ret     
add_sysex_addr  ENDP

;****************************************************************************
send_MIDI_sysex CPROC USES DS SI DI Src:FAR PTR,XType:WORD,Len:WORD  ;Send MIDI System Exclusive message
                cld

                cmp [XType],0f0h         ;F0 type?
                jne __get_msg_len       ;no, don't send explicit F0

                INVOKE send_byte,0f0h

__get_msg_len:  lds si,[Src]
                mov cx,[Len]            ;get length
                jcxz __exit

__send_bytes:   push cx
                lodsb
                INVOKE send_byte,ax
                pop cx
                loop __send_bytes

__exit:         ret
send_MIDI_sysex ENDP

;****************************************************************************
sysex_wait      CPROC USES DS SI DI Delay:WORD              ;Delay after System Exclusive message
                                        ;transmissions
                mov ax,40h              ;wait n VBL periods (14 ms/period min, 
                mov ds,ax               ;requires CGA/EGA/VGA/XGA video)

                mov dx,ds:[63h]         ;get CRTC Address register location
                add dl,6                ;get CRTC Status register location

                mov cx,[Delay]
                jcxz __exit

__sync_1:       in al,dx            
                test al,8
                jz __sync_1             

__sync_2:       in al,dx
                test al,8
                jnz __sync_2

                loop __sync_1

__exit:         ret
sysex_wait      ENDP

;****************************************************************************
write_system    CPROC USES DS SI DI Index:WORD,Value:WORD          ;Write value to System area
                 			                           ;(Warning: No delay!)
		mov ax,[Index]
		lea bx,[Value]  
                INVOKE send_sysex_msg,0,10h,0,ax,ss::bx,1,0      
                ret
write_system    ENDP

;****************************************************************************
write_rhythm_setup CPROC USES DS SI DI Keynum:WORD,Offs:WORD,Value:WORD    ;Write value to Rhythm Setup area
		mov ax,[Keynum]
		sub ax,24
		shl ax,1
		shl ax,1
		add ax,[Offs]
		INVOKE add_sysex_addr,ax,3,1,16

		mov cl,ah
		lea bx,[Value]
		
                INVOKE send_sysex_msg,0,dx,cx,ax,ss::bx,1,4
                ret
write_rhythm_setup ENDP

;****************************************************************************
write_patch     CPROC USES DS SI DI Patch:WORD,Index:WORD,Value:WORD,MySize:WORD       ;Write byte or word to Patch area
                mov ax,[Patch]
                shl ax,1
                shl ax,1
                shl ax,1
                add ax,[Index]
                INVOKE add_sysex_addr,ax,5,0,0

		mov cl,ah		
                lea bx,[Value]

                INVOKE send_sysex_msg,0,dx,cx,ax,ss::bx,[MySize],2
__exit:         ret
write_patch     ENDP

;****************************************************************************
send_MIDI_message CPROC USES DS SI DI Stat:WORD,D1:WORD,D2:WORD       
                LOCAL op:WORD                ;Send MIDI Channel Voice message
                mov si,[D1]
                and si,0ffh             ;SI=data 1 / controller #
                mov di,[Stat]
                mov ax,di               
                and di,00fh             ;DI=channel

                and ax,0f0h             ;AX=status
                cmp ax,0b0h             
                je __go_cc
                cmp ax,0c0h
                je __prg_change
                cmp ax,090h             ;Note On (or Note Off)?
                jne __send              

                add note_event_l,1      ;yes, update timbre cache LRU counters
                adc note_event_h,0      
                mov bh,0
                mov bl,chan_timbs[di]
                cmp bl,-1
                je __send       
                shl bx,1
                mov ax,note_event_l
                mov dx,note_event_h
                mov timb_hist_l[bx],ax
                mov timb_hist_h[bx],dx

__send:         mov di,[Stat]
                INVOKE send_byte,di
                INVOKE send_byte,si
                and di,0f0h
                cmp di,0c0h
                je __exit
                cmp di,0d0h
                je __exit
                INVOKE send_byte,[D2]
__exit:         ret

__go_cc:        jmp __ctrl_change

__prg_change:   mov ax,si               ;log current patch for channel
                mov MIDI_program[di],al
                mov ah,MIDI_bank[di]
                cmp ah,patch_bank[si]   ;changing patch's timbre bank?
                je __set_index          ;no, just log index & send message

                push ax                 ;else send sysex message to associate
                mov al,ah               ;patch with timbre
                INVOKE setup_patch,si,ax
                pop ax

__set_index:    INVOKE index_timbre,ax
                mov chan_timbs[di],al
                jmp __send

__ctrl_change:  cmp si,SYSEX_RANGE_BEG
                jb __send
                cmp si,SYSEX_RANGE_END
                jbe __sysex
                cmp si,PATCH_REVERB
                je __p_rev
                cmp si,PATCH_BENDER
                je __p_b_range
                cmp si,REVERB_MODE
                je __rev_mode
                cmp si,REVERB_TIME
                je __rev_time
                cmp si,REVERB_LEVEL
                je __rev_lvl
                cmp si,PATCH_BANK_SEL
                je __t_bank
		cmp si,RHYTHM_KEY_TIMB
		je __r_t_sel
                cmp si,TIMBRE_PROTECT
                je __t_prot
                
                cmp si,CHAN_LOCK                ;(lowest XMIDI control #)
                jb __send                       
                cmp si,SEQ_INDEX                ;(highest XMIDI control #)
                ja __send                       ;keep XMIDI controls out of 
                jmp __exit                      ;MIDI data stream for speed

__t_prot:       mov bl,chan_timbs[di]
                cmp bl,-1
                je __exit
                mov bh,0
                mov al,timb_attribs[bx]
                and al,10111111b
                cmp [D2],64
                jl __tprot
                or al,01000000b
__tprot:        mov timb_attribs[bx],al
                jmp __exit

__t_bank:       mov al,BYTE PTR [D2]
                mov MIDI_bank[di],al
                jmp __exit

__p_rev:        mov al,MIDI_program[di]
                mov ah,0
                cmp al,-1
                je __exit
                push ax
                INVOKE write_patch,ax,6,[D2],1
                or di,0c0h
                INVOKE send_byte,di
                pop ax
                INVOKE send_byte,ax
                jmp __exit

__p_b_range:    mov al,MIDI_program[di]
                mov ah,0
                cmp al,-1
                je __exit
                push ax
                INVOKE write_patch,ax,4,[D2],1
                or di,0c0h
                INVOKE send_byte,di
                pop ax
                INVOKE send_byte,ax
                jmp __exit

__rev_mode:     INVOKE write_system,1,[D2]
                jmp __exit
__rev_time:     INVOKE write_system,2,[D2]
                jmp __exit
__rev_lvl:      INVOKE write_system,3,[D2]
                jmp __exit

__r_t_sel:      mov al,chan_timbs[di]
                cmp al,-1
                je __exit
                mov ah,0
		INVOKE write_rhythm_setup,[D2],0,ax
		jmp __exit

__sysex:        sub si,SYSEX_RANGE_BEG
                mov ax,si
                mov cx,SYSEX_BLK_SIZE
                mov dx,0
                div cx    
                mov op,dx
                mov bx,ax
                mov al,BYTE PTR [D2]             ;BX=queue #, AL=data, DX=operation
                cmp dx,0
                je __set_MSB
                cmp dx,1
                je __set_KSB
                cmp dx,2
                je __set_LSB

                mov ax,SYSEX_SIZE       ;BX = queue #
                mul bx
                add ax,OFFSET sysex_queues
                mov di,ax               ;DI = base queue address
                add al,queue_ptrs[bx]
                adc ah,0
                mov si,ax               ;SI = pointer to last byte
                mov al,BYTE PTR [D2]
                mov cs:[si],al

                cmp op,3
                je __bump_ptr           ;inc ptr and exit if not final byte

__send_queue:   mov al,queue_ptrs[bx]   ;else send message
                mov ah,0
                inc ax
                mov si,ax               ;SI = len
                xchg di,bx              ;DI = queue #, CS:BX = base address

                INVOKE send_sysex_msg,0,M_ad[di],K_ad[di],L_ad[di],cs::bx,si,0
                cmp op,3                ;was this an overflow dump?
                jne __address_byte      

                INVOKE sysex_wait,4     ;yes, do an automatic wait of 4
                jmp __overflowed        ;VBL intervals

__address_byte: dec si                  ;SI=len-1
__overflowed:   INVOKE add_sysex_addr,si,WORD PTR M_ad[di],WORD PTR K_ad[di], WORD PTR L_ad[di]
               
                mov L_ad[di],al         ;add (qlen-1) to sysex start address,
                mov K_ad[di],ah         ;so future Final Byte controllers will
                mov M_ad[di],dl         ;address same byte (unless overflowed)

                mov queue_ptrs[di],0    ;flush queue
                jmp __exit

__bump_ptr:     cmp queue_ptrs[bx],SYSEX_SIZE-1
		jae __send_queue	;dump queue if overflow occurs
                inc queue_ptrs[bx]
                jmp __exit

__set_MSB:      mov M_ad[bx],al
                jmp __exit
__set_KSB:      mov K_ad[bx],al
                jmp __exit
__set_LSB:      mov L_ad[bx],al
                jmp __exit

send_MIDI_message ENDP

;****************************************************************************
index_timbre    CPROC USES DS SI DI GNum:WORD               ;Get global timbre's local index 0-63 
                mov si,0
                mov ax,[GNum]   
__find_gnum:    test timb_attribs[si],10000000b
                jz __find_next          ;(timbre unused)
                cmp timb_bank[si],ah
                jne __find_next
                cmp timb_num[si],al
                je __found
__find_next:    inc si
                cmp si,NUM_TIMBS
                jb __find_gnum

                mov si,-1               ;return -1 if timbre not loaded

__found:        mov ax,si
                ret
index_timbre    ENDP

;****************************************************************************
setup_patch     CPROC USES DS SI DI Patch:WORD,Bank:WORD         
                mov bl,BYTE PTR [Patch]
                mov bh,0
                mov ah,BYTE PTR [Bank]
                mov patch_bank[bx],ah   ;log timbre bank # for patch

                cmp ah,0
                je __bank_0             ;bank 0 = built-in Roland timbres

                mov al,bl
                INVOKE index_timbre,ax  ;see if timbre loaded
                cmp ax,-1
                je __bank_0             ;timbre not loaded, use default

                mov ah,al               ;select TIMBRE NUMBER 0-63
                mov al,2                ;select MEMORY (timbre group 2)
                jmp __send

__bank_0:       mov ah,BYTE PTR [Patch]          ;restore default Roland timbre...
                mov al,0
                cmp ah,64               ;set GROUP A if patch # < 64
                sbb al,-1               ;set GROUP B if patch # >= 64
                and ah,63               ;set TIMBRE NUMBER 0-63
			
__send:         INVOKE write_patch,[Patch],0,ax,2

__exit:         ret                   
setup_patch     ENDP            

;****************************************************************************
;*                                                                          *
;*  Public (API-accessible) procedures                                      *
;*                                                                          *
;****************************************************************************

describe_driver CPROC USES DS SI DI H:WORD,IntRateProc:FAR PTR      ;Return far ptr to DDT
                pushf
                cli

                mov dx,cs
                mov device_name_s,dx
                lea ax,DDT

                POP_F
                ret
describe_driver ENDP

;****************************************************************************
send_sysex_msg  CPROC USES DS SI DI H:WORD,AddrA:WORD,AddrB:WORD,AddrC:WORD,MyData:FAR PTR,MySize:WORD,MyWait:WORD
                pushf
                cli

                INVOKE send_byte,0f0h   ;transmit Roland MT-32 header
                INVOKE send_byte,041h
                INVOKE send_byte,010h
                INVOKE send_byte,016h
                INVOKE send_byte,012h

                INVOKE send_byte,[AddrA]
                INVOKE send_byte,[AddrB]
                INVOKE send_byte,[AddrC]

                mov al,BYTE PTR [AddrA]          ;init checksum
                mov ah,0
                add al,BYTE PTR [AddrB]
                adc ah,0
                add al,BYTE PTR [AddrC]
                adc ah,0
                mov chksum,ax

                les di,[MyData]           ;send each message byte
                mov si,[MySize]
__send_data:    or si,si
                jz __send_chksum
                dec si
                xor ah,ah
                mov al,es:[di]
                inc di
                add chksum,ax
                INVOKE send_byte,ax
                jmp __send_data

__send_chksum:  mov ax,chksum           
                and ax,7fh
                sub al,80h
                neg al
                and ax,7fh
                INVOKE send_byte,ax     ;send the checksum byte

                INVOKE send_byte,0f7h   ;send EOX terminator

                INVOKE sysex_wait,[MyWait]

                POP_F
                ret
send_sysex_msg  ENDP

;****************************************************************************
write_display   CPROC USES DS SI DI H:WORD,String:FAR PTR   ;Write string to display (unless NULL)
                pushf
                cli

                cld
                lds si,[String]         ;bail out if null string
                mov ax,ds
                cmp ax,0
                je __end_write

                push cs                 ;pad string with spaces
                pop es
                lea di,string_buf
                mov cx,display_size
                mov al,' '
                rep stosb

                lea di,string_buf       ;write up to /display_size/ characters
                mov cx,display_size
__pad_string:   lodsb
                cmp al,0
                je __show_it
                stosb
                loop __pad_string

__show_it:      INVOKE send_sysex_msg,0,20h,00h,00h,ADDR string_buf,display_size,4

__end_write:    POP_F
                ret
write_display   ENDP

;****************************************************************************
send_cv_msg     CPROC USES DS SI DI H:WORD,Stat:WORD,D1:WORD,D2:WORD       ;Send an explicit Channel Voice msg
                pushf
                cli

                INVOKE send_MIDI_message,[Stat],[D1],[D2]

                POP_F
                ret
send_cv_msg     ENDP

;****************************************************************************
protect_timbre  CPROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE
                pushf
                cli

                mov al,[Num]
                mov ah,[Bank]

                cmp ax,-1
                je __prot_all

                INVOKE index_timbre,ax
                cmp ax,-1
                je __exit               ;timbre not loaded, can't protect it

                mov bx,ax
                or timb_attribs[bx],01000000b
                jmp __exit

__prot_all:     mov bx,0
__prot_timb:    or timb_attribs[bx],01000000b
                inc bx
                cmp bx,NUM_TIMBS
                jb __prot_timb

__exit:         POP_F
                ret
protect_timbre  ENDP

;****************************************************************************
unprotect_timbre CPROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE          ;Allow a timbre to be replaced
                pushf 
                cli

                mov al,[Num]
                mov ah,[Bank]

                cmp ax,-1
                je __unprot_all

                INVOKE index_timbre,ax
                cmp ax,-1
                je __exit               ;timbre not loaded, can't unprotect it

                mov bx,ax
                and timb_attribs[bx],10111111b
                jmp __exit

__unprot_all:   mov bx,0
__unprot_timb:  and timb_attribs[bx],10111111b
                inc bx
                cmp bx,NUM_TIMBS
                jb __unprot_timb

__exit:         POP_F
                ret
unprotect_timbre ENDP

;****************************************************************************
timbre_status   CPROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE          ;Return 0 if timbre not resident
                pushf 
                cli

                mov al,[Num]
                mov ah,[Bank]
                cmp ah,0                ;Roland driver reports all bank 0
                je __OK                 ;(default) and bank 127 (rhythm) 
                cmp ah,127              ;timbres present
                je __OK                 

                INVOKE index_timbre,ax

__OK:           inc ax                  ;0 if -1, else local cache index

                POP_F
                ret
timbre_status   ENDP

;****************************************************************************
get_cache_size  CPROC USES DS SI DI H:WORD
                pushf
                cli

                mov ax,0                ;no resident cache for MT-32

                POP_F
                ret
get_cache_size  ENDP

;****************************************************************************
define_cache    CPROC USES DS SI DI H:WORD,MyAddr:FAR PTR,MySize:WORD
                ret
define_cache    ENDP

;****************************************************************************
get_request     CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __no_request
                lds si,sequence_state[si]

                cmp WORD PTR [si].state_table.TIMB+2,0
                je __no_request         ;no requested timbres, exit

                lds si,[si].state_table.TIMB        ;make sure TIMB chunk is present
                cmp WORD PTR [si],'IT'
                jne __no_request        ;if not, no requests are possible
                cmp WORD PTR [si+2],'BM'
                jne __no_request

                add si,8
                mov di,[si]             ;get TIMB.cnt
__chk_index:    add si,2
                mov ax,[si]
                cmp ah,0                ;bank 0 reserved for Roland built-in
                je __next_index         ;timbres.... don't request
                cmp ah,127              ;bank 127 reserved for melodic-mode 
                je __next_index         ;rhythm sounds.... don't request
                INVOKE index_timbre,[si]
                cmp ax,-1               ;timbre in local cache?
                je __request            ;no, request it
__next_index:   dec di
                jne __chk_index
                jmp __no_request        ;all requested timbres loaded, exit

__request:      mov ax,[si]             ;else return request: AL=num, AH=bank
                jmp __exit

__no_request:   mov ax,-1
                
__exit:         POP_F
                ret
get_request     ENDP

;****************************************************************************
install_timbre  CPROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE,MyAddr:FAR PTR
                LOCAL sys_seg:WORD,sys_dest:WORD
                pushf
                cli

                mov al,[Num]
                mov ah,[Bank]

                cmp ah,0                ;bank 0 reserved for built-in default
                je __set_patch          ;timbres -- restore normal patch
                cmp ah,127              ;bank 127 reserved for melodic mode
                je __exit               ;rhythm sounds -- don't install

                INVOKE index_timbre,ax
                cmp ax,-1
                jne __set_patch         ;timbre already resident, index it

                mov ax,WORD PTR [MyAddr]
                or ax,WORD PTR [MyAddr+2]
                jz __exit

                mov si,0                ;else look for an empty timbre slot
__find_free:    test timb_attribs[si],10000000b
                jz __found
                inc si
                cmp si,NUM_TIMBS
                jb __find_free

                mov si,0                ;no free timbre slots, replace least-
                mov bx,0                ;recently-used unprotected timbre
                mov cx,-1
                mov ax,-1
                mov dx,-1
__find_LRU:     test timb_attribs[si],01000000b
                jnz __next_LRU          ;(timbre protected)
                cmp timb_hist_h[bx],dx
                ja __next_LRU
                jb __log_LRU
                cmp timb_hist_l[bx],ax
                ja __next_LRU
__log_LRU:      mov ax,timb_hist_l[bx]
                mov dx,timb_hist_h[bx]
                mov cx,si
__next_LRU:     add bx,2
                inc si
                cmp si,NUM_TIMBS
                jb __find_LRU

                cmp cx,-1               ;if no unprotected timbre slots, exit 
                je __exit               ;without installing new timbre

                mov si,cx               ;else SI = LRU timbre index

__found:        mov bx,si               ;found free/LRU timbre, update its
                shl bx,1                ;timestamp and replace it
                mov ax,note_event_l      
                mov dx,note_event_h     
                add note_event_l,1      
                adc note_event_h,0      
                mov timb_hist_l[bx],ax  
                mov timb_hist_h[bx],dx  

                mov al,[Num]            ;AL=num, AH=bank
                mov ah,[Bank]
                mov timb_num[si],al     ;record global # in slot
                mov timb_bank[si],ah    ;mark timbre "in use/unprotected"
                mov timb_attribs[si],10000000b                  

                cmp WORD PTR [MyAddr+2],0
                je __exit               ;(NULL pointer = placeholder)

                les di,[MyAddr]
                add di,2                ;skip timbre length prefix (norm. $F6)

                mov ax,si               ;set up to send timbre dump to Roland
                shl ax,1                ;8,AX,00 = MT-32 address MSB,KSB,LSB

                mov sys_seg,es          ;send common parameter
                mov sys_dest,ax
;                INVOKE send_sysex_msg,0,8,sys_dest,0,di,sys_seg,0eh,3
                INVOKE send_sysex_msg,0,8,sys_dest,0,es::di,0eh,3
                mov es,sys_seg 
                add di,0eh              ;send partial parameter #1
;                INVOKE send_sysex_msg,0,8,sys_dest,0eh,di,sys_seg,3ah,3
                INVOKE send_sysex_msg,0,8,sys_dest,0eh,es::di,3ah,3
                mov es,sys_seg 
                add di,3ah              ;send partial parameter #2
;                INVOKE send_sysex_msg,0,8,sys_dest,48h,di,sys_seg,3ah,3
                INVOKE send_sysex_msg,0,8,sys_dest,48h,es::di,3ah,3
                mov es,sys_seg 
                add di,3ah              ;send partial parameter #3
                inc sys_dest
;                INVOKE send_sysex_msg,0,8,sys_dest,2,di,sys_seg,3ah,3
                INVOKE send_sysex_msg,0,8,sys_dest,2,es::di,3ah,3
                mov es,sys_seg 
                add di,3ah              ;send partial parameter #4
;                INVOKE send_sysex_msg,0,8,sys_dest,3ch,di,sys_seg,3ah,3
                INVOKE send_sysex_msg,0,8,sys_dest,3ch,es::di,3ah,3
                mov es,sys_seg 
__set_patch:    INVOKE setup_patch,WORD PTR [Num],WORD PTR [Bank]

__exit:         POP_F
	  	ret
install_timbre  ENDP
