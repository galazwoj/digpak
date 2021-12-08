
nosound.com:      shell.asm ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /DBUILD=2 /DNOSOUND=1 /Fenosound /Fonosound /Flnosound /Fmnosound shell.asm	

clean:
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
