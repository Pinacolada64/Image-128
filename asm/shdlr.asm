outscn:

outscn0:
	lda #0
	sta idlejif
	tax
	tay
	jsr dspidle
scnoff:
	nop
	jsr chkblnk
	beq sc1
	jsr scrnon
sc1:
	jsr crsroff
	jsr cleanup
sc1a:
	lda sline
	cmp botline
	beq sc1b
	bcc sc1b
	jsr scroll
	jmp sc1a
sc1b:
	jsr sccrsr
	lda $fe
	and #127
	cmp #32
	bcs sc4
	lda $fe
	ldy #chrs_end - chrs - 1
sc2:
	cmp chrs,y
	beq sc6
	dey
	bpl sc2
	ldy #15
sc3:
	cmp colors,y
	beq sc9
	dey
	bne sc3
	jmp sccrsr
sc4:
	ldx scnpos
	cpx rmargin	; c64: cpx #39. the last column, 39 or 79
	bne sc5
	ldx sline
	cpx botline
	bne sc8
	jsr scroll
sc8:
	lda $fe
	jsr prtscn	; c64: $e716
	lda #0
	sta scnpos
; c64: lda #39 / sta $d5, the line length a linked line had stretched.
; The 128's $ee is the screen's last column, which the editor sets.
	jsr fixlink
	jmp sccrsr
sc5:
	lda $fe
	jmp prtscn	; c64: $e716
sc9:
	lda fredmode
	beq sc9a
	tay
sc9a:
	sty mcolor
	rts

sc6:
	tya
	asl
	tay
	lda chrtbl,y
	sta sc7+1
	lda chrtbl+1,y
	sta sc7+2
	lda $fe
sc7:
	jsr $ffff
	jmp sccrsr
scret:
	ldx #0
	stx mprint
	stx mspeed
	stx mdigits
	ldx #'0'
	stx cnumc
	jsr scdn
	ldx mleft
	beq scret0
scret1:
	lda #' '
	jsr prtscn	; c64: $e716
	dex
	bne scret1
scret0:
	rts
scupc:
	and #128
	asl
	rol
	sta mupcase
	rts

scclear:
	ldx #0
sccl1:
	jsr scline
	jsr fixlinks
	inx
	cpx #24
	bcc sccl1
schome:
	lda #0
	sta sline
	lda #0
	sta scnpos
sccrsr:
	ldx sline
sccrsr1:
	jsr he9f0
	jmp hea24
scrt:
	ldx scnpos
	cpx rmargin	; c64: cpx #39
	bne scrt1
scdn:
	ldx sline
	cpx botline
	bne scrt1
	pha
	jsr scroll
	pla
scrt1:
	jmp prtscn	; c64: $e716
scdel:

sclf:
	ldx scnpos
	bne scrt1
scup:
	ldx sline
	bne scrt1
	rts
scrvs:
	jmp prtscn	; c64: $e716
scbell:
	lda flag_bel_addr
	and #flag_bel_l_mask
	beq scbell1
	ldx #2
	ldy #0
	jsr sound
scbell1:
	rts

scroll:
	inc scnlock
	bit mode	; 80 columns?
	bmi scrollv	; yes: the VDC scrolls
	lda sal		; c64: $ac
	pha
	lda sal+1	; same: $ad
	pha
	lda eal	; c64: $ae
	pha
	lda eal+1	; same: \$af
	pha
	ldx #0
	jsr he9f0
	jsr hea24
scroll0:
	inx
	cpx #24
	beq scroll2
	jsr calcscn
	sty sal		; c64: $ac
	sta sal+1	; same: $ad
	jsr calccol
	sty eal		; c64: $ae
	sta eal+1	; same: \$af
	ldy #39
scroll1:
	lda (sal),y	; same: ($ac),y
	sta (pnt),y	; c64:  ($d1),y
	lda (eal),y	; same: ($ae),y
	sta (colptr),y	; c64:  ($f3),y
	dey
	bpl scroll1
	ldy sal		; same: $ac
	lda sal+1	; same: $ad
	sty pnt		; c64:  $d1
	sta pnt+1	; c64:  $d2
	ldy eal		; same: $ae
	lda eal+1	; same: $af
	sty colptr	; c64:  $f3
	sta colptr+1	; c64:  $f4
	jmp scroll0
