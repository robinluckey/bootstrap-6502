;
; Prompts for your name, then says hello.
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
			;		; print prompt
	A9 <prompt	; LDA lo(&A)
	8500		; STA 00
	A9 >prompt	; LDA hi(&A)
	8501		; STA 01
	20 &puts	; JSR puts
			;		; get name
	A9 <name		; LDA lo(&S)
	8500		; STA 00
	A9 >name		; LDA hi(&S)
	8501		; STA 01
	20 &gets	; JSR gets
			;		; print "Hello, "
	A9 <hello	; LDA lo(&H)
	8500		; STA 00
	A9 >hello	; LDA hi(&H)
	8501		; STA 01
	20 &puts	; JSR puts
			;		; print name
	A9 <name		; LDA lo(&S)
	8500		; STA 00
	A9 >name		; LDA hi(&S)
	8501		; STA 01
	20 &puts	; JSR puts
			;		; print "!\n"
	A9 <end		; LDA lo(&Z)
	8500		; STA 00
	A9 >end		; LDA hi(&Z)
	8501		; STA 01
	20 &puts	; JSR puts
	00		; BRK

:gets
	; Input memory 00-01 must point to a string buffer
	; Gets at most 256 characters (including null terminator).
	A000		; LDY #00
:gets_loop
	20 &getchar	; JSR getchar
	C90A		; CMP #'\n'
	F007		; BEQ +7
	9100		; STA (00),Y
	C8		; INY
	D0 -0C		; BNE gets_loop
			;		; fall through if out of bounds
	A0FF		; LDY #FF	; terminate at max 256th byte
			;		; append null terminator
	A900		; LDA #0
	9100		; STA (00),Y
	60		; RTS

:puts
	; Input memory 00-01 must point to null-terminated string.
	; At most 256 bytes will be printed.
	A000		; LDY #00
:puts_loop
	B100		; LDA (00),Y
	C900		; CMP #0
	D001		; BNE +1
	60		; RTS
	20 &putchar	; JSR putchar
	C8		; INY
	D0 -0D		; BNE puts_loop
	60		; RTS -- out of bounds

:prompt	"What is your name?"
	0A ; newline
	00 ; null terminator

:hello	"Hello, "
	00 ; null terminator

:end	"!" 0A 00

:name	; String buffer to end of RAM

