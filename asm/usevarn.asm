; usevarn.asm -- &,73: usevar, a number variable as text (resident,
; ml.res2: varbl.asm's part, ml.res1, had 52 bytes left)

;* get variable descriptor; a number variable's as text (&,73)
; 11/27/2026: Image 3.0's &,9 fix (swap2.s btmnum, ml.s intfout and
; numdesc), here in one place, so swap2's btmvar (&,9) reaches it through
; jmptbl (swap2 has 28 bytes to spare): usevar left a number's 5 bytes in
; varbuf, and btmvar showed them as if a string's descriptor (garbage in
; the window). The name's 2 bytes are just before the value (bank 1,
; which cfg_ml maps in): bit 7 set in both = integer, in the second
; only = string (left as usevar got it), in neither = floating point.
; A number goes through FOUT to text at $0100, and varbuf becomes a
; descriptor for that text without its leading space
usevarn:
	jsr usevar
	lda varpnt
	sec
	sbc #2
	sta index_24
	lda varpnt+1
	sbc #0
	sta index_24+1
	ldy #1
	lda (index_24),y
	bpl usevarn1	; floating point
	dey
	lda (index_24),y
	bpl usevarn4	; a string
	lda var		; an integer: high byte, low byte
	ldy var+1
	jsr givayf	; c64: $b391
	jmp usevarn2
; floating point: unpack it in the FAC (varbuf is FAC1): the sign is bit 7
; of the first mantissa byte, where the 1 the packed form leaves out goes
usevarn1:
	lda var+1
	sta facsgn
	ora #$80
	sta var+1
usevarn2:
	jsr fout	; c64: $bddd
	ldx #0
	lda $0100
	cmp #' '
	bne usevarn3
	inx
usevarn3:
	stx var+1
	lda #>$0100
	sta var+2
usevarn5:
	lda $0100,x
	beq usevarn6
	inx
	bne usevarn5
usevarn6:
	txa
	sec
	sbc var+1
	sta var
usevarn4:
	rts
