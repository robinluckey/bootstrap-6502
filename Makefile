SRCDIR := src
OBJDIR := bin

SRCS := tohex.asm hexchars.asm
OBJS := $(addprefix $(OBJDIR)/,$(SRCS:.asm=.img))
SRCS := $(addprefix $(SRCDIR)/,$(SRCS))

$(OBJDIR)/%.img : $(SRCDIR)/%.asm
	cmd/hasm $< | cmd/pack > $@

EXE := $(OBJDIR)/run

# World's worst linker
#
# Sifts code location directives ("* = 1000") from each source file,
# then generates a run6502 command that loads each image at the correct
# location.
#
$(EXE) : $(OBJS) $(SRCS)
	echo 'run6502 -I 0000 -X 0000 -R 1000 -P FFDD -G FFEE \' > $@
	grep -E '\*\s*=' $(SRCS) \
  	  | sed -e 's/src\/\(.*\)\.asm:[^0-9A-F]*\([0-9A-F]\+\)/  -l \2 $(OBJDIR)\/\1.img \\/' >> $@
	chmod a+x $@

test : $(OBJDIR)/run
	echo 'Hello, world!' | $(OBJDIR)/run

clean :
	rm -f $(OBJS) $(EXE)