scroll2:
	jsr scline0
	pla
	sta eal+1	; same: $af
	pla
	sta eal		; c64:  $ae
	pla
	sta sal+1	; same: $ad
	pla
	sta sal		; same: $ac
scroll3:
	dec sline
	jsr sccrsr
	dec scnlock
	rts

; scroll in 80 columns: rows 1-23 up a row, as above, but the VDC copies
; them itself (one block copy for the characters, one for the
; attributes), then row 23 is cleared. With the screen mask on, rows
; 16-23 are in vdcsave, so a row at a time (scrollm).
scrollv:
	lda scnmode
	beq scrollm
	lda vdcscrn
	jsr scrollv1
	lda vdcattr
	jsr scrollv1
	ldx #23
	jsr vdcline
	jmp scroll3
; .a: high byte of the screen or attribute base
scrollv1:
	sta vdc_dst+1
	sta vdc_src+1
	lda #0
	sta vdc_dst
	lda #VDC_COLS	; from row 1
	sta vdc_src
	lda vdcrowlo+23	; 23 rows
	sta vdc_count
	lda vdcrowhi+23
	sta vdc_count+1
	jmp vdc_copy

scrollm:
	ldx #0
scrollm1:
	stx vdcm_row
	jsr vdcrow	; destination: row .x
	jsr vdcmcopy
	inx
	jsr vdcrow	; source: row .x+1
	jsr vdcmswap
	jsr vdcmcpy1
	ldx vdcm_row
	inx
	cpx #23
	bcc scrollm1
	jsr vdcline	; row 23
	jmp scroll3

scline:
	bit mode	; 80 columns?
	bmi vdcline
	jsr he9f0
	jsr hea24
scline0:
	ldy #39
scline1:
	lda color	; c64:  646
	sta (colptr),y	; c64:  ($f3),y
	lda #32
	sta (pnt),y	; c64:  ($d1),y
	dey
	bpl scline1
	rts

; clear console row .x on the VDC (in vdcsave if the mask hides it):
; spaces, and attributes in the current color (the editor keeps a VDC
; attribute in color in 80 columns). Keeps .x (scclear counts rows in
; it). vdclinea: clear the row at vdcr_scr/vdcr_atr.
vdcline:
	stx vdcline_row
	jsr vdcrow
vdclinea:
	lda vdcr_scr
	sta vdc_dst
	lda vdcr_scr+1
	sta vdc_dst+1
	lda #' '
	jsr vdcline1
	lda vdcr_atr
	sta vdc_dst
	lda vdcr_atr+1
	sta vdc_dst+1
	lda color
	jsr vdcline1
	ldx vdcline_row
	rts
; fill a row at vdc_dst with .a
vdcline1:
	ldy #VDC_COLS
	sty vdc_count
	ldy #0
	sty vdc_count+1
	jmp vdc_fill
vdcline_row:
	byte 0

chrtbl:
	word scupc,scupc
	word scrvs,scrvs
	word schome,scclear
	word scrt,sclf
	word scdn,scup
	word scret,scdel
	word scbell
chrs:
	byte swlc, swuc
	byte reverse_on, reverse_off
	byte cursor_home, clear_screen
	byte cursor_right, cursor_left
	byte cursor_down, cursor_up
	byte carriage_return, cbm_backspace
	byte ascii_bel
chrs_end:

cleanup:
	; c64: lda #39 / sta $d5 (see sc8)
	lda #0
	sta qtsw	; c64: 212
	lda #0
	sta insrt	; c64: 216

fixlink:
	ldx sline
