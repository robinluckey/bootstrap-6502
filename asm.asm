*FFDD	:putchar
*FFEE	:getchar

;	page zero global variables

*0080	:locl		; location counter
*0081	:loch
*0082	:pass		; assembly pass (0 or 1)

*0086	:vcurl		; pointer to current vtable element
*0087	:vcurh
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

*0098	:addrmode	; opcode addressing mode
	; enum constants
	*0000	:am_none	; no operand (implied or register)
	*0001	:am_immed	; immediate
	*0002	:am_rel		; relative
	*00FF	:am_unknown

*00A0	:putsl		; address of string argument to puts
*00A1	:putsh

*00B0	:mcurl		; pointer to current mnemonic table element
*00B1	:mcurh

;	data storage

*2000	:line		; length-prefixed string input buffer
*2100	:vtable		; variable-length symbol table

;	code

*1000

:main
:init
	LDA #00
	85 <linel	; STA linel
	85 <lineh	; STA lineh
	85 <pass	; STA pass
	LDA #<vtable
	85 <vnextl	; STA vnextl
	LDA #>vtable
	85 <vnexth	; STA vnexth

:main_loop
	JSR &readline
	CMP #FF
	BEQ ~exit
	JSR &parse
	JSR &eval
	;JSR &show
	JMP &main_loop	; JUMP main_loop
:exit
	A5 <pass	; LDA pass
	BNE 03
	JSR &print_vtable
;	JSR &dump_vtable
	BRK

:readline
	E6 <linel	; INC linel
	BCC 02
	E6 <lineh	; INC lineh
			;
	LDY #00
	99 &line	; STA line,Y	; length 0 by default
:readline_loop
	JSR &getchar
	CMP #FF		; CMP #eof
	BNE 01
	RTS
	INY
	99 &line	; STA line,Y
	CMP #"\n"
	BNE ~readline_loop
	8C &line	; STY line
	RTS

:parse
	LDA #00
	85 <cursor	; STA cursor	; reset cursor beginning of line

	LDA #00
	85 <org		; STA org
	85 <label	; STA label
	85 <mnemonic	; STA mnemonic
	85 <operand	; STA operand
	85 <comment	; STA comment

	JSR &find_org
	JSR &find_label
	JSR &find_mnemonic
	JSR &find_operand
	JSR &find_comment
	RTS

:find_org
	A4 <cursor	; LDY cursor
:find_org_begin				; seek to beginning of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_white
	BCS ~find_org_begin
	CMP #"*"
	BNE ~find_org_exit
	84 <org		; STY org
:find_org_end				; seek to end of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_token
	BCS ~find_org_end
	DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_org_exit
	RTS

:find_label
	A4 <cursor	; LDY cursor
:find_label_begin			; seek to beginning of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_white
	BCS ~find_label_begin
	CMP #":"
	BNE ~find_label_exit
	84 <label	; STY label
:find_label_end				; seek to end of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_token
	BCS ~find_label_end
	DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_label_exit
	RTS

:find_mnemonic
	A4 <cursor	; LDY cursor
:find_mnemonic_begin			; seek to beginning of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_white
	BCS ~find_mnemonic_begin
	JSR &is_token
	BCC ~find_mnemonic_exit
	84 <mnemonic	; STY mnemonic
:find_mnemonic_end			; seek to end of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_token
	BCS ~find_mnemonic_end
	DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_mnemonic_exit
	RTS

:find_operand
	A4 <cursor	; LDY cursor
:find_operand_begin			; seek to beginning of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_white
	BCS ~find_operand_begin
	JSR &is_token
	BCC ~find_operand_exit
	84 <operand	; STY operand
:find_operand_end			; seek to end of token
	INY
	B9 &line	; LDA line,Y
	JSR &is_token
	BCS ~find_operand_end
	DEY		; "unconsume" non-token character
	84 <cursor	; STY cursor
:find_operand_exit
	RTS

:find_comment
	A4 <cursor	; LDY cursor
:find_comment_begin			; seek to beginning of comment
	INY
	B9 &line	; LDA line,Y
	JSR &is_white
	BCS ~find_comment_begin
	CMP #";"
	BCC ~find_comment_exit
	84 <comment	; STY comment
