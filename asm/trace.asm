; trace.asm -- the screen mask's numbers on row 23 (11/15/2026)
;
; trace0 (shdlr.asm) calls trace2 between BASIC statements while the mask
; is on, in cfg_ml. Here, in the shared bottom 16K after glue.asm, not in
; shdlr.asm: $e000-$fbff has no room (lbar2.asm), and nothing here needs
; more than cfg_ml's view of memory.
;
; Row 23 has two number cells, "x=00000" at sdisp+12 and sdisp+21
; (sub.display.lbl draws "R           V=00000  L=00000           T"):
;
;	lightbar Em3 right (check 49) off:  V=00000  L=00000
;	lightbar Em3 right (check 49) on:   P=00000  V=00000
;
; V, variable space: fretop - strend, bank 1's free room between the
;    arrays and the strings (c64's M=, lda 51 / sbc 49 ..., which there
;    was all of free memory; the 128's pointers are two bytes on)
; P, program space: maxmem0 - txtend ($1212 - $1210), bank 0's room left
;    for BASIC text below textop; it goes down as modules load
; L, the BASIC line running (curlin), while the line trace (lightbar Trc
;    left, check 24) is on
;
; Each number is drawn only when it changes (oldmem, oldprg, oldline).
; The cell letters are checked against Em3's right each time: when they don't
; match (Em3's right changed, or sub.display drew the mask again) both letters
; are written and every number is forgotten, so each cell is drawn at
; once; the L cell then shows the line running even with the trace off,
; rather than keeping V's digits.
;
; In 80 columns vdcstat copies the VIC's row 23 to the VDC, so this shows
; there too (modules/TODO.md: the VDC's own row 23 with P, V and L).

trace2:
	bit mode
	bpl trace2_40
	jmp trace80	; 80 columns: row 22's P V L (status.asm)
trace2_40:
	lda flag_em3_addr
	and #flag_em3_r_mask	; 0, or 2 with Em3's right on
	sta trcsw
	tax
	lda trcltr,x
	cmp sdisp+12
	beq trace2a
	sta sdisp+12
	lda trcltr+1,x
	sta sdisp+21
	lda #$ff		; no number's high byte: draw each again
	sta oldmem+1
	sta oldprg+1
	sta oldline+1
trace2a:
; P, in the first cell, with Em3's right on
	lda trcsw
	beq trace3
	sec
	lda maxmem0
	sbc txtend
	tay
	lda maxmem0+1
	sbc txtend+1
	tax
	cpy oldprg
	bne trace2b
	cpx oldprg+1
	beq trace3
trace2b:
	sty oldprg
	stx oldprg+1
	tya
	ldy #0
	jsr trcnum
; V: the first cell, or the second with Em3's right on
trace3:
	sec
	lda fretop
	sbc strend
	tay
	lda fretop+1
	sbc strend+1
	tax
	cpy oldmem
	bne trace3a
	cpx oldmem+1
	beq trace4
trace3a:
	sty oldmem
	stx oldmem+1
	ldy #0
	lda trcsw
	beq trace3b
	ldy #9
trace3b:
	lda oldmem
	jsr trcnum
; L, in the second cell, with Em3's right off: while the trace is on, or once
; after the cells were forgotten
trace4:
	lda trcsw
	bne trace7
	lda oldline+1
	cmp #$ff
	beq trace4a
	lda flag_trc_addr
	and #flag_trc_l_mask
	beq trace7
trace4a:
	lda curlin	; c64: 57
	ldx curlin+1	; c64: 58
	cmp oldline
	bne trace5
	cpx oldline+1
	beq trace7
trace5:
	sta oldline
	stx oldline+1
	ldy #9
	jsr trcnum
trace5p:
	lda flag_trc_addr
	and #flag_trc_l_mask
	beq trace7
	ldx #0
	ldy #200
trace6:
; pause trace with Ctrl key
	lda shflag	; c64: 653
	and #CONTROL_KEY; 4
	beq trace7
	dex
	bne trace6
	dey
	bne trace6
trace7:
	rts

; .a/.x (low, high) in decimal, five reversed digits in the cell .y says:
; 0, sdisp+14 (the first), or 9, sdisp+23 (the second)
trcnum:
	sty trccell
	jsr decimal	; shdlr.asm: decchr, .x and .y used
	lda trccell
	clc
	adc #4
	tay
	ldx #4
trcnum1:
	lda decchr,x
	ora #$80
	sta sdisp+14,y
	dey
	dex
	bpl trcnum1
	rts

; the cells' letters (reversed, the lowercase set the mask is in): Em3's right
; off, V and L; on, P and V (trcsw, 0 or 2, indexes them)
trcltr:
	byte $d6, $cc
	byte $d0, $d6

trcsw:
	byte 0
trccell:
	byte 0
oldline:
	word 0
oldmem:
	word 0
oldprg:
	word 0
