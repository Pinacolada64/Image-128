{include:"equates.asm"}

orig rs232_exec_address ; "rs232_user.bin"

enabl	= $2a1	; CIA #2 NMI flag
baudof	= $299	; time required to send a bit

rstkey = $fe56
norest = $fe72
nmiexit = $ff37	; c64: $febc
findfn = $f30f
devnum = $f31f
nofile = $f701

first:

xx00:
	jmp setup
xx03:
	jmp inabl
xx06:
	jmp disab
xx09:
	jmp rsget_entry
xx0c:
	jmp rsout_entry
xx0f:
	jmp setbaud

	;     300   600  1200 2400 4800
strt:
	word 4915, 2550, 1090, 459, 220
full:
	word 3410, 1705,  845, 421, 200
baudofs:
	word 3410, 1706,  852, 426, 213

vectbl:

oldnmi:
	byte $18
	word nmi64
oldopn:
	byte $1a
	word nopen
oldcls:
	byte $1c
	word nclose
oldchk:
	byte $1e
	word nchkin
oldclr:
	byte $22
	word nclrch
oldchr:
	byte $24
	word nchrin
;oldout:
;	byte $26
;	word nchrout
oldget:
	byte $2a
	word ngetin

	byte 0

setup:
	ldx #0
	lda #3
	sta 21
setup1:
	lda vectbl,x
	beq setup3
	sta 20
	lda #$4c
	sta vectbl,x
	inx
	ldy #0
setup2:
	lda vectbl,x
	pha
	lda (20),y
	sta vectbl,x
	pla
	sta (20),y
	iny
	inx
	cpy #2
	bcc setup2
	jmp setup1
setup3:
	ldx #$01
	ldy #<426
	lda $2a6
	beq setup4
	ldx #$81
	ldy #<416
setup4:
	stx $dc0e
	sty baudofs+6
	rts

nmi64:
	pha
	txa
	pha
	tya
	pha
nmi128:
	cld
	lda $dd01
	and #%00010000
	sta carrier
	ldx $dd07
	lda #$7f
	sta $dd0d
	lda $dd0d
	bpl notcia
	cpx $dd07
	ldy $dd01
	bcs maskit
	ora #2
	ora $dd0d
maskit:
	and enabl
	tax
	lsr
	bcc ckflag
	lda $dd00
	and #$fb
	ora $b5
	sta $dd00
ckflag:
	txa
	and #$10
	beq nmion
strtlo:
	lda #$42
	sta $dd06
strthi:
	lda #$04
	sta $dd07
	lda #$11
	sta $dd0f
	lda #$12
	eor enabl
	sta enabl
	sta $dd0d
fulllo:
	lda #$4d
	sta $dd06
fullhi:
	lda #$03
	sta $dd07
	lda #$08
	sta $a8
	bne chktxd

notcia:
	ldy #$00
	jmp rstkey

nmion:
	lda enabl
	sta $dd0d
	txa
	and #$02
	beq chktxd
	tya
	lsr
	ror $aa
	dec $a8
	bne txd
	ldy ridbe
	lda $aa
	sta ribuf,y
	iny
	bpl nowrp
	ldy #0
nowrp:
	sty ridbe
	lda #$00
	sta $dd0f
	lda #$12
switch:
	ldy #$7f
	sty $dd0d
	sty $dd0d
	eor enabl
	sta enabl
	sta $dd0d
txd:
	txa
	lsr
chktxd:
	bcc exit
	dec $b4
	bmi char
	lda #$04
	ror $b6
	bcs store
low:
	lda #$00
store:
	sta $b5
exit:
	jmp nmiexit
char:
	ldy rodbs
	cpy rodbe
	beq txoff
	jsr sendchr
	bne low
txoff:
	ldx #0
	stx $dd0e
	lda #1
	bne switch

sendchr:
	lda robuf,y
	sta $b6
	iny
	bpl send1
	ldy #0
