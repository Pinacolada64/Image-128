stcount:
	byte 0
stsize:
	byte 0

lodstruc:
	jsr fnvar
	tya
	pha
	txa
	pha
	jsr evalfil
	jsr strucbnk
	pla
	tax
	pla
	tay
	lda #0
	jmp loadf

savstruc:
	jsr fnvar
	tya
	pha
	txa
	pha
	jsr evalint	; the number of bytes, in .x .y (and linnum)
	stx strucsz
	sty strucsz+1
	jsr evalfil
	jsr strucbnk
	pla		; the end: the start + the bytes (c64: + linnum,
	sta $69		; $14, after evalfil, carry as it fell; the 128's
	clc		; linnum is $16, and its filename parser may use it)
	adc strucsz
	tax
	pla
	sta $6a
	adc strucsz+1
	tay
	lda #$69
	jmp savef

strucsz:
	word 0

; the array is in BASIC's variables, bank 1, and so is the filename (a
; BASIC string): SETBNK both to 1 for LOAD and SAVE. getfile (BASIC's own
; filename parser) leaves the data bank at 0, where LOAD puts a program,
; and in bank 0, at the array's address, is the BASIC program text: a
; struct load wrote its file over im or a module, and a save wrote out
; that text (e.last, the lightbar's, ...). c64: one bank.
strucbnk:
	lda #1
	ldx #1
	jmp setbnk

struct:
	sty stcount
	cpx #0
	beq putstruc
	cpx #1
	beq getstruc
	cpx #2
	beq lodstruc
	cpx #3
	beq savstruc
	cpx #14
	beq putfloat
	cpx #15
	beq getfloat
	lda #68
	jmp usetbl1

putstruc:
	jsr fnvar1
	jsr evalstr
	sta stsize
	ldy #0
	tax
	beq puts2
puts1:
	lda (index_24),y	; the string, from evalstr (c64: $22)
	sta (linnum),y
	iny
	cpy stcount
	bcs puts3
	dex
	bne puts1
puts2:
	lda #0
	sta (linnum),y
	iny
	cpy stcount
	bcc puts2
puts3:
	rts

getstruc:
	jsr fnvar1
	jsr fnvar
	ldy #0
gets1:
	lda (linnum),y
	beq gets2
	iny
	cpy stcount
	bcc gets1
gets2:
	sty stcount
	tya
	jsr makeroom
	ldy #0
gets3:
	cpy stcount
	beq gets4
	lda (linnum),y
	sta (var+1),y	; ($62),y
	iny
	bne gets3
gets4:
	jsr strold	; 128: see varbl.asm's strold/strnew
	ldy #4
gets5:
	lda var,y	; $61,y
	sta (varpnt),y	; ($47),y
	dey
	bpl gets5
	jmp strnew

putfloat:
	jsr fnvar1
	jsr fnvar
	ldy #4
putf1:
	lda (varpnt),y	; ($47),y
	sta (linnum),y
	dey
	bpl putf1
	rts

getfloat:
	jsr fnvar1
	jsr fnvar
	ldy #4
getf1:
	lda (linnum),y
	sta (varpnt),y	; ($47),y
	dey
	bpl getf1
	rts

cursposn:
	sty cursp0+1
	stx cursp2+1
	jsr cursmode
	beq cursp4
	lda #cursor_home
	jsr xchrout
cursp0:
	ldx #0
	beq cursp2
cursp1:
	lda #cursor_down
	jsr xchrout
	dex
	bne cursp1
cursp2:
	ldx #0
	beq cursp4
cursp3:
	lda #cursor_right
	jsr xchrout
	dex
	bne cursp3
cursp4:
	rts

cursmode:
	ldx #16
	jsr chkflag ;asc
	bne cursmod1
	lda #1
	rts
cursmod1:
	ldx #18
	jsr chkflag ;ans
	beq cursmod2
	lda #2
	rts
cursmod2:
	lda #0
	rts

calcgoto:
	txa
	pha
	ldx #var_a_integer
	jsr usevar
	ldx varbuf+1
	ldy varbuf
	pla
	bne calcgot1
	jmp mlgoto
calcgot1:
	jmp mlgosub

ecschk:
	stx stsize
	sty stcount
	jsr evalint
	sty ecsc5+1
	stx ecsc6+1
	jsr fnvar
	stx ecsc3+1
	sty ecsc4+1
	jsr evalstr
	sta index
	ldy #0
ecsc1:
	lda #0
	cpy index
	bcs ecsc2
	lda ($22),y
ecsc2:
	sta buf2,y
	iny
	cpy #8
	bcc ecsc1
	lda index
	beq ecsquit
	ldy #0
ecsc3:
	lda #0
	sta varbuf+3
ecsc4:
	lda #0
	sta varbuf+4
	lda #0
	sta varbuf+0
	lda #1
	sta varbuf+1
ecsscan:
	ldy #2
	lda (varbuf+3),y
ecsc5:
	and #0
	bne ecsscan1
	ldy #3
	lda (varbuf+3),y
ecsc6:
	and #0
	beq ecsnext
ecsscan1:
	ldy #6
	ldx #0
ecsscan2:
	lda (varbuf+3),y
	iny
	cmp buf2,x
	bne ecsnext
	cpy stsize
	bcs ecsdone
	inx
	cpx #8
	bcc ecsscan2
	jmp ecsdone

ecsnext:
	lda varbuf+3
	clc
	adc stsize
	sta varbuf+3
	lda varbuf+4
	adc #0
	sta varbuf+4
	inc varbuf+1
	dec stcount
	bne ecsscan
ecsquit:
	lda #0
	sta varbuf
	sta varbuf+1
ecsdone:
	ldx #var_a_integer
	jmp putvar

arbit:
	sty lu_load+1
; c64: "lda $ffd2 / cmp #$20" found a Lt. Kernal (it patches CHROUT's
; jump table entry to a jsr). No Lt. Kernal support on the 128 yet.
	lda #0
	cmp #$20
	bne arbit1
	dex
	beq lock
	dex
	beq unlock
arbit1:
	rts

lock:
	clc
	jsr block
	bpl idle
	cmp port_load+1
	beq lock1
	ldy #$cc ; reverse uppercase L
	sty tdisp+31
	jsr tdelay
	bne lock
idle:
	ldx #0
	lda port_load+1
lock1:
	inx
	sec
	jsr block
	jsr tdelay
	clc
	jsr block
port_load:
	cmp #0
	bne lock
	ldy #$a0
	sty tdisp+31
	rts

unlock:
	clc
	jsr block
	bpl unlock0
	cmp port_load+1
	bne unlock0
	dex
	bne unlock1
	lda #0
unlock1:
	sec
	jmp block
unlock0:
	rts

block:
	jsr ltk_bnkout
	php
	sta ltk_redbuf
	stx ltk_redbuf+1
lu_load:
; changed by self-modifying code
	lda #0
	sec
blkl_load:
; changed by self-modifying code
	adc #0
	tax
	lda #0
blkh_load:
; changed by self-modifying code
	adc #0
	tay
	lda #10
	plp
	jsr ltk_driver
	word ltk_redbuf
	byte 1
	ldx ltk_redbuf+1
	lda ltk_redbuf
	jsr ltk_bankin
	cli
	rts

tdelay:
	lda d1icr
	lda #%00000010
dloop:
	bit d1icr
	beq dloop
	rts


; 128: an$ without its first .a characters, as a string of its own. The
; c64 (strio.asm's newdate, strscan) moved an$'s pointer past them, which BASIC 7
; can't have: its garbage collection walks the string area string by
; string, each followed by its back-link, so it read the last two skipped
; characters as a back-link and wrote a string's new address through it,
; wherever they pointed (tests/standin/orphan.bas). makeroom runs while
; an$ is still whole (a collection moves it and its descriptor with it),
; then the rest is copied from wherever an$'s string is now.
; Here, not in strio.asm: $c000-$cfff is full.
strrest:
	sta strr_skip
	ldx #var_an_string
	jsr usevar
	sec
	lda varbuf
	sbc strr_skip
	bcs strr1
	lda #0		; (more to skip than there is)
strr1:
	sta strr_keep
	bne strr2
	jsr zero	; nothing left: ""
	jmp strr4
strr2:
	jsr makeroom	; .a bytes: varbuf
	ldx #var_an_string
	jsr gvarptr	; x/y: an$'s descriptor
	stx free_fb
	sty free_fc
	ldy #1
	lda (free_fb),y
	clc
	adc strr_skip
	tax
	iny
	lda (free_fb),y
	adc #0
	sta free_fc
	stx free_fb
	ldy strr_keep
strr3:
	dey
	lda (free_fb),y
	sta (varbuf+1),y
	tya
	bne strr3
strr4:
	ldx #var_an_string
	jmp putvar

strr_len:  byte 0	; strscan: an$'s length
strr_skip: byte 0
strr_keep: byte 0
