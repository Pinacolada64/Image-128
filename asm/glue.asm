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

gate_ptr = free_fb		; zero page pointer to the inline bytes

farcall:
	php
	sei
	sta gate_a
	stx gate_x
	sty gate_y
	pla
	sta gate_p
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
irq_far:
	lda $d019
	and #$01		; raster? (the editor acknowledges it)
	beq irq_far1
	lda #cfg_ml
	sta mmucr
	jsr newirq
	lda #cfg_rom
	sta mmucr
irq_far1:
	jmp (oldirq_vec)

oldirq_vec:
	word k_irq		; setirq saves the vector here

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

farjmp_newstt:
	lda #cfg_rom
	sta mmucr
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
