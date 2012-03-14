	ORG 1000

;
; print greeting
;
A91C	LDA LO:"ROBOS >"
8510	STA 10
A910	LDA HI:"ROBOS >"
8511	STA 11
2030FF	JSR FF30	; printsz()


;
; echo
;
20EEFF	JSR FFEE	; getchar()

C90A	CMP #'\n'	; end of line detected
D004	BNE +4
20DDFF	JSR FFDD	; putchar() -- echo the newline for nice exit
00	BRK		; or, RTS

2010FF	JSR FF10	; printhex()

4C0B10	JMP 100B	; repeat!

524F424F533E2000	"ROBOS> "
