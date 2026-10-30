; read.asm -- "++ read": Image's file reader. i.RF (the idle screen's D),
; i.UD, i.UX, i.DX, i.CP v3.1, i.t, i/SM.lk util and sub.local load it with
; a$="read":gosub 28 and call it with &,16,x,y.
;
; No source survives: disassembled from the 3.0 release's "++ read" (MASTER
; D1 231231.d81, 11 blocks) by tools/ovl_dis.py, with --label at the eight
; strings and tables the code points at (that reassembles at $c000 byte for
; byte), then ported on 2026-10-29 (the C64's values are in the comments),
; as index.asm was:
; - runs at protostart ($1c00), where &,7,dv%,2 loads it; its pointers to
;   its own strings and tables are #<label/#>label (c64 #$c0-#$ca)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63), its buffers
;   buf2 and buffer ($0e27, $0e77; c64 $ce27, $ce77), its & dispatcher
;   usetbl1 ($192a; c64 $cd03); 10/29/2026: also the six pointers to buf2
;   and buffer it builds from immediates (#<buf2/#>buf2; c64 #$27/#$ce),
;   which ovl_dis.py didn't flag: the lines came out as commas
; - the KERNAL (READST, CHKIN, GETIN) through the ML's ROM stubs, the ROM
;   being out in cfg_ml
; - $fb/$fc stay: farcall puts them back (glue.asm)

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
L_c000:
	jmp L_c01d
	byte $06
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
	byte $00
L_c00b:
	byte $00
L_c00c:
	byte $00
L_c00d:
	byte $00
L_c00e:
	byte $00
L_c00f:
	byte $00
L_c010:
	byte $00
L_c011:
	byte $00
L_c012:
	byte $8b,$cd,$cc,$20,$d4,$41,$49,$4c
	byte $3a,$8b,$8b
L_c01d:
	cpx #$ff
	bne L_c02d
	jsr L_ca36
	lda #$06
	sta varbuf+1	; c64: $62
	ldx #$1e
	jmp L_ca2a
L_c02d:
	stx L_c004
	lda #$08
	sta L_c011
	tya
	beq L_c043
	sec
	sbc #$08
	and #$fc
	clc
	ror
	ror
	sta L_c011
L_c043:
	lda #$00
	sta L_c007
	sta L_c00a
	sta L_c010
	sta L_c00d
	sta L_c00e
	sta L_c00f
	ldx #$02
	jsr chkin	; c64: $ffc6 (the ROM is out in cfg_ml)
	jsr L_c87c
	sta L_c008
	jsr L_c87c
	sta L_c009
	lda L_c009
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda L_c8af,y
	sta L_c86e
	lda L_c009
	and #$0f
	tay
	lda L_c8af,y
	sta L_c86f
	lda L_c008
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda L_c8af,y
	sta L_c870
	lda L_c008
	and #$0f
	tay
	lda L_c8af,y
	sta L_c871
	lda #<L_c85a	; c64: #$5a
	sta varbuf+1	; c64: $62
	lda #>L_c85a	; c64: #$c8
	sta varbuf+2	; c64: $63
	lda #$1a
	sta varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	lda L_c008
	cmp #$01
	bne L_c0c7
	lda L_c009
	cmp #$08
	bne L_c0c7
	jmp L_c0fd
L_c0c7:
	lda L_c008
	cmp #$01
	bne L_c0d8
	lda L_c009
	cmp #$1c
	bne L_c0d8
	jmp L_c0fd
L_c0d8:
	lda L_c008
	cmp #$01
	bne L_c0e9
	lda L_c009
	cmp #$40
	bne L_c0e9
	jmp L_c0fd
L_c0e9:
	lda L_c008
	cmp #$01
	bne L_c0fa
	lda L_c009
	cmp #$04
	bne L_c0fa
	jmp L_c0fd
L_c0fa:
	jmp L_c8bf
L_c0fd:
	lda L_c009
	pha
	lda L_c008
	pha
	ldx #$10
	jsr L_ca2f
	ldx #$1e
	jsr L_ca20
	lda varbuf+1	; c64: $62
	beq L_c139
	lda #$01
	sta L_c010
	ldx #$12
	jsr L_ca2f
	ldx #$1e
	jsr L_ca20
	lda varbuf+1	; c64: $62
	beq L_c139
	ldx #$13
	jsr L_ca2f
	ldx #$1e
	jsr L_ca20
	lda varbuf+1	; c64: $62
	beq L_c139
	lda #$00
	sta L_c010
L_c139:
	lda L_c010
	ora L_c004
	sta L_c010
L_c142:
	lda L_c00a
	beq L_c14c
	pla
	pla
	jmp L_ca11
L_c14c:
	jsr L_c87c
	sta L_c008
	jsr L_c87c
	sta L_c009
	cmp #$00
	bne L_c1a4
	lda L_c008
	cmp #$00
	bne L_c1a4
	lda L_c00a
	beq L_c16d
	pla
	pla
	jmp L_ca11
L_c16d:
	lda #<L_c012	; c64: #$12
	sta varbuf+1	; c64: $62
	lda #>L_c012	; c64: #$c0
	sta varbuf+2	; c64: $63
	lda #$0b
	sta varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	pla
	clc
	adc L_c00d
	sta L_c008
	pla
	adc L_c00e
	sta L_c009
	lda L_c008
	sec
	sbc #$02
	sta L_c008
	lda L_c009
	sbc #$00
	sta L_c009
	jmp L_c8bf
L_c1a4:
	jsr L_c87c
	sta L_c008
	jsr L_c87c
	sta L_c009
	lda L_c008
	sta varbuf+1	; c64: $62
	lda L_c009
	sta varbuf	; c64: $61
	ldx #$1e
	jsr L_ca2a
	lda #<L_c875	; c64: #$75
	sta varbuf+1	; c64: $62
	lda #>L_c875	; c64: #$c8
	sta varbuf+2	; c64: $63
	lda #$07
	sta varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
L_c1d3:
	jsr L_c87c
	sta L_c004
	cmp #$00
	bne L_c1fe
	lda #$8b
	sta buf2	; c64: $ce27
	lda #$01
	sta varbuf	; c64: $61
	lda #<buf2	; c64: #$27
	sta varbuf+1	; c64: $62
	lda #>buf2	; c64: #$ce
	sta varbuf+2	; c64: $63
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	lda #$00
	sta L_c007
	jmp L_c142
L_c1fe:
	and #$80
	bne L_c205
	jmp L_c29d
L_c205:
	lda L_c007
	beq L_c20d
	jmp L_c29d
L_c20d:
	lda L_c004
	cmp #$ce
	bne L_c227
	jsr L_c87c
	sta L_c004
	lda #<L_c82a	; c64: #$2a
	sta $fb
	lda #>L_c82a	; c64: #$c8
	sta $fc
	ldx #$02
	jmp L_c248
L_c227:
	cmp #$fe
	bne L_c23e
	jsr L_c87c
	sta L_c004
	lda #<L_c76b	; c64: #$6b
	sta $fb
	lda #>L_c76b	; c64: #$c7
	sta $fc
	ldx #$02
	jmp L_c248
L_c23e:
	lda #<L_c578	; c64: #$78
	sta $fb
	lda #>L_c578	; c64: #$c5
	sta $fc
	ldx #$80
L_c248:
	cpx L_c004
	bne L_c250
	jmp L_c26f
L_c250:
	inc $fb
	lda $fb
	bne L_c258
	inc $fc
L_c258:
	ldy #$00
	lda ($fb),y
	and #$80
	bne L_c26b
	inc $fb
	lda $fb
	bne L_c258
	inc $fc
	jmp L_c258
L_c26b:
	inx
	jmp L_c248
L_c26f:
	ldy #$00
	lda ($fb),y
	and #$7f
	sta buf2,y	; c64: $ce27
	iny
L_c279:
	lda ($fb),y
	and #$80
	bne L_c288
	lda ($fb),y
	sta buf2,y	; c64: $ce27
	iny
	jmp L_c279
L_c288:
	sty varbuf	; c64: $61
	lda #<buf2	; c64: #$27
	sta varbuf+1	; c64: $62
	lda #>buf2	; c64: #$ce
	sta varbuf+2	; c64: $63
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	jmp L_c1d3
L_c29d:
	jsr L_c2a3
	jmp L_c288
L_c2a3:
	lda L_c004
	sta buf2	; c64: $ce27
	cmp #$22
	bne L_c2b8
	lda L_c007
	eor #$01
	sta L_c007
	jmp L_c336
L_c2b8:
	cmp #$5c
	bne L_c2c4
	lda #$5c
	sta buf2+1	; c64: $ce28
	ldy #$02
	rts
L_c2c4:
	ldy #$00
L_c2c6:
	cmp L_c508,y
	beq L_c2d3
	iny
	cpy #$38
	bne L_c2c6
	jmp L_c318
L_c2d3:
	lda L_c010
	beq L_c305
	lda #<L_c34c	; c64: #$4c
	sta $fb
	lda #>L_c34c	; c64: #$c3
	sta $fc
	tya
	tax
L_c2e2:
	ldy #$00
	cpx #$00
	beq L_c2fa
L_c2e8:
	inc $fb
	lda $fb
	bne L_c2f0
	inc $fc
L_c2f0:
	lda ($fb),y
	cmp #$5b
	bne L_c2e8
	dex
	jmp L_c2e2
L_c2fa:
	lda ($fb),y
	sta buf2,y	; c64: $ce27
	iny
	cmp #$5d
	bne L_c2fa
	rts
L_c305:
	lda L_c540,y
	sta buf2+1	; c64: $ce28
	lda #$12
	sta buf2	; c64: $ce27
	lda #$92
	sta buf2+2	; c64: $ce29
	ldy #$03
	rts
L_c318:
	cmp #$1c
	bne L_c336
	lda L_c010
	bne L_c339
	lda #$12
	sta buf2	; c64: $ce27
	lda #$5c
	sta buf2+1	; c64: $ce28
	sta buf2+2	; c64: $ce29
	lda #$92
	sta buf2+3	; c64: $ce2a
	ldy #$04
	rts
L_c336:
	ldy #$01
	rts
L_c339:
	ldy #$00
L_c33b:
	lda L_c347,y
	sta buf2,y	; c64: $ce27
	iny
	cpy #$05
	bne L_c33b
	rts
L_c347:
	byte $5b,$d2,$45,$44,$5d
L_c34c:
	byte $5b,$c3,$54,$52,$4c,$2d,$41,$5d
	byte $5b,$c3,$54,$52,$4c,$2d,$42,$5d
	byte $5b,$c3,$54,$52,$4c,$2d,$43,$5d
	byte $5b,$c3,$54,$52,$4c,$2d,$44,$5d
	byte $5b,$d7,$48,$49,$54,$45,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$46,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$47,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$48,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$49,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$4a,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$4b,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$4c,$5d,$5b
	byte $d2,$45,$54,$55,$52,$4e,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$4e,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$4f,$5d,$5b
	byte $c3,$54,$52,$4c,$2d,$50,$5d,$5b
	byte $c3,$52,$53,$52,$20,$c4,$57,$4e
	byte $5d,$5b,$d2,$45,$56,$20,$cf,$4e
	byte $5d,$5b,$c8,$4f,$4d,$45,$5d,$5b
	byte $c2,$41,$43,$4b,$53,$50,$41,$43
	byte $45,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $55,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $56,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $57,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $58,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $59,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $5a,$5d,$5b,$c6,$31,$5d,$5b,$c6
	byte $33,$5d,$5b,$c6,$35,$5d,$5b,$c6
	byte $37,$5d,$5b,$c6,$32,$5d,$5b,$c6
	byte $34,$5d,$5b,$c6,$36,$5d,$5b,$c6
	byte $38,$5d,$5b,$c3,$52,$53,$52,$20
	byte $d5,$50,$5d,$5b,$c3,$52,$53,$52
	byte $20,$cc,$45,$46,$54,$5d,$5b,$c3
	byte $52,$53,$52,$20,$d2,$49,$47,$48
	byte $54,$5d,$5b,$c3,$54,$52,$4c,$2d
	byte $ce,$5d,$5b,$c2,$4c,$41,$43,$4b
	byte $5d,$5b,$c3,$59,$41,$4e,$5d,$5b
	byte $d0,$55,$52,$50,$4c,$45,$5d,$5b
	byte $c7,$52,$45,$45,$4e,$5d,$5b,$c2
	byte $4c,$55,$45,$5d,$5b,$d9,$45,$4c
	byte $4c,$4f,$57,$5d,$5b,$d2,$45,$56
	byte $20,$cf,$46,$46,$5d,$5b,$cf,$52
	byte $41,$4e,$47,$45,$5d,$5b,$c2,$52
	byte $4f,$57,$4e,$5d,$5b,$cc,$54,$2e
	byte $20,$d2,$45,$44,$5d,$5b,$c4,$41
	byte $52,$4b,$20,$c7,$52,$41,$59,$5d
	byte $5b,$cd,$45,$44,$2e,$20,$c7,$52
	byte $41,$59,$5d,$5b,$cc,$54,$2e,$20
	byte $c7,$52,$45,$45,$4e,$5d,$5b,$cc
	byte $54,$2e,$20,$c2,$4c,$55,$45,$5d
	byte $5b,$cc,$54,$2e,$20,$c7,$52,$41
	byte $59,$5d,$5b,$c3,$4c,$45,$41,$52
	byte $2f,$c8,$4f,$4d,$45,$5d,$5b,$c3
	byte $54,$52,$4c,$2d,$40,$5d,$5b,$d3
	byte $48,$49,$46,$54,$2d,$d2,$45,$54
	byte $55,$52,$4e,$5d
L_c508:
	byte $01,$02,$03,$04,$05,$06,$07,$08
	byte $09,$0a,$0b,$0c,$0d,$0e,$0f,$10
	byte $11,$12,$13,$14,$15,$16,$17,$18
	byte $19,$1a,$85,$86,$87,$88,$89,$8a
	byte $8b,$8c,$91,$1d,$9d,$8e,$90,$9f
	byte $9c,$1e,$1f,$9e,$92,$81,$95,$96
	byte $97,$98,$99,$9a,$9b,$93,$00,$8d
L_c540:
	byte $41,$42,$43,$44,$45,$46,$47,$48
	byte $49,$4a,$4b,$4c,$4d,$4e,$4f,$50
	byte $51,$52,$53,$54,$55,$56,$57,$58
	byte $59,$5a,$c5,$c6,$c7,$c8,$c9,$ca
	byte $cb,$cc,$d1,$5d,$dd,$ce,$d0,$df
	byte $dc,$5e,$5f,$a6,$d2,$c1,$d5,$d6
	byte $d7,$d8,$d9,$da,$db,$d3,$40,$cd
L_c578:
	byte $c5,$4e,$44,$c6,$4f,$52,$ce,$45
	byte $58,$54,$c4,$41,$54,$41,$c9,$4e
	byte $50,$55,$54,$23,$c9,$4e,$50,$55
	byte $54,$c4,$49,$4d,$d2,$45,$41,$44
	byte $cc,$45,$54,$c7,$4f,$54,$4f,$d2
	byte $55,$4e,$c9,$46,$d2,$45,$53,$54
	byte $4f,$52,$45,$c7,$4f,$53,$55,$42
	byte $d2,$45,$54,$55,$52,$4e,$d2,$45
	byte $4d,$d3,$54,$4f,$50,$cf,$4e,$d7
	byte $41,$49,$54,$cc,$4f,$41,$44,$d3
	byte $41,$56,$45,$d6,$45,$52,$49,$46
	byte $59,$c4,$45,$46,$d0,$4f,$4b,$45
	byte $d0,$52,$49,$4e,$54,$23,$d0,$52
	byte $49,$4e,$54,$c3,$4f,$4e,$54,$cc
	byte $49,$53,$54,$c3,$4c,$52,$c3,$4d
	byte $44,$d3,$59,$53,$cf,$50,$45,$4e
	byte $c3,$4c,$4f,$53,$45,$c7,$45,$54
	byte $ce,$45,$57,$d4,$41,$42,$28,$d4
	byte $4f,$c6,$4e,$d3,$50,$43,$28,$d4
	byte $48,$45,$4e,$ce,$4f,$54,$d3,$54
	byte $45,$50,$ab,$ad,$aa,$af,$de,$c1
	byte $4e,$44,$cf,$52,$be,$bd,$bc,$d3
	byte $47,$4e,$c9,$4e,$54,$c1,$42,$53
	byte $d5,$53,$52,$c6,$52,$45,$d0,$4f
	byte $53,$d3,$51,$52,$d2,$4e,$44,$cc
	byte $4f,$47,$c5,$58,$50,$c3,$4f,$53
	byte $d3,$49,$4e,$d4,$41,$4e,$c1,$54
	byte $4e,$d0,$45,$45,$4b,$cc,$45,$4e
	byte $d3,$54,$52,$24,$d6,$41,$4c,$c1
	byte $53,$43,$c3,$48,$52,$24,$cc,$45
	byte $46,$54,$24,$d2,$49,$47,$48,$54
	byte $24,$cd,$49,$44,$24,$c7,$4f,$d2
	byte $47,$52,$d2,$43,$4c,$52,$ce,$ca
	byte $4f,$59,$d2,$44,$4f,$54,$c4,$45
	byte $43,$c8,$45,$58,$24,$c5,$52,$52
	byte $24,$c9,$4e,$53,$54,$52,$c5,$4c
	byte $53,$45,$d2,$45,$53,$55,$4d,$45
	byte $d4,$52,$41,$50,$d4,$52,$4f,$4e
	byte $d4,$52,$4f,$46,$46,$d3,$4f,$55
	byte $4e,$44,$d6,$4f,$4c,$c1,$55,$54
	byte $4f,$d0,$55,$44,$45,$46,$c7,$52
	byte $41,$50,$48,$49,$43,$d0,$41,$49
	byte $4e,$54,$c3,$48,$41,$52,$c2,$4f
	byte $58,$c3,$49,$52,$43,$4c,$45,$c7
	byte $53,$48,$41,$50,$45,$d3,$53,$48
	byte $41,$50,$45,$c4,$52,$41,$57,$cc
	byte $4f,$43,$41,$54,$45,$c3,$4f,$4c
	byte $4f,$52,$d3,$43,$4e,$43,$4c,$52
	byte $d3,$43,$41,$4c,$45,$c8,$45,$4c
	byte $50,$c4,$4f,$cc,$4f,$4f,$50,$c5
	byte $58,$49,$54,$c4,$49,$52,$45,$43
	byte $54,$4f,$52,$59,$c4,$53,$41,$56
	byte $45,$c4,$4c,$4f,$41,$44,$c8,$45
	byte $41,$44,$45,$52,$d3,$43,$52,$41
	byte $54,$43,$48,$c3,$4f,$4c,$4c,$45
	byte $43,$54,$c3,$4f,$50,$59,$d2,$45
	byte $4e,$41,$4d,$45,$c2,$41,$43,$4b
	byte $55,$50,$c4,$45,$4c,$45,$54,$45
	byte $d2,$45,$4e,$55,$4d,$42,$45,$52
	byte $cb,$45,$59,$cd,$4f,$4e,$49,$54
	byte $4f,$52,$d5,$53,$49,$4e,$47,$d5
	byte $4e,$54,$49,$4c,$d7,$48,$49,$4c
	byte $45,$fe,$3f
L_c76b:
	byte $c2,$41,$4e,$4b,$c6,$49,$4c,$54
	byte $45,$52,$d0,$4c,$41,$59,$d4,$45
	byte $4d,$50,$4f,$cd,$4f,$56,$53,$50
	byte $52,$d3,$50,$52,$49,$54,$45,$d3
	byte $50,$52,$43,$4f,$4c,$4f,$52,$d2
	byte $52,$45,$47,$c5,$4e,$56,$45,$4c
	byte $4f,$50,$45,$d3,$4c,$45,$45,$50
	byte $c3,$41,$54,$41,$4c,$4f,$47,$c4
	byte $4f,$50,$45,$4e,$c1,$50,$50,$45
	byte $4e,$44,$c4,$43,$4c,$4f,$53,$45
	byte $c2,$53,$41,$56,$45,$c2,$4c,$4f
	byte $41,$44,$d2,$45,$43,$4f,$52,$44
	byte $c3,$4f,$4e,$43,$41,$54,$c4,$56
	byte $45,$52,$49,$46,$59,$c4,$43,$4c
	byte $45,$41,$52,$d3,$50,$52,$53,$41
	byte $56,$c3,$4f,$4c,$4c,$49,$53,$49
	byte $4f,$4e,$c2,$45,$47,$49,$4e,$c2
	byte $45,$4e,$44,$d7,$49,$4e,$44,$4f
	byte $57,$c2,$4f,$4f,$54,$d7,$49,$44
	byte $54,$48,$d3,$50,$52,$44,$45,$46
	byte $d1,$55,$49,$54,$d3,$54,$41,$53
	byte $48,$ff,$c6,$45,$54,$43,$48,$ff
	byte $d3,$57,$41,$50,$cf,$46,$46,$c6
	byte $41,$53,$54,$d3,$4c,$4f,$57
L_c82a:
	byte $d0,$4f,$54,$c2,$55,$4d,$50,$d0
	byte $45,$4e,$d2,$53,$50,$50,$4f,$53
	byte $d2,$53,$50,$52,$49,$54,$45,$d2
	byte $53,$50,$43,$4f,$4c,$4f,$52,$d8
	byte $4f,$52,$d2,$57,$49,$4e,$44,$4f
	byte $57,$d0,$4f,$49,$4e,$54,$45,$52
L_c85a:
	byte $93,$5c,$51,$30,$8b,$cc,$4f,$41
	byte $44,$20,$c1,$44,$44,$52,$45,$53
	byte $53,$3a,$20,$24
L_c86e:
	byte $30
L_c86f:
	byte $30
L_c870:
	byte $30
L_c871:
	byte $30,$8b,$8b,$00
L_c875:
	byte $5c,$23,$30,$5c,$25,$41,$20
L_c87c:
	jsr getin	; c64: $ffe4 (the ROM is out in cfg_ml)
	pha
	jsr readst	; c64: $ffb7 (the ROM is out in cfg_ml)
	and #$40
	beq L_c88c
	lda #$ff
	sta L_c00a
L_c88c:
	ldx #$1d
	jsr L_ca20
	lda varbuf+1	; c64: $62
	bne L_c89a
	lda #$ff
	sta L_c00a
L_c89a:
	inc L_c00d
	lda L_c00d
	bne L_c8ad
	inc L_c00e
	lda L_c00e
	bne L_c8ad
	inc L_c00f
L_c8ad:
	pla
	rts
L_c8af:
	byte $30,$31,$32,$33,$34,$35,$36,$37
	byte $38,$39,$c1,$c2,$c3,$c4,$c5,$c6
L_c8bf:
	lda #$00
	sta L_c005
	sta L_c006
	sta L_c010
	lda #<buffer	; c64: #$77
	sta L_c00b
	lda #>buffer	; c64: #$ce
	sta L_c00c
	lda L_c009
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda L_c8af,y
	sta buf2	; c64: $ce27
	lda L_c009
	and #$0f
	tay
	lda L_c8af,y
	sta buf2+1	; c64: $ce28
	lda L_c008
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda L_c8af,y
	sta buf2+2	; c64: $ce29
	lda L_c008
	and #$0f
	tay
	lda L_c8af,y
	sta buf2+3	; c64: $ce2a
	lda #$3a
	sta buf2+4	; c64: $ce2b
	lda #$20
	sta buf2+5	; c64: $ce2c
	lda #<buf2	; c64: #$27
	sta varbuf+1	; c64: $62
	lda #>buf2	; c64: #$ce
	sta varbuf+2	; c64: $63
	lda #$06
	sta varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
L_c92c:
	lda L_c00a
	beq L_c941
	lda #$20
	sta L_c004
	lda #$20
	sta buf2	; c64: $ce27
	sta buf2+1	; c64: $ce28
	jmp L_c961
L_c941:
	jsr L_c87c
	sta L_c004
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda L_c8af,y
	sta buf2	; c64: $ce27
	lda L_c004
	and #$0f
	tay
	lda L_c8af,y
	sta buf2+1	; c64: $ce28
L_c961:
	lda #$20
	sta buf2+2	; c64: $ce29
	lda #$03
	sta varbuf	; c64: $61
	lda #<buf2	; c64: #$27
	sta varbuf+1	; c64: $62
	lda #>buf2	; c64: #$ce
	sta varbuf+2	; c64: $63
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	jsr L_c2a3
	sty L_c004
	lda L_c00b
	sta $fb
	lda L_c00c
	sta $fc
	ldy #$00
L_c98c:
	lda buf2,y	; c64: $ce27
	sta ($fb),y
	iny
	cpy L_c004
	bne L_c98c
	lda L_c00b
	clc
	adc L_c004
	sta L_c00b
	lda L_c00c
	adc #$00
	sta L_c00c
	lda L_c006
	clc
	adc L_c004
	sta L_c006
	inc L_c005
	lda L_c005
	cmp L_c011
	beq L_c9c1
	jmp L_c92c
L_c9c1:
	lda L_c008
	clc
	adc L_c011
	sta L_c008
	lda L_c009
	adc #$00
	sta L_c009
	jsr L_c9e1
	lda L_c00a
	bne L_c9de
	jmp L_c8bf
L_c9de:
	jmp L_ca11
L_c9e1:
	lda #<L_ca10	; c64: #$10
	sta varbuf+1	; c64: $62
	lda #>L_ca10	; c64: #$ca
	sta varbuf+2	; c64: $63
	lda #$01
	sta varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jsr L_ca3b
	lda #<buffer	; c64: #$77
	sta varbuf+1	; c64: $62
	lda #>buffer	; c64: #$ce
	sta varbuf+2	; c64: $63
	ldy L_c006
	lda #$8b
	sta buffer,y	; c64: $ce77
	iny
	sty varbuf	; c64: $61
	ldx #$01
	jsr L_ca2a
	jmp L_ca3b
L_ca10:
	byte $20
L_ca11:
	lda L_c00e
	sta varbuf+1	; c64: $62
	lda L_c00f
	sta varbuf	; c64: $61
	ldx #$1e
	jmp L_ca2a
L_ca20:
	lda #$1d
	jmp usetbl1	; c64: $cd03
	byte $a9,$16,$4c,$03,$cd
L_ca2a:
	lda #$1e
	jmp usetbl1	; c64: $cd03
L_ca2f:
	lda #$34
	ldy #$03
	jmp usetbl1	; c64: $cd03
L_ca36:
	lda #$1f
	jmp usetbl1	; c64: $cd03
L_ca3b:
	lda #$00
	jsr usetbl1	; c64: $cd03
	ldx #$11
	jsr L_ca20
	lda varbuf	; c64: $61
	ora L_c00a
	sta L_c00a
	rts
	byte $30,$31,$2f,$30,$39,$2f,$39,$31
	byte $20,$20,$35,$3a,$30,$30,$50,$0d
	byte $c3,$4f,$50,$52,$2e,$31,$39,$39
	byte $31,$20,$ce,$45,$57,$20,$c9,$4d
	byte $41,$47,$45
L_end:

