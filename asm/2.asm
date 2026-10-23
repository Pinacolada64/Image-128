; 2.asm -- "++ 2": Copier 3.0's (i.CP's) file copier, on the 128.
; sys protostart: copy file #3 to #2, in blocks of up to 254 bytes kept
; in screen rows 7-13, counting them at "BLKS:" (row 21), until the end of
; the file or of the count +6 read; +3: count file #3's bytes into 3 bytes
; written to #2; +6: read such a count from #3, then copy that many
; bytes; +28: copy the next file (the setup at +0 already done).
;
; No source survives: disassembled from the 3.0 release's "++ 2" by
; tools/ovl_dis.py (entries $c01c, $c0e2, $c128; it reassembles at $c000
; byte for byte), then ported on 2026-10-22:
; - runs at protostart ($1c00), called with sys from BASIC, so in BASIC's
;   bank 15: the KERNAL is in, and its jump table, $90 and the VIC screen
;   and color RAM are where the C64 has them
; - the C64 KERNAL's routine that clears a screen line ($e9ff) isn't in the
;   128's: rows 7-21 are cleared directly

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
L_c000:
	jmp L_c009
	jmp L_c0e2	; +3 (c64: bytes $4c,$e2,$c0)
	jmp L_c128	; +6 (c64: bytes $4c,$28,$c1)
L_c009:
	lda #$ff
	sta L_c145
	sta L_c146
	sta L_c147
L_c014:
	jsr L_c0b0
	lda #$00
	sta L_c148
L_c01c:
	ldx #$03
	jsr k_chkin	; c64: $ffc6
	ldy #$00
	ldx #$00
L_c025:
	stx L_c0df
	jsr k_chrin	; c64: $ffcf
	ldx status	; c64: $90
	beq L_c03a
	cpx #$40
	beq L_c03a
	cpx L_c0df
	bne L_c025
	beq L_c06b
L_c03a:
	sta $0518,y	; the VIC screen (same on the 128)
	iny
	lda L_c145
	bne L_c04e
	lda L_c146
	bne L_c04b
	dec L_c147
L_c04b:
	dec L_c146
L_c04e:
	dec L_c145
	lda L_c145
	ora L_c146
	ora L_c147
	bne L_c063
	lda #$01
	sta L_c148
	bne L_c06b
L_c063:
	cpy #$fe
	beq L_c06b
	cpx #$00
	beq L_c025
L_c06b:
	sty L_c0e0
	stx L_c0df
	jsr k_clrchn	; c64: $ffcc
	ldx #$02
	jsr k_chkout	; c64: $ffc9
	ldy #$00
	ldx #$00
L_c07d:
	lda $0518,y	; the VIC screen (same on the 128)
L_c080:
	stx L_c0e1
	jsr k_chrout	; c64: $ffd2
	ldx status	; c64: $90
	beq L_c091
	cpx L_c0e1
	bne L_c080
	beq L_c097
L_c091:
	iny
	cpy L_c0e0
	bne L_c07d
L_c097:
	jsr k_clrchn	; c64: $ffcc
	jsr L_c149
	lda L_c0df
	ora status	; c64: $90
	bne L_c0ac
	lda L_c148
	bne L_c0ac
	jmp L_c01c
L_c0ac:
	rts
	byte $00,$00,$00
L_c0b0:
	lda #' '	; 128: clear rows 7-21 ($0518-$076f) here: the C64
	ldx #0		; KERNAL's "clear a screen line" (ldx #7: jsr $e9ff,
L_c0b2:			; up to row 21) isn't in the 128's
	sta $0518,x
	sta $0618,x
	inx
	bne L_c0b2
	ldx #$57
L_c0b3:
	sta $0718,x
	dex
	bpl L_c0b3
	ldy #$00
L_c0bc:
	lda #$03
	sta $d918,y	; color RAM (same on the 128)
	iny
	bne L_c0bc
	ldy #$09
L_c0c6:
	lda L_c0d5,y
	sta $0748,y	; the VIC screen (same on the 128)
	lda #$01
	sta $db48,y	; color RAM (same on the 128)
	dey
	bpl L_c0c6
	rts
L_c0d5:
	byte $42,$4c,$4b,$53,$3a,$20,$30,$30
	byte $30,$30
L_c0df:
	byte $00
L_c0e0:
	byte $00
L_c0e1:
	byte $00
L_c0e2:
	ldx #$03
	jsr k_chkin	; c64: $ffc6
	lda #$00
	sta L_c145
	sta L_c146
	sta L_c147
L_c0f2:
	jsr k_getin	; c64: $ffe4
	inc L_c145
	bne L_c102
	inc L_c146
	bne L_c102
	inc L_c147
L_c102:
	lda status	; c64: $90
	beq L_c0f2
	jsr k_clrchn	; c64: $ffcc
	ldx #$02
	jsr k_chkout	; c64: $ffc9
	lda L_c145
	jsr k_chrout	; c64: $ffd2
	lda L_c146
	jsr k_chrout	; c64: $ffd2
	lda L_c147
	jsr k_chrout	; c64: $ffd2
	jsr k_clrchn	; c64: $ffcc
	lda #$03
	jmp $ffc3	; KERNAL CLOSE (the same on both)
L_c128:
	ldx #$03
	jsr k_chkin	; c64: $ffc6
	jsr k_getin	; c64: $ffe4
	sta L_c145
	jsr k_getin	; c64: $ffe4
	sta L_c146
	jsr k_getin	; c64: $ffe4
	sta L_c147
	jsr k_clrchn	; c64: $ffcc
	jmp L_c014
L_c145:
	byte $00
L_c146:
	byte $00
L_c147:
	byte $00
L_c148:
	byte $00
L_c149:
	ldx #$51
	ldy #$03
L_c14d:
	inc $0700,x	; the VIC screen (same on the 128)
	lda $0700,x	; the VIC screen (same on the 128)
	cmp #$3a
	bne L_c160
	lda #$30
	sta $0700,x	; the VIC screen (same on the 128)
	dex
	dey
	bpl L_c14d
L_c160:
	rts
L_end:
