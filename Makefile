SRCDIR := src
OBJDIR := bin

SRCS := main.asm printhex.asm hexchars.asm printsz.asm
OBJS := $(addprefix $(OBJDIR)/,$(SRCS:.asm=.img))
SRCS := $(addprefix $(SRCDIR)/,$(SRCS))

$(OBJDIR)/%.img : $(SRCDIR)/%.asm
	cmd/hasm $< | cmd/pack > $@

EXE := $(OBJDIR)/run

$(EXE) : $(OBJS) $(SRCS) map
	echo 'run6502 -I 0000 -X 0000 -R 1000 -P FFDD -G FFEE \' > $@
	sed -e 's/\(\w\+\)\s\+\(\w\+\)/ -l \1 $(OBJDIR)\/\2.img \\/' map >> $@
	chmod a+x $@

map : $(SRCS)
	grep 'ORG ' $(SRCS) \
	  | sed -e 's/.\+\/\(.\+\)\.asm:\s\+ORG\s\+\([0-9A-Fa-f]\+\)/\2  \1/' \
	  | sort > map

test : $(EXE)
	echo 'Hello, world!' | $(OBJDIR)/run

clean :
	rm -f $(OBJS) $(EXE) map
