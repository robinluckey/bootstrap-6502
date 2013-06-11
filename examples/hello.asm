;
; Hello World Example
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
	LDX #00

:loop
	BD &hello	; LDA hello, X
	BNE 01
	BRK
	JSR &putchar
	INX
	BNE ~loop

:hello
	_	"Hello, World!\n\0"
