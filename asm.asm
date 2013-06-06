*FFDD	:putchar
*FFEE	:getchar

;	global variables
;
;	20-21	label A
;	22-23	label B
;	...
;	32-33	label Z
;
;	80-81	location counter
;	82	assembly pass (0 or 1)
;	84-85   vnext ; pointer to next available vtable entry

*2000	.A :buf		; general-purpose string buffer
*3000	.V :vtable	; variable-length symbol table

*1000

:main
	4C @init	; JMP init

:incr_loc
	E680		; INC 80
	D002		; BNE +2
	E681		; INC 81
	60		; RTS

:skip_comment
	20 @getchar	; JSR getchar
	C90A		; CMP #'\n'
	D0 -07		; BNE -7
	60		; RTS

:emit
	48		; PHA
	A582		; LDA 82
	C901		; CMP #1
	D005		; BNE +5
	68		; PLA
	20 @putchar	; JSR putchar
	60		; RTS
	68		; PLA
	60		; RTS

:define_label
	20 @getchar	; JSR getchar
	18		; CLC
	69BF		; ADC #BF	; 'A'-'Z' -> 0...
	0A		; ASL A		; sizeof(label) = 2
	AA		; TAX
	A580		; LDA 80	; location counter
	9520		; STA 20,X	; values stored from 20...
	A581		; LDA 81
	9521		; STA 21,X
	60		; RTS

:eval_label
	20 @getchar	; JSR getchar
	18		; CLC
	69BF		; ADC #BF	; 'A'-'Z' -> 0...
	0A		; ASL A		; sizeof(label) = 2
	AA		; TAX
	B520		; LDA 20,X
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	B521		; LDA 21,X
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	60		; RTS

; The variable table (vtable) is a packed array of null-terminated records:
;
;	2 bytes: value (16-bit memory address)
;	n bytes: name (variable length string)
;	1 byte:  0 terminator
;
; The table begins at &V. The pointer vnext (84-85) always points to the first
; empty byte beyond the end of the vtable.

:read_var		; Reads a variable name from stdin and stores it in &A, offset
			; by 2 bytes to match vtable records.
			;
	A9 <A		; LDA #lo(buf)
	8502		; STA pbuf
	A9 >A		; LDA #hi(buf)
	8503		; STA pbuf+1
	A002		; LDY #2	; Note 2-byte offset
:read_var_loop
	20 @getchar	; JSR getchar
	C9 " "		; CMP #' '
	F00E		; BEQ read_var_end
	C909		; CMP #'\t'
	F00A		; BEQ read_var_end
	C90A		; CMP #'\n'
	F006		; BEQ read_var_end
	9102		; STA (pbuf),Y
	C8		; INY
	D0 -14		; BNE read_var_loop
	00		; BRK		; error -- variable name too long
:read_var_end
	A900		; LDA #0	; null terminate input buffer
	9102		; STA (pbuf),Y
	60		; RTS

:seek_var
			; Finds a named variable in the vtable.
			; Variable name to be matched must be stored in buffer A.
			; Variable name should be offset by 2 bytes to match vtable records.
			;
			; If the variable is found, the return accumulator will be 1,
			; and addresses 00-01 will point at its vtable entry.
			;
			; If the variable is not found, the accumulator will be 0,
			; and the pointer will be equal to vnext, beyond the end of the
			; vtable. The caller may append a new value here.
			;
			; Addresses 02-03 will be used as temp pointer into buffer A.
			;
	A9 <V		; LDA #lo(vtable); begin at top of vtable
	8500		; STA pv
	A9 >V		; LDA #hi(vtable)
	8501		; STA pv+1
	A9 <A		; LDA #lo(buf)	; temp pointer into buffer A
	8502		; STA pbuf
	A9 >A		; LDA #hi(buf)
	8503		; STA pbuf+1
:seek_var_each
	A500		; LDA pv	; reached end of vtable?
	C584		; CMP vnext
	D009		; BNE seek_var_cmp
	A501		; LDA pv+1
	C585		; CMP vnext+1
	D003		; BNE seek_var_cmp
	A900		; LDA #00	; variable does not exist
	60		; RTS
:seek_var_cmp
	A002		; LDY #2	; variable name begins after 2-byte address
