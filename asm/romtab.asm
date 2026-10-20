; romtab.asm -- the ML's way into ROM. With cfg_ml in $ff00 the ROMs are
; switched out, so each ROM routine the ML (or a module) calls has a stub
; here: farcall (glue.asm) switches to cfg_rom, calls the routine, and
; switches back. equates.asm gives each stub's name and position
; (romtab + 7*n); the orig before each one stops the build if this list
; and that one ever disagree.

	orig romtab+7*0
	jsr farcall	; chrget
	byte cfg_rom
	word k_chrget
	rts
	orig romtab+7*1
	jsr farcall	; chrgot
	byte cfg_rom
	word k_chrgot
	rts
	orig romtab+7*2
	jsr farcall	; chkcom
	byte cfg_rom
	word k_chkcom
	rts
	orig romtab+7*3
	jsr farcall	; frmnum
	byte cfg_rom
	word k_frmnum
	rts
	orig romtab+7*4
	jsr farcall	; frmevl
	byte cfg_rom
	word k_frmevl
	rts
	orig romtab+7*5
	jsr farcall	; frestr
	byte cfg_rom
	word k_frestr
	rts
	orig romtab+7*6
	jsr farcall	; getbytc
	byte cfg_rom
	word k_getbytc
	rts
	orig romtab+7*7
	jsr farcall	; getadr
	byte cfg_rom
	word k_getadr
	rts
	orig romtab+7*8
	jsr farcall	; fout
	byte cfg_rom
	word k_fout
	rts
	orig romtab+7*9
	jsr farcall	; jfout
	byte cfg_rom
	word k_jfout
	rts
	orig romtab+7*10
	jsr farcall	; ptrget
	byte cfg_rom
	word k_ptrget
	rts
	orig romtab+7*11
	jsr farcall	; ptrget1
	byte cfg_rom
	word k_ptrget1
	rts
	orig romtab+7*12
	jsr farcall	; makerm1
	byte cfg_rom
	word k_makerm1
	rts
	orig romtab+7*13
	jsr farcall	; linkprg
	byte cfg_rom
	word k_linkprg
	rts
	orig romtab+7*14
	jsr farcall	; getfile
	byte cfg_rom
	word k_getfile
	rts
	orig romtab+7*15
	jsr farcall	; prtscn
	byte cfg_rom
	word k_prtscn
	rts
	orig romtab+7*16
	jsr farcall	; givayf
	byte cfg_rom
	word k_givayf
	rts
	orig romtab+7*17
	jsr farcall	; linget
	byte cfg_rom
	word k_linget
	rts
	orig romtab+7*18
	jsr farcall	; parchk
	byte cfg_rom
	word k_parchk
	rts
	orig romtab+7*19
	jsr farcall	; setmsg
	byte cfg_rom
	word k_setmsg
	rts
	orig romtab+7*20
	jsr farcall	; readst
	byte cfg_rom
	word k_readst
	rts
	orig romtab+7*21
	jsr farcall	; setlfs
	byte cfg_rom
	word k_setlfs
	rts
	orig romtab+7*22
	jsr farcall	; setnam
	byte cfg_rom
	word k_setnam
	rts
	orig romtab+7*23
	jsr farcall	; openf
	byte cfg_rom
	word k_openf
	rts
	orig romtab+7*24
	jsr farcall	; closef
	byte cfg_rom
	word k_closef
	rts
	orig romtab+7*25
	jsr farcall	; chkin
	byte cfg_rom
	word k_chkin
	rts
	orig romtab+7*26
	jsr farcall	; chkout
	byte cfg_rom
	word k_chkout
	rts
	orig romtab+7*27
	jsr farcall	; clrchn
	byte cfg_rom
	word k_clrchn
	rts
	orig romtab+7*28
	jsr farcall	; chrin
	byte cfg_rom
	word k_chrin
	rts
	orig romtab+7*29
	jsr farcall	; chrout
	byte cfg_rom
	word k_chrout
	rts
	orig romtab+7*30
	jsr farcall	; loadf
	byte cfg_rom
	word k_loadf
	rts
	orig romtab+7*31
	jsr farcall	; savef
	byte cfg_rom
	word k_savef
	rts
	orig romtab+7*32
	jsr farcall	; getin
	byte cfg_rom
	word k_getin
	rts
	orig romtab+7*33
	jsr farcall	; plot
	byte cfg_rom
	word k_plot
	rts
	orig romtab+7*34
	jsr farcall	; setbnk
	byte cfg_rom
	word k_setbnk
	rts
	orig romtab+7*35
	jsr farcall	; kbdget
	byte cfg_rom
	word k_kbdget
	rts
	orig romtab+7*36
	jsr farcall	; gotol
	byte cfg_rom
	word k_gotol
	rts
	orig romtab+7*romtab_entries
