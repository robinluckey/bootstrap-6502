test : g0 g1
	diff g0 g1

g1 : g0 asm.asm
	cmd/run g0 < asm.asm > g1

g0 : asm.asm
	cmd/run asm.img < asm.asm > g0

clean :
	rm -f g0 g1

promote : g1
	diff g0 g1 && cp g1 asm.img	
