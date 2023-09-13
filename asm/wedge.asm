orig wedge_exec_address
; jump table

; xx00: install w/o error trap
; xx03: install w/error trap
; xx06: load after filename is set
; xx09: save array pointers
; xx0c: restore array pointers

start:
	jmp install
	jmp install0
	jmp openroom
	jmp arraysv0
	jmp arrayrs0
	jmp collect
wgone0:
	jmp wgone
weval0:
	jmp weval
wtrap0:
	jmp wtrap
wfunc0:
	tsx
	txa
	tay
	lda #$00
	jmp givayf	; c64: $b391

filename_len:
	byte 0
fdev:
	byte 0

tload:
	jsr chrget
	jsr getfile
	jsr openroom
	jmp gone2

openroom:
	ldy #0
openroo1:
	cpy fnlen	; $b7
	beq openroo2
	lda (fnadr),y	; ($bb),y
	sta fbuf,y
	iny
	cpy #20
	bcc openroo1
openroo2:
	sty filename_len
	lda fa		; $ba
	sta fdev
	lda sa		; $b9
	and #31
	sta loadflag
	jsr collect
	ldx strend	; $31
	ldy strend+1	; c64: $32
	stx sal		; c64: $ac
	sty sal+1	; c64: $ad
	ldx fretop	; c64: $33
	ldy fretop+1	; c64: $34
	stx eal		; c64: $ae
	sty eal+1	; c64: $af
	stx strend	; c64: $31
	sty strend+1	; c64: $32
	ldx #$2f
	jsr oprm
	ldx #$2d
	jsr oprm

loadfile:
	lda #127
	ldx fdev
	ldy #0
	jsr setlfs
	ldx #<fbuf
	ldy #>fbuf
	lda filename_len
	jsr setnam
	jsr openf
	ldx #127
	jsr chkin
	jsr chrin
	jsr chrin
	jsr chrin
	jsr chrin
	jsr chrin
	sta l1x+1
	jsr chrin
	sta l2x+1
	jsr clrchn
	lda #127
	jsr closef
	jsr scan0
	lda #127
	ldx fdev
	ldy #0
	jsr setlfs
	ldx #<fbuf
	ldy #>fbuf
	lda filename_len
	jsr setnam
	lda #0
	ldx eal		; c64: $ae
	ldy eal+1	; c64: $af
	jsr loadf
	bcc loadfil1
	jsr chopfile
loaderr:
	ldx #29
	jmp error
loadfil1:
	jsr linkprg

	lda l1x+1
	cmp curlin	; c64: $39/57
	lda l2x+1
	sbc curlin+1	; c64: $3a/58
	bcs chopfile
	lda #<(prgstart-1)
	sta txtptr	; c64: $7a
	lda #>(prgstart-1)
	sta txtptr+1	; c64: $7b

chopfile:
	ldx #<65535
	ldy #>65535
chopfil1:
	stx l1x+1
	sty l2x+1
	jsr scan0
	ldy #0
	tya
	sta (eal),y	; same: ($ae),y
	iny
	sta (eal),y	; same: ($ae),y
	clc
	lda #2
	adc eal		; c64: $ae
	sta eal		; c64: $ae
	lda #0
	adc eal+1	; c64: $af
	sta eal+1	; c64: $af

closroom:
	ldx txttab	; c64: $2d
	ldy txttab+1	; c64: $2e
	stx sal		; c64: $ac
	sty sal+1	; c64: $ad
	ldx eal		; c64: $ae
	ldy eal+1	; c64: $af
	stx txttab	; c64: $2d
	sty txttab+1	; c64: $2e
	ldx #$2f
	jsr clrm
	ldx #$31

clrm:
	sei
	ldy #0
	lda 0,x
	sta cmp0	; c64: $b0
	lda 1,x
	sta cmp0+1	; c64: $b1
clrm1:
	lda (sal),y	; same: ($ac),y
	sta (eal),y	; same: ($ae),y
	lda sal		; same: $ac
	cmp 0,x
	bne clrm0
	lda sal+1	; c64: $ad
	cmp 1,x
	beq clrm4
clrm0:
	inc sal		; c64: $ac
	bne clrm2
	inc sal+1	; c64: $ad
clrm2:
	inc eal		; c64: $ae
	bne clrm3
	inc eal+1	; c64: $af
clrm3:
	jmp clrm1
clrm4:
	lda eal		; c64: $ae
	sta 0,x
	lda eal+1	; c64: $af
	sta 1,x
	cli
	rts

