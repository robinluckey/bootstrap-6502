;*=1000

	; asm()
	;
	; initialize location counter
	;
A900	; LDA #00
8580	; STA 80
;+4.

;*=1004
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
D006	; BNE +6
A580	; LDA 80	; get location counter
207010	; JSR 1070	; printhex()
00	; BRK
	;
C93B	; CMP #';'	; comment?
F00B	; BEQ +11
	;
203610	; JSR 1036	; parse_hex_byte();
20DDFF	; JSR FFDD	; putchar();
E680	; INC 80	; increment location counter
4C0410	; JMP 1004
	;
	; skip_to_newline
	;
20EEFF	; JSR FFEE	; getchar()
C90A	; CMP #'\n'
D0F9	; BNE -7
4C0410	; JMP 1004
;+50.

;*=1036
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

;*=1052
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

;*=1060
	; "0123456789ABCDEF"
30313233343536373839414243444546
; +16.

;*=1070
	; printhex();
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B96010	; LDA 1060,Y
20DDFF	; JSR FFDD	; putchar()

8A	; TXA		; restore
290F	; AND #0F		; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B96010	; LDA 1060,Y
20DDFF	; JSR FFDD	; putchar()

60	; RTS
;+24.
