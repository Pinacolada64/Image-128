; lbar2.asm -- 80 columns: the lightbar's next page beside it (11/07/2026)
;
; On the 80-column screen the lightbar row (16) shows two pages, in pairs:
; 1-2, 3-4, 5-6, 7-8 (user's request, 11/07/2026). The page the cursor is
; on is irq7's, on the VIC row; the other page of its pair is drawn here
; (lbar2/lbar2c, equates.asm). vdcsrow copies the VIC row to the VDC's
; columns 0-39 and puts the other page in 40-79 (lbar2_put); when the
; cursor is on the pair's second page, lbar2_put swaps them: the other
; page in 0-39, the VIC row's in 40-79. In the low memory after the &
; jump table (jmptbl, $1a00), not $e000-$fbff, which is full; every
; configuration sees it (the shared RAM below $4000).

; 11/07/2026: the other page of the cursor's pair (page xor 1) drawn as
; above, but into lbar2/lbar2c, which vdcsrow puts in the VDC's row 16,
; columns 40-79: two pages side by side in 80 columns. No position on it is
; highlighted (tmpbar $ff): the cursor is on this page. Then vdcst_force: a
; change to the next page's checkmarks alone doesn't change the VIC row,
; which vdcstat's checksums look at
irq7n:
	bit mode
	bpl irq7n9	; 40 columns: nothing
	lda #$ff
	sta tmpbar
	lda bar
	and #8
	sta lbar2_side	; not 0: the cursor's page is the pair's second
	lda bar
	and #$38
	eor #8		; the other page of the pair * 8
	sta irq7n1+1
	asl
	clc
irq7n1:
; self modifying code changes this
	adc #0		; * 24: its labels in bartbl
	tay
	lda irq7n1+1
	lsr
	lsr
	tax		; * 2: its checkmarks in chktbl
	lda #<lbar2
	sta irq7f1+1
	lda #>lbar2
	sta irq7f1+2
	lda #<lbar2c
	sta irq7g1+1
	lda #>lbar2c
	sta irq7g1+2
	lda chktbl+1,x
	pha
	lda chktbl+0,x
	ldx #0
irq7n2:
	jsr irq7h
	cpx #20
	bcc irq7n2
	pla
irq7n3:
	jsr irq7h
	cpx #40
	bcc irq7n3
	lda #<ldisp
	sta irq7f1+1
	lda #>ldisp
	sta irq7f1+2
	lda #<lcolr
	sta irq7g1+1
	lda #>lcolr
	sta irq7g1+2
	lda #1
	sta vdcst_force
irq7n9:
	rts

; vdcsrow, row 16: after its 40 characters, the next page's 40 (lbar2_put),
; and after its 40 attributes, theirs (lbar2_putc). Nothing for another
; row, or before irq7n has drawn the page (lbar2's first byte still 0, as
; ml.low loads it)
; When the cursor is on the pair's second page (lbar2_side), the row starts
; again at column 0 with the other page, then the VIC row's 40 (at the
; address vdcsrow's own loops read, vdcs_d1/vdcs_d2's operands)
lbar2_put:
	jsr lbar2_ok
	bcc lbar2_9
	lda lbar2_side
	beq lbar2_0
	lda vdcr_scr+1	; back to column 0
	ldy vdcr_scr
	jsr vdc_set_update
lbar2_0:
	ldy #0
lbar2_1:
	lda lbar2,y
	jsr vdc_put
	iny
	cpy #40
	bcc lbar2_1
	lda lbar2_side
	beq lbar2_9
	lda vdcs_d1+1	; then the VIC row
	sta lbar2_3+1
	lda vdcs_d1+2
	sta lbar2_3+2
	ldy #0
lbar2_3:
; self-modifying code changes this
	lda $ffff,y
	jsr vdc_put
	iny
	cpy #40
	bcc lbar2_3
lbar2_9:
	rts
lbar2_putc:
	jsr lbar2_ok
	bcc lbar2_9
	lda lbar2_side
	beq lbar2_4
	lda vdcr_atr+1	; back to column 0
	ldy vdcr_atr
	jsr vdc_set_update
lbar2_4:
	lda #<lbar2c
	sta lbar2_5+1
	lda #>lbar2c
	sta lbar2_5+2
	jsr lbar2_c40
	lda lbar2_side
	beq lbar2_9
	lda vdcs_d2+1	; then the VIC row's colors
	sta lbar2_5+1
	lda vdcs_d2+2
	sta lbar2_5+2
; 40 VIC colors (at lbar2_5's operand) as VDC attributes
lbar2_c40:
	ldy #0
lbar2_5:
; self-modifying code changes this
	lda $ffff,y
	and #$0f
	tax
	lda vdccolor,x
	ora vdcs_alt
	jsr vdc_put
	iny
	cpy #40
	bcc lbar2_5
	rts
lbar2_side:	byte 0
; carry set: row 16, and the page drawn
lbar2_ok:
	lda vdcs_row
	cmp #16
	bne lbar2_8
	lda lbar2
	beq lbar2_8
	sec
	rts
lbar2_8:
	clc
	rts

; vdcsrow's checksum step (Fletcher: a += byte, b += a), moved here from
; shdlr.asm to make room in $e000-$fbff for the calls above
vdcsum:
	clc
	adc vdcs_a
	sta vdcs_a
	clc
	adc vdcs_b
	sta vdcs_b
	rts

; &,72's entry (jmptb.asm; 11/08/2026): row+32 copies the whole VIC row
; (columns 0-39, characters) to the same row of the VDC, in 80 columns;
; nothing in 40. Any other &,72 goes on to vdccell (vdc.asm). Here, not in
; vdccell: $e000-$fbff has no room. ++ copier writes each block it reads
; to VIC rows 2-8 (from $0450) and calls this for each of those rows, so
; the bytes stream by on either screen
vdccellx:
	txa
	and #$20
	bne vdcrw0
	jmp vdccell
vdcrw0:
	bit mode
	bpl vdcrw9
	txa
	and #$1f
	sta vdcrw_r
	tax
	jsr vdcrowd	; vdcr_scr: the VDC row's address
	lda vdcr_scr+1
	ldy vdcr_scr
	jsr vdc_set_update
	ldx vdcrw_r
	jsr calcscn2	; the VIC row's: .y low, .a high
	sty vdcrw2+1
	sta vdcrw2+2
	ldy #0
vdcrw2:
; self-modifying code changes this
	lda $ffff,y
	jsr vdc_put
	iny
	cpy #40
	bcc vdcrw2
vdcrw9:
	rts
vdcrw_r:	byte 0
