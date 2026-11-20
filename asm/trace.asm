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
;	lightbar Prg right (check 49) off:  V=00000  L=00000
;	lightbar Prg right (check 49) on:   P=00000  V=00000
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
; The cell letters are checked against Prg's right each time: when they don't
; match (Prg's right changed, or sub.display drew the mask again) both letters
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
	lda flag_prg_addr
	and #flag_prg_r_mask	; 0, or 2 with Prg's right on
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
; P, in the first cell, with Prg's right on
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
; V: the first cell, or the second with Prg's right on
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
; L, in the second cell, with Prg's right off: while the trace is on, or once
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

; the cells' letters (reversed, the lowercase set the mask is in): Prg's right
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

; ********************************
; *  akfix: ak$ follows ll%       *
; ********************************
; 11/19/2026 (user's idea, modules/TODO.md): ak$, the separator line (pound-vj in & output:
; a space, ll%-2 midlines, Image's return ($8b), ll% characters in all), was
; built by BASIC loops (i.lo 3594, i/lo.on 4102, sub.param1 60606) that each
; place changing ll% had to remember, and some didn't: an 80-column logon's
; "PRIME TIME" lines kept the width ll% had at i/lo.on 4102. Now, between
; statements (from trace0, after anfix's strfix, where makeroom's garbage
; collection can't upset anything), when ll% is 3-80 and ak$ isn't that
; long, ak$ is rebuilt here, as strfix builds a string: makeroom, fill it,
; putvar. ak$'s own length is the check, not a remembered width, so an ak$
; BASIC set some other way (im 3062 at boot, from sw) is put right too.
; ll% has no index in vars (varbl.asm is full): setptrs (intro.asm) puts its
; place in lloff; 0 until then (before boot's setptrs), and akfix does nothing.
; ll% is read through akll1/akll2's operands, set each time, not $fb/$fc.
; Ends with trace0's old jmp vdcstat.
; 11/20/2026: also modclmn (the caller's width, which outmdm's wrap and the
; MCI tab use) is kept at ll%: BASIC poked it beside some ll% changes only
akfix:
	jsr llget
	bcs akfix9	; ll% not found yet, or not 3-80
	sta akw
	sta modclmn
	ldx #var_ak_string
	jsr usevar	; varbuf: ak$'s descriptor (its length first)
	lda varbuf
	cmp akw
	beq akfix9	; ll% wide already
	lda akw
	jsr makeroom	; .a bytes, marked garbage until putvar: varbuf
	ldy akw
	dey
	lda #$8b	; Image's return (quoters.lbl's f6), last
	sta (varbuf+1),y
	lda #$c0	; the midlines
akfix1:
	dey
	beq akfix2
	sta (varbuf+1),y
	bne akfix1	; always: .y isn't 0
akfix2:
	lda #$20	; a space, first
	sta (varbuf+1),y
	ldx #var_ak_string
	jsr putvar	; ak$ is it now; the old one is garbage
akfix9:
	jmp vdcstat

; llget: ll% in .a, carry clear when it is 3-80 (akfix; center.asm's
; &,15,7). Carry set: not found yet (lloff 0, before boot's setptrs), over
; 255, or out of range
llget:
	lda lloff
	ora lloff+1
	beq llget9
	clc
	lda vartab
	adc lloff
	sta akll1+1
	sta akll2+1
	lda vartab+1
	adc lloff+1
	sta akll1+2
	sta akll2+2
	ldx #0
akll1:
	lda $ffff,x	; ll%'s high byte (bank 1: cfg_ml sees it)
	bne llget9	; over 255
	inx
akll2:
	lda $ffff,x	; ll%'s low byte: the width
	cmp #3
	bcc llget9	; 0 before a logon, or too narrow for " ", a midline and the return
	cmp #81
	bcs llget9
	clc
	rts
llget9:
	sec
	rts

lloff:
	word 0	; ll%'s place: varpnt - vartab (setptrs)
akw:
	byte 0	; the width being built
