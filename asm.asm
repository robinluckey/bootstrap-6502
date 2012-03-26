P01
*1000

	; Forward jump to last instruction.
	; The address must be calculated,
	; then hand-copied here.
	;
4C6811	; JMP ????

.N	; incr_loc
	;
E680	; INC 80
D002	; BNE +2
E681	; INC 81
60	; RTS

.C	; skip_comment
	;
20EEFF	; JSR FFEE	; getchar()
C90A	; CMP #'\n'
D0F9	; BNE -7
60	; RTS

.D	; define_label
	;
20EEFF	; JSR getchar
18	; CLC
69BF	; ADC #B9	; 'A'-'Z' -> 0...
0A	; ASL A		; sizeof(label) = 2
AA	; TAX
A580	; LDA 80	; location counter
9520	; STA 20,X	; values stored from 20...
A581	; LDA 81
9521	; STA 21,X
60	; RTS

.E	; eval_label
	;
20EEFF	; JSR getchar
18	; CLC
69BF	; ADC #B9	; 'A'-'Z' -> 0...
0A	; ASL A		; sizeof(label) = 2
AA	; TAX
B520	; LDA 20,X
20DDFF	; JSR putchar
20 &N	; JSR incr_loc
B521	; LDA 21,X
20DDFF	; JSR putchar
20 &N	; JSR incr_loc
60	; RTS

.X	; hex_digits
	;
	"0123456789ABCDEF"

.P	; printhex
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B9 &X	; LDA hex_digits,Y
20DDFF	; JSR putchar

8A	; TXA		; restore
290F	; AND #0F	; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B9 &X	; LDA hex_digits,Y
20DDFF	; JSR putchar

60	; RTS

.Y	; print_symbol_table
	;
A90A	; LDA #"\n"
20DDFF	; JSR putchar
A9 "P"	; LDA #"P"
20DDFF	; JSR putchar
A901	; LDA #1
20 &P	; JSR printhex
A90A	; LDA #"\n"
20DDFF	; JSR putchar
	;
	;
A200	; LDX #00
	;
.Z	;
	;
A9 "*"	; LDA #"*"
20DDFF	; JSR putchar
B521	; LDA 21,X
DA	; PHX
20 &P	; JSR printhex
FA	; PLX
B520	; LDA 20,X
DA	; PHX
20 &P	; JSR printhex
FA	; PLX
A9 " "	; LDA #" "
20DDFF	; JSR putchar
	;
A9 "."	; LDA #"."
20DDFF	; JSR putchar
8A	; TXA
4A	; LSR A
18	; CLC
6941	; ADC #41	; 0... -> 'A'-'Z'
20DDFF	; JSR putchar
A90A	; LDA #"\n"
20DDFF	; JSR putchar
	;
E8	; INX
E8	; INX
8A	; TXA
C934	; CMP #34
D001	; BNE +1
60	; RTS
4C &Z	; JMP &Z

.S	; string_literal
	;
20EEFF	; JSR getchar
C922	; CMP #'"'
D001	; BNE +1
60	; RTS
20DDFF	; JSR putchar
20 &N	; JSR incr_loc
4C &S	; JMP string_literal


.R	; parse_hex_byte
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
20EEFF	; JSR getchar
C93A	; CMP #3A
9002	; BCC .+2
69F8	; ADC #F8	
290F	; AND #0F
0510	; ORA 10
60	; RTS

.O	; set_org
	;
20EEFF	; JSR getchar
20 &R	; JSR parse_hex_byte
8581	; STA 81	; MSB first
20EEFF	; JSR getchar
20 &R	; JSR parse_hex_byte
8580	; STA 80	; 16-bit location counter
60	; RTS

.Q	; set_pass
	;
20EEFF	; JSR getchar
20 &R	; JSR parse_hex_byte
8582	; STA 82
60	; RTS

.I	; init
	;
A900	; LDA #00
8580	; STA 80	; 16-bit location counter
A910	; LDA #10
8581	; STA 81
A900	; LDA #00
8582	; STA 82	; pass 0 by default

.L	; loop
	;
20EEFF	; JSR getchar
C9FF	; CMP #FF	; EOF?
D00A	; BNE +10
A582	; LDA 82
C900	; CMP #0
D003	; BNE +3
20 &Y	; JSR print_symbol_table
00	; BRK
	;
C9 " "	; CMP #' '	; skip white space
F0EB	; BEQ loop	; -21 -15
C909	; CMP #'\t'
F0E7	; BEQ loop	; -25 -19
C90A	; CMP #'\n'
F0E3	; BEQ loop	; -29 -23
	;
	;		; switch on pseudo-op
C9 "*"	; CMP #'*'
D006	; BNE +6
20 &O	; JSR set_org
4C &L	; JMP loop
	;
C9 "."	; CMP #'.'
D006	; BNE +6
20 &D	; JSR define_label
4C &L	; JMP loop
	;
C9 "&"	; CMP #'&'
D006	; BNE +6
20 &E	; JSR eval_label
4C &L	; JMP loop 
	;
C922	; CMP #'"'
D006	; BNE +6
20 &S	; JSR string_literal
4C &L	; JMP loop
	;
C9 ";"	; CMP #';'
D006	; BNE +6
20 &C	; JSR skip_comment
4C &L	; JMP loop
	;
C9 "P"	; CMP #'P'
D006	; BNE +6
20 &Q	; JSR set_pass
4C &L	; JMP loop
	;
	;		; no pseudo-op; emit raw byte
	;
20 &R	; JSR parse_hex_byte
20DDFF	; JSR putchar
20 &N	; JSR incr_loc
	;
4C &L	; JMP loop

	;-------------------------------------------------
4C &I	; JMP init	; Placed at end of file for
			; ease in computing address.
