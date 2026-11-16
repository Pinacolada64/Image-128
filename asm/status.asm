; status.asm -- the status line's indicators (row 24), 11/16/2026.
;
; Each indicator (equates.asm: stat_abt ... stat_car) is turned on or off
; through draw_status_line ($199f): .a = its index, .x = 0 off, non-zero
; on. It keeps .a .x .y, and uses only the registers and the stack, so the
; IRQ (the carrier) and the SwiftLink's NMI (overrun, flow control) can
; call it while the main line is in it too.
;
; 40 columns: each indicator has a cell of row 24 (stat_col40) and a
; reversed letter (stat_chr40). Several share a cell (30: A, P, L; 31: G,
; S, L; 32: F, I): it shows the lowest-index one that's on, or a reverse
; space. 30 and 31 are the main line's alone; at 32 the NMI's F can come
; between the main line's look at the cell and its store, leaving I or a
; space showing while F is on, until either changes again (user,
; 11/16/2026: I moved from 33 to 32, so time left has a space before it).
;
; 80 columns: the VIC's cells stay blank (the left half is the date, time
; and time left). The VDC can't be written from an interrupt (select a
; register, then write it), so stat_vdc, from vdcstat on the main line,
; draws each indicator whose state changed: its three-letter label
; (stat_lbl80) at row 24, column 40+4*idx, or three reverse spaces.
;
; Assembled after trace.asm in the shared bottom 16K: visible in every
; bank configuration, the NMI's and the IRQ's included.

draw_status_line0:
	php
	pha		; the index
	txa
	pha		; on/off
	tya
	pha
	tsx		; $0101,x = .y, $0102,x = on/off, $0103,x = the index
	lda $0103,x
	tay
	lda $0102,x
	beq dsl1
	lda #1
dsl1:
	cmp stat_on,y
	beq dsl9	; no change (the NMI's Flo comes every byte, the
	sta stat_on,y	; IRQ's Car every pass): nothing to draw
	bit mode
	bmi dsl9	; 80 columns: stat_vdc draws the label
	ldx stat_col40,y	; the indicator's cell
	ldy #0
dsl2:
	txa
	cmp stat_col40,y
	bne dsl3
	lda stat_on,y
	bne dsl4	; the lowest index that's on in this cell
dsl3:
	iny
	cpy #stat_count
	bcc dsl2
	lda #$a0	; none: a reverse space
	bne dsl5
dsl4:
	lda stat_chr40,y
dsl5:
	sta tdisp,x
dsl9:
	pla
	tay
	pla
	tax
	pla
	plp
	rts

; 80 columns, from vdcstat (the main line): each indicator whose state
; changed since it was drawn
stat_vdc:
	ldy #stat_count-1
stv1:
	lda stat_on,y
	cmp stat_shown,y
	beq stv2
	sta stat_shown,y
	jsr stat_vdc1
stv2:
	dey
	bpl stv1
	jmp r80_vdc	; then rows 20, 21 and 23's right halves

; indicator .y (.a: 0 off, 1 on) at row 24, column 40+4*.y. Keeps .y.
stat_vdc1:
	sty stat_y
	sta stat_onv
	tya
	asl
	asl		; (clears the carry: .y < 64)
	adc #<$07a8	; row 24, column 40: 24*80+40
	tay
	lda #>$07a8
	clc
	adc vdcscrn
	jsr vdc_set_update	; .a = high byte, .y = low
	lda stat_y
	asl
	adc stat_y	; .y * 3: the label
	tay
	lda #3
	sta stat_n
stv3:
	lda #$a0	; off: a reverse space
	ldx stat_onv
	beq stv4
	lda stat_lbl80,y
stv4:
	jsr vdc_put
	iny
	dec stat_n
	bne stv3
	ldy stat_y
	rts

; intro's setup, at boot: every indicator off, each 40-column cell blank
stat_init:
	ldy #stat_count-1
sti1:
	lda #0
	sta stat_on,y
	sta stat_shown,y
	ldx stat_col40,y
	lda #$a0
	sta tdisp,x
	dey
	bpl sti1
	rts

; logoff (setup.asm): indicators 0-7 off, the overrun's O too (it stays
; on until then); Int and Car follow the hardware
stat_clear:
	ldx #0
	lda #stat_flo
stc1:
	jsr draw_status_line0
	sec
	sbc #1
	bpl stc1
	rts

