1 rem &,9 (swap2's btmvar): a variable in the 16-character window, row 22
2 rem columns 24-39 (adisp+24, 1928; btmwin, $19ba, in 80 columns). 11/27/2026: a number variable came
3 rem out garbage; now it's shown as text (usevarn, &,73). Each case sets
4 rem the variable and shows it straight away (& output sets rc, sh and kp%),
5 rem then reads the window back: got | want, * if they differ
6 rem kp% is ml variable 38 (integer), sh 18 and rc 17 (floating point),
7 rem an$ 0 (a string). prints "done n failed"
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,40:f=0
11 w=1928:if peek(215) and 128 then w=6586:rem 80 columns: btmwin ($19ba)
12 &chr$(147):&,18,1:rem the mask on: btmvar draws nothing with it off (scnmode, 2787)
20 kp%=1234:&,9,38:w$="1234":gosub 100
22 kp%=-7:&,9,38:w$="-7":gosub 100
24 kp%=0:&,9,38:w$="0":gosub 100
30 sh=3.25:&,9,18:w$="3.25":gosub 100
32 rc=-2.5:&,9,17:w$="-2.5":gosub 100
34 sh=1000000:&,9,18:w$="1000000":gosub 100
36 sh=0:&,9,18:w$="0":gosub 100
40 an$="hello":&,9,0:w$="hello":gosub 100
50 &"done"+str$(f)+" failed"+chr$(13)
60 goto 60
100 g$="":for i=0 to 15:c=peek(w+i) and 127:if c<32 then c=c+64:goto 104
102 if c>63 then c=c+64-64*(c<96)
104 g$=g$+chr$(c):next
106 do while left$(g$,1)=" ":g$=mid$(g$,2):loop
108 do while right$(g$,1)=" ":g$=left$(g$,len(g$)-1):loop
110 e$=" ":if g$<>w$ then e$="*":f=f+1
112 &g$+" | "+w$+" "+e$+chr$(13):return
