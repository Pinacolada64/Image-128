# DO/LOOP candidates in Image BBS 128's BASIC

Scanned 10/27/2026: `modules/*.lbl` (182 files), `im 128.bas` and
`i_su.config.lbl`, looking for loops built from a backward jump (`goto`,
`if ... then N`, `on -(...) goto N` to the same or an earlier line, up to 4
lines back) and FOR loops ended early by setting their own variable.
Line ranges are *top-bottom* of each loop. The scan is by pattern, so treat
each entry as "look here", not as a verified rewrite.

**Since the scan** (10/28/2026):
- i.WF's and sub.editor's file loaders (3036, 3118; 60036, 60118) are im
  line 47 now, a DO loop in im's low lines.
- i/lo.idle is built with C64List 4.06 (`instr`, DO); sub.misc2's loader
  (60280) is a DO loop.
- i.lo.cp, i.lo.rf, i.lo.vf and i.lo.em are gone (the idle screen runs
  i.CP, i.RF, i.VF and i.EM): skip their rows below.
- A module written with `{:labels}` can't move to C64List 4.06, which
  numbers such a file from 0 whatever `{number:}` says: it keeps to BASIC
  2 (i.edit idlecmds), or needs its lines numbered first.

## Why it's worth it: backward GOTO is slow here

GOTO to an earlier line searches from the start of the program, a line at
a time. A module's lines come after im's (236 lines below 3000), so every
pass of a hand-made loop in a module walks through all of those, plus the
module's own lines before the loop (and, for a sub.* module at 60000, those
of the i.* module loaded with it): typically 300-450 lines. Measured on x128 (1 MHz, 500 passes of `k=k+1`, behind an
im-sized program of 430 lines / 19 KB):

| Loop | Jiffies (1/60 s) |
|---|---|
| `if k<500 then 60010`, at line 60010 | 2908 (48 s; ~87 ms a pass) |
| the same at line 2 | 307 |
| `do:k=k+1:loop while k<500` | 290, wherever it is |
| `for k=1 to 500:next` | 47 |

That's about 0.2 ms a line searched, so a hand-made loop in a module costs
60-90 ms a pass just finding its line (half that at 2 MHz): reading 250 lines of a file that way is ~20 s of
searching. DO/LOOP keeps the text pointer on BASIC 7.0's stack and doesn't
search. FOR/NEXT is faster still: **leave FOR loops as they are.**

Also checked: RETURN from inside a DO or FOR leaves BASIC 7.0's stack clean
(same as `exit`); only a GOTO or THEN out of a loop leaves its frame
behind (PROGRAMMING.md, "What leaves garbage").

## Before converting a module

DO/LOOP is BASIC 7.0, so the module must be built with C64List 4.06 and
`Basic70.bas` instead of `3_0-preface.lbl`, with its jumps into im written
as `{$33}`, `{$39}99` and so on (done so far: sub.stack, i.VL, sub.modem,
i/IM.modem, sub.misc2). The way that's worked: convert, build, check the
program is byte-for-byte the 4.04 build, then change the loops. The
converter I used for those (a scratch script, not in `tools/` yet) misses a jump right after THEN (`thengosub30`) or
after a variable (`onntgoto999`); C64List 4.06 reports those as "Can't
locate target line", and the identical-build check catches anything else.

## Patterns and rewrites

Condition at the end:

```
3210 n=n+1:&,2,2:tt$(n)=a$:if st=.then 3210
3210 do:n=n+1:&,2,2:tt$(n)=a$:loop until st
```

`on -(...) goto` with more after it on the line:

```
4606 &,2,2:kk=kk+1:ed$(kk)=a$:on-(st=0andkk<61)goto4606:close2:u=1
4606 do:&,2,2:kk=kk+1:ed$(kk)=a$:loop while st=0 and kk<61:close2:u=1
```

The jump inside an IF's THEN (a false IF skips the rest of the line, LOOP
included, so the test turns round into an EXIT):

```
4592 &,2,2:ifa$<>"{^}"andkk<101thentt$(kk)=a$:kk=kk+1:goto4592
4592 do:&,2,2:if a$="{^}" or kk>100 then exit
4593 tt$(kk)=a$:kk=kk+1:loop
```

## 1. Convert: file-reading loops with no way out but the end (112)

Each pass reads from disk (`&,2,2`, `input#`, `read`...), so these run many
times; nothing jumps out of them, and anything that jumps in goes to the
top line. These are the ones to do.

