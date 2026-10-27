# TODO.md

- [ ] combine i_SM.consig1 and i_SM.consig2 into one module, `lm=1...2` to pick conversion task
- [ ] split directory entries into filenames (keeping surrounding quotes) with &,15,6 (see i.DE2, lines 3084-3088), compare with ImageBBS3 repo, i.CP rework
- [ ] use _e.g._, `a=instr("ABCDE",an$):on a goto ...` instead of `on -(an$="A")-2*(an$="B") goto ...`
- [ ] fix im's nested sub.* reload (lines 100-112, as in the 3.0 release): when a sub.* module calls another (e.g. logoff: sub.misc runs sub.modem through line 74), line 102 does `new 60000` and reloads the caller through line 110 while BASIC is still inside a gosub from the caller's own lines; on the 128 logoff then corrupts memory (the tt$() array header, screen cells) after the sub.misc reload
- [ ] i/lo-last miscalculates the time used: 12:00 AM to 12:01 AM reads as 100 minutes, not 1 minute
- [ ] when porting `++ path` (path.asm `loadfile`) and `++ post` (post.asm, twice): they pass `a$` (bank 1) to `setnam` without `setbnk`, so the KERNAL reads the filename from whatever bank the last `setbnk` left; call `setbnk` with .a=0, .x=1 first, as prgfile and ecs.asm's ecsload do (ECS lost its definitions that way: every ECS command "Unknown")
- [ ] ML: in 80 columns, say what the status flags on the bottom line (row 24, `tdisp`) mean in words on its right half (columns 40-79): today they're single reversed letters at `tdisp+30`-`+32` and `+39` (`S` swapping a module in, `G` garbage collection, and the ones `chrio.asm`, `setup.asm` and `irqhn.asm` set), e.g. "Swapping", "Garbage collect", "Pausing", "Interrupt"; `vdcstat` copies only the left 40 columns, `&,69`'s `dispvdcr` owns the right half
- [ ] 80 columns: a lightbar across the whole width (the status area's right half, columns 40-79, is free apart from `&,69`'s text): more checkmarks or wider labels than the 40-column one, drawn on the VDC (`lightbar.asm`, `dispvdcr`)