; row 23's transmit (rs_txwin) and receive (rs_rxwin) windows, from the
; RS-232 drivers' rsout and rsget (each driver had its own copy; moved
; here 11/16/2026 for their room): while the mask is on and the
; lightbar's check 61 (enable RX/TX windows) is, the window scrolls one to
; the left and the byte in ptr1 goes in at its right. .a .y lost, .x kept.
rs_txwin0:
	jsr rswin_on
	beq rswin9
	bit mode
	bmi r80_tx	; 80 columns: 38 wide, on the right half
	ldy #0
rstx1:
	lda sdisp+30,y
	sta sdisp+29,y
	iny
	cpy #9
	bcc rstx1
	lda ptr1	; c64: $9e
	sta sdisp+38
rswin9:
	rts
rs_rxwin0:
	jsr rswin_on
	beq rswin9
	ldy #9		; 40 columns: 10 wide (1-10)
	bit mode
	bpl rsrx0
	ldy #37		; 80 columns: 38 wide (1-38), the VIC row vdcstat copies
rsrx0:
	sty rsrx2+1
	ldy #0
rsrx1:
	lda sdisp+2,y
	sta sdisp+1,y
	iny
rsrx2:
	cpy #9		; (set above)
	bcc rsrx1
	lda ptr1	; c64: $9e
	sta sdisp+1,y	; the right end: 10 or 38
	rts
; .a non-zero (Z clear) when the windows show
rswin_on:
	lda scnmode
	bne rswin_no
	lda flag_dsr_addr
	and #flag_dsr_r_mask
	rts
rswin_no:
	lda #0
	rts

; ----------------------------------------------------------------------
; 80 columns: the right halves (columns 40-79) of rows 22, 19 and 23, kept
; here (r80_text, 40 bytes a row) and drawn on the VDC by r80_vdc, from
; vdcstat on the main line, when a row changed (r80_dirty) or the mask
; came on (vdcst_force): the VIC screen has no columns past 39, and the
; VDC can't be written from an interrupt. 11/16/2026 (user's layout):
;   row 22  the C= N= bar on to column 79: L= the BASIC line (trace), M=
;           the last module loaded (the wedge's openroom: modname, up to
;           16 characters), and "Image BBS 128" at 67-79; P= program space and V= variable
;           space are at 24-39, on the VIC's half (sub.display draws
;           "P=----- V=----- " there; trace80 the digits)
;   row 19  Buf: bytes waiting in the RS-232 receive buffer
;   row 23  the transmit window, 38 wide (the receive window is the VIC's
;           columns 1-38, which vdcstat copies), then T
; Row 19 is the system box's third (sub.display draws 17-18 and blanks
; 20-21). A cell's color: columns 40 and 79 r80_edge's; the others
; r80_rev's when reversed (labels), r80_mid's when not (values).

r80_tx:		; rs_txwin in 80 columns: row 23, columns 41-78
	ldy #0
r80tx1:
	lda r80_text+82,y
	sta r80_text+81,y
	iny
	cpy #37
	bcc r80tx1
	lda ptr1	; c64: $9e
	sta r80_text+118
	lda #1
	sta r80_dirty+2
	rts

; from stat_vdc (vdcstat, 80 columns): Buf and the module, then any row
; that changed, while the mask is on
r80_vdc:
	lda scnmode
	bne r80v9	; mask off: rows 20-23 are the console's
	jsr r80_buf
	jsr r80_mod
	jsr r80_btm
	ldx #2
r80v1:
	lda vdcst_force
	bne r80v2
	lda r80_dirty,x
	beq r80v3
r80v2:
	lda #0
	sta r80_dirty,x
	stx r80_i
	jsr r80_row
	ldx r80_i
r80v3:
	dex
	bpl r80v1
r80v9:
	rts

; draw row r80_i's right half: its 40 characters, then their attributes
; (colors as above; the lowercase set)
r80_row:
	ldy r80_rows,x
	lda vdcrowlo,y
	clc
	adc #40
	sta r80_lo
	lda vdcrowhi,y
	adc #0
	sta r80_hi
	clc
	adc vdcscrn
	ldy r80_lo
	jsr vdc_set_update
	ldx r80_i
	ldy r80_off,x
	sty r80_o
	lda #40
	sta r80_n
