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

; 128: &,2 (dskin) leaves a$ pointing at the line in buf2, outside the
; string area. On the c64 x$=a$ copied such a string; BASIC 7's assignment
; copies only the descriptor, so every x$=a$ after &,2,2 changed with the
; next line read: im's d3$ (the status line's "Last"), sub.modem's mt$
; (whose val() then overflowed 300*2^a at logon) and others. &,2 now runs
; dskina: dskin, then strfix makes a$ a string of its own, as putln does
; for tt$(). This happens as the & call ends, like BASIC's own string
; making: makeroom can start a garbage collection, which uses zero page
; ($11, $14, $24/$25, $50-$5f, $61/$62...) that ML in the middle of its own
; work may be holding, so it isn't done inside putvar (tried: ?syntax and
; ?type mismatch errors in struct and MCI calls). swap3's reader calls
; dskin itself and keeps it as it was.
dskina:
	jsr dskin
	ldx #var_a_string
; strfix: if string variable .x points at text in RAM every configuration
; shares (below $4000, or $c000 up: Image's buffers), copy it into a new
; string and put that in the variable (putvar links it back). A string in
; $4000-$bfff is in the string area, or a literal in the program text (bank
; 0, not mapped here), and stays as it is.
strfix:
	stx strc_var
	jsr usevar	; varbuf: its descriptor
	lda varbuf
	beq strc9	; ""
	ldx varbuf+2
	cpx #$40
	bcc strc1
	cpx #$c0
	bcc strc9
strc1:
	sta strc_len
	stx free_fc	; the text (farcall keeps $fb/$fc)
	lda varbuf+1
	sta free_fb
	lda strc_len
	jsr makeroom	; .a bytes: varbuf
	ldy strc_len
strc2:
	dey
	lda (free_fb),y
	sta (varbuf+1),y
	tya
	bne strc2
	ldx strc_var
	jmp putvar
strc9:
	rts

strc_len: byte 0
strc_var: byte 0

arrays1:
; 0: tt$()	6: c%()
; 1: bb$()	7: d%()
; 2: dt$()	8: e%()
; 3: ed$()	9: f%()
; 4: nn$()	10: ac%()
; 5: a%()	11: so%()
	ascii "tbdenACDEFAS"
arrays2:
	ascii "TBTDN"
	byte $80, $80, $80, $80, $80
	ascii "CO"

; clear an array: &,11,x (x: arrays1/arrays2's numbering above)
; 128: was in the struct module (struct.asm); resident since it grew
; past the module's 6 pages with clrstr
arrclr:
	cpx #12
	bcs clrar7
	lda arytab	; 47
	sta varpnt	; 71
	lda arytab+1	; 48
	sta varpnt+1	; 72
clrar0:
	ldy #3
	lda (varpnt),y	; (71),y
	sta 21
	dey
	lda (varpnt),y	; (71),y
	sta 20
	dey
	lda (varpnt),y	; (71),y
	cmp arrays2,x
	bne clrar1
	dey
	lda (varpnt),y	; (71),y
	cmp arrays1,x
	beq clrar3
clrar1:
	clc
	lda 20
	adc varpnt	; 71
	sta varpnt	; 71
	lda 21
	adc varpnt+1	; 72
	sta varpnt+1	; 72
	lda varpnt	; 71
	cmp strend	; 49
	bne clrar2
	lda varpnt+1	; 72
	cmp strend+1	; 50
	beq clrar7
clrar2:
	jmp clrar0
clrar3:
	clc
	lda varpnt	; 71
	adc #7
	sta varpnt	; 71
	lda varpnt+1	; 72
	adc #0
	sta varpnt+1	; 72
	sec
	lda 20
	sbc #7
	sta 20
	lda 21
	sbc #0
	sta 21
	cpx #5		; 128: tt$() to nn$(), the string arrays:
	bcs clrar4
	jsr clrstr	; their strings garbage first
clrar4:
	ldy #0
	tya
	sta (varpnt),y	; (71),y
	inc varpnt	; 71
	bne clrar5
	inc varpnt+1	; 72
clrar5:
	lda 20
	bne clrar6
	dec 21
clrar6:
	dec 20
	bne clrar4
	lda 21
	bne clrar4
clrar7:
	rts

; 128: before clrarr zeros a string array's descriptors (varpnt: the first,
; 20/21: how many bytes), mark garbage each string in the string area whose
; back-link is its element: [length][$ff], as BASIC 7's assignment and
; strold (varbl.asm) do. Zeroed without that, the strings stayed "in use",
; linked to elements that no longer pointed at them: BASIC 7 then left their
; links behind when it moved the arrays (a new variable), and its garbage
; collection wrote a moved string's address through them (i/lo-last's tt$()
; lines, cleared by im's &,11 at line 82: tools/strcheck.py found one linked
; into the variable s). Uses free_fb/fc; keeps varpnt and 20/21.
clrstr:
	lda varpnt
	pha
	lda varpnt+1
	pha
	lda 20
	pha
	lda 21
	pha
clrs1:
	lda 20
	ora 21
	beq clrs8
	ldy #0
	lda (varpnt),y	; its length
	beq clrs5	; ""
	tax
	iny
	lda (varpnt),y
	sta free_fb
	iny
	lda (varpnt),y
	sta free_fc
	lda free_fb	; in the string area: fretop up to memsiz?
	cmp fretop
	lda free_fc
	sbc fretop+1
	bcc clrs5
	lda free_fb
	cmp memsiz
	lda free_fc
	sbc memsiz+1
	bcs clrs5
	txa		; just past the text: its back-link
	clc
	adc free_fb
	sta free_fb
	bcc clrs2
	inc free_fc
clrs2:
	ldy #0		; ours?
	lda (free_fb),y
	cmp varpnt
	bne clrs5
	iny
	lda (free_fb),y
	cmp varpnt+1
	bne clrs5
	lda #$ff	; the length, $ff
	sta (free_fb),y
	dey
	txa
	sta (free_fb),y
clrs5:
	clc		; the next element
	lda varpnt
	adc #3
	sta varpnt
	bcc clrs6
	inc varpnt+1
clrs6:
	sec
	lda 20
	sbc #3
	sta 20
	lda 21
	sbc #0
	sta 21
	jmp clrs1
clrs8:
	pla
	sta 21
	pla
	sta 20
	pla
	sta varpnt+1
	pla
	sta varpnt
	rts
