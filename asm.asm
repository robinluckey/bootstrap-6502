*FFDD	:putchar
*FFEE	:getchar

;	page zero global variables

*0080	:locl		; location counter
*0081	:loch
*0082	:pass		; assembly pass (0 or 1)

*0084	:bufl		; pointer to current location in buf
*0085	:bufh

*0086	:vcurl		; pointer to current vtable entry
*0087	:vcurh		; pointer to current vtable entry
*0088	:vnextl		; pointer to next available vtable entry
*0089	:vnexth

;	data storage

*2000	:buf		; general-purpose string buffer
*2100	:vtable		; variable-length symbol table

;	code

*1000			; all programs must begin at $1000

:main

:init
	A9 <vtable	; LDA lo(vtable)
	85 <vnextl	; STA vnextl
	A9 >vtable	; LDA hi(vtable)
	85 <vnexth	; STA vnexth
	A900		; LDA #00	; pass 0 by default
	85 <pass	; STA pass

:main_loop
	20 &getchar	; JSR getchar
	C9FF		; CMP #FF	; EOF?
	D00A		; BNE +10
	A5 <pass	; LDA pass
	C900		; CMP #0
	D003		; BNE +3
	20 &print_vtable ; JSR print_vtable
	00		; BRK
			;
	C9 " "		; CMP #' '	; skip white space
	F0 ~main_loop	; BEQ main_loop
	C909		; CMP #'\t'
	F0 ~main_loop	; BEQ main_loop
	C90A		; CMP #'\n'
	F0 ~main_loop	; BEQ main_loop
			;		; switch on pseudo-op
	C9 "*"		; CMP #'*'
	D006		; BNE +6
	20 &set_loc	; JSR set_loc
	4C &main_loop	; JMP
			;
	C9 ">"		; CMP #'>'
	D006		; BNE +6
	20 &get_hi	; JSR get_hi
	4C &main_loop	; JMP
			;
	C9 "<"		; CMP #'<'
	D006		; BNE +6
	20 &get_lo	; JSR get_lo
	4C &main_loop	; JMP
			;
	C922		; CMP #'"'
	D006		; BNE +6
	20 &string_literal	; JSR string_literal
	4C &main_loop	; JMP
			;
	C9 ";"		; CMP #';'
	D006		; BNE +6
	20 &skip_comment	; JSR skip_comment
	4C &main_loop	; JMP
			;
	C9 "P"		; CMP #'P'
	D006		; BNE +6
	20 &set_pass	; JSR set_pass
	4C &main_loop	; JMP
			;
	C9 "-"		; CMP #'-'
	D006		; BNE +6
	20 &twos_comp	; JSR twos_comp
	4C &main_loop	; JMP
			;
	C9 ":"		; CMP #':'
	D006		; BNE +6
	20 &set_var	; JSR set_var
	4C &main_loop	; JMP
			;
	C9 "&"		; CMP #'&'
	D006		; BNE +6
	20 &get_var	; JSR get_var
	4C &main_loop	; JMP
			;
	C9 "~"		; CMP #'~'
	D006		; BNE +6
	20 &get_rel_var	; JSR get_rel_var
	4C &main_loop	; JMP
			;
			; no pseudo-op; emit raw byte
			;
	20 &parse_hex_byte ; JSR parse_hex_byte
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
			;
	4C &main_loop	; JMP main_loop

:set_loc
	20 &getchar	; JSR getchar
	20 &parse_hex_byte ; JSR parse_hex_byte
	85 <loch	; STA loch	; MSB first
	20 &getchar	; JSR getchar
	20 &parse_hex_byte ; JSR parse_hex_byte
	85 <locl	; STA locl
	60		; RTS

:incr_loc
	E6 <locl	; INC locl
	D002		; BNE +2
	E6 <loch	; INC loch
	60		; RTS

:set_pass
	20 &getchar	; JSR getchar
	20 &parse_hex_byte ; JSR parse_hex_byte
	85 <pass	; STA pass
	60		; RTS

