;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;лл                                                                        лл
;лл   MMASTER.INC                                                          лл
;лл                                                                        лл
;лл   IBM Audio Interface Library -- ASC MediaMaster MIDI interpreter      лл
;лл                                                                        лл
;лл   Version 1.00 of  4-Jun-92: Initial version                           лл
;лл                                                                        лл
;лл   8086 ASM source compatible with Turbo Assembler v2.0 or later        лл
;лл   Author: John Miles                                                   лл
;лл                                                                        лл
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;лл                                                                        лл
;лл   Copyright (C) 1992 Miles Design, Inc.                                лл
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

MAX_REC_CHAN    equ 16                  ;Max channel recognized by synths
MAX_TRUE_CHAN   equ 9                   ;Max channel available for locking
MIN_TRUE_CHAN   equ 2                   ;Min channel # (1-based)

DEF_SYNTH_VOL   equ 100                 ;init vol=100%
CLEAR_SYNTH     equ TRUE                ;TRUE to reset on init/shutdown

                ;
                ;Driver Description Table (DDT)
                ;Returned by describe_driver() proc
                ;

DDT             LABEL WORD
min_API_version dw 200                  ;Minimum API version required = 2.00
drvr_type       dw 3                    ;Type 3: XMIDI driver
data_suffix     db 'ESQ',0              ;Native data/instrument file suffix
device_name_o   dw OFFSET devnames      ;Pointer to list of supported devices
device_name_s   dw ?
default_IO      dw 338h                 ;Factory default I/O parameters
default_IRQ     dw 3
default_DMA     dw 1
default_DRQ     dw -1
service_rate    dw QUANT_RATE           ;Typically 120 calls/second 
display_size    dw 0

devnames        db 'ASC MediaMaster(TM) or 100% compatible',0
                db 0                    ;0 to end list of device names

                ;
                ;Default setup values & constants
                ;

                ;
                ;Misc. data
                ;

patch_bank      db 128 dup (?)

note_event_l    dw ?                            ;used for LRU counting
note_event_h    dw ?

