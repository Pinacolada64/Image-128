1 rem lightbar: labels (e.lightbar) and default checkmarks (e.lightdefs), as im loads them;
2 rem f1 mask, f3/f5 move, f4/f6 jump a row, f7/f8 toggle a check
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
6 &chr$(147)
7 a$="0:e.lightbar":&,7,8,8
8 open 2,8,2,"0:e.lightdefs,s,r"
9 for x=0 to 7:&,2,2:for i=1 to 16:&,52,x*16+i-1,val(mid$(a$,i,1)):next:next:close 2
10 &"lightbar test"+chr$(13)+chr$(13)
11 &"f1: mask on/off   f2: blank screen"+chr$(13)
12 &"f3/f5: highlight left/right"+chr$(13)
13 &"f4/f6: highlight up/down a row (8)"+chr$(13)
14 &"f7/f8: toggle the highlighted check"+chr$(13)
15 &,18,1
20 goto 20
