;
; Hello World Example
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main					; 1000
	A9 00		; LDA #00
	AA		; TAX

:loop					; 1003
	BD &hello	; LDA hello, X
	C9 00		; CMP #0
	D0 01		; BNE +1
	00		; BRK
	20 &putchar	; JSR putchar
	E8		; INX
	D0 ~loop	; BNE loop

:hello					; 1011
	_	"Hello, World!"
	_	0A	; newline
	_	00	; null terminator
