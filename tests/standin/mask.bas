1 rem screen mask: on and off (&,18), with console text scrolling underneath.
2 rem line 30 waits for a key (or the monitor: > 0b00 01); f1 toggles the mask
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 2816,0
6 &chr$(147)
10 for i=1 to 30:lp=1:&"line \!i of the scroll test":next
15 &,18,1
20 for i=31 to 40:lp=1:&"masked \!i":next
21 rem lines longer than the screen: a wrap mustn't push the mask down
22 a$="that wraps onto the next row, longer than the screen is wide, 40 or 80 columns.":for i=1 to 6:lp=1:&"long \!i "+a$:next
25 &"Press any key: "
30 do:get k$:loop while k$="" and peek(2816)=0
35 &"{f6}":&,18,0
40 for i=41 to 71:lp=1:&"unmasked \!i":next
50 goto 50
