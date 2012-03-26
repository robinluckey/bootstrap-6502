test : g0 g1
	diff g0 g1

g1 : g0 asm.asm g1.sym
	cat g1.sym asm.asm | cmd/run g0 > g1

g1.sym: g0 asm.asm
	cat asm.asm | cmd/run g0 > g1.sym

g0 : asm.asm g0.sym
	cat g0.sym asm.asm | cmd/run asm.img > g0

g0.sym : asm.asm
	cat asm.asm | cmd/run asm.img > g0.sym

clean :
	rm -f g0 g1 *.sym

promote : g1
	diff g0 g1 && cp g1 asm.img	
