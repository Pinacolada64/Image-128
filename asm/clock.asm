; clock.asm -- "++ clock": the idle screen's big clock. i/lo.idle loads it
; (a$="clock":gosub 28) and calls it once a pass with &,16; while the clock
; flag is on, it draws the time from the CIA's time of day in 4 by 4 blocks
; of quarter-block characters at the top left of the screen (rows 1-5,
; columns 0-17), in the current color.
;
; From ImageBBS3's source/clock.s, which (assembled at $c000 with the C64's
; addresses) is the 3.0 release's "++ clock" byte for byte. Ported on
; 2026-10-21 (the C64's addresses are in the comments):
; - runs at protostart ($1c00; c64 $c000)
; - the clock flag is clock ($18d9; c64 $07fa), the color color ($f1;
;   c64 646); the VIC screen, color RAM and CIA are where they were
; - a, x, y and w, which C64List takes for registers, are q_a ... q_w
; - in 80 columns (mode bit 7) it copies the cells it drew to the same
;   place on the VDC (vdcclk), the VIC screen being out of sight there; the
;   mask keeps its rows in vdcsave then, so the VIC's rows 1-5 are free. It's
;   assembled on its own, so it has its own copy of the VDC register writes
;   and of vdccolor (vdc.asm).

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000

screen= $0400 + 40	; c64: $0428
colorm= colorram + 40	; c64: $d828
c1= color		; c64: 646

ml:
	jmp doclock

doclock0:
	rts
doclock:
	lda clock
	beq doclock0
	lda scs
	cmp clockscs
	beq doclock0
	sta clockscs
	lda hrs
	jsr bcdtob
	and #1
	sta h0
	sty h1
	lda min
	jsr bcdtob
	sta m0
	sty m1
	lda ten
	ldy #0
	lda h0
	bne ck3
	lda #10
	jsr quad
ck3:
	jsr quad
	lda h1
	jsr quad
	lda clockscs
	lsr
	lda #0
	adc #10
	jsr quad
	lda m0
	jsr quad
	lda m1
	jsr quad
	lda h0
	bne ck4
	lda #10
	jsr quad
	jsr quad
ck4:
	lda #160
	ldy c2
	sta screen+57
	sty colorm+57
	sta screen+97
	sty colorm+97
	sta screen+137
	sty colorm+137
	ldy #17
ck2:
	lda #160
	sta screen+160,y
	lda c2
	sta colorm+160,y
	dey
	bne ck2
	jmp vdcclk

bcdtob:
	pha
	and #$0f
	tay
	pla
	lsr
	lsr
	lsr
	lsr
	rts

h0:
	byte 0
h1:
	byte 0
m0:
	byte 0
m1:
	byte 0
clockscs:
	byte 0
q_a:
	byte 0
q_x:
	byte 0
q_y:
	byte 0
q_w:
	byte 0
c2:
	byte 11

charbuf:
	area 8, 0

quadchr:
	byte 160,236,251,226,252,97,127,126,254,255,225,124,98,123,108,32

quad:
	sta q_a
	sty q_y
	sta quad0+1
	lda #0
	asl quad0+1
	rol
	asl quad0+1
	rol
	asl quad0+1
	rol
	tax
	lda quad0+1
	clc
	adc #<chrset
	sta quad0+1
	txa
	adc #>chrset
	sta quad0+2
	ldx #7
quad0:
	lda $ffff,x
	sta charbuf,x
	dex
	bpl quad0
	lda #0
	sta q_x
quad1:
	lda #4
	sta q_w
	lda q_a
	cmp #10
	bcc quad2
	lda #1
	sta q_w
quad2:
	ldx q_x
	lda #0
	asl charbuf,x
	rol
	asl charbuf,x
	rol
	asl charbuf+1,x
	rol
	asl charbuf+1,x
	rol
	tax
	lda quadchr,x
	sta screen,y
	lda c1
	sta colorm,y
	iny
	dec q_w
	bne quad2
	inc q_x
	inc q_x
	lda q_x
	cmp #8
	bcs quad3
	lda q_y
	clc
	adc #40
	sta q_y
	tay
	jmp quad1
quad3:
	tya
	clc
	adc #136
	tay
	lda q_a
	rts

chrset:
	byte %00011100
	byte %00100010
	byte %00100010
	byte %00100010
	byte %00100010
	byte %00100010
	byte %00011100
	byte %00000000

	byte %00001000
	byte %00011000
	byte %00001000
	byte %00001000
	byte %00001000
	byte %00001000
	byte %00011100
	byte %00000000

	byte %00011100
	byte %00100010
	byte %00000010
	byte %00011100
	byte %00100000
	byte %00100000
	byte %00111110
	byte %00000000

	byte %00011100
	byte %00100010
	byte %00000010
	byte %00001100
	byte %00000010
	byte %00100010
	byte %00011100
	byte %00000000

	byte %00100100
	byte %00100100
	byte %00100100
	byte %00111110
	byte %00000100
	byte %00000100
	byte %00000100
	byte %00000000

	byte %00111110
	byte %00100000
	byte %00100000
	byte %00111100
	byte %00000010
	byte %00000010
	byte %00111100
	byte %00000000

	byte %00011100
	byte %00100010
	byte %00100000
	byte %00111100
	byte %00100010
	byte %00100010
	byte %00011100
	byte %00000000

	byte %00111110
	byte %00000010
	byte %00000010
	byte %00000100
	byte %00001000
	byte %00010000
	byte %00010000
	byte %00000000

	byte %00011100
	byte %00100010
	byte %00100010
	byte %00011100
	byte %00100010
	byte %00100010
	byte %00011100
	byte %00000000

	byte %00011100
	byte %00100010
	byte %00100010
	byte %00011110
	byte %00000010
	byte %00100010
	byte %00011100
	byte %00000000

	byte %00000000
	byte %00000000
	byte %00000000
	byte %00000000
	byte %00000000
	byte %00000000
	byte %00000000
	byte %00000000

	byte %00000000
	byte %01000000
	byte %00000000
	byte %00000000
	byte %00000000
	byte %01000000
	byte %00000000
	byte %00000000

; 80 columns: copy what doclock drew (rows 1-5, columns clk_first to
; clk_end) from the VIC screen to the VDC's, the colors as attributes (as
; shdlr.asm's vdcsrow: vdccolor, with the editor's charset bit from color).
; The cells around it are the idle screen's, on the VDC only.
vdcclk:
	bit mode
	bmi vdcclk0	; (vdcclk9 is too far for a branch)
	rts
