;
; Hello World Example
;

*1000	; Programs must begin at 0x1000

	A900	; LDA #00
	AA	; TAX

.L
	BD &H	; LDA &H, X
	C900	; CMP #0
	D001	; BNE +1
	00	; BRK
	20DDFF	; JSR putchar
	E8	; INX
	4C &L	; JMP &L

.H	"Hello, World!"
	0A	; newline
	00	; null terminator
