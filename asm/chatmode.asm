; chatmode.asm -- "++ chatmode": the chat file on a (multiplexed) Lt. Kernal
; hard drive. Not on the boot disk (not in build.sh's overlays): Image BBS
; 128's own Lt. Kernal code is still off (intro's use_ltk). Assemble it with
;
;	wine c64list4_04.exe chatmode.asm -prg:chatmode.prg -ovr
;
; 11/12/2026: tried on VICE 3.8's Lt. Kernal emulation in 128 mode
; (tests/standin/chatmode.bas, tools/ltk_chatmode.py): the first &,16 made
; chatfile (the Lt. Kernal's DIR: LU 10, user 00, 16 blocks, type 5) and
; showed its empty first block; the second found it. Not tried yet: a
; replay of saved text (nothing writes any: modules/TODO.md).
;
; A module loads it (a$="chatmode":gosub 28) and calls &,16: it finds
; "chatfile" on LU 10, user 0, or makes it (16 blocks, contiguous), then
; shows the text saved in it, until a $00 byte, its last block, or a key
; on the keyboard. The result is at protostart+3:
;
;	peek({sym:protostart}+3)  0 the file was there, 1 it was made (empty),
;	                          2 no room for it, 3 no LU 10, or the new
;	                          file wasn't found after it was catalogued
;	peek({sym:protostart}+4)  how many of its blocks were shown
;
; From Image BBS 2.0's v2/asm/tests/chatmode.asm, a fragment (C64, "1990
; sys ml:rem new image": it replaced im's line 1990, which in 2.0 sets up
; the BBS's node identifiers, ni and n1$). What it did: find "chatfile"
; in the logged LU and user (FNFILE), or make it -- a contiguous
; sequential file (type 5) of 16 blocks (ALCONT), entered in the catalog
; (mini-sub $24) -- and print "ChatFile Created", "No Room" or "Chat
; Mode:" with the Lt. Kernal's own output; copy the header block out of
; the host adapter's RAM; then "chatmode": take the file's first block
; number and loop until a key is pressed -- with nothing yet in the loop
; ("FIXME: missing code. presumably some kind of display function here").
;
; What it was for isn't in the fragment. Its file is like the lockfile
; that Image 2.0 kept for multi-node systems (intro.asm's lockinit,
; miscl.asm's &,13 lock/unlock): a contiguous file whose blocks every port
; of a multiplexed Lt. Kernal reads and writes by number. A saved chat,
; replayed, is the user's recollection (11/12/2026), and what this does;
; a chat between the nodes, through the file, would fit too. Either way
; something else had to write the text, and nothing in 2.0 does.
;
; The Lt. Kernal calls, from the Lt. Kernal Power Station articles
; (~/Documents/c64/ltkernal: PSV1N4.TXT documents them; PSV1N5A.TXT is
; W. J. Brier's LK Mini-Mon 1.1, a C-128 program that makes and reads
; type 5 files with them):
; - DRIVER ($8045): .a the LU, .x/.y the block (low, high), carry clear to
;   read and set to write, then after the jsr the buffer's address and
;   the number of blocks (0: 256); .a .x .y come back, the carry doesn't.
;   Blocks are 512 bytes. On the 128, Mini-Mon calls it with $ff00 =
;   %00001110 (RAM at $4000-$bfff, the KERNAL ROM, I/O) and puts $00 back
;   before BNKIN; its buffer is in the shared low RAM, as cmbuf is here
; - the other calls (SETLUN, CLRHDR, FNFILE, ALCONT, the mini-subs)
;   between BNKOUT ($fc4e) and BNKIN ($fc71), which are in the Lt. Kernal's
;   KERNAL ROM: so with $ff00 = cfg_rom ($00), never cfg_ml, where
;   $c000-$ffff is Image's own resident ML. BNKOUT leaves interrupts off,
;   so a cli follows BNKIN (as lockinit and block do)
; - ALCONT: the header block cleared (CLRHDR), the name, the file type and
;   NBINFL (blocks, the header block too, high byte first) set; carry
;   clear if it got them all, and nothing allocated if it didn't
; - FNFILE fails with three values in .a/.x/.y, which the catalog mini-sub
;   takes: the first pushed, then .x/.y, .a = $24, jsr MNSEXT. Mini-Mon
;   does exactly that, without a pla after it, as the fragment did (its
;   "FIXME: missing matching pla" isn't a bug); the stack pointer is kept
;   here anyway and put back before the rts. Mini-Mon then searches for
;   the file again before using its header, and so does this
; - the file's origin (HDRADR, hdrblk+$20, which equates.asm calls blmilo)
;   is its header block, high byte first; its data blocks follow it
; Also: the file is on LU 10, user 0, as lockinit's lockfile (the fragment
; used whatever LU was logged in: on a multiplexed drive, each port's
; own); a new file's first data block is zeroed, so it shows as empty;
; the text goes through Image's output (&,24: the screen and the caller),
; not the Lt. Kernal's OUTPUT ($8048), which knows nothing of the modem;
; RS-232 is off around the Lt. Kernal's calls (rsdisab: its NMIs; the
; Power Station warns about NMIs during a write); the key is the 128's
; keyboard buffer count (ndx, $d0; c64 198).

{alpha:alt}
{include:"equates.asm"}

catlog	= $24		; mini-sub: index catalog
cntfil	= $05		; file type: contiguous sequential data
cm_size	= 16		; the file's blocks, its header block too
cm_lu	= 10
cm_drvcfg = %00001110	; $ff00 for DRIVER, as LK Mini-Mon

	orig protostart	; c64: $0801 (a BASIC line and a sys)

	jmp cmentry

; the result: protostart+3, +4
cmstat:
	byte 3
cmshown:
	byte 0

; ********************************
; *  &,16 (cfg_ml)
; ********************************

cmentry:
	tsx
	stx cmsp
	lda #3
	sta cmstat
	lda #0
	sta cmshown
	jsr rsdisab
	lda #cfg_rom	; the Lt. Kernal's KERNAL ROM
	sta mmucr
	jsr ltk_bnkout
	lda ltk_activu	; the logged LU and user, put back after
	sta cmuser
	lda ltk_activl
	sta cmlu
	lda #cm_lu
	jsr ltk_setlun
	bcs cmdone	; no LU 10
	lda #0
	sta ltk_activu
	jsr cmfind
	bcc cmfound

; not there: make it
	sta cmidx
	stx cmidx+1
	sty cmidx+2
	jsr ltk_clrhdr
	jsr cmname1
	lda #cntfil
	sta filtyp
	lda #>cm_size	; high byte first
	sta nbinfl
	lda #<cm_size
	sta nbinfl+1
	jsr ltk_alcont
	bcc cmmade
	lda #2		; no room
	sta cmstat
	jmp cmdone
cmmade:
	lda cmidx	; into the catalog (the mini-sub takes the
	pha		; first value from the stack)
	lda #catlog
	ldx cmidx+1
	ldy cmidx+2
	jsr ltk_mnsext
	jsr cmfind	; its header, as Mini-Mon does
	bcs cmdone	; (status 3)
	lda #1
	bne cmfound1
cmfound:
	lda #0
cmfound1:
	sta cmstat
	lda blmilo+0	; its origin: the header block
	sta cmhdr+1
	lda blmilo+1
	sta cmhdr

cmdone:
	lda cmlu
	jsr ltk_setlun
	lda cmuser
	sta ltk_activu
	jsr ltk_bankin
	lda #cfg_ml
	sta mmucr
	cli
	jsr rsinabl
	lda cmstat
	cmp #2
	bcs cmexit
	cmp #1
	bne cmshow

; a new file: its first data block emptied
	ldy #0
	tya
cmmade1:
	sta cmbuf,y
	sta cmbuf+256,y
	iny
	bne cmmade1
	lda #1
	sec		; write
	jsr cmblock

; show it: each data block's text, to a $00, the last block or a key
cmshow:
	lda #<cmhead
	ldx #>cmhead
	jsr cmprint
	lda #1
	sta cmblk
cmshow1:
	lda ndx		; a key: stop
	bne cmexit
	lda cmblk
	clc		; read
	jsr cmblock
	inc cmshown
	ldy #0
cmshow2:
	lda cmbuf,y
	beq cmexit
	jsr cmputc
	lda ndx
	bne cmexit
	iny
	bne cmshow2
cmshow3:
	lda cmbuf+256,y
	beq cmexit
	jsr cmputc
	lda ndx
	bne cmexit
	iny
	bne cmshow3
	inc cmblk
	lda cmblk
	cmp #cm_size
	bcc cmshow1

cmexit:
	ldx cmsp	; the stack as it came
	txs
	rts

; ********************************
; *  the Lt. Kernal
; ********************************

; (banked out, cfg_rom) find "chatfile" in the logged LU and user: carry
; clear if it's there (its header in hdrblk); set if not, with the values
; the catalog mini-sub takes in .a/.x/.y
cmfind:
	jsr ltk_clrhdr
	jsr cmname1
	jmp ltk_fnfile

; the name into the header block
cmname1:
	ldy #7		; "chatfile", 8 characters
cmname2:
	lda cmname,y
	sta filnam,y
	dey
	bpl cmname2
	rts

; (cfg_ml) data block .a of the file (1 to cm_size-1): carry clear reads
; it into cmbuf, set writes cmbuf to it
cmblock:
	sta cmtmp
	php
	jsr rsdisab
	lda #cm_drvcfg
	sta mmucr
	jsr ltk_bnkout
	clc
	lda cmtmp
	adc cmhdr
	tax
	lda cmhdr+1
	adc #0
	tay
	lda #cm_lu
	plp		; read or write
	jsr ltk_driver
	word cmbuf
	byte 1
	lda #cfg_rom
	sta mmucr
	jsr ltk_bankin
	lda #cfg_ml
	sta mmucr
	cli
	jmp rsinabl

; ********************************
; *  Image's output
; ********************************

; .a/.x a 0-ended string
cmprint:
	sta cmprint1+1
	stx cmprint1+2
	ldy #0
cmprint1:
	lda $ffff,y	; target of self-modifying code
	beq cmprint2
	jsr cmputc
	iny
	bne cmprint1
cmprint2:
	rts

; .a to Image's output (&,24 takes it in $fe); keeps .y
cmputc:
	sta $fe
	tya
	pha
	lda #24
	jsr usetbl1
	pla
	tay
	rts

cmhead:
	ascii "Chat Mode:"
	byte 13,0
cmname:
	ascii "chatfile"
cmsp:
	byte 0
cmlu:
	byte 0
cmuser:
	byte 0
cmidx:
	byte 0,0,0	; FNFILE's values for the catalog mini-sub
cmhdr:
	word 0		; the header block's number (low, high)
cmblk:
	byte 0
cmtmp:
	byte 0
; a block (512 bytes), past the overlay's end, in the shared low RAM
cmbuf:
