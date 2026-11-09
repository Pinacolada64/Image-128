#!/usr/bin/env python3
"""Write s.timezones and s.dstrules, the time zone list and the daylight
saving time rules (sub.info, sub.clocks), as PETSCII SEQ files.

  tools/dstfiles.py OUTDIR      writes OUTDIR/s.timezones and OUTDIR/s.dstrules

Put them on the system drive (drive 1, s_files.d81 here) with c1541:
  c1541 build/s_files.d81 -delete s.timezones -write OUTDIR/s.timezones "s.timezones,s"

s.timezones, a line per zone (sub.info lists them; a zone is kept as its
first 11 characters: e.data record 45 for the BBS, mid$(uf$,6) for a caller):
  1-3   standard time's name, 3 characters (the date display has room for 3)
  4-7   its offset, hhmm, from UTC-12: GMT is 1200, UTC-8 0400, UTC+9:30 2130
  8     the DST rule's letter in s.dstrules, "-" for none
  9-11  daylight time's name, spaces for none
  12-   the description (sub.info shows 28 characters of it)

s.dstrules, a line per rule (sub.clocks reads the BBS's and each caller's):
  1     the letter
  2-3   start month, 4 week (1-4, 5 = last), 5 weekday (1 = Sunday),
  6-9   time, hhmm, in standard time; 10 L (local) or U (UTC)
  11-19 the end, the same way (its time in standard time too: the US's
        2:00 AM daylight time is 0100)
  20-   a description
A start month after the end month means DST across New Year (Australia).
"""
import os
import sys

# (zone, description). The 3.0 release's zones come first in each group;
# 11/02/2026: the places in them that don't use DST are lines of their own
ZONES = [
    ("SST0100-   ", "Midway Island, Samoa"),
    ("HST0200-   ", "(US) Hawaii"),
    ("AKS0300UAKD", "(US) Alaska"),
    ("PST0400UPDT", "(US/CA) Pacific Time"),
    ("MST0500UMDT", "(US/CA) Mountain Time"),
    ("MST0500-   ", "(US) Arizona"),
    ("CST0600UCDT", "(US/CA) Central Time"),
    ("CST0600-   ", "(CA) Saskatchewan"),
    ("CST0600-   ", "Mexico City"),
    ("EST0700UEDT", "(US/CA) Eastern Time"),
    ("AST0800UADT", "(CA) Atlantic Time, Bermuda"),
    ("AST0800-   ", "Puerto Rico"),
    ("G-30900-   ", "GMT -3 Hours"),
    ("NST0930UNDT", "(CA) Newfoundland"),
    ("G-21000-   ", "GMT -2 Hours"),
    ("G-11100-   ", "GMT -1 Hour"),
    ("GMT1200EBST", "(UK) Greenwich Mean Time"),
    ("UTC1200-   ", "Universal Time, no DST"),
    ("CET1300ECES", "(EU) Central European Time"),
    ("G+11300-   ", "GMT +1 Hour"),
    ("EET1400EEES", "(EU) Eastern European Time"),
    ("G+21400-   ", "GMT +2 Hours"),
    ("G+31500-   ", "GMT +3 Hours"),
    ("G+41600-   ", "GMT +4 Hours"),
    ("G+51700-   ", "GMT +5 Hours"),
    ("G+61800-   ", "GMT +6 Hours"),
    ("G+71900-   ", "GMT +7 Hours"),
    ("WAT2000-   ", "(AU) Western Australia"),
    ("KST2100-   ", "Korean Standard Time"),
    ("G+92100-   ", "GMT +9 Hours"),
    ("CAT2130ACAD", "(AU) South Australia"),
    ("CAT2130-   ", "(AU) Northern Territory"),
    ("EAT2200AEAD", "(AU) NSW, Vic., Tas., ACT"),
    ("EAT2200-   ", "(AU) Queensland"),
    ("G112300-   ", "GMT +11 Hours"),
    ("NZT2400NNZD", "New Zealand"),
    ("G122400-   ", "GMT +12 Hours"),
]

RULES = [
    "U03210200L11110100LUS and Canada (since 2007)",
    "E03510100U10510100UEuropean Union and the UK",
    "A10110200L04110200LAustralia: NSW Vic Tas ACT SA",
    "N09510200L04110200LNew Zealand",
]


def petscii(text):
    """ASCII to PETSCII as the BBS's files have it (lower/upper case mode):
    lowercase letters $41-$5a, capitals $c1-$da"""
    out = bytearray()
    for ch in text:
        c = ord(ch)
        if 0x61 <= c <= 0x7a:
            out.append(c - 0x20)
        elif 0x41 <= c <= 0x5a:
            out.append(c + 0x80)
        else:
            out.append(c)
    return bytes(out)


def check():
    for zone, desc in ZONES:
        assert len(zone) == 11, zone
        assert zone[3:7].isdigit(), zone
        rule = zone[7]
        assert rule == "-" or any(r[0] == rule for r in RULES), zone
        assert (rule == "-") == (zone[8:11] == "   "), zone
        assert len(desc) <= 28, desc
    for rule in RULES:
        assert rule[1:9].isdigit() and rule[10:18].isdigit(), rule
        assert rule[9] in "LU" and rule[18] in "LU", rule


def main():
    # 11/06/2026: an option isn't a directory ("--help" made one called that)
    if len(sys.argv) != 2 or sys.argv[1].startswith('-'):
        sys.exit(__doc__)
    check()
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "s.timezones"), "wb") as f:
        f.write(b"".join(petscii(z + d) + b"\r" for z, d in ZONES))
    with open(os.path.join(out, "s.dstrules"), "wb") as f:
        f.write(b"".join(petscii(r) + b"\r" for r in RULES))


if __name__ == "__main__":
    main()
