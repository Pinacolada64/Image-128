;  ansicup.asm -- &,70 (cursposn, miscl.asm) for an ANSI caller: one CUP
;  (11/15/2026, user's request)
;
;  cursposn puts the cursor at column X, row Y (from 0) with Home, Y Downs
;  and X Rights, each through xchrout: to the console and the modem. For
;  an ANSI caller (flags 16 and 18) outmod sends each of those as its own
;  sequence (Esc[B, Esc[C: 3 bytes), so row 20, column 30 cost 154 bytes.
;  Now: the console gets Home, Downs and Rights as before (outscn0 alone,
;  so Image's own cursor, sline/scnpos, follows), and the modem one CUP,
;  Esc[row;colH (rows and columns from 1), sent raw (outm) when outmdm0
;  would send anything (inchat, or carchk4: not local, carrier up). The
;  modem's column and line counts (modclm, usrlin) are set as the Home,
;  Downs and Rights would have left them (outadj).
;
;  cursposn calls this in place of "lda #cursor_home: jsr xchrout" (miscl.asm
;  is before arrays.asm's fixed address, with 6 bytes to spare), with A
;  cursmode's result: 1 Commodore (Home, then cursposn's own loops), 2 ANSI
;  (all of it here, then straight back to cursposn's caller). The counts
;  are in cursposn's own operands (cursp0+1 rows, cursp2+1 columns).

cursans:
	cmp #2
	beq cursan1
	lda #cursor_home
	jmp xchrout
cursan1:
	pla		; not back to cursposn: to its caller
	pla
; the console: Home, Downs, Rights
	lda #cursor_home
	jsr cursscn
	lda cursp0+1
	sta cursan_n
cursan2:
	lda cursan_n
	beq cursan3
	lda #cursor_down
	jsr cursscn
	dec cursan_n
	jmp cursan2
cursan3:
	lda cursp2+1
	sta cursan_n
cursan4:
	lda cursan_n
	beq cursan5
	lda #cursor_right
	jsr cursscn
	dec cursan_n
	jmp cursan4
; the modem: where Home, Downs and Rights leave outadj's counts
cursan5:
	lda cursp2+1
	sta modclm
	lda cursp0+1
	sta usrlin
	lda inchat
	bne cursan6
	jsr carchk4
	bne cursan9
cursan6:
	lda #27
	jsr outm
	lda #'['
	jsr outm
	ldx cursp0+1
	inx
	txa
	jsr cursdec
	lda #';'
	jsr outm
	ldx cursp2+1
	inx
	txa
	jsr cursdec
	lda #$48	; ASCII "H" (a capital here would be $c8)
	jmp outm
cursan9:
	rts

; one character to the console only
cursscn:
	sta $fe
	jmp outscn0

; A (1-255) in decimal to the modem, without leading zeros
cursdec:
	ldy #0		; no digit sent yet
	ldx #100
	jsr cursdig
	ldx #10
	jsr cursdig
	ora #'0'
	jmp outm
; A's digit for X (100 or 10), unless it's a leading zero; A the rest
cursdig:
	stx cursan_d
	ldx #0
cursdg1:
	cmp cursan_d
	bcc cursdg2
	sbc cursan_d
	inx
	bne cursdg1
cursdg2:
	pha
	txa
	bne cursdg3
	cpy #0
	beq cursdg4
cursdg3:
	ora #'0'
	jsr outm
	ldy #1
cursdg4:
	pla
	rts

cursan_n:
	byte 0
cursan_d:
	byte 0
