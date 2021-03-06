all : test examples

test : g0 g1
	diff g0 g1

g1 : g0 asm.asm g1.sym
	cat g1.sym asm.asm | cmd/run g0 > g1

g1.sym: g0 asm.asm
	cat asm.asm | cmd/run g0 > g1.sym

g0 : asm.asm g0.sym
	cat g0.sym asm.asm | cmd/run asm > g0

g0.sym : asm.asm
	cat asm.asm | cmd/run asm > g0.sym

clean :
	rm -f g0 g1 *.sym *.img examples/*.sym examples/*.img

promote : g1
	diff g0 g1 && cp g1 asm

%.img : %.asm
	cat $< | cmd/run asm > $(basename $@).sym
	cat $(basename $@).sym $< | cmd/run asm > $@

EXAMPLES_SRC=$(shell ls examples/*.asm)
EXAMPLES_IMG=$(shell ls examples/*.asm | sed 's/.asm/.img/')

examples : $(EXAMPLES_IMG)
