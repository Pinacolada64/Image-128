# Empire 6.0 (Image 1.2 version)

The Image 1.2 port of Empire, as it stands in
[Pinacolada64/ImageBBS](https://github.com/Pinacolada64/ImageBBS) at
`v1.2/games/empire6` (commit `02505c6`, 2024-06-26), copied here unchanged
as the starting point for the Image 128 port (branch `empire`).

- `Empire6.lbl`: the resident part, `+.empire 6` (lines 1-799): stats,
  ranks, the turn loop. `includes.lbl` names its lines for the modules.
- `plus_emp6_*.lbl`: the "mini-plus" (LMP) modules, `+.emp6.<name>`, loaded
  at line 800 by `{:sub.load_lmp}` and ending in RETURN: `startup` (the
  wall, new players), `startturn`, `trading`, `colony`, `combat`,
  `endturn`, `town`, `maint`, `tourney`, `quests` (not started).
- `*.txt`: the game's texts (intro, menus, islands, tournament, win and
  wreck stories, docs), from Empire Deluxe on Centipede 128 BBS;
  `mdl.emp.delx*.txt` are that BBS's BASIC 7 program, for reference.
- `changelog.txt`: what changed from Empire 5.1, and what's still to do;
  `variables.txt`: the game's variables.

The Image 128 modules made from these are in `modules/` (`i.empire`,
`i/emp.*`).
