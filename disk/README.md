# disk/

Data files `asm/build.sh` writes to `build/image128.d71` as they are.

| File | On the disk as | From | What it is |
|---|---|---|---|
| `e.lightbar.prg` | `e.lightbar` | Image BBS 3.0 release, D2 (2023-12-31) | the lightbar's 64 three-letter labels, loaded by `im` line 3110 (`&,7,dv%,8`, into `bartbl`) |
| `e.lightdefs.seq` | `e.lightdefs` (SEQ) | Image BBS 3.0 release, D2 (2023-12-31) | the checkmarks the BBS starts with: 8 lines (pages) of 16 digits, read by `im` lines 3250-3258 |

The 3.0 originals are on `master d2 2023-12-31.d81` in the ImageBBS3
repo (`Larry Hedman/master-release-2023-12-31/`).