:find_comment_end			; seek to end of line
	INY
	B9 &line	; LDA line,Y
	CMP #"\n"
	BCS ~find_comment_end
	DEY		; "unconsume" newline character
	84 <cursor	; STY cursor
:find_comment_exit
	RTS

:eval
	JSR &eval_org
	JSR &eval_label
	JSR &eval_addrmode
	JSR &eval_mnemonic
	JSR &eval_operand
	RTS

:eval_org
	A4 <org		; LDY org
	BNE 01
	RTS
	INY		; skip '*' char
	84 <cursor	; STY cursor
	JSR &parsehex
	85 <loch	; STA loch	; MSB first
	JSR &parsehex
	85 <locl	; STA locl
	RTS

:eval_label
	A4 <label	; LDY label
	BNE 01
	RTS
	INY		; skip ':' char
	84 <cursor	; STY cursor
	JSR &set_var
	RTS

:eval_addrmode
	; Look ahead to the operand to deduce the addressing mode.
	; If the addressing mode has leading syntax (such as '#')
	; then advance the operand cursor to skip it.
	A4 <operand	; LDY operand
	BNE ~eval_am_immed
	LDA #<am_none
	85 <addrmode	; STA addrmode
	RTS
:eval_am_immed
	B9 &line	; LDA line,Y
	CMP #"#"
	BNE ~eval_am_unknown
	LDA #<am_immed
	85 <addrmode	; STA addrmode
	E6 <operand	; INC <operand
	RTS
:eval_am_unknown
	LDA #<am_unknown
	85 <addrmode	; STA addrmode
	RTS

:eval_mnemonic
	A4 <mnemonic	; LDY mnemonic
	BNE 01
	RTS
	84 <cursor	; STY <cursor

	JSR &lookup_mnemonic
	BCC 04
	JSR &emit_opcode
	RTS

	A4 <mnemonic	; LDY mnemonic
	B9 &line	; LDA line,Y
	E6 <cursor	; INC <cursor

	CMP #"P"
	BNE 04
	JSR &set_pass
	RTS

	CMP #"_"	; no-op
	BNE 01
	RTS

			; assume hex mnemonic
	C6 <cursor	; DEC cursor
	JSR &hex_literal
	RTS

:lookup_mnemonic
	; Check for instructions whose opcode does not depend on operand
	LDA #<mtable_const
	85 <mcurl	; STA mcurl
	LDA #>mtable_const
	85 <mcurh	; STA mcurh
	JSR &lookup_mnem_inner
	BCC 01		; not found, keep looking
	RTS

	; Failing that, check for immediate-mode instructions
	A5 <addrmode	; LDA addrmode
	CMP #<am_immed	; CMP am_immed
	BEQ 02
	CLC		; return false
	RTS
	LDA #<mtable_immed
	85 <mcurl	; STA mcurl
	LDA #>mtable_immed
	85 <mcurh	; STA mcurh
	JSR &lookup_mnem_inner
	RTS

:lookup_mnem_inner
:lm_each_elem
	LDY #00
	A6 <cursor	; LDX cursor
:lm_each_char
	B1 <mcurl	; LDA (mcurl),Y
	BEQ ~lm_not_found		; zero marks end of table
	DD &line	; CMP line,X
	BNE ~lm_miss
	INX
	INY
	CPY #03
	BCC ~lm_each_char
;lm_found
	SEC		; return true
	RTS
:lm_miss
	A5 <mcurl	; LDA mcurl
	CLC
	ADC #04				; sizeof(mtable element)
	85 <mcurl	; STA mcurl
	A5 <mcurh	; LDA mcurh
	ADC #00
	85 <mcurh	; STA mcurl
	JMP &lm_each_elem
:lm_not_found
	LDA #00
	85 <mcurl	; STA mcurl
	85 <mcurh	; STA mcurh
	CLC		; return false
	RTS

:mtable_const		; constant opcodes (do not depend on operands)
	_ "BCC"
	_ 90
	_ "BCS"
	_ B0
	_ "BEQ"
	_ F0
	_ "BNE"
	_ D0
	_ "BRK"
	_ 00
	_ "CLC"
	_ 18
	_ "DEX"
	_ CA
	_ "DEY"
	_ 88
	_ "INX"
	_ E8
	_ "INY"
	_ C8
	_ "JMP"
	_ 4C
	_ "JSR"
	_ 20
	_ "PHA"
	_ 48
	_ "PLA"
	_ 68
	_ "RTS"
	_ 60
	_ "SEC"
	_ 38
	_ "TAX"
	_ AA
	_ "TAY"
	_ A8
	_ "TXA"
	_ 8A
	_ "TYA"
	_ 98
	_ 00		; null terminator

