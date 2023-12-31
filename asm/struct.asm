{include:equates.asm}
orig protostart
; .pseudopc protostart {
; .namespace structml {

;putstruc - put string into struct
; &,nn,0,num,arry(a,b),string$
; arry(a,b) = starting element
; num = # of bytes
; string$ = the string

;getstruc - get string from struct
; &,nn,1,num,arry(a,b),string$
; arry(a,b) = starting element
; num = # of bytes
; string$ = the string

;lodstruc - load structure
; &,nn,2,0,arry(a,b),"file",dev
; arry(a,b) = starting element
; "file" = filename
; dev = device #

;savstruc - save structure
; &,nn,3,0,arry(a,b),bytes,"file",dev
; arry(a,b) = starting element
; bytes = # of bytes
; "file" = filename
; dev = device #

;putdate - put date into struct
; &,nn,4,0,arry(a,b),string$
; arry(a,b) = starting element
; string$ = the date string

;getdate - get date from struct
; &,nn,5,0,arry(a,b),string$
; arry(a,b) = starting element
; string$ = the string

;doscan - scan structures
; &,nn,6,num,com,a(a,b),b(a,b),l,bits,test
; com = command number
; com = 0: 2 byte and, <>0
; com = 1: 2 byte and, ==0
; com = 2: 2 byte cmp, <
; com = 3: 2 byte cmp, >=
; com = 4: date cmp, <
; com = 5: date cmp, >=
; num = # of structures to scan
; a(a,b) = starting flags element
; b(a,b) = starting object element
; bits = the bits to set if true
; test = the object to test for

ilen	= var	; c64: $61 ;1
istr	= var+1	; c64: $62 ;2
iptr	= var+3	; c64: $64 ;2
jlen	= var+6	; c64: $69 ;1
jstr	= var+7	; c64: $6a ;2
jptr	= var+9	; c64: $6c ;2
temp	= $14	; c64: $14 ;2

opandy	= $39	; 57
opcmpy	= $d9	; 217
opbne	= $d0	; 208
opbcc	= $90	; 144
opbeq	= $f0	; 240
opbcs	= $b0	; 176

makerm	= $b475
getnxt	= $e206

defbase	= $c600

@entry1:
	jmp clrarr
@entry2:
	sty count
	stx func
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	txa
	sec
	sbc #4
	asl
	tax
	lda functbl,x
	sta strucjmp+1
	lda functbl+1,x
	sta strucjmp+2
strucjmp:
	jsr strucrts
	pla
	sta r6510
strucrts:
	rts

functbl:
	word putdate ;4
	word getdate ;5
	word doscan ;6
	word sort ;7
	word scannums ;8
	word scansum ;9
	word cpystruc ;10
	word scanstr ;11
	word gamescan ;12
	word textread ;13

; TODO move variable selection here since only one is used
@putvar:
	lda #30
	jmp usetbl1
; not called:
;xchrout:
;	sta $fe
;xchrout1:
;	lda #24
;	jmp usetbl1

count:
	byte 0
func:
	byte 0
@size:
	byte 0
scanfor:
	byte 0,0,0,0,0,0
bitmask:
	word 0
invert:
	byte 0
oper:
	byte 0

getsize:
	jsr evalbyt
	stx <@size
	rts
getword:
	jsr evalint
	sty scanfor
	stx scanfor+1
	rts

evaldate:
	jsr evalstr
	stx $62
	sty $63
	ldy #1
	ldx #0
evald1:
	lda ($62),y
	iny
	and #15
	asl
	asl
	asl
	asl
	sta scanfor,x
	lda ($62),y
	iny
	and #15
	ora scanfor,x
	sta scanfor,x
	inx
	cpx #5
	bcc evald1
evald2:
	ldy #0
	lda ($62),y
	sta scanfor+5
	ldx scanfor+3
	txa
	and #$7f
	cmp #$12
	bne evald3
	txa
	sec
	sbc #$12
	tax
evald3:
	stx scanfor+3
	rts

putdate:
	jsr fnvar1
	jsr evaldate
	ldy #0
putd1:
	lda scanfor,y
	sta ($14),y
	iny
	cpy #6
	bcc putd1
	rts

getdate:
	jsr fnvar1
	ldy #5
getd1:
	lda ($14),y
	sta scanfor,y
	dey
	bpl getd1
	jsr fnvar
	lda #11
	jsr makerm
	ldx scanfor+3
	txa
	and #$7f
	bne getd0
	txa
	clc
	adc #$12
	tax
getd0:
	stx scanfor+3
	lda scanfor+5
	ldx #0
	ldy #0
	sta ($62),y
	iny
getd2:
	lda scanfor,x
	inx
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta ($62),y
	iny
	pla
	and #15
	ora #$30
	sta ($62),y
	iny
	cpx #5
	bcc getd2
getd3:
	ldy #4
getd4:
	lda var,y	; $61,y
	sta (varpnt),y	; ($47),y
	dey
	bpl getd4
	rts

opc1:
	byte opandy,opcmpy
opc2:
	byte opbne, opbcc
opc3:
	byte opbeq, opbcs

scanbits:
	txa
	lsr
	tax
	and #1
	tay
	rts

doscan:
	jsr evalbyt
	stx oper
	txa
	and #1
	sta invert
	jsr scanbits
	lda opc1,y
	sta checkc0
	jsr scanbits
	lda opc1,y
	sta checkc1
	jsr scanbits
	lda opc2,y
	sta checkc2
	lda opc3,y
	sta checkc3
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr getsize
	jsr evalint
	sty bitmask
	stx bitmask+1
	lda oper
	and #64
	bne doscan1
	jsr getword
	lda #2
	jmp doscan2
doscan1:
	jsr evaldate
	lda #6
doscan2:
	sta checkc4+2
	pla
	sta jptr	; $6c
	pla
	sta jstr+1	; $6b
	pla
	sta jstr	; $6a
	pla
	sta jlen	; $69
	lda #0
	sta varbuf
	sta varbuf+1
	lda count
	beq doscan15
doscan3:
	lda oper
	bmi doscan6
	ldy #1
doscan5:
	lda bitmask,y
	eor #255
	and (jlen),y	; ($69),y
	sta (jlen),y	; ($69),y
	dey
	bpl doscan5
doscan6:
	ldy #0
doscan7:
	lda (jstr+1),y	; ($6b),y
checkc0:
	cmp scanfor,y
checkc1:
	cmp scanfor,y
	beq checkc4
checkc2:
	bne doscan9
checkc3:
	beq doscan8
checkc4:
	iny
	cpy #2
	bcc doscan7
doscan8:
	lda invert
	bne doscan10
	jmp doscan12
doscan9:
	lda invert
	bne doscan12
doscan10:
	ldy #1
doscan11:
	lda bitmask,y
	ora (jlen),y	; ($69),y
	sta (jlen),y	; ($69),y
	dey
	bpl doscan11
	inc varbuf+1
doscan12:
	ldx #2
doscan13:
	clc
	lda <@size
	adc (jlen),x	; $69,x
	sta (jlen),x	; $69,x
	bcc doscan14
	inc (jstr),x	; $6a,x
doscan14:
	dex
	dex
	bpl doscan13
	dec count
	bne doscan3
doscan15:
	ldx #var_a_integer
	jmp <@putvar

i:
	word 0
j:
	word 0
n:
	word 0
base:
	word 0

calcp:
	stx <temp
	sty <temp+1
	txa
	asl
	tax
	tya
	rol
	tay
	clc
	txa
	adc <temp
	tax
	tya
	adc <temp+1
	tay
	clc
	txa
	adc base
	tax
	tya
	adc base+1
	tay
	rts
calcs:
	stx <temp
	sty <temp+1
	ldy #0
	lda (<temp),y
	pha
	iny
	lda (<temp),y
	tax
	iny
	lda (<temp),y
	tay
	pla
	rts

strcmp:
	ldy #0
strcmp1:
	lda (jstr),y
	cmp (istr),y
	bne strcmp3
	iny
	cpy jlen
	bcs strcmp2
	cpy ilen
	bcc strcmp1
strcmp2:
	ldy jlen
	cpy ilen
strcmp3:
	rts

strptn:
	ldy #0
strptn1:
	lda (jstr),y
	cmp #function_key_2	; "?" wildcard
	beq strptn2
	cmp #function_key_7	; "*" wildcard
	beq strptn4
	cmp (istr),y
	bne strptn4
strptn2:
	iny
	cpy jlen
	bcs strptn3
	cpy ilen
	bcc strptn1
strptn3:
	ldy jlen
	cpy ilen
strptn4:
	rts

sort:
	jsr fnvar
	stx base
	sty base+1
	jsr evalint
	cpx #0
	bne sort0
	dey
sort0:
	dex
	stx n
	sty n+1
	ldx #0
	ldy #0
	stx i
	sty i+1
sort1:
	jsr calcp
	stx iptr
	sty iptr+1
	jsr calcs
	sta ilen
	stx istr
	sty istr+1
	ldx i
	ldy i+1
sort2:
	inx
	bne sort3
	iny
sort3:
	stx j
	sty j+1
	jsr calcp
	stx jptr
	sty jptr+1
	jsr calcs
	sta jlen
	stx jstr
	sty jstr+1
	jsr strcmp
	bcs sort8
	ldy #2
sort7:
	lda ilen,y
	sta (jptr),y
;	lda jlen,y
	lda $0069,y
	sta (iptr),y
	sta ilen,y
	dey
	bpl sort7
sort8:
	ldx j
	ldy j+1
	cpx n
	bne sort2
	cpy n+1
	bne sort2
	ldx i
	ldy i+1
	inx
	bne sort9
	iny
sort9:
	stx i
	sty i+1
	cpx n
	bne sort1
	cpy n+1
	bne sort1
	rts

; scan numbers
; &,nn,8,num,siz,acs,a(a,b),res%(s),start

; i/GF example:
; &,60,8,s%(0,0),80,1,s%(0,1),e%(1),1

; i/lo.instant example:
; &,52,4,3:&,60,8,fb%(.,.),60,2^(a%+3),fb%(11,1),ff%(1),1

; returns a%, # of results
; returns res%(), 1-dimensional array of results, 1-a%
scannums:
	jsr getsize
	jsr getword
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr evalbyt
	stx varbuf
	lda #0
	sta varbuf+2
	sta varbuf+1
	pla
	sta jstr	; $6a
	pla
	sta jlen	; $69
	pla
	sta jptr	; $6c
	pla
	sta jstr+1	; $6b
scannum1:
	lda count
	beq scannum6
	ldy #0
scannum2:
	lda (jstr+1),y	; ($6b),y
	and scanfor
	bne scannum3
	iny
	lda (jstr+1),y	; ($6b),y
	and scanfor+1
	beq scannum4
scannum3:
	ldy varbuf+2
	lda #0
	sta (jlen),y	; ($69),y
	iny
	lda varbuf
	sta (jlen),y	; ($69),y
	iny
	sty varbuf+2
	inc varbuf+1
scannum4:
	inc varbuf
	clc
	lda <@size
	adc jstr+1	; $6b
	sta jstr+1	; $6b
	bcc scannum5
	inc jptr	; $6c
scannum5:
	dec count
	bne scannum1
scannum6:
	lda #0
	sta varbuf
	ldx #var_a_integer
	jmp <@putvar

; sum
; &,nn,9,num,siz,a(a,b)

scansum:
	jsr getsize
	jsr fnvar
	stx jstr+1	; $6b
	sty jptr	; $6c
	lda #0
	sta varbuf
	sta varbuf+1
scansum1:
	lda count
	beq scansum4
	ldy #1
	clc
scansum2:
	lda (jstr+1),y	; ($6b),y
	adc varbuf,y
	sta varbuf,y
	dey
	bpl scansum2
	lda <@size
	adc jstr	; $6b
	sta jstr	; $6b
	bcc scansum3
	inc jptr	; $6c
scansum3:
	dec count
	bne scansum1
scansum4:
	ldx #var_a_integer
	jmp <@putvar

; copy
; &,nn,10,size,a1(a,b),a2(a,b)

cpystruc:
	jsr fnvar
	stx cpys1+1
	sty cpys1+2
	jsr fnvar
	stx cpys2+1
	sty cpys2+2
	ldy #0
cpys1:
	lda $ffff,y
cpys2:
	sta $ffff,y
	iny
	cpy count
	bcc cpys1
	rts

; scan for string
; &,nn,11,num,siz,op,str,a1(a,b),a2(b),start

stroplo:
	byte <strcmp,<strptn
strophi:
	byte >strcmp,>strptn

scanstr:
	jsr getsize
	jsr evalbyt
	txa
	and #1
	tax
	lda stroplo,x
	sta scanstr0+1
	lda strophi,x
	sta scanstr0+2
	jsr evalstr
	sta index
	tax
	ldy #0
scanstr_loop1:
	lda (index_24),y	; ($22),y
	sta buffer,y
	iny
	dex
	bne scanstr_loop1
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr fnvar
	txa
	pha
	tya
	pha
	jsr evalbyt
	stx iptr
	lda #0
	sta iptr+1
	pla
	sta jptr+1
	pla
	sta jptr
	pla
	sta istr+1
	pla
	sta istr
	lda #<buffer
	sta jstr
	lda #>buffer
	sta jstr+1
	lda index
	sta jlen
scanstr1:
	lda count
	beq scanstr5
	ldy #0
@:
	lda (istr),y
	beq scanstr2
	iny
	bne <@
scanstr2:
	sty ilen
scanstr0:
	jsr strcmp
	bne scanstr3
	ldy iptr+1
	lda #0
	sta (jptr),y
	iny
	lda iptr
	sta (jptr),y
	iny
	sty iptr+1
scanstr3:
	inc iptr
	clc
	lda <@size
	adc istr
	sta istr
	bcc scanstr4
	inc istr+1
scanstr4:
	dec count
	bne scanstr1
scanstr5:
	lda #0
	sta varbuf
	lda iptr+1
	lsr
	sta varbuf+1
	ldx #var_a_integer
	jmp <@putvar

arrays1:
; 0: tt$()	6: c%()
; 1: bb$()	7: d%()
; 2: dt$()	8: e%()
; 3: ed$()	9: f%()
; 4: nn$()	10: ac%()
; 5: a%()	11: so%()
	ascii "tbdenACDEFAS"
arrays2:
	ascii "TBTDN"
	byte $80, $80, $80, $80, $80
	ascii "CO"

; clear an array
clrarr:
	cpx #12
	bcs clrar7
	lda arytab	; 47
	sta varpnt	; 71
	lda arytab+1	; 48
	sta varpnt+1	; 72
clrar0:
	ldy #3
	lda (varpnt),y	; (71),y
	sta 21
	dey
	lda (varpnt),y	; (71),y
	sta 20
	dey
	lda (varpnt),y	; (71),y
	cmp arrays2,x
	bne clrar1
	dey
	lda (varpnt),y	; (71),y
	cmp arrays1,x
	beq clrar3
clrar1:
	clc
	lda 20
	adc varpnt	; 71
	sta varpnt	; 71
	lda 21
	adc varpnt+1	; 72
	sta varpnt+1	; 72
	lda varpnt	; 71
	cmp strend	; 49
	bne clrar2
	lda varpnt+1	; 72
	cmp strend+1	; 50
	beq clrar7
clrar2:
	jmp clrar0
clrar3:
	clc
	lda varpnt	; 71
	adc #7
	sta varpnt	; 71
	lda varpnt+1	; 72
	adc #0
	sta varpnt+1	; 72
	sec
	lda 20
	sbc #7
	sta 20
	lda 21
	sbc #0
	sta 21
clrar4:
	ldy #0
	tya
	sta (varpnt),y	; (71),y
	inc varpnt	; 71
	bne clrar5
	inc varpnt+1	; 72
clrar5:
	lda 20
	bne clrar6
	dec 21
clrar6:
	dec 20
	bne clrar4
	lda 21
	bne clrar4
clrar7:
	rts

; game scan
; &,60,12,count,size,a$,a%(a,b),b$

gamescan:
	jsr evalbyt
	stx <@size
	jsr evalstr
	lda index_24	; $22
	sta game2+1
	lda index_24+1	; $23
	sta game2+2
	jsr fnvar1
	jsr fnvar
	lda count
	asl
	jsr makerm
	ldy #0
	sty index
game1:
	ldy #1
	lda ($14),y
	asl
	tax
	ldy index
	jsr game2
	jsr game2
	sty index
	clc
	lda $14
	adc <@size
	sta $14
	lda $15
	adc #0
	sta $15
	dec count
	bne game1
	ldy #4
game3:
	lda var,y	; $61,y
	sta (varpnt),y	; ($47),y
	dey
	bpl game3
	rts

game2:
	lda $ffff,x
	sta (var+1),y	; ($62),y
	inx
	iny
	rts

; textread:

; &,60,13,number,reclen,scan(),bits,text(),strlen

textread:
	jsr getsize
	jsr fnvar
	stx textr3+1
	sty textr3+2
	jsr getword
	jsr fnvar
	stx textr9+1
	sty textr9+2
	jsr evalbyt
	stx textr10+1
	ldx count
	beq textr7
textr1:
	ldy #1
textr2:
	lda scanfor,y
textr3:
	and $ffff,y
	bne textr8
	dey
	bpl textr2
textr4:
	clc
	lda textr3+1
	adc <@size
	sta textr3+1
	bcc textr5
	inc textr3+2
textr5:
	clc
	lda textr9+1
	adc <@size
	sta textr9+1
	bcc textr6
	inc textr9+2
textr6:
	dec count
	bne textr1
textr7:
	rts

textr8:
	ldy #0
textr9:
; self-modifying code:
	lda $ffff,y
	iny
	jsr chrout
textr10:
	cpx #0
	bcc textr9
	jmp textr4