; make row .x the start of a logical line (unlink it from the row above).
; c64: lda 217,x / ora #128 / sta 217,x (the line link table). The 128's
; screen editor keeps a bitmap at $035e-$0361 instead: a set bit links the
; row to the one above; byte row/8, bit $80 >> (row & 7) (the editor's
; $cb9f, table at $ce6c). This used to "jsr $cb74", the editor's routine
; that only tests the bit -- and with the ROMs out, Image's own code.
fixlinks:
	txa
	pha
	lsr
	lsr
	lsr
	sta fixlinks_byte
	txa
	and #7
	tax
	lda fixlinks_bits,x
	eor #$ff
	ldx fixlinks_byte
	and ldtb2,x
	sta ldtb2,x
	pla
	tax
	rts
fixlinks_byte:
	byte 0
fixlinks_bits:
	byte $80,$40,$20,$10,$08,$04,$02,$01

botline:
	byte 22

poscrsr:
	txa
	pha
	tya
	pha
	pla
	tax
	pla
	tay
	clc
	jmp plot	; c64: jmp $fff0

;* output routine to fix 1200 and
;* do the transmit window

out0:
	sta ptr1	; c64: $9e
	txa
	pha
	tya
	pha
	jmp out3
outm:
	sta ptr1	; c64: $9e
	txa
	pha
	tya
	pha
	jmp out1
out:
	sta ptr1	; c64: $9e
	txa
	pha
	tya
	pha
	lda $9a
	cmp #4
	bcs out5
	cmp #2
	beq out1
	bcc out4
	ldx #1
	jsr setmode
	inc scnlock
	jsr crsroff
	lda ptr1	; c64: $9e
	jsr prtscn	; c64: $e716
	dec scnlock
	jmp out4
out1:

out3:
	lda ptr1	; c64: $9e
	jsr rsout
out4:
	pla
	tay
	pla
	tax
	lda ptr1	; c64: $9e
	clc
	rts
out5:
	pla
	tay
	pla
	tax
	lda ptr1	; c64: $9e
	jsr rsdisab
	jsr oldout
	jmp rsinabl

crsroff:
	lda #1
	sta crsrflg
	lda crsrmode
	beq crsroff1
	ldy #0
	sty crsrmode
	bit mode	; 80 columns: the VDC's cursor is hardware, nothing
	bmi crsroff1	; to put back (and pnt is a VDC address)
; put back the character and color under the cursor (c64: jsr $ea13)
	lda #2
	sta blnct
	ldy pntr
	lda undchr
	sta (pnt),y
	lda undcol
	sta (colptr),y
crsroff1:
	rts

crsron:
	lda sline
	cmp botline
	beq crsron0
	bcs crsron1
crsron0:
	lda #0
	sta crsrflg
	rts
crsron1:
	lda #1
	sta crsrflg
	rts

dispstr:
	stx dispstr0+1
	sty dispstr6+1
	jsr evalstr
	sta dispstr4+1
	stx dispstr1+1
	sty dispstr1+2
	jsr evalbyt
	stx dispstr5+1
	txa
	and #$80
	sta dispstr8+1
	inc scnlock
dispstr6:
	ldx #0
	beq dispstr7
	lda dispstr4+1
	beq dispstr7
	bit mode	; editor on the 80-column screen?
	bpl dispstr10
	cpx #16		; and a console row? Draw it on the VDC instead.
	bcc dispvdc	; Rows 16 and up are the status area, drawn on
dispstr10:		; the VIC screen as in 40 columns (vdcstat)
	jsr calcscn0
	sty dispstr2+1
	sta dispstr2+2
	jsr calccol0
	sty dispstr3+1
	sta dispstr3+2
dispstr0:
	ldx #0
	ldy #0
dispstr5:
	lda #1
dispstr3:
	sta $d800,x
dispstr1:
	lda $0100,y
	jsr chkspcl
	pha
	and #$7f
	cmp #32
	pla
	bcc dispstr9
	jsr convchr
dispstr8:
	ora #$80
dispstr2:
	sta $0400,x
	inx
dispstr9:
	iny
dispstr4:
	cpy #0
	bcc dispstr5
dispstr7:
	dec scnlock
	rts

