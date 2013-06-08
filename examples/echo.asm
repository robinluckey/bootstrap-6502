;
; Echo
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
	JSR &getchar
	C9 FF		; CMP EOF?
	BNE 01
	BRK
	JSR &putchar
	JMP &main