r80r1:
	lda r80_text,y
	jsr vdc_put
	iny
	dec r80_n
	bne r80r1
	lda r80_hi
	clc
	adc vdcattr
	ldy r80_lo
	jsr vdc_set_update
	ldy #0
r80r2:
	ldx r80_i
	lda r80_edge,x
	cpy #0
	beq r80r4
	cpy #39
	beq r80r4
	tya
	clc
	adc r80_o
	tax
	lda r80_text,x
	ldx r80_i
	asl		; reversed? (bit 7)
	lda r80_mid,x
	bcc r80r4
	lda r80_rev,x
r80r4:
	and #$0f
	tax
	lda vdccolor,x
	ora #VDC_ATTR_ALT
	jsr vdc_put
	iny
	cpy #40
	bcc r80r2
	rts

; Buf: (ridbe - ridbs) and 127, three digits at row 19, columns 48-50
r80_buf:
	lda ridbe
	sec
	sbc ridbs
	and #127
	cmp r80_bufn
	beq r80b9
	sta r80_bufn
	ldx #0
	jsr decimal	; decchr: five ASCII digits
	ldx #2
r80b1:
	lda decchr+2,x	; (plain: a value)
	sta r80_text+40+8,x
	dex
	bpl r80b1
	lda #1
	sta r80_dirty+1
r80b9:
	rts

; M=: when the wedge loaded one (modnew), its name (modname, modlen
; characters, up to 16) at row 22, columns 50-65, reversed
r80_mod:
	lda modnew
	beq r80m9
	lda #0
	sta modnew
	ldx #0		; skip a drive prefix ("0:"): from past a ':' in
	ldy #0		; the first three characters
r80m0:
	cpy modlen
	bcs r80m0b
	lda modname,y
	iny
	cmp #':'
	bne r80m0a
	tya
	tax		; the name starts after it
r80m0a:
	cpy #3
	bcc r80m0
r80m0b:
	stx r80_skip
	ldy #0
r80m1:
	tya
	clc
	adc r80_skip
	tax
	lda #$a0	; past the name: reverse spaces
	cpx modlen
	bcs r80m3
	lda modname,x	; PETSCII to the lowercase set's screen codes
	cmp #$c0
	bcc r80m2
	sbc #$80	; $c1-$da (capitals) to $41-$5a
	bne r80m2a
r80m2:
	cmp #$40
	bcc r80m2a
	sbc #$40	; $41-$5a (lowercase) to $01-$1a
r80m2a:
	ora #$80
r80m3:
	sta r80_text+10,y
	iny
	cpy #16
	bcc r80m1
	lda #1
	sta r80_dirty
r80m9:
	rts

; &,9's window (btmvar wrote btmwin): row 22, columns 64-79
r80_btm:
	lda btmnew
	beq r80bt9
	lda #0
	sta btmnew
	ldy #15
r80bt1:
	lda btmwin,y
	sta r80_text+24,y
	dey
	bpl r80bt1
	lda #1
	sta r80_dirty
r80bt9:
	rts

