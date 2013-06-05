;	global variables
;
;	20-21	label A
;	22-23	label B
;	...
;	32-33	label Z
;
;	80-81	location counter
;	82	assembly pass (0 or 1)
;	84-85   vnext -- pointer to next available variable-length symbol table entry

*2000	.A	; general-purpose string buffer
*3000	.V	; vtable -- variable-length symbol table

*1000

4C &I	; JMP init

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
D0 -07	; BNE -7
60	; RTS

.M	; emit		; putchar if pass 1
	;
48	; PHA
A582	; LDA 82
C901	; CMP #1
D005	; BNE +5
68	; PLA
20DDFF	; JSR putchar
60	; RTS
68	; PLA
60	; RTS

.D	; define_label
	;
20EEFF	; JSR getchar
18	; CLC
69BF	; ADC #BF	; 'A'-'Z' -> 0...
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
69BF	; ADC #BF	; 'A'-'Z' -> 0...
0A	; ASL A		; sizeof(label) = 2
AA	; TAX
B520	; LDA 20,X
20 &M	; JSR emit
20 &N	; JSR incr_loc
B521	; LDA 21,X
20 &M	; JSR emit
20 &N	; JSR incr_loc
60	; RTS

.U	; define_variable
	;
	; The symbol table is a packed array of records:
	;
	;	2 bytes: value (memory address)
	;	n bytes: string name
	;	1 byte:  0 terminator
	;
A000	; LDY #00
	;
A580	; LDA 80	; store location counter value
9184	; STA (vnext),Y
C8	; INY
A581	; LDA 81
9184	; STA (vnext),Y
C8	; INY
	;
	; .loop		; read and store variable name
20EEFF	; JSR getchar
C90A	; CMP #'\n'
F00E	; BEQ .term
C909	; CMP #'\t'
F00A	; BEQ .term
C9 " "	; CMP #' '
F006	; BEQ .term
9184	; STA (vnext),Y
C8	; INY
D0 -14	; BNE .loop
00	; BRK		; error -- variable name too long
	;
	; .term		; null terminate variable name
A900	; LDA #00
9184	; STA (vnext),Y
C8	; INY
	;
98	; TYA		; update vnext
18	; CLC
6584	; ADC 84
8584	; STA 84
9002	; BCC +2
E685	; INC 85
60	; RTS

.G	; lo_byte -- eval_label, but emit low byte only
	;
20EEFF	; JSR getchar
18	; CLC
69BF	; ADC #BF	; 'A'-'Z' -> 0...
0A	; ASL A		; sizeof(label) = 2
AA	; TAX
B520	; LDA 20,X
20 &M	; JSR emit
20 &N	; JSR incr_loc
60	; RTS

.H	; hi_byte -- eval_label, but emit high byte only
	;
20EEFF	; JSR getchar
18	; CLC
69BF	; ADC #BF	; 'A'-'Z' -> 0...
0A	; ASL A		; sizeof(label) = 2
AA	; TAX
B521	; LDA 21,X
20 &M	; JSR emit
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

.W	; print_variables
	;
A9 "P"	; LDA #"P"
20DDFF	; JSR putchar
A901	; LDA #1
20 &P	; JSR printhex
A90A	; LDA #"\n"
20DDFF	; JSR putchar
	;
A9 <V	; LDA lo(vtable)
8500	; STA 00	; 00-01: temp pointer into vtable
A9 >V	; LDA hi(vtable)
8501	; STA 01
	;
.B	; .loop
A500	; LDA 00	; at end of vtable?
C584	; CMP lo(vnext)
D007	; BNE +7
A501	; LDA 01
C585	; CMP hi(vnext)
D001	; BNE +1
60	; RTS
	;
A9 "*"	; LDA #"*"
20DDFF	; JSR putchar
A001	; LDY #01	; print address -- high byte first!
B100	; LDA (00),Y
20 &P	; JSR printhex
A000	; LDY #00
B100	; LDA (00),Y
20 &P	; JSR printhex
	;
A9 " "	; LDA #" "
20DDFF	; JSR putchar
A9 ":"	; LDA #":"
20DDFF	; JSR putchar
	;
A002	; LDY #02
	; .print_name_loop
B100	; LDA (00),Y
C900	; CMP #0
F007	; BEQ .end_of_name
20DDFF	; JSR putchar
C8	; INY
D0 -0C	; BNE .print_name_loop
00	; BRK		; error -- variable name too long
	;
	; .end_of_name
A90A	; LDA #"\n"
20DDFF	; JSR putchar
	;
C8	; INY		; update temp pointer to next element
98	; TYA
18	; CLC
6500	; ADC 00
8500	; STA 00
9002	; BCC +2
E601	; INC 01
4C &B	; JMP .loop

0000 0000 0000

.K	; lookup_variable						;112F
	;
	; reads variable name from stdin, emits its value to stdout
	;
	; 00-01: (pv)   iteration pointer into vtable
	; 02-03: (pbuf) iteration pointer into input buffer
	;
