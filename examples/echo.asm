;
; Echo
;

*1000	; Programs must begin at 0x1000

.L
	20EEFF	; JSR getchar
	C9FF	; CMP EOF?
	D001	; BNE +1
	00	; BRK
	20DDFF	; JSR putchar
	4C &L	; JMP &L
