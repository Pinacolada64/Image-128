1 rem &,69 on the 80-column status area's right half (columns 40-79), drawn
2 rem with the mask off and on. steps wait for the monitor: > 0b00 01, 02, 03
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 2816,0
6 &chr$(147)
10 for i=1 to 30:&"line"+str$(i)+" of the scroll test"+chr$(13):next
12 &,69,42,24,"row 24 right",7
13 &,69,42,18,"row 18 right, drawn unmasked",13
14 &,69,2,18,"row 18 left",5
15 if peek(2816)=0 then 15
16 &,18,1
17 if peek(2816)=1 then 17
20 for i=31 to 35:&"masked"+str$(i)+chr$(13):next
30 if peek(2816)=2 then 30
35 &,18,0
40 &,69,42,19,"row 19 right, drawn unmasked",3
45 for i=41 to 45:&"unmasked"+str$(i)+chr$(13):next
46 if peek(2816)=3 then 46
47 &,18,1
50 goto 50
