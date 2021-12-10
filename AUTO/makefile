all:    	digauto.com	\
	        fullauto.com

digauto.com:    auto.asm 	\
		..\compat.inc   \
		..\soundrv.inc  \
		..\prologue.mac \
		GF166.INC       \
		SBLASTER.INC    \
		PAS16.INC       \
		PAUDIO.INC      \
		SBPRO.INC       \
		SB16.INC     
	ml /AT /Cp /I. /I.. /Fedigauto /Fodigauto /Fldigauto /Fmdigauto auto.asm	

fullauto.com:    auto.asm 	\
		..\compat.inc   \
		..\soundrv.inc  \
		..\prologue.mac \
		GF166.INC       \
		SBLASTER.INC    \
		PAS16.INC       \
		PAUDIO.INC      \
		SBPRO.INC       \
		SB16.INC     
	ml /AT /Cp /I. /I.. /DALLDRIVERS=1 /Fefullauto /Fofullauto /Flfullauto /Fmfullauto auto.asm	



#GF166.INC:	GF166.COM	
#	com2asm.exe GF166.COM    >	GF166.INC
#	
#SBLASTER.INC:   SBLASTER.COM	
#	com2asm.exe SBLASTER.COM >	SBLASTER.INC
#
#PAS16.INC:      PAS16.COM	
#	com2asm.exe PAS16.COM    >	PAS16.INC
#
#PAUDIO.INC:     PAUDIO.COM	
#	com2asm.exe PAUDIO.COM   >	PAUDIO.INC
#
#SBPRO.INC:      SBPRO.COM	
#	com2asm.exe SBPRO.COM    >	SBPRO.INC
#
#SB16.INC:       SB16.COM	
#	com2asm.exe SB16.COM     >	SB16.INC
#
com2asm.exe:
	bcc com2asm.c

clean:
	-del *.obj
	-del *.map
	-del *.lst

cclean:	clean
	-del *.com
	-del *.exe
