; intro.asm -- runs at protostart, included in ml.asm. The boot loader
; (boot.asm) jumps to intro in cfg_rom once every part of the ML is in
; place; "sys 7171" in im (c64: sys 49155) calls setup.

devnum = 186
{undef:use_ltk}	; Lt. Kernal emulation is not ready for VICE 128

; intro is a proto
	jmp intro
	jmp setup_far
	byte $ff ;intro

;* intro program

intro:

; share the bottom and top 16K of RAM between the banks (see cfg_ml in
; equates.asm), keeping the VIC's bank bits

	sei
	lda mmurcr
	and #$c0
	ora #rcr_shared
	sta mmurcr
	cli

; BASIC's memory for im: program text in bank 0 from prgstart up to
; textop, variables and strings in bank 1 from varstart up to vartop
; (the swapped-out modules are above it). Still in cfg_rom: stores to
; $4000 and up go to bank 0's RAM under the ROMs.

	lda #<prgstart
	ldx #>prgstart
	sta txttab	; c64: $2b
	stx txttab+1	; c64: $2c
	lda #0
	sta prgstart-1
	sta prgstart
	sta prgstart+1
	lda #<(prgstart-1)
	sta $0a05	; bottom of BASIC text (c64: $0281)
	stx $0a06
	lda #<textop
	ldx #>textop
	sta $1212	; top of BASIC text
	stx $1213
	lda #<varstart
	ldx #>varstart
	sta vartab	; c64: $2d
	stx vartab+1
	lda #<vartop
	ldx #>vartop
	sta $39		; top of string space (c64: $37)
	stx $3a
	sta $0a07	; top of variables (c64: $0283)
	stx $0a08

;load "im 128" basic program into bank 0

	lda #0
	tax
	jsr k_setbnk	; data and filename in bank 0
	lda #1
	ldx devnum
	ldy #0
	jsr k_setlfs	; $ffba
	lda im_filename
	ldx #<(im_filename+1)
	ldy #>(im_filename+1)
	jsr k_setnam	; $ffbd
	lda #0
	ldx #<prgstart
	ldy #>prgstart
	jsr k_loadf
	stx $1210	; end of BASIC text
	sty $1211
	jsr k_linkprg
	lda #1
	sta loadflag	; im: "on peek(linflg) goto 3000,4000"

;restore screen

	lda #clear_screen
	jsr k_prtscn	; c64: $e716

;fake lightbar table

	lda #0
	ldy #0
chktbl_loop:
	sta chktbl,y
	iny
	cpy #16
	bne chktbl_loop
	lda #32
	ldy #0
bartbl_loop:
	sta bartbl,y
	iny
	cpy #192
	bne bartbl_loop