scan0:
	ldx txttab	; c64: $2b
	ldy txttab+1	; c64: $2c
	stx sal		; c64: $ac
	sty sal+1	; $ad
scan1:
	stx eal		; $ae
	sty eal+1	; $af
	ldy #2
	lda (eal),y	; same: ($ae),y
l1x:
	cmp #0
	iny
	lda (eal),y	; same: ($ae),y
l2x:
	sbc #0
	bcs scan3
scan2:
	lda eal		; $ae
	ldx eal+1	; $af
	sta sal		; $ac
	stx sal+1	; $ad
	ldy #0
	lda (eal),y	; same: ($ae),y
	tax
	iny
	lda (eal),y	; same: ($ae),y
	tay
	bne scan1
scan3:
	rts

oprm:
	sei
	ldy #0
	lda 0,x
	sta cmp0	; $b0
	lda 1,x
	sta cmp0+1	; $b1
oprm1:
	lda sal		; c64: $ac
	cmp 0,x
	bne oprm0
	lda sal+1	; c64: $ad
	cmp 1,x
	beq oprm4
oprm0:
	lda sal		; c64: $ac
	bne oprm2
	dec sal+1	; c64: $ad
oprm2:
	dec sal		; c64: $ac
	lda eal		; c64: $ae
	bne oprm3
	dec eal+1	; c64: $af
oprm3:
	dec eal		; same: $ae
	lda (sal),y	; same: ($ac),y
	sta (eal),y	; same: ($ae),y
	jmp oprm1
oprm4:
	lda eal		; same: $ae
	sta 0,x
	lda eal+1	; same: $af
	sta 1,x
	cli
	rts

pokefix:
	lda $15
	cmp #$40
	bcc pokefix1
	cmp #$43
	bcc pokefix0
	cmp #$46
	bcc pokefix1
	cmp #$4a
	bcs pokefix1
	sec
	sbc #$03
pokefix0:
	sec
	sbc #$30
	sta $15
pokefix1:
	rts

tpoke:
	jsr chrget
	jsr getbytc	; was getnum (label only used once here)
	jsr pokefix
	ldy #0
	txa
	sta ($14),y
	jmp gone2

tsys:
	jsr chrget
	jsr frmnum
	jsr getadr
	lda linnum	; c64: $15
	cmp #$ff
	beq tsys1
	cmp #$c0
	beq tsys1
	jmp ilqerr
tsys1:
	jsr syscll
	jmp gone2

tnew:
	jsr chrget
	jsr linget
	ldx linnum	; c64: $14
	ldy linnum+1	; c64: $15
	jsr chopfil1
	jmp gone2

thex:
	ldx #0
	stx var+1	; c64: $62
	stx var+2	; c64: $63
thex1:
	jsr chrget
	bcc thex2
	cmp #'g'
	bcs thex5
	cmp #'a'
	bcc thex5
	sbc #7
thex2:
	and #$f
	ldx #4
thex3:
	asl var+2	; c64: $63
	rol var		; c64: $62
	bcs thex4
	dex
	bne thex3
	ora var+2	; c64: $63
	sta var+2	; c64: $63
	bcc thex1
thex4:
	jmp ilqerr
thex5:
	ldx #$90
	sec
	jmp retval

tpeek:
	jsr chrget
	jsr parchk
	lda $14
	pha
	lda $15
	pha
	jsr getadr
	jsr pokefix
	ldy #0
	lda ($14),y
	tay
	pla
	sta $15
	pla
	sta $14
	jmp retbyt

tampr:
	jsr chrget
	jsr getaxy
	jsr usetbl1
	jmp gone2

wgone:
	lda fretop	; c64: $33/51
	cmp strend	; c64: $31/49
	lda fretop+1	; c64: $34/52
	sbc strend+1	; c64: $32/50
	bne wgone1
	jsr collect
	lda fretop	; c64: $33/51
	cmp strend	; c64: $31/49
	lda fretop+1	; c64: $34/52
	sbc strend+1	; c64: $32/50
	bne wgone1
; less than 256 bytes free, force
; out of memory error for safety
	ldx #1
	jsr arrayrs0
	ldx #16
	jmp error ;outofm
wgone1:
	lda #r6510_basic_ram
	sta r6510
	jsr trace
	lda #r6510_normal
	sta r6510
	jsr chrget
	cmp #'&'
	beq ampr0
	cmp #poketok
	beq poke0
	cmp #systok
	beq sys0
	cmp #loadtok
	beq load0
	cmp #newtok
	beq new0
	jsr chrgot
	jmp gone1

