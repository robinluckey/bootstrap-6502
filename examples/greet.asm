;
; Prompts for your name, then says hello.
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
			;		; print prompt
	A9 <prompt	; LDA lo(&A)
	85 00		; STA 00
	A9 >prompt	; LDA hi(&A)
	85 01		; STA 01
	JSR &puts
			;		; get name
	A9 <name		; LDA lo(&S)
	85 00		; STA 00
	A9 >name		; LDA hi(&S)
	85 01		; STA 01
	JSR &gets
			;		; print "Hello, "
	A9 <hello	; LDA lo(&H)
	85 00		; STA 00
	A9 >hello	; LDA hi(&H)
	85 01		; STA 01
	JSR &puts
			;		; print name
	A9 <name	; LDA lo(&S)
	85 00		; STA 00
	A9 >name	; LDA hi(&S)
	85 01		; STA 01
	JSR &puts
			;		; print "!\n"
	A9 <end		; LDA lo(&Z)
	85 00		; STA 00
	A9 >end		; LDA hi(&Z)
	85 01		; STA 01
	JSR &puts
	BRK

:gets
	; Input memory 00-01 must point to a string buffer
	; Gets at most 256 characters (including null terminator).
	A0 00		; LDY #00
:gets_loop
	JSR &getchar
	C9 0A		; CMP #'\n'
	BEQ 07
	91 00		; STA (00),Y
	INY
	D0 ~gets_loop	; BNE gets_loop
			;		; fall through if out of bounds
	A0 FF		; LDY #FF	; terminate at max 256th byte
			;		; append null terminator
	A9 00		; LDA #0
	91 00		; STA (00),Y
	RTS

:puts
	; Input memory 00-01 must point to null-terminated string.
	; At most 256 bytes will be printed.
	A0 00		; LDY #00
:puts_loop
	B1 00		; LDA (00),Y
	C9 00		; CMP #0
	BNE 01
	RTS
	JSR &putchar
	INY
	BNE ~puts_loop	; BNE puts_loop
	RTS

:prompt	_	"What is your name?"
	_	0A ; newline
	_	00 ; null terminator

:hello	_	"Hello, "
	_	00 ; null terminator

:end	_	"!"
	_	0A ; newline
	_	00 ; null terminator

:name	_	; String buffer to end of RAM

