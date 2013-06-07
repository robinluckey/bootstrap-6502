*FFDD	:putchar
*FFEE	:getchar

;	page zero global variables

*0080	:locl		; location counter
*0081	:loch
*0082	:pass		; assembly pass (0 or 1)

*0086	:vcurl		; pointer to current vtable entry
*0087	:vcurh		; pointer to current vtable entry
*0088	:vnextl		; pointer to next available vtable entry
*0089	:vnexth

*0090	:cursor		; offset to last consumed character in line
*0091	:org		; offset to address within buffer (0 = no address)
*0092	:label		; offset to label
*0093	:mnemonic	; offset to mnemonic
*0094	:operand	; offset to operand
*0095	:comment	; offset to comment

*0096	:linel		; line number
*0097	:lineh		;

*00A0	:putsl		; address of string argument to puts
*00A1	:putsh

;	data storage

*2000	:line		; length-prefixed string input buffer
*2100	:vtable		; variable-length symbol table

;	code

*1000

:main
	A9 00		; LDA #00
	85 <linel	; STA linel
	85 <lineh	; STA lineh
	85 <pass	; STA pass
	A9 <vtable	; LDA lo(vtable)
	85 <vnextl	; STA vnextl
	A9 >vtable	; LDA hi(vtable)
	85 <vnexth	; STA vnexth

:main_loop
	20 &readline	; JSR readline
	C9 FF		; CMP #eof
	F0 ~exit	; BEQ exit
	20 &parse	; JSR parse
	20 &eval	; JSR eval
	20 &show	; JSR show
	4C &main_loop	; JUMP main_loop
:exit
	A5 <pass	; LDA pass
	C9 00		; CMP #0
	D0 03		; BNE +3
	20 &print_vtable ; JSR print_vtable
	00		; BRK

:readline
	E6 <linel	; INC linel
	90 02		; BCC +2
	E6 <lineh	; INC lineh
			;
	A0 00		; LDY #00
	99 &line	; STA line,Y	; length 0 by default
:readline_loop
	20 &getchar	; JSR getchar
	C9 FF		; CMP #eof
	D0 01		; BNE +1
	60		; RTS
	C8		; INY
	99 &line	; STA line,Y
	C9 0A		; CMP #'\n'
	D0 ~readline_loop ; BNE readline_loop
	8C &line	; STY line
	60		; RTS

:parse
	A9 00		; LDA #00
	85 <cursor	; STA cursor	; reset cursor beginning of line

	A9 00		; LDA #00
	85 <org		; STA org
	85 <label	; STA label
	85 <mnemonic	; STA mnemonic
	85 <operand	; STA operand
	85 <comment	; STA comment

	20 &find_org	; JSR find_org
	20 &find_label	; JSR find_label
	20 &find_mnemonic ; JSR find_mnemonic
	20 &find_operand ; JSR find_operand
	20 &find_comment ; JSR find_comment
	60		; RTS

:find_org
	A4 <cursor	; LDY cursor
:find_org_begin				; seek to beginning of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_white	; JSR is_white
	B0 ~find_org_begin ; BCS find_org_begin
	C9 "*"		; CMP #'*'
	D0 ~find_org_exit ; BNE find_org_exit
	84 <org		; STY org
:find_org_end				; seek to end of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_token	; JSR is_token
	B0 ~find_org_end ; BCS find_org_end
	88		; DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_org_exit
	60		; RTS

:find_label
	A4 <cursor	; LDY cursor
:find_label_begin			; seek to beginning of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_white	; JSR is_white
	B0 ~find_label_begin ; BCS find_label_begin
	C9 ":"		; CMP #':'
	D0 ~find_label_exit ; BNE find_label_exit
	84 <label	; STY label
:find_label_end				; seek to end of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_token	; JSR is_token
	B0 ~find_label_end ; BCS find_label_end
	88		; DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_label_exit
	60		; RTS

:find_mnemonic
	A4 <cursor	; LDY cursor
:find_mnemonic_begin			; seek to beginning of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_white	; JSR is_white
	B0 ~find_mnemonic_begin ; BCS find_mnemonic_begin
	20 &is_token
	90 ~find_mnemonic_exit ; BCC find_mnemonic_exit
	84 <mnemonic	; STY mnemonic
:find_mnemonic_end			; seek to end of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_token	; JSR is_token
	B0 ~find_mnemonic_end ; BCS find_mnemonic_end
	88		; DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_mnemonic_exit
	60		; RTS

:find_operand
	A4 <cursor	; LDY cursor
