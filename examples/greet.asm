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
	20 &puts	; JSR puts
			;		; get name
	A9 <name		; LDA lo(&S)
	85 00		; STA 00
	A9 >name		; LDA hi(&S)
	85 01		; STA 01
	20 &gets	; JSR gets
			;		; print "Hello, "
	A9 <hello	; LDA lo(&H)
	85 00		; STA 00
	A9 >hello	; LDA hi(&H)
	85 01		; STA 01
	20 &puts	; JSR puts
			;		; print name
	A9 <name	; LDA lo(&S)
	85 00		; STA 00
	A9 >name	; LDA hi(&S)
	85 01		; STA 01
	20 &puts	; JSR puts
			;		; print "!\n"
	A9 <end		; LDA lo(&Z)
	85 00		; STA 00
	A9 >end		; LDA hi(&Z)
	85 01		; STA 01
	20 &puts	; JSR puts
	00		; BRK

:gets
	; Input memory 00-01 must point to a string buffer
	; Gets at most 256 characters (including null terminator).
	A0 00		; LDY #00
:gets_loop
	20 &getchar	; JSR getchar
	C9 0A		; CMP #'\n'
	F0 07		; BEQ +7
	91 00		; STA (00),Y
	C8		; INY
	D0 ~gets_loop	; BNE gets_loop
			;		; fall through if out of bounds
	A0 FF		; LDY #FF	; terminate at max 256th byte
			;		; append null terminator
	A9 00		; LDA #0
	91 00		; STA (00),Y
	60		; RTS

:puts
	; Input memory 00-01 must point to null-terminated string.
	; At most 256 bytes will be printed.
	A0 00		; LDY #00
:puts_loop
	B1 00		; LDA (00),Y
	C9 00		; CMP #0
	D0 01		; BNE +1
	60		; RTS
	20 &putchar	; JSR putchar
	C8		; INY
	D0 ~puts_loop	; BNE puts_loop
	60		; RTS -- out of bounds

:prompt	_	"What is your name?"
	_	0A ; newline
	_	00 ; null terminator

:hello	_	"Hello, "
	_	00 ; null terminator

:end	_	"!"
	_	0A ; newline
	_	00 ; null terminator

:name	_	; String buffer to end of RAM

