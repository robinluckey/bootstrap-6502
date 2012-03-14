;*=1000

	; asm()
	;
	; skip spaces
	;
20EEFF	; JSR FFEE	; getchar()
C920	; CMP #' '	; space?
F0F9	; BEQ -7
C909	; CMP #'\t'
F0F5	; BEQ -11
C90A	; CMP #'\n'	; newline?
F0F1	; BEQ -15
	;
C9FF	; CMP #FF	; EOF?
D001	; BNE +1
00	; BRK
	;
C93B	; CMP #';'	; comment?
F009	; BEQ +9
	;
202B10	; JSR 102B	; parse_hex_byte();
20DDFF	; JSR FFDD	; putchar();
4C0010	; JMP 1000
	;
	; skip_to_newline
	;
20EEFF	; JSR FFEE	; getchar()
C90A	; CMP #'\n'
D0F9	; BNE -7
4C0010	; JMP 1000
;+43.

;*=102B
	; parse_hex_byte();
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

;*=1048
	; printsz()
	;
A000	; LDY #0
B110	; LDA (10),Y
D001	; BNE +1
60	; RTS

20DDFF	; JSR FFDD	; putchar()
C8	; INY
D0F5	; BNE -11
60	; RTS
;+14.

;*=1056
	; "0123456789ABCDEF"
30313233343536373839414243444546
; +16.

;*=1068
	; printhex();
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B95610	; LDA 1058,Y
20DDFF	; JSR FFDD	; putchar()

8A	; TXA		; restore
290F	; AND #0F		; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B95610	; LDA 1058,Y
20DDFF	; JSR FFDD	; putchar()

60	; RTS
;+24.
