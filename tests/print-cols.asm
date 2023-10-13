orig $0c00

chrout	= $ffd2 ; print character in .a
prtlin	= $8e32 ; print ascii digits of value in > .a, < .y

; working code to split number into tens place and ones place:
; .C:c000  F8          SED
; .C:c001  A9 41       LDA #$41
; .C:c003  8D 00 C1    STA $C100
; .C:c006  29 0F       AND #$0F
; .C:c008  8D 01 C1    STA $C101 ; ones digit
; .C:c00b  AD 00 C1    LDA $C100 ; original value
; .C:c00e  29 F0       AND #$F0	; not strictly necessary
; .C:c010  4A          LSR A
; .C:c011  4A          LSR A
; .C:c012  4A          LSR A
; .C:c013  4A          LSR A
; .C:c014  8D 02 C1    STA $C102 ; tens digit
; .C:c017  00          BRK

; (C:$c104) m c100 c102
; >C:c100  41 01 04

scale:
; split the column width into tens and ones digits

; initialize:
	sed
	lda llen	; get terminal line length
;	clc
;	sbc #1		; subtract one since zero-based (e.g., 0-39, not 1-40)
	lda #$00
	sta scale_column; 0 columns output so far
	sta scale_temp
	sta tens_digit
	sta ones_digit
; store ones digit:
	lda llen
	and #$f0	; %11110000
	sta ones_digit
	lda llen	; get entire value back
;	and #$0f	; %00001111 - not strictly necessary
	lsr		; convert to tens digit (repeat count)
	lsr
	lsr
	lsr
	sta tens_digit

; initialize values...
; eh... this code isn't so great
	lda #$0a	;  "__________0123456789"
	sta tens_tab_count;"0123456789": spaces to print
	lda #'0'	;  "0_________1": digit to print
	sta tens_print
	lda #$01
	sta tens_tab_flag; 1: print 11 spaces for initial tab over

	jsr prcr	; print carriage return
tens_digit0:
; determine how many times to repeat
	lda tens_digit
	beq ones_digit0	; none left

	lda tens_digit
	inc tens_print	; store it
;tens_print = * + 1
;	lda #$ff	; self-modifying digit to print
;	byte $2c	; 'bit' instruction to skip next lda
tens_tab:
tens_tab_count = * + 1
	lda #$ff	; self-modifying spaces to tab over
	clc
tens_tab_flag = * + 1	; 1: print 11 spaces, 0: print 10
	adc #$01
	lsr tens_tab_flag ; shift initial '1' bit into carry
	tay		; .y = repeat count
	lda #' '	; char to print
	jsr repeat_char	; TODO: Fix this

tens_print = * + 1
	lda #$ff	; self-modifying digit to print
	jsr chrout

; c128:
;	lda #00
;	ldx tens_digit
;	jsr prtnum

	dec tens_digit
	lda scale_column; how many columns printed
	cmp llen	; reached line length?
	bmi tens_digit0

ones_digit0:
; print last tens digit again on last column
	lda tens_print
	beq ones_digit1
	jsr chrout

ones_digit1:
	ldy ones_digit	; ones digit countdown
	beq scale_done

ones_digit_init:
	lda #'0'
	sta ones_print
ones_digit_inc:
; loop through printing '0...9' <ones_digit> times:
	inc ones_print
	lda ones_print
	cmp #':'
	beq ones_digit_init

ones_print = * + 1
	lda #$ff
	jsr chrout

	inc scale_column; decrement ones digit countdown
	lda scale_column
	cmp llen
	bmi ones_digit_inc

scale_done:
	cld
	jsr prcr	; print carriage return

; TODO: print 'L' and 'R' (or '<' and '>') for left and right margins
; (e.g., if both are set to 15):
;
;           1         2         3         4
; 01234567890123456789012345678901234567890
;                <          >
	rts

prtnum:
	; print number in > .a, < .x
	; enter with digit in .x
	; this routine label is also in editor.asm, but uses MCI £%a instead
	lda #$00
	jmp prtlin	; $8e32

; monitor
;     pc  sr ac xr yr sp
; ; fb000 00 00 00 00 f9
; a 00b00  a0 0a    ldy #$0a
; a 00b02  a9 65    lda #$65
; a 00b04  20 d2 ff jsr $ffd2
; a 00b07  88       dey
; a 00b08  d0 fa    bne $0b04
; a 00b0a  60       rts
; a 00b0b
; x
; ready.
; 10 sysdec("0b00")
; run
; EEEEEEEEEE
; ready.

repeat_char:
; print .y copies of char in .a
	cpy #00
	beq repeat_char_done
	jsr chrout
	dey
	ldx scale_column
	cpx llen
	beq repeat_char_done
	jmp repeat_char
repeat_char_done:
	rts

prcr:
	lda #$0d
	jmp chrout

scale_column:
	byte $00 ; how many columns output so far
scale_temp:
	byte $00 ; store temp values
tens_digit:
	byte $00
ones_digit:
	byte $00
llen:
	byte 40