; the wedge: &, $hex and the rest in BASIC (wedge.asm's install)

	jsr wedge_exec_address

; run program

	jmp farjmp_run	; c64: lda #0 / jsr $a871 (RUN) / jmp $a7ae (NEWSTT)

;* filenames

im_filename:
	byte setup_far-im_filename-1
	ascii "im 128"

; im's "sys 7171" (protostart+3): setup in cfg_ml
setup_far:
	jsr farcall
	byte cfg_ml
	word setup
	rts

;* setup routines *

;* main setup routine
setup:
	lda #0
	tay
zero_cassbuff:
	sta cassbuff,y
	iny
	cpy #mleft-cassbuff+1	; c64: 1024-cassbuff (828-1023)
	bne zero_cassbuff
	ldy #0
copy_date:
	lda date2,y
	sta date1,y
	iny
	cpy #28
	bne copy_date
	lda #80
	sta ptrclmn
	lda #40
	sta modclmn
	lda #1
	sta local
	ldy #0
zero_tmmpscn:
	lda #32
	sta tempscn+$00,y
	sta tempscn+$a0,y
	lda #1
	sta tempcol+$00,y
	sta tempcol+$a0,y
	iny
	cpy #$a0
	bne zero_tmmpscn
	ldy #11
copy_daysofm:
	lda daysofm0,y
	sta daysofm,y
	dey
	bpl copy_daysofm

	jsr copytran

	ldy #15
	lda #16
zero_pmodetbl:
	sta pmodetbl,y
	dey
	bpl zero_pmodetbl
	lda #255
	sta pmodetbl+16
	lda #0
	sta pmodetbl+17
	ldy #0
alarmtb_loop:
	lda #1
	sta alarmtb,y
	lda #0
	sta alarmtb+1,y
	iny
	bpl alarmtb_loop

	ldy #12*3-1
months_loop:
	lda montbl0,y
	sta montbl,y
	dey
	bpl months_loop

	ldy #8*3-1
days_in_months_loop:
	lda daytbl0,y
	sta daytbl,y
	dey
	bpl days_in_months_loop

	ldy #31
date_format_loop:
	lda date1fmt,y
	sta date1,y
	dey
	bpl date_format_loop

	ldy #64
sound_loop:
	lda sndtbl0,y
	sta sndtbl,y
	dey
	bpl sound_loop

	ldy #0
	ldx #0
screen_addresses_loop:
	lda screentb,y
	iny
	sta lobytes,x
	lda screentb,y
	iny
	sta hibytes,x
	lda screentb,y
	iny
	sta lobytec,x
	lda screentb,y
	iny
	sta hibytec,x
	inx
	cpx #25
	bne screen_addresses_loop

	lda chrout	; $ffd2
	cmp #$20
	bne setup1
{ifdef:use_ltk}
	jsr lockinit	; TODO: once LtK emulation comes out for vice 128...
{endif}

setup1:
	lda #0
	sta passmode
	lda #'X'
	sta mask
	lda #2
	sta bar
	lda #0
	sta readmode
	sta scnmode
	sta scnlock
	sta interm
	sta inchat
	jsr iosetup
	jsr setptrs
	jsr setirq
	jsr trapoff
	jsr setscrn
	ldx #3
	jsr comq	; set mci color default?
	jsr startmsg
	rts

;* setup i/o windows

iosetup:
	lda ICHROUT	; $0326
	sta oldout_vec
	lda ICHROUT+1	; $0327
	sta oldout_vec+1
	lda #<newout_far
	sta ICHROUT	; $0326
	lda #>newout_far
	sta ICHROUT+1	; $0327
	rts

;* setup irq vector

; Image's IRQ work runs ahead of the KERNAL's handler, which keeps the
; VIC's raster interrupt (glue.asm's irq_far). c64: this took the raster
; interrupt over (ml.asm's newirq says why that's not done here yet).
setirq:
	lda #$1f
	sta d1icr	; CIA #1 interrupts off (the 128 uses none)
	lda #$ff
	sta timblo
	sta timbhi
	lda #$11
	sta ciacrb	; timer B free-running, for Image's own timing
	lda #0
	sta irqcount
	sei
; BASIC 7's own IRQ ($a84d, for SPRITE/MOVSPR, SOUND and PLAY) copies its
; sprite table into $d000-$d010 every frame, over Image's BBS flags there
; (local, case, carrier, mupcase...). Image does its own sound, so turn
; it off: the KERNAL's IRQ only calls it with initstat bit 0 set.
	lda initstat
	and #$fe
	sta initstat
	lda 788		; CINV
	ldx 789
	cmp #<irq_far	; setup runs again when im restarts: don't
	bne setirq1	; chain irq_far to itself
	cpx #>irq_far
	beq setirq2
setirq1:
	sta oldirq_vec
	stx oldirq_vec+1
	lda #<irq_far
	sta 788
	lda #>irq_far
	sta 789
setirq2:
	cli
	rts

;* initial setup of screen
;* colors/ clear/ etc
setscrn:
	lda #$00
	sta $d020
	lda #$00
	sta $d021
	lda #'{lowercase}'	; $0e
	jsr chrout
	lda #$0b	; 128: disable shift+C= (the C64 code sent $08)
	jsr chrout
	lda #'{white}'	; $05
	jsr chrout
	jsr makdate
	jmp dispdate

;* find BASIC variable
getvarp:
	txa
	asl
	tay
	lda varlist+1,y
	tax
	lda varlist,y
	sta varnam	; c64: $45
	stx varnam+1	; c64: $46
	jmp findvar1

; ********************************
; *     variables used by ml     *
; ********************************

