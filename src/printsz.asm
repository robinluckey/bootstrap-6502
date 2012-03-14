;
; Print null-terminated string to stdout
;
; in: pointer to string at memory location 10
;
	ORG FF30

A000	LDY #0
B110	LDA (10),Y
D001	BNE +1
60	RTS

20DDFF	JSR FFDD	; putchar()
C8	INY
D0F5	BNE -11
60	RTS