:mtable_immed		; opcodes with immediate mode operand
	_ "ADC"
	_ 69
	_ "AND"
	_ 29
	_ "CMP"
	_ C9
	_ "CPX"
	_ E0
	_ "CPY"
	_ C0
	_ "EOR"
	_ 49
	_ "LDA"
	_ A9
	_ "LDX"
	_ A2
	_ "LDY"
	_ A0
	_ 00		; null terminator

:emit_opcode
	LDY #03
	B1 <mcurl	; LDA (mcurl),Y
	JSR &emit
	JSR &incr_loc
	RTS

:set_pass
	JSR &parsehex
	85 <pass	; STA pass
	RTS

:eval_operand
	A4 <operand	; LDY operand
	BNE 01
	RTS
	B9 &line	; LDA line,Y
	84 <cursor	; STY <cursor
	E6 <cursor	; INC <cursor

	CMP #"&"
	BNE 04
	JSR &get_var
	RTS

	CMP #">"
	BNE 04
	JSR &get_hi
	RTS

	CMP #"<"
	BNE 04
	JSR &get_lo
	RTS

	CMP #"~"
	BNE 04
	JSR &get_rel_var
	RTS

	CMP #22		; CMP #'"'
	BNE 04
	JSR &string_literal
	RTS

	CMP #"-"
	BNE 04
	JSR &twos_comp
	RTS

			; assume hex operand
	C6 <cursor	; DEC cursor
	JSR &hex_literal
	RTS

:parsehex
	; Reads hex value from cursor position, and advances cursor.
	; Returns result in A.

	A4 <cursor	; LDY <cursor
					; hi nibble
	B9 &line	; LDA line,Y
	INY
	CMP #3A
	BCC 02
	ADC #F8
	AND #0F
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	85 00		; STA 00
					; lo nibble
	B9 &line	; LDA line,Y
	INY
	CMP #3A
	BCC 02
	ADC #F8
	AND #0F
	05 00		; ORA 00

	84 <cursor	; STY cursor
	RTS

:incr_loc
	E6 <locl	; INC locl
	BNE 02
	E6 <loch	; INC loch
	RTS

:emit
	PHA
	A5 <pass	; LDA pass
	CMP #01
	BNE 05
	PLA
	JSR &putchar
	RTS
	PLA
	RTS

