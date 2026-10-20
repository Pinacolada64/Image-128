; wedge.asm -- Image's BASIC hooks: & and the $hex constant, LOAD and
; NEW for modules, and error trapping. Runs at wedge_exec_address in
; BASIC's own configuration (cfg_rom), so it calls BASIC and the KERNAL
; directly: direct_rom gives it their real addresses.
{def:direct_rom}
{include:"equates.asm"}
orig wedge_exec_address
; jump table

; xx00: install w/o error trap
; xx03: install w/error trap
; xx06: load after filename is set
; xx09: save array pointers
; xx0c: restore array pointers

start:
	jmp install
	jmp install0
	jmp openroom
	jmp arraysv0
	jmp arrayrs0
	jmp collect
wgone0:
	jmp wgone
weval0:
	jmp weval
wtrap0:
	jmp wtrap
wfunc0:
	tsx
	txa
	tay
	lda #$00
	jmp givayf	; c64: $b391

filename_len:
	byte 0
fdev:
	byte 0

tload:
	jsr chrget
	jsr getfile
	jsr openroom
	jmp gone2

; load a module into the running program: LOAD "name",dev[,sa] from a
; program comes here (tload). The module's first line says where it goes:
; it's loaded over the program from the first line at or after that one,
; so "new 3000:load ..." puts a module at line 3000 on. The secondary
; address goes to loadflag, which im's line 0 uses to pick where to carry
; on when a load replaces the line that's running (it restarts at line 0).
;
; c64: program text and variables were one block, so openroom first moved
; the variables up out of the way (oprm) and closroom moved them back down
; after the new end of the program (clrm). On the 128 the variables are in
; bank 1, apart from the text in bank 0, so nothing moves: load, set the
; end of the program ($1210), relink.
openroom:
; BASIC can arrive here with $ff00 = $01 (its fetch routines load preset C):
; ROMs in but no I/O, so the KERNAL's serial code would read ROM at $dd00
; and find no drive ("device not present"). BASIC's own I/O statements
; switch to bank 15 ($00) first; so does this.
	lda #cfg_rom
	sta mmucr
	ldy #0
openroo1:
	cpy fnlen	; $b7
	beq openroo2
	lda #fnadr	; c64: lda ($bb),y. The name can be a string in
	ldx fnbank	; bank 1: fetch it from the bank BASIC's setbnk
	jsr indfet	; gave the KERNAL
	sta fbuf,y
	iny
	cpy #18		; fbuf is 20 bytes: room for loadfile's ",p"
	bcc openroo1
openroo2:
	sty filename_len
	lda fa		; $ba
	sta fdev
	lda sa		; $b9
	and #31
	sta loadflag

; the module's first line number: bytes 5 and 6 of the file (after the
; load address and the first line's link)
; Read on a data channel, ",p" for the program file: a half-read LOAD
; channel (secondary address 0, as the c64 code used) leaves a 1571 in
; burst mode hanging on the LOAD that follows.
loadfile:
	jsr setfile
	ldy filename_len
	lda #comma
	sta fbuf,y
	lda #'p'
	sta fbuf+1,y
	iny
	iny
	tya
	ldx #<fbuf
	ldy #>fbuf
	jsr setnam
	lda #127
	ldx fdev
	ldy #2
	jsr setlfs
	jsr openf
	ldx #127
	jsr chkin
	jsr chrin
	jsr chrin
	jsr chrin
	jsr chrin
	jsr chrin
	sta l1x+1
	jsr chrin
	sta l2x+1
	jsr clrchn
	lda #127
	jsr closef
	jsr scan0	; eal: the first line at or after it

; load it there, in bank 0
	jsr setfile
	lda #0
	ldx eal		; c64: $ae
	ldy eal+1	; c64: $af
	jsr loadf
	bcc loadfil1
	jsr chopfile	; keep what's left of the program before it
loaderr:
	ldx #29		; ?load error
	jmp error
loadfil1:
	cpy #>textop	; past the top of BASIC text?
	bcc loadfil2
	jsr chopfile
	ldx #16		; ?out of memory
	jmp error
