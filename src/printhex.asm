;
; Print ASCII hex codes for characters read from STDIN
;

	ORG FF10

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

60	RTS
