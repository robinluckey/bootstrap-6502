;
; Prompts for your name, then says hello.
;

*FFDD	:putchar
*FFEE	:getchar

*1000	; Programs must begin at 0x1000

:main
			; print prompt
	LDA #<prompt
	85 00		; STA 00
	LDA #>prompt
	85 01		; STA 01
	JSR &puts
			; get name
	LDA #<name	; LDA lo(&S)
	85 00		; STA 00
	LDA #>name	; LDA hi(&S)
	85 01		; STA 01
	JSR &gets
			; print "Hello, "
	LDA #<hello
	85 00		; STA 00
	LDA #>hello
	85 01		; STA 01
	JSR &puts
			; print name
	LDA #<name
	85 00		; STA 00
	LDA #>name
	85 01		; STA 01
	JSR &puts
			; print "!\n"
	LDA #<end
	85 00		; STA 00
	LDA #>end
	85 01		; STA 01
	JSR &puts
	BRK

:gets
	; Input memory 00-01 must point to a string buffer
	; Gets at most 256 characters (including null terminator).
	A0 #00
:gets_loop
	JSR &getchar
	CMP #0A		; CMP #'\n'
	BEQ 07
	91 00		; STA (00),Y
	INY
	D0 ~gets_loop	; BNE gets_loop
			;		; fall through if out of bounds
	A0 #FF		; LDY #FF	; terminate at max 256th byte
			;		; append null terminator
	LDA #00
	91 00		; STA (00),Y
	RTS

:puts
	; Input memory 00-01 must point to null-terminated string.
	; At most 256 bytes will be printed.
	A0 #00
:puts_loop
	B1 00		; LDA (00),Y
	CMP #00
	BNE 01
	RTS
	JSR &putchar
	INY
	BNE ~puts_loop	; BNE puts_loop
	RTS

:prompt	_	"What is your name?\n\0"
:hello	_	"Hello, \0"
:end	_	"!\n\0"
:name	_	; String buffer to end of RAM