loadfil2:
	stx $1210	; end of BASIC text
	sty $1211
	jsr linkprg
; if the module replaced the line that's running, carry on from the start
; of the program (im's line 0) -- the c64 code did the same
	lda l1x+1
	cmp curlin	; c64: $39/57
	lda l2x+1
	sbc curlin+1	; c64: $3a/58
	bcs loadfil3
	lda #<(prgstart-1)
	sta txtptr	; c64: $7a
	lda #>(prgstart-1)
	sta txtptr+1	; c64: $7b
loadfil3:
	rts

; setlfs/setnam/setbnk for the module file
setfile:
	lda #127
	ldx fdev
	ldy #0
	jsr setlfs
	ldx #<fbuf
	ldy #>fbuf
	lda filename_len
	jsr setnam
	lda #0		; load into bank 0, the filename's in bank 0
	tax
	jmp setbnk

; end the program before line l1x/l2x (chopfile: where a failed load
; started; chopfil1: line .x/.y, for "new <line>")
chopfile:
	ldx l1x+1
	ldy l2x+1
chopfil1:
	stx l1x+1
	sty l2x+1
	jsr scan0
	ldy #0		; two zero bytes: the end of the program (stores go
	tya		; to bank 0's RAM under the ROMs)
	sta (eal),y	; same: ($ae),y
	iny
	sta (eal),y	; same: ($ae),y
	clc
	lda #2
	adc eal		; c64: $ae
	sta $1210	; end of BASIC text (c64: closroom moved the
	lda #0		; variables down to here)
	adc eal+1	; c64: $af
	sta $1211
	rts

; eal: the first program line numbered l1x/l2x or more, or the end of the
; program. Reads the text in bank 0, so with the ROMs switched out.
scan0:
	lda mmucr
	pha
	lda #cfg_bank0
	sta mmucr
	ldx txttab	; c64: $2b
	ldy txttab+1	; c64: $2c
	stx sal		; c64: $ac
	sty sal+1	; $ad
scan1:
	stx eal		; $ae
	sty eal+1	; $af
	ldy #2
	lda (eal),y	; same: ($ae),y
l1x:
	cmp #0
	iny
	lda (eal),y	; same: ($ae),y
l2x:
	sbc #0
	bcs scan3
scan2:
	lda eal		; $ae
	ldx eal+1	; $af
	sta sal		; $ac
	stx sal+1	; $ad
	ldy #0
	lda (eal),y	; same: ($ae),y
	tax
	iny
	lda (eal),y	; same: ($ae),y
	tay
	bne scan1
scan3:
	pla
	sta mmucr
	rts

tnew:
	jsr chrget
	jsr linget
	ldx linnum	; c64: $14
	ldy linnum+1	; c64: $15
	jsr chopfil1
	jmp gone2

thex:
	ldx #0
	stx var+1	; c64: $62
	stx var+2	; c64: $63
thex1:
	jsr chrget
	bcc thex2
	cmp #'g'
	bcs thex5
	cmp #'a'
	bcc thex5
	sbc #7
thex2:
	and #$f
	ldx #4
thex3:
	asl var+2	; c64: $63
	rol var+1	; c64: $62
	bcs thex4
	dex
	bne thex3
	ora var+2	; c64: $63
	sta var+2	; c64: $63
	bcc thex1
thex4:
	jmp ilqerr
thex5:
	ldx #$90
	sec
	jmp retval

tampr:
	jsr chrget
	jsr getaxy
	jsr usetbl1
	jmp gone2

wgone:
	lda fretop	; c64: $33/51
	cmp strend	; c64: $31/49
	lda fretop+1	; c64: $34/52
	sbc strend+1	; c64: $32/50
	bne wgone1
	jsr forcegc	; collect, in cfg_ml (glue.asm's wedge_far)
	lda fretop	; c64: $33/51
	cmp strend	; c64: $31/49
	lda fretop+1	; c64: $34/52
	sbc strend+1	; c64: $32/50
	bne wgone1
; less than 256 bytes free, force
; out of memory error for safety
	ldx #1
	jsr arrayres	; arrayrs0, in cfg_ml
	ldx #16
	jmp error ;outofm
wgone1:
	jsr trace	; trace_far: the ML's trace0, in cfg_ml
	jsr chrget
	cmp #'&'
	beq ampr0
; c64: POKE and SYS came here too (pokefix's C64 address remapping and
; a SYS filter); the 128 uses BASIC 7.0's own, which honor BANK
	cmp #loadtok
	beq load0
	cmp #newtok
	beq new0
	jsr chrgot
	jmp gone1

weval:
	jsr chrget
	ldx #0
	stx valtyp	; $d
	cmp #'$'
	beq hex0
	jsr chrgot
	jmp eval1

ampr0:
	jmp tampr
load0:
	jmp tload
new0:
	jmp tnew
hex0:
	jmp thex

getaxy:
	jsr getparm
	stx sareg	; c64: 780
	jsr getparm
	stx sxreg	; c64: 781
	jsr getparm
	stx syreg	; c64: 782
	lda sareg	; c64: 780
	ldx sxreg	; c64: 781
	ldy syreg	; c64: 782
	rts

getparm:
	jsr chrgot
	ldx #0
	cmp #comma
	bne getparm1
	jsr chrget	; c64: getbytc ($b79b) did this itself
	jsr getbytc
getparm1:
	rts

wtrap:
	stx sareg	; c64: $030c
	lda curlin	; c64: $39
	sta sxreg	; c64: $030d
	lda curlin+1	; c64: $3a
	sta syreg	; c64: $030e
	lda #<$4d3f	; c64: <$e38b, contents of ($0300)
	sta IERROR	; $300
	lda #>$4d3f	; c64: >$e38b, contents of ($0300)
	sta IERROR+1	; $301
	ldx #$fa
	txs
; BASIC 7 keeps GOSUB, FOR and DO frames in its own stack at $0800-$09ff,
; not on the CPU's (which the txs above empties): empty it too, as CLR
; does ($521a)
	lda #$ff
	sta $7d
	lda #$09
	sta $7e
	lda #$1b	; c64: 25 ($19); the 128's temp string stack starts at $1b
	sta temppt	; c64: $16/22
	lda #<trapline
	sta linnum	; c64: $14
	lda #>trapline
	sta linnum+1	; c64: $15
	jsr gotol	; c64: jsr $a8a3 (goto+3)
	jmp newstt	; c64: $a7ae

install:
	lda #<$4d3f	; the 128's default IERROR (c64: $e38b)
	ldx #>$4d3f
	jmp install1
install0:
	lda #<wtrap0
	ldx #>wtrap0
install1:
	sta IERROR	; $300
	stx IERROR+1	; $301
	lda #<wgone0
	ldx #>wgone0
	sta IGONE	; $308
	stx IGONE+1	; $309
	lda #<weval0
	ldx #>weval0
	sta IEVAL	; $30a
	stx IEVAL+1	; $30b
	lda #<wfunc0
	ldx #>wfunc0
	sta USRADD	; $311
	stx USRADD+1	; $312
	rts

arrayoff:
	txa
	and #7
	asl
	asl
	tax
	ldy #2
	rts

;* copy pointers for arrays *
arraysv0:
	jsr arrayoff
arsv1:
; &,27: save array pointer "level" in .x?
arytab_hi = $0032	; dirty hack to assemble "lda arytab+1,y"
	sec
	lda arytab,y	; c64: $2f
	sbc vartab	; c64: $2d
	sta arryptrs+0,x; $13d0
;	lda arytab+1,y	; c64: $30
	lda arytab_hi,y	; c64: $30
	sbc vartab+1	; c64: $2e
	sta arryptrs+1,x; $13d1
	inx
	inx
	dey
	dey
	bpl arsv1
	rts

;* restore pointers for arrays *
arrayrs0:
	lda arytab	; c64: $2f
	sta sal		; c64: $ac
	lda arytab+1	; c64: $30
	sta sal+1	; c64: $ad
	jsr arrayoff
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
	rts

collect:
	lda #>gc
	ldy #>gchide
	ldx #gclen
	jsr swapper
	jsr gc
	jmp swapagn
