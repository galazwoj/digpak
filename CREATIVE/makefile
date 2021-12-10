all: 		sblaster.com \
		sbpro.com    \
		sb16.com     \
		stfx.com     \
		sbclone.com

sblaster.com:	creative.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /Fesblaster /Fosblaster /Flsblaster /Fmsblaster /DBUILD=9 /DSBLASTER=1 creative.asm	

sbpro.com:	creative.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /Fesbpro    /Fosbpro    /Flsbpro    /Fmsbpro    /DBUILD=9 /DSBPRO=1    creative.asm	

sb16.com:      	creative.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /Fesb16     /Fosb16     /Flsb16     /Fmsb16     /DBUILD=9 /DSB16=1     creative.asm	

stfx.com:      	creative.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /Festfx     /Fostfx     /Flstfx     /Fmstfx     /DBUILD=9 /DSTFX=1     creative.asm	

sbclone.com:   	creative.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /Fesbclone  /Fosbclone  /Flsbclone  /Fmsbclone  /DBUILD=9 /DSBCLONE=1  creative.asm	

clean:
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
	                                                                