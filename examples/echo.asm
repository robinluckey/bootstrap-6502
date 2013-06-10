;
; Echo
;

*FFDD	:putchar
*FFEE	:getchar

*00FF	:eof

*1000	; Programs must begin at 0x1000

:main
	JSR &getchar
	CMP #<eof
	BNE 01
	BRK
	JSR &putchar
	JMP &main