; trace2 in 80 columns: P, V and L on row 22 (all three always; the
; lightbar's Dbg changes nothing here): P and V on the VIC's half (columns
; 26-30, 34-38), L in r80_text (42-46). L follows the line while the trace
; (Trc left, check 24) is on, and is drawn once at the start. When
; sub.display drew the mask again its "P=-----" is there: forget P and V,
; so both are drawn at once, and put "Image BBS 128" back in &,9's window
; (as 40 columns' mask does; an &,9 after the mask still wins: r80_btm
; runs after this, from vdcstat).
row22	= $0400 + (40*22)	; the VIC's row 22
trace80:
	lda row22+26
	cmp #$ad	; a reversed '-'
	bne t80p
	lda #$ff
	sta oldprg+1
	sta oldmem+1
	ldy #15
t80v1:
	lda r80_ver,y
	sta r80_text+24,y
	dey
	bpl t80v1
	lda #1
	sta r80_dirty
t80p:
	sec
	lda maxmem0
	sbc txtend
	tay
	lda maxmem0+1
	sbc txtend+1
	tax
	cpy oldprg
	bne t80a
	cpx oldprg+1
	beq t80b
t80a:
	sty oldprg
	stx oldprg+1
	tya
	ldy #26		; P's digits: row 22, columns 26-30 (VIC)
	jsr t80num
t80b:
	sec
	lda fretop
	sbc strend
	tay
	lda fretop+1
	sbc strend+1
	tax
	cpy oldmem
	bne t80c
	cpx oldmem+1
	beq t80d
t80c:
	sty oldmem
	stx oldmem+1
	tya
	ldy #34		; V's: 34-38 (VIC)
	jsr t80num
t80d:
	lda t80_first
	bne t80e
	lda flag_trc_addr
	and #flag_trc_l_mask
	beq t80f
t80e:
	lda curlin	; c64: 57
	ldx curlin+1	; c64: 58
	cmp oldline
	bne t80g
	cpx oldline+1
	beq t80f
t80g:
	sta oldline
	stx oldline+1
	ldy #42		; L's: 42-46 (r80_text)
	jsr t80num
	lda #0
	sta t80_first
	jmp trace5p	; trace2's Ctrl-key pause, while the trace is on
t80f:
	rts

; .a/.x in decimal, five reversed digits on row 22 from column .y: the
; VIC's row below 40, r80_text's from 40
t80num:
	sty t80_cell
	jsr decimal
	ldy t80_cell
	ldx #0
t80n1:
	lda decchr,x
	ora #$80
	cpy #40
	bcs t80n2
	sta row22,y
	bcc t80n3	; (always)
t80n2:
	sta r80_text-40,y
t80n3:
	iny
	inx
	cpx #5
	bcc t80n1
	lda #1
	sta r80_dirty
	rts

r80_rows:	byte 22,19,23
r80_off:	byte 0,40,80
r80_edge:	byte 1,12,1	; colors: columns 40 and 79
r80_mid:	byte 1,12,3	; 41-78, plain cells: values (the window's cyan)
r80_rev:	byte 1,15,3	; 41-78, reversed: row 22's white bar, the box's
			; light gray labels, the window
r80_dirty:	byte 1,1,1
r80_text:	; row 22: "L=00000 M=" name(16) " Image BBS 128", all reversed
	byte $cc,$bd,$b0,$b0,$b0,$b0,$b0,$a0,$cd,$bd
	byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	byte $a0,$a0,$a0,$a0,$a0,$a0,$a0,$c9,$8d,$81
	byte $87,$85,$a0,$c2,$c2,$d3,$a0,$b1,$b2,$b8
		; row 19: [Buf   ] 000/127 ([] reversed)
	byte $20,$c2,$95,$86,$a0,$a0,$a0,$20,$30,$30
	byte $30,$2f,$31,$32,$37,$20,$20,$20,$20,$20
	byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
		; row 23: a reverse space, the transmit window, T
	byte $a0,$20,$20,$20,$20,$20,$20,$20,$20,$20
	byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$d4
r80_ver:	; &,9's window's own text, as the 40-column mask's
	byte $a0,$a0,$a0,$c9,$8d,$81,$87,$85
	byte $a0,$c2,$c2,$d3,$a0,$b1,$b2,$b8
r80_bufn:	byte $ff
t80_first:	byte 1
r80_i:		byte 0
r80_lo:		byte 0
r80_hi:		byte 0
r80_n:		byte 0
t80_cell:	byte 0
r80_skip:	byte 0
r80_o:		byte 0

; by index: Abt Pau Dsk GC Swp Lck Ovr Flo Int Car
stat_col40:
	byte 30,30,30,31,31,31,29,32,32,39	; (I at 32 with F: a space before time left)
stat_chr40:	; A P L G S L O F I, and a check
	byte $c1,$d0,$cc,$c7,$d3,$cc,$cf,$c6,$c9,$fa
; screen codes, reversed, in the lowercase set the status rows use
stat_lbl80:
	byte $c1,$82,$94	; Abt
	byte $d0,$81,$95	; Pau
	byte $c4,$93,$8b	; Dsk
	byte $c7,$c3,$a0	; GC
	byte $d3,$97,$90	; Swp
	byte $cc,$83,$8b	; Lck
	byte $cf,$96,$92	; Ovr
	byte $c6,$8c,$8f	; Flo
	byte $c9,$8e,$94	; Int
	byte $c3,$81,$92	; Car
stat_on:	; 0 off, 1 on
	byte 0,0,0,0,0,0,0,0,0,0
stat_shown:	; 80 columns: as stat_vdc last drew them
	byte 0,0,0,0,0,0,0,0,0,0
stat_y:		byte 0
stat_onv:	byte 0
stat_n:		byte 0