:seek_var_cmp_loop
	B100		; LDA (pv),Y
	D102		; CMP (pbuf),Y
	D008		; BNE seek_var_skip
	C900		; CMP #0	; reached end of name -> successful match
	F018		; BEQ seek_var_found
	C8		; INY
	D0 -0D		; BNE seep_var_cmp_loop
	00		; BRK		; error -- variable name too long
:seek_var_skip
	B100		; LDA (pv),Y	; seek to end of unmatched name
	C8		; INY
	C900		; CMP #0
	D0 -07		; BNE seek_var_skip
:seek_var_next
	98		; TYA		; move pv to next variable in vtable
	18		; CLC
	6500		; ADC 00
	8500		; STA 00
	9002		; BCC +2
	E601		; INC 01
	4C @seek_var_each ; JUMP
:seek_var_found
	A901		; LDA #01	; variable exists
	60		; RTS

:get_var		; Reads a variable name from stdin, then
			;
			;   ... during pass 0, increments location counter only.
			;   ... during pass 1, also evaluates and emits its value.
			;
			; Addresses 00-03 will be destroyed.
			;
	20 @read_var	; JSR read_var  ; sets 02-03 to variable name buffer
	20 @incr_loc	; JSR incr_loc
	20 @incr_loc	; JSR incr_loc
			;
	A582		; LDA 82	; which pass?
	C900		; CMP #0
	F011		; BEQ get_var_end
			;
	20 @seek_var	; JSR seek_var	; sets 00-01 to vtable record
	A000		; LDY #00	; lo value
	B100		; LDA (pv),Y
	20 @emit	; JSR emit
	A001		; LDY #01	; hi value
	B100		; LDA (pv),Y
	20 @emit	; JSR emit
:get_var_end
	60		; RTS

:get_hi			; Same as get_var, but emits hi byte only
			;
	20 @read_var	; JSR read_var  ; sets 02-03 to variable name buffer
	20 @incr_loc	; JSR incr_loc
			;
	A582		; LDA 82	; which pass?
	C900		; CMP #0
	F00A		; BEQ get_hi_end
			;
	20 @seek_var	; JSR seek_var	; sets 00-01 to vtable record
	A001		; LDY #01	; hi value
	B100		; LDA (pv),Y
	20 @emit	; JSR emit
:get_hi_end
	60		; RTS

:get_lo			; Same as get_var, but emits lo byte only
			;
	20 @read_var	; JSR read_var  ; sets 02-03 to variable name buffer
	20 @incr_loc	; JSR incr_loc
			;
	A582		; LDA 82	; which pass?
	C900		; CMP #0
	F00A		; BEQ get_lo_end
			;
	20 @seek_var	; JSR seek_var	; sets 00-01 to vtable record
	A000		; LDY #00	; lo value
	B100		; LDA (pv),Y
	20 @emit	; JSR emit
:get_lo_end
	60		; RTS

:set_var		; Reads a variable name from stdin, then writes an entry
			; in the vtable using the current location counter as its value.
			;
			; An existing variable will be overwritten. New variables will
			; be appended to the end of the vtable.
			;
			; Addresses 00-03 will be destroyed.
			;
	20 @read_var	; JSR read_var  ; sets 02-03 to variable name buffer
	20 @seek_var	; JSR seek_var	; sets 00-01 to vtable record
	48		; PHA		; 0 if record did not exist (new vtable entry)
			;
	A000		; LDY #00	; save location counter value
	A580		; LDA loc
	9100		; STA (pv),Y
	C8		; INY
	A581		; LDA loc+1
	9100		; STA (pv),Y
:set_var_loop
	C8		; INY		; save variable name
	B102		; LDA (pbuf),Y
	9100		; STA (pv),Y
	C900		; CMP #0
	D0 -09		; BNE set_var_loop
			;
			; If we have extended the vtable, we must update the end pointer.
			;
	68		; PLA
	C900		; CMP #00
	F001		; BEQ +01
	60		; RTS
	C8		; INY
	98		; TYA		; update vnext
	18		; CLC
	6584		; ADC 84
	8584		; STA 84
	9002		; BCC +2
	E685		; INC 85
	60		; RTS

:lo_byte				; eval_label, but emit low byte only
	20 @getchar	; JSR getchar
	18		; CLC
	69BF		; ADC #BF	; 'A'-'Z' -> 0...
	0A		; ASL A		; sizeof(label) = 2
	AA		; TAX
	B520		; LDA 20,X
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	60		; RTS

