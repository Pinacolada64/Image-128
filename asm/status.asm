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
	rts

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
	ldy #0
rsrx1:
	lda sdisp+2,y
	sta sdisp+1,y
	iny
	cpy #9
	bcc rsrx1
	lda ptr1	; c64: $9e
	sta sdisp+10
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
