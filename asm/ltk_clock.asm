; ltk_clock.asm -- "++ ltk clock": the "Lt. Kernal" clock, a Dallas DS1216
; SmartWatch on a control port, read for sub.clocks (im=3, "Lt. Kernal port 1
; or 2" in setup's clock part). A module loads it (a$="ltk clock":gosub 28),
; then:
;
;	&,16,1      reads the clock on control port 1 (CIA 1's port B, $dc01)
;	&,16,2      on control port 2 (port A, $dc00)
;	&,16,0      only turns ckregs into the date (no clock read): a test
;
; and the date is at protostart+7 on, as Image keeps it (z$): the weekday
; (1-7), the year, month and day, the hour (1-12, 80 more after noon) and
; the minute, 11 digits, then the second (2 more). The clock's own values
; (BCD) are at +20 on: year, month, date, weekday, hour (24-hour),
; minute, second, hundredths. With no clock there they're whatever the
; port's lines read (sub.clocks checks the date).
;
; From swr.ml (Image BBS 2.0/3.0, "v2/larry", 288 bytes at $c000; C64List
; disassembled it as swr_ml.lst): sys 49152 switched it from port 1 to port 2
; (it flipped the low byte of each port address it uses, self-modified),
; sys 49155 read the clock, the date at 49159-49169. The DS1216 is read by
; bit-banging the port: the 64-bit recognition pattern (ckpatt) is clocked
; out, then the clock's 64 bits are clocked in, a bit at a time, lowest
; first; with ckwrite nonzero it first clocks ckregs out to set the clock
; (sub.clocks doesn't). The port's data direction: lines 2-4 out, line 1
; (the clock's data) in, then put back as it was. swr.ml decremented it
; instead: port 2's $ff became $fe, right, but port 1's $00 became $ff, so
; line 1 was an output, latched low, and the clock could never pull it high:
; port 1 always read zeros (seen with VICE's DS1216 SmartWatch, 11/12/2026).
;
; Image BBS 128 (11/12/2026): runs at protostart ($1c00; c64 $c000), started
; with &,16 (in cfg_ml, which has the I/O); the port is set from &,16's
; number, not toggled; the pattern's and registers' addresses are written
; whole (c64: only their low bytes, all in page $c0); the BCD digits are
; shifted down with lsr (c64: ror, which brings in the carry: wrong digits
; if it was set). The data keeps its C64 offsets (+6 write, +7 the date,
; +20 the registers, +28 the pattern).

{alpha:alt}
{include:"equates.asm"}

	orig protostart	; c64: $c000

	jmp ckentry	; +0 &,16 (c64: jmp $c08b, port 2)
	jmp ckread	; +3 read, on the port last set (c64: sys 49155)
ckwrite:
	byte 0		; +6 nonzero: set the clock from ckregs first
ckdate:
	area 13, 0	; +7 the date (11 digits), then the second (2)
ckregs:
	byte $91,$09,$08,$11,$13,$44,$00,$00	; +20 year, month, date,
			; weekday, hour, minute, second, hundredths (BCD)
ckpatt:
	byte $5c,$a3,$3a,$c5,$5c,$a3,$3a,$c5	; +28 the DS1216's
			; recognition pattern (sent from the last byte down)

; &,16,x: .x the port (1, 2), or 0: convert only
ckentry:
	txa
	bne ckentry1
	jmp ckconv	; (out of a branch's reach)
ckentry1:
	and #1		; port 1: $dc01, $dc03; port 2: $dc00, $dc02
	sta ckp1+1
	sta ckp2+1
	sta ckp3+1
	sta ckp4+1
	sta ckp5+1
	sta ckp6+1
	sta ckp7+1
	ora #2
	sta ckd1+1
	sta ckd2+1
	sta ckd3+1
; read the clock (c64: $c025)
ckread:
	sei
ckd1:
	lda $dc03	; the port's direction: lines 2-4 (D, /CE, /WE) out,
	sta ckddr	; line 1 (Q) in; put back after
	ora #%00001110
	and #%11111110
ckd2:
	sta $dc03
	lda #$08
ckp1:
	sta $dc01
	lda #$0f
ckp2:
	sta $dc01
	lda ckwrite
	beq ckread1
	inc ckwrite
	jsr cksendp	; the pattern, then the new values
	jsr cksendr
ckread1:
	jsr cksendp	; the pattern, then the clock's 64 bits
	ldx #7
ckread2:
	ldy #8
ckread3:
	lda #$08
ckp3:
	sta $dc01
ckp4:
	lda $dc01
	ror		; bit 0
	ror ckregs,x
	lda #$0f
ckp5:
	sta $dc01
	dey
	bne ckread3
	dex
	bpl ckread2
	lda ckddr
ckd3:
	sta $dc03
	jsr ckconv
	cli
	rts

; clock out the pattern (cksendp) or ckregs (cksendr), from the last byte
; down, each from its lowest bit (c64: $c067, $c06a)
cksendp:
	lda #<ckpatt
	ldx #>ckpatt
	bne cksend0
cksendr:
	lda #<ckregs
	ldx #>ckregs
cksend0:
	sta cksend1+1
	stx cksend1+2
	ldx #7
cksend1:
	lda $ffff,x	; target of self-modifying code
	ldy #8
cksend2:
	pha
	rol
	and #2		; the bit, on line 1
ckp6:
	sta $dc01
	lda #$0f
ckp7:
	sta $dc01
	pla
	ror
	dey
	bne cksend2
	dex
	bpl cksend1
	rts

; ckregs to ckdate (c64: $c0b1)
ckconv:
	lda ckregs+3	; the weekday, first (put in at the end)
	and #7
	ora #$30
	pha
	ldy #1
	lda ckregs+0	; year
	jsr ckbcd
	lda ckregs+1	; month
	jsr ckbcd
	lda ckregs+2	; date
	jsr ckbcd
	ldx #0		; the hour: 24-hour BCD to 1-12, $80 after noon
	lda ckregs+4
	cmp #$12
	bcc ckconv2
	ldx #$80
	cmp #$22
	bcs ckconv1
	cmp #$20
	bcc ckconv1
	sbc #$18	; 20, 21: 8, 9
	bcs ckconv2
ckconv1:
	sec
	sbc #$12
ckconv2:
	cmp #0
	bne ckconv3
	lda #$12	; 0: 12
ckconv3:
	stx ckdate
	ora ckdate
	jsr ckbcd
	lda ckregs+5	; minute
	jsr ckbcd
	lda ckregs+6	; second
	jsr ckbcd
	pla
	sta ckdate
	rts

ckddr:
	byte 0		; the port's direction, as it was

; BCD .a to two digits at ckdate,y
ckbcd:
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta ckdate,y
	iny
	pla
	and #$0f
	ora #$30
	sta ckdate,y
	iny
	rts
