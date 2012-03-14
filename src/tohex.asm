;
; Print ASCII hex codes for characters read from STDIN
;

	* = 1000

20EEFF	JSR FFEE	; getchar()

C90A	CMP #'\n'	; end of line detected
D004	BNE +4
20DDFF	JSR FFDD	; putchar() -- echo the newline for nice exit
00	BRK		; or, RTS

AA	TAX		; backup
4A	LSR A		; high order nibble
4A	LSR A
4A	LSR A
4A	LSR A
A8	TAY		; lookup hex char
18	CLC
B900FF	LDA FF00,Y
20DDFF	JSR FFDD	; putchar()

8A	TXA		; restore
290F	AND #0F		; low order nibble
A8	TAY		; lookup hex char
18	CLC
B900FF	LDA FF00,Y
20DDFF	JSR FFDD	; putchar()

4C0010	JMP 1000	; repeat!