:hi_byte				;eval_label, but emit high byte only
	20 @getchar	; JSR getchar
	18		; CLC
	69BF		; ADC #BF	; 'A'-'Z' -> 0...
	0A		; ASL A		; sizeof(label) = 2
	AA		; TAX
	B521		; LDA 21,X
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	60		; RTS

:printhex
	AA		; TAX		; backup
	4A		; LSR A		; high order nibble
	4A		; LSR A
	4A		; LSR A
	4A		; LSR A
	A8		; TAY		; lookup hex char
	18		; CLC
	B9 &X		; LDA hex_digits,Y
	20 @putchar	; JSR putchar
	8A		; TXA		; restore
	290F		; AND #0F	; low order nibble
	A8		; TAY		; lookup hex char
	18		; CLC
	B9 &X		; LDA hex_digits,Y
	20 @putchar	; JSR putchar
	60		; RTS

:print_variable_table
	A9 "P"		; LDA #"P"
	20 @putchar	; JSR putchar
	A901		; LDA #1
	20 @printhex	; JSR printhex
	A90A		; LDA #"\n"
	20 @putchar	; JSR putchar
			;
	A9 <V		; LDA lo(vtable)
	8500		; STA 00	; 00-01: temp pointer into vtable
	A9 >V		; LDA hi(vtable)
	8501		; STA 01
:pv_loop
	A500		; LDA 00	; at end of vtable?
	C584		; CMP lo(vnext)
	D007		; BNE +7
	A501		; LDA 01
	C585		; CMP hi(vnext)
	D001		; BNE +1
	60		; RTS

	A9 "*"		; LDA #"*"
	20 @putchar	; JSR putchar
	A001		; LDY #01	; print address -- high byte first!
	B100		; LDA (00),Y
	20 @printhex		; JSR printhex
	A000		; LDY #00
	B100		; LDA (00),Y
	20 @printhex		; JSR printhex
	A9 " "		; LDA #" "
	20 @putchar	; JSR putchar
	A9 ":"		; LDA #":"
	20 @putchar	; JSR putchar

	A002		; LDY #02
:pv_name_loop
	B100		; LDA (00),Y
	C900		; CMP #0
	F007		; BEQ pv_end_of_name
	20 @putchar	; JSR putchar
	C8		; INY
	D0 -0C		; BNE :pv_name_loop
	00		; BRK		; error -- variable name too long
:pv_end_of_name
	A90A		; LDA #"\n"
	20 @putchar	; JSR putchar
	C8		; INY		; update temp pointer to next element
	98		; TYA
	18		; CLC
	6500		; ADC 00
	8500		; STA 00
	9002		; BCC +2
	E601		; INC 01
	4C @pv_loop	; JMP

:print_symbol_table
	A9 "P"		; LDA #"P"
	20 @putchar	; JSR putchar
	A901		; LDA #1
	20 @printhex	; JSR printhex
	A90A		; LDA #"\n"
	20 @putchar	; JSR putchar
	A200		; LDX #00
:pst_loop
	A9 "*"		; LDA #"*"
	20 @putchar	; JSR putchar
	B521		; LDA 21,X
	DA		; PHX
	20 @printhex	; JSR printhex
	FA		; PLX
	B520		; LDA 20,X
	DA		; PHX
	20 @printhex	; JSR printhex
	FA		; PLX
	A9 " "		; LDA #" "
	20 @putchar	; JSR putchar
	A9 "."		; LDA #"."
	20 @putchar	; JSR putchar
	8A		; TXA
	4A		; LSR A
	18		; CLC
	6941		; ADC #41	; 0..25 -> 'A'-'Z'
	20 @putchar	; JSR putchar
	A90A		; LDA #"\n"
	20 @putchar	; JSR putchar
	E8		; INX
	E8		; INX
	8A		; TXA
	C934		; CMP #34
	D001		; BNE +1
	60		; RTS
	4C @pst_loop	; JMP

:string_literal
	20 @getchar	; JSR getchar
	C922		; CMP #'"'
	D001		; BNE +1
	60		; RTS
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	4C @string_literal ; JMP

:twos_comp
	; Read a hex byte from stdin, then emit
	; the negation of that byte.
	20 @getchar	; JSR getchar
	20 @parse_hex_byte	; JSR parse_hex_byte
	49FF		; EOR #FF
	18		; CLC
	6901		; ADC #1
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
	60		; RTS

