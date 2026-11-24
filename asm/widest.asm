; widest.asm -- &,15,8,s,n: the widest visible width among tt$(1) to
; tt$(n), from each one's character s (0 or 1: all of it), returned in .a,
; which usetbl0 puts in sareg: BASIC reads it as peek(6) (11/20/2026, for sub.columns: the user's choice of an
; & call over BASIC's loop through every character). The width is counted
; as &,15,7 counts it (center.asm's cmeas): control characters nothing,
; MCI commands what they print. n 0, or no tt$(): 0.
;
; Under I/O at $d000 with center.asm (cmeas, cdesc) and widest2.asm, run in
; cfg_io: center_lo.asm's widest stub calls widesti. arrfind is miscl.asm's;
; wst and wn are bytes after anfix ($0af5, $0af6).

widesti:
	sty wst		; s
	jsr chkcom
	jsr getbytc	; .x: n
	lda #0
	sta sareg	; the widest so far
	txa
	beq wret	; no items
	sta wn
	ldx #0		; tt$() (arrays1/arrays2's numbering)
	jsr arrfind	; varpnt: tt$(0)
	bcs wret	; no tt$()
	lda varpnt
	sta cvp		; wloop steps to tt$(1) first
	lda varpnt+1
	sta cvp+1
	ldy wst		; s 0 or 1: index 0
	beq widest1
	dey
widest1:
	sty wst
	jmp wloop
wret:
	rts
