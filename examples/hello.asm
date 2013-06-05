;
; Hello World Example
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main					; 1000
	A900		; LDA #00
	AA		; TAX

:loop					; 1003
	BD @hello	; LDA hello, X
	C900		; CMP #0
	D001		; BNE +1
	00		; BRK
	20 @putchar	; JSR putchar
	E8		; INX
	4C @loop	; JMP loop

:hello					; 1012
	"Hello, World!"
	0A	; newline
	00	; null terminator
