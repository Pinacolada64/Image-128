; glue.asm -- code that has to be visible in every MMU configuration:
; assembled at glue ($3600), in the shared bottom 16K (rcr_shared), so
; it's there whether BASIC (cfg_rom) or Image's ML (cfg_ml) is running.
;
; farcall is the one door between the two: it runs a routine in another
; configuration and comes back to the caller's.
;
;	jsr farcall
;	byte cfg		; $ff00 value to run the target in
;	word target
;
; The target gets the caller's .a, .x, .y and flags, and the caller gets
; the target's back; the caller's $ff00 comes back too, whatever the
; target left (BASIC's own fetch routines finish by loading one of the
; MMU's preset configurations, so a routine called in cfg_rom can return
; in bank 0 or bank 1 with the KERNAL in). romtab.asm's stubs use it to
; call ROM from the ML, and the entries below use it to call the ML from
; BASIC's side (the wedge, KERNAL vectors, SYS).
;
; Reentrant: the caller's $ff00 and where to come back to are on the
; stack, and the few shared bytes below are used only with interrupts
; masked (an IRQ handler can farcall in the middle of someone else's).
;
; It reads the inline bytes through gate_ptr ($fb/$fc), which C64 code
; takes for free zero page (the ++ overlays use it as a pointer), so it
; puts the caller's two bytes back before going on to the target: neither
; the target nor the caller sees farcall's use of them, nor that of an
; IRQ's farcall in between.

gate_ptr = free_fb		; zero page pointer to the inline bytes

; farcall has to stay the first thing here: the wedge, assembled on its
; own, calls it as "jsr glue" (collect, in wedge.asm)
farcall:
	php
	sei
	sta gate_a
	stx gate_x
	sty gate_y
	pla
	sta gate_p
	lda gate_ptr		; the caller's $fb/$fc, put back below
	sta gate_fb
	lda gate_ptr+1
	sta gate_fc
	pla			; our return address: the byte before
	sta gate_ptr		; the inline bytes
	pla
	sta gate_ptr+1
	ldy #1
	lda (gate_ptr),y
	sta gate_cfg
	iny
	lda (gate_ptr),y
	sta gate_t
	iny
	lda (gate_ptr),y
	sta gate_t+1
	clc			; the caller's return address, past them
	lda gate_ptr
	adc #3
	tax
	lda gate_ptr+1
	adc #0
	pha
	txa
	pha
	lda mmucr		; the caller's configuration
	pha
	lda #>(farcall_back-1)	; where the target returns to
	pha
	lda #<(farcall_back-1)
	pha
	lda gate_cfg
	sta mmucr
	lda gate_fb
	sta gate_ptr
	lda gate_fc
	sta gate_ptr+1
	lda gate_p
	pha
	lda gate_a
	ldx gate_x
	ldy gate_y
	plp			; the caller's flags (and I) for the target;
	jmp (gate_t)		; an IRQ waits until after this jmp

farcall_back:
	php
	sei
	sta gate_a
	pla
	sta gate_p
	pla			; the caller's configuration
	sta mmucr
	lda gate_p
	pha
	lda gate_a
	plp
	rts			; to the caller, past the inline bytes

gate_a:   byte 0
gate_x:   byte 0
gate_y:   byte 0
gate_p:   byte 0
gate_cfg: byte 0
gate_t:   word 0
gate_fb:  byte 0
gate_fc:  byte 0

; ********************************
; *  into the ML from BASIC's side
; ********************************

; usetbl1 (the interface page's "&" entry, which the wedge calls in
; cfg_rom): run usetbl0 in cfg_ml
usetbl_far:
	jsr farcall
	byte cfg_ml
	word usetbl0
	rts

; the KERNAL's CHROUT vector (ICHROUT, $0326), set by iosetup
newout_far:
	jsr farcall
	byte cfg_ml
	word newout
	rts

; the IRQ vector (CINV, $0314), set by setirq. The KERNAL's entry ($ff17)
; has already pushed .a .x .y and $ff00 and switched to cfg_rom. Image's
; IRQ work (ml.asm's newirq) runs once a frame, on the VIC raster
; interrupt -- in text mode the screen editor's only one, at line $ff --
; and then the KERNAL's own handler ($fa65) runs as usual: the screen
; editor, the jiffy clock, the keyboard, BASIC's sprites and sound. It
; exits through $ff33, which puts back the interrupted $ff00.
; c64: Image replaced the KERNAL's IRQ and did those itself (irq9).
;
; The split screen (c64: ml.s's "raster"): with the screen mask on, the
; console rows use the character set the output chose (mupcase, set by
; chr$(14)/chr$(142): 0 lowercase, 1 uppercase/graphics) and the mask's
; rows the lowercase set. setirq sets graphm to $ff, so the editor's IRQ
; leaves $d018 and $d012 to Image (it still acks the raster interrupt and
; scans the keyboard). Two raster interrupts a frame: at line $ff (the
; frame's: the console's set, Image's IRQ work, the KERNAL's handler) and,
; with the mask on, at mask_line, two lines above the mask's top row (the
; KERNAL's entry takes most of a line), which sets the mask's set and
; returns without the KERNAL, so the clocks and keyboard run once a frame.
; The c64 split at lines 106 and 234 (rows 7 and 23); the 3.0 mask starts
; at row 16.
mask_line = 51 + 8*16 - 2	; text row r starts at line 51 + 8r

irq_far:
	lda $d019
	and #$01		; raster? (the editor acknowledges it)
	beq irq_far1
	lda irq_phase
	bne irq_mask
	lda vm1			; the frame's: the console's set
	and #$f0		; (the screen's address, from the editor's VM1)
	sta irq_mset
	lda mupcase
	and #1
	asl
	eor #$06		; $06: lowercase ($1800), $04: uppercase ($1000)
	ora irq_mset
	sta $d018
	lda irq_mset
	ora #$06
	sta irq_mset		; and the mask's, for irq_mask
	lda #$ff
	ldx scnmode		; mask on (0): the mask's interrupt next
	bne irq_far0
	lda #mask_line
	inc irq_phase
irq_far0:
	sta $d012
	lda #cfg_ml
	sta mmucr
	jsr newirq
	lda #cfg_rom
	sta mmucr
irq_far1:
	jmp (oldirq_vec)

; the mask's interrupt: its character set, then the frame's interrupt next
irq_mask:
	lda irq_mset
	sta $d018
	lda #$01
	sta $d019		; ack
	lda #$ff
	sta $d012
	lda #0
	sta irq_phase
	jmp nmiexit		; $ff33: .y .x .a and $ff00 back, rti

irq_phase:
	byte 0			; 1: the next raster interrupt is the mask's
irq_mset:
	byte $16		; $d018 for the mask's rows

oldirq_vec:
	word k_irq		; setirq saves the vector here

; 10/27/2026: the editor's KEYCHK vector ($033c), set by setirq. Every key
; the editor decodes comes through here in .a, in the keyboard interrupt,
; on its way into the buffer: keep the first one in idlekey, for
; i/lo.idle (which clears it when it takes it), then go on as before
keychk_far:
	pha
	lda idlekey
	bne keychk_far1		; one is waiting already
	pla
	pha
	sta idlekey
keychk_far1:
	pla
	jmp (oldkeychk_vec)

oldkeychk_vec:
	word $c6ad		; setirq saves the vector here

; BASIC line trace, from the wedge's statement hook
trace_far:
	jsr farcall
	byte cfg_ml
	word trace0
	rts

; ********************************
; *  into the wedge from the ML
; ********************************

; the wedge jump table at wedgemem ($1900) comes here, so the wedge's
; routines run in the configuration they need whoever calls them: the
; array and garbage collection routines work on BASIC's variables (bank
; 1) and call the swapper, so cfg_ml; loadprg calls the KERNAL directly,
; so cfg_rom. 7 bytes each, in wedge.asm's own jump table order.

wedge_far:
	jsr farcall		; +0: install, no error trap (trapoff)
	byte cfg_ml
	word wedge_exec_address+0
	rts
	jsr farcall		; +7: install with error trap (trapon)
	byte cfg_ml
	word wedge_exec_address+3
	rts
	jsr farcall		; +14: load a module (loadprg)
	byte cfg_rom
	word wedge_exec_address+6
	rts
	jsr farcall		; +21: save array pointers (arraysav)
	byte cfg_ml
	word wedge_exec_address+9
	rts
	jsr farcall		; +28: restore array pointers (arrayres)
	byte cfg_ml
	word wedge_exec_address+12
	rts
	jsr farcall		; +35: garbage collect (forcegc)
	byte cfg_ml
	word wedge_exec_address+15
	rts

; ********************************
; *  out of the ML for good
; ********************************

; these leave the ML for BASIC and don't come back, so there's nothing
; to restore: switch to cfg_rom and go

; farjmp_newstt (mljump: &,66,1's GOSUB) leaves from the middle of the &
; statement, the wedge's and farcall's frames still on the CPU stack: put
; the stack back as BASIC 7's own GOSUB leaves it. NEWSTT keeps the stack
; pointer from the start of the statement in stksav, and runs a statement
; with jsr $4b3f from $4af3; GOSUB ends with jmp newstt, leaving that
; return address ($4af5) there, and RETURN drops its own (pla pla) and
; returns through it. Each call left the & frames there before, until the
; stack ran out, and RETURN went back through them. (c64: the same
; garbage, under the GOSUB frame on its CPU stack.)
farjmp_newstt:
	lda #cfg_rom
	sta mmucr
	bit runmod
	bpl farjmp_newstt1	; direct mode: stksav isn't kept
	ldx stksav
	txs
farjmp_newstt1:
	lda #>(k_newstt-1)
	pha
	lda #<(k_newstt-1)
	pha
	jmp k_newstt

; .x: error number
farjmp_error:
	lda #cfg_rom
	sta mmucr
	jmp k_error

; RUN the BASIC program, as intro.asm's C64 original did with
; "lda #0 / jsr run / jmp newstt"
farjmp_run:
	lda #cfg_rom
	sta mmucr
	lda #0
	jsr k_run
	jmp k_newstt