| Module | Loops |
|---|---|
| `i.CP.v3.1.lbl` | 3398-3400 |
| `i.EM.lbl` | 3070-3072, 3204-3204, 3218-3218, 3504-3508, 3516-3518 |
| `i.IM.lbl` | 3210-3210 |
| `i.JA.lbl` | 3022-3028 |
| `i.LN.lbl` | 3072-3076, 3084-3086 |
| `i.NF.lbl` | 3090-3090 |
| `i.NM_auto.lbl` | 3228-3228, 3444-3446, 3704-3704 |
| `i.NM_config.lbl` | 3572-3578, 3642-3642 |
| `i.NM_utils.lbl` | 3094-3094, 3494-3500 |
| `i.NW.lbl` | 3016-3016, 3042-3046, 3090-3090, 3104-3104 |
| `i.RF.lbl` | 3086-3088, 3140-3140 |
| `i.VB.lbl` | 3004-3004, 3072-3074, 3102-3102, 3106-3106 |
| `i.VF.lbl` | 3004-3004, 3034-3034, 3116-3116 |
| `i.WF.lbl` | 3036-3036, 3118-3118 |
| `i.lo.em.lbl` | 3070-3072, 3204-3204, 3218-3218, 3504-3508, 3516-3518 |
| `i.lo.im.lbl` | 3210-3210 |
| `i.lo.rf.lbl` | 3086-3088, 3140-3140 |
| `i.lo.vf.lbl` | 3004-3004, 3034-3034, 3116-3116 |
| `i.misc2.lbl` | 3148-3150 |
| `i.relread.lbl` | 3014-3020 |
| `i_EM.fwd.lbl` | 4020-4020 |
| `i_GF-maint.lbl` | 4524-4524 |
| `i_IM.modem.lbl` | 4602-4606, 4622-4624, 4862-4866, 4872-4872, 4882-4886 |
| `i_IM.netmail.lbl` | 4534-4540, 4604-4604 |
| `i_MM.maint.lbl` | 4054-4054 |
| `i_MM.sb-edit.lbl` | 4036-4038 |
| `i_MM.u_d_c.lbl` | 4016-4016, 4018-4018 |
| `i_MM.ud-local.lbl` | 4110-4116 |
| `i_NM.mail.lbl` | 4538-4538, 4606-4606, 4632-4632, 4680-4682, 4906-4906, 4940-4940 |
| `i_NM.netsub2.lbl` | 4070-4070 |
| `i_NM.netsub3.lbl` | 4080-4080, 4098-4098, 4104-4108 |
| `i_NM.netsub4.lbl` | 4050-4050, 4062-4064 |
| `i_NM.sort.lbl` | 4406-4406, 4426-4426, 4622-4628, 4814-4814, 4846-4848 |
| `i_NM.update.lbl` | 4006-4006, 4032-4032, 4056-4062, 4086-4086 |
| `i_SM.alpha_ind.lbl` | 4026-4030, 4036-4040 |
| `i_SM.fixer.lbl` | 4080-4080 |
| `i_SM.lk util.lbl` | 4236-4236 |
| `i_SM.netfile.lbl` | 4076-4076 |
| `i_SM.reledit.lbl` | 4294-4296, 4622-4624, 4650-4650 |
| `i_SM.scan netlog.lbl` | 4004-4008 |
| `i_lo!telecheck.lbl` | 4510-4510 |
| `i_lo-anagram.lbl` | 4556-4558 |
| `i_lo-jerk.lbl` | 4514-4520 |
| `i_lo-netwall.lbl` | 4514-4514, 4540-4544, 4588-4588, 4602-4602 |
| `i_lo-news2.lbl` | 4592-4592 |
| `i_lo-vote.lbl` | 4526-4528, 4538-4538, 4542-4542 |
| `i_lo-wall.lbl` | 4520-4522 |
| `i_lo.misc.lbl` | 4364-4368 |
| `i_lo_an.lbl` | 4006-4008 |
| `i_lo_cp maint.lbl` | 4008-4008 |
| `i_lo_payroll.lbl` | 4004-4004 |
| `sub.editor.lbl` | 60036-60036, 60118-60118 |
| `sub.info.lbl` | 60086-60086 |
| `sub.modem.lbl` | 60010-60025 |
| `sub.param1.lbl` | 60108-60108 |
| `sub.protos.lbl` | 60040-60040 |

## 2. Also convertible, rarely repeated (138)

Same shape, no file reading: input prompts that ask again (`if an$="" then
4220`), padding (`if len(ed$(3))<8 then ...:goto 4686`), random picks. They
seldom go round more than once or twice, so the gain is tidiness, not
speed: not worth a pass of their own. Do them when a module is open for
something else.

## 3. Need EXIT or reworking (94 reading files, 273 not)

A GOTO or THEN from inside the loop to somewhere else: as DO loops, each
such jump must become `exit` (then the code after LOOP decides where to
go), or it leaves a 5-byte frame on BASIC 7.0's stack each time. Worth it
for the file readers when the module is converted anyway:

