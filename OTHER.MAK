
all:     	    \
#	digvesa.com \	
#	gf166.com   \
#	sb16.com    \
	digplay.obj \
	digplay0.obj

digvesa.com:  	digvesa.asm soundrv.inc prologue.mac vbeai.inc
	ml /AT /Cp /I. /Fedigvesa /Fodigvesa /Fldigvesa digvesa.asm	

gf166.com:      gf166.asm soundrv.inc prologue.mac 
	ml /AT /Cp /I. /Fegf166 /Fogf166 /Flgf166 gf166.asm	

sb16.com:      	sb16.asm soundrv.inc prologue.mac 
	ml /AT /Cp /I. /Fesb16 /Fosb16 /Flsb16 sb16.asm	

digplay.obj: 	digplay.asm prologue.mac
	ml /c /Cp /I. /Fodigplay /Fldigplay digplay.asm	

digplay0.obj: 	digplay.asm prologue.mac
	ml /c /Cp /I. /Fodigplay0 /Fldigplay0 /DLOADABLE_DRIVERS=0 digplay.asm	

clean:	
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
