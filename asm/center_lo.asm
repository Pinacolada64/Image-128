; center_lo.asm -- the rest of center.asm (11/20/2026): cdigits (&,15,7's
; integer width) and mtab (the MCI tab's body), at $3581-$35ff, the 127
; bytes free between the screen save buffers (tempcol, to $3580) and glue
; ($3600): the shared area below $4000 had no room for all of center.asm.
; ml.low (split-ml.py: wedgemem to $4000) loads it.

; the width cnum prints for the integer in varbuf (high), varbuf+1 (low):
; its digits, a minus sign, at least cdig
cdigits:
	lda #0
	sta ctmp	; the sign's width (center.asm's ctmp: free here)
	lda varbuf
	bpl cdg1
	inc ctmp	; the minus sign
	lda #0
	sec
	sbc varbuf+1
	sta varbuf+1
	lda #0
	sbc varbuf
	sta varbuf
cdg1:
	ldx #0
cdg2:
	cpx #4
	beq cdg3
	lda varbuf+1
	cmp ctenl,x
	lda varbuf
	sbc ctenh,x
	bcc cdg3	; under 10, 100, 1000, 10000
	inx
	bne cdg2
cdg3:
	inx		; the digits
	txa
	clc
	adc ctmp
	cmp cdig
	bcs cdg4
	lda cdig
cdg4:
	rts
ctenl:
	byte <10,<100,<1000,<10000
ctenh:
	byte >10,>100,>1000,>10000


; ********************************
; *  mtab: the MCI tab           *
; ********************************
; pound, back arrow, nn: spaces to column nn (mval), from mcicm.asm's ctab,
; which has stepped past the second digit. The column is the caller's
; (modclm, which outmdm keeps, up to modclmn - 1: akfix keeps modclmn at
; ll%) when the modem gets output (local 0, also at a console login), the
; screen's (scnpos, up to rmargin) at the idle screen (local 1). It was
; always the screen's, so a 40-column console stopped an 80-column caller's
; tab at 39. Nothing when the column is there already or past it, or nn is
; past the last column
mtab:
	jsr mtabcol	; .a: the column now, .y: the last column
	cmp mval
	bcs mtab9	; there, or past it
	cpy mval
	bcc mtab9	; nn past the last column
	eor #$ff	; mval - the column: the spaces, counted once (output's
	sec		; word wrap holds characters back, so the caller's column
	adc mval	; doesn't move with each one)
	sta ctmp	; center.asm's ctmp, free outside &,15,7
mtab1:
	lda #' '
	sta $fe
	jsr output
	dec ctmp
	bne mtab1
mtab9:
	rts
mtabcol:
	ldy local
	bne mtabc1
	ldy modclmn
	dey
	lda modclm
	rts
mtabc1:
	ldy rmargin
	lda scnpos
	rts
