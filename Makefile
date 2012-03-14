SRCDIR := src
OBJDIR := bin

SRCS := tohex.asm hexchars.asm
OBJS := $(addprefix $(OBJDIR)/,$(SRCS:.asm=.img))

$(OBJDIR)/%.img : $(SRCDIR)/%.asm
	cmd/hasm $< | cmd/pack > $@

all : $(OBJS)

test : all
	echo 'Hello, world!' | ./run

clean :
	rm -f $(OBJS)
