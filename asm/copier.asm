; copier.asm -- "++ copier": the file "protocol" used in Console Local
; mode, and by i.CP (Copy-All). It copies between two files BASIC has
; already opened: file #3 is read, file #2 is written. Nothing is closed
; except as noted.
;
; &,16,0    copy all of #3 to #2, in blocks of up to 254 bytes, until
;           the end of #3 (status <> 0); "Good:" counts the blocks
; &,16,1    count the bytes in #3 ("Bytes:" counts them), write the count
;           to #2 as 3 bytes (low, middle, high), then close #3
; &,16,2    read a 3-byte count (low, middle, high) from #3, then copy
;           that many more bytes of #3 to #2, as &,16,0 does
; &,16,3    compare #3 with #2 (both opened for reading), a block at a
;           time ("Bytes:" counts the bytes compared): a% = 0 if they're
;           the same, 1 if not; b% = the number of the first byte that
;           differs, or of the first byte past the end of the shorter file
;           (its low 16 bits)
; &,16,255  a% = 2, the protocol number
;
; &,16,1 then &,16,0 into the same #2 writes a file behind its length;
; &,16,2 on that copies the file back out, stopping at its end (so more
; can follow it).
;
; The counters are the digits of the protocol screen's row 15
; (" Good: 00000  Bad: 00000  Bytes: 000000 ", drawn by sub.display):
; pbuf0 is that row of screen memory, and gcount/bcount/ncount the
; columns of each counter's last digit. Bad: isn't used here.
;
; Ported on 2026-11-05 from ImageBBS3's source/copier.s (3.1, with
; &,16,3; the 3.0 release's has calls 0-2 and 255 only), C64 values in
; the comments:
; - runs at protostart ($1c00; c64 $c000), where &,7,dv%,2 loads it
; - the KERNAL through the ML's ROM stubs (close: closef)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63)
; - 80 columns: the VIC screen isn't seen there, so each call (0-3) first
;   copies the counter line the module printed on the VDC into pbuf0's
;   row, and each counter cell that changes goes back to the VDC (&,72,
;   vdccell in vdc.asm; nothing in 40 columns). "Good:" goes cell by
;   cell; "Bytes:", which counts every byte, every 64 bytes and when the
;   call ends, as a farcall a byte would slow &,16,1 and &,16,3 down

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

gcount = 11	; last digit of "Good:"
bcount = 23	; last digit of "Bad:" (not used)
ncount = 38	; last digit of "Bytes:"