| Module | Loops |
|---|---|
| `i.BB.lbl` | 3212-3212, 3218-3218 |
| `i.CP.v3.1.lbl` | 3272-3272, 3420-3424 |
| `i.DE.lbl` | 3110-3112, 3140-3142, 3140-3144, 3206-3208, 3206-3212, 3220-3222, 3220-3224, 3264-3266, 3264-3268 |
| `i.DE2.lbl` | 3110-3112, 3140-3142, 3140-3144, 3206-3208, 3206-3212, 3220-3222, 3220-3224, 3264-3266, 3264-3268 |
| `i.DX.lbl` | 3108-3110, 3150-3152, 3150-3154, 3150-3156 |
| `i.EM.lbl` | 3078-3078, 3234-3234, 3230-3236, 3298-3298 |
| `i.JA.lbl` | 3080-3084, 3116-3120 |
| `i.NM_utils.lbl` | 3412-3416, 3446-3450 |
| `i.NW.lbl` | 3088-3088 |
| `i.RF.lbl` | 3108-3112 |
| `i.SF.lbl` | 3092-3096, 3092-3098 |
| `i.UB.lbl` | 3016-3018 |
| `i.UD.lbl` | 3336-3342, 3426-3432 |
| `i.UL.lbl` | 3088-3094 |
| `i.VF.lbl` | 3068-3072, 3158-3158, 3296-3296 |
| `i.lo.em.lbl` | 3078-3078, 3234-3234, 3230-3236, 3298-3298 |
| `i.lo.rf.lbl` | 3108-3112 |
| `i.lo.vf.lbl` | 3068-3072, 3158-3158, 3296-3296 |
| `i.relread.lbl` | 3018-3020 |
| `i_EM.fwd.lbl` | 4040-4040, 4030-4040 |
| `i_IM.modem.lbl` | 4364-4370, 4808-4814 |
| `i_MM.sb-edit.lbl` | 4052-4052 |
| `i_MM.u_d_c.lbl` | 4036-4040 |
| `i_NM.mail.lbl` | 4678-4678, 4682-4682, 4954-4960 |
| `i_NM.netsub2.lbl` | 4008-4008, 4040-4040 |
| `i_NM.netsub3.lbl` | 4048-4050, 4086-4086 |
| `i_NM.sort.lbl` | 4618-4618, 4628-4628 |
| `i_NM.update.lbl` | 4118-4118, 4128-4128 |
| `i_SM.bu.lbl` | 4010-4012 |
| `i_SM.conmenu.lbl` | 4008-4010 |
| `i_SM.consig2.lbl` | 4008-4012 |
| `i_SM.reledit.lbl` | 4402-4408 |
| `i_lo-fmail.lbl` | 4506-4508, 4506-4510, 4506-4512 |
| `i_lo-jerk.lbl` | 4530-4536, 4574-4578 |
| `i_lo-netwall.lbl` | 4586-4586 |
| `i_lo-vote.lbl` | 4504-4508 |
| `i_lo-wall.lbl` | 4530-4536 |
| `i_lo.mail.lbl` | 4010-4010, 4006-4010 |
| `i_lo.misc.lbl` | 4310-4312 |
| `i_lo.tt maint.lbl` | 4006-4008, 4006-4012 |
| `i_lo_jerk.lbl` | 4010-4014 |
| `i_lo_lkbu.lbl` | 4010-4012 |
| `i_lo_today.lbl` | 4026-4032 |
| `i_lo_tt maint.lbl` | 4006-4008, 4006-4012 |
| `sub.comm1.lbl` | 60122-60126 |

Seven more jump out only to im (an error or carrier-loss exit to 999 and
the like): i.RF and i.lo.rf 3024-3030, i.WF 3134-3136, i.sigedit
3004-3012, i_lo-cr pool 4520-4522, sub.editor 60134-60136. Those paths
leave the module anyway; an `exit` first still keeps the stack clean.

## 4. Leave

- **Long loops (688 backward jumps over 5+ lines):** menus that redraw
  after each command and multi-line retries, entered from several places;
  they run once per keypress, so the search costs nothing a caller notices.
- **Several jumps back to the same top (11):** i_SM.alpha_ind 4026-4032 and
  4036-4042, sub.misc 60094-60100, i.CP.v3.1 3078-3082, i.MU (4), i.NM_auto
  3422-3428, i.t 3324-3332. Need restructuring, not a mechanical swap.
- **FOR loops ended early (84):** the `i=i+rc*n` / `x=ur` idiom to stop a
  listing on the abort key. BASIC 7.0 has no EXIT for FOR, and FOR/NEXT is
  the fastest loop there is; a DO version would be longer and slower.

## Duplicates

Several modules are near-copies and share their loops: i.EM / i.lo.em,
i.IM / i.lo.im, i.RF / i.lo.rf, i.VF / i.lo.vf, i.DE / i.DE2, i_IM.logon /
i_IM.lo.logon, i_lo.login / i_lo.login+, i_lo.tt maint / i_lo_tt maint.
Worth checking which of each pair is still on a disk before converting
both.
