all:			\
	ibmbak.com     	\
	ibmsnd.com     	\
	adlib.com     	\
	vmsnd.com      	\
	smsnd.com      	\
	digisp.com    	\
	tanextx.com   	\
	echoii.com    	\
	lantsnd.com    	\
	ibm1bit.com  	\
	bigmouth.com      	

# Build just the orphan digpak drivers.
                               
ibmbak.com:     shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Foibmbak   /Feibmbak   /Flibmbak   /DBUILD=13 shell.asm
		                                       
ibmsnd.com:     shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Foibmsnd   /Feibmsnd   /Flibmsnd   /DBUILD=5  shell.asm
		                                       
adlib.com:      shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Foadlib    /Feadlib    /Fladlib    /DBUILD=1  shell.asm
		                                       
vmsnd.com:      shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Fovmsnd    /Fevmsnd /Flvmsnd /Fmvmsnd /DBUILD=3  shell.asm
		                                       
smsnd.com:      shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Fosmsnd    /Fesmsnd /Flsmsnd /Fmsmsnd /DBUILD=4  shell.asm
		                                       
digisp.com:     shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Fodigisp   /Fedigisp   /Fldigisp   /DBUILD=6  shell.asm
		                                       
# Used on Tandy 3 voice systems.  None of these machines are VGA, driver
# only applicable when addressing extremely low end hardware, like the
# PC Jr <g>                                            
tanextx.com:    shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Fotanextx  /Fetanextx  /Fltanextx  /DBUILD=7  shell.asm
		                                       
# Street Electronics Echo II.  Used in schools primarily.
echoii.com:     shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Foechoii   /Feechoii   /Flechoii   /DBUILD=11 shell.asm
		                                       
# Lantastic Voice Adapter.  Not a wide scale consumer device.
lantsnd.com:    shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                    
		ml /AT /Cp /I. /Folantsnd  /Felantsnd  /Fllantsnd  /DBUILD=12 shell.asm
		                                       
# 1 bit digital audio PC Speaker Driver.  Lousy quality, but least
# intrusive on running application.        
ibm1bit.com:    shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Foibm1bit  /Feibm1bit  /Flibm1bit  /DBUILD=14 shell.asm
		                                       
# Talking Technologies BigMouth.  No one actually owns this device.
# A highly orphan piece of hardware.       
bigmouth.com:   shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. /Fobigmouth /Febigmouth /Flbigmouth /Fmbigmouth /DBUILD=16 shell.asm

clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
        
