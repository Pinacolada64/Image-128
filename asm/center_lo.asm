; center_lo.asm -- at $3581-$35ff, the bytes free between the screen save
; buffers (tempcol, to $3580) and glue ($3600); ml.low loads it.
; 11/20/2026: center (&,15,7) and widest (&,15,8) here are farcall stubs:
; their code is under I/O at $d000 (center.asm, widest*.asm, ml.io), run in
; cfg_io. mtab stays here: it reads local (I/O) and prints.

center:
	jsr farcall
	byte cfg_io
	word centeri
	rts

widest:
	jsr farcall
	byte cfg_io
	word widesti
	rts

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
	sta mtabn
mtab1:
	lda #' '
	sta $fe
	jsr output
	dec mtabn
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
mtabn:
	byte 0	; the spaces left
