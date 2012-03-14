%.asm %.img :
	cmd/hasm $< | cmd/pack > $@

all: bin/tohex.img bin/hexchars.img

bin/tohex.img : src/tohex.asm

bin/hexchars.img : src/hexchars.asm

test : all
	echo 'Hello, world!' | ./run

clean :
	rm -f bin/*.img
