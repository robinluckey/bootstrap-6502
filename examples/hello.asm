;
; Hello World Example
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main					; 1000
	A9 #00		; LDA #00
	TAX

:loop					; 1003
	BD &hello	; LDA hello, X
	C9 #00		; CMP #0
	BNE 01
	BRK
	JSR &putchar
	INX
	BNE ~loop

:hello					; 1011
	_	"Hello, World!"
	_	0A	; newline
	_	00	; null terminator
