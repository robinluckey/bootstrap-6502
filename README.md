# Bootstrapped 6502 Assembler

This is a fool's errand to bootstrap a complete 6502 assembler. I am doing
this for fun, with no expectation that it will be useful for anything.
The journey is the goal: to begin with (nearly) nothing, and to slowly craft
a functioning assembler. I am indebted to Edmund Grimly Evans for his
[detailed bootstrapping project description](http://homepage.ntlworld.com/edmund.grimley-evans/bcompiler.html),
which is the original inspiration for this project.

The original version of this assembler was a short length of hand-assembled hex
code. This resulted in a tiny program which, when fed a string of its own hex
source code, could emit its own object code.

From this starting point, each tiny feature was implemented using the features
already available: first came support for white space and line breaks, then
comments, then string literals, and most recently address labels.

## Runtime environment

I use Ian Piumarta's excellent [lib6502](http://piumarta.com/software) to
emulate a 6502 computer.

`run6502` must be installed on the path.

The design assumes that the entire 16-bit address space represents available
RAM, with the exception of the space above FFDD, which is reserved for
lib6502's getchar() and putchar() ROM subroutines.

The assembler code is not relocatable, and assumes that it will be loaded at
0x1000 and execution will begin there.

## HOWTO

Assemble source code to object code:

    $ cat foo.asm | cmd/run asm > foo.sym           # Pass 0
    $ cat foo.sym foo.asm | cmd/run asm > foo.img   # Pass 1

Execute:

    $ cmd/run foo.img

Disassemble object code to stdout:

    $ cmd/disasm foo.img

Build and run the example program:

    $ make examples/hello.img
    $ cmd/run hello.img
    Hello, World!

## Assembler Features

To call this an assembler is an overstatement. It accepts ASCII hex codes from
`stdin`, and emits bytes on `stdout`. It offers a few minimal "features" that
make it barely a language:

 - The location counter can be modified using the `*` pseudo-op, however all
   source code must be contiguous and begin at 0x1000. There is no linker.

 - A label can be assigned from the current 16-bit location counter using the
   `:` pseudo-op.

 - The 16-bit value of a label can be inserted with the `&` pseudo-op.

 - An 8-bit relative offset to a label can be inserted with the `~` pseudo-op.

 - It supports comments, which must begin with `;` and end at the next newline
   character.

 - It can emit a symbol table to allow forward label references.

An important thing that this assembler can _not_ yet do:

 - It does not recognize any opcode mnemonics. All actual machine instructions
   must be entered as hex codes.

## Two-pass assembly process

The assembler operates in two passes to provide support for forward label
references.

During pass 0, the input assembly is parsed, the location counter is
maintained, and labels are assigned their values, but no machine code is
output. Instead, when the end of the input is reached, the symbol table is
dumped to stdout. This symbol table takes the form of source code, which is
valid assembler input for the next pass.

During pass 1, the symbol table is prepended to the same input assembly, and
both are fed to the assembler. This enables the assembly code to refer to all
symbols, which now have all of their location values defined. Note that the
symbol table also begins with the 'P01' psuedo-op, which signals the assembler
to operate in pass 1 behavior.

## Two-generation compilation

`asm.asm` is the assembler source code, written in our minimal assembly
language, and `asm` is the reference master assembler object code. Both are
held in source control.

When compiling the assembler, the makefile will iterate two generations.

The `make` process will first use `asm` to compile generation 0 object code as
file `g0`. If this succeeds, it then uses `g0` to compile second-generation
object code `g1`. If `g0` and `g1` are bitwise identical, the test passes and
we assume that the new assembler functions properly. `make promote` can then be
used to permanently select `g1` as the new reference master assembler.

