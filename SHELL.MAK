all:			\
	pas16.com      	\
	paudio.com	\
	adlibg.com     	\
	aria.com       	\
	sblaster.com	\
	nosound.com	\
	sbclone.com	\
	tansltl.com	\
	lsize.com	\
	sbpro.com	\
	cvxsnd.com	\
	source.com	\
	STFX.com		

# Builds all of the digpak drivers from SHELL.ASM BUT does not build the
# orphan drivers.  Run ORPHAN.MAK to build the orphan sound drivers that
# neither me nor you, or nearly anyone for that matter, cares about.
					
pas16.com:      shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
		ml /AT /Cp /I. 	/Fepas16    /Fopas16    /Flpas16    /DBUILD=15 /DPAS16=1  	shell.asm	
		                                                                                            
paudio.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fepaudio   /Fopaudio   /Flpaudio   /DBUILD=15 	      		shell.asm			
		                                                                                            
adlibg.com:     shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I.	/Feadlibg   /Foadlibg   /Fladlibg   /DBUILD=18 	      		shell.asm			
		                                                                                            
aria.com:       shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I.	/Fearia     /Foaria     /Flaria     /DBUILD=20 	      		shell.asm			
		                                                                                            
sblaster.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I.	/Fesblaster /Fosblaster /Flsblaster /DBUILD=9 	      		shell.asm			
		                                                                                            
nosound.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fenosound  /Fonosound  /Flnosound  /DBUILD=2 /DNOSOUND=1 	shell.asm	
		                                                                                            
sbclone.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fesbclone  /Fosbclone  /Flsbclone  /DBUILD=9 /DSBCLONE=1 	shell.asm	
		                                                                                            
# Uses the Tandy ROM BIOS calls for digital audio available on the                         
# SL/TL line of Tandy machines.                                                                             
                                                                                                            
tansltl.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fetansltl  /Fotansltl  /Fltansltl  /DBUILD=8 	       		shell.asm			
		                                                                                            
lsize.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Felsize    /Folsize    /Fllsize    /DBUILD=2 /DLIFESIZE=1 	shell.asm	
		                                                                                            
sbpro.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fesbpro    /Fosbpro    /Flsbpro    /DBUILD=9 /DSBPRO=1 	shell.asm		
		                                                                                            
cvxsnd.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fecvxsnd   /Focvxsnd   /Flcvxsnd /Fmcvxsnd  /DBUILD=2 		shell.asm			
		                                                                                            
source.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/Fesource   /Fosource   /Flsource   /DBUILD=10 			shell.asm			
		                                                                                            
STFX.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                           
		ml /AT /Cp /I. 	/FeSTFX     /FoSTFX     /FlsSTFX    /DBUILD=9 /DSTFX=1 		shell.asm	
		  
clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