weval:
	jsr chrget
	ldx #0
	stx valtyp	; $d
	cmp #'$'
	beq hex0
	cmp #peektok
	beq peek0
	jsr chrgot
	jmp eval1

ampr0:
	jmp tampr
poke0:
	jmp tpoke
sys0:
	jmp tsys
load0:
	jmp tload
new0:
	jmp tnew
hex0:
	jmp thex
peek0:
	jmp tpeek

getaxy:
	jsr getparm
	stx sareg	; c64: 780
	jsr getparm
	stx sxreg	; c64: 781
	jsr getparm
	stx syreg	; c64: 782
	lda sareg	; c64: 780
	ldx sxreg	; c64: 781
	ldy syreg	; c64: 782
	rts

getparm:
	jsr chrgot
	ldx #0
	cmp #comma
	bne getparm1
	jsr getbytc
getparm1:
	rts

wtrap:
	stx sareg	; c64: $030c
	lda curlin	; c64: $39
	sta sxreg	; c64: $030d
	lda curlin+1	; c64: $3a
	sta syreg	; c64: $030e
	lda #<$4d3f	; c64: <$e38b, contents of ($0300)
	sta IERROR	; $300
	lda #>$4d3f	; c64: >$e38b, contents of ($0300)
	sta IERROR+1	; $301
	ldx #$fa
	txs
	lda #25
	sta temppt	; c64: $16/22
	lda #<trapline
	sta linnum	; c64: $14
	lda #>trapline
	sta linnum+1	; c64: $15
	jsr goto+3	; c64: $a8a3
	jmp newstt	; c64: $a7ae

install:
	lda #<$e38b
	ldx #>$e38b
	jmp install1
install0:
	lda #<wtrap0
	ldx #>wtrap0
install1:
	sta IERROR	; $300
	stx IERROR+1	; $301
	lda #<wgone0
	ldx #>wgone0
	sta IGONE	; $308
	stx IGONE+1	; $309
	lda #<weval0
	ldx #>weval0
	sta IEVAL	; $30a
	stx IEVAL+1	; $30b
	lda #<wfunc0
	ldx #>wfunc0
	sta USRADD	; $311
	stx USRADD+1	; $312
	rts

arrayoff:
	txa
	and #7
	asl
	asl
	tax
	ldy #2
	rts

;* copy pointers for arrays *
arraysv0:
	jsr arrayoff
arsv1:
; &,27: save array pointer "level" in .x?
arytab_hi = $0032	; dirty hack to assemble "lda arytab+1,y"
	sec
	lda arytab,y	; c64: $2f
	sbc vartab	; c64: $2d
	sta arryptrs+0,x; $13d0
;	lda arytab+1,y	; c64: $30
	lda arytab_hi,y	; c64: $30
	sbc vartab+1	; c64: $2e
	sta arryptrs+1,x; $13d1
	inx
	inx
	dey
	dey
	bpl arsv1
	rts

;* restore pointers for arrays *
arrayrs0:
	lda arytab	; c64: $2f
	sta sal		; c64: $ac
	lda arytab+1	; c64: $30
	sta sal+1	; c64: $ad
	jsr arrayoff
arrs1:
	clc
	lda arryptrs+0,x
	adc vartab	; c64: $2d
	sta arytab,y	; c64: $2f
	lda arryptrs+1,x
	adc vartab+1	; c64: $2e
;	sta arytab+1,y	; c64: $30
	sta arytab_hi,y
	inx
	inx
	dey
	dey
	bpl arrs1
	lda arytab	; c64:  $2f
	sta eal		; c64:  $ae
	lda arytab+1	; c64:  $30
	sta eal+1	; c64:  $af
	ldy #0
	beq arrs2
arrs3:
	inc sal		; c64:  $ac
	bne arrs3a
	inc sal+1	; c64:  $ad
arrs3a:
	inc eal		; c64:  $ae
	bne arrs2
	inc eal+1	; c64:  $af
arrs2:
	lda (sal),y	; same: ($ac),y
	sta (eal),y	; same: ($ae),y
	lda eal		; same: $ae
	cmp strend	; c64:  $31
	bne arrs3
	lda eal+1	; c64: $af
	cmp strend+1	; c64: $32
	bne arrs3
	rts

collect:
	lda #>gc
	ldy #>gchide
	ldx #gclen
	jsr swapper
	jsr gc
	jmp swapagn