varlist:
	byte $41, $ce         ;  0 an$
	byte $41, $80         ;  1 a$
	byte $42, $80         ;  2 b$
	byte $54, $d2         ;  3 tr$
	byte $44, $b1         ;  4 d1$
	byte $44, $b2         ;  5 d2$
	byte $44, $b3         ;  6 d3$
	byte $44, $b4         ;  7 d4$
	byte $44, $b5         ;  8 d5$
	byte $4c, $c4         ;  9 ld$
	byte $54, $d4         ; 10 tt$
	byte $4e, $c1         ; 11 na$
	byte $52, $ce         ; 12 rn$
	byte $50, $c8         ; 13 ph$
	byte $41, $cb         ; 14 ak$
	byte $4c, $50         ; 15 lp
	byte $50, $4c         ; 16 pl
	byte $52, $43         ; 17 rc
	byte $53, $48         ; 18 sh
	byte $4d, $57         ; 19 mw
	byte $4e, $4c         ; 20 nl
	byte $55, $4c         ; 21 ul
	byte $51, $45         ; 22 qe
	byte $52, $51         ; 23 rq
	byte $c1, $c3         ; 24 ac%
	byte $45, $46         ; 25 ef
	byte $4c, $46         ; 26 lf
	byte $57, $80         ; 27 w$
	byte $50, $80         ; 28 p$
	byte $d4, $d2         ; 29 tr%
	byte $c1, $80         ; 30 a%
	byte $c2, $80         ; 31 b$
	byte $c4, $d6         ; 32 dv%
	byte $44, $d2         ; 33 dr$
	byte $43, $b1         ; 34 c1$
	byte $43, $b2         ; 35 c2$
	byte $43, $cf         ; 36 co$
	byte $43, $c8         ; 37 ch$
	byte $cb, $d0         ; 38 kp%
	byte $43, $b3         ; 39 c3$
	byte $46, $b1         ; 40 f1$
	byte $46, $b2         ; 41 f2$
	byte $46, $b3         ; 42 f3$
	byte $46, $b4         ; 43 f4$
	byte $46, $b5         ; 44 f5$
	byte $46, $b6         ; 45 f6$
	byte $46, $b7         ; 46 f7$
	byte $46, $b8         ; 47 f8$
	byte $4d, $d0         ; 48 mp$
	byte $cd, $ce         ; 49 mn%

; find all vars used by ml,
; get their pointers

setptrs:
	lda #49	; counter for how many variables to process
	sta tmp1
setp1:
	ldx tmp1
	jsr getvarp
	lda tmp1
	asl
	tay
	sec
	lda varpnt	; c64: $47
	sbc vartab	; c64: $2d
	sta vars,y
	lda varpnt+1	; c64: $48
	sbc vartab+1	; c64: $2e
	sta vars+1,y
	dec tmp1
	bpl setp1
	rts

date2:
	ascii "Sat Aug 08, 2020 12:25 PM   "

copytran:
	ldy #0
copytran_loop1:
	lda tr1,y
	sta tblatc,y
	iny
	cpy #128
	bcc copytran_loop1
	ldy #0
copytran_loop2:
	lda tr2,y
	sta tblcta,y
	iny
	bne copytran_loop2
	ldy #0
copytran_loop3:
	lda tr3,y
	sta tblcta1,y
	lda tr4,y
	sta tblcta2,y
	lda tr5,y
	sta tblcta3,y
	iny
	cpy #32
	bcc copytran_loop3
	rts

; tblatc
tr1:
	byte $00,$00,$02,$00,$04,$00,$00,$00
	byte $14,$09,$00,$00,$93,$0d,$0e,$0f
	byte 0,$11,0,$13,20,$15,$16,$17,$18,$19,0,27,0,0,0,0
	ascii " !"
	byte 34
	ascii "#$%&'()*+,-./"
	ascii "0123456789:;<=>?"
	ascii "@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
	ascii "{pound}"
	ascii "]^_"
	byte 0
	ascii "abcdefghijklmnopqrstuvwxyz"
	byte 0,0,0,0,20

; tblcta
{alpha:ascii}	; .encoding "ascii"
tr2:
	byte $00, $01, $02, $03, $04, $05, $06, $07
	byte $08, $09, $0a, $0b, $0c, $0d, $00, $0f
	byte $10, $11, $12, $13, $08, $15, $16, $17
	byte $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
	ascii " !"
	byte 34
	ascii "#$%&'()*+,-./"
	ascii "0123456789:;<=>?"
	ascii "@abcdefghijklmnopqrstuvwxyz[\]^_"
	ascii "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*-!**"
	byte 0,129,0,0,0,0,0,0,0,0,0,0,0,$d,0,0
	byte 0,145,146,12,0,149,150,151,152,153,154,155,156,157,158,159
	ascii " !---!*!-*!****-"
	ascii "****!!!---******"
	ascii "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*!!**"
	ascii " !---!*!-*!****-"
	ascii "****!!!---******"
{alpha:normal}	; .encoding "petscii_mixed"

