; post.asm -- "++ post": the message bases' index, for i.SB and
; i/NM.netsub3 (a$="post":gosub 28, then &,16,x...): it loads a base's
; index just past itself, saves it, and finds a message in it by binary
; search, as ++ index does for u.index.
;
; Ported from the 3.0 release's "++ post" (MASTER D1 231231.d81, 6 blocks;
; "01/08/91  1:39A"), not from source/post.s: that is an older version
; ("03/22/90 01:08a", 1578 bytes against the release's 1472, with the
; serial-number copy check the release doesn't have). The release was
; disassembled by tools/ovl_dis.py (it reassembles at $c000 byte for
; byte), then ported on 2026-10-29 as index.asm was (the C64's values are
; in the comments):
; - runs at protostart ($1c00), where &,7,dv%,2 loads it; the index it
;   loads and saves starts at last, its last byte (#<last/#>last;
;   c64 #$bf/#$c5)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63), its buffers
;   buf2 and buffer ($0e27, $0e77; c64 $ce27, $ce77), its & dispatcher
;   usetbl1 ($192a; c64 $cd03); index ($d00f) is the same on the 128
; - the KERNAL through the ML's ROM stubs, the ROM being out in cfg_ml;
;   setbnk before LOAD and SAVE: the index in bank 0, the filename (a$)
;   in bank 1 (the TODO's warning: without it the KERNAL read the name
;   from whatever bank the last setbnk left)
; - $fb/$fc stay: farcall puts them back (glue.asm)

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
proto4_entry:
	jmp proto4
	byte $08	; the overlay's number (c64 source: 255)

; the binary search's indices: high, low and current

h_msb:
	byte $00
h_lsb:
	byte $00
l_msb:
	byte $00
l_lsb:
	byte $00
x_msb:
	byte $00
x_lsb:
	byte $00

; the command that positions the REL file to a record ("p", the channel,
; the record low and high, the position in it, CR). The release keeps the
; data file's number in the channel byte, ptrchan, and uses it for its
; reads and writes too (setfile sets it; the 1990 source had 2 everywhere)

ptrcom:
	byte $50	; "p"
ptrchan:
	byte $02
ptr_lsb:
	byte $00
ptr_msb:
	byte $00
ptrpos:
	byte $01,$0d

xx_lsb:
	byte $00
xx_msb:
	byte $00
ptr2_lsb:
	byte $00
ptr2_msb:
	byte $00

; the command channel's file number (15; setcmd sets it), in place of the
; 1990 source's copy0, copy1 and fake (the serial-number copy check's)
cmdchan:
	byte $0f

; FIND      &,16      binary search for an$ in the REL file (file ptrchan,
;                     command channel cmdchan): if found a%=the value,
;                     b%=its position; if not, a%=0, b%=where to insert
; LOADINDX  &,16,1    load an index file (a$, dv%) to "last"
; SAVEINDX  &,16,2    save it
; MAKEINDX  &,16,3    clear the index
; INSTINDX  &,16,4    insert a% at position b%
; DELTINDX  &,16,5    delete position b%
; NEXTINDX  &,16,6    the value after position b%: a%, and b% the new one
; SETCRSKP  &,16,7    CRs to skip when reading a record (.y): to index a
;                     field other than the first
; LOADPOST  &,16,8    read a post's index from its REL file, from record b%
;                     (a chain: next record, length, bytes); a% = its count
; SAVEPOST  &,16,9    write it back, from record a%, b% = where it starts
; NUMBINDX  &,16,10   a% = the index's count
; READPOST  &,16,11   release: &,59 (farerr); post reading is swap3's
;                     relread (&,57) now (1990 source: postread, here)
; SETCMD    &,16,12   cmdchan = .y (new in the release)
; SETFILE   &,16,13   ptrchan = .y (new in the release)
; &,16,255            a% = 8, the overlay's number (new in the release)
proto4:
	cpx #$ff
	beq identify
	txa
	beq find
	dex
	beq loadindx
	dex
	beq saveindx
	dex
	beq makeindx
	dex
	beq instindx
	dex
	beq deltindx
	dex
	beq nextindx
	dex
	beq setcrskp
	dex
	beq loadpost
	dex
	beq savepost
	dex
	beq numbindx
	dex
	beq readpost
	dex
	beq setcmd
	dex
	beq setfile
	rts
loadindx:
	jmp loadfile
saveindx:
	jmp savefile
makeindx:
	jmp makefile
instindx:
	jmp insert
deltindx:
	jmp delete
nextindx:
	jmp getnext
setcrskp:
	jmp setskip
loadpost:
	jmp postload
savepost:
	jmp postsave
numbindx:
	jmp indxcnt
readpost:
	jmp postread
setcmd:
	jmp setcmdch
setfile:
	jmp setfilech
identify:
	jmp ident
find:
	ldx #var_an_string
	jsr usevar
	ldy #$00
findloop:
	lda (varbuf+1),y	; c64: $62
	sta buffer,y	; c64: $ce77
	iny
	cpy varbuf	; c64: $61
	bcc findloop
	lda #$00
	sta buffer,y	; c64: $ce77
	sty xlen1
	lda last
	ldx last+1
	sta h_msb
	stx h_lsb
	lda #$00
	ldx #$01
	sta l_msb
	stx l_lsb
	lda l_msb
	ldx l_lsb
	sta x_msb
	stx x_lsb
	jsr check
	beq found_it
	bcs find1
	jmp xputavar
find1:
	lda h_msb
	ldx h_lsb
	sta x_msb
	stx x_lsb
	jsr check
	beq found_it
	bcc find2
	lda h_msb
	ldx h_lsb
	inx
	bne find1a
	clc
	adc #$01
find1a:
	sta x_msb
	stx x_lsb
	jmp xputavar
found_it:
	jmp putavar
find2:
	lda l_msb
	cmp h_msb
	bne find3
	lda l_lsb
	cmp h_lsb
	bne find3
	jmp xputavar
find3:
	clc
	lda l_lsb
	adc h_lsb
	sta x_lsb
	lda l_msb
	adc h_msb
	sta x_msb
	lsr x_msb
	ror x_lsb
	lda x_msb
	cmp l_msb
	bne find4
	lda x_lsb
	cmp l_lsb
	bne find4
	lda h_msb
	ldx h_lsb
	sta l_msb
	stx l_lsb
	sta x_msb
	stx x_lsb
find4:
	jsr check
	beq found_it
	lda x_msb
	ldx x_lsb
	bcc find11
	sta l_msb
	stx l_lsb
	jmp find2
find11:
	sta h_msb
	stx h_lsb
	jmp find2
check:
	jsr sendptr
	lda skip
	sta skip2
	beq check2
check1:
	dec skip2
check2:
	ldx ptrchan
	ldy #$00
	jsr dskin
	lda skip2
	bne check1
	jmp compare
sendptr:
	jsr calcptr
sendcom:
	ldx cmdchan
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	ldy #$00
	ldx #$06
sendloop:
	lda ptrcom,y
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	iny
	dex
	bne sendloop
	jmp clrchn	; c64: $ffcc (the ROM is out in cfg_ml)
calcptr:
	lda x_lsb
	asl
	tay
	lda x_msb
	rol
	tax
	clc
	tya
	adc #<last	; c64: #$bf
	sta $fb
	txa
	adc #>last	; c64: #$c5
	sta $fc
	ldy #$00
	lda ($fb),y
	sta ptr_msb
	iny
	lda ($fb),y
	sta ptr_lsb
	rts
compare:
	ldy #$00
comploop:
	lda buffer,y	; c64: $ce77
	cmp buf2,y	; c64: $ce27
	bne compare1
	iny
	cpy xlen1
	beq compare2
	cpy index	; c64: $d00f, the same on the 128
	bne comploop
compare2:
	ldy xlen1
	cpy index	; c64: $d00f, the same on the 128
compare1:
	rts
xlen1:
	byte $00
loadfile:
	ldx #var_a_string
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd (the ROM is out in cfg_ml)
	ldx #var_dv_integer
	jsr usevar
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #$00
	ldx #<last	; c64: #$bf
	ldy #>last	; c64: #$c5
	jsr loadf	; c64: $ffd5 (the ROM is out in cfg_ml)
indxcnt:
	lda last
	ldx last+1
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #var_a_integer
	jmp putvar
savefile:
	ldx #var_a_string
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: $ffbd (the ROM is out in cfg_ml)
	ldx #var_dv_integer
	jsr usevar
	lda #$08
	ldx varbuf+1	; c64: $62
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	lda #0		; 128: the data in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jsr setbnk
	lda #<last	; c64: #$bf
	ldx #>last	; c64: #$c5
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	lda last+1
	asl
	tax
	lda last
	rol
	tay
	clc
	txa
	adc #<last	; c64: #$bf
	tax
	tya
	adc #>last	; c64: #$c5
	tay
	clc
	txa
	adc #$03
	tax
	tya
	adc #$00
	tay
	lda #varbuf	; the start pointer for SAVE (c64: #$61)
	jmp savef	; c64: $ffd8 (the ROM is out in cfg_ml)
makefile:
	lda #$00
	sta last
	sta last+2
	lda #$00
	sta last+1
	sta last+3
	rts
xputavar:
; enter with value in .x
	lda #$00
	sta ptr_lsb
	sta ptr_msb
putavar:
	lda ptr_msb
	ldx ptr_lsb
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #var_a_integer
	jsr putvar
	lda x_msb
	ldx x_lsb
	sta varbuf	; c64: $61
	stx varbuf+1	; c64: $62
	ldx #var_b_integer
	jsr putvar
	lda ptr_lsb
	ora ptr_msb
	rts
insert:
	ldx #var_b_integer
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta x_msb
	stx x_lsb
	inc last+1
	bne insert1a
	inc last
insert1a:
	ldx #var_a_integer
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta ptr_msb
	stx ptr_lsb
insert2:
	lda ptr_lsb
	ldx ptr_msb
	sta h_lsb
	stx h_msb
	jsr calcptr
	ldy #$00
	lda h_msb
	sta ($fb),y
	iny
	lda h_lsb
	sta ($fb),y
	lda x_lsb
	cmp last+1
	bne insert3
	lda x_msb
	cmp last
	bne insert3
	rts
insert3:
	inc x_lsb
	bne insert3a
	inc x_msb
insert3a:
	jmp insert2
delete:
	ldx #var_b_integer
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta x_msb
	stx x_lsb
delete1:
	lda x_msb
	cmp last
	bne delete2
	lda x_lsb
	cmp last+1
	beq delete3
delete2:
	jsr calcptr
	ldy #$03
	lda ($fb),y
	pha
	dey
	lda ($fb),y
	tax
	dey
	pla
	sta ($fb),y
	dey
	txa
	sta ($fb),y
	inc x_lsb
	bne delete2a
	inc x_msb
delete2a:
	jmp delete1
delete3:
	lda last+1
	bne delete3a
	dec last
delete3a:
	dec last+1
	rts
getnext:
	ldx #var_b_integer
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	sta x_msb
	stx x_lsb
	inc x_lsb
	bne getnext1
	inc x_msb
getnext1:
	jsr calcptr
	jmp putavar
setskip:
	sty skip
	rts
skip:
	byte $00
skip2:
	byte $00
postload:
	jsr makefile
	ldx #var_b_integer
	jsr usevar
	lda varbuf+1	; c64: $62
	sta ptr_lsb
	lda varbuf	; c64: $61
	sta ptr_msb
	lda #<last	; c64: #$bf
	sta $fb
	lda #>last	; c64: #$c5
	sta $fc
postld1:
	jsr sendcom
	ldx ptrchan
	ldy #$03
	jsr dskin
	lda buf2	; c64: $ce27
	sta ptr_lsb
	lda buf2+1	; c64: $ce28
	sta ptr_msb
	ldy buf2+2	; c64: $ce29
	sty l_msb
	ldx ptrchan
	cpy #$00
	beq postld3
	jsr dskin
	ldy #$00
postld2:
	lda buf2,y	; c64: $ce27
	sta ($fb),y
	iny
	cpy l_msb
	bne postld2
	lda $fb
	clc
	adc l_msb
	sta $fb
	bcc postld3
	inc $fc
postld3:
	lda ptr_lsb
	cmp #$00
	bne postld1
	lda ptr_msb
	cmp #$00
	bne postld1
	jmp indxcnt
postsave:
	ldx #var_a_integer
	jsr usevar
	lda varbuf+1	; c64: $62
	sta xx_lsb
	sta ptr_lsb
	lda varbuf	; c64: $61
	sta xx_msb
	sta ptr_msb
	jsr sendcom
	ldx #$01
	jsr tenwait
	jsr sendcom
	ldx ptrchan
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	lda #$00
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr sendcom
	ldx #var_b_integer
	jsr usevar
	lda varbuf+1	; c64: $62
	sta ptr_lsb
	lda varbuf	; c64: $61
	sta ptr_msb
	lda #<last	; c64: #$bf
	sta postsv2+1
	lda #>last	; c64: #$c5
	sta postsv2+2
	lda last+1
	asl
	tax
	lda last
	rol
	tay
	clc
	txa
	adc #<last	; c64: #$bf
	tax
	tya
	adc #>last	; c64: #$c5
	tay
	clc
	txa
	adc #$02
	sta l_msb
	tya
	adc #$00
	sta l_lsb
postsv0:
	jsr sendcom
	ldx ptrchan
	ldy #$02
	jsr dskin
	jsr sendcom
	lda ptr_lsb
	sta ptr2_lsb
	lda ptr_msb
	sta ptr2_msb
	ldx #$01
	jsr tenwait
	jsr sendcom
	lda ptr_lsb
	sta varbuf+1	; c64: $62
	lda ptr_msb
	sta varbuf	; c64: $61
	ldx #var_b_integer
	jsr putvar
	lda buf2	; c64: $ce27
	sta ptr_lsb
	lda buf2+1	; c64: $ce28
	sta ptr_msb
	cmp #$00
	bne postsv1
	lda ptr_lsb
	cmp #$00
	bne postsv1
	lda xx_lsb
	sta buf2	; c64: $ce27
	lda xx_msb
	sta buf2+1	; c64: $ce28
	inc xx_lsb
	bne postsv1a
	inc xx_msb
postsv1a:
	lda xx_lsb
	sta ptr_lsb
	lda xx_msb
	sta ptr_msb
	jsr sendcom
	ldx ptrchan
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
	lda #$00
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr sendcom
	lda ptr2_lsb
	sta ptr_lsb
	lda ptr2_msb
	sta ptr_msb
	jsr sendcom
	ldx #$01
	jsr tenwait
	jsr sendcom
	lda buf2	; c64: $ce27
	sta ptr_lsb
	lda buf2+1	; c64: $ce28
	sta ptr_msb
postsv1:
	ldy #$00
postsv2:
	lda $ffff	; the address is put here (postsv2+1/+2): self-modifying
	sta buf2+3,y	; c64: $ce2a
	iny
	inc postsv2+1
	bne postsv3
	inc postsv2+2
postsv3:
	lda postsv2+1
	cmp l_msb
	bne postsv4
	lda postsv2+2
	cmp l_lsb
	bne postsv4
	lda #$00
	sta ptr_lsb
	sta ptr_msb
	sta buf2	; c64: $ce27
	sta buf2+1	; c64: $ce28
	jmp postsv5
postsv4:
	cpy #$4c
	bne postsv2
postsv5:
	sty buf2+2	; c64: $ce29
	iny
	iny
	iny
	sty h_msb
	ldy #$00
	ldx ptrchan
	jsr chkout	; c64: $ffc9 (the ROM is out in cfg_ml)
postsv6:
	lda buf2,y	; c64: $ce27
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	iny
	cpy h_msb
	bne postsv6
	lda #$0d
	jsr chrout	; c64: $ffd2 (the ROM is out in cfg_ml)
	jsr clrchn	; c64: $ffcc (the ROM is out in cfg_ml)
	lda ptr_lsb
	bne postsv7
	lda ptr_msb
	bne postsv7
	rts
postsv7:
	jmp postsv0
postread:
	lda #$3b
	ldx #$00
	jmp usetbl1	; c64: $cd03
setcmdch:
	sty cmdchan
	rts
setfilech:
	sty ptrchan
	rts
ident:
	jsr zero
	lda #$08
	sta varbuf+1	; c64: $62
	ldx #var_a_integer
	jmp putvar
usevar:
	lda #$1d
	jmp usetbl1	; c64: $cd03
tenwait:
	lda #$16
	jmp usetbl1	; c64: $cd03
dskin:
	lda #$02
	jmp usetbl1	; c64: $cd03
putvar:
	lda #$1e
	jmp usetbl1	; c64: $cd03
zero:
	lda #$1f
	jmp usetbl1	; c64: $cd03

; load "-1" into the variable buffer, and the file reader: no caller left in
; the release (they were left as data by the disassembler, with the C64's
; $cd03); usetbl1 here, so they'd work if one came back
minusone:
	lda #32
	jmp usetbl1	; c64: $cd03
reader:
	lda #3
	jmp usetbl1	; c64: $cd03

; the version, and the release's message in place of the 1990 source's
; "So long, and thanks for all the fish!"
vers:
	byte $30,$31,$2f,$30,$38,$2f,$39,$31	; "01/08/91  1:39A"
	byte $20,$20,$31,$3a,$33,$39,$41,$0d
	byte $d4,$c8,$c5,$d2,$c5,$27,$d3,$20	; "There's no need to fear..."
	byte $ce,$cf,$20,$ce,$c5,$c5,$c4,$20
	byte $d4,$cf,$20,$c6,$c5,$c1,$d2,$2e
	byte $2e,$2e,$d5,$ce,$c4,$c5,$d2,$c4	; "Underdog"
	byte $cf,$c7,$0d,$c9,$d3,$20,$c8,$c5	; "is here!"
	byte $d2,$c5,$21,$0d,$c3,$4f,$50,$52	; "Copr.1990 New Image"
	byte $2e,$31,$39,$39,$30,$20,$ce,$45
	byte $57,$20,$c9,$4d,$41,$47,$45

; the index is kept here, from the last byte on (the C64's "last"):
; struct indexdata { uint16 count (high byte first); uint16 data() }
last:
	byte $00

