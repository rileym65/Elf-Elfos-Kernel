PROJECT = kernel

$(PROJECT).prg: $(PROJECT).asm bios.inc
	../../date.pl > date.inc
	./build.pl > build.inc
	cpp $(PROJECT).asm -o - | sed -e 's/^#.*//' > temp.asm
	rcasm -l -v -x -d1802 temp | tee kernel.lst
	cat temp.prg | sed -f adjust.sed > x.prg
	rm temp.prg
	mv x.prg kernel.prg

clean:
	-rm $(PROJECT).prg


