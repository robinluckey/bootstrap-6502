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
:init
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
	;20 &show	; JSR show
	4C &main_loop	; JUMP main_loop
:exit
	A5 <pass	; LDA pass
	C9 00		; CMP #0
	D0 03		; BNE +3
	;20 &dump_vtable
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
	20 &eval_label	; JSR eval_label
	20 &eval_mnemonic ; JSR eval_mnemonic
	20 &eval_operand ; JSR eval_operand
	60		; RTS

:eval_org
	A4 <org		; LDY org
	D0 01		; BNE +1
	60		; RTS
	C8		; INY		; skip '*' char
	84 <cursor	; STY cursor
	20 &parsehex	; JSR parsehex
	85 <loch	; STA loch	; MSB first
	20 &parsehex	; JSR parsehex
	85 <locl	; STA locl
	60		; RTS

:eval_label
	A4 <label	; LDY label
	D0 01		; BNE +1
	60		; RTS
	C8		; INY		; skip ':' char
	84 <cursor	; STY cursor
	20 &set_var	; JSR set_var
	60		; RTS

:eval_mnemonic
	A4 <mnemonic	; LDY mnemonic
	D0 01		; BNE +1
	60		; RTS
	B9 &line	; LDA line,Y
	84 <cursor	; STY <cursor
	E6 <cursor	; INC <cursor

	C9 "P"		; CMP #'P'
	D0 04		; BNE +4
	20 &set_pass	; JSR set_pass
	60		; RTS

	C9 "_"		; CMP #'_'	; no-op
	D0 01		; BNE +1
	60		; RTS

			; assume hex mnemonic
	C6 <cursor	; DEC cursor
	20 &hex_literal ; JSR hex_literal
	60		; RTS

:set_pass
	20 &parsehex	; JSR parsehex
	85 <pass	; STA pass
	60		; RTS

:eval_operand
	A4 <operand	; LDY operand
	D0 01		; BNE +1
	60		; RTS
	B9 &line	; LDA line,Y
	84 <cursor	; STY <cursor
	E6 <cursor	; INC <cursor

	C9 "&"		; CMP #'&'
	D0 04		; BNE +4
	20 &get_var	; JSR get_var
	60		; RTS

	C9 ">"		; CMP #'>'
	D0 04		; BNE +4
	20 &get_hi	; JSR get_hi
	60		; RTS

	C9 "<"		; CMP #'<'
	D0 04		; BNE +4
	20 &get_lo	; JSR get_lo
	60		; RTS

	C9 "~"		; CMP #'~'
	D0 04		; BNE +4
	20 &get_rel_var	; JSR get_rel_var
	60		; RTS

	C9 22		; CMP #'"'
	D0 04		; BNE +4
	20 &string_literal ; JSR string_literal
	60		; RTS

	C9 "-"		; CMP #'-'
	D0 04		; BNE +4
	20 &twos_comp	; JSR twos_comp
	60		; RTS

			; assume hex operand
	C6 <cursor	; DEC cursor
	20 &hex_literal ; JSR hex_literal
	60		; RTS

:parsehex
	; Reads hex value from cursor position, and advances cursor.
	; Returns result in A.

	A4 <cursor	; LDY <cursor
					; hi nibble
	B9 &line	; LDA line,Y
	C8		; INY
	C9 3A		; CMP #3A
	90 02		; BCC +2
	69 F8		; ADC #F8
	29 0F		; AND #0F
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	85 00		; STA 00
					; lo nibble
	B9 &line	; LDA line,Y
	C8		; INY
	C9 3A		; CMP #3A
	90 02		; BCC +2
	69 F8		; ADC #F8
	29 0F		; AND #0F
	05 00		; ORA 00

	84 <cursor	; STY cursor
	60		; RTS

:incr_loc
	E6 <locl	; INC locl
	D0 02		; BNE +2
	E6 <loch	; INC loch
	60		; RTS

:emit
	48		; PHA
	A5 <pass	; LDA pass
	C9 01		; CMP #1
	D0 05		; BNE +5
	68		; PLA
	20 &putchar	; JSR putchar
	60		; RTS
	68		; PLA
	60		; RTS

:string_literal
	A4 <cursor	; LDY cursor
	B9 &line	; LDA line,Y
	E6 <cursor	; INC cursor
	C9 22		; CMP #'"'
	D0 01		; BNE +1
	60		; RTS
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
	4C &string_literal ; JMP string_literal

:hex_literal
	; Read and emit a series of hex bytes beginning at
	; cursor position
	A4 <cursor	; LDY cursor
	B9 &line	; LDA line,Y
	20 &is_token	; BCS is_token
	B0 01		; BCS +1
	60		; RTS
	20 &parsehex	; JSR parsehex
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
	4C &hex_literal	; JMP hex_literal

