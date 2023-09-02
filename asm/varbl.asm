; ********************************
; *  variable handling routines  *
; ********************************

; * get descriptor for tt$(.x)
getarr:
	jsr findarr
	ldy #2
	jmp usevar1

;* get and copy memory to buffer
getln:
	jsr getarr
	ldy var
	sty index
getln0:
	dey
	cpy #$ff
	beq getln1
	cpy #80
	bcs getln0
	lda (var+1),y
	sta buffer,y
	jmp getln0
getln1:
	rts

;* print tt$(.a)
prtln:
	jsr getarr
	jmp outstr

;* put descriptor for tt$(.x) and
;* store buffer in memory
putarr:
	jsr findarr
	ldy #2
	jmp putvar1

;* put and store string
putln:
	txa
	pha
	lda index
	jsr makeroom
	ldy index
	beq putln2
	dey
putln1:
	lda buffer,y
	sta (var+1),y
	dey
	bpl putln1
putln2:
	pla
	tax
	jmp putarr

;* find descriptor for tt$(.x)
findarr:
	stx varpnt	; c64: $47
	lda #0
	asl varpnt	; c64: $47
	rol
	sta varpnt+1	; c64: $48
	txa
	clc
	adc varpnt	; c64: $47
	sta varpnt	; c64: $47
	lda #0
	adc varpnt+1	; c64: $48
	sta varpnt+1	; c64: $48
	clc
	lda arytab	; c64: $2f
	adc varpnt	; c64: $47
	sta varpnt	; c64: $47
	lda arytab+1	; c64: $30
	adc varpnt+1	; c64: $48
	sta varpnt+1	; c64: $48
	clc
	lda #7
	adc varpnt	; c64: $47
	sta varpnt	; c64: $47
	lda #0
	adc varpnt+1	; c64: $48
	sta varpnt+1	; c64: $48
	rts

;* get variable pointer of basic variable .x in vars table
; returns:
;	.x: > variable pointer
;	.y: < variable pointer
gvarptr:
	txa
	asl
	tay
	clc
	lda vars,y
	adc vartab	; c64: $2d
	tax
	lda vars+1,y
	adc vartab+1	; c64: $2e
	tay
	rts

varname:
	jsr gvarptr
	stx varpnt	; c64: $47
	sty varpnt+1	; c64: $48
	rts
findvar:
	sta varnam	; c64: $45
	stx varnam+1	; c64: $46
	jmp findvar1

;* print string variable
prtvar:
	jsr usevar
	jmp outstr

;* print string variable w/mci
prtvar0:
	lda mci
	pha
	lda #0
	sta mci
	jsr prtvar
	pla
	sta mci
	rts

;* get variable descriptor
usevar:
	jsr varname
	jmp usevar2
usevar0:
	jsr findvar
usevar2:
	ldy #4
usevar1:
	lda (varpnt),y	; c64: $47
	sta var,y
	dey
	bpl usevar1
	rts

;* put variable descriptor
putvar:
	jsr varname
	jmp putvar2
putvar0:
	jsr findvar
putvar2:
	ldy #4
putvar1:
	lda var,y
	sta (varpnt),y	; c64: $47
	dey
	bpl putvar1
	rts

zero:
	lda #0
	ldy #4
zero1:
	sta var,y
	dey
	bpl zero1
	rts
minusone:
	jsr zero
	lda #$81
	sta var
	rts

; ********************************
; *     variables used by ml     *
; ********************************

vars:
	byte $41, $ce	;  0 an$
	byte $41, $80	;  1 a$
	byte $42, $80	;  2 b$
	byte $54, $d2	;  3 tr$
	byte $44, $b1	;  4 d1$: 11-digit current date string
	byte $44, $b2	;  5 d2$
	byte $44, $b3	;  6 d3$
	byte $44, $b4	;  7 d4$
	byte $44, $b5	;  8 d5$
	byte $4c, $c4	;  9 ld$: user's last call date
	byte $54, $d4	; 10 tt$
	byte $4e, $c1	; 11 na$: user's handle
	byte $52, $ce	; 12 rn$: user's real name
;	byte $50, $c8	; 13 ph$: phone number
	byte $45, $cd	; 13 em$: email address
	byte $41, $cb	; 14 ak$: separator line + "{f6}"
	byte $4c, $50	; 15 lp: Disable or enable word-wrap for & text output.
			;	lp=0: disable word-wrap, lp=1: enable word-wrap
	byte $50, $4c	; 16 pl: Case flag for user input.
			;	FIXME: pl=0: uppercase/lowercase, pl=1: uppercase only (like £Ix)?
 	byte $52, $43	; 17 rc
	byte $53, $48	; 18 sh: spacebar hit
	byte $4d, $57	; 19 mw
	byte $4e, $4c	; 20 nl: graphics mode
	byte $55, $4c	; 21 ul
	byte $51, $45	; 22 qe
	byte $52, $51	; 23 rq
	byte $c1, $c3	; 24 ac%: access level
	byte $45, $46	; 25 ef: Extended Command Set flag
	byte $4c, $46	; 26 lf: linefeed mode
	byte $57, $80	; 27 w$: wrapped text/reply to prompt
	byte $50, $80	; 28 p$: prompt string
	byte $d4, $d2	; 29 tr%: time remaining on BBS
	byte $c1, $80	; 30 a%
	byte $c2, $80	; 31 b$
	byte $c4, $d6	; 32 dv%: device number
	byte $44, $d2	; 33 dr$: drive number
	byte $43, $b1	; 34 c1$: "Entering Chat Mode" string
	byte $43, $b2	; 35 c2$: "Exiting Chat Mode" string
	byte $43, $cf	; 36 co$: computer type string
	byte $43, $c8	; 37 ch$: copy of co$?
	byte $cb, $d0	; 38 kp%: keypress ascii value?
	byte $43, $b3	; 39 c3$: "Returning to Editor" string
	byte $46, $b1	; 40 f1$: programmable function key definitions
	byte $46, $b2	; 41 f2$
	byte $46, $b3	; 42 f3$
	byte $46, $b4	; 43 f4$
	byte $46, $b5	; 44 f5$
	byte $46, $b6	; 45 f6$
	byte $46, $b7	; 46 f7$
	byte $46, $b8	; 47 f8$
	byte $4d, $d0	; 48 mp$: "...More?" prompt string
	byte $cd, $ce	; 49 mn%: minute of day?