; &,69 in 80 columns: X = row, column in dispstr0+1. The screen mask
; is VIC-only so far, so scnmode doesn't apply: every row is drawn
; straight to the VDC screen. Characters go out through R31 one after
; another (control codes skipped, as above), then one block fill sets
; the attributes of the ones drawn.
dispvdc:
	lda dispstr1+1	; string address
	sta dispvdc1+1
	lda dispstr1+2
	sta dispvdc1+2
	lda vdcrowlo,x	; vdc_dst = row * 80 + column
	clc
	adc dispstr0+1
	sta vdc_dst
	lda vdcrowhi,x
	adc #0
	sta vdc_dst+1
	adc vdcscrn	; carry clear: + screen base
	ldy vdc_dst
	jsr vdc_set_update
	ldy #0
	sty vdc_count
	sty vdc_count+1
dispvdc1:
	lda $0100,y
	jsr chkspcl
	pha
	and #$7f
	cmp #32
	pla
	bcc dispvdc2
	jsr convchr
	ora dispstr8+1	; reverse
	jsr vdc_put
	inc vdc_count
dispvdc2:
	iny
	cpy dispstr4+1
	bcc dispvdc1
	lda vdc_count
	beq dispvdc3	; nothing printable
	lda vdc_dst+1
	clc
	adc vdcattr	; attribute address of the first character
	sta vdc_dst+1
	lda dispstr5+1
	and #$0f
	tax
	lda color	; keep the editor's charset (ALT) bit
	and #VDC_ATTR_ALT
	ora vdccolor,x
	jsr vdc_fill
dispvdc3:
	jmp dispstr7

calcscn0:
	lda scnmode
	beq calcscn2
	bne calcscn1
calcscn:
	lda scnmode
	bne calcscn2
calcscn1:
	lda lobytes,x
	tay
	lda hibytes,x
	rts
; the 128 editor's 40-column screen has no line link table: row x is
; always at $0400 + x * 40
calcscn2:
	lda vicrowlo,x
	tay
	lda vicrowhi,x
	ora #$04
	rts

calccol0:
	lda scnmode
	beq calccol2
	bne calccol1
calccol:
	lda scnmode
	bne calccol2
calccol1:
	lda lobytec,x
	tay
	lda hibytec,x
	rts
calccol2:
	lda vicrowlo,x
	tay
	lda vicrowhi,x
	ora #$d8
	rts

; row * 40, rows 0-24
vicrowlo:
	byte $00,$28,$50,$78,$a0,$c8,$f0,$18,$40,$68,$90,$b8,$e0
	byte $08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0
vicrowhi:
	byte $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01
	byte $02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03

; point pnt and colptr at row .x, as the editor's own $c15e does: in 80
; columns, at the row in VDC screen and attribute memory, which is what
; the editor expects there (the screen mask is VIC-only)
he9f0:
	tya
	pha
	bit mode	; 80 columns?
	bmi he9f0v
	jsr calcscn
	sty pnt		; c64: $d1
	sta pnt+1	; c64: $d2
	pla
	tay
	rts
he9f0v:
	lda vdcrowlo,x
	sta pnt
	lda vdcrowhi,x
	ora vdcscrn
	sta pnt+1
	pla
	tay
	rts

hea24:
	tya
	pha
	bit mode	; 80 columns?
	bmi hea24v
	jsr calccol
	sty colptr	; c64: $f3
	sta colptr+1	; c64: $f4
	pla
	tay
	rts
hea24v:
	lda vdcrowlo,x
	sta colptr
	lda vdcrowhi,x
	ora vdcattr
	sta colptr+1
	pla
	tay
	rts

; toggle full screen
setmode:
	cpx scnmode
	beq setmode1
	rts
setmode1:
	txa
	ldx #15
	eor #1
	beq setmode2
	ldx #23
setmode2:
	sta scnmode
	stx botline
	jsr crsroff

