
all:    digvesa.com 

digvesa.com:  	digvesa.asm ..\soundrv.inc ..\prologue.mac ..\vbeai.inc ..\compat.inc
	ml /AT /Cp /I.. /Fedigvesa /Fodigvesa /Fldigvesa /Fmdigvesa digvesa.asm	

clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