chan_timbs      db NUM_CHANS dup (?)            ;indexes used by channels 1-16
                                               ;(-1 if internal/uninit'd)
MIDI_bank       db NUM_CHANS dup (?)            ;Patch Bank Select values
MIDI_program    db NUM_CHANS dup (?)            ;program change # / channel

ECSR            dw ?                            ;Emulation Control/Status Reg
EDR             dw ?                            ;Emulation Data Reg

set_IO_parms      PROTO IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
detect_device     PROTO H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
send_byte         PROTO DataByte:BYTE
reset_interface   PROTO 
sysex_wait        PROTO Delay:WORD
reset_synth       PROTO 
init_synth        PROTO 
send_MIDI_message PROTO Stat:BYTE,D1:BYTE,D2:BYTE   
describe_driver   PROTO H:WORD,IntRateProc:FAR PTR  
send_sysex_msg    PROTO H:WORD,AddrA:BYTE,AddrB:BYTE,AddrC:BYTE,MyData:FAR PTR,MySize:WORD,MyWait:WORD
write_display     PROTO H:WORD,String:FAR PTR  
send_cv_msg       PROTO H:WORD,Stat:WORD,D1:WORD,D2:WORD 
protect_timbre    PROTO H:WORD,Bank:BYTE,Num:BYTE    
unprotect_timbre  PROTO H:WORD,Bank:BYTE,Num:BYTE    
timbre_status     PROTO H:WORD,Bank:BYTE,Num:BYTE    
get_cache_size    PROTO H:WORD
define_cache      PROTO H:WORD,MyAddr:FAR PTR,MySize:WORD
get_request       PROTO H:WORD,Sequence:WORD
install_timbre    PROTO H:WORD,Bank:BYTE,Num:BYTE,MyAddr:FAR PTR

;****************************************************************************
;*                                                                          *
;*  MediaMaster 6850 I/O routines                                           *
;*                                                                          *
;****************************************************************************

set_IO_parms    PROC USES DS SI DI IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
                mov ax,[IO_ADDR]
                mov ECSR,ax
                inc ax
                mov EDR,ax
                ret
set_IO_parms    ENDP

;****************************************************************************
detect_device   PROC H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
                mov ax,1
                ret
detect_device   ENDP

;****************************************************************************
send_byte       PROC DataByte:BYTE
                mov dx,ECSR
__wait_CTS:     in al,dx
                test al,2
                je __wait_CTS

                mov dx,EDR
                mov al,[DataByte]
                out dx,al
                ret
send_byte       ENDP

;****************************************************************************
reset_interface PROC USES DS SI DI
                pushf
                cli
                
                mov dx,ECSR
                mov al,3                ;reset port
                mov cx,8
__send_reset:   out dx,al
                loop __send_reset

                call sysex_wait C,1

                mov dx,ECSR
                mov al,15h              ;normal operation, IRQ's disabled
                out dx,al

                POP_F
                ret
reset_interface ENDP

;****************************************************************************
;*                                                                          *
;*  MIDI interpreter and related procedures                                 *
;*                                                                          *
;****************************************************************************

sysex_wait      PROC USES DS SI DI Delay:WORD
     ;Delay after System Exclusive message transmissions
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
reset_synth     PROC USES DS SI DI
                pushf                
                cli

                POP_F
                ret
reset_synth     ENDP

;****************************************************************************
init_synth      PROC USES DS SI DI
                pushf           
                cli

                mov note_event_l,0
                mov note_event_h,0

                mov di,0
__init_tchans:  mov MIDI_program[di],-1
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
send_MIDI_message PROC USES DS SI DI Stat:BYTE,D1:BYTE,D2:BYTE     ;Send MIDI Channel Voice message
                mov si,WORD PTR [D1]
                and si,0ffh             ;SI=data 1 / controller #
                mov di,WORD PTR [Stat]
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

__send:         mov di,WORD PTR [Stat]
                call send_byte C,di
                call send_byte C,si
                and di,0f0h
                cmp di,0c0h
                je __exit
                cmp di,0d0h
                je __exit
                call send_byte C,WORD PTR [D2]
__exit:         ret

                JUMPS

__go_cc:        jmp __ctrl_change

__prg_change:   jmp __send

__ctrl_change:  cmp si,PATCH_BANK_SEL
                je __t_bank
                
                cmp si,CHAN_LOCK                ;(lowest XMIDI control #)
                jb __send                       
                cmp si,SEQ_INDEX                ;(highest XMIDI control #)
                ja __send                       ;keep XMIDI controls out of 
                jmp __exit                      ;MIDI data stream for speed

__t_bank:       mov al,[D2]
                mov MIDI_bank[di],al
                jmp __exit
send_MIDI_message ENDP

;****************************************************************************
;*                                                                          *
;*  Public (API-accessible) procedures                                      *
;*                                                                          *
;****************************************************************************

describe_driver PROC USES DS SI DI H:WORD,IntRateProc:FAR PTR   ;Return far ptr to DDT
                pushf
                cli

                mov dx,cs
                mov device_name_s,dx
                lea ax,DDT

                POP_F
                ret
describe_driver ENDP

;****************************************************************************
send_sysex_msg  PROC H:WORD,AddrA:BYTE,AddrB:BYTE,AddrC:BYTE,MyData:FAR PTR,MySize,MyWait:WORD
                ret
send_sysex_msg  ENDP

;****************************************************************************
write_display   PROC H:WORD,String:FAR PTR   ;Write string to display (unless NULL)
                ret
write_display   ENDP

;****************************************************************************
send_cv_msg     PROC USES DS SI DI H:WORD,Stat:WORD,D1:WORD,D2:WORD       ;Send an explicit Channel Voice msg
                pushf
                cli

                call send_MIDI_message C,[Stat],[D1],[D2]

                POP_F
                ret
send_cv_msg     ENDP

;****************************************************************************
protect_timbre  PROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE     ;Protect a timbre from replacement
                pushf
                cli

                POP_F
                ret
protect_timbre  ENDP

;****************************************************************************
unprotect_timbre PROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE    ;Allow a timbre to be replaced
                pushf 
                cli

                POP_F
                ret
unprotect_timbre ENDP

;****************************************************************************
timbre_status   PROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE     ;Return 0 if timbre not resident
                pushf 
                cli

                POP_F
                ret
timbre_status   ENDP

;****************************************************************************
get_cache_size  PROC USES DS SI DI H:WORD
                pushf
                cli

                mov ax,0                ;no resident cache

                POP_F
                ret
get_cache_size  ENDP

;****************************************************************************
define_cache    PROC USES DS SI DI H:WORD,MyAddr:FAR PTR,MySize:WORD
                ret
define_cache    ENDP

;****************************************************************************
get_request     PROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov ax,-1
                
                POP_F
                ret
get_request     ENDP

;****************************************************************************
install_timbre  PROC USES DS SI DI H:WORD,Bank:BYTE,Num:BYTE,MyAddr:FAR PTR
                LOCAL sys_seg,sys_dest               
                pushf
                cli

                POP_F
                ret
install_timbre  ENDP