:parse_hex_byte
	; Assumes that the first char is already in A.
	; Reads the second char from stdin, then returns
	; the byte value in A.
					; hi nibble
	C93A		; CMP #3A
	9002		; BCC .+2
	69F8		; ADC #F8
	290F		; AND #0F
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	8510		; STA 10
					; lo nibble
	20 @getchar	; JSR getchar
	C93A		; CMP #3A
	9002		; BCC .+2
	69F8		; ADC #F8
	290F		; AND #0F
	0510		; ORA 10
	60		; RTS

:set_org
	20 @getchar	; JSR getchar
	20 @parse_hex_byte ; JSR parse_hex_byte
	8581		; STA 81	; MSB first
	20 @getchar	; JSR getchar
	20 @parse_hex_byte ; JSR parse_hex_byte
	8580		; STA 80	; 16-bit location counter
	60		; RTS

:set_pass
	20 @getchar	; JSR getchar
	20 @parse_hex_byte ; JSR parse_hex_byte
	8582		; STA 82
	60		; RTS

:init
	A9 <V		; LDA lo(vtable)
	8584		; STA pnext
	A9 >V		; LDA hi(vtable)
	8585		; STA pnext+1
	A900		; LDA #00	; pass 0 by default
	8582		; STA pass

:main_loop
	20 @getchar	; JSR getchar
	C9FF		; CMP #FF	; EOF?
	D00D		; BNE +13
	A582		; LDA 82
	C900		; CMP #0
	D006		; BNE +6
	20 @print_symbol_table ; JSR
	20 @print_variable_table ; JSR
	00		; BRK
			;
	C9 " "		; CMP #' '	; skip white space
	F0 -18		; BEQ loop
	C909		; CMP #'\t'
	F0 -1C		; BEQ loop
	C90A		; CMP #'\n'
	F0 -20		; BEQ loop
			;		; switch on pseudo-op
	C9 "*"		; CMP #'*'
	D006		; BNE +6
	20 @set_org	; JSR set_org
	4C @main_loop	; JMP
			;
	C9 "."		; CMP #'.'
	D006		; BNE +6
	20 @define_label ; JSR
	4C @main_loop	; JMP
			;
	C9 "&"		; CMP #'&'
	D006		; BNE +6
	20 @eval_label	; JSR
	4C @main_loop	; JMP
			;
	C9 "]"		; CMP #'>'
	D006		; BNE +6
	20 @get_hi	; JSR get_hi
	4C @main_loop	; JMP
			;
	C9 "["		; CMP #'['
	D006		; BNE +6
	20 @get_lo	; JSR get_lo
	4C @main_loop	; JMP
			;
	C9 ">"		; CMP #'>'
	D006		; BNE +6
	20 @hi_byte	; JSR hi_byte
	4C @main_loop	; JMP
			;
	C9 "<"		; CMP #'<'
	D006		; BNE +6
	20 @lo_byte	; JSR lo_byte
	4C @main_loop	; JMP
			;
	C922		; CMP #'"'
	D006		; BNE +6
	20 @string_literal	; JSR string_literal
	4C @main_loop	; JMP
			;
	C9 ";"		; CMP #';'
	D006		; BNE +6
	20 @skip_comment	; JSR skip_comment
	4C @main_loop	; JMP
			;
	C9 "P"		; CMP #'P'
	D006		; BNE +6
	20 @set_pass	; JSR set_pass
	4C @main_loop	; JMP
			;
	C9 "-"		; CMP #'-'
	D006		; BNE +6
	20 @twos_comp	; JSR twos_comp
	4C @main_loop	; JMP
			;
	C9 ":"		; CMP #':'
	D006		; BNE +6
	20 @set_var	; JSR set_var
	4C @main_loop	; JMP
			;
	C9 "@"		; CMP #'@'
	D006		; BNE +6
	20 @get_var	; JSR get_var
	4C @main_loop	; JMP
			;
			; no pseudo-op; emit raw byte
			;
	20 @parse_hex_byte ; JSR parse_hex_byte
	20 @emit	; JSR emit
	20 @incr_loc	; JSR incr_loc
			;
	4C @main_loop	; JMP

.X :hex_digits
	"0123456789ABCDEF"