:twos_comp
	; Read a hex byte from cursor position, then emit
	; its negation
	20 &parsehex	; JSR parsehex
	49 FF		; EOR #FF
	18		; CLC
	69 01		; ADC #1
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
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
	C9 09		; CMP #'\t'
	F0 ~is_token_f	; BEQ is_token_f
	C9 0A		; CMP #'\n'
	F0 ~is_token_f	; BEQ is_token_f
	C9 ";"		; CMP #';'
	F0 ~is_token_f	; BEQ is_token_f
	C9 00		; CMP #00
	F0 ~is_token_f	; BEQ is_token_f
	38		; SEC		; true
	60		; RTS
:is_token_f
	18		; CLC		; false
	60		; RTS

:is_white
	C9 " "		; CMP #' '
	F0 ~is_white_t	; BEQ is_white_t
	C9 09		; CMP #'\t'
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
	29 0F		; AND #0F	; low order nibble
	A8		; TAY		; lookup hex char
	18		; CLC
	B9 &hex_digits	; LDA hex_digits,Y
	20 &putchar	; JSR putchar
	60		; RTS

:seek_var		; Using the variable name at cursor position,
			; find the variable in the vtable.
			;
			; If the variable is found, the return accumulator
			; will be 1, and addresses vcurl,h will point at its
			; vtable entry.
			;
			; If the variable is not found, the accumulator will be
			; 0, and vcurl,h will be equal to vnext, beyond the
			; end of the vtable. The caller may append a new value
			; here.
			;
	A9 <vtable	; LDA #lo(vtable); begin at top of vtable
	85 <vcurl	; STA vcurl
	A9 >vtable	; LDA #hi(vtable)
	85 <vcurh	; STA vcurh
:seek_var_each
	A5 <vcurl	; LDA vcurl	; reached end of vtable?
	C5 <vnextl	; CMP vnextl
	D0 ~seek_var_cmp ; BNE seek_var_cmp
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP vnexth
	F0 ~seek_var_not_found ; BEQ seek_var_not_found
:seek_var_cmp
	A0 02		; LDY #2	; vtable name follows 2-byte address
	A6 <cursor	; LDX cursor
:seek_var_cmp_loop
	B1 <vcurl	; LDA (vcurl),Y	; get next letter of name from vtable
	C9 00				; end of variable name?
	D0 ~seek_var_cmp_char ; BNE seek_var_cmp_char
	BD &line	; LDA line,X
	20 &is_token
	90 ~seek_var_found ; BCC seek_var_found	; both variables ended -- match
	B0 ~seek_var_end ; BCS seek_var_end	; only one eneed -- go to next
:seek_var_cmp_char
	DD &line	; CMP line,X
	D0 ~seek_var_end ; BNE seek_var_end	; no match -- go to next vtable entry
	E8		; INX			; else onward to next letter
	C8		; INY
	D0 ~seek_var_cmp_loop ; BNE seep_var_cmp_loop
	00		; BRK		; error -- variable name too long
:seek_var_end
	B1 <vcurl	; LDA (vcurl),Y	; seek to end of unmatched name
	C8		; INY
	C9 00		; CMP #0
	D0 ~seek_var_end ; BNE seek_var_skip
:seek_var_next
	98		; TYA		; move vcur to next variable in vtable
	18		; CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	90 02		; BCC +2
	E6 <vcurh	; INC 01
	D0 ~seek_var_each ; BNE seek_var_each
:seek_var_not_found
	A9 00		; LDA #00	; variable does not exist
	60		; RTS
:seek_var_found
	A9 01		; LDA #01	; variable exists
	60		; RTS

:get_var		; Reads variable name from cursor position, then...
			;
			; ...during pass 0, increments location counter only.
			; ...during pass 1, also evaluates and emits its value.
			;
	20 &incr_loc	; JSR incr_loc
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass; which pass?
	C9 00		; CMP #0
	F0 ~get_var_end	; BEQ get_var_end

	20 &seek_var	; JSR seek_var	; set vcurl,h
	D0 05		; BNE +5	; check return result
	A9 01		; LDA #01	; errcode 1 == variable not found
	4C &error	; JMP error

	A0 00		; LDY #00	; lo value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
	A0 01		; LDY #01	; hi value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_var_end
	60		; RTS

:get_hi			; Same as get_var, but emits hi byte only
			;
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C9 00		; CMP #0
	F0 ~get_hi_end	; BEQ get_hi_end
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	D0 05		; BNE +5	; check return result
	A9 01		; LDA #01	; errcode 1 == variable not found
	4C &error	; JMP error

	A0 01		; LDY #01	; hi value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_hi_end
	60		; RTS