:skip_comment
	20 &getchar	; JSR getchar
	C90A		; CMP #'\n'
	D0 ~skip_comment ; BNE
	60		; RTS

:emit
	48		; PHA
	A5 <pass	; LDA pass
	C901		; CMP #1
	D005		; BNE +5
	68		; PLA
	20 &putchar	; JSR putchar
	60		; RTS
	68		; PLA
	60		; RTS

:string_literal
	20 &getchar	; JSR getchar
	C922		; CMP #'"'
	D001		; BNE +1
	60		; RTS
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
	4C &string_literal ; JMP

:twos_comp
	; Read a hex byte from stdin, then emit
	; the negation of that byte.
	20 &getchar	; JSR getchar
	20 &parse_hex_byte	; JSR parse_hex_byte
	49FF		; EOR #FF
	18		; CLC
	6901		; ADC #1
	20 &emit	; JSR emit
	20 &incr_loc	; JSR incr_loc
	60		; RTS

:parse_hex_byte
	; Assumes that the first char is already in A.
	; Reads the second char from stdin, then returns
	; the byte value in A.
					; hi nibble
	C93A		; CMP #3A
	9002		; BCC +2
	69F8		; ADC #F8
	290F		; AND #0F
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	0A		; ASL A
	8510		; STA 10
					; lo nibble
	20 &getchar	; JSR getchar
	C93A		; CMP #3A
	9002		; BCC +2
	69F8		; ADC #F8
	290F		; AND #0F
	0510		; ORA 10
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

:hex_digits
	"0123456789ABCDEF"

; The variable table (vtable) is a packed array of null-terminated records:
;
;	2 bytes: value (16-bit memory address)
;	n bytes: name (variable length string)
;	1 byte:  0 terminator
;
; The table begins at :vtable. :vnext always points to the first
; empty byte beyond the end of the vtable.

:read_var		; Reads a variable name from stdin and
			; stores it in :buf, offset by 2 bytes
			; to match vtable records.
			;
	A9 <buf		; LDA #lo(buf)
	85 <bufl	; STA bufl
	A9 >buf		; LDA #hi(buf)
	85 <bufh	; STA bufh
	A002		; LDY #2	; Note 2-byte offset
:read_var_loop
	20 &getchar	; JSR getchar
	C9 " "		; CMP #' '
	F0 ~read_var_end ; BEQ read_var_end
	C909		; CMP #'\t'
	F0 ~read_var_end ; BEQ read_var_end
	C90A		; CMP #'\n'
	F0 ~read_var_end ; BEQ read_var_end
	91 <bufl	; STA (bufl),Y
	C8		; INY
	D0 ~read_var_loop ; BNE read_var_loop
	00		; BRK		; error -- variable name too long
:read_var_end
	A900		; LDA #0	; null terminate input buffer
	91 <bufl	; STA (bufl),Y
	60		; RTS

:seek_var		; Finds a named variable in the vtable.
			; Variable name to be matched must be stored in :buf.
			; Variable name should be offset by 2 bytes to match
			; vtable records.
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
	A9 <buf		; LDA #lo(buf)	; temp pointer into buffer A
	85 <bufl	; STA bufl
	A9 >buf		; LDA #hi(buf)
	85 <bufh	; STA bufh
:seek_var_each
	A5 <vcurl	; LDA vcurl	; reached end of vtable?
	C5 <vnextl	; CMP vnextl
	D0 ~seek_var_cmp ; BNE seek_var_cmp
	A5 <vcurh	; LDA vcurh
	C5 <vnexth	; CMP vnexth
	D0 ~seek_var_cmp ; BNE seek_var_cmp
	A900		; LDA #00	; variable does not exist
	60		; RTS
:seek_var_cmp
	A002		; LDY #2	; variable name follows 2-byte address
:seek_var_cmp_loop
	B1 <vcurl	; LDA (vcurl),Y
	D1 <bufl	; CMP (bufl),Y
	D0 ~seek_var_skip ; BNE seek_var_skip
	C900		; CMP #0	; reached end of name -> matched
	F0 ~seek_var_found ; BEQ seek_var_found
	C8		; INY
	D0 ~seek_var_cmp_loop ; BNE seep_var_cmp_loop
	00		; BRK		; error -- variable name too long
