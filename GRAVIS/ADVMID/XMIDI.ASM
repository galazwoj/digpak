;[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
;[[                                                                        [[
;[[   XMIDI.ASM                                                            [[
;[[                                                                        [[
;[[   IBM Audio Interface Library -- Extended MIDI sound driver shell      [[
;[[                                                                        [[
;[[   Version 1.00 of 27-Sep-91: Initial version for AIL V2.0 release      [[
;[[           1.01 of 25-Nov-91: Handles not consumed by invalid sequences [[
;[[                              RBRN indexing fixed                       [[
;[[           1.02 of  8-Dec-91: Callback Trigger values readable          [[
;[[                              AIL_cancel_callback clears address dword  [[
;[[           1.03 of 28-Dec-91: Callbacks compatible with Pascal and C    [[
;[[           1.04 of 31-Jan-92: reset_sequence() clears global sustain    [[
;[[           1.05 of  2-Feb-92: stop/resume_sequence() validate handles   [[
;[[                              Flag "seq_started" added to state table   [[
;[[                              Beat/bar count math precision increased   [[
;[[           1.06 of 15-Feb-92: Includes YAMAHA.INC instead of YM3812.INC [[
;[[                              Copyright message header updated          [[
;[[                              Time denominators < 4 counted correctly   [[
;[[                              Do shutdown only if initialized           [[
;[[           1.07 of 15-Mar-92: Beat fraction initialized nonzero         [[
;[[           1.08 of  3-Apr-92: BRANCH_EXIT equate added                  [[
;[[           1.09 of  4-Jun-92: PASOPL and MMASTER compatibility          [[
;[[           1.10 of 14-Oct-92: New time signature function for improved  [[
;[[                              precision                                 [[
;[[                                                                        [[
;[[   Author: John Miles                                                   [[
;[[   8086 ASM source compatible with Turbo Assembler v2.0 or later        [[
;[[                                                                        [[
;[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
;[[                                                                        [[
;[[   Copyright (C) 1991, 1992 Miles Design, Inc.                          [[
;[[                                                                        [[
;[[   Miles Design, Inc.                                                   [[
;[[   10926 Jollyville #308                                                [[
;[[   Austin, TX 78759                                                     [[
;[[   (512) 345-2642 / FAX (512) 338-9630 / BBS (512) 454-9990             [[
;[[                                                                        [[
;[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
; Not binary compatible with tasm
;   jumps generated differently
;   invoke generates different code
;   pop_f macro nonsense removed
;   add, sp -x generated instead of sub sp, x


                .MODEL TINY,C          ;Procedures far, data near by default
		ASSUME CS:_TEXT, DS:NOTHING, ES:NOTHING, SS:NOTHING	

CPROC 		equ	<PROC  FAR C >
CPROTO 		equ	<PROTO FAR C >
LPROC 		equ	<PROC  NEAR C PRIVATE>
LPROTO 		equ	<PROTO NEAR C>

                ;
                ;Configuration equates
                ;

FALSE           equ 0
TRUE            equ -1

QUANT_RATE      equ 120                 ;Quantization (def=120 intervals/sec.)
QUANT_TIME      equ 8333                ;(uS/interval = 1000000/QUANT_RATE)

QUANT_TIME_16_L equ 008d5h              ;set to 16,000,000/QUANT_RATE --
QUANT_TIME_16_H equ 00002h              ;normally 133333 (208D5H)

MAX_NOTES       equ 32                  ;Max # of notes "on" simultaneously
FOR_NEST        equ 4                   ;# of FOR loop nesting levels
NSEQS           equ 8                   ;# of sequence handles available
QUANT_ADVANCE   equ 1                   ;Beat/bar counts += n intervals

DEF_PITCH_L     equ 00h
DEF_PITCH_H     equ 40h                 ;Default pitch bend = 4000h (mid-way)

BRANCH_EXIT     equ TRUE                ;TRUE to allow branches out of loops

                ;
                ;Macros, non-configurable equates
                ;

                INCLUDE AIL.MAC
                INCLUDE AIL.INC

                IFDEF SBSTD
YM3812          equ 1
                ENDIF

                IFDEF ADLIBSTD
YM3812          equ 1
                ENDIF

                IFDEF PAS
YM3812          equ 1
STEREO          equ 1
                ENDIF

                IFDEF SBPRO1
YM3812          equ 1
STEREO          equ 1
                ENDIF

                IFDEF SBPRO2
YMF262          equ 1
STEREO          equ 1
                ENDIF

                IFDEF PASOPL
YMF262          equ 1
STEREO          equ 1
                ENDIF

                IFDEF ADLIBG
YMF262          equ 1
STEREO          equ 1
                ENDIF

                IFDEF TANDY
SPKR            equ 1
                ENDIF

                IFDEF IBMPC
SPKR            equ 1
                ENDIF

                IFDEF CMS
SPKR            equ 1
                ENDIF

NUM_CHANS       equ 16                  ;# of MIDI channels

                .CODE
		.186
                dw OFFSET driver_index
                db 'Copyright (C) 1991,1992 Miles Design, Inc.',01ah

driver_index    LABEL WORD
                dw AIL_DESC_DRVR,OFFSET describe_driver
                dw AIL_DET_DEV,OFFSET detect_device
                dw AIL_INIT_DRVR,OFFSET init_driver
                dw AIL_SERVE_DRVR,OFFSET serve_driver
                dw AIL_SHUTDOWN_DRVR,OFFSET shutdown_driver

                dw AIL_STATE_TAB_SIZE,OFFSET get_state_size
                dw AIL_INSTALL_CB,OFFSET install_callback
                dw AIL_CANCEL_CB,OFFSET cancel_callback
                dw AIL_REG_SEQ,OFFSET register_seq
                dw AIL_REL_SEQ_HND,OFFSET release_seq

                dw AIL_START_SEQ,OFFSET start_seq
                dw AIL_STOP_SEQ,OFFSET stop_seq
                dw AIL_RESUME_SEQ,OFFSET resume_seq
                dw AIL_SEQ_STAT,OFFSET get_seq_status
                dw AIL_REL_VOL,OFFSET get_rel_volume
                dw AIL_SET_REL_VOL,OFFSET set_rel_volume
                dw AIL_REL_TEMPO,OFFSET get_rel_tempo
                dw AIL_SET_REL_TEMPO,OFFSET set_rel_tempo
                dw AIL_CON_VAL,OFFSET get_control_val
                dw AIL_SET_CON_VAL,OFFSET set_control_val
                dw AIL_CHAN_NOTES,OFFSET get_chan_notes
                dw AIL_MAP_SEQ_CHAN,OFFSET map_seq_channel
                dw AIL_TRUE_SEQ_CHAN,OFFSET true_seq_channel
                dw AIL_BEAT_CNT,OFFSET get_beat_count
                dw AIL_BAR_CNT,OFFSET get_bar_count
                dw AIL_BRA_INDEX,OFFSET branch_index

                dw AIL_SEND_CV_MSG,OFFSET send_cv_msg
                dw AIL_SEND_SYSEX_MSG,OFFSET send_sysex_msg
                dw AIL_WRITE_DISP,OFFSET write_display

                dw AIL_LOCK_CHAN,OFFSET lock_channel
                dw AIL_RELEASE_CHAN,OFFSET release_channel

                dw AIL_T_CACHE_SIZE,OFFSET get_cache_size
                dw AIL_DEFINE_T_CACHE,OFFSET define_cache
                dw AIL_T_REQ,OFFSET get_request
                dw AIL_INSTALL_T,OFFSET install_timbre
                dw AIL_PROTECT_T,OFFSET protect_timbre
                dw AIL_UNPROTECT_T,OFFSET unprotect_timbre
                dw AIL_T_STATUS,OFFSET timbre_status
                dw -1

                ;
                ;Synthesizer- and interface-specific routines
                ;

                IFDEF MT32
                INCLUDE mt32.inc        ;Roland MT-32-compatible synthesizer
                ENDIF

                IFDEF YM3812
                INCLUDE yamaha.inc      ;Standard Ad Lib-style chipset
                ENDIF

                IFDEF YMF262
                INCLUDE yamaha.inc      ;YMF262 support for Ad Lib Gold et al.
                ENDIF

                IFDEF MMASTER
                INCLUDE mmaster.inc     ;ASC MediaMaster and 100% compatibles
                ENDIF

                IFDEF SPKR              
                INCLUDE spkr.inc        ;Internal speaker support for PC/Tandy
                ENDIF

                ;
                ;Misc. data
                ;

ctrl_log        STRUC                   ;XMIDI sequence/global controller log
PV              db NUM_CHANS dup (?)    
MODUL           db NUM_CHANS dup (?)    
PAN             db NUM_CHANS dup (?)    
EXP             db NUM_CHANS dup (?)    
SUS             db NUM_CHANS dup (?)    
PBS             db NUM_CHANS dup (?)
C_LOCK          db NUM_CHANS dup (?)    
C_PROT          db NUM_CHANS dup (?)    
V_PROT          db NUM_CHANS dup (?)    
ctrl_log        ENDS

logged_ctrls    LABEL BYTE              ;Controllers saved in state table
                db PART_VOLUME,MODULATION,PANPOT,EXPRESSION,SUSTAIN
                db PATCH_BANK_SEL
                db CHAN_LOCK,CHAN_PROTECT,VOICE_PROTECT
NUM_CONTROLS    equ ($-logged_ctrls)    ;room for 16 max. w/8-bit hash

ctrl_default    LABEL BYTE              ;default controller/program change
                db 127,0,64,127,0       ;values for startup initialization
                db 0
                db 0,0,0

prg_default     db 68,48,95,78          ;(Roland defaults)
                db 41,3,110,122,-1

ctrl_hash       db 256 dup (-1)         ;Controller offsets indexed for speed
                
state_table     STRUC                   ;XMIDI sequence state table layout
TIMB            dd ?
RBRN            dd ?
EVNT            dd ?
EVNT_ptr        dd ?
cur_callback    dw ?
ctrl_ptr        dd ?
seq_handle      dw ?
seq_started     dw ?
status          dw ?
post_release    dw ?
interval_cnt    dw ?
note_count      dw ?
vol_error       dw ?
vol_percent     dw ?
vol_target      dw ?
vol_accum_l     dw ?
vol_accum_h     dw ?
vol_period_l    dw ?
vol_period_h    dw ?
tempo_error     dw ?
tempo_percent   dw ?
tempo_target    dw ?
tempo_accum_l   dw ?
tempo_accum_h   dw ?
tempo_period_l  dw ?
tempo_period_h  dw ?
beat_count      dw ?
measure_count   dw ?
time_numerator  dw ?
time_fraction_l dw ?
time_fraction_h dw ?
beat_fraction_l dw ?
beat_fraction_h dw ?
time_per_beat_l dw ?
time_per_beat_h dw ?
FOR_ptrs        dd FOR_NEST dup (?)
FOR_loop_cnt    dw FOR_NEST dup (?)
chan_map        db NUM_CHANS dup (?)
chan_program    db NUM_CHANS dup (?)
chan_pitch_l    db NUM_CHANS dup (?)
chan_pitch_h    db NUM_CHANS dup (?)
chan_indirect   db NUM_CHANS dup (?)
chan_controls   ctrl_log <>
note_chan       db MAX_NOTES dup (?)
note_num        db MAX_NOTES dup (?)
note_time_l     dw MAX_NOTES dup (?)
note_time_h     dw MAX_NOTES dup (?)
state_table     ENDS

sequence_state  dd NSEQS dup (?)
sequence_count  dw ?
current_handle  dw ?

service_active  dw ?
trigger_ds      dw ?
trigger_fn      dd ?

global_shadow   LABEL BYTE            
global_controls ctrl_log <>
global_program  db NUM_CHANS dup (?)
global_pitch_l  db NUM_CHANS dup (?)
global_pitch_h  db NUM_CHANS dup (?)
GLOBAL_SIZE     equ ($-global_shadow)

active_notes    db NUM_CHANS dup (?)    
lock_status     db NUM_CHANS dup (?)    ;bit 7: locked
                                        ;    6: lock-protected           
init_OK         dw 0
IFDEF GRAVIS
chk_hook_str    db 'ULTRAMID',0              ;Stamp to find resident GF1 O.S.
gf1hook        	label   dword   ; The GF1 hook for all AIL calls.
hookoff     	dw      0
hookseg     	dw      0
ENDIF
find_seq        	CPROTO XMID:FAR PTR,SeqNum:WORD   
rewind_seq      	CPROTO Sequence:WORD 
flush_channel_notes 	CPROTO Chan:WORD     
flush_note_queue 	CPROTO State:FAR PTR 
reset_sequence  	CPROTO State:FAR PTR 
restore_sequence 	CPROTO State:FAR PTR 
XMIDI_volume    	CPROTO State:FAR PTR 
XMIDI_control   	CPROTO State:FAR PTR,Chan:WORD,Con:WORD,Val:WORD
XMIDI_note_on   	CPROTO State:FAR PTR      
XMIDI_meta      	CPROTO State:FAR PTR      
XMIDI_sysex     	CPROTO State:FAR PTR      
ul_divide       	CPROTO NumLO:WORD,NumHI:WORD,DenLO:WORD,DenHI:WORD       
advance_count   	CPROTO Sequence:WORD        
serve_driver    	CPROTO               
init_driver     	CPROTO H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
shutdown_driver 	CPROTO H:WORD,SignOff:FAR PTR
get_state_size  	CPROTO H:WORD
install_callback 	CPROTO H:WORD,Fn:FAR PTR    
cancel_callback 	CPROTO H:WORD               
register_seq    	CPROTO H:WORD,XMID:FAR PTR,Num:WORD,State:FAR PTR,Ctrl:FAR PTR
release_seq     	CPROTO H:WORD,Sequence:WORD
start_seq       	CPROTO H:WORD,Sequence:WORD
stop_seq        	CPROTO H:WORD,Sequence:WORD
resume_seq      	CPROTO H:WORD,Sequence:WORD
get_seq_status  	CPROTO H:WORD,Sequence:WORD
get_beat_count 	 	CPROTO H:WORD,Sequence:WORD
get_bar_count   	CPROTO H:WORD,Sequence:WORD
map_seq_channel 	CPROTO H:WORD,Sequence:WORD,SeqChan:WORD,PhysChan:WORD
true_seq_channel 	CPROTO H:WORD,Sequence:WORD,SeqChan:WORD
branch_index    	CPROTO H:WORD,Sequence:WORD,Marker:BYTE
get_rel_tempo   	CPROTO H:WORD,Sequence:WORD
get_rel_volume  	CPROTO H:WORD,Sequence:WORD
set_rel_tempo   	CPROTO H:WORD,Sequence:WORD,Tempo:WORD,Grad:WORD
set_rel_volume 	 	CPROTO H:WORD,Sequence:WORD,Volume:WORD,Grad:WORD
get_control_val 	CPROTO H:WORD,Sequence:WORD,Chan:WORD,Control:WORD
set_control_val 	CPROTO H:WORD,Sequence:WORD,Chan:WORD,Control:WORD,Val:WORD
get_chan_notes  	CPROTO H:WORD,Sequence:WORD,Chan:WORD
lock_channel    	CPROTO H:WORD               
release_channel 	CPROTO H:WORD,Chan:WORD

;****************************************************************************
;*                                                                          *
;*  XMIDI interpreter and related procedures                                *
;*                                                                          *
;****************************************************************************

find_seq        CPROC USES DS SI DI XMID:FAR PTR,SeqNum:WORD        ;Find FORM SeqNum in IFF 
                LOCAL end_addr_l:WORD,end_addr_h:WORD     ;CAT/FORM XMID file
                mov cx,[SeqNum]
                inc cx                          ;look for CXth FORM XMID chunk

                lds si,[XMID]
__find_XMID:    cmp WORD PTR [si],'AC'
                jne __chk_FORM
                cmp WORD PTR [si+2],' T'
                je __found_IFF
__chk_FORM:     cmp WORD PTR [si],'OF'                 
                jne __not_found         
                cmp WORD PTR [si+2],'MR'                 ;return failure if not an IFF
                jne __not_found                 ;image

__found_IFF:    cmp WORD PTR [si+8],'MX'
                jne __next_XMID
                cmp WORD PTR [si+10],'DI'
                je __found_XMID

__next_XMID:    mov dx,[si+4]                   ;find first XMID chunk
                mov ax,[si+6]
                xchg al,ah
                xchg dl,dh
                add ax,8
                adc dx,0
                ADD_PTR ax,dx,ds,si
                jmp __find_XMID
                
__found_XMID:   mov dx,[si+4]                   
                mov ax,[si+6]
                xchg al,ah
                xchg dl,dh
                sub ax,5                        
                sbb dx,0                        ;DX:AX=last byte of all FORMs
                mov end_addr_l,ax
                mov end_addr_h,dx

                cmp WORD PTR [si],'OF'                   ;if outer header was a FORM,
                jne __scan_CAT                  ;return successfully if CX=1
                cmp WORD PTR [si+2],'MR'
                jne __scan_CAT
                cmp cx,1
                je __seq_found
                jmp __not_found           

__scan_CAT:     add si,12                       ;index first FORM chunk

__check_FORM:   cmp WORD PTR [si+8],'MX'                 ;is this a FORM XMID?
                jne __next_FORM
                cmp WORD PTR [si+10],'DI'
                je __next_seq                   ;yes, dec the loop counter...

__next_FORM:    mov dx,[si+4]                   ;else add length of FORM + 8
                mov ax,[si+6]                   ;and keep looking...
                xchg al,ah
                xchg dl,dh
                add ax,8
                adc dx,0
                sub end_addr_l,ax               ;...unless EOF reached
                sbb end_addr_h,dx
                jl __not_found
                ADD_PTR ax,dx,ds,si
                jmp __check_FORM

__next_seq:     loop __next_FORM                ;look for CXth sequence chunk

__seq_found:    mov ax,si                       
                mov dx,ds
                jmp __exit                      ;return pointer to first chunk

__not_found:    mov ax,0                        ;return NULL if not found
                mov dx,0
__exit:         ret
find_seq        ENDP

;****************************************************************************
rewind_seq      CPROC USES DS SI DI Sequence:WORD      ;Reset sequence pointer and invalidate
               				              ;all state table entries                                                    
                mov si,[Sequence]
                lds si,sequence_state[si]

                mov cx,FOR_NEST
                mov bx,0
__init_FOR:     mov [si].state_table.FOR_loop_cnt[bx],-1
                add bx,2
                loop __init_FOR

                mov bx,NUM_CHANS-1
__init_chans:   mov [si].state_table.chan_map[bx],bl
                mov [si].state_table.chan_program[bx],-1
                mov [si].state_table.chan_pitch_l[bx],-1
                mov [si].state_table.chan_pitch_h[bx],-1
                mov [si].state_table.chan_indirect[bx],-1
                dec bx
                jge __init_chans

                mov bx,SIZE state_table.chan_controls-1
__init_ctrls:   mov BYTE PTR [si].state_table.chan_controls[bx],-1
                dec bx
                jge __init_ctrls

                mov bx,MAX_NOTES-1
__init_notes:   mov [si].state_table.note_chan[bx],-1
                dec bx
                jge __init_notes

                mov [si].state_table.cur_callback,-1
                mov [si].state_table.interval_cnt,0
                mov [si].state_table.note_count,0
                mov [si].state_table.vol_percent,DEF_SYNTH_VOL
                mov [si].state_table.vol_target,DEF_SYNTH_VOL
                mov [si].state_table.tempo_percent,100
                mov [si].state_table.tempo_target,100
                mov [si].state_table.tempo_error,0
                mov [si].state_table.beat_count,0              
                mov [si].state_table.measure_count,-1

                mov [si].state_table.beat_fraction_l,0
                mov [si].state_table.beat_fraction_h,0

                mov [si].state_table.time_fraction_l,0
                mov [si].state_table.time_fraction_h,0

                mov [si].state_table.time_numerator,4       ;default to 4/4 time

                mov [si].state_table.time_per_beat_l,01200h ;default to 500000 us/beat*16
                mov [si].state_table.time_per_beat_h,0007ah ;(120 beats/min)

                ret
rewind_seq      ENDP

;****************************************************************************
flush_channel_notes CPROC USES DS SI DI Chan:WORD      ;Turn all sequences' notes off in a 
                LOCAL handle:WORD,seqcnt:WORD     ;given channel
                mov handle,0            ;for all sequences....

                mov cx,sequence_count
                mov seqcnt,cx
                jcxz __exit

__for_seq:      mov di,handle
                add handle,4
                cmp WORD PTR sequence_state[di+2],0
                je __for_seq            ;(sequence not registered)

                lds si,sequence_state[di]

                cmp [si].state_table.note_count,0
                je __next_seq           ;no notes on, don't bother looking

                mov bx,0                ;check note queue for active notes
__for_entry:    mov al,[si].state_table.note_chan[bx]
                cmp al,BYTE PTR [Chan]
                jne __next_entry
                mov [si].state_table.note_chan[bx],-1
                mov cl,[si].state_table.note_num[bx]
                mov di,bx
                mov bl,al
                mov bh,0                ;translate logical to physical channel
                mov bl,[si].state_table.chan_map[bx]
                dec active_notes[bx]    ;dec # of active notes in channel
                or bl,80h               ;send MIDI Note Off message
                INVOKE send_MIDI_message,bx,cx,0
                dec [si].state_table.note_count
                mov bx,di
__next_entry:   inc bx
                cmp bx,MAX_NOTES
                jb __for_entry

__next_seq:     dec seqcnt
                jne __for_seq

__exit:         ret
flush_channel_notes ENDP

;****************************************************************************
flush_note_queue CPROC USES DS SI DI State:FAR PTR     ;Turn all queued notes off
                cld

                lds si,[State]

                mov bx,0                ;check note queue for active notes
__for_entry:    mov al,[si].state_table.note_chan[bx]
                cmp al,-1
                je __next_entry
                mov [si].state_table.note_chan[bx],-1
                mov cl,[si].state_table.note_num[bx]
                mov di,bx
                mov bl,al
                mov bh,0                ;translate logical to physical channel
                mov bl,[si].state_table.chan_map[bx]
                dec active_notes[bx]    ;dec # of active notes in channel
                or bl,80h               ;send MIDI Note Off message
                INVOKE send_MIDI_message,bx,cx,0
                mov bx,di
__next_entry:   inc bx
                cmp bx,MAX_NOTES
                jb __for_entry

                mov [si].state_table.note_count,0
                ret
flush_note_queue ENDP

;****************************************************************************
reset_sequence  CPROC USES DS SI DI State:FAR PTR     ;Abandon all sequence-owned resources
                lds si,[State]

                mov di,0
__for_chan:     mov bx,di
                mov al,[si].state_table.chan_controls.SUS[bx]
                cmp al,64
                jl __chk_lock
                mov global_controls.SUS[bx],0
                or bx,0b0h
                INVOKE send_MIDI_message,bx,SUSTAIN,0
                mov bx,di

__chk_lock:     mov al,[si].state_table.chan_controls.C_LOCK[bx]
                cmp al,64
                jl __chk_cprot
                INVOKE flush_channel_notes,di
                mov bx,di
                mov bl,[si].state_table.chan_map[bx]
                mov bh,0
                inc bx
                INVOKE release_channel,0,bx
                mov bx,di
                mov [si].state_table.chan_map[bx],bl

__chk_cprot:    mov al,[si].state_table.chan_controls.C_PROT[bx]
                cmp al,64
                jl __chk_vprot
                and lock_status[bx],10111111b

__chk_vprot:    mov al,[si].state_table.chan_controls.V_PROT[bx]
                cmp al,64
                jl __next_chan
                or bx,0b0h
                INVOKE send_MIDI_message,bx,VOICE_PROTECT,0
                mov bx,di

__next_chan:    inc di
                cmp di,NUM_CHANS
                jne __for_chan

                ret
reset_sequence  ENDP

;****************************************************************************
restore_sequence CPROC USES DS SI DI State:FAR PTR     ;Reassert all "owned" controls
                LOCAL con:WORD,ctrl:WORD,index:WORD      
                lds si,[State]

                mov di,0                ;re-lock any channels formerly locked
__for_lock:     mov bx,di               ;by CHAN_LOCK controllers
                mov al,[si].state_table.chan_controls.C_LOCK[bx]
                cmp al,-1
                je __next_lock
                cmp al,64
                jl __next_lock
                INVOKE lock_channel,0   ;lock new channel and map to current
                dec ax                  ;channel in sequence
                cmp ax,-1
                jne __locked
                mov ax,di
__locked:       mov bx,di
                mov [si].state_table.chan_map[bx],al
__next_lock:    inc di
                cmp di,NUM_CHANS
                jne __for_lock

                mov con,0               ;re-establish all logged controller
__for_control:  mov bx,con              ;values
                mov bl,logged_ctrls[bx]
                cmp bl,CHAN_LOCK        ;(except channel locks, which were
                je __next_control       ;done above)
                mov ctrl,bx
                mov bl,ctrl_hash[bx]
                mov index,bx            
                mov di,0
__for_channel:  mov bx,di
                add bx,index
                mov al,BYTE PTR [si].state_table.chan_controls[bx]
                cmp al,-1
                je __next_channel
                INVOKE XMIDI_control,ds::si,di,ctrl,ax
__next_channel: inc di
                cmp di,NUM_CHANS
                jne __for_channel
__next_control: inc con
                cmp con,NUM_CONTROLS
                jne __for_control

                mov di,0                ;restore pitch/program # values
__for_p_p:      mov bx,di
                mov al,[si].state_table.chan_pitch_l[bx]
                cmp al,-1
                je __set_prg
                mov dl,[si].state_table.chan_pitch_h[bx]
                cmp dl,-1
                je __set_prg
                mov bl,[si].state_table.chan_map[bx]
                or bx,0e0h
                INVOKE send_MIDI_message,bx,ax,dx
                mov bx,di
__set_prg:      mov dl,[si].state_table.chan_program[bx]
                cmp dl,-1
                je __next_p_p
                mov bl,[si].state_table.chan_map[bx]
                or bx,0c0h
                INVOKE send_MIDI_message,bx,dx,0
__next_p_p:     inc di
                cmp di,NUM_CHANS
                jne __for_p_p

                ret
restore_sequence ENDP

;****************************************************************************
XMIDI_volume    CPROC USES DS SI DI State:FAR PTR      ;Send updated volume control messages               
                lds si,[State]       
                                       
                mov bx,0                
__for_chan:     mov al,[si].state_table.chan_controls.PV[bx]
                cmp al,-1
                je __next_chan
                mov ah,0

                mov cx,[si].state_table.vol_percent
                mul cx                  ;else get scaled volume value
                mov cx,100
                div cx
                cmp ax,127
                jb __send
                mov ax,127

__send:         mov di,bx               ;update global controller shadow
                mov global_controls.PV[bx],al
                test lock_status[bx],10000000b
                jnz __next_chan         ;(logical channel locked)
                mov di,bx
                mov bl,[si].state_table.chan_map[bx]
                or bl,0b0h              ;send the new volume value
                INVOKE send_MIDI_message,bx,PART_VOLUME,ax
                mov bx,di               ;recover channel

__next_chan:    inc bx
                cmp bx,NUM_CHANS
                jne __for_chan

                ret
XMIDI_volume    ENDP

;****************************************************************************
XMIDI_control   CPROC USES DS SI DI State:FAR PTR,Chan:WORD,Con:WORD,Val:WORD
               				      ;Process XMIDI Control Change message
                LOCAL prg_sp:WORD
                cld

                lds si,[State]

                mov bl,BYTE PTR [Chan]           ;BX=channel #
                mov bh,0                
                mov dl,BYTE PTR [Val]            ;DX=value
                mov dh,0

                mov al,[si].state_table.chan_indirect[bx]
                cmp al,-1
                je __value              ;no indirection pending, continue

                mov [si].state_table.chan_indirect[bx],-1
                mov bl,al
                les di,[si].state_table.ctrl_ptr    ;else get value from controller table
                mov dl,es:[di][bx]      

__value:        mov bl,BYTE PTR [Con]            ;BX=controller #
                mov bh,0

                mov bl,ctrl_hash[bx]
                cmp bl,-1
                je __interpret          ;(not loggable)

                add bl,BYTE PTR [Chan]           ;copy controller value to state tables
                mov BYTE PTR global_controls[bx],dl
                mov BYTE PTR [si].state_table.chan_controls[bx],dl         

__interpret:    mov al,BYTE PTR [Con]            ;handle sequence-specific controllers
                mov bl,BYTE PTR [Chan]
                cmp al,PART_VOLUME      ;BX=channel, AL=controller #, DX=value
                je __scale_volume       
                cmp al,CLEAR_BEAT_BAR   
                je __go_cc
                cmp al,CALLBACK_TRIG
                je __go_cb
                cmp al,FOR_LOOP
                je __go_for
                cmp al,NEXT_LOOP
                je __go_next
                cmp al,CHAN_PROTECT
                je __go_cp
                cmp al,CHAN_LOCK
                je __go_cl
                cmp al,INDIRECT_C_PFX
                je __go_indirect

__send:         test lock_status[bx],10000000b
                jnz __exit              ;(logical channel locked)
                mov bl,[si].state_table.chan_map[bx]
                or bl,0b0h              ;send the controller value
                INVOKE send_MIDI_message,bx,ax,dx
              
__exit:         mov ax,3                ;return total event size
                ret

__scale_volume: mov cx,[si].state_table.vol_percent
                cmp cx,100
                je __send               ;100% volume, don't scale
                mov ax,dx
                mul cx                  ;else get scaled volume value
                mov cx,100
                div cx
                mov dx,ax
                mov ax,PART_VOLUME
                cmp dx,127
                jb __send_volume
                mov dx,127
__send_volume:  mov global_controls.PV[bx],dl
                jmp __send

__go_cc:        jmp __clear_cntrs
__go_cb:        jmp __callback
__go_for:       jmp __for_loop
__go_next:      jmp __next_loop
__go_cp:        jmp __chan_prot
__go_cl:        jmp __chan_lock
__go_indirect:  jmp __indirect

__indirect:     mov [si].state_table.chan_indirect[bx],dl
                jmp __exit

__clear_cntrs:  mov [si].state_table.beat_count,0
                mov [si].state_table.measure_count,0
                mov [si].state_table.beat_fraction_l,0
                mov [si].state_table.beat_fraction_h,0

                mov ax,[si].state_table.time_fraction_l
                mov dx,[si].state_table.time_fraction_h
                sub [si].state_table.beat_fraction_l,ax
                sbb [si].state_table.beat_fraction_h,dx
                jmp __exit

__callback:     mov [si].state_table.cur_callback,dx
                mov ax,WORD PTR trigger_fn
                or ax,WORD PTR trigger_fn+2
                je __exit               ;(callback functions disabled)
                pushf

                mov prg_sp,sp           ;save SP before parameters pushed

                push dx                 ;(use C calling convention)
                push [si].state_table.seq_handle    ;push sequence handle, ctrl value
                mov ds,trigger_ds       ;restore the application module's DS
                call [trigger_fn]       ;and call the callback function

                mov sp,prg_sp           ;restore old SP value

                POP_F
                jmp __exit

__for_loop:     mov bx,0                ;get index of available loop counter
                mov cx,FOR_NEST
__for_find:     cmp [si].state_table.FOR_loop_cnt[bx],-1
                je __for_found
                add bx,2
                loop __for_find
                jmp __exit
__for_found:    mov [si].state_table.FOR_loop_cnt[bx],dx
                shl bx,1
                les di,[si].state_table.EVNT_ptr    ;(NEXT controller will skip FOR)
                mov WORD PTR [si].state_table.FOR_ptrs[bx],di
                mov WORD PTR [si].state_table.FOR_ptrs[bx+2],es
                jmp __exit

__next_loop:    cmp dl,64               ;BREAK controller (value < 64)?
                jl __exit               ;yes, ignore and continue

                mov bx,(FOR_NEST*2)-2   
                mov cx,FOR_NEST         ;else get index of inner loop counter
__next_find:    cmp [si].state_table.FOR_loop_cnt[bx],-1
                jne __next_found
                sub bx,2
                loop __next_find
                jmp __exit
__next_found:   cmp [si].state_table.FOR_loop_cnt[bx],0
                je __do_loop            ;FOR value 0 = infinite loop
                dec [si].state_table.FOR_loop_cnt[bx]
                jnz __do_loop
                mov [si].state_table.FOR_loop_cnt[bx],-1
                jmp __exit              ;remove loop from list if dec'd to 0
__do_loop:      shl bx,1
                les di,[si].state_table.FOR_ptrs[bx]
                mov WORD PTR [si].state_table.EVNT_ptr,di
                mov WORD PTR [si].state_table.EVNT_ptr+2,es
                jmp __exit

__chan_prot:    or lock_status[bx],01000000b
                cmp dl,64
                jge __exit
                and lock_status[bx],10111111b
                jmp __exit

__chan_lock:    mov di,bx
                cmp dl,64
                jl __unlock
                INVOKE lock_channel,0   ;lock new channel and map to current
                dec ax                  ;channel in sequence
                cmp ax,-1
                jne __set_chan
                mov ax,di
__set_chan:     mov bx,di
                mov [si].state_table.chan_map[bx],al
                jmp __exit

__unlock:       INVOKE flush_channel_notes,di
                mov bx,di
                mov bl,[si].state_table.chan_map[bx]
                inc bx
                INVOKE release_channel,0,bx
                mov bx,di
                mov [si].state_table.chan_map[bx],bl
                jmp __exit              ;release and unmap locked channel

XMIDI_control   ENDP

;****************************************************************************
XMIDI_note_on   CPROC USES DS SI DI State:FAR PTR      ;Turn XMIDI note on, add to note queue
                LOCAL chan_note:WORD,vel:WORD,len:WORD ;Returns AX=size of Note On event
                lds si,[State]          
                les di,[si].state_table.EVNT_ptr    ;retrieve event data pointer
                mov ax,es:[di]         
                and al,0fh              ;AL=channel, AH=note #
                mov chan_note,ax
                mov al,es:[di+2]        ;AL=velocity
                mov vel,ax

                mov ax,di               ;get VLN duration value in DX:AX
                add di,3
                mov bx,0                
                mov dx,0
                jmp __calc_VLN
__shift_VLN:    mov cx,7
__mul_128:      shl bx,1
                rcl dx,1
                loop __mul_128
__calc_VLN:     mov cl,es:[di]
                inc di
                mov ch,cl
                and cl,7fh
                or bl,cl
                or ch,ch
                js __shift_VLN
                sub di,ax               ;get length of entire event
                mov len,di              ;DX:BX = duration in q-intervals

                mov di,chan_note
                and di,0fh
                test lock_status[di],10000000b
                jnz __exit              ;(logical channel locked)

                mov ax,ds               ;set up to scan the note queue for
                mov es,ax               ;an empty slot
                lea di,[si].state_table.note_chan   
                mov cx,MAX_NOTES
                mov al,0ffh             
                repne scasb             
                mov ax,di
                jne __overflow          ;overwrite entry 0 if queue full
                inc [si].state_table.note_count     ;else bump note counter...
                lea ax,[si].state_table.note_chan+1 ;and index the empty slot
__overflow:     sub di,ax               ;DI=queue slot [0,MAX_NOTES-1]

                mov ax,bx               ;DX:AX = duration
                mov bx,di               ;BX = queue slot
                sub ax,1                ;predecrement (note queue watches for
                sbb dx,0                ;negative durations)

                mov cx,chan_note        ;log the note's channel and key #
                mov [si].state_table.note_chan[bx],cl
                mov [si].state_table.note_num[bx],ch
                shl bx,1                ;log the note's duration
                mov [si].state_table.note_time_l[bx],ax
                mov [si].state_table.note_time_h[bx],dx

                mov bl,cl
                mov bh,0                ;translate logical to physical channel
                mov bl,[si].state_table.chan_map[bx]
                inc active_notes[bx]    ;inc # of notes in channel
                or bl,90h               ;turn the note on
                mov cl,ch
                INVOKE send_MIDI_message,bx,cx,vel

__exit:         mov ax,len              ;return event length
                ret
XMIDI_note_on   ENDP

;****************************************************************************
XMIDI_meta      CPROC USES DS SI DI State:FAR PTR      ;XMIDI meta-event interpreter
                LOCAL event_len:WORD,event_type:BYTE
                lds si,[State]          ;get pointers to state table and event
                les di,[si].state_table.EVNT_ptr   
                mov al,es:[di+1]
                mov event_type,al

                mov bx,di               ;get offset of status byte
                add di,2                ;adjust for type and status bytes
                mov ax,0                ;get variable-length number
                mov dx,0
                jmp __calc_VLN
__shift_VLN:    mov cx,7
__mul_128:      shl ax,1
                rcl dx,1
                loop __mul_128
__calc_VLN:     mov cl,es:[di]
                inc di
                mov ch,cl
                and cl,7fh
                or al,cl
                or ch,ch
                js __shift_VLN
                mov cx,di
                sub cx,bx               ;BX = size of meta-event header
                add ax,cx               ;add size of header to data length
                mov event_len,ax        ;to determine overall event length

                mov al,event_type
                cmp al,2fh
                je __end_sequence
                cmp al,58h
                je __time_sig
                cmp al,51h
                je __set_tempo

__exit:         mov ax,event_len        ;return total event length
                ret

__end_sequence: INVOKE reset_sequence,ds::si
                mov [si].state_table.status,SEQ_DONE
                cmp [si].state_table.post_release,0 ;release-on-completion pending?
                je __exit              
                INVOKE release_seq,0,current_handle
                jmp __exit

__time_sig:     mov ch,0
                mov cl,es:[di]
                mov [si].state_table.time_numerator,cx

                mov cl,es:[di+1]
                sub cx,2
                jae __do_mult
                neg cx

                mov ax,QUANT_TIME_16_L
                mov dx,QUANT_TIME_16_H
__div_quant:    shr dx,1
                rcr ax,1
                loop __div_quant
                jmp __end_calc

__do_mult:      mov ax,1
                shl ax,cl
                mov cx,ax
                mov ax,0
                mov dx,0
__mul_quant:    add ax,QUANT_TIME_16_L
                adc dx,QUANT_TIME_16_H
                loop __mul_quant

__end_calc:     mov [si].state_table.time_fraction_l,ax
                mov [si].state_table.time_fraction_h,dx

                mov [si].state_table.beat_fraction_l,0
                mov [si].state_table.beat_fraction_h,0
                sub [si].state_table.beat_fraction_l,ax
                sbb [si].state_table.beat_fraction_h,dx

                mov [si].state_table.beat_count,0
                inc [si].state_table.measure_count
                jmp __exit

__set_tempo:    mov dh,0
                mov dl,es:[di]
                mov ah,es:[di+1]
                mov al,es:[di+2]

                mov cx,4
__mul_X16:      shl ax,1
                rcl dx,1
                loop __mul_X16

                mov [si].state_table.time_per_beat_l,ax
                mov [si].state_table.time_per_beat_h,dx
                jmp __exit

XMIDI_meta      ENDP

;****************************************************************************
XMIDI_sysex     CPROC USES DS SI DI State:FAR PTR      ;XMIDI System Exclusive interpreter
                LOCAL event_len:WORD,event_type:WORD
                lds si,[State]          ;get pointers to state table and event
                les di,[si].state_table.EVNT_ptr   
                mov al,es:[di]
                mov ah,0
                mov event_type,ax

                mov bx,di               ;get offset of type byte
                inc di                  ;adjust for type (F0 | F7) byte
                mov ax,0                ;get variable-length number
                mov dx,0
                jmp __calc_VLN
__shift_VLN:    mov cx,7
__mul_128:      shl ax,1
                rcl dx,1
                loop __mul_128
__calc_VLN:     mov cl,es:[di]
                inc di
                mov ch,cl
                and cl,7fh
                or al,cl
                or ch,ch
                js __shift_VLN
                mov cx,di
                sub cx,bx               ;BX = size of header (type + len)
                add cx,ax               ;add size of header to data length
                mov event_len,cx        ;to determine overall event length

                IFDEF send_MIDI_sysex
                INVOKE send_MIDI_sysex,es::di,event_type,ax
                ENDIF

                mov ax,event_len        ;return total event length
                ret
XMIDI_sysex     ENDP

;*****************************************************************************
ul_divide       CPROC USES DS SI DI NumLO:WORD,NumHI:WORD,DenLO:WORD,DenHI:WORD        ;Unsigned long division
                mov ax,[NumLO]
                mov dx,[NumHI]
                mov bx,[DenLO]
                mov cx,[DenHI]

                or cx,cx
                jne __long_div
                or dx,dx
                je __short_div
                or bx,bx
                je __short_div

__long_div:     mov bp,cx
                mov cx,20h
                xor di,di
                xor si,si
                
__div_loop:     shl ax,1
                rcl dx,1
                rcl si,1
                rcl di,1
                cmp di,bp
                jb __cont_loop
                ja __bump_quot
                cmp si,bx
                jb __cont_loop
__bump_quot:    sub si,bx
                sbb di,bp
                inc ax
__cont_loop:    loop __div_loop
                jmp __end_div

__short_div:    div bx
                xor dx,dx

__end_div:      ret

ul_divide       ENDP

;****************************************************************************
advance_count   CPROC USES DS SI DI Sequence:WORD           ;Fetch DX=bar, AX=beat "advanced" by
                                                      ;QUANT_ADVANCE intervals
                mov si,[Sequence]
                lds si,sequence_state[si]

                mov ax,[si].state_table.beat_count
                mov dx,[si].state_table.measure_count

                IF QUANT_ADVANCE        ;anticipate future changes to beat/bar
                                        ;count (assuming current MIDI meter!)
                mov di,QUANT_ADVANCE
                mov bx,[si].state_table.beat_fraction_l
                mov cx,[si].state_table.beat_fraction_h

__advance_loop: add bx,[si].state_table.time_fraction_l
                adc cx,[si].state_table.time_fraction_h

                cmp cx,[si].state_table.time_per_beat_h
                jl __advance_next
                jg __new_beat
                cmp bx,[si].state_table.time_per_beat_l
                jl __advance_next

__new_beat:     sub bx,[si].state_table.time_per_beat_l
                sbb cx,[si].state_table.time_per_beat_h
                
                inc ax                  ;bump beat if ticks > ticks per beat

                cmp ax,[si].state_table.time_numerator
                jb __advance_next

                mov ax,0                ;bump measure if beat > time numerator
                inc dx

__advance_next: dec di
                jnz __advance_loop

                ENDIF

                cmp dx,0                ;don't return negative measure counts
                jge __return            ;before 1st time signature
                mov dx,0

__return:       ret                     
advance_count   ENDP                    

;****************************************************************************
;*                                                                          *
;*  Public (API-accessible) procedures                                      *
;*                                                                          *
;****************************************************************************
serve_driver    CPROC  USES DS SI DI                   ;Periodic driver service routine
                LOCAL seqcnt:WORD
                cld

                cmp service_active,0    ;OK to interrupt foreground process?
IFDEF GRAVIS
                jne __served
		mov ax,TSR_SEM_ENTER
		call gf1hook
		or ax, ax
		je __served
		jmp __do_service
ELSE
		je  __do_service
		jmp __served		;no
ENDIF
__new_beat:     sub ax,[si].state_table.time_per_beat_l
                sbb dx,[si].state_table.time_per_beat_h
                inc [si].state_table.beat_count
                mov cx,[si].state_table.beat_count
                cmp cx,[si].state_table.time_numerator
                jb __same_beat
                mov [si].state_table.beat_count,0
                inc [si].state_table.measure_count
                jmp __same_beat

__do_service:   inc service_active

                mov current_handle,-4   ;for all sequences....

                mov cx,sequence_count
                mov seqcnt,cx
                jcxz __end_seqs

__for_seq:      add current_handle,4
                mov di,current_handle
                cmp WORD PTR sequence_state[di+2],0
                je __for_seq            ;(sequence not registered)

                lds si,sequence_state[di]
                cmp [si].state_table.status,SEQ_PLAYING
                jne __next_seq          ;(sequence not playing)

                mov ax,[si].state_table.tempo_error
                add ax,[si].state_table.tempo_percent
                mov [si].state_table.tempo_error,ax
                sub ax,100
                jl __chk_t_grad
__rep_interval: mov [si].state_table.tempo_error,ax

                cmp [si].state_table.note_count,0   ;any notes on in sequence?
                jne __do_queue          ;yes, turn off any expired notes

__end_queue:    dec [si].state_table.interval_cnt
                jle __do_events         ;next interval ready, play it

__end_events:   mov ax,[si].state_table.beat_fraction_l
                mov dx,[si].state_table.beat_fraction_h
                add ax,[si].state_table.time_fraction_l
                adc dx,[si].state_table.time_fraction_h
                cmp dx,[si].state_table.time_per_beat_h
                jg __new_beat
                jl __same_beat
                cmp ax,[si].state_table.time_per_beat_l
                jge __new_beat
__same_beat:    mov [si].state_table.beat_fraction_l,ax
                mov [si].state_table.beat_fraction_h,dx

                mov ax,[si].state_table.tempo_error
                sub ax,100
                jge __rep_interval

__chk_t_grad:   mov ax,[si].state_table.tempo_percent
                cmp ax,[si].state_table.tempo_target
                jne __do_temp_grad

__chk_v_grad:   mov ax,[si].state_table.vol_percent
                cmp ax,[si].state_table.vol_target
                jne __do_vol_grad

__next_seq:     dec seqcnt
                jne __for_seq

__end_seqs:     IFDEF serve_synth       ;update synthesizer hardware regs and
                INVOKE serve_synth        ;time-variant effects, if applicable
                ENDIF
IFDEF GRAVIS
		mov ax, TSR_SEM_LEAVE
		call gf1hook
ENDIF
                dec service_active
__served:       ret

__do_temp_grad: jmp __tempo_grad
__do_vol_grad:  jmp __volume_grad

__do_events:    jmp __get_event   

__do_queue:     lea di,[si].state_table.note_chan   ;check note queue for expired notes
                mov dx,di
                mov cx,MAX_NOTES        
__scan_queue:   mov ax,ds
                mov es,ax
                mov al,0ffh             
__next_scan:    repe scasb             
                je __end_queue          ;no active notes left, return to loop
                mov bx,di
                sub bx,dx
                dec bx
                shl bx,1                ;get offset of note in queue
                sub [si].state_table.note_time_l[bx],1
                sbb [si].state_table.note_time_h[bx],0
                jge __next_scan         ;not yet expired, keep searching
                push cx
                shr bx,1
                mov al,-1               ;else mark note entry as "free"
                xchg al,[si].state_table.note_chan[bx]
                mov cl,[si].state_table.note_num[bx]
                mov bl,al
                mov bh,0                ;translate logical to physical channel
                mov bl,[si].state_table.chan_map[bx]
                dec active_notes[bx]    ;dec # of active notes in channel
                or bl,80h               ;send MIDI Note Off message
                INVOKE send_MIDI_message,bx,cx,0
                pop cx
                lea dx,[si].state_table.note_chan   ;restore queue length & base pointer
                dec [si].state_table.note_count     
                jnz __scan_queue        ;keep searching if any notes left
                jmp __end_queue         ;else return to interval loop

__new_interval: add WORD PTR [si].state_table.EVNT_ptr,1
                mov [si].state_table.interval_cnt,ax
                jmp __end_events

__normalize:    FAR_TO_HUGE es,di
                mov WORD PTR [si].state_table.EVNT_ptr+2,es
                mov WORD PTR [si].state_table.EVNT_ptr,di
                jmp __get_status

__get_event:    les di,[si].state_table.EVNT_ptr    ;get next event status byte
                cmp di,8000h            ;(for speed, normalize EVNT pointer 
                jae __normalize         ;only when necessary)

__get_status:   mov al,es:[di]          ;AL = channel/status
                mov ah,0                
                cmp ax,128              ;XMIDI interval count?
                jb __new_interval       ;yes, store it and continue   

                mov bx,ax               ;ES:DI->EVNT_ptr; DS:SI->state table
                and ax,0f0h             ;AX = status
                and bx,00fh             ;BX = logical channel
                mov cl,es:[di+1]        ;CL = data byte 1
                mov dl,es:[di+2]        ;DL = data byte 2

                cmp ax,0f0h             ;branch to XMIDI event handler for
                jae __sys               ;current MIDI status byte value
                cmp ax,0e0h
                jae __pitch_wheel
                mov di,2
                cmp ax,0d0h
                jae __send_event
                cmp ax,0c0h
                jae __prg_change
                cmp ax,0b0h
                jae __ctrl_change
                mov di,3
                cmp ax,0a0h
                jae __send_event

                INVOKE XMIDI_note_on,ds::si
                mov di,ax
                jmp __end_event

__sys:          cmp bl,0fh         
                je __meta
                INVOKE XMIDI_sysex,ds::si
                mov di,ax
                jmp __end_event

__meta:         INVOKE XMIDI_meta,ds::si
                mov di,ax
                jmp __end_event

__ctrl_change:  INVOKE XMIDI_control,ds::si,bx,cx,dx
                mov di,3
                jmp __end_event

__pitch_wheel:  mov [si].state_table.chan_pitch_l[bx],cl
                mov [si].state_table.chan_pitch_h[bx],dl
                mov global_pitch_l[bx],cl
                mov global_pitch_h[bx],dl
                mov di,3
                jmp __send_event

__prg_change:   mov [si].state_table.chan_program[bx],cl
                mov global_program[bx],cl
                mov di,2

__send_event:   test lock_status[bx],10000000b
                jnz __end_event         ;(logical channel locked)
                or al,[si].state_table.chan_map[bx]
                INVOKE send_MIDI_message,ax,cx,dx

__end_event:    add WORD PTR [si].state_table.EVNT_ptr,di
                cmp [si].state_table.status,SEQ_PLAYING
                jne __end_sequence
                jmp __get_event
__end_sequence: jmp __next_seq          

__tempo_grad:   pushf
                mov ax,[si].state_table.tempo_accum_l
                mov dx,[si].state_table.tempo_accum_h
                add ax,(QUANT_TIME / 100)
                adc dx,0
                mov cx,-1               ;CX=total tempo change/tick
__for_tempo:    inc cx
                mov [si].state_table.tempo_accum_l,ax
                mov [si].state_table.tempo_accum_h,dx
__next_tempo:   sub ax,[si].state_table.tempo_period_l    
                sbb dx,[si].state_table.tempo_period_h
                jge __for_tempo
                POP_F                   ;restore result of comparison
                jcxz __end_t_grad       ;(no change this tick)
                mov bx,[si].state_table.tempo_target
                mov ax,[si].state_table.tempo_percent
                jl __add_tempo            
                sub ax,cx
                cmp ax,bx
                jge __set_tempo
                jmp __end_tempo
__add_tempo:    add ax,cx
                cmp ax,bx
                jle __set_tempo
__end_tempo:    mov ax,bx
__set_tempo:    mov [si].state_table.tempo_percent,ax
__end_t_grad:   jmp __chk_v_grad

__volume_grad:  pushf
                mov ax,[si].state_table.vol_accum_l
                mov dx,[si].state_table.vol_accum_h
                add ax,(QUANT_TIME / 100)
                adc dx,0
                mov cx,-1               ;CX=total vol change/tick
__for_vol:      inc cx
                mov [si].state_table.vol_accum_l,ax
                mov [si].state_table.vol_accum_h,dx
__next_vol:     sub ax,[si].state_table.vol_period_l    
                sbb dx,[si].state_table.vol_period_h
                jge __for_vol
                POP_F                   ;restore result of comparison
                jcxz __end_v_grad       ;(no change this tick)
                mov bx,[si].state_table.vol_target
                mov ax,[si].state_table.vol_percent
                jl __add_vol            
                sub ax,cx
                cmp ax,bx
                jge __set_vol
                jmp __end_vol
__add_vol:      add ax,cx
                cmp ax,bx
                jle __set_vol
__end_vol:      mov ax,bx
__set_vol:      mov [si].state_table.vol_percent,ax
                INVOKE XMIDI_volume,ds::si
__end_v_grad:   jmp __next_seq

serve_driver    ENDP

;****************************************************************************
init_driver     CPROC USES DS SI DI H:WORD,IO_ADDR:WORD,IRQ:WORD,DMA:WORD,DRQ:WORD
                pushf
                cli
                cld
IFDEF GRAVIS
		mov ax, TSR_APP_START
		call gf1hook
ENDIF
                mov service_active,0
                mov sequence_count,0

                push cs
                pop es

                mov ax,-1
                lea di,global_shadow
                mov cx,GLOBAL_SIZE/2
                rep stosw
                lea di,ctrl_hash
                mov cx,(SIZE ctrl_hash)/2
                rep stosw

                mov ax,0
                lea di,sequence_state
                mov cx,(SIZE sequence_state)/2
                rep stosw
                lea di,lock_status
                mov cx,(SIZE lock_status)/2
                rep stosw
                lea di,active_notes
                mov cx,(SIZE active_notes)/2
                rep stosw

                mov si,0                ;create fast lookup table for 
                mov ax,0                ;XMIDI controller address offsets
                mov bh,0
__create_hash:  mov bl,logged_ctrls[si]
                mov ctrl_hash[bx],al
                add ax,NUM_CHANS
                inc si
                cmp si,NUM_CONTROLS
                jne __create_hash

                IFDEF set_IO_parms
                INVOKE set_IO_parms,[IO_ADDR],[IRQ],[DMA],[DRQ]
                ENDIF
                IFDEF reset_interface
                INVOKE reset_interface
                ENDIF
                IFDEF init_interface
                INVOKE init_interface
                ENDIF
                INVOKE reset_synth
                INVOKE init_synth
                INVOKE cancel_callback,H

                mov si,0                        ;init MIDI/XMIDI controllers
__for_ctrl:     mov di,MIN_TRUE_CHAN-1          ;to nominal default values
__for_chan:     mov ax,di
                or ax,0b0h
                mov bl,logged_ctrls[si]
                mov bh,0
                mov cl,ctrl_default[si]
                cmp cl,-1
                je __next_ctrl
                mov dx,bx
                mov bl,ctrl_hash[bx]
                add bx,di
                mov BYTE PTR global_controls[bx],cl
                INVOKE send_MIDI_message,ax,dx,cx
                inc di
                cmp di,MAX_REC_CHAN-1
                jbe __for_chan
__next_ctrl:    inc si
                cmp si,NUM_CONTROLS-1
                jbe __for_ctrl

                IFDEF sysex_wait
                INVOKE sysex_wait,10            ;wait for FIFO to empty if
                ENDIF                           ;necessary

                mov di,MIN_TRUE_CHAN-1          ;init pitch/programs
__for_p_p:      mov global_pitch_l[di],DEF_PITCH_L
                mov global_pitch_h[di],DEF_PITCH_H
                mov ax,di
                or ax,0e0h
                INVOKE send_MIDI_message,ax,DEF_PITCH_L,DEF_PITCH_H
                mov bl,[prg_default-MIN_TRUE_CHAN+1+di]
                cmp bl,-1
                je __next_p_p
                mov global_program[di],bl
                mov ax,di
                or ax,0c0h
                INVOKE send_MIDI_message,ax,bx,0
__next_p_p:     inc di
                cmp di,MAX_REC_CHAN-1
                jbe __for_p_p

                IFDEF sysex_wait
                INVOKE sysex_wait,10            ;wait for FIFO to empty if
                ENDIF                           ;necessary

                mov init_OK,1

                POP_F
                ret
init_driver     ENDP

;****************************************************************************
shutdown_driver CPROC USES DS SI DI H:WORD,SignOff:FAR PTR
                LOCAL handle:WORD,seqcnt:WORD     ;given channel
                pushf
                cli

                cmp init_OK,0
                je __exit

                mov handle,0            ;for all sequences....
                mov cx,sequence_count
                mov seqcnt,cx
                jcxz __shutdown
__for_seq:      mov di,handle
                add handle,4
                cmp WORD PTR sequence_state[di+2],0
                je __for_seq            ;(sequence not registered)
                INVOKE stop_seq,0,di
                INVOKE release_seq,0,di
__next_seq:     dec seqcnt
                jne __for_seq

__shutdown:     INVOKE reset_synth

                IFDEF write_display
                INVOKE write_display,0,[SignOff]
                ENDIF

                IFDEF reset_interface
                INVOKE reset_interface
                ENDIF

                IFDEF shutdown_synth
                INVOKE shutdown_synth
                ENDIF
IFDEF GRAVIS
		mov ax, TSR_APP_END
		call gf1hook
ENDIF
                mov init_OK,0

__exit:         POP_F
                ret
shutdown_driver ENDP

;****************************************************************************
get_state_size  CPROC USES DS SI DI H:WORD
                pushf
                cli

                mov ax,SIZE state_table

                POP_F
                ret
get_state_size  ENDP

;****************************************************************************
install_callback CPROC USES DS SI DI H:WORD,Fn:FAR PTR      ;Declare callback trigger handler
                pushf
                cli

                mov trigger_ds,ds       ;save application module's DS

                les di,[Fn]
                mov WORD PTR trigger_fn,di
                mov WORD PTR trigger_fn+2,es

                POP_F
                ret
install_callback ENDP

;****************************************************************************
cancel_callback CPROC USES DS SI DI H:WORD                  ;Disable callback trigger calls
                pushf
                cli

                mov WORD PTR trigger_fn,0
                mov WORD PTR trigger_fn+2,0

                POP_F
                ret
cancel_callback ENDP

;****************************************************************************
register_seq    CPROC USES DS SI DI H:WORD,XMID:FAR PTR,Num:WORD,State:FAR PTR,Ctrl:FAR PTR
                LOCAL handle:WORD,chunk_len_l:WORD,chunk_len_h:WORD
                                        ;Initialize sequence state table and
                pushf                   ;return sequence handle
                cli

                mov bx,0                ;look for an unused sequence handle
                mov cx,NSEQS
__find_handle:  cmp WORD PTR sequence_state[bx+2],0
                je __handle_found
                add bx,4
                loop __find_handle

                mov ax,-1               ;no sequence handles available...
                jmp __exit              ;return failure

__handle_found: mov handle,bx

                INVOKE find_seq,[XMID],[Num]
                cmp dx,0
                je __bad                ;sequence not found, exit...

                mov es,dx
                mov di,ax
                mov chunk_len_l,12      ;else skip FORM <len> XMID header
                mov chunk_len_h,0     
 
                lds si,[State]
                mov WORD PTR sequence_state[bx],si
                mov WORD PTR sequence_state[bx+2],ds

                mov WORD PTR [si].state_table.TIMB+2,0
                mov WORD PTR [si].state_table.RBRN+2,0
                mov WORD PTR [si].state_table.EVNT+2,0

__log_chunk:    ADD_PTR chunk_len_l,chunk_len_h,es,di
                mov ax,es:[di+6]
                mov dx,es:[di+4]
                xchg al,ah
                xchg dl,dh
                add ax,8
                adc dx,0
                mov chunk_len_l,ax
                mov chunk_len_h,dx

                cmp WORD PTR es:[di],'IT'        ;TIMB = list of required timbres
                jne __not_TIMB          ;(optional)
                cmp WORD PTR es:[di+2],'BM'
                jne __not_TIMB
                mov WORD PTR [si].state_table.TIMB,di
                mov WORD PTR [si].state_table.TIMB+2,es
                jmp __log_chunk

__not_TIMB:     cmp WORD PTR es:[di],'BR'        ;RBRN = list of branch points
                jne __not_RBRN          ;(optional)
                cmp WORD PTR es:[di+2],'NR'
                jne __not_RBRN
                mov WORD PTR [si].state_table.RBRN,di
                mov WORD PTR [si].state_table.RBRN+2,es
                jmp __log_chunk

__not_RBRN:     cmp WORD PTR es:[di],'VE'        ;EVNT = MIDI event list 
                jne __log_chunk         ;(mandatory; must be last chunk in
                cmp WORD PTR es:[di+2],'TN'      ;sequence)
                jne __log_chunk
IFDEF GRAVIS
; ES:DI Is a pointer to the Xmidi event list.
; Now send down all programs in this midi event sequence.
		push	es
		push	di
		mov 	ax,TSR_LOAD_XMIDI_PATCHES
		call    cs:gf1hook
		pop	di
		pop	es
ENDIF
                mov ax,handle
                mov [si].state_table.seq_handle,ax
                mov WORD PTR [si].state_table.EVNT,di
                mov WORD PTR [si].state_table.EVNT+2,es

                les di,[Ctrl]
                mov WORD PTR [si].state_table.ctrl_ptr,di
                mov WORD PTR [si].state_table.ctrl_ptr+2,es

                mov [si].state_table.post_release,0

                mov [si].state_table.seq_started,0
                mov [si].state_table.status,SEQ_STOPPED
                inc sequence_count

                INVOKE rewind_seq,handle

                mov ax,handle

                jmp __exit

__bad:          mov ax,-1
__exit:         POP_F
                ret
register_seq    ENDP

;****************************************************************************
release_seq     CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli
 
                mov si,[Sequence]
                cmp si,-1
                je __exit

                cmp WORD PTR sequence_state[si+2],0
                je __exit

                les di,sequence_state[si]
                cmp es:[di].state_table.status,SEQ_PLAYING
                jne __release

                mov es:[di].state_table.post_release,1
                jmp __exit

__release:      mov WORD PTR sequence_state[si+2],0
                dec sequence_count

__exit:         POP_F
                ret
release_seq     ENDP

;****************************************************************************
start_seq       CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]

                cmp [si].state_table.status,SEQ_PLAYING
                jne __start
                INVOKE stop_seq,0,[Sequence]

__start:        INVOKE rewind_seq,[Sequence]

                mov ax,WORD PTR [si].state_table.EVNT
                mov dx,WORD PTR [si].state_table.EVNT+2
                ADD_PTR 8,0,dx,ax
                mov WORD PTR [si].state_table.EVNT_ptr,ax
                mov WORD PTR [si].state_table.EVNT_ptr+2,dx
IFDEF GRAVIS
		mov 	ax,TSR_START_SEQUENCE
		call    cs:gf1hook
ENDIF
                mov [si].state_table.status,SEQ_PLAYING
                mov [si].state_table.seq_started,1

__exit:         POP_F
                ret
start_seq       ENDP

;****************************************************************************
stop_seq        CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                cmp WORD PTR sequence_state[si+2],0
                je __exit

                lds si,sequence_state[si]

                cmp [si].state_table.status,SEQ_PLAYING
                jne __exit

                INVOKE flush_note_queue,ds::si
                INVOKE reset_sequence,ds::si

                mov [si].state_table.status,SEQ_STOPPED

__exit:         POP_F
                ret
stop_seq        ENDP

;****************************************************************************
resume_seq      CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                cmp WORD PTR sequence_state[si+2],0
                je __exit

                lds si,sequence_state[si]

                cmp [si].state_table.status,SEQ_STOPPED
                jne __exit

                cmp [si].state_table.seq_started,0
                je __exit

                INVOKE restore_sequence,ds::si

                mov [si].state_table.status,SEQ_PLAYING
                                           
__exit:         POP_F
                ret
resume_seq      ENDP

;****************************************************************************
get_seq_status  CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]

                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]
                mov ax,[si].state_table.status

__exit:         POP_F
                ret
get_seq_status  ENDP

;****************************************************************************
get_beat_count  CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]

                mov ax,-1
                cmp si,ax
                je __exit

                INVOKE advance_count,si

__exit:         POP_F
                ret
get_beat_count  ENDP

;****************************************************************************
get_bar_count   CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]

                mov ax,-1
                cmp si,ax
                je __exit

                INVOKE advance_count,si

                mov ax,dx

__exit:         POP_F
                ret
get_bar_count   ENDP

;****************************************************************************
map_seq_channel CPROC USES DS SI DI H:WORD,Sequence:WORD,SeqChan:WORD,PhysChan:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]
                mov bx,[SeqChan]
                dec bx
                mov ax,[PhysChan]
                dec ax
                mov [si].state_table.chan_map[bx],al

__exit:         POP_F
                ret
map_seq_channel ENDP

;****************************************************************************
true_seq_channel CPROC USES DS SI DI H:WORD,Sequence:WORD,SeqChan:WORD
                pushf
                cli

                mov si,[Sequence]
                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]
                mov bx,[SeqChan]
                dec bx
                mov al,[si].state_table.chan_map[bx]
                mov ah,0
                inc ax

__exit:         POP_F
                ret
true_seq_channel ENDP

;****************************************************************************
branch_index    CPROC USES DS SI DI H:WORD,Sequence:WORD,Marker:BYTE
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]

                cmp WORD PTR [si].state_table.RBRN+2,0
                je __exit               ;no branch points, exit               


                les di,[si].state_table.RBRN        ;make sure RBRN chunk is still present
                cmp WORD PTR es:[di],'BR'
                jne __exit              ;if not, no branching is possible
                cmp WORD PTR es:[di+2],'NR'
                jne __exit      

                mov cx,es:[di+8]        ;get RBRN.cnt
                add di,10
                mov al,[Marker]         
__find_marker:  cmp es:[di],al
                je __marker_found
__find_next:    add di,6                ;sizeof(RBRN.entry)
                loop __find_marker
                jmp __exit              ;marker not found in RBRN chunk

__marker_found: mov ax,es:[di+2]        ;else get offset of target in EVNT
                mov dx,es:[di+4]        ;chunk
                add ax,8
                adc dx,0
                les di,[si].state_table.EVNT
                ADD_PTR ax,dx,es,di
                mov WORD PTR [si].state_table.EVNT_ptr,di
                mov WORD PTR [si].state_table.EVNT_ptr+2,es
                mov [si].state_table.interval_cnt,0
                INVOKE flush_note_queue,ds::si

                IF BRANCH_EXIT          ;cancel all FOR...NEXT loops if
                mov cx,FOR_NEST         ;BRANCH_EXIT is TRUE
                mov bx,0
__init_FOR:     mov [si].state_table.FOR_loop_cnt[bx],-1
                add bx,2
                loop __init_FOR
                ENDIF

__exit:         POP_F
                ret
branch_index    ENDP

;****************************************************************************
get_rel_tempo   CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]
                mov ax,[si].state_table.tempo_percent

__exit:         POP_F
                ret
get_rel_tempo   ENDP

;****************************************************************************
get_rel_volume  CPROC USES DS SI DI H:WORD,Sequence:WORD
                pushf
                cli

                mov si,[Sequence]
                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]
                mov ax,[si].state_table.vol_percent

__exit:         POP_F
                ret
get_rel_volume  ENDP


;****************************************************************************
set_rel_tempo   CPROC USES DS SI DI H:WORD,Sequence:WORD,Tempo:WORD,Grad:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]
                mov ax,[Tempo]
                mov [si].state_table.tempo_target,ax

                cmp [Grad],0
                je __immed

                mov ax,[si].state_table.tempo_target
                sub ax,[si].state_table.tempo_percent
                jz __exit               ;(no difference specified)
                cwd
                xor ax,dx
                sub ax,dx
                mov cx,ax               ;CX = tempo delta

                mov ax,10               ;get # of 100us periods/step
                mul [Grad]           
		INVOKE ul_divide,ax,dx,cx,0
                mov bx,ax
                or bx,dx
                jnz __nonzero
                mov ax,1
__nonzero:      mov [si].state_table.tempo_period_l,ax   
                mov [si].state_table.tempo_period_h,dx
                mov [si].state_table.tempo_accum_l,0
                mov [si].state_table.tempo_accum_h,0
                jmp __exit

__immed:        mov [si].state_table.tempo_percent,ax

__exit:         POP_F
                ret
set_rel_tempo   ENDP

;****************************************************************************
set_rel_volume  CPROC USES DS SI DI H:WORD,Sequence:WORD,Volume:WORD,Grad:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]
                mov ax,[Volume]
                mov [si].state_table.vol_target,ax

                cmp [Grad],0
                je __immed

                mov ax,[si].state_table.vol_target
                sub ax,[si].state_table.vol_percent
                jz __exit               ;(no difference specified)
                cwd
                xor ax,dx
                sub ax,dx
                mov cx,ax               ;CX = vol delta

                mov ax,10               ;get # of 100us periods/step
                mul [Grad]           
                INVOKE ul_divide,ax,dx,cx,0
                mov bx,ax
                or bx,dx
                jnz __nonzero
                mov ax,1
__nonzero:      mov [si].state_table.vol_period_l,ax   
                mov [si].state_table.vol_period_h,dx
                mov [si].state_table.vol_accum_l,0
                mov [si].state_table.vol_accum_h,0
                jmp __exit

__immed:        mov [si].state_table.vol_percent,ax
                INVOKE XMIDI_volume,ds::si

__exit:         POP_F
                ret
set_rel_volume  ENDP

;****************************************************************************
get_control_val CPROC USES DS SI DI H:WORD,Sequence:WORD,Chan:WORD,Control:WORD
                pushf
                cli

                mov si,[Sequence]

                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]

                mov bx,[Control]

                cmp bx,CALLBACK_TRIG    ;allow application to poll last
                jne __not_cb            ;callback trigger controller

                mov ax,[si].state_table.cur_callback
                jmp __exit

__not_cb:       mov bl,ctrl_hash[bx]
                cmp bl,-1
                je __exit               ;controller value not maintained, exit

                add bx,[Chan]
                dec bx
                mov al,BYTE PTR [si].state_table.chan_controls[bx]
                cbw                     ;else return current controller value

__exit:         POP_F
                ret
get_control_val ENDP

;****************************************************************************
set_control_val CPROC USES DS SI DI H:WORD,Sequence:WORD,Chan:WORD,Control:WORD,Val:WORD
                pushf
                cli

                mov si,[Sequence]
                cmp si,-1
                je __exit

                lds si,sequence_state[si]

                mov ax,[Chan]
                dec ax
                INVOKE XMIDI_control,ds::si,ax,[Control],[Val]

__exit:         POP_F
                ret
set_control_val ENDP

;****************************************************************************
get_chan_notes  CPROC USES DS SI DI H:WORD,Sequence:WORD,Chan:WORD
                pushf
                cli

                mov si,[Sequence]

                mov ax,-1
                cmp si,ax
                je __exit

                lds si,sequence_state[si]

                mov ax,0
                mov bx,0
                mov cx,[Chan]
                dec cx
__count_notes:  cmp [si].state_table.note_chan[bx],cl
                jne __next_note
                inc ax
__next_note:    inc bx
                cmp bx,MAX_NOTES
                jne __count_notes

__exit:         POP_F
                ret
get_chan_notes  ENDP

;****************************************************************************
lock_channel    CPROC USES DS SI DI H:WORD                  ;return 0 if no channel available
                                                      ;for locking
                pushf
                cli

                mov cx,-1               ;find highest channel # w/lowest note
                mov si,cx               ;activity
                mov ax,11000000b        ;skip locked and protected channels
__do_search:    mov di,MAX_TRUE_CHAN-1
__find_channel: test lock_status[di],al
                jnz __find_next      
                cmp active_notes[di],cl
                jae __find_next         ;'jae' gives priority to higher chans
                mov cl,active_notes[di]
                mov si,di
__find_next:    dec di
                cmp di,MIN_TRUE_CHAN-1  ;(1-based channel #'s)
                jge __find_channel

                cmp si,-1              
                jne __got_channel

                cmp ax,10000000b
                je __exit
                mov ax,10000000b        ;if no channels available for locking,
                jmp __do_search         ;ignore lock protection & try again

__got_channel:  or si,0b0h
                INVOKE send_MIDI_message,si,SUSTAIN,0
                and si,0fh
                INVOKE flush_channel_notes,si
                mov active_notes[si],0

                or lock_status[si],10000000b

__exit:         mov ax,si
                inc ax
                POP_F
                ret
lock_channel    ENDP

;****************************************************************************
release_channel CPROC USES DS SI DI H:WORD,Chan:WORD
                pushf
                cli
                
                mov si,[Chan]
                dec si
                test lock_status[si],10000000b
                jz __exit               ;channel not locked, exit
                and lock_status[si],01111111b

                mov active_notes[si],0  ;silence the channel
                or si,0b0h              ;(caller responsible for housekeeping)
                INVOKE send_MIDI_message,si,SUSTAIN,0
                INVOKE send_MIDI_message,si,ALL_NOTES_OFF,0

                and si,0fh              ;update channel controller values
                mov bx,si
                mov di,0
__for_ctrl:     mov dl,BYTE PTR global_controls[bx]
                cmp dl,-1               ;controller value was never set in
                je __next_ctrl          ;channel, skip it
                push bx
                and bl,0fh              ;else isolate channel #...
                or bl,0b0h              ;and send Control Change message
                mov al,logged_ctrls[di]
                INVOKE send_MIDI_message,bx,ax,dx
                pop bx
__next_ctrl:    add bx,NUM_CHANS        ;index next controller value
                inc di                  ;index next controller type
                cmp di,NUM_CONTROLS
                jne __for_ctrl

                and si,0fh
                mov al,global_program[si]
                cmp al,-1               ;update channel program #
                je __restore_pw
                or si,0c0h
                INVOKE send_MIDI_message,si,ax,0
__restore_pw:   and si,0fh              ;update channel pitch wheel
                mov al,global_pitch_l[si]
                cmp al,-1
                je __exit
                mov dl,global_pitch_h[si]
                cmp dl,-1
                je __exit
                or si,0e0h
                INVOKE send_MIDI_message,si,ax,dx

__exit:         POP_F
                ret
release_channel ENDP

;****************************************************************************
                END
