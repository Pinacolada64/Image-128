; netsub.asm -- "++ netsub": i/NM.netsub2's message tracking tables, for
; NetSubs (a$="netsub":gosub 28, then &,16,x): two tables of 128 records,
; each a node's 3-letter name and a number (5 bytes, a float as BASIC
; keeps one), kept just past this, 2K in all:
;   &,16    a$'s number in the second table into rc, in the first into qe
;           (a node not in a table is added to it with 0; -1 if it's full)
;   &,16,1  qe into a$'s record in the first table (added if new)
;   &,16,2,dv%  load the tables from file a$ (cleared first)
;   &,16,3,dv%  save them to file a$
;   &,16,4  take a$ out of the first table (later records move up): qe its
;           number, or -1 if it isn't there
;   &,16,5,n  the first table's record n: an$ its name, qe its number
;           (an$ "" and qe -1 past the last)
;   &,16,6  clear both tables
;   &,16,7  copy the first table over the second
;   &,16,255  a% = the version (10)
;
; No source survives: disassembled from the 3.0 release's "++ netsub"
; ("01/09/91  4:34P", 4 blocks) by tools/ovl_dis.py, then ported on
; 2026-11-05 (C64 values in the comments):
; - runs at protostart ($1c00; c64 $c000), where &,7,dv%,2 loads it; the
;   tables start at table1, its end (#<table1/#>table1; c64 #$7e/#$c2)
; - Image's variable buffer is varbuf ($63-$67; c64 $61-$65, FAC1): the
;   5-byte numbers go through it as usevar and putvar have them
; - the record pointer (rptr) and the table's end (rend, high byte then
;   low) stay in $6a-$6d: FAC2 on both, and usevar, putvar and zero don't
;   use it on the 128 either (varbl.asm)
; - the KERNAL through the ML's ROM stubs; setbnk before LOAD and SAVE:
;   the tables in bank 0, the filename (a$) in bank 1, as ++ post does

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

rptr	= $6a	; the current record (c64: the same)
rend	= $6c	; the table's end: high byte, then low (c64: the same)

tabsize	= 128*8	; each table's size: 128 records of 8 bytes

	orig protostart	; c64: $c000
netsub:
	jmp entry
	byte $0a	; the version
	byte $30,$31,$2f,$30,$39,$2f,$39,$31	; "01/09/91  4:34P"
	byte $20,$20,$34,$3a,$33,$34,$50,$00

; -1, as BASIC keeps a float (and Image's minusone)
minus1:
	byte $81,$80,$00,$00,$00

entry:
	cpx #$ff
	bne entry0
	jsr zero	; &,16,255: a% = the version
	lda #$0a
	sta varbuf+1	; c64: $62
	ldx #var_a_integer
	jmp putvar
entry0:
	txa
	bne entry1
	jmp getboth	; 0
entry1:
	dex
	bne entry2
	jmp setnum	; 1
entry2:
	dex
	bne entry3
	jmp loadtab	; 2
entry3:
	dex
	bne entry4
	jmp savetab	; 3
entry4:
	dex
	bne entry5
	jmp delnode	; 4
entry5:
	dex
	bne entry6
	jmp getrec	; 5
entry6:
	dex
	bne entry7
	jmp clear	; 6
entry7:
	dex
	bne entry8
	jmp copytab	; 7
entry8:
	rts

; the file: a$ on device .y, secondary address 0
setfile:
	tya
	tax
	lda #$01
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	ldx #var_a_string
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: jmp $ffbd
	lda #0		; 128: the tables in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jmp setbnk

; 6: clear both tables
clear:
	lda #<table1
	sta clear1+1
	lda #>table1	; c64: #$c2
	sta clear1+2
clear0:
	lda #$00
clear1:
	sta $ffff	; (the address: set above)
	inc clear1+1
	bne clear2
	inc clear1+2
clear2:
	lda clear1+2
	cmp #>tabend	; c64: #$ca
	bne clear0
	lda clear1+1
	cmp #<tabend	; c64: #$7e
	bne clear0
	rts

; not found: -1 into varbuf, carry set
notfound:
	ldx #$00
notfnd1:
	lda minus1,x
	sta varbuf,x	; c64: $61,x
	inx
	cpx #$05
	bne notfnd1
; the record pointer to its number (past the name)
tonum:
	lda rptr
	clc
	adc #$03
	sta rptr
	lda rptr+1
	adc #$00
	sta rptr+1
	clc
	rts

; 2: load the tables
loadtab:
	jsr clear
	jsr setfile
	lda #$00
	ldx #<table1	; c64: #$7e
	ldy #>table1	; c64: #$c2
	jmp loadf	; c64: $ffd5

; 3: save them
savetab:
	jsr setfile
	lda #<table1	; c64: #$7e
	sta varbuf	; c64: $61
	lda #>table1	; c64: #$c2
	sta varbuf+1	; c64: $62
	lda #varbuf	; c64: #$61, the start's zero page address
	ldx #<tabend	; c64: #$7e
	ldy #>tabend	; c64: #$ca
	jmp savef	; c64: $ffd8

; 0: a$'s number in the second table into rc, in the first into qe
getboth:
	jsr find2
	ldx #var_rc_float
	jsr putvar
	jsr find1
	ldx #var_qe_float
	jmp putvar

; 1: qe into a$'s record in the first table
setnum:
	jsr find1
	bcc setnum1
	ldx #var_qe_float	; full: qe = -1
	jmp putvar
setnum1:
	ldx #var_qe_float
	jsr usevar
	ldy #$00
setnum2:
	lda varbuf,y	; c64: $0061,y
	sta (rptr),y
	iny
	cpy #$05
	bne setnum2
	rts

; 4: take a$ out of the first table
delnode:
	jsr find1
	bcs delnod5
	lda rptr	; back to the record's name
	sec
	sbc #$03
	sta rptr
	lda rptr+1
	sbc #$00
	sta rptr+1
delnod1:
	cmp #>(table1+tabsize-8)	; the last record? c64: #$c6
	bne delnod3
	lda rptr
	cmp #<(table1+tabsize-8)	; c64: #$76
	bne delnod3
	ldy #$00	; it's emptied
	lda #$00
delnod2:
	sta (rptr),y
	iny
	cpy #$08
	bne delnod2
	jmp delnod6
delnod3:
	ldy #$0f	; the next record over this one
delnod4:
	lda (rptr),y
	pha
	dey
	cpy #$07
	bne delnod4
	ldy #$00
delnod4a:
	pla
	sta (rptr),y
	iny
	cpy #$08
	bne delnod4a
	lda rptr
	clc
	adc #$08
	sta rptr
	lda rptr+1
	adc #$00
	sta rptr+1
	jmp delnod1
delnod5:
	jsr notfound
delnod6:
	ldx #var_qe_float
	jmp putvar

; find a$ in the second table
find2:
	ldx #var_a_string
	jsr usevar
	lda #<table2	; c64: #$7e
	sta rptr
	lda #>table2	; c64: #$c6
	sta rptr+1
	lda #>tabend	; c64: #$ca
	sta rend
	lda #<tabend	; c64: #$7e
	sta rend+1
	jmp find

; find a$ in the first table
find1:
	ldx #var_a_string
	jsr usevar
	lda #<table1	; c64: #$7e
	sta rptr
	lda #>table1	; c64: #$c2
	sta rptr+1
	lda #>table2	; c64: #$c6
	sta rend
	lda #<table2	; c64: #$7e
	sta rend+1
; from rptr to rend: a record named a$ (its number into varbuf), or the
; first empty one (named a$, 0 into varbuf); carry set if neither (-1).
; rptr is left at the record's number
find:
	ldy #$00
	ldx #$00
find0:
	cpy #$03
	beq found
	lda (rptr),y
	cmp #$00
	beq newrec
	cmp (varbuf+1),y	; c64: ($62),y
	bne findnext
	iny
	jmp find0
newrec:
	ldy #$00
newrec1:
	lda (varbuf+1),y	; c64: ($62),y
	sta (rptr),y
	iny
	cpy #$03
	bne newrec1
	jsr zero
	jmp tonum
findnext:
	lda rptr
	clc
	adc #$08
	sta rptr
	lda rptr+1
	adc #$00
	sta rptr+1
	cmp rend
	bne find
	lda rptr
	cmp rend+1
	bne find
	jsr notfound
	sec
	rts
found:
	lda (rptr),y
	sta varbuf,x	; c64: $61,x
	inx
	iny
	cpx #$05
	bne found
	jmp tonum

; 5: the first table's record .y
getrec:
	lda #$00
	sta rptr+1
	sty rptr
	jsr zero
	clc
	rol rptr	; times 8
	rol rptr+1
	clc
	rol rptr
	rol rptr+1
	clc
	rol rptr
	rol rptr+1
	lda rptr
	clc
	adc #<table1	; c64: #$7e
	sta rptr
	lda rptr+1
	adc #>table1	; c64: #$c2
	sta rptr+1
	ldy #$00
	lda (rptr),y
	beq getrec2
	lda #$03	; a$: its name, in the table
	sta varbuf	; c64: $61
	lda rptr
	sta varbuf+1	; c64: $62
	lda rptr+1
	sta varbuf+2	; c64: $63
	ldx #var_an_string	; (the release's: an$, not a$)
	jsr putvar
	ldy #$03
	ldx #$00
getrec1:
	lda (rptr),y
	sta varbuf,x	; c64: $61,x
	inx
	iny
	cpx #$05
	bne getrec1
	ldx #var_qe_float
	jmp putvar
getrec2:
	ldx #var_an_string
	jsr putvar
	jsr notfound
	ldx #var_qe_float
	jmp putvar

; 7: copy the first table over the second
copytab:
	lda #<table1	; c64: #$7e
	sta copy1+1
	lda #>table1	; c64: #$c2
	sta copy1+2
	lda #<table2	; c64: #$7e
	sta copy2+1
	sta copy3+1
	lda #>table2	; c64: #$c6
	sta copy2+2
	sta copy4+1
copy1:
	lda $ffff	; (the addresses: set above)
copy2:
	sta $ffff
	inc copy1+1
	bne copy5
	inc copy1+2
copy5:
	inc copy2+1
	bne copy6
	inc copy2+2
copy6:
	lda copy1+1
copy3:
	cmp #$ff	; (the end: table2, set above)
	bne copy1
	lda copy1+2
copy4:
	cmp #$ff
	bne copy1
	rts

usevar:
	lda #29
	jmp usetbl1	; c64: $cd03
putvar:
	lda #30
	jmp usetbl1	; c64: $cd03
zero:
	lda #31
	jmp usetbl1	; c64: $cd03
	byte $00

; the tables, just past the overlay (not in the file)
table1:
table2	= table1 + tabsize	; c64: $c67e
tabend	= table2 + tabsize	; c64: $ca7e
