orig $0d00
; string input.asm

; **zeropage addresses**
strend	= $0035	; pointer to end of string stack
pointer	= $49	; pointer to descriptors
column	= $ec	; cursor column
lineptr	= $e0	; pointer: column 0 of current cursor line

bank0	= $0c03
bank1	= $0c06

; **own variables**
alowlen	= $00fb	; length of string with allowed chars
alowadr	= $fc	; pointer: address of string w/ allowed chars
startpos= $a3	; pointer: start position of input
length	= $a5	; maximal input length

; **kernal routines**
bsout	= $ffd2	; output character in accu
basin	= $ffcf	; input character from log. file
chkcom	= $795c	; check for comma
getpos	= $7aaf	; get descriptor position of variable
strres	= $9299	; reserve memory
getin	= $ffe4	; get a character from keyboard buffer
setcrs	= $fff0	; set cursor
open	= $ffc0	; open file
close	= $ffc3	; close file
chkin	= $ffc6	; set input channel to logical file
clrch	= $ffcc	; set input to keyboard, output to screen
setlfs	= $ffba	; set file parameters
setnam	= $ffbd	; set file name

;**save parameters**
string_input:
	sta length
	txa
	pha
	tya
	pha

; **set cursor**
	clc
	jsr setcrs	; set cursor

; **get descriptors allow string**
	jsr chkcom
	jsr getpos
	jsr bank1
	ldy #$02
getit:	lda (pointer),y
	sta alowlen,y
	dey
	bpl getit
	jsr bank0

; **input loop**
get:	jsr invert	; invert character
get1:	jsr getin
	beq get
	jsr invert
; **return?**
	cmp #$0d
	beq return

; **allowed character?**
	ldy alowlen
	dey
compare:
	jsr bank1
	cmp (alowadr),y
	jsr bank0
	beq output
	dey
	bpl compare
	bmi get	; unconditional jump

; **character output**
output:
	jsr bsout
	jmp get

	; **cursor at start position**
return:
	pla	; get saved
	tay	; start
	pla	; position
	tax
	clc		; and put
	jsr setcrs	; cursor there

; **pointer to input position**
	lda lineptr+1   ; produce
	sta startpos+1  ; pointer to
	lda lineptr     ; input start
	clc
	adc column
	sta startpos
	bcc startp
	inc startpos+1

; **determine actual input length**
startp:
	ldy length
	dey
lact:	lda (startpos),y
	cmp #32
	bne okay	; remove
	dey		; tailing
	cpy #255	; spaces
	bne lact

	; **preparations for return string**
okay:	iny
	sty length	; save length
	jsr chkcom	; pointer on
	jsr getpos	; return string

	lda length
	jsr strres	; reserve space


; **test for zero input string length**
	lda length	; was the string empty?
	beq update	; yes, then only update descriptors

; **screen: open logical file**
	lda #3
	tax
	tay
	jsr setlfs
	lda #0
	jsr setnam
	jsr open
	ldx #3
	jsr chkin

; **read/create string**
	ldy #0
read:	jsr basin
	jsr bank1
	sta (strend),y
	jsr bank0
	iny
	cpy length
	bne read

; **close file/standard input**
	jsr clrch
	lda #3
	jsr close

; **update descriptors**
update:
	jsr bank1
desupd:	ldy #0
	lda length
	sta (pointer),y
dupd:	lda strend,y
	iny
	sta (pointer),y
	cpy #2
	bne dupd
	jsr bank0
	rts             ; return to basic

; **invert char under cursor**
invert:	pha
;	lda $dc08
	ldy column
	lda (lineptr),y
	eor #128
	sta (lineptr),y
	pla
	rts
