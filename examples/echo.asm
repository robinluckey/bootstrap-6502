;
; Echo
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
	20 &getchar	; JSR getchar
	C9 FF		; CMP EOF?
	D0 01		; BNE +1
	00		; BRK
	20 &putchar	; JSR putchar
	4C &main	; JMP main