; swap the VIC screen's rows 16-23 with tempscn, as the C64 does (in 80
; columns the VIC rows hold only the status area, which vdcstat copies
; to the VDC; vdcmask does the console's side there)
swapscn:
	lda curptr	; c64: $d1
	pha
	lda curptr+1	; c64: $d2
	pha
	lda colptr	; c64: $f3
	pha
	lda colptr+1	; c64: $f4
	pha
	lda sal		; c64: $ac
	pha
	lda sal+1	; same: $ad
	pha
	lda eal		; c64: $ae
	pha
	lda eal+1	; same: \$af
	pha
	lda scnmode
	pha
	ldx #0
swapscn1:
	jsr calcscn	; c64: jsr $e9f0 / jsr $ea24 (he9f0/hea24, which
	sty curptr	; point at the VDC in 80 columns)
	sta curptr+1
	jsr calccol
	sty colptr
	sta colptr+1
	jsr calcscn0
	cmp curptr+1	; c64: $d2
	beq swapscn3
	sty sal		; c64: $ac
	sta sal+1	; same: $ad
	jsr calccol0
	sty eal		; c64: $ae
	sta eal+1	; same: \$af
	ldy #39
swapscn2:
	lda (curptr),y	; c64: ($d1),y
	pha
	lda (sal),y	; same: ($ac),y
	sta (curptr),y	; c64: ($d1),y
	pla
	sta (sal),y	; same: ($ac),y
	lda (colptr),y	; c64:  ($f3),y
	pha
	lda (eal),y	; same: ($ae),y
	sta (colptr),y	; c64:  ($f3),y
	pla
	sta (eal),y	; same: ($ae),y
	dey
	bpl swapscn2
swapscn3:
	inx
	cpx #25
	bcc swapscn1
	pla
	sta scnmode
	pla
	sta eal+1	; both: $af
	pla
	sta eal		; both: $ae
	pla
	sta sal+1	; both: $ad
	pla
	sta sal		; both: $ac
	pla
	sta colptr+1	; c64:  $f4
	pla
	sta colptr	; c64:  $f3
	pla
	sta curptr+1	; c64:  $d2
	pla
	sta curptr	; c64: $d1
	bit mode	; 80 columns?
	bmi vdcmask
	rts

; ********************************
; *  status lines on the VDC
; ********************************

