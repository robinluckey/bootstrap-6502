;
; Prompts for your name, then says hello.
;

*1000	; Programs must begin at 0x1000

.M	; main
	;
	; print prompt
	;
A9 <A	; LDA lo(&A)
8500	; STA 00
A9 >A	; LDA hi(&A)
8501	; STA 01
20 &P	; JSR print_string
	;
	; get name
	;
A9 <S	; LDA lo(&S)
8500	; STA 00
A9 >S	; LDA hi(&S)
8501	; STA 01
20 &G	; JSR get_line
	;
	; print "Hello, "
	;
A9 <H	; LDA lo(&H)
8500	; STA 00
A9 >H	; LDA hi(&H)
8501	; STA 01
20 &P	; JSR print_string
	;
	; print name
	;
A9 <S	; LDA lo(&S)
8500	; STA 00
A9 >S	; LDA hi(&S)
8501	; STA 01
20 &P	; JSR print_string
	;
	; print "!\n"
	;
A9 <Z	; LDA lo(&Z)
8500	; STA 00
A9 >Z	; LDA hi(&Z)
8501	; STA 01
20 &P	; JSR print_string
	;
00	; BRK

.G	; get_line
	;
	; Input memory 00-01 must point to a string buffer.
	; Gets at most 256 characters (including null terminator).
	;
A000	; LDY #00
	;
	; .loop
20EEFF	; JSR getchar
C90A	; CMP #'\n'
F007	; BEQ +7
9100	; STA (00),Y
C8	; INY
D0 -0C	; BNE .loop
	;
	; fall through if out of bounds
A0FF	; LDY #FF ; terminate at max 256th byte
	;
	; append null terminator
	;
A900	; LDA #0
9100	; STA (00),Y
60	; RTS

.P	; print_string
	;
	; Input memory 00-01 must point to null-terminated string.
	; At most 256 bytes will be printed.
	;
A000	; LDY #00
	;
	; .loop
B100	; LDA (00),Y
C900	; CMP #0
D001	; BNE +1
60	; RTS
20DDFF	; JSR putchar
C8	; INY
D0 -0D	; BNE loop
60	; RTS -- out of bounds

.A	"Enter your name: "
	00 ; null terminator

.H	"Hello, "
	00 ; null terminator

.Z	"!" 0A 00

.S	; String buffer to end of RAM

