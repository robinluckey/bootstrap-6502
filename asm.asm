;*=1000

	; Forward jump to init.
	; Address must be calculated,
	; or copied from disassembly.
	;
4C7210	; JMP &I

.C	; skip_comment()
	;
20EEFF	; JSR FFEE	; getchar()
C90A	; CMP #'\n'
D0F9	; BNE -7
60	; RTS

.D	; define_label()
	;
20EEFF	; JSR FFEE	; getchar()
18	; CLC
69B9	; ADC #B9	; 'A'-'Z' -> 0...
AA	; TAX
A580	; LDA 80	; location counter
9520	; STA 20,X	; values stored from 20...
60	; RTS

.E	; eval_label()
	;
20EEFF	; JSR FFEE	; getchar()
18	; CLC
69B9	; ADC #B9	; 'A'-'Z' -> 0...
AA	; TAX
B520	; LDA 20,X
20DDFF	; JSR FFDD	; putchar()
E680	; INC 80	; location counter
A910	; LDA #10
20DDFF	; JSR FFDD	; putchar()
E680	; INC 80	; location counter
60	; RTS

.R	; parse_hex_byte()
	;
	; hi nibble
	;
C93A	; CMP #3A
9002	; BCC .+2
69F8	; ADC #F8	
290F	; AND #0F
0A	; ASL A
0A	; ASL A
0A	; ASL A
0A	; ASL A
8510	; STA 10
	;
	; lo nibble
	;
20EEFF	; JSR FFEE	; getchar()
C93A	; CMP #3A
9002	; BCC .+2
69F8	; ADC #F8	
290F	; AND #0F
0510	; ORA 10
60	; RTS

.X	; "0123456789ABCDEF"
30313233343536373839414243444546

.P	; printhex
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B9 &X	; LDA &X,Y
20DDFF	; JSR FFDD	; putchar()

8A	; TXA		; restore
290F	; AND #0F	; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B9 &X	; LDA &X,Y
20DDFF	; JSR FFDD	; putchar()

60	; RTS

.I	; init
	;
A900	; LDA #00
8580	; STA 80	; location counter

.L	; loop
	;
20EEFF	; JSR FFEE	; getchar()
C9FF	; CMP #FF	; EOF?
D001	; BNE +1
00	; BRK
	;
C920	; CMP #' '	; skip white space
F0F4	; BEQ L		; -12
C909	; CMP #'\t'
F0F0	; BEQ L		; -16
C90A	; CMP #'\n'
F0EC	; BEQ L		; -20
	;
	;		; switch on pseudo-op
C92E	; CMP #'.'
D006	; BNE +6
20 &D	; JSR		; define_label()
4C &L	; JMP
	;
C926	; CMP #'&'
D006	; BNE +6
20 &E	; JSR		; eval_label()
4C &L	; JMP &L
	;
C93B	; CMP #';'
D006	; BNE +6
20 &C	; JSR		; skip_comment()
4C &L	; JMP
	;		; else eval as hex machine code
20 &R	; JSR		; parse_hex_byte()
20DDFF	; JSR FFDD	; putchar()
E680	; INC 80	; location counter
	;
4C &L	; JMP
;