; tblcta1
tr3:
	byte 032,221,220,196,095,179,178,179
	byte 220,047,222,195,201,192,191,220
	byte 218,193,194,180,221,221,222,223
	byte 223,220,217,187,200,217,188,176

; tblcta2
tr4:
	byte 196,065,066,067,068,069,070,071
	byte 072,073,074,075,076,077,078,079
	byte 080,081,082,083,084,085,086,087
	byte 088,089,090,197,221,179,178,092

; tblcta3
tr5:
	byte 196,042,179,196,196,196,196,179
	byte 179,191,192,217,192,092,047,218
	byte 191,254,196,042,179,218,042,254
	byte 042,179,042,197,221,179,227,092

;* months and days
montbl0:
	ascii "JanFebMarAprMayJun"
	ascii "JulAugSepOctNovDec"
daytbl0:
	ascii "???SunMonTueWedThu"
	ascii "FriSat"
daysofm0:
	byte 31,28,31,30,31,30
	byte 31,31,30,31,30,31

date1fmt:
	ascii "Sat Dec  9, 2020"
	ascii " 12:00 AM EST   "

sndtbl0:

;(0) beep
	byte $00,$40,$10,$f0,$11
	byte $00,$00,$00,$00,$00
	byte $00,$00,$00,$00,$00
	byte $10
;(1) ding
	byte $44,$40,$0b,$00,$15
	byte $00,$00,$00,$00,$00
	byte $d8,$2a,$00,$00,$00
	byte $50
;(2) bell
	byte $00,$60,$09,$00,$11
	byte $00,$60,$09,$00,$11
	byte $00,$60,$09,$00,$11
	byte $20
;(3) bong
	byte $44,$10,$0d,$00,$15
	byte $30,$08,$0b,$00,$15
	byte $1c,$04,$0d,$00,$15
	byte $e0

startmsg:
	lda #1
	sta local
	ldx #0
	jsr setmode
	lda #5
	jsr usetbl1
	lda #bootvers_end - bootvers
	sta varbuf
	lda #<bootvers
	sta varbuf+1
	lda #>bootvers
	sta varbuf+2
	ldx #var_an_string
	jsr putvar
	ldx #var_an_string
	jmp prtvar0

bootvers:
	ascii "{clear} Image BBS 128 v"
	ascii {usedef:version_number}
	ascii " {pound}$a{f6}"
bootvers_end:


screentb:
	word $400+000,$d800+000
	word $400+040,$d800+040
	word $400+080,$d800+080
	word $400+120,$d800+120
	word $400+160,$d800+160
	word $400+200,$d800+200
	word $400+240,$d800+240
	word $400+280,$d800+280
	word $400+320,$d800+320
	word $400+360,$d800+360
	word $400+400,$d800+400
	word $400+440,$d800+440
	word $400+480,$d800+480
	word $400+520,$d800+520
	word $400+560,$d800+560
	word $400+600,$d800+600
	word tempscn0,tempcol0
	word tempscn1,tempcol1
	word tempscn2,tempcol2
	word tempscn3,tempcol3
	word tempscn4,tempcol4
	word tempscn5,tempcol5
	word tempscn6,tempcol6
	word tempscn7,tempcol7
	word $400+960,$d800+960

{ifdef:use_ltk}
lockinit:
	jsr ltk_bnkout
	lda ltk_activu
	pha
	lda ltk_activl
	pha
	lda #10
	jsr ltk_setlun
	lda #0
	sta ltk_activu
	jsr ltk_clrhdr
	ldy #0
lockinit_loop1:
	lda lockname,y
	beq lockint1
	sta filnam,y
	iny
	bne lockinit_loop1
lockint1:
	jsr ltk_fnfile
	bcs lkerror
	lda blmilo+1
	sta blkl_load+1
	lda blmilo+0
	sta blkh_load+1
	jsr ltk_getprt
	ora #$80
	sta port_load+1
lkerror:
	pla
	jsr ltk_setlun
	pla
	sta ltk_activu
	jsr ltk_bankin
	cli
	rts

lockname:
	ascii "lockfile"
	byte 0
{endif}
