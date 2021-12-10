
splay.exe:	splay.c digplay.h digplay0.obj
	bcc -ml -M splay.c digplay0.obj

digplay0.obj: 	digplay.asm ..\prologue.mac
	ml /c /Cp /I.. /Fodigplay0 /Fldigplay0 /DLOADABLE_DRIVERS=0 digplay.asm	

digplay.obj: 	digplay.asm ..\prologue.mac
	ml /c /Cp /I.. /Fodigplay /Fldigplay digplay.asm	

clean:
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del splay.exe
