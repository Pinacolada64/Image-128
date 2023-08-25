; saved as tests\bank-init.asm
; to load into monitor:
; l "bank init.obj",08,0b00
orig $0c00

varpnt	= $49	; $49-$4a: pointer: current BASIC variable data

frnum	= $77d7	; get numeric expression from text
		; return result in FAC #1
chkcom	= $795c ; check for "," in text, stops with "?syntax error" if not found
getpos	= $7aaf	; return pointer to variable table
		; < .a & $49, > .y & $4a
getbyt	= $87f4 ; get 8-bit value
		; return in .x
adrbyt	= $8803 ; execute adrbyt, chkcom, getbyt.
		; return .x: 8-bit value. 16-bit value: < $16, > $17
getadr	= $880f ; execute chkcom, frnum, and adrfor in order.
		; returns
adrfor	= $8815 ; convert floating point number into 16-bit value.
		; returns < .y & $16, > .a & $17

mmurcr	= $d506	; Memory Management Unit RAM Configuration Register

mmucr	= $ff00	; Memory Management Unit Configuration Register

init_common_ram:
	jmp jmp_init_common_ram	; $0b00
bank_0:
	jmp jmp_bank_0		; $0b03
bank_1:
	jmp jmp_bank_1		; $0b06

; from section 8.1

jmp_init_common_ram:	; $0b00 in example
	lda mmucr	; $ff00: mmu config register
	pha
	lda #$00
	sta mmucr	; $ff00: mmu config register
	lda mmurcr	; $d506: mmu ram config register
			; bits 1-0: 00 = 1k
			;           01 = 4k
			;           10 = 8k
			;           11 = 16k
			; bits 3-2: 01 = Common RAM at bottom
	ora #%00000110	; $06
	sta mmurcr	; $d506
	pla
	sta mmucr	; $ff00
	rts

jmp_bank_0:		; $0b16 in example
	php
	pha
	lda #$00
	sta mmucr	; $ff00
	pla
	plp
	rts

jmp_bank_1:		; $0b20 in example
	php
	pha
	lda #$7f
	sta mmucr	; $ff00
	pla
	plp
	rts
