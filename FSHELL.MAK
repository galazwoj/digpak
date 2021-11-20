all:			\
	ft2500.com  	\
	fibmbak.com 	\
	fadlib.com 	\
	fcvxsnd.com 	\
	fvmsnd.com 	\
	fsmsnd.com 	\
	ftanextx.com 	\
	fsource.com 	\
	fechoii.com 	\
	fibm1bit.com 	\
	fbigmout.com 	
		              
ft2500.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc
	ml /AT /Cp /I. /Foft2500   /Feft2500   /Flft2500   /Fmft2500   /DBUILD=19                shell.asm
		                            	         	         	
fibmbak.com: 	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                           
	ml /AT /Cp /I. /Fofibmbak  /Fefibmbak  /Flfibmbak  /Fmfibmbak  /DBUILD=13 /DFOREGROUND=1 shell.asm
		                            	         	         	
fadlib.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                            
	ml /AT /Cp /I. /Fofadlib   /Fefadlib   /Flfadlib   /Fmfadlib   /DBUILD=1  /DFOREGROUND=1 shell.asm
		                            	         	         	
fcvxsnd.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                           
	ml /AT /Cp /I. /Fofcvxsnd  /Fefcvxsnd  /Flfcvxsnd  /Fmfcvxsnd  /DBUILD=2  /DFOREGROUND=1 shell.asm
		                            	         	         	
fvmsnd.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                            
	ml /AT /Cp /I. /Fofvmsnd   /Fefvmsnd   /Flfvmsnd   /Fmfvmsnd   /DBUILD=3  /DFOREGROUND=1 shell.asm
		                            	         	         	
fsmsnd.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                            
	ml /AT /Cp /I. /Fofsmsnd   /Fefsmsnd   /Flfsmsnd   /Fmfsmsnd   /DBUILD=4  /DFOREGROUND=1 shell.asm
		                            	         	         	
ftanextx.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                          
	ml /AT /Cp /I. /Foftanextx /Feftanextx /Flftanextx /Fmftanextx /DBUILD=7  /DFOREGROUND=1 shell.asm
		                            	         	         	                           
fsource.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                    
	ml /AT /Cp /I. /Fofsource  /Fefsource  /Flfsource  /Fmfsource  /DBUILD=10 /DFOREGROUND=1 shell.asm
		                            	         	         	                           
fechoii.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                    
	ml /AT /Cp /I. /Fofechoii  /Fefechoii  /Flfechoii  /Fmfechoii  /DBUILD=11 /DFOREGROUND=1 shell.asm
		                            	         	         	                           
fibm1bit.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                   
	ml /AT /Cp /I. /Fofibm1bit /Fefibm1bit /Flfibm1bit /Fmfibm1bit /DBUILD=14 /DFOREGROUND=1 shell.asm
		                            	         	         	                           
fbigmout.com:	shell.asm soundrv.inc prologue.mac common.inc state.inc vbeai.inc compat.inc                                                  
	ml /AT /Cp /I. /Fofbigmout /Fefbigmout /Flfbigmout /Fmfbigmout /DBUILD=16 /DFOREGROUND=1 shell.asm
		                                                                 
clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
          
