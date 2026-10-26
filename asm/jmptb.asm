; jump table for &'s, at jmptbl ($1a00). Entries in a swapped-out
; module are its parked (bank 1) address plus the offset of its entry:
; usetbl0 sends those through caller (calls.asm), which swaps it in.
; jmptbl:
	word outastr	;&
	word swap1_swap_address	;1-inline
	word dskina	;&,2 (128: dskin, then a$ copied: miscl.asm)
	word swap3_swap_address	;3-read0
	word getmdm	;&,4
	word getversn	;&,5
	word swap1_swap_address+6	;6-password
	word prgfile	;&,7
	word dskdir	;&,8
	word swap2_swap_address+6	;9-btmvar
	word swap2_swap_address	;10-term
	word arrclr	;&,11 (128: resident, miscl.asm; was in struct)
	word swap3_swap_address+3	;12-newuser
	word arbit	;&,13
	word dumparr	;&,14
	word convan	;&,15
	word protostart	;&,16 (c64: 49152)
	word protostart+3	;&,17 (c64: 49155)
	word setmode	;&,18
	word getversn	;&,19

	word swap3_swap_address+12	; 20 - read_interface_byte
	; Reads a byte from the interface table
	; &,20,x,y
	; x = index (see table)
	; y = command (0=put in a%, 1=return in acc)

	word swap3_swap_address+18	; 21 - write_interface_byte
	; Writes a byte to the interface table
	; &,21,x,y
	; x = index (see table)
	; y = value

	word tenwait	;&,22
	word xgetin	;&,23
	word xchrout1	;&,24
	word swap2_swap_address+12	;25-sound
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
	word ecs_swap_address	;42-ecs
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
	word swap1_swap_address+9	;54-useeditr
	word output	;&,55
	word swap2_swap_address+3	;56-chatmoe
	word swap3_swap_address+6	;57-relread
	word setalm	;&,58
	word farerr	;&,59
	word struct	;&,60
	word poscrsr	;&,61
	word settim	;&,62
	word swap1_swap_address+3	;63-inline1
	word swap2_swap_address+9	;64-convstr
	word swap3_swap_address+9	;65-convert
	word calcgoto	;&,66
	word swap3_swap_address+12	;67-copyrite
	word struct_swap_address+3	;68-struct
	word dispstr	;&,69
	word cursposn	;&,70
	word putvar2	;&,71 (128): var to the descriptor at varpnt, keeping BASIC 7's
			; back-links (varbl.asm); for the struct module