:seek_var_skip
	B1 <vcurl	; LDA (vcurl),Y	; seek to end of unmatched name
	C8		; INY
	C900		; CMP #0
	D0 ~seek_var_skip ; BNE seek_var_skip
:seek_var_next
	98		; TYA		; move vcur to next variable in vtable
	18		; CLC
	65 <vcurl	; ADC vcurl
	85 <vcurl	; STA vcurl
	9002		; BCC +2
	E6 <vcurh	; INC 01
	4C &seek_var_each ; JUMP
:seek_var_found
	A901		; LDA #01	; variable exists
	60		; RTS

:get_var		; Reads a variable name from stdin, then...
			;
			; ...during pass 0, increments location counter only.
			; ...during pass 1, also evaluates and emits its value.
			;
	20 &read_var	; JSR read_var  ; sets buf, bufl
	20 &incr_loc	; JSR incr_loc
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass; which pass?
	C900		; CMP #0
	F0 ~get_var_end	; BEQ get_var_end
			;
	20 &seek_var	; JSR seek_var	; set vcurl,h
	A000		; LDY #00	; lo value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
	A001		; LDY #01	; hi value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_var_end
	60		; RTS

:get_hi			; Same as get_var, but emits hi byte only
			;
	20 &read_var	; JSR read_var  ; fills buf, inits bufl
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C900		; CMP #0
	F0 ~get_hi_end	; BEQ get_hi_end
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	A001		; LDY #01	; hi value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_hi_end
	60		; RTS

:get_lo			; Same as get_var, but emits lo byte only
			;
	20 &read_var	; JSR read_var  ; fill buf, sets bufl
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C900		; CMP #0
	F0 ~get_lo_end	; BEQ get_lo_end
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	A000		; LDY #00	; lo value
	B1 <vcurl	; LDA (vcurl),Y
	20 &emit	; JSR emit
:get_lo_end
	60		; RTS

:get_rel_var		; Same as get_var, but emits single-byte relative offset
			; from current location (appropriate for branch
			; instructions).
			;
	20 &read_var	; JSR read_var  ; fills buf, sets bufl
	20 &incr_loc	; JSR incr_loc
			;
	A5 <pass	; LDA pass
	C900		; CMP #0
	D001		; BNE +1
	60		; RTS
			;
	20 &seek_var	; JSR seek_var	; sets vcurl,h
			;
	A000		; LDY #00
	B1 <vcurl	; LDA (vcurl),Y
	38		; SEC		; compute (pv) - (loc), low byte only
	E5 <locl	; SBC locl
	20 &emit	; JSR emit
	60		; RTS

:set_var		; Reads a variable name from stdin, then writes an entry
			; into the vtable using the current location counter as
			; its value.
			;
			; An existing variable will be overwritten. New
			; variables will be appended to the end of the vtable.
			;
	20 &read_var	; JSR read_var  ; fills buf, sets bufl,h
	20 &seek_var	; JSR seek_var	; sets vcurl,h
	48		; PHA		; 0 if record did not exist (new entry)
			;
	A000		; LDY #00	; save location counter value
	A5 <locl	; LDA locl
	91 <vcurl	; STA (vcurl),Y
	C8		; INY
	A5 <loch	; LDA loch
	91 <vcurl	; STA (vcurl),Y
:set_var_loop
	C8		; INY		; save variable name
	B1 <bufl	; LDA (bufl),Y
	91 <vcurl	; STA (vcurl),Y
	C900		; CMP #0
	D0 ~set_var_loop ; BNE set_var_loop
			;
			; If we have extended the vtable, we must update the
			; end pointer vnext.
			;
	68		; PLA
	C900		; CMP #00
	F001		; BEQ +01
	60		; RTS
	C8		; INY
	98		; TYA		; update vnext
	18		; CLC
	65 <vnextl	; ADC vnextl
	85 <vnextl	; STA vnextl
	9002		; BCC +2
	E6 <vnexth		; INC 85
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

