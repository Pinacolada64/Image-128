; index.asm -- "++ index" (the same file as "++ 4"): the user index
; (u.index) in memory, for sub.handles and the rest: it loads the index
; just past itself, saves it, and finds a handle in it by binary search
; (&,16,x: 0 put a$ in the search buffer, 1 load, 2 save, 3 clear, 4-8
; search, insert, delete...).
;
; No source survives: disassembled from the 3.0 release's "++ index" by
; tools/ovl_dis.py (it reassembles at $c000 byte for byte), then ported
; on 2026-10-20 (the C64's addresses are in the comments):
; - runs at protostart ($1c00), where &,7,dv%,2 loads it; its index data
;   starts at L_end, just past it (#<L_end/#>L_end, c64 #$a1/#$c3)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63, FAC1),
;   its buffers buf2 and buffer ($0e27, $0e77; c64 $ce27, $ce77), its &
;   dispatcher usetbl1 ($192a; c64 $cd03)
; - the KERNAL through the ML's ROM stubs (setlfs, setnam, chkout, chrout,
;   clrchn, loadf, savef; c64 $ffba...), the ROM being out in cfg_ml;
;   setbnk before LOAD and SAVE
; - $fb/$fc stay: farcall puts them back (glue.asm)

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
L_c000:
	jmp L_c010
	byte $04
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
	byte $50,$02
L_c00c:
	byte $00
L_c00d:
	byte $00,$01,$0d
L_c010:
	txa
	beq L_c044
	dex
	beq L_c02c
	dex
	beq L_c02f
	dex
	beq L_c032
	dex
	beq L_c035
	dex
	beq L_c038
	dex
	beq L_c03b
	dex
	beq L_c03e
	dex
	beq L_c041
	rts
L_c02c:
	jmp L_c197
L_c02f:
	jmp L_c1cb
L_c032:
	jmp L_c210
L_c035:
	jmp L_c24e
L_c038:
	jmp L_c2ac
L_c03b:
	jmp L_c2f6
L_c03e:
	jmp L_c313
L_c041:
	jmp L_c319
L_c044:
	ldx #$00
	jsr L_c37e
	ldy #$00
L_c04b:
	lda (varbuf+1),y	; c64: ($62),y
	sta buffer,y	; c64: $ce77
	iny
	cpy varbuf	; c64: $61
	bcc L_c04b
	lda #$00
	sta buffer,y	; c64: $ce77
	sty L_c196
	lda L_c3a1
	ldx L_c3a2
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
	jsr L_c121
	beq L_c0b1
	bcs L_c089
	jmp L_c221
L_c089:
	lda L_c004
	ldx L_c005
	sta L_c008
	stx L_c009
	jsr L_c121
	beq L_c0b1
	bcc L_c0b4
	lda L_c004
	ldx L_c005
	inx
	bne L_c0a8
	clc
	adc #$01
L_c0a8:
	sta L_c008
	stx L_c009
	jmp L_c221
L_c0b1:
	jmp L_c229
L_c0b4:
	lda L_c006
	cmp L_c004
	bne L_c0c7
	lda L_c007
	cmp L_c005
	bne L_c0c7
	jmp L_c221
L_c0c7:
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
	bne L_c102
	lda L_c009
	cmp L_c007
	bne L_c102
	lda L_c004
	ldx L_c005
	sta L_c006
	stx L_c007
	sta L_c008
	stx L_c009
L_c102:
	jsr L_c121
	beq L_c0b1
	lda L_c008
	ldx L_c009
	bcc L_c118
	sta L_c006
	stx L_c007
	jmp L_c0b4
L_c118:
	sta L_c004
	stx L_c005
	jmp L_c0b4
L_c121:
	jsr L_c13e
	lda L_c317
	sta L_c318
	beq L_c12f
L_c12c:
	dec L_c318
L_c12f:
	ldx #$02
	ldy #$00
	jsr L_c388
	lda L_c318
	bne L_c12c
	jmp L_c17a
L_c13e:
	jsr L_c157
	ldx #$0f
	jsr chkout	; c64: $ffc9
	ldy #$00
	ldx #$06
L_c14a:
	lda L_c00a,y
	jsr chrout	; c64: $ffd2
	iny
	dex
	bne L_c14a
	jmp clrchn	; c64: $ffcc
L_c157:
	lda L_c009
	asl
	tay
	lda L_c008
	rol
	tax
	clc
	tya
	adc #<L_end
	sta $fb	; (farcall leaves $fb/$fc alone)
	txa
	adc #>L_end
	sta $fc
	ldy #$00
	lda ($fb),y
	sta L_c00d
	iny
	lda ($fb),y
	sta L_c00c
	rts
L_c17a:
	ldy #$00
L_c17c:
	lda buffer,y	; c64: $ce77
	cmp buf2,y	; c64: $ce27
	bne L_c195
	iny
	cpy L_c196
	beq L_c18f
	cpy index	; $d00f, the same on the 128
	bne L_c17c
L_c18f:
	ldy L_c196
	cpy index	; $d00f, the same on the 128
L_c195:
	rts
L_c196:
	byte $00
L_c197:
	ldx #$01
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd
	ldx #$20
	jsr L_c37e
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #$00
	ldx #<L_end
	ldy #>L_end
	jsr loadf	; c64: $ffd5
	lda L_c3a1
	ldx L_c3a2
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1e
	jmp L_c38d
L_c1cb:
	ldx #$01
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd
	ldx #$20
	jsr L_c37e
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #<L_end
	ldx #>L_end
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	lda L_c3a2
	asl
	tax
	lda L_c3a1
	rol
	tay
	clc
	txa
	adc #<L_end
	tax
	tya
	adc #>L_end
	tay
	clc
	txa
	adc #$02
	tax
	tya
	adc #$00
	tay
	lda #varbuf	; the start pointer for SAVE (c64: #$61)
	jmp savef	; c64: $ffd8
L_c210:
	lda #$00
	sta L_c3a1
	sta L_c3a3
	lda #$00
	sta L_c3a2
	sta L_c3a4
	rts
L_c221:
	lda #$00
	sta L_c00c
	sta L_c00d
L_c229:
	lda L_c00d
	ldx L_c00c
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1e
	jsr L_c38d
	lda L_c008
	ldx L_c009
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #$1f
	jsr L_c38d
	lda L_c00c
	ora L_c00d
	rts
L_c24e:
	ldx #$1f
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
	inc L_c3a2
	bne L_c265
	inc L_c3a1
L_c265:
	ldx #$1e
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c00d
	stx L_c00c
L_c274:
	lda L_c00c
	ldx L_c00d
	sta L_c005
	stx L_c004
	jsr L_c157
	ldy #$00
	lda L_c004
	sta ($fb),y
	iny
	lda L_c005
	sta ($fb),y
	lda L_c009
	cmp L_c3a2
	bne L_c2a1
	lda L_c008
	cmp L_c3a1
	bne L_c2a1
	rts
L_c2a1:
	inc L_c009
	bne L_c2a9
	inc L_c008
L_c2a9:
	jmp L_c274
L_c2ac:
	ldx #$1f
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
L_c2bb:
	lda L_c008
	cmp L_c3a1
	bne L_c2cb
	lda L_c009
	cmp L_c3a2
	beq L_c2ea
L_c2cb:
	jsr L_c157
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
	bne L_c2e7
	inc L_c008
L_c2e7:
	jmp L_c2bb
L_c2ea:
	lda L_c3a2
	bne L_c2f2
	dec L_c3a1
L_c2f2:
	dec L_c3a2
	rts
L_c2f6:
	ldx #$1f
	jsr L_c37e
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta L_c008
	stx L_c009
	inc L_c009
	bne L_c30d
	inc L_c008
L_c30d:
	jsr L_c157
	jmp L_c229
L_c313:
	sty L_c317
	rts
L_c317:
	byte $00
L_c318:
	byte $00
L_c319:
	ldx #$1e
	jsr L_c37e
	lda varbuf	; c64: $61
	sta L_c004
	lda varbuf+1	; c64: $62
	sta L_c005
	lda #$00
	sta L_c008
	lda #$01
	sta L_c009
	lda L_c3a1
	bne L_c33f
	lda L_c3a2
	bne L_c33f
	jmp L_c221
L_c33f:
	jsr L_c157
	lda L_c00d
	cmp L_c004
	bne L_c355
	lda L_c00c
	cmp L_c005
	bne L_c355
	jmp L_c229
L_c355:
	inc L_c009
	bne L_c35d
	inc L_c008
L_c35d:
	lda L_c008
	cmp L_c3a1
	bne L_c36d
	lda L_c009
	cmp L_c3a2
	beq L_c33f
L_c36d:
	lda L_c009
	cmp L_c3a2
	lda L_c008
	sbc L_c3a1
	bcc L_c33f
	jmp L_c221
L_c37e:
	lda #$1d
	jmp usetbl1	; c64: $cd03
	lda #$16	; (not reached)
	jmp usetbl1	; c64: $cd03
L_c388:
	lda #$02
	jmp usetbl1	; c64: $cd03
L_c38d:
	lda #$1e
	jmp usetbl1	; c64: $cd03
	byte $30,$32,$2f,$30,$37,$2f,$39,$30
	byte $20,$31,$32,$3a,$30,$30,$41
L_end:
L_c3a1 = L_end + 0	; past the end: a variable
L_c3a2 = L_end + 1	; past the end: a variable
L_c3a3 = L_end + 2	; past the end: a variable
L_c3a4 = L_end + 3	; past the end: a variable