:string_literal
	A4 <cursor	; LDY cursor
	B9 &line	; LDA line,Y
	E6 <cursor	; INC cursor
	CMP #"\""
	BNE 01
	RTS
	CMP #"\\"
	BNE ~string_letter
	A4 <cursor	; LDY cursor	; escape sequence
	B9 &line	; LDA line,Y
	E6 <cursor	; INC cursor
	CMP #"n"
	BNE 02
	LDA #0A
	CMP #"t"
	BNE 02
	LDA #09
	CMP #"0"
	BNE 02
	LDA #00
	; Anything else (including '\' or '"'), just fall through
	; and print whatever followed the original '\'.
	; Note that this (correctly) prevents \" from terminating a string.
:string_letter
	JSR &emit
	JSR &incr_loc
	JMP &string_literal

:hex_literal
	; Read and emit a series of hex bytes beginning at
	; cursor position
	A4 <cursor	; LDY cursor
	B9 &line	; LDA line,Y
	JSR &is_token
	BCS 01
	RTS
	JSR &parsehex
	JSR &emit
	JSR &incr_loc
	JMP &hex_literal

:twos_comp
	; Read a hex byte from cursor position, then emit
	; its negation
	JSR &parsehex
	EOR #FF
	CLC
	ADC #01
	JSR &emit
	JSR &incr_loc
	RTS

:puts
	LDY #00
:puts_loop
	B1 <putsl	; LDA (putsl),Y
	BNE 01
	RTS
	JSR &putchar
	INY
	BNE ~puts_loop
	BRK		; error -- string too long

:is_token
	CMP #" "
	BEQ ~is_token_f
	CMP #"\t"
	BEQ ~is_token_f
	CMP #"\n"
	BEQ ~is_token_f
	CMP #";"
	BEQ ~is_token_f
	CMP #00
	BEQ ~is_token_f
	SEC		; true
	RTS
:is_token_f
	CLC		; false
	RTS

:is_white
	CMP #" "
	BEQ ~is_white_t
	CMP #09		; CMP #'\t'
	BEQ ~is_white_t
	CLC		; false
	RTS
:is_white_t
	SEC		; true
	RTS

:printhex
	TAX				; backup
	4A		; LSR A		; high order nibble
	4A		; LSR A
	4A		; LSR A
	4A		; LSR A
	TAY				; lookup hex char
	CLC
	B9 &hex_digits	; LDA hex_digits,Y
	JSR &putchar
	TXA				; restore
	AND #0F				; low order nibble
	TAY				; lookup hex char
	CLC
	B9 &hex_digits	; LDA hex_digits,Y
	JSR &putchar
	RTS

:seek_var		; Using the variable name at cursor position,
			; find the variable in the vtable.
			;
			; If the variable is found, the return accumulator
			; will be 1, and addresses vcurl,h will point at its
			; vtable element
			;
			; If the variable is not found, the accumulator will be
			; 0, and vcurl,h will be equal to vnext, beyond the
			; end of the vtable. The caller may append a new value
			; here.
			;
	LDA #<vtable	; begin at top of vtable
	85 <vcurl	; STA vcurl
	LDA #>vtable
	85 <vcurh	; STA vcurh
:seek_var_each
	A5 <vcurl	; LDA vcurl	; reached end of vtable?
	C5 <vnextl	; CMP vnextl
	BNE ~seek_var_cmp
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP vnexth
	BEQ ~seek_var_not_found
:seek_var_cmp
	LDY #02				; vtable name follows 2-byte address
	A6 <cursor	; LDX cursor
:seek_var_cmp_loop
	B1 <vcurl	; LDA (vcurl),Y	; get next letter of name from vtable
	BNE ~seek_var_cmp_char		; null terminator?
	BD &line	; LDA line,X
	JSR &is_token
	BCC ~seek_var_found		; both variables ended -- match
	BCS ~seek_var_end
:seek_var_cmp_char
	DD &line	; CMP line,X
	BNE ~seek_var_end		; no match -- go to next vtable element
	INX				; else onward to next letter
	INY
	BNE ~seek_var_cmp_loop
	BRK				; error -- variable name too long
:seek_var_end
	B1 <vcurl	; LDA (vcurl),Y	; seek to end of unmatched name
	INY
	CMP #00
	BNE ~seek_var_end
:seek_var_next
	TYA				; move vcur to next variable in vtable
	CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	BCC 02
	E6 <vcurh	; INC 01
	BNE ~seek_var_each
:seek_var_not_found
	LDA #00		; variable does not exist
	RTS
:seek_var_found
	LDA #01		; variable exists
	RTS

:get_var		; Reads variable name from cursor position, then...
			;
			; ...during pass 0, increments location counter only.
			; ...during pass 1, also evaluates and emits its value.
			;
	JSR &incr_loc
	JSR &incr_loc
			;
	A5 <pass	; LDA pass; which pass?
	BEQ ~get_var_end

	JSR &seek_var	; set vcurl,h
	BNE 05		; check return result
	LDA #01		; errcode 1 == variable not found
	JMP &error

	LDY #00				; lo value
	B1 <vcurl	; LDA (vcurl),Y
	JSR &emit
	LDY #01				; hi value
	B1 <vcurl	; LDA (vcurl),Y
	JSR &emit
:get_var_end
	RTS

:get_hi			; Same as get_var, but emits hi byte only
			;
	JSR &incr_loc
			;
	A5 <pass	; LDA pass
	BEQ ~get_hi_end
			;
	JSR &seek_var	; sets vcurl,h
	BNE 05		; check return result
	LDA #01		; errcode 1 == variable not found
	JMP &error

	LDY #01				; hi value
	B1 <vcurl	; LDA (vcurl),Y
	JSR &emit
:get_hi_end
	RTS

:get_lo			; Same as get_var, but emits lo byte only
			;
	JSR &incr_loc

	A5 <pass	; LDA pass
	BEQ ~get_lo_end

	JSR &seek_var	; sets vcurl,h
	BNE 05		; check return result
	LDA #01		; errcode 1 == variable not found
	JMP &error

	LDY #00				; lo value
	B1 <vcurl	; LDA (vcurl),Y
	JSR &emit
:get_lo_end
	RTS

:get_rel_var		; Same as get_var, but emits single-byte relative offset
			; from current location (appropriate for branch
			; instructions).
	JSR &incr_loc
	A5 <pass	; LDA pass
	BNE 01
	RTS

	JSR &seek_var	; sets vcurl,h
	BNE 05		; check return result
	LDA #01		; errcode 1 == variable not found
	JMP &error

	LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	SEC				; compute (pv) - (loc), low byte only
	E5 <locl	; SBC locl
	JSR &emit
	RTS

:set_var		; Reads a variable name from line at cursor position,
			; then writes an element into the vtable using the
			; current location counter as its value.
			;
			; An existing variable will be overwritten. New
			; variables will be appended to the end of the vtable.
	JSR &seek_var			; sets vcurl,h
	PHA				; 0 if record did not exist (new element)

	LDY #00				; save location counter value
	A5 <locl	; LDA locl
	91 <vcurl	; STA (vcurl),Y
	INY
	A5 <loch	; LDA loch
	91 <vcurl	; STA (vcurl),Y
					; save variable name
	A6 <cursor	; LDX cursor
:set_var_loop
	INY
	BD &line	; LDA line,X
	91 <vcurl	; STA (vcurl),Y
	INX
	JSR &is_token	; end of name?
	BCS ~set_var_loop

	LDA #00		; null terminate name
	91 <vcurl	; STA (vcurl),Y
	INY
			;
			; If we have extended the vtable, we must update the
			; end pointer vnext.
			;
	PLA
	BEQ 01
	RTS
	98		; TYA		; update vnext
	CLC
	65 <vnextl	; ADC vnextl
	85 <vnextl	; STA vnextl
	BCC 02
	E6 <vnexth	; INC vnexth
	RTS

:print_vtable
	LDA #"P"
	JSR &putchar
	LDA #01
	JSR &printhex
	LDA #"\n"
	JSR &putchar

	LDA #<vtable
	85 <vcurl	; STA vcurl
	LDA #>vtable
	85 <vcurh	; STA vcurh
:pv_loop
	A5 <vcurl	; LDA vcurl	; at end of vtable?
	C5 <vnextl	; CMP (vnextl)
	BNE 07
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP (vnexth)
	BNE 01
	RTS

	LDA #"*"
	JSR &putchar
	LDY #01				; print address -- high byte first!
	B1 <vcurl	; LDA (vcurl),Y
	JSR &printhex
	LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	JSR &printhex
	LDA #" "
	JSR &putchar
	LDA #":"
	JSR &putchar

	LDY #02
:pv_name_loop
	B1 <vcurl	; LDA (vcurl),Y
	INY
	CMP #00
	BEQ ~pv_end_of_name
	JSR &putchar
	BNE ~pv_name_loop
	BRK		; error -- variable name too long
:pv_end_of_name
	LDA #"\n"
	JSR &putchar
	98		; TYA
	CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	BCC 02
	E6 <vcurh	; INC vcurh
	JMP &pv_loop

:show			; debugging aid
	JSR &show_line
;	JSR &show_pass
	JSR &show_loc
;	JSR &show_org
	JSR &show_label
	JSR &show_mnemonic
	JSR &show_operand
;	JSR &show_comment
;	JSR &show_vnext
	JSR &show_mcur
	JSR &show_addrmode
	LDA #"\n"
	JSR &putchar
	RTS

:show_line
	LDA #<sz_line
	85 <putsl	; STA putsl
	LDA #>sz_line
	85 <putsh	; STA putsh
	JSR &puts
	A5 <lineh	; LDA lineh
	JSR &printhex
	A5 <linel	; LDA linel
	JSR &printhex
	RTS

:show_pass
	LDA #<sz_pass
	85 <putsl	; STA putsl
	LDA #>sz_pass
	85 <putsh	; STA putsh
	JSR &puts
	A5 <pass	; LDA pass
	JSR &printhex
	RTS

:show_loc
	LDA #<sz_loc
	85 <putsl	; STA putsl
	LDA #>sz_loc
	85 <putsh	; STA putsh
	JSR &puts
	A5 <loch	; LDA loch
	JSR &printhex
	A5 <locl	; LDA locl
	JSR &printhex
	RTS

:show_org
	LDA #<sz_org
	85 <putsl	; STA putsl
	LDA #>sz_org
	85 <putsh	; STA putsh
	JSR &puts
	A5 <org		; LDA org
	JSR &printhex
	RTS

:show_label
	LDA #<sz_label
	85 <putsl	; STA putsl
	LDA #>sz_label
	85 <putsh	; STA putsh
	JSR &puts
	A5 <label	; LDA label
	JSR &printhex
	RTS

:show_mnemonic
	LDA #<sz_mnemonic
	85 <putsl	; STA putsl
	LDA #>sz_mnemonic
	85 <putsh	; STA putsh
	JSR &puts
	A5 <mnemonic	; LDA mnemonic
	JSR &printhex
	RTS

:show_operand
	LDA #<sz_operand
	85 <putsl	; STA putsl
	LDA #>sz_operand
	85 <putsh	; STA putsh
	JSR &puts
	A5 <operand	; LDA operand
	JSR &printhex
	RTS

:show_comment
	LDA #<sz_comment
	85 <putsl	; STA putsl
	LDA #>sz_comment
	85 <putsh	; STA putsh
	JSR &puts
	A5 <comment	; LDA comment
	JSR &printhex
	RTS

:show_vnext
	LDA #<sz_vnext
	85 <putsl	; STA putsl
	LDA #>sz_vnext
	85 <putsh	; STA putsh
	JSR &puts
	A5 <vnexth	; LDA vnexth
	JSR &printhex
	A5 <vnextl	; LDA vnextl
	JSR &printhex
	RTS

:show_mcur
	LDA #<sz_mcur
	85 <putsl	; STA putsl
	LDA #>sz_mcur
	85 <putsh	; STA putsh
	JSR &puts
	A5 <mcurh	; LDA mcurh
	JSR &printhex
	A5 <mcurl	; LDA mcurl
	JSR &printhex
	RTS

:show_addrmode
	LDA #<sz_addrmode
	85 <putsl	; STA putsl
	LDA #>sz_addrmode
	85 <putsh	; STA putsh
	JSR &puts
	A5 <addrmode	; LDA addrmode
	JSR &printhex
	RTS

:sz_line	_ "; line:\0"
:sz_pass	_ "  pass:\0"
:sz_loc		_ "  loc:\0"
:sz_org		_ "  org:\0"
:sz_label	_ "  label:\0"
:sz_mnemonic	_ "  mnem:\0"
:sz_operand	_ "  oper:\0"
:sz_comment	_ "  comment:\0"
:sz_vnext	_ "  vnext:\0"
:sz_mcur	_ "  mcur:\0"
:sz_addrmode	_ "  mode:\0"

:hex_digits _ "0123456789ABCDEF"

:dump_vtable
	LDA #<vtable
	85 <putsl	; STA putsl
	LDA #>vtable
	85 <putsh	; STA putsh
	JSR &hex_dump
	RTS

:hex_dump		; emit bytes beginning at putsl
	A5 <putsh	; LDA putsl
	JSR &printhex
	A5 <putsl	; LDA putsh
	JSR &printhex
	LDA #":"
	JSR &putchar
	LDY #00
:hex_dump_loop
	B1 <putsl	; LDA (putsl),Y
	84 00		; STY 00
	JSR &printhex
	LDA #" "
	JSR &putchar
	A4 00		; LDY 00
	INY
	CPY #80
	BNE ~hex_dump_loop
	LDA #"\n"
	JSR &putchar
	RTS

:error
	PHA		; save error code

	LDA #<sz_errline
	85 <putsl	; STA putsl
	LDA #>sz_errline
	85 <putsh	; STA putsh
	JSR &puts
	A5 <lineh	; LDA lineh
	JSR &printhex
	A5 <linel	; LDA linel
	JSR &printhex

	LDA #<sz_errcode
	85 <putsl	; STA putsl
	LDA #>sz_errcode
	85 <putsh	; STA putsh
	JSR &puts
	PLA
	JSR &printhex

	LDA #"\n"
	JSR &putchar
	BRK

:sz_errline _ "Line:\0"
:sz_errcode _ "  Error:\0"
