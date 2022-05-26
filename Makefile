PROJECT = kernel
OBJS = \
	main.prg \
	alloc.prg \
	append.prg \
	chdir.prg \
	checkeof.prg \
	checkeom.prg \
	checkwrt.prg \
	chkvld.prg \
	cklstlmp.prg \
	close.prg \
	coldboot.prg \
	create.prg \
	dealloc.prg \
	delchain.prg \
	delete.prg \
	exec.prg \
	execbin.prg \
	execdir.prg \
	finalsl.prg \
	finddir.prg \
	findsep.prg \
	follow.prg \
	freedir.prg \
	freelump.prg \
	getfddrof.prg \
	getfdeof.prg \
	getfdflgs.prg \
	getfddwrd.prg \
	getsecofs.prg \
	gettmdt.prg \
	incofs.prg \
	kinit.prg \
	loadsec.prg \
	lmpsecofs.prg \
	lmpsize.prg \
	lumptosec.prg \
	mkdir.prg \
	open.prg \
	opendir.prg \
	openmd.prg \
	rawread.prg \
	rawwrite.prg \
	read.prg \
	readlump.prg \
	readsys.prg \
	reapheap.prg \
	rename.prg \
	rmdir.prg \
	searchdir.prg \
	secloaded.prg \
	secofslmp.prg \
	sectolump.prg \
	sector0.prg \
	seek.prg \
	seekend.prg \
	setdef.prg \
	setfddrof.prg \
	setfdeof.prg \
	setfdflgs.prg \
	setfddwrd.prg \
	settrx.prg \
	setupfd.prg \
	start.prg \
	startlump.prg \
	validate.prg \
	write.prg \
	writelump.prg \
	writesys.prg \
        final.prg

.SUFFIXES: .asm .prg

kernel.bin: $(OBJS)
	asm02 -l -L main.asm
	link02 $(OBJS) -s -b -o kernel.bin

.asm.prg:
	asm02 -l -L $<

clean:
	-rm *.prg
	-rm $(PROJECT).bin


