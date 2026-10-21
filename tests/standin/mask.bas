1 rem screen mask: on and off (&,18), with console text scrolling underneath.
2 rem steps wait for the monitor: > 0b00 01, then > 0b00 02 (or f1 toggles it)
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 2816,0
6 &chr$(147)
10 for i=1 to 30:&"line"+str$(i)+" of the scroll test"+chr$(13):next
15 &,18,1
20 for i=31 to 40:&"masked"+str$(i)+chr$(13):next
21 rem lines longer than the screen: a wrap mustn't push the mask down
22 a$="that wraps onto the next row, longer than the screen is wide, 40 or 80 columns. ":for i=1 to 6:&"long"+str$(i)+" "+a$+chr$(13):next
30 if peek(2816)=0 then 30
35 &,18,0
40 for i=41 to 45:&"unmasked"+str$(i)+chr$(13):next
50 goto 50
