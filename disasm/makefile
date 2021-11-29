
all:     	    \
#	sb16.com    \
	gf1digi.com \
	gf166.com   \
	digvesa.com 

digvesa.com:  	digvesa.asm ..\soundrv.inc ..\prologue.mac ..\vbeai.inc ..\compat.inc
	ml /AT /Cp /I.. /Fedigvesa /Fodigvesa /Fldigvesa /Fmdigvesa digvesa.asm	

gf166.com:      gf166.asm ..\soundrv.inc ..\prologue.mac ..\compat.inc
	ml /AT /Cp /I.. /I..\gravis /Fegf166 /Fogf166 /Flgf166 /Fmgf166 gf166.asm	

gf1digi.com:      gf1digi.asm  
	ml /AT /Cp /I..\gravis /Fegf1digi /Fogf1digi /Flgf1digi /Fmgf1digi gf1digi.asm	


sb16.com:      	sb16.asm ..\soundrv.inc ..\prologue.mac ..\compat.inc
	ml /AT /Cp /I.. /Fesb16 /Fosb16 /Flsb16 sb16.asm	

clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