:find_operand_begin			; seek to beginning of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_white	; JSR is_white
	B0 ~find_operand_begin ; BCS find_operand_begin
	20 &is_token
	90 ~find_operand_exit ; BCC find_operand_exit
	84 <operand	; STY operand
:find_operand_end			; seek to end of token
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_token	; JSR is_token
	B0 ~find_operand_end ; BCS find_operand_end
	88		; DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_operand_exit
	60		; RTS

:find_comment
	A4 <cursor	; LDY cursor
:find_comment_begin			; seek to beginning of comment
	C8		; INY
	B9 &line	; LDA line,Y
	20 &is_white	; JSR is_white
	B0 ~find_comment_begin ; BCS find_comment_begin
	C9 ";"		; CMP #';'
	90 ~find_comment_exit ; BCC find_comment_exit
	84 <comment	; STY comment
:find_comment_end			; seek to end of line
	C8		; INY
	B9 &line	; LDA line,Y
	C9 0A		; CMP #'\n'
	B0 ~find_comment_end ; BCS find_comment_end
	88		; DEY		; "unconsume" newline character
	84 <cursor	; STY cursor
:find_comment_exit
	60		; RTS

:eval
	20 &eval_org	; JSR eval_org
	20 &eval_mnemonic ; JSR eval_mnemonic
	60		; RTS

:eval_org
	A4 <org		; LDY org
	D0 01		; BNE +1
	60		; RTS
	C8		; INY		; skip '*' char
	20 &parsehex	; JSR parsehex
	85 <loch	; STA loch	; MSB first
	20 &parsehex	; JSR parsehex
	85 <locl	; STA locl
	60		; RTS

:eval_mnemonic
	A4 <mnemonic	; LDY mnemonic
	D0 01		; BNE +1
	60		; RTS
	B9 &line	; LDA line,Y

	C9 "P"		; CMP #'P'
	D0 04		; BNE +4
	20 &set_pass	; JSR set_pass
	60		; RTS

	; unrecognized mnemonic
	60		; RTS

:set_pass
	C8		; INY		; skip 'P' char
	20 &parsehex	; JSR parsehex
	85 <pass	; STA pass
	60		; RTS

:parsehex
	; Y register must contain offset to first
	; hex char in line.
	; Y will be incremented twice, A holds result.

					; hi nibble
	B9 &line	; LDA line,Y
	C8		; INY
	C93A		; CMP #3A
	9002		; BCC +2
	69F8		; ADC #F8
	290F		; AND #0F
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	8500		; STA 00
					; lo nibble
	B9 &line	; LDA line,Y
	C8		; INY
	C93A		; CMP #3A
	9002		; BCC +2
	69F8		; ADC #F8
	290F		; AND #0F
	0500		; ORA 00
	60		; RTS

:incr_loc
	E6 <locl	; INC locl
	D002		; BNE +2
	E6 <loch	; INC loch
	60		; RTS

:puts
	A0 00		; LDY #00
:puts_loop
	B1 <putsl	; LDA (putsl),Y
	D0 01		; BNE +1
	60		; RTS
	20 &putchar	; JSR putchar
	C8		; INY
	D0 ~puts_loop	; BNE puts_loop
	00		; BRK		; error -- string too long

:is_token
	C9 " "		; CMP #' '
	F0 ~is_token_f	; BEQ is_token_f
	C909		; CMP #'\t'
	F0 ~is_token_f	; BEQ is_token_f
	C90A		; CMP #'\n'
	F0 ~is_token_f	; BEQ is_token_f
	C9 ";"		; CMP #';'
	F0 ~is_token_f	; BEQ is_token_f
	C900		; CMP #00
	F0 ~is_token_f	; BEQ is_token_f
	38		; SEC		; true
	60		; RTS
:is_token_f
	18		; CLC		; false
	60		; RTS

:is_white
	C9 " "		; CMP #' '
	F0 ~is_white_t	; BEQ is_white_t
	C909		; CMP #'\t'
	F0 ~is_white_t	; BEQ is_white_t
	18		; CLC		; false
	60		; RTS
:is_white_t
	38		; SEC		; true
	60		; RTS

:printhex
	AA		; TAX		; backup
	4A		; LSR A		; high order nibble
	4A		; LSR A
	4A		; LSR A
	4A		; LSR A
	A8		; TAY		; lookup hex char
	18		; CLC
	B9 &hex_digits	; LDA hex_digits,Y
	20 &putchar	; JSR putchar
	8A		; TXA		; restore
	290F		; AND #0F	; low order nibble
	A8		; TAY		; lookup hex char
	18		; CLC
	B9 &hex_digits	; LDA hex_digits,Y
	20 &putchar	; JSR putchar
	60		; RTS

