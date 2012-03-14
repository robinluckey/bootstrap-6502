
;*=1000
	; prompt()
	;
A91C	; LDA LO:"ROBOS >"
8510	; STA 10
A910	; LDA HI:"ROBOS >"
8511	; STA 11
202410  ; JSR 1023	; printsz()
;+11.


;*=100B
	; echo()
	;
20EEFF	; JSR FFEE	; getchar()

C90A	; CMP #'\n'	; end of line detected
D004	; BNE +4
20DDFF	; JSR FFDD	; putchar() -- echo the newline for nice exit
00	; BRK		; or, RTS

204210	; JSR 1042	; printhex()

4C0B10	; JMP 100B	; repeat!
; +17.

;*=101C
	; "ROBOS> \0"
	;
524F424F533E2000
; +8.

;*=1024
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

;*=1032
	; "0123456789ABCDEF"
30313233343536373839414243444546
; +16.

;*=1042
	; printhex();
	;
AA	; TAX		; backup
4A	; LSR A		; high order nibble
4A	; LSR A
4A	; LSR A
4A	; LSR A
A8	; TAY		; lookup hex char
18	; CLC
B93210	; LDA 1032,Y
20DDFF	; JSR FFDD	; putchar()

8A	; TXA		; restore
290F	; AND #0F		; low order nibble
A8	; TAY		; lookup hex char
18	; CLC
B93210	; LDA 1032,Y
20DDFF	; JSR FFDD	; putchar()

60	; RTS
;+24.
