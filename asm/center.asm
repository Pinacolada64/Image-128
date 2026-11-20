; center.asm -- &,15,7, a string centered for the caller's width, and the
; MCI tab's body (11/20/2026). In the shared bottom 16K after status.asm
; ($c000-$cfff, strio.asm and mcicm.asm, has no room); cdigits and mtab are
; in center_lo.asm, at $3581 below glue, as this didn't fit below $4000.
;
; &,15,7          centers a$ for ll%
; &,15,7,w        centers a$ for w columns (0: ll%)
; &,15,7,w,s$     centers s$ (any string variable) for w (0: ll%)
;
; &'s parser (wedge.asm's getaxy) reads two numbers after the command, 7
; and w, so a variable comes third: &,15,7,0,b$. The string gets the MCI
; tab (pound, back arrow, two digits) to column (w - visible) / 2 put in
; front; a tab already at its start (an earlier &,15,7) is replaced, so it
; can be centered again for another width.
;
; The visible length is what the string prints:
; - characters $20-$7f and $a0-$ff count one each, $00-$1f and $80-$9f
;   (colors, reverse, Image's tokens such as its return, $8b) none;
; - MCI commands (pound, the command, its argument) count what they print:
;     $x, vX    the variable's length (cstr, comv)
;     %x        the integer's digits and sign, at least the field width an
;               earlier #n in the string set (cnum, clen)
;     o<c>      19 (como)
;     h<n>      n back (comh: backspaces)
;     a...      up to the next pound, nothing (coma: a compare)
;     m.., <-nn 4 bytes, nothing (margins, a tab)
;     !x        nothing: a floating point number's printed width isn't
;               worked out here
;     the rest  3 bytes, nothing (colors, modes, bells, returns...)
;   two pounds print one; a pound before a character that isn't a
;   command prints itself, and the character counts as usual.

center:
	sty cnw		; w: 0 for ll%
	jsr chrgot
	cmp #comma
	bne cent1
	jsr chkcom
	jsr ptrget	; varpnt: the variable named
	bit valtyp
	bmi cent2	; a string
	rts		; a number: left as it is
cent1:
	ldx #var_a_string
	jsr varname	; varpnt: a$
cent2:
	lda varpnt
	sta cvp
	lda varpnt+1
	sta cvp+1
	lda cnw
	bne cent3
	jsr llget	; .a: ll%
	bcc cent3
	rts		; no ll% yet (cent9 is past a branch's reach: C64List
			; assembles a branch too far as $ff, with no error)
cent3:
	sta cnw
	jsr cdesc	; slen, and the text's address in cget's and ccopy's operands
	lda #0
	sta coff
	tay
; a tab at the start, from an earlier &,15,7: skipped, and replaced
	lda slen
	cmp #4
	bcc cent4
	jsr cch
	cmp #$5c	; pound
	bne cent4
	iny
	jsr cch
	ldy #0
	cmp #$5f	; back arrow
	bne cent4
	ldy #4
	sty coff
cent4:
	jsr cmeas	; vis: the text's visible length from .y
	jmp cdone

; cmeas: the visible length (vis) of the text cdesc set up, from its
; character .y (11/20/2026: a subroutine, for &,15,8 too: widest.asm)
cmeas:
	lda #0
	sta vis
	sta cdig
cscan:
	cpy slen
	bcs cmeas9
	jsr cch
	cmp #$5c	; pound: an MCI command
	beq cmci
	and #$7f
	cmp #$20
	bcc cnext	; a control character
	jsr cvis1
cnext:
	iny
	jmp cscan
cmeas9:
	rts

; the width: (w - visible) / 2, at most column 79
cdone:
	lda cnw
	sec
	sbc vis
	bcs cd1
	lda #0		; wider than w: column 0
cd1:
	lsr
	cmp #80
	bcc cd2
	lda #79
cd2:
	sta ccol
; the new string: pound, back arrow, the column's two digits, the text
	lda slen
	sec
	sbc coff
	clc
	adc #4
	bcs cent9	; over 255
	jsr makeroom	; .a bytes: varbuf
	jsr cdesc	; the text again: makeroom's garbage collection can move it
	ldy #0
	lda #$5c	; pound
	sta (varbuf+1),y
	iny
	lda #$5f	; back arrow
	sta (varbuf+1),y
	lda ccol
	ldx #'0'-1
cd3:
	inx		; the tens digit
	sec
	sbc #10
	bcs cd3
	adc #10+'0'	; the ones digit (carry clear)
	pha
	txa
	iny
	sta (varbuf+1),y
	pla
	iny
	sta (varbuf+1),y
	ldx coff
cd4:
	cpx slen
	bcs cd5
	iny
ccopy:
	lda $ffff,x	; the text (cdesc sets the operand)
	sta (varbuf+1),y
	inx
	bne cd4
cd5:
	lda cvp		; the variable again: putvar2 puts varbuf there
	sta varpnt
	lda cvp+1
	sta varpnt+1
	jmp putvar2
cent9:
	rts

; an MCI command: .y at its pound
cmci:
	iny
	cpy slen
	bcs clast	; a pound last: printed as it is
	jsr cch
	cmp #$5c
	beq c2pnd	; two pounds: one printed
	and #63		; as domci's mcom
	sta ccmd
	beq cbad
	cmp #26
	bcc cvalid	; a-y
	cmp #31
	beq cvalid	; back arrow: tab
	cmp #33
	beq cvalid	; !
	cmp #35
	bcc cbad
	cmp #38
	bcc cvalid	; # $ %
cbad:			; not a command: the pound prints, then this character
	jsr cvis1
	jmp cscan
clast:
	jsr cvis1
	jmp cmeas9
c2pnd:
	jsr cvis1
	jmp cnext

; .y at the command; its argument next
cvalid:
	iny
	lda #0
	sta carg
	cpy slen
	bcs cv0
	jsr cch
	sta carg
cv0:
	lda ccmd
	cmp #1		; a: a compare, up to the next pound
	bne cv2
cva:
	iny
	cpy slen
	bcc cva1
	jmp cmeas9	; out of a branch's reach
cva1:
	jsr cch
	cmp #$5c
	bne cva
	jmp cnext
cv2:
	cmp #13		; m: margins, 4 bytes
	beq cv4
	cmp #31		; back arrow: a tab, 4 bytes
	bne cv3
cv4:
	iny
	jmp cnext
cv3:
	cmp #15		; o: 19 of its argument
	bne cv5
	lda #19
	jsr cvisa
	jmp cnext
cv5:
	cmp #8		; h: backspaces
	bne cv6
	lda carg
	and #$0f
	sta ctmp
	lda vis
	sec
	sbc ctmp
	bcs cv5a
	lda #0
cv5a:
	sta vis
	jmp cnext
cv6:
	cmp #35		; #: a field width, with a digit (at most 5, as clen)
	bne cv7
	lda carg
	cmp #'0'
	bcc cv6b
	cmp #'9'+1
	bcs cv6b
	and #$0f
	cmp #6
	bcc cv6a
	lda #5
cv6a:
	sta cdig
cv6b:
	jmp cnext
cv7:
	cmp #22		; v: a variable from mcivars
	bne cv8
	sty cy
	lda carg
	and #$0f
	tax
	jsr mcivar	; varbuf: its descriptor
	jmp cvlen
cv8:
	cmp #36		; $: a one-letter string variable
	bne cv9
	sty cy
	lda carg
	ldx #$80
	jsr usevar0
cvlen:
	lda varbuf	; its length
	jsr cvisa
	ldy cy
	jmp cnext
cv9:
	cmp #37		; %: a one-letter integer variable
	bne cv10
	sty cy
	lda carg
	ora #$80
	ldx #$80
	jsr usevar0	; varbuf: its value, high byte first
	jsr cdigits
	jsr cvisa
	ldy cy
cv10:
	jmp cnext

; one visible character more (at most 255)
cvis1:
	lda #1
; .a visible characters more (at most 255)
cvisa:
	clc
	adc vis
	bcc cvisa1
	lda #255
cvisa1:
	sta vis
	rts

; the variable's descriptor (at cvp): its length to slen, its text's
; address into cget's and ccopy's operands
cdesc:
	lda cvp
	sta cdsc+1
	lda cvp+1
	sta cdsc+2
	ldy #2
cdsc:
	lda $ffff,y
	sta slen,y	; slen, then saddr
	dey
	bpl cdsc
	lda saddr
	sta cget+1
	sta ccopy+1
	lda saddr+1
	sta cget+2
	sta ccopy+2
	rts

; the text's character .y
cch:
cget:
	lda $ffff,y
	rts

cnw:
	byte 0	; the width to center in
cvp:
	word 0	; the variable's descriptor (varpnt)
slen:
	byte 0	; its length
saddr:
	word 0	; its text (bank 1)
coff:
	byte 0	; 4 when an old tab at its start is skipped, else 0
vis:
	byte 0	; the visible length so far
cdig:
	byte 0	; the field width a #n set
ccol:
	byte 0	; the column to tab to
ccmd:
	byte 0	; an MCI command (mcom)
carg:
	byte 0	; its argument
ctmp:
	byte 0
cy:
	byte 0	; .y while a variable is read
