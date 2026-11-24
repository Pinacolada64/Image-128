; using.asm -- &,15,9: what BASIC prints on the screen, into a string, so
; BASIC 7.0's PRINT USING can format a number for Image's & output
; (11/24/2026, the user's request):
;
;	&,15,9:print using "##,###.##";x;:&,15,9,1:&"You owe $"+a$+".{f6}"
;
; &,15,9          starts: BASIC's PRINTs to the screen go to usebuf, not
;                 the screen, from here
; &,15,9,1        stops, and puts what was printed in a$
; &,15,9,1,s$     stops, and puts it in s$ (any string variable)
;
; Image's CHROUT hook (iosetup: ICHROUT $0326 -> newout_far -> out,
; shdlr.asm) is where BASIC's PRINT goes, so out keeps a screen character
; (device 3) here while usecap is set: print#, cmd and & output aren't
; touched (& output goes to prtscn and the modem itself, not CHROUT).
; Returns are dropped, so PRINT USING with or without its ";" gives the
; same string; past 128 characters the rest is dropped. PUDEF works as
; usual (the fill, comma, point and dollar characters).
;
; In the shared bottom 16K after status.asm (glue's area, visible in every
; configuration), as the & call runs in cfg_ml and out does too.

usebuf	= $3f80		; 128 bytes, to $3fff: ml.asm's addrcheck keeps
			; the code below it

; the & call (strio.asm's convtbl, 9): .y the third number
using:
	cpy #0
	bne using1
	sty uselen	; &,15,9: start, empty
	iny
	sty usecap
	rts
using1:
	lda #0		; &,15,9,1: stop
	sta usecap
	jsr chrgot
	cmp #comma
	bne using2
	jsr chkcom
	jsr ptrget	; varpnt: the variable named
	bit valtyp
	bmi using3	; a string
	rts		; a number: left as it is
using2:
	ldx #var_a_string
	jsr varname	; varpnt: a$
using3:
	lda varpnt	; kept: makeroom may use it
	pha
	lda varpnt+1
	pha
	lda uselen
	jsr makeroom	; .a bytes: varbuf
	pla
	sta varpnt+1
	pla
	sta varpnt
	ldy #0
using4:
	cpy uselen
	bcs using5
	lda usebuf,y
	sta (varbuf+1),y
	iny
	bne using4
using5:
	jmp putvar2	; varbuf into the variable

; from out (shdlr.asm), a screen character while usecap is set: kept in
; usebuf, or dropped (a return, or the buffer full)
usechr:
	lda ptr1	; the character
	cmp #$0d
	beq usechr9
	ldy uselen
	bmi usechr9	; 128 already
	sta usebuf,y
	inc uselen
usechr9:
	rts

usecap:
	byte 0		; 1: out keeps screen characters in usebuf
uselen:
	byte 0		; how many are there
