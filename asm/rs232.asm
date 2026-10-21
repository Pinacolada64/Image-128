{include:"equates.asm"}

orig protostart ; "rs232.prg"

; ml.rs232: im loads it at protostart (&,7,dv%,2) and runs it with &,16,a:
; .x = 0 for the user port driver, 1 for the SwiftLink.
;
; c64: it copied the driver to rs232, where it ran, with its jump table
; at the front. On the 128 the drivers are assembled at
; rs232_exec_address ($2c00), and rs232 ($1912) is a separate 21-byte
; table the ML calls (rts until now): copy the driver there, then point
; the table's first six entries at the driver's own (setup, enable,
; disable, get, out, baud; the seventh, rschar, stays an rts).

ml:
	cpx #2
	bcs ml4
	lda rslow,x
	sta ml1+1
	lda rshigh,x
	sta ml1+2
	ldy #0
	ldx #3
ml1:
	lda rs232a,y
ml2:
	sta rs232_exec_address,y
	iny
	bne ml1
	inc ml1+2
	inc ml2+2
	dex
	bne ml1
	ldx #0
ml3:
	lda #$4c	; jmp rs232_exec_address + .x
	sta rs232,x
	txa
	clc
	adc #<rs232_exec_address
	sta rs232+1,x
	lda #>rs232_exec_address
	adc #0
	sta rs232+2,x
	inx
	inx
	inx
	cpx #6*3
	bcc ml3
ml4:
	jmp rs232	; the driver's setup (an rts if none was loaded)

rslow:
	byte <rs232a, <rs232b
rshigh:
	byte >rs232a, >rs232b

rs232a:
	embed "rs232_user.bin"
rs232b:
	embed "rs232_swift.bin"
