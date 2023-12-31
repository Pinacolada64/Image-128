; jump table for &'s
; jmptbl:
	word outastr	;&
	word $f400	;1-inline
	word dskin	;&,2
	word $fc00	;3-read0
	word getmdm	;&,4
	word getversn	;&,5
	word $f406	;6-password
	word prgfile	;&,7
	word dskdir	;&,8
	word $f806	;9-btmvar
	word $f800	;10-term
	word $ee00	;11-clrarr
	word $fc03	;12-newuser
	word arbit	;&,13
	word dumparr	;&,14
	word convan	;&,15
	word 49152	;&,16
	word 49155	;&,17
	word setmode	;&,18
	word getversn	;&,19

	word $fc0c	; 20 - read_interface_byte
	; Reads a byte from the interface table
	; &,20,x,y
	; x = index (see table)
	; y = command (0=put in a%, 1=return in acc)

	word $fc12	; 21 - write_interface_byte
	; Writes a byte to the interface table
	; &,21,x,y
	; x = index (see table)
	; y = value

	word tenwait	;&,22
	word xgetin	;&,23
	word xchrout1	;&,24
	word $f80c	;25-sound
	word ecschk	;&,26
	word arraysav	;&,27
	word arrayres	;&,28
	word usevar	;&,29
	word putvar	;&,30
	word zero	;&,31
	word minusone	;&,32
	word getarr	;&,33
	word putarr	;&,34
	word getln	;&,35
	word putln	;&,36
	word trapon	;&,37
	word trapoff	;&,38
	word prtln	;&,39
	word forcegc	;&,40
	word setbaud	;&,41
	word $e400	;42-ecs
	word chatchk	;&,43 chrio.asm
	word trace	;&,44
	word prtvar	;&,45
	word prtvar0	;&,46 swap3.asm
	word carchk	;&,47
	word getkbd	;&,48
	word getmod	;&,49
	word outscn	;&,50
	word outmod	;&,51
	word chkflags	;&,52
	word logoff	;&,53
	word $f409	;54-useeditr
	word output	;&,55
	word $f803	;56-chatmoe
	word $fc06	;57-relread
	word setalm	;&,58
	word farerr	;&,59
	word struct	;&,60
	word poscrsr	;&,61
	word settim	;&,62
	word $f403	;63-inline1
	word $f809	;64-convstr
	word $fc09	;65-convert
	word calcgoto	;&,66
	word $fc0c	;67-copyrite
	word $ee03	;68-struct
	word dispstr	;&,69
	word cursposn	;&,70