:get_lo			; Same as get_var, but emits lo byte only
			;
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C9 00		; CMP #0
	F0 ~get_lo_end	; BEQ get_lo_end
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	D0 05		; BNE +5	; check return result
	A9 01		; LDA #01	; errcode 1 == variable not found
	4C &error	; JMP error

	A0 00		; LDY #00	; lo value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_lo_end
	60		; RTS

:get_rel_var		; Same as get_var, but emits single-byte relative offset
			; from current location (appropriate for branch
			; instructions).
			;
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C9 00		; CMP #0
	D0 01		; BNE +1
	60		; RTS
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	D0 05		; BNE +5	; check return result
	A9 01		; LDA #01	; errcode 1 == variable not found
	4C &error	; JMP error

	A0 00		; LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	38		; SEC		; compute (pv) - (loc), low byte only
	E5 <locl	; SBC locl
	20 &emit	; JSR emit
	60		; RTS

:set_var		; Reads a variable name from line at cursor position,
			; then writes an entry into the vtable using the
			; current location counter as its value.
			;
			; An existing variable will be overwritten. New
			; variables will be appended to the end of the vtable.
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	48		; PHA		; 0 if record did not exist (new entry)
			;
	A0 00		; LDY #00	; save location counter value
	A5 <locl	; LDA locl
	91 <vcurl	; STA (vcurl),Y
	C8		; INY
	A5 <loch	; LDA loch
	91 <vcurl	; STA (vcurl),Y
					; save variable name
	A6 <cursor	; LDX cursor
:set_var_loop
	C8		; INY
	BD &line	; LDA line,X
	91 <vcurl	; STA (vcurl),Y
	E8		; INX
	20 &is_token	; end of name?
	B0 ~set_var_loop ; BCS set_var_loop
			;
	A9 00		; LDA #00	; null terminate name
	91 <vcurl	; STA (vcurl),Y
	C8		; INY
			;
			; If we have extended the vtable, we must update the
			; end pointer vnext.
			;
	68		; PLA
	C9 00		; CMP #00
	F0 01		; BEQ +01
	60		; RTS
	98		; TYA		; update vnext
	18		; CLC
	65 <vnextl	; ADC vnextl
	85 <vnextl	; STA vnextl
	90 02		; BCC +2
	E6 <vnexth	; INC vnexth
	60		; RTS

:print_vtable
	A9 "P"		; LDA #"P"
	20 &putchar	; JSR putchar
	A9 01		; LDA #1
	20 &printhex	; JSR printhex
	A9 0A		; LDA #"\n"
	20 &putchar	; JSR putchar
			;
	A9 <vtable	; LDA lo(vtable)
	85 <vcurl	; STA vcurl
	A9 >vtable	; LDA hi(vtable)
	85 <vcurh	; STA vcurh
:pv_loop
	A5 <vcurl	; LDA vcurl	; at end of vtable?
	C5 <vnextl	; CMP (vnextl)
	D0 07		; BNE +7
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP (vnexth)
	D0 01		; BNE +1
	60		; RTS

	A9 "*"		; LDA #"*"
	20 &putchar	; JSR putchar
	A0 01		; LDY #01	; print address -- high byte first!
	B1 <vcurl	; LDA (vcurl),Y
	20 &printhex	; JSR printhex
	A0 00		; LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	20 &printhex	; JSR printhex
	A9 " "		; LDA #" "
	20 &putchar	; JSR putchar
	A9 ":"		; LDA #":"
	20 &putchar	; JSR putchar

	A0 02		; LDY #02
:pv_name_loop
	B1 <vcurl	; LDA (vcurl),Y
	C8		; INY
	C9 00		; CMP #0
	F0 ~pv_end_of_name ; BEQ pv_end_of_name
	20 &putchar	; JSR putchar
	D0 ~pv_name_loop ; BNE :pv_name_loop
	00		; BRK		; error -- variable name too long
:pv_end_of_name
	A9 0A		; LDA #"\n"
	20 &putchar	; JSR putchar
	98		; TYA
	18		; CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	90 02		; BCC +2
	E6 <vcurh	; INC vcurh
	4C &pv_loop	; JMP

:show			; debugging aid
	20 &show_line
	;20 &show_pass
	20 &show_loc
	;20 &show_org
	20 &show_label
	20 &show_mnemonic
	20 &show_operand
	;20 &show_comment
	20 &show_vnext
	A9 0A		; LDA #'\n'
	20 &putchar	; JSR putchar
	60		; RTS

:show_line
	A9 <sz_line	; LDA #lo(sz_line)
	85 <putsl	; STA putsl
	A9 >sz_line	; LDA #hi(sz_line)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <lineh	; LDA lineh
	20 &printhex	; JSR printhex
	A5 <linel	; LDA linel
	20 &printhex	; JSR printhex
	60		; RTS

