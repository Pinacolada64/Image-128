orig $0c00 ; 3072
; "&" wedge for basic 7.0
chrget	= $0380
chrgot	= $0386

INSTALLED = $01
UNINSTALLED = $00

jump_table:
	jmp install_wedge
	jmp uninstall_wedge
install_wedge:
; check if installed (will overwrite with 'jsr $ffff' otherwise!)
	lda wedge_installed_flag
	bne install_rts
; save old address of chrget
	lda chrget
	sta oldwedge
	lda chrget+1
	sta oldwedge+1
	lda chrget+2
	sta oldwedge+2

; put "jmp wedge" at chrget location
	lda #$4c	; jmp instruction
	sta chrget
	lda #<wedge	; lo byte
	sta chrget+1
	lda #>wedge	; hi byte
	sta chrget+2
; flag as installed
	lda #INSTALLED
	sta wedge_installed_flag
install_rts:
	rts

uninstall_wedge:
; check if already uninstalled:
	lda wedge_installed_flag
	beq uninstall_rts
; restore old wedge values:
	lda oldwedge
	sta chrget
	lda oldwedge+1
	sta chrget+1
	lda oldwedge+2
	sta chrget+2
; flag as uninstalled:
	lda #UNINSTALLED
	sta wedge_installed_flag
uninstall_rts:
	rts

wedge:
	inc $3d		; get next byte in basic text
	bne wedge_next_basic_token	; 0c16
	inc $3e
wedge_next_basic_token:
	jsr chrgot	; re-get same char
	cmp #'&'		; is it '&'?
	beq wedge_dispatch
wedge_chrgot:
	jmp chrgot	; continue normally
wedge_dispatch:
	lda $3e		; in program mode?
	cmp #$02	; no?
	beq wedge_chrgot
; in program mode, so use wedge
; save registers:
	pha
	tya
	pha
	txa
	pha
	lda #$00
	sta $ff00	; switch to bank 15
	inc $d020	; increment border color
; restore registers:
	pla
	tax
	pla
	tay
	pla
	jmp chrget	; get next basic token

wedge_installed_flag:
	byte $00	; start out not installed ($00)
			; installed = $01
oldwedge:
; old address of wedge:
	byte $ff, $ff, $ff
