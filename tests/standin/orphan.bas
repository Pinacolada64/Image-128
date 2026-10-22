1 rem &,15,6 (strscan) and &,15,5 (newdate) shorten an$. the c64 moved
2 rem its pointer past the dropped characters; basic 7's garbage collection
3 rem then read the last two of them as a back-link and wrote through it.
4 rem here an$ ends up past chr$(11), so 0 and 11 would point it at $0b00
5 rem (2816), where a fake descriptor waits: len 3, ptr $55aa (170 85)
6 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 print "&,15,6 / &,15,5 orphan test":f=0
20 poke 2816,3:poke 2817,170:poke 2818,85
30 an$="qqq"+chr$(0)+chr$(11)+"rest":&,15,6,11
40 if len(a$)<>4 or an$<>"rest" then print "split wrong":f=1
50 x=fre(1)
60 print "$0b01/2 after gc:";peek(2817);peek(2818)
70 if peek(2817)<>170 or peek(2818)<>85 then print "written through the orphan":f=1
100 an$="abc"+" def":&,15,6,32:if a$<>"abc" or an$<>"def" then print "case 1:"a$","an$:f=1
110 an$="abc"+"":&,15,6,32:if a$<>"abc" or an$<>"" then print "case 2:"a$","an$:f=1
120 an$=" "+"x":&,15,6,32:if a$<>"" or an$<>"x" then print "case 3:"a$","an$:f=1
130 an$="":&,15,6,32:if a$<>"" or an$<>"" then print "case 4:"a$","an$:f=1
140 an$="1901103"+"8045":&,15,5:if len(an$)<>10 or right$(an$,4)<>"8045" then print "case 5:"an$:f=1
150 x=fre(1):if peek(2817)<>170 or peek(2818)<>85 then print "written after cases":f=1
160 if f then print "failed":end
170 print "all passed":end