A9 <A	; LDA #lo(buf)
8502	; STA pbuf
A9 >A	; LDA #hi(buf)
8503	; STA pbuf+1
	;
A002	; LDY #2	; load input buffer.
	;		; Note 2-byte offset to match vtable records
	; .loop								; 1139
20EEFF	; JSR getchar
C9 " "	; CMP #' '
F00E	; BEQ .search
C909	; CMP #'\t'
F00A	; BEQ .search
C90A	; CMP #'\n'
F006	; BEQ .search
9102	; STA (pbuf),Y
C8	; INY
D0 -14	; BNE .loop
00	; BRK		; error -- variable name too long
	;
	; .search	; find matching name in table			; 114E
	;
A900	; LDA #0	; null terminate input buffer
9102	; STA (pbuf),Y
	;
A9 <V	; LDA #lo(vtable); begin at top of vtable
8500	; STA pv
A9 >V	; LDA #hi(vtable)
8501	; STA pv+1
	;
.J	;								; 115A
A002	; LDY #2	; variable name begins after 2-byte address
B100	; LDA (pv),Y
D102	; CMP (pbuf),Y
D008	; BNE .skip
C900	; CMP #0	; end of name -> successful match
F022	; BEQ .found
C8	; INY
D0 -0D	; BNE
00	; BRK		; error -- variable name too long
	;
	; .skip								; 116A
B100	; LDA (pv),Y	; find end of variable in table
C8	; INY
C900	; CMP #0
D0 -07	; BNE .skip
	;
	; .next		; move pv to next variable in vtable		; 1171
98	; TYA
18	; CLC
6500	; ADC 00
8500	; STA 00
9002	; BCC +2
E601	; INC 01
	;
A500	; LDA 00	; at end of vtable?
C584	; CMP vnext
D0 -27	; BNE &J
A501	; LDA 01
C585	; CMP nvext+1
D0 -2D	; BNE &J
00	; BRK		; error -- variable not found
	;
	; .found							; 1189
A000	; LDY #00	; vtable record lo address
B100	; LDA (pv),Y
20 &M	; JSR emit
20 &N	; JSR incr_loc
A001	; LDY #01	; vtable record hi address
B100	; LDA (pv),Y
20 &M	; JSR emit
20 &N	; JSR incr_loc
60	; RTS

.Y	; print_symbol_table
	;
A9 "P"	; LDA #"P"
20DDFF	; JSR putchar
A901	; LDA #1
20 &P	; JSR printhex
A90A	; LDA #"\n"
20DDFF	; JSR putchar
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
6941	; ADC #41	; 0..25 -> 'A'-'Z'
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
20 &M	; JSR emit
20 &N	; JSR incr_loc
4C &S	; JMP string_literal

.T	; twos_complement
	;
	; Read a hex byte from stdin, then emit
	; the negation of that byte.
	;
20EEFF	; JSR getchar
20 &R	; JSR parse_hex_byte
49FF	; EOR #FF
18	; CLC
6901	; ADC #1
20 &M	; JSR emit
20 &N	; JSR incr_loc
60	; RTS

.R	; parse_hex_byte
	;
	; Assumes that the first char is already in A.
	; Reads the second char from stdin, then returns
	; the byte value in A.
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
A9 <V	; LDA lo(vtable)
8584	; STA 84	; initialize variable symbol table pointer
A9 >V	; LDA hi(vtable)
8585	; STA 85
A900	; LDA #00
8582	; STA 82	; pass 0 by default

.L	; loop
	;
20EEFF	; JSR getchar
C9FF	; CMP #FF	; EOF?
D00D	; BNE +13
A582	; LDA 82
C900	; CMP #0
D006	; BNE +6
20 &Y	; JSR print_symbol_table
20 &W	; JSR print_variable_table
00	; BRK
	;
C9 " "	; CMP #' '	; skip white space
F0 -18	; BEQ loop
C909	; CMP #'\t'
F0 -1C	; BEQ loop
C90A	; CMP #'\n'
F0 -20	; BEQ loop
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
C9 ">"	; CMP #'>'
D006	; BNE +6
20 &H	; JSR hi_byte
4C &L	; JMP loop
	;
C9 "<"	; CMP #'<'
D006	; BNE +6
20 &G	; JSR lo_byte
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
C9 "-"	; CMP #'-'
D006	; BNE +6
20 &T	; JSR twos_complement
4C &L	; JMP loop
	;
C9 ":"	; CMP #':'
D006	; BNE +6
20 &U	; JSR define_variable
4C &L	; JMP loop
	;
C9 "@"	; CMP #'@'
D006	; BNE +6
20 &K	; JSR lookup_variable
4C &L	; JMP loop
	;
	;		; no pseudo-op; emit raw byte
	;
20 &R	; JSR parse_hex_byte
20 &M	; JSR emit
20 &N	; JSR incr_loc
	;
4C &L	; JMP loop