send1:
	sty rodbs
	lda #9
	sta $b4
	rts

disabl:
	pha
test:
	lda enabl
	and #$03
	bne test
	lda #$10
	sta $dd0d
	lda #$02
	and enabl
	bne test
	sta enabl
	pla
	rts

fulbuf:
	jsr strtup
	jmp point
rsout_entry:
	sta $9e
	sty $97
point:
	ldy rodbe
	sta robuf,y
	iny
	bpl rsout1
	ldy #0
rsout1:
	cpy rodbs
	beq fulbuf
	sty rodbe

	lda scnmode
	bne strtup
	lda flag_dsr_addr
	and #flag_dsr_r_mask
	beq strtup

; update TX window

	ldy #0
outdisp:
	lda sdisp+30,y
	sta sdisp+29,y
	iny
	cpy #9
	bcc outdisp
	lda $9e
	sta sdisp+38
strtup:
	lda enabl
	and #1
	bne ret3
	sta $b5
	ldy rodbs
	jsr sendchr
	lda baudof
	sta $dd04
	lda baudof+1
	sta $dd05
	lda #$11
	sta $dd0e
	lda #$81
change:
	sta $dd0d
	php
	sei
	ldy #$7f
	sty $dd0d
	sty $dd0d
	ora enabl
	sta enabl
	sta $dd0d
	plp
ret3:
	clc
	ldy $97
	lda $9e
	rts

nchkin:
	stx xtmp
	jsr findfn
	bne nosuch
	jsr devnum
	lda $ba
	cmp #2
	bne back
	sta $99
inable:
	sta $9e
	sty $97
	jsr getenabl
	bne ret1
	sta $dd0f
	lda #$90
	jmp change
nosuch:
	jmp nofile
back:
	ldx xtmp
	jsr disab
	jsr oldchk
	jmp inabl
xtmp:
	byte 0

ngetin:
	pha
	lda $9a
	cmp #2
	bne notget
	pla
rsget_entry:
	sta $9e
	sty $97
	ldy ridbs
	cpy ridbe
	beq ret2
	lda ribuf,y
	sta $9e
	iny
	bpl rsget1
	ldy #0
rsget1:
	sty ridbs

	lda scnmode
	bne ret1
	lda flag_dsr_addr
	and #flag_dsr_r_mask
	beq ret1

; update RX window

	ldy #0
inpdisp:
	lda sdisp+2,y
	sta sdisp+1,y
	iny
	cpy #9
	bcc inpdisp
	lda $9e
	sta sdisp+10
ret1:
	clc
ret2:
	ldy $97
	lda $9e
	rts
notget:
	pla
	jsr disab
	jsr oldget

inabl:
	php
	pha
	txa
	pha
	tya
	pha
	jsr inable
	pla
	tay
	pla
	tax
	pla
	plp
	rts

disab:
	php
	jsr disabl
	plp
	rts

getenabl:
	lda enabl
	and #$12
	rts

dtrtable:
	byte 0, 38

setdtr:
	and #1
	tay
	lda dtrtable,y
	sta 56577
	rts

setbaud:
	cmp #0
	bmi setdtr
	cmp #5
	bcc setbaud1
	rts
setbaud1:
	asl
	tay
	lda strt,y
	sta strtlo+1
	lda strt+1,y
	sta strthi+1
	lda full,y
	sta fulllo+1
	lda full+1,y
	sta fullhi+1
	lda baudofs,y
	sta baudof
	lda baudofs+1,y
	sta baudof+1
	jsr getenabl
	bne ret1
	sta $dd0f
	rts

;nchrout:
;	jsr disab
;	jsr oldout
;	jmp inabl

nopen:
	jsr disab
	jsr oldopn
	jmp inabl

nclose:
	jsr disab
	jsr oldcls
	jmp inabl

nclrch:
	jsr disab
	jsr oldclr
	jmp inabl

nchrin:
	jsr disab
	jsr oldchr
	jmp inabl

last:
