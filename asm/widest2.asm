; widest2.asm -- &,15,8's loop (widest.asm has the rest): each of tt$(1)
; to tt$(n) (cvp steps 3 bytes, an element's descriptor), measured from
; wst by center.asm's cmeas; the widest in sareg, and in .a at the end

wloop:
	clc
	lda cvp
	adc #3
	sta cvp
	bcc wloop1
	inc cvp+1
wloop1:
	jsr cdesc	; slen, and the text's address
	ldy wst
	jsr cmeas	; vis
	lda vis
	cmp sareg
	bcc wloop2
	sta sareg
wloop2:
	dec wn
	bne wloop
	lda sareg	; the result in .a: usetbl0 stores .a in sareg as an & call ends
	rts