vdcclk0:
	lda #<screen
	sta vdcclk_c+1
	sta vdcclk_d+1
	lda #80		; row 1
	sta clk_vdc
	lda #0
	sta clk_vdc+1
	sta clk_row
	lda color
	and #$80
	sta clk_alt
vdcclk1:
	ldx clk_row
	lda clk_vdc
	clc
	adc clk_first,x
	sta clk_upd_lo
	tay
	lda clk_vdc+1
	adc #0
	sta clk_upd_hi
	ora vdcscrn
	jsr clk_upd
	ldx clk_row
	ldy clk_first,x
vdcclk2:
vdcclk_c:
	lda screen,y
	jsr clk_put
	iny
	ldx clk_row
	tya
	cmp clk_end,x
	bcc vdcclk2
	ldy clk_upd_lo
	lda clk_upd_hi
	ora vdcattr
	jsr clk_upd
	ldx clk_row
	ldy clk_first,x
vdcclk3:
vdcclk_d:
	lda colorm,y
	and #$0f
	tax
	lda clk_color,x
	ora clk_alt
	jsr clk_put
	iny
	ldx clk_row
	tya
	cmp clk_end,x
	bcc vdcclk3
	lda vdcclk_c+1	; the next row
	clc
	adc #40
	sta vdcclk_c+1
	sta vdcclk_d+1
	lda clk_vdc
	clc
	adc #80
	sta clk_vdc
	bcc vdcclk4
	inc clk_vdc+1
vdcclk4:
	inc clk_row
	lda clk_row
	cmp #5
	bcs vdcclk9
	jmp vdcclk1	; (too far for a branch)
vdcclk9:
	rts

; the columns doclock draws on rows 1-5: the digits (0-16), the shadow
; down the right (17, rows 2-4) and along the bottom (1-17, row 5)
clk_first:
	byte 0,0,0,0,1
clk_end:
	byte 17,18,18,18,18

; the VDC's update address (R18/R19) to .a (high) .y (low); keeps .y
clk_upd:
	ldx #$12
	jsr clk_reg
	inx
	tya
; .a to VDC register .x; keeps .x .y
clk_reg:
	stx $d600
clk_reg1:
	bit $d600
	bpl clk_reg1
	sta $d601
	rts
; .a to the update address, which moves on (R31)
clk_put:
	ldx #$1f
	jmp clk_reg

clk_vdc:
	word 0
clk_upd_lo:
	byte 0
clk_upd_hi:
	byte 0
clk_row:
	byte 0
clk_alt:
	byte 0
; VDC RGBI for each VIC color: vdc.asm's vdccolor
clk_color:
	byte $00,$0f,$08,$07,$0b,$04,$02,$0d,$0a,$0c,$09,$06,$01,$05,$03,$0e
