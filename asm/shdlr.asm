outscn:

@outscn0:
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
	cpx #39
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
	lda #39
	sta lnmx	; c64: $d5/213. max screen line length
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
	cpx #39
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
	dec sline
	jsr sccrsr
	dec scnlock
	rts

scline:
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
	lda #39
	sta lnmx	; c64: $d5/213
	lda #0
	sta qtsw	; c64: 212
	lda #0
	sta insrt	; c64: 216

fixlink:
	ldx sline
fixlinks:
; c128 line link table is a bitmap from $035e-$361 (4 bytes, 24 bits)
;	lda 217,x
;	ora #128
;	sta 217,x
; clear line link bitmap, row in .x:
	jsr $cb74
	rts

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
	jmp $fff0

;* output routine to fix 1200 and
;* do the transmit window

out0:
	sta $9e
	txa
	pha
	tya
	pha
	jmp out3
outm:
	sta $9e
	txa
	pha
	tya
	pha
	jmp out1
out:
	sta $9e
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
	lda $9e
	jsr prtscn	; c64: $e716
	dec scnlock
	jmp out4
out1:

out3:
	lda $9e
	jsr rsout
out4:
	pla
	tay
	pla
	tax
	lda $9e
	clc
	rts
out5:
	pla
	tay
	pla
	tax
	lda $9e
	jsr rsdisab
	jsr oldout
	jmp rsinabl

crsroff:
	lda #1
	sta crsrflg
	lda crsrmode
	beq crsroff1
	lda undchr
	ldx undcol
	ldy #0
	sty crsrmode
	jsr $ea13	; FIXME: set cursor blink timing & color memory address
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
calcscn2:
	lda $ecf0,x	; FIXME: Low Byte Table of Screen Line Addresses
	tay
	lda $d9,x	; FIXME: screen line link table
	and #$03
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
	lda $ecf0,x	; FIXME: Low Byte Table of Screen Line Addresses
	tay
	lda $d9,x	; FIXME: Screen line link table
	and #$03
	ora #$d8
	rts

he9f0:
	tya
	pha
	jsr calcscn
	sty pnt		; c64: $d1
	sta pnt+1	; c64: $d2
	pla
	tay
	rts

hea24:
	tya
	pha
	jsr calccol
	sty colptr	; c64: $f3
	sta colptr+1	; c64: $f4
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
	jsr he9f0
	jsr hea24
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
	rts
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
	rts

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