:show_pass
	A9 <sz_pass	; LDA #lo(sz_pass)
	85 <putsl	; STA putsl
	A9 >sz_pass	; LDA #hi(sz_pass)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <pass	; LDA pass
	20 &printhex	; JSR printhex
	60		; RTS

:show_loc
	A9 <sz_loc	; LDA #lo(sz_loc)
	85 <putsl	; STA putsl
	A9 >sz_loc	; LDA #hi(sz_loc)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <loch	; LDA loch
	20 &printhex	; JSR printhex
	A5 <locl	; LDA locl
	20 &printhex	; JSR printhex
	60		; RTS

:show_org
	A9 <sz_org	; LDA #lo(sz_org)
	85 <putsl	; STA putsl
	A9 >sz_org	; LDA #hi(sz_org)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <org		; LDA org
	20 &printhex	; JSR printhex
	60		; RTS

:show_label
	A9 <sz_label	; LDA #lo(sz_label)
	85 <putsl	; STA putsl
	A9 >sz_label	; LDA #hi(sz_label)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <label	; LDA label
	20 &printhex	; JSR printhex
	60		; RTS

:show_mnemonic
	A9 <sz_mnemonic	; LDA #lo(sz_mnemonic)
	85 <putsl	; STA putsl
	A9 >sz_mnemonic	; LDA #hi(sz_mnemonic)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <mnemonic	; LDA mnemonic
	20 &printhex	; JSR printhex
	60		; RTS

:show_operand
	A9 <sz_operand	; LDA #lo(sz_operand)
	85 <putsl	; STA putsl
	A9 >sz_operand	; LDA #hi(sz_operand)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <operand	; LDA operand
	20 &printhex	; JSR printhex
	60		; RTS

:show_comment
	A9 <sz_comment	; LDA #lo(sz_comment)
	85 <putsl	; STA putsl
	A9 >sz_comment	; LDA #hi(sz_comment)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <comment	; LDA comment
	20 &printhex	; JSR printhex
	60		; RTS

:show_vnext
	A9 <sz_vnext	; LDA #lo(sz_vnext)
	85 <putsl	; STA putsl
	A9 >sz_vnext	; LDA #hi(sz_vnext)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <vnexth	; LDA vnexth
	20 &printhex	; JSR printhex
	A5 <vnextl	; LDA vnextl
	20 &printhex	; JSR printhex
	60		; RTS

:sz_line	"; line:" 00
:sz_pass	"  pass:" 00
:sz_loc		"  loc:" 00
:sz_org		"  org:" 00
:sz_label	"  label:" 00
:sz_mnemonic	"  mnem:" 00
:sz_operand	"  oper:" 00
:sz_comment	"  comment:" 00
:sz_vnext	"  vnext:" 00

:hex_digits
	"0123456789ABCDEF"

:dump_vtable
	A9 <vtable	; LDA #lo(vtable)
	85 <putsl	; STA putsl
	A9 >vtable	; LDA #hi(vtable)
	85 <putsh	; STA putsh
	20 &hex_dump	; JSR hex_dump
	60		; RTS

:hex_dump		; emit bytes beginning at putsl
	A5 <putsh	; LDA putsl
	20 &printhex	; JSR printhex
	A5 <putsl	; LDA putsh
	20 &printhex	; JSR printhex
	A9 ":"		; LDA #":'
	20 &putchar	; JSR putchar
	A0 00		; LDY #00
:hex_dump_loop
	B1 <putsl	; LDA (putsl),Y
	84 00		; STY 00
	20 &printhex	; JSR printhex
	A9 " "		; LDA #" "
	20 &putchar	; JSR putchar
	A4 00		; LDY 00
	C8		; INY
	C0 80		; CPY #80
	D0 ~hex_dump_loop ; BNE hext_dump_loop
	A9 0A		; LDA #'\n'
	20 &putchar	; JSR putchar
	60		; RTS

:error
	48		; PHA		; save error code

	A9 <sz_errline	; LDA #lo(sz_errline)
	85 <putsl	; STA putsl
	A9 >sz_errline	; LDA #hi(sz_errline)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	A5 <lineh	; LDA lineh
	20 &printhex	; JSR printhex
	A5 <linel	; LDA linel
	20 &printhex	; JSR printhex

	A9 <sz_errcode	; LDA #lo(sz_errcode)
	85 <putsl	; STA putsl
	A9 >sz_errcode	; LDA #hi(sz_errcode)
	85 <putsh	; STA putsh
	20 &puts	; JSR puts
	68		; PLA
	20 &printhex	; JSR printhex

	A9 0A		; LDA #"\n"
	20 &putchar	; JSR putchar
	00		; BRK

:sz_errline "Line:" 00
:sz_errcode "  Error:" 00
