; post.asm -- "++ post": the message bases' index, for i.SB and
; i/NM.netsub3 (a$="post":gosub 28, then &,16,x...): it loads a base's
; index just past itself, saves it, and finds a message in it by binary
; search, as ++ index does for u.index.
;
; Ported from the 3.0 release's "++ post" (MASTER D1 231231.d81, 6 blocks;
; "01/08/91  1:39A"), not from source/post.s: that is an older version
; ("03/22/90 01:08a", 1578 bytes against the release's 1472, with the
; serial-number copy check the release doesn't have). The release was
; disassembled by tools/ovl_dis.py (it reassembles at $c000 byte for
; byte), then ported on 2026-10-29 as index.asm was (the C64's values are
; in the comments):
; - runs at protostart ($1c00), where &,7,dv%,2 loads it; the index it
;   loads and saves starts at L_c5bf, its last byte (#<L_c5bf/#>L_c5bf;
;   c64 #$bf/#$c5)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63), its buffers
;   buf2 and buffer ($0e27, $0e77; c64 $ce27, $ce77), its & dispatcher
;   usetbl1 ($192a; c64 $cd03); index ($d00f) is the same on the 128
; - the KERNAL through the ML's ROM stubs, the ROM being out in cfg_ml;
;   setbnk before LOAD and SAVE: the index in bank 0, the filename (a$)
;   in bank 1 (the TODO's warning: without it the KERNAL read the name
;   from whatever bank the last setbnk left)
; - $fb/$fc stay: farcall puts them back (glue.asm)

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
L_c000:
	jmp L_c015
	byte $08
L_c004:
	byte $00
L_c005:
	byte $00
L_c006:
	byte $00
L_c007:
	byte $00
L_c008:
	byte $00
L_c009:
	byte $00
L_c00a:
	byte $50
L_c00b:
	byte $02
L_c00c:
	byte $00
L_c00d:
	byte $00,$01,$0d
L_c010:
	byte $00
L_c011:
	byte $00
L_c012:
	byte $00
L_c013:
	byte $00
L_c014:
	byte $0f
L_c015:
	cpx #$ff
	beq L_c06b
	txa
	beq L_c06e
	dex
	beq L_c044
	dex
	beq L_c047
	dex
	beq L_c04a
	dex
	beq L_c04d
	dex
	beq L_c050
	dex
	beq L_c053
	dex
	beq L_c056
	dex
	beq L_c059
	dex
	beq L_c05c
	dex
	beq L_c05f
	dex
	beq L_c062
	dex
	beq L_c065
	dex
	beq L_c068
	rts
L_c044:
	jmp L_c1c3
L_c047:
	jmp L_c1f7
L_c04a:
	jmp L_c23c
L_c04d:
	jmp L_c27a
L_c050:
	jmp L_c2d8
L_c053:
	jmp L_c322
L_c056:
	jmp L_c33f
L_c059:
	jmp L_c345
L_c05c:
	jmp L_c3b0
L_c05f:
	jmp L_c1e8
L_c062:
	jmp L_c532
L_c065:
	jmp L_c539
L_c068:
	jmp L_c53d
L_c06b:
	jmp L_c541
L_c06e:
	ldx #$00
	jsr L_c54d
	ldy #$00
L_c075:
	lda (varbuf+1),y	; c64: $62
	sta buffer,y	; c64: $ce77
	iny
	cpy varbuf	; c64: $61
	bcc L_c075
	lda #$00
	sta buffer,y	; c64: $ce77
	sty L_c1c2
	lda L_c5bf
	ldx L_c5c0
	sta L_c004
	stx L_c005
	lda #$00
	ldx #$01
	sta L_c006
	stx L_c007
	lda L_c006
	ldx L_c007
	sta L_c008
	stx L_c009
	jsr L_c14b
	beq L_c0db
	bcs L_c0b3
	jmp L_c24d
L_c0b3:
	lda L_c004
	ldx L_c005
	sta L_c008
	stx L_c009
	jsr L_c14b
	beq L_c0db
	bcc L_c0de
	lda L_c004
	ldx L_c005
	inx
	bne L_c0d2
	clc
	adc #$01
L_c0d2:
	sta L_c008
	stx L_c009
	jmp L_c24d
L_c0db:
	jmp L_c255
L_c0de:
	lda L_c006
	cmp L_c004
	bne L_c0f1
	lda L_c007
	cmp L_c005
	bne L_c0f1
	jmp L_c24d
L_c0f1:
	clc
	lda L_c007
	adc L_c005
	sta L_c009
	lda L_c006
	adc L_c004
	sta L_c008
	lsr L_c008
	ror L_c009
	lda L_c008
	cmp L_c006
	bne L_c12c
	lda L_c009
	cmp L_c007
	bne L_c12c
	lda L_c004
	ldx L_c005
	sta L_c006
	stx L_c007
	sta L_c008
	stx L_c009
L_c12c:
	jsr L_c14b
	beq L_c0db
	lda L_c008
	ldx L_c009
	bcc L_c142
	sta L_c006
	stx L_c007
	jmp L_c0de
L_c142:
	sta L_c004
	stx L_c005
	jmp L_c0de
L_c14b:
	jsr L_c169
	lda L_c343
	sta L_c344
	beq L_c159
L_c156:
	dec L_c344
L_c159:
	ldx L_c00b
	ldy #$00
	jsr L_c557
	lda L_c344
	bne L_c156
	jmp L_c1a6
L_c169:
	jsr L_c183
L_c16c:
	ldx L_c014
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	ldy #$00
	ldx #$06
L_c176:
	lda L_c00a,y
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	iny
	dex
	bne L_c176
	jmp clrchn	; c64: $ffcc (the ROM is out in cfg_ml)
L_c183:
	lda L_c009
	asl
	tay
	lda L_c008
	rol
	tax
	clc
	tya
	adc #<L_c5bf	; c64: #$bf
	sta $fb
	txa
	adc #>L_c5bf	; c64: #$c5
	sta $fc
	ldy #$00
	lda ($fb),y
	sta L_c00d
	iny
	lda ($fb),y
	sta L_c00c
	rts
L_c1a6:
	ldy #$00
L_c1a8:
	lda buffer,y	; c64: $ce77
	cmp buf2,y	; c64: $ce27
	bne L_c1c1
	iny
	cpy L_c1c2
	beq L_c1bb
	cpy index	; c64: $d00f, the same on the 128
	bne L_c1a8
L_c1bb:
	ldy L_c1c2
	cpy index	; c64: $d00f, the same on the 128
L_c1c1:
	rts
L_c1c2:
	byte $00
L_c1c3:
	ldx #$01
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd (the ROM is out in cfg_ml)
	ldx #$20
	jsr L_c54d
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #$00
	ldx #<L_c5bf	; c64: #$bf
	ldy #>L_c5bf	; c64: #$c5
	jsr loadf	; c64: $ffd5 (the ROM is out in cfg_ml)
L_c1e8:
	lda L_c5bf
	ldx L_c5c0
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1e
	jmp L_c55c
L_c1f7:
	ldx #$01
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd (the ROM is out in cfg_ml)
	ldx #$20
	jsr L_c54d
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #<L_c5bf	; c64: #$bf
	ldx #>L_c5bf	; c64: #$c5
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	lda L_c5c0
	asl
	tax
	lda L_c5bf
	rol
	tay
	clc
	txa
	adc #<L_c5bf	; c64: #$bf
	tax
	tya
	adc #>L_c5bf	; c64: #$c5
	tay
	clc
	txa
	adc #$03
	tax
	tya
	adc #$00
	tay
	lda #varbuf	; the start pointer for SAVE (c64: #$61)
	jmp savef	; c64: $ffd8 (the ROM is out in cfg_ml)
L_c23c:
	lda #$00
	sta L_c5bf
	sta L_c5c1
	lda #$00
	sta L_c5c0
	sta L_c5c2
	rts
L_c24d:
	lda #$00
	sta L_c00c
	sta L_c00d
L_c255:
	lda L_c00d
	ldx L_c00c
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1e
	jsr L_c55c
	lda L_c008
	ldx L_c009
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1f
	jsr L_c55c
	lda L_c00c
	ora L_c00d
	rts
L_c27a:
	ldx #$1f
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
	inc L_c5c0
	bne L_c291
	inc L_c5bf
L_c291:
	ldx #$1e
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c00d
	stx L_c00c
L_c2a0:
	lda L_c00c
	ldx L_c00d
	sta L_c005
	stx L_c004
	jsr L_c183
	ldy #$00
	lda L_c004
	sta ($fb),y
	iny
	lda L_c005
	sta ($fb),y
	lda L_c009
	cmp L_c5c0
	bne L_c2cd
	lda L_c008
	cmp L_c5bf
	bne L_c2cd
	rts
L_c2cd:
	inc L_c009
	bne L_c2d5
	inc L_c008
L_c2d5:
	jmp L_c2a0
L_c2d8:
	ldx #$1f
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
L_c2e7:
	lda L_c008
	cmp L_c5bf
	bne L_c2f7
	lda L_c009
	cmp L_c5c0
	beq L_c316
L_c2f7:
	jsr L_c183
	ldy #$03
	lda ($fb),y
	pha
	dey
	lda ($fb),y
	tax
	dey
	pla
	sta ($fb),y
	dey
	txa
	sta ($fb),y
	inc L_c009
	bne L_c313
	inc L_c008
L_c313:
	jmp L_c2e7
L_c316:
	lda L_c5c0
	bne L_c31e
	dec L_c5bf
L_c31e:
	dec L_c5c0
	rts
L_c322:
	ldx #$1f
	jsr L_c54d
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
	inc L_c009
	bne L_c339
	inc L_c008
L_c339:
	jsr L_c183
	jmp L_c255
L_c33f:
	sty L_c343
	rts
L_c343:
	byte $00
L_c344:
	byte $00
L_c345:
	jsr L_c23c
	ldx #$1f
	jsr L_c54d
	lda varbuf+1	; c64: $62
	sta L_c00c
	lda varbuf	; c64: $61
	sta L_c00d
	lda #<L_c5bf	; c64: #$bf
	sta $fb
	lda #>L_c5bf	; c64: #$c5
	sta $fc
L_c35f:
	jsr L_c16c
	ldx L_c00b
	ldy #$03
	jsr L_c557
	lda buf2	; c64: $ce27
	sta L_c00c
	lda buf2+1	; c64: $ce28
	sta L_c00d
	ldy buf2+2	; c64: $ce29
	sty L_c006
	ldx L_c00b
	cpy #$00
	beq L_c39f
	jsr L_c557
	ldy #$00
L_c388:
	lda buf2,y	; c64: $ce27
	sta ($fb),y
	iny
	cpy L_c006
	bne L_c388
	lda $fb
	clc
	adc L_c006
	sta $fb
	bcc L_c39f
	inc $fc
L_c39f:
	lda L_c00c
	cmp #$00
	bne L_c35f
	lda L_c00d
	cmp #$00
	bne L_c35f
	jmp L_c1e8
L_c3b0:
	ldx #$1e
	jsr L_c54d
	lda varbuf+1	; c64: $62
	sta L_c010
	sta L_c00c
	lda varbuf	; c64: $61
	sta L_c011
	sta L_c00d
	jsr L_c16c
	ldx #$01
	jsr L_c552
	jsr L_c16c
	ldx L_c00b
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	lda #$00
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr L_c16c
	ldx #$1f
	jsr L_c54d
	lda varbuf+1	; c64: $62
	sta L_c00c
	lda varbuf	; c64: $61
	sta L_c00d
	lda #<L_c5bf	; c64: #$bf
	sta L_c4cb+1
	lda #>L_c5bf	; c64: #$c5
	sta L_c4cb+2
	lda L_c5c0
	asl
	tax
	lda L_c5bf
	rol
	tay
	clc
	txa
	adc #<L_c5bf	; c64: #$bf
	tax
	tya
	adc #>L_c5bf	; c64: #$c5
	tay
	clc
	txa
	adc #$02
	sta L_c006
	tya
	adc #$00
	sta L_c007
L_c422:
	jsr L_c16c
	ldx L_c00b
	ldy #$02
	jsr L_c557
	jsr L_c16c
	lda L_c00c
	sta L_c012
	lda L_c00d
	sta L_c013
	ldx #$01
	jsr L_c552
	jsr L_c16c
	lda L_c00c
	sta varbuf+1	; c64: $62
	lda L_c00d
	sta varbuf	; c64: $61
	ldx #$1f
	jsr L_c55c
	lda buf2	; c64: $ce27
	sta L_c00c
	lda buf2+1	; c64: $ce28
	sta L_c00d
	cmp #$00
	bne L_c4c9
	lda L_c00c
	cmp #$00
	bne L_c4c9
	lda L_c010
	sta buf2	; c64: $ce27
	lda L_c011
	sta buf2+1	; c64: $ce28
	inc L_c010
	bne L_c47e
	inc L_c011
L_c47e:
	lda L_c010
	sta L_c00c
	lda L_c011
	sta L_c00d
	jsr L_c16c
	ldx L_c00b
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	lda #$00
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr L_c16c
	lda L_c012
	sta L_c00c
	lda L_c013
	sta L_c00d
	jsr L_c16c
	ldx #$01
	jsr L_c552
	jsr L_c16c
	lda buf2	; c64: $ce27
	sta L_c00c
	lda buf2+1	; c64: $ce28
	sta L_c00d
L_c4c9:
	ldy #$00
L_c4cb:
	lda $ffff	; the address is put here (L_c4cb+1/+2): self-modifying
	sta buf2+3,y	; c64: $ce2a
	iny
	inc L_c4cb+1
	bne L_c4da
	inc L_c4cb+2
L_c4da:
	lda L_c4cb+1
	cmp L_c006
	bne L_c4fb
	lda L_c4cb+2
	cmp L_c007
	bne L_c4fb
	lda #$00
	sta L_c00c
	sta L_c00d
	sta buf2	; c64: $ce27
	sta buf2+1	; c64: $ce28
	jmp L_c4ff
L_c4fb:
	cpy #$4c
	bne L_c4cb
L_c4ff:
	sty buf2+2	; c64: $ce29
	iny
	iny
	iny
	sty L_c004
	ldy #$00
	ldx L_c00b
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
L_c510:
	lda buf2,y	; c64: $ce27
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	iny
	cpy L_c004
	bne L_c510
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr clrchn	; c64: $ffcc (the ROM is out in cfg_ml)
	lda L_c00c
	bne L_c52f
	lda L_c00d
	bne L_c52f
	rts
L_c52f:
	jmp L_c422
L_c532:
	lda #$3b
	ldx #$00
	jmp usetbl1	; c64: $cd03
L_c539:
	sty L_c014
	rts
L_c53d:
	sty L_c00b
	rts
L_c541:
	jsr L_c561
	lda #$08
	sta varbuf+1	; c64: $62
	ldx #$1e
	jmp L_c55c
L_c54d:
	lda #$1d
	jmp usetbl1	; c64: $cd03
L_c552:
	lda #$16
	jmp usetbl1	; c64: $cd03
L_c557:
	lda #$02
	jmp usetbl1	; c64: $cd03
L_c55c:
	lda #$1e
	jmp usetbl1	; c64: $cd03
L_c561:
	lda #$1f
	jmp usetbl1	; c64: $cd03
	byte $a9,$20,$4c,$03,$cd,$a9,$03,$4c
	byte $03,$cd,$30,$31,$2f,$30,$38,$2f
	byte $39,$31,$20,$20,$31,$3a,$33,$39
	byte $41,$0d,$d4,$c8,$c5,$d2,$c5,$27
	byte $d3,$20,$ce,$cf,$20,$ce,$c5,$c5
	byte $c4,$20,$d4,$cf,$20,$c6,$c5,$c1
	byte $d2,$2e,$2e,$2e,$d5,$ce,$c4,$c5
	byte $d2,$c4,$cf,$c7,$0d,$c9,$d3,$20
	byte $c8,$c5,$d2,$c5,$21,$0d,$c3,$4f
	byte $50,$52,$2e,$31,$39,$39,$30,$20
	byte $ce,$45,$57,$20,$c9,$4d,$41,$47
	byte $45
L_c5bf:
	byte $00
L_end:
L_c5c0 = L_end + 0	; past the end: a variable
L_c5c1 = L_end + 1	; past the end: a variable
L_c5c2 = L_end + 2	; past the end: a variable

