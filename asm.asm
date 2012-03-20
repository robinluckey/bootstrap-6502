;*=1000

	; .start
	;
A900	; LDA #00
8580	; STA 80	; location counter
;+4.

;*=1004
	; .loop
	;
20EEFF	; JSR FFEE	; getchar()
C9FF	; CMP #FF	; EOF?
D001	; BNE +1
00	; BRK
	;
C920	; CMP #' '	; skip white space
F0F4	; BEQ loop	; -12
C909	; CMP #'\t'
F0F0	; BEQ loop	; -16
C90A	; CMP #'\n'
F0EC	; BEQ loop	; -20
	;
	;		; switch on pseudo-op
C92E	; CMP #'.'
D006	; BNE +6
204910	; JSR		; define_label()
4C0410	; JMP 1004
	;
C926	; CMP #'&'
D006	; BNE +6
205510	; JSR		; eval_label()
4C0410	; JMP 1004
	;
C93B	; CMP #';'
D006	; BNE +6
204110	; JSR		; skip_comment()
4C0410	; JMP 1004
	;		; else eval as hex machine code
206B10	; JSR		; parse_hex_byte()
20DDFF	; JSR FFDD	; putchar()
E680	; INC 80	; location counter
	;
4C0410	; JMP loop
;

;*=1041
	; skip_comment()
	;
20EEFF	; JSR FFEE	; getchar()
C90A	; CMP #'\n'
D0F9	; BNE -7
60	; RTS
;+8.

;*=1049
	; define_label()
	;
20EEFF	; JSR FFEE	; getchar()
18	; CLC
69B9	; ADC #B9	; 'A'-'Z' -> 0...
AA	; TAX
A580	; LDA 80	; location counter
9520	; STA 20,X	; values stored from 20...
60	; RTS
;+12.

;*=1055
	; eval_label()
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
;+22.

;*=106B
	; parse_hex_byte()
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
;+28.

;*=1087
	; "0123456789ABCDEF"
30313233343536373839414243444546
; +16.

;*=1097
	; printhex();
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B98710	; LDA 1087,Y
20DDFF	; JSR FFDD	; putchar()

8A	; TXA		; restore
290F	; AND #0F	; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B98710	; LDA 1087,Y
20DDFF	; JSR FFDD	; putchar()

60	; RTS
;+24.