:print_vtable
	A9 "P"		; LDA #"P"
	20 &putchar	; JSR putchar
	A901		; LDA #1
	20 &printhex	; JSR printhex
	A90A		; LDA #"\n"
	20 &putchar	; JSR putchar
			;
	A9 <vtable	; LDA lo(vtable)
	85 <vcurl	; STA vcurl
	A9 >vtable	; LDA hi(vtable)
	85 <vcurh	; STA vcurh
:pv_loop
	A5 <vcurl	; LDA vcurl	; at end of vtable?
	C5 <vnextl	; CMP (vnextl)
	D007		; BNE +7
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP (vnexth)
	D001		; BNE +1
	60		; RTS

	A9 "*"		; LDA #"*"
	20 &putchar	; JSR putchar
	A001		; LDY #01	; print address -- high byte first!
	B1 <vcurl	; LDA (vcurl),Y
	20 &printhex	; JSR printhex
	A000		; LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	20 &printhex	; JSR printhex
	A9 " "		; LDA #" "
	20 &putchar	; JSR putchar
	A9 ":"		; LDA #":"
	20 &putchar	; JSR putchar

	A002		; LDY #02
:pv_name_loop
	B1 <vcurl	; LDA (vcurl),Y
	C900		; CMP #0
	F0 ~pv_end_of_name ; BEQ pv_end_of_name
	20 &putchar	; JSR putchar
	C8		; INY
	D0 ~pv_name_loop ; BNE :pv_name_loop
	00		; BRK		; error -- variable name too long
:pv_end_of_name
	A90A		; LDA #"\n"
	20 &putchar	; JSR putchar
	C8		; INY		; update temp pointer to next element
	98		; TYA
	18		; CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	9002		; BCC +2
	E6 <vcurh	; INC vcurh
	4C &pv_loop	; JMP

:show
	A9 <sz_line	; LDA #lo(sz_line)
	85 <putsl	; STA putsl
	A9 >sz_line	; LDA #hi(sz_line)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <lineh	; LDA lineh
	20 &printhex	; JSR printhex
	A5 <linel	; LDA linel
	20 &printhex	; JSR printhex

	A9 <sz_pass	; LDA #lo(sz_pass)
	85 <putsl	; STA putsl
	A9 >sz_pass	; LDA #hi(sz_pass)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <pass	; LDA pass
	20 &printhex	; JSR printhex

	A9 <sz_loc	; LDA #lo(sz_loc)
	85 <putsl	; STA putsl
	A9 >sz_loc	; LDA #hi(sz_loc)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <loch	; LDA loch
	20 &printhex	; JSR printhex
	A5 <locl	; LDA locl
	20 &printhex	; JSR printhex

	A9 <sz_org	; LDA #lo(sz_org)
	85 <putsl	; STA putsl
	A9 >sz_org	; LDA #hi(sz_org)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <org		; LDA org
	20 &printhex	; JSR printhex

	A9 <sz_label	; LDA #lo(sz_label)
	85 <putsl	; STA putsl
	A9 >sz_label	; LDA #hi(sz_label)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <label	; LDA label
	20 &printhex	; JSR printhex

	A9 <sz_mnemonic	; LDA #lo(sz_mnemonic)
	85 <putsl	; STA putsl
	A9 >sz_mnemonic	; LDA #hi(sz_mnemonic)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <mnemonic	; LDA mnemonic
	20 &printhex	; JSR printhex

	A9 <sz_operand	; LDA #lo(sz_operand)
	85 <putsl	; STA putsl
	A9 >sz_operand	; LDA #hi(sz_operand)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <operand	; LDA operand
	20 &printhex	; JSR printhex

	;A9 <sz_comment	; LDA #lo(sz_comment)
	;85 <putsl	; STA putsl
	;A9 >sz_comment	; LDA #hi(sz_comment)
	;85 <putsh	; STA putsh
	;20 &puts	; JSR puts
	;A5 <comment	; LDA comment
	;20 &printhex	; JSR printhex

	A9 0A		; LDA #'\n'
	20 &putchar	; JSR putchar
	60		; RTS

:sz_line	"; line: " 00
:sz_pass	"  pass: " 00
:sz_loc		"  loc: " 00
:sz_org		"  org: " 00
:sz_label	"  label: " 00
:sz_mnemonic	"  mnem: " 00
:sz_operand	"  oper: " 00
:sz_comment	"  comment: " 00

:hex_digits
	"0123456789ABCDEF"
