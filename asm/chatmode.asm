; chatmode.asm -- "++ chatmode": the chat file on a (multiplexed) Lt. Kernal
; hard drive. UNTESTED: Image BBS 128 has no Lt. Kernal support yet (intro's
; use_ltk is off: VICE has no Lt. Kernal for the 128), so this is assembled
; but not on the boot disk (not in build.sh's overlays). Assemble it with
;
;	wine c64list4_04.exe chatmode.asm -prg:chatmode.prg -ovr
;
; A module loads it (a$="chatmode":gosub 28) and calls &,16: it finds
; "chatfile" on LU 10, user 0, or makes it (16 blocks, contiguous), then
; shows the text saved in it, until a $00 byte, its last block, or a key
; on the keyboard. The result is at protostart+3:
;
;	peek({sym:protostart}+3)  0 the file was there, 1 it was made (empty),
;	                          2 no room for it, 3 not found and not made
;	peek({sym:protostart}+4)  how many of its blocks were shown
;
; From Image BBS 2.0's v2/asm/tests/chatmode.asm, a fragment (C64, "1990
; sys ml:rem new image": it replaced im's line 1990, which in 2.0 sets up
; the BBS's node identifiers, ni and n1$). What it did: find "chatfile"
; in the logged LU and user (FNFILE), or make it -- a contiguous
; sequential file (type 5) of 16 blocks (ALCONT), entered in the catalog
; ("index catalog", mini-sub $24) -- and print "ChatFile Created", "No
; Room" or "Chat Mode:" with the Lt. Kernal's own output; copy the header
; block out of the host adapter's RAM; then "chatmode": take the file's
; first block number (blmilo) and loop until a key is pressed -- with
; nothing yet in the loop ("FIXME: missing code. presumably some kind of
; display function here").
;
; What it was for isn't in the fragment. Its file is like the lockfile
; that Image 2.0 kept for multi-node systems (intro.asm's lockinit,
; miscl.asm's &,13 lock/unlock): a contiguous file whose blocks every port
; of a multiplexed Lt. Kernal reads and writes by number. A saved chat,
; replayed, is the user's recollection (11/12/2026), and what this does;
; a chat between the nodes, through the file, would fit too. Either way
; something else had to write the text, and nothing in 2.0 does.
;
; The Lt. Kernal's documentation (floodgap.com's ckb/ltk/isam02.html,
; sixofdloc's ltk_dos_addresses.asm) gives these routines' addresses and
; the header's layout, big-endian (so nbinfl takes 16's high byte first,
; as the fragment did), 512-byte blocks, and BNKOUT/BANKIN around every
; call, but not how FNFILE, ALCONT, the mini-subs or the block driver
; take their arguments. So:
; - FNFILE's .a/.x/.y on failure (kept as idxoff/idxblk) and the mini-sub
;   call (idxoff pushed, then .x/.y, .a the mini-sub) are the fragment's,
;   unchecked. The fragment's "pha" has no "pla" ("FIXME: missing matching
;   pla"); maybe the mini-sub takes it from the stack. The C64 left
;   through BASIC's DATA statement (jmp $a8f8), not an rts, so a byte
;   left there did no harm; here the stack pointer is kept on entry and
;   put back before the rts, whatever the mini-sub does with it
; - the block driver as miscl.asm's block calls it (from the C64 Image
;   code, which worked): .a the LU, .x/.y the block number (low/high),
;   carry clear to read and set to write, then the buffer's address and
;   the number of blocks after the jsr; the buffer in the host adapter's
;   RAM ($91e0, hdrblk, which miscl.asm calls ltk_redbuf), copied out
;   before BANKIN
; - the file is on LU 10, user 0, as lockinit's lockfile (the fragment used
;   whatever LU was logged in: on a multiplexed drive, each port's own)
; - the header block's number: blmilo+0 high, +1 low (lockinit's reading);
;   the data blocks follow it (miscl.asm's block: header + 1 + n)
; - a new file's first data block is zeroed, so it shows as empty
; - text goes through Image's output (&,24: the screen and the caller),
;   not the Lt. Kernal's (output, $8048), which knows nothing of the modem
; - the key is the 128's keyboard buffer count (ndx, $d0; c64 198)

{alpha:alt}
{include:"equates.asm"}

catlog	= $24		; mini-sub: index catalog
cntfil	= $05		; file type: contiguous sequential data
cm_size	= 16		; the file's blocks, its header block too
cm_lu	= 10

	orig protostart	; c64: $0801 (a BASIC line and a sys)

	jmp cmentry

; the result: protostart+3, +4
cmstat:
	byte 3
cmshown:
	byte 0

cmentry:
	tsx
	stx cmsp
	lda #3
	sta cmstat
	lda #0
	sta cmshown
	jsr ltk_bnkout
	lda ltk_activu	; the logged LU and user, put back after
	sta cmuser
	lda ltk_activl
	sta cmlu
	lda #cm_lu
	jsr ltk_setlun
	lda #0
	sta ltk_activu
	jsr ltk_clrhdr
	ldy #7		; "chatfile", 8 characters
cmentry1:
	lda cmname,y
	sta filnam,y
	dey
	bpl cmentry1
	jsr ltk_fnfile
	bcc cmfound

; not there: make it
	sta cmidxoff
	stx cmidxblk
	sty cmidxblk+1
	lda #cntfil
	sta filtyp
	lda #>cm_size	; big-endian
	sta nbinfl
	lda #<cm_size
	sta nbinfl+1
	jsr ltk_alcont
	bcc cmmade
	lda #2		; no room
	sta cmstat
	jmp cmdone
cmmade:
	lda cmidxoff
	pha		; the fragment's; see the top
	ldx cmidxblk
	ldy cmidxblk+1
	lda #catlog
	jsr ltk_mnsext
	lda blmilo+0
	sta cmhdr+1
	lda blmilo+1
	sta cmhdr
	ldy #0		; its first data block emptied
	tya
cmmade1:
	sta hdrblk,y
	sta hdrblk+256,y
	iny
	bne cmmade1
	lda #1
	sec		; write
	jsr cmblock
	lda #1
	sta cmstat
	jmp cmdone

cmfound:
	lda blmilo+0
	sta cmhdr+1
	lda blmilo+1
	sta cmhdr
	lda #0
	sta cmstat

cmdone:
	jsr ltk_bnkout	; again: cmblock ends with BANKIN
	lda cmlu
	jsr ltk_setlun
	lda cmuser
	sta ltk_activu
	jsr ltk_bankin
	cli
	lda cmstat
	cmp #2
	bcs cmexit

; show it: each data block's text, to a $00, the last block or a key
	lda #<cmhead
	ldx #>cmhead
	jsr cmprint
	lda #1
	sta cmblk
cmshow1:
	lda ndx		; a key: stop
	bne cmexit
	clc		; read
	lda cmblk
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
	ldx cmsp	; the stack as it came (the mini-sub's byte)
	txs
	rts

; data block .a of the file (1 to cm_size-1): carry clear reads it into
; cmbuf, set writes hdrblk's 512 bytes to it. As miscl.asm's block
cmblock:
	php
	jsr ltk_bnkout
	clc
	adc cmhdr
	tax
	lda cmhdr+1
	adc #0
	tay
	lda #cm_lu
	plp
	php
	jsr ltk_driver
	word hdrblk
	byte 1
	plp
	bcs cmblock2	; written: nothing to copy
	ldy #0
cmblock1:
	lda hdrblk,y	; out of the host adapter's RAM
	sta cmbuf,y
	lda hdrblk+256,y
	sta cmbuf+256,y
	iny
	bne cmblock1
cmblock2:
	jsr ltk_bankin
	cli
	rts

; .a/.x a 0-ended string to Image's output
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
cmidxoff:
	byte 0
cmidxblk:
	word 0
cmhdr:
	word 0		; the header block's number (low, high)
cmblk:
	byte 0
; a block (512 bytes), past the overlay's end
cmbuf:
