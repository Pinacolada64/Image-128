; arrays.asm: &,28, put the array pointers back (arrayrs0), with the 128's
; string bookkeeping: the dropped variables' and dropped string arrays'
; strings marked garbage (arrmark, arrmarka), the moved string arrays'
; strings linked to their new places (arrlink). Resident, at arrayres_hi
; (equates.asm), which the wedge's &,28 entry jumps to: the wedge (wedge.asm,
; $2f00, assembled on its own) has no room for it below tempscn ($3300).
; Runs in cfg_ml, as the wedge's entry does (glue.asm's wedge_far+28).

	jmp arrayrs0	; arrayres_hi: the entry, first

arytab_hi = $0032	; "lda arytab+1,y" (arytab is a zero page equate)

; .x: the level (c64: 0-3); .x: its offset in arryptrs, .y: 2 (arytab, strend)
arroff:
	txa
	and #7
	asl
	asl
	tax
	ldy #2
	rts

;* restore pointers for arrays *
arrayrs0:
	lda arytab	; c64: $2f
	sta sal		; c64: $ac
	lda arytab+1	; c64: $30
	sta sal+1	; c64: $ad
	lda strend	; 128: where the arrays end now, for arrmarka
	sta oldend
	lda strend+1
	sta oldend+1
	jsr arroff
arrs1:
	clc
	lda arryptrs+0,x
	adc vartab	; c64: $2d
	sta arytab,y	; c64: $2f
	lda arryptrs+1,x
	adc vartab+1	; c64: $2e
;	sta arytab+1,y	; c64: $30
	sta arytab_hi,y
	inx
	inx
	dey
	dey
	bpl arrs1
	jsr arrmark	; 128: the dropped variables' strings are garbage
	jsr arrmarka	; 128: and the dropped string arrays'
	lda arytab	; c64:  $2f
	sta eal		; c64:  $ae
	lda arytab+1	; c64:  $30
	sta eal+1	; c64:  $af
	ldy #0
	beq arrs2
arrs3:
	inc sal		; c64:  $ac
	bne arrs3a
	inc sal+1	; c64:  $ad
arrs3a:
	inc eal		; c64:  $ae
	bne arrs2
	inc eal+1	; c64:  $af
arrs2:
	lda (sal),y	; same: ($ac),y
	sta (eal),y	; same: ($ae),y
	lda eal		; same: $ae
	cmp strend	; c64:  $31
	bne arrs3
	lda eal+1	; c64: $af
	cmp strend+1	; c64: $32
	bne arrs3
	jmp arrlink	; 128: the moved arrays' strings point back to them

; 128: BASIC 7 keeps a back-link after each string in its string area (bank
; 1, fretop up to memsiz) to the descriptor that holds it, and marks a
; string nothing holds with its length and $ff; its garbage collection
; ($92ea) goes by those. Putting the array pointers back as above (c64:
; that was all) drops the variables made since they were saved and moves
; the arrays down over them, so: before the move, mark the dropped
; variables' strings as garbage (arrmark); after it, point the strings of
; the string arrays back at their elements' new places (arrlink). Without
; them the next garbage collection followed stale back-links: it hung, or
; wrote over the arrays.

; the plain variables from arytab (where the arrays go) to sal (where
; they were): a string's string is garbage now
arrmark:
	lda arytab
	sta eal
	lda arytab+1
	sta eal+1
arrm1:
	lda eal
	cmp sal
	lda eal+1
	sbc sal+1
	bcs arrm9	; done
	ldy #0
	lda (eal),y	; a string: name's first byte bit 7 clear,
	bmi arrm2
	iny
	lda (eal),y	; second set
	bpl arrm2
	iny		; the descriptor, after the name
	jsr strpast
	bcs arrm2
	ldy #0
	txa		; the length,
	sta (free_fb),y
	iny
	lda #$ff	; and $ff
	sta (free_fb),y
arrm2:
	clc		; variables are 7 bytes
	lda eal
	adc #7
	sta eal
	bcc arrm1
	inc eal+1
	bne arrm1	; always
arrm9:
	rts

; the arrays dropped too: those after the ones kept, at their old places
; (sal + the arrays' new length, up to oldend, the old strend): each string
; array element's string that links back to its element is garbage now.
; Without this (im's 304: &,28,1, then line 306 DIMs bb$(), dt$(), ed$(),
; nn$() again), their strings stayed "in use", linked into memory the
; arrays moved over: the collection wrote through those links into co$()
; and im$() (tools/strcheck.py after a logoff; tests/standin/arrayrs.bas).
arrmarka:
	sec		; the arrays kept: strend - arytab bytes, from sal
	lda strend
	sbc arytab
	sta eal
	lda strend+1
	sbc arytab+1
	sta eal+1
	clc
	lda eal
	adc sal
	sta eal
	lda eal+1
	adc sal+1
	sta eal+1
arma1:
	lda eal
	cmp oldend
	lda eal+1
	sbc oldend+1
	bcs arm9a	; done
	ldy #2		; amnext: the next array (+2/+3: this one's size)
	clc
	lda (eal),y
	adc eal
	sta amnext
	iny
	lda (eal),y
	adc eal+1
	sta amnext+1
	ldy #0
	lda (eal),y	; a string array?
	bmi arma8
	iny
	lda (eal),y
	bpl arma8
	ldy #4		; the elements, after 5 + 2 * dimensions
	lda (eal),y
	asl
	adc #5
	adc eal
	sta eal
	bcc arma3
	inc eal+1
arma3:
	lda eal
	cmp amnext
	lda eal+1
	sbc amnext+1
	bcs arma8	; past the last element
	ldy #0
	jsr strpast
	bcs arma4
	ldy #0		; its link is this element?
	lda (free_fb),y
	cmp eal
	bne arma4
	iny
	lda (free_fb),y
	cmp eal+1
	bne arma4
	lda #$ff	; the length, $ff
	sta (free_fb),y
	dey
	txa
	sta (free_fb),y
arma4:
	clc		; elements are 3 bytes
	lda eal
	adc #3
	sta eal
	bcc arma3
	inc eal+1
	bne arma3	; always
arma8:
	lda amnext	; on to the next array
	sta eal
	lda amnext+1
	sta eal+1
	jmp arma1
arm9a:
	rts

oldend:	byte 0,0
amnext:	byte 0,0

; the arrays from arytab to strend: each string array element's string
; points back to the element
arrlink:
	lda arytab
	sta eal
	lda arytab+1
	sta eal+1
arrl1:
	lda eal
	cmp strend
	lda eal+1
	sbc strend+1
	bcs arrl9	; done
	ldy #2		; sal: the next array (+2/+3: this one's size)
	clc
	lda (eal),y
	adc eal
	sta sal
	iny
	lda (eal),y
	adc eal+1
	sta sal+1
	ldy #0
	lda (eal),y	; a string array?
	bmi arrl8
	iny
	lda (eal),y
	bpl arrl8
	ldy #4		; the elements, after 5 + 2 * dimensions
	lda (eal),y
	asl
	adc #5
	adc eal
	sta eal
	bcc arrl3
	inc eal+1
arrl3:
	lda eal
	cmp sal
	lda eal+1
	sbc sal+1
	bcs arrl8	; past the last element
	ldy #0
	jsr strpast
	bcs arrl4
	ldy #0
	lda eal		; the back-link: the element's address
	sta (free_fb),y
	iny
	lda eal+1
	sta (free_fb),y
arrl4:
	clc		; elements are 3 bytes
	lda eal
	adc #3
	sta eal
	bcc arrl3
	inc eal+1
	bne arrl3	; always
arrl8:
	lda sal		; on to the next array
	sta eal
	lda sal+1
	sta eal+1
	jmp arrl1
arrl9:
	rts

; (eal),y: a string descriptor. If its string is in the string area
; (fretop to memsiz), free_fb/fc points just past it (to its back-link),
; .x is its length and carry is clear; carry set if not. Keeps .y.
strpast:
	lda (eal),y	; the length
	beq strp9	; empty: no string
	tax
	iny
	lda (eal),y
	sta free_fb
	iny
	lda (eal),y
	sta free_fc
	dey
	dey
	lda free_fb	; below fretop: not in the string area
	cmp fretop
	lda free_fc
	sbc fretop+1
	bcc strp9
	lda free_fb	; at or past memsiz: not either
	cmp memsiz
	lda free_fc
	sbc memsiz+1
	bcs strp9
	txa
	clc
	adc free_fb
	sta free_fb
	bcc strp1
	inc free_fc
strp1:
	clc
	rts
strp9:
	sec
	rts
