
multisnd.com:      msnd33.asm msdspini.asm msdsperm.asm msnd_dsp.equ msnd.inc ..\compat.inc ..\soundrv.inc ..\prologue.mac 
	ml /AT /Cp /I.. /DMSND=1 /Femultisnd /Fomultisnd /Flmultisnd /Fmmultisnd msnd33.asm	

clean:
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
