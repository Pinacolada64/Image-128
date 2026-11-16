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
; V, variable space: fretop - strend, bank 1's free room between the
;    arrays and the strings (c64's M=, lda 51 / sbc 49 ..., which there
;    was all of free memory; the 128's pointers are two bytes on)
; L, the BASIC line running (curlin), while the line trace (lightbar Trc
;    left, check 24) is on; Ctrl pauses it
;
; Each number is drawn only when it changes (oldmem, oldline).
;
; 80 columns show P= (program space) too, all on row 22: trace80, in
; status.asm. (11/15/2026 the lightbar's right Dbg swapped 40 columns' V=
; L= for P= V=; 11/16/2026 that went, Dbg being the border color on an
; event, im's line 23.)

trace2:
	bit mode
	bpl trace2_40
	jmp trace80	; 80 columns: row 22's P V L (status.asm)
trace2_40:
; V, variable space, in the first cell
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
	tya
	ldy #0
	jsr trcnum
; L, the line running, in the second, while the trace is on
trace4:
	lda flag_trc_addr
	and #flag_trc_l_mask
	beq trace7
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

trccell:
	byte 0
oldline:
	word 0
oldmem:
	word 0
oldprg:
	word 0