pbuf0	= $658	; screen memory, row 15
pbufrow	= 15	; 128: its row (for &,72)
; 11/07/2026: the block buffer in protobuf ($2b00, the overlays' block
; transfer area), not screen memory ($400, as the c64's): the 40-column
; screen's top rows showed each block, over setup's own lines and frame
pbuf1	= protobuf	; copy buffer (one block, up to 254 bytes)

	orig protostart	; c64: $c000

; &,16,x passes x in X: 255 (wraps to 0 on inx) = protocol number,
; then 0, 1, 2, 3
proto:
	inx
	beq protonum
	txa		; 128: in 80 columns, the counter line from the VDC
	pha
	ldx #pbufrow+64
	ldy #0
	lda #72
	jsr usetbl1
	pla
	tax
	dex
	beq copyall	; &,16,0
	dex
	beq jcount	; &,16,1
	dex
	beq copysome	; &,16,2
	dex
	beq jcompare	; &,16,3
	rts

jcount:
	jmp count
jcompare:
	jmp compare

; &,16,255: a% = 2
protonum:
	lda #0
	sta varbuf	; c64: $61
	lda #2
	sta varbuf+1	; c64: $62
	ldx #var_a_integer
putvar:
	lda #30
	jmp usetbl1	; c64: $cd03

; &,16,2: the count to copy is the first 3 bytes of #3
copysome:
	ldx #3
	jsr chkin
	jsr getin
	sta flen
	jsr getin
	sta flen+1
	jsr getin
	sta flen+2
	jsr clrchn
	jmp copy

; &,16,0: count = $ffffff, so the copy ends at end of file
copyall:
	lda #$ff
	sta flen
	sta flen+1
	sta flen+2
; copy #3 to #2 a block at a time, until the count runs out or #3 ends
copy:
	lda #0
	sta done
; read up to 254 bytes into pbuf1, counting flen down
cp1:
	ldx #3
	jsr chkin
; 11/07/2026: the status cleared for each block: nothing else clears it
; between blocks, and writing a block to another drive (a CMD HD on the
; bus) left a bit in it, which the next block's first read took for the
; end of the file (setup's copies stopped after a few blocks)
	lda #0
	sta status
	ldy #0
	ldx #0
cp2:
	jsr chrin
	sta pbuf1,y
	iny
	lda flen
	bne cp4
	lda flen+1
	bne cp3
	dec flen+2
cp3:
	dec flen+1
cp4:
	dec flen
	lda flen
	ora flen+1
	ora flen+2
	bne cp5
	inc done
	bne cp6
cp5:
	cpy #254
	beq cp6
	lda status
	beq cp2
	inc done
; write the block to #2, add 1 to "Good:"; again unless done
cp6:
	sty buflen
	jsr clrchn
	ldx #2
	jsr chkout
	ldy #0
cp7:
	lda pbuf1,y
	jsr chrout
	iny
	cpy buflen
	bne cp7
	jsr clrchn
	jsr goodblok
	lda done
	beq cp1
	rts

; &,16,1: count the bytes of #3, adding 1 to "Bytes:" for each
count:
	ldx #3
	jsr chkin
	lda #0
	sta flen
	sta flen+1
	sta flen+2
count1:
	jsr getin
	inc flen
	bne nxtcount
	inc flen+1
	bne nxtcount
	inc flen+2
nxtcount:
	jsr goodbyte
	lda status
	beq count1
; write the count to #2, low byte first, and close #3
	jsr clrchn
	jsr showbytes	; 128: "Bytes:" as it ended, on the VDC
	ldx #2
	jsr chkout
	lda flen
	jsr chrout
	lda flen+1
	jsr chrout
	lda flen+2
	jsr chrout
	jsr clrchn
	lda #3
	jmp closef	; c64: $ffc3

; &,16,3: compare #3 with #2. Read up to 254 bytes of #3 into pbuf1, then
; the same number of #2, checking each against pbuf1 as it's read; flen
; counts the bytes compared (as "Bytes:" does)
compare:
	lda #0
	sta flen
	sta flen+1
	sta flen+2
cm1:
	ldx #3
	jsr chkin
	lda #0		; 11/07/2026: as cp1: a clean status for this block
	sta status
	ldy #0
cm2:
	jsr chrin
	sta pbuf1,y
	iny
	lda status
	bne cm3
	cpy #254
	bne cm2
cm3:
	sty buflen
	sta done	; #3's status after this block: nonzero = it ended
	jsr clrchn
	ldx #2
	jsr chkin
	lda #0		; 11/07/2026: #3's status (its end, or a bit another
	sta status	; drive left) isn't #2's: the compare stopped at byte 1
	ldy #0
cm4:
	jsr chrin
	pha
	jsr incpos
	pla
	cmp pbuf1,y
	bne cm9		; differs at byte flen
	iny
	lda status
	bne cm5
	cpy buflen
	bne cm4
cm5:
	sty len2
	sta st2		; #2's status: nonzero = it ended
	jsr clrchn
; this block matched: did both files end here, neither, or only one?
	lda len2
	cmp buflen
	bne short	; #2 ended before #3's block did
	lda done
	bne cm6
	lda st2
	bne short	; #2 ended, #3 didn't
	jmp cm1
cm6:
	lda st2
	beq short	; #3 ended, #2 didn't
	lda #0		; both ended: the same
	beq setab
cm9:
	jsr clrchn
	lda #1
	bne setab
; one file is longer: b% = the byte after the shorter one's end
short:
	jsr incpos
	lda #1
; a% = A, b% = low 16 bits of flen
setab:
	jsr showbytes	; 128: "Bytes:" as it ended, on the VDC (keeps .a)
	sta varbuf+1	; c64: $62
	lda #0
	sta varbuf	; c64: $61
	ldx #var_a_integer
	jsr putvar
	lda flen+1
	sta varbuf	; c64: $61
	lda flen
	sta varbuf+1	; c64: $62
	ldx #var_b_integer
	jmp putvar

; add 1 to flen and to "Bytes:"; keeps Y
incpos:
	inc flen
	bne incpos1
	inc flen+1
	bne incpos1
	inc flen+2
incpos1:
	tya
	pha
	jsr goodbyte
	pla
	tay
	rts

len2:
	byte 0	; bytes of #2 read in this block
st2:
	byte 0	; #2's status after this block

buflen:
	byte 0	; bytes in pbuf1
flen:
	byte 0,0,0	; byte count, low byte first
done:
	byte 0	; nonzero: last block

; add 1 to the 6-digit "Bytes:" counter on the screen (128: to the VDC
; every 64 bytes; flen counts the same bytes in &,16,1 and &,16,3)
goodbyte:
	ldx #ncount
	ldy #6
	clc		; 128: not cell by cell
	jsr counter0
	lda flen
	and #63
	bne goodbyt9
	jmp showbytes
goodbyt9:
	rts
; add 1 to the 5-digit "Good:" counter on the screen
goodblok:
	ldx #gcount
	ldy #5
	sec		; 128: each cell that changes to the VDC too
; add 1 to the Y-digit counter whose last digit is at pbuf0+X (128: carry
; set, each cell that changes to the VDC too)
counter0:
	ror showflag	; bit 7: the carry
counter:
	inc pbuf0,x
	lda pbuf0,x
	cmp #':'
	bne counter2
	lda #'0'
	sta pbuf0,x
	jsr showif
	dex
	dey
	bne counter
	rts
counter2:
showif:
	bit showflag
	bmi showcell
	rts
showflag:
	byte 0

; 128, 11/05/2026: the cell at pbuf0+.x to the VDC (&,72, vdccell;
; nothing in 40 columns). Keeps .x .y
showcell:
	txa
	pha
	tya
	pha
	txa
	tay
	ldx #pbufrow
	lda #72
	jsr usetbl1
	pla
	tay
	pla
	tax
	rts
; "Bytes:"'s six digits to the VDC. Keeps .a .x .y
showbytes:
	pha
	txa
	pha
	tya
	pha
	ldx #ncount-5
showbyt1:
	jsr showcell
	inx
	cpx #ncount+1
	bcc showbyt1
	pla
	tay
	pla
	tax
	pla
	rts