; In 80 columns the console is on the VDC, but the status area -- row
; 24, and rows 16-23 too while the screen mask is on (scnmode = 0) --
; is still drawn on the VIC screen, by the IRQ and by &,69 for rows 16
; and up. vdcstat copies those VIC rows to the same rows of the VDC.
; It can't run in the IRQ: the editor's VDC writes (select a register,
; then write it) aren't safe from an interrupt that selects another, so
; it runs from the main line, in getchr (the ML's wait for a key) and in
; trace0 (every BASIC statement), at most once every 8 jiffies. A row is
; redrawn only when the Fletcher checksum of its characters and colors
; changes.
;
; While the mask is on, the console's own rows 16-23 are kept in spare
; VDC RAM (vdcsave), as the C64 keeps them in tempscn: vdcrow finds
; them there, so scrolling and clearing carry on underneath.

vdcsave	= $1000		; VDC RAM: 8 rows of characters at $1000, their
vdcsavea = $1800	; attributes at $1800 (free: the editor uses
			; $0000-$0fcf and the charset at $2000)

; setmode turned the mask on or off (scnmode is the new setting): move
; the console's rows 16-23 into vdcsave and blank them for the status
; area, or bring them back
vdcmask:
	lda #16
	sta vdcm_row
vdcmask1:
	ldx vdcm_row
	jsr vdcrowd	; on the VDC screen
	lda scnmode
	bne vdcmask2
	jsr vdcmcopy	; mask on: screen -> vdcsave
	jsr vdcrowv
	jsr vdcmcpy1
	ldx vdcm_row
	jsr vdcrowd	; and blank the screen row
	jsr vdclinea
	jmp vdcmask3
vdcmask2:
	jsr vdcmcopy	; mask off: vdcsave -> screen
	jsr vdcrowv
	jsr vdcmswap
	jsr vdcmcpy1
vdcmask3:
	inc vdcm_row
	lda vdcm_row
	cmp #24
	bcc vdcmask1
	lda #1		; draw every status row, at the next vdcstat
	sta vdcst_force
	lda #$ff	; (no jiffy count matches: "and #$f8")
	sta vdcst_jif
	rts
; copy one row (characters and attributes) from vdcr_scr/vdcr_atr, saved
; in vdcm_*, to the addresses vdcrowv just put in vdcr_*
vdcmcopy:
	lda vdcr_scr
	sta vdcm_scr
	lda vdcr_scr+1
	sta vdcm_scr+1
	lda vdcr_atr
	sta vdcm_atr
	lda vdcr_atr+1
	sta vdcm_atr+1
	rts
vdcmswap:
	ldx #3
vdcmswp1:
	lda vdcr_scr,x
	ldy vdcm_scr,x
	sta vdcm_scr,x
	tya
	sta vdcr_scr,x
	dex
	bpl vdcmswp1
	rts
vdcmcpy1:
	lda vdcm_scr
	sta vdc_src
	lda vdcm_scr+1
	sta vdc_src+1
	lda vdcr_scr
	sta vdc_dst
	lda vdcr_scr+1
	sta vdc_dst+1
	jsr vdccopy80
	lda vdcm_atr
	sta vdc_src
	lda vdcm_atr+1
	sta vdc_src+1
	lda vdcr_atr
	sta vdc_dst
	lda vdcr_atr+1
	sta vdc_dst+1
vdccopy80:
	lda #VDC_COLS
	sta vdc_count
	lda #0
	sta vdc_count+1
	jmp vdc_copy

; vdcrow: the VDC addresses of console row .x, in vdcr_scr (characters)
; and vdcr_atr (attributes): rows 16-23 are in vdcsave while the mask is
; on. vdcrowd: the row on the VDC screen; vdcrowv: the row in vdcsave
; (.x 16-23). Keep .x.
vdcrow:
	lda scnmode
	bne vdcrowd	; mask off: every row on the screen
	cpx #16
	bcc vdcrowd
	cpx #24
	bcc vdcrowv
vdcrowd:
	lda vdcrowlo,x
	sta vdcr_scr
	sta vdcr_atr
	lda vdcrowhi,x
	ora vdcscrn
	sta vdcr_scr+1
	lda vdcrowhi,x
	ora vdcattr
	sta vdcr_atr+1
	rts
vdcrowv:
	lda vdcrowlo-16,x	; (row - 16) * 80
	sta vdcr_scr
	sta vdcr_atr
	lda vdcrowhi-16,x
	ora #>vdcsave
	sta vdcr_scr+1
	lda vdcrowhi-16,x
	ora #>vdcsavea
	sta vdcr_atr+1
	rts

; copy the VIC status rows to the VDC (see above). Keeps .x and .y.
vdcstat:
	bit mode
	bpl vdcst9
	lda jiffy
	and #$f8
	cmp vdcst_jif
	beq vdcst9
	sta vdcst_jif
	txa
	pha
	tya
	pha
	ldx #24
vdcst1:
	jsr vdcsrow
	dex
	lda scnmode
	bne vdcst2	; mask off: row 24 only
	cpx #16
	bcs vdcst1
vdcst2:
	lda #0
	sta vdcst_force
	pla
	tay
	pla
	tax
vdcst9:
	rts

; VIC row .x to VDC row .x, if it changed. Keeps .x.
vdcsrow:
	stx vdcs_row
	jsr calcscn2	; the VIC screen row itself
	sty vdcs_c1+1
	sta vdcs_c1+2
	sty vdcs_d1+1
	sta vdcs_d1+2
	jsr calccol2
	sty vdcs_c2+1
	sta vdcs_c2+2
	sty vdcs_d2+1
	sta vdcs_d2+2
	lda #0		; Fletcher: a += byte, b += a
	sta vdcs_a
	sta vdcs_b
	ldy #39
vdcs1:
vdcs_c1:
	lda $ffff,y
	jsr vdcsum
vdcs_c2:
	lda $ffff,y
	and #$0f
	jsr vdcsum
	dey
	bpl vdcs1
	ldx vdcs_row
	lda vdcst_force
	bne vdcs2
	lda vdcs_a
	cmp vdcst_a-16,x
	bne vdcs2
	lda vdcs_b
	cmp vdcst_b-16,x
	beq vdcs9	; unchanged
vdcs2:
	lda vdcs_a
	sta vdcst_a-16,x
	lda vdcs_b
	sta vdcst_b-16,x
	jsr vdcrowd	; draw it: 40 characters, then spaces to the end
	lda vdcr_scr+1	; of the 80-column row
	ldy vdcr_scr
	jsr vdc_set_update
	ldy #0
vdcs3:
vdcs_d1:
	lda $ffff,y
	jsr vdc_put
	iny
	cpy #40
	bcc vdcs3
vdcs4:
	lda #' '
	jsr vdc_put
	iny
	cpy #VDC_COLS
	bcc vdcs4
	lda vdcr_atr+1	; and the 40 colors, as attributes
	ldy vdcr_atr
	jsr vdc_set_update
	lda color	; the editor's charset (ALT) bit, as dispvdc
	and #VDC_ATTR_ALT
	sta vdcs_alt
	ldy #0
vdcs5:
vdcs_d2:
	lda $ffff,y
	and #$0f
	tax
	lda vdccolor,x
	ora vdcs_alt
	jsr vdc_put
	iny
	cpy #40
	bcc vdcs5
vdcs9:
	ldx vdcs_row
	rts
vdcsum:
	clc
	adc vdcs_a
	sta vdcs_a
	clc
	adc vdcs_b
	sta vdcs_b
	rts

vdcr_scr:	word 0
vdcr_atr:	word 0
vdcm_scr:	word 0
vdcm_atr:	word 0
vdcm_row:	byte 0
vdcs_row:	byte 0
vdcs_a:		byte 0
vdcs_b:		byte 0
vdcs_alt:	byte 0
vdcst_jif:	byte $ff
vdcst_force:	byte 1
vdcst_a:	byte 0,0,0,0,0,0,0,0,0	; rows 16-24
vdcst_b:	byte 0,0,0,0,0,0,0,0,0

;****************************
;* decimal to ascii routine *
;****************************
decimal:
	sta binary
	stx binary+1
	ldy #0
dec1:
	ldx #'0'
dec2:
	lda binary
	cmp dectbl1,y
	lda binary+1
	sbc dectbl2,y
	bcc dec3
	sta binary+1
	lda binary
	sbc dectbl1,y
	sta binary
	inx
	bne dec2
dec3:
	txa
	sta decchr,y
	iny
	cpy #5
	bne dec1
	rts

dectbl1:
	byte <10000, <1000, <100, <10, <1
dectbl2:
	byte >10000, >1000, >100, >10, >1
;*
;* memory and trace update
;*
trace0:
	inc scnlock
	lda scnmode
	bne trace1
	jsr trace2
trace1:
	dec scnlock
	jmp vdcstat	; 80 columns: the status lines to the VDC

trace2:
	sec
	lda 51
	sbc 49
	tay
	lda 52
	sbc 50
	tax
	cpy oldmem
	bne trace3
	cpx oldmem+1
	beq trace4
trace3:
	sty oldmem
	stx oldmem+1
	tya
	jsr decimal
	ldy #4
trace3a:
	lda decchr,y
	ora #$80
	sta sdisp+14,y
	dey
	bpl trace3a
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
	jsr decimal
	ldy #4
trace5a:
	lda decchr,y
	ora #$80
	sta sdisp+23,y
	dey
	bpl trace5a
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

oldline:
	word 0
oldmem:
	word 0

dspidle:
	sta idlesec
	stx idleten
	sty idlemin
	lda scnmode
	bne dspidle1
	lda curdsp
	beq dspidle1
	lda idlesec
	ora #$b0
	sta adisp+18
	txa
	ora #$b0
	sta adisp+17
	tya
	ora #$b0
	sta adisp+16
dspidle1:
	rts
