1 rem &,15,7: a string centered for ll% (center.asm), and the mci tab
2 rem (\_nn: mtab, center_lo.asm). failed checks are listed at the end
3 rem (for &,15,7: the column wanted and what it put in front), then "done"
4 rem and the count. \ is the pound, _ the back arrow (petcat)
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 56328,0
15 print chr$(147);:f=0:f$=""
20 ll%=40:a$="hello":&,15,7:x$="plain":e$="17":gosub 900
25 a$=chr$(5)+"hello"+chr$(146):&,15,7:x$="colors":e$="17":gosub 900
30 b$="world":a$="hi \$b!":&,15,7:x$="pound-$":e$="15":gosub 900
35 n%=123:a$="n=\%n":&,15,7:x$="pound-%":e$="17":gosub 900
40 n%=-5:a$="\#3\%n":&,15,7:x$="field #3":e$="18":gosub 900
45 d1$="abcd":a$="\v0":&,15,7:x$="pound-v":e$="18":gosub 900
50 a$="\o-":&,15,7:x$="pound-o":e$="10":gosub 900
55 a$="a\\b":&,15,7:x$="two pounds":e$="18":gosub 900
60 a$="\9x":&,15,7:x$="not mci":e$="18":gosub 900
65 a$="\a1xx\yz":&,15,7:x$="compare":e$="19":gosub 900
70 a$="hello":&,15,7,80:x$="width 80":e$="37":gosub 900
75 c$="hello":&,15,7,0,c$:a$=c$:x$="c$":e$="17":gosub 900
80 a$="hello":&,15,7:&,15,7:x$="twice":e$="17":gosub 900
81 if len(a$)<>9 then f=f+1:f$=f$+" twice-len"
85 &,15,7,80:x$="again, 80":e$="37":gosub 900
90 a$="":for i=1 to 50:a$=a$+"x":next:&,15,7:x$="too wide":e$="00":gosub 900
95 ll%=0
96 a$="hello":&,15,7:if a$<>"hello" then f=f+1:f$=f$+" no-ll%(len"+str$(len(a$))+" "+mid$(a$,1,4)+" ll%"+str$(ll%)+")"
97 ll%=40
98 n=5:&,15,7,0,n:if n<>5 then f=f+1:f$=f$+" number"
100 rem the tab: the screen's column at the idle screen (local 1)
110 poke 53248,1:&,70,0,18:&"\_10x":p=pos(0):if p<>11 then f=f+1:f$=f$+" tab10-local"+str$(p)
120 &,70,0,19:&"\_50x":p=pos(0):if p<>1 then f=f+1:f$=f$+" tab50-local"+str$(p)
130 rem the caller's column (local 0): ll% 80, so modclmn 80 (akfix); the
131 rem loc checkmark ($1300 bit 4) on, as at a console login: without a
132 rem carrier, carchk would stop & output
135 poke 4864,peek(4864) or 16
140 ll%=80
150 poke 53248,0:a$=chr$(13)+"\_50x":&:m=peek(6272):k=peek(6267):poke 53248,1
155 if m<>51 or k<>80 then f=f+1:f$=f$+" tab50-caller80"+str$(m)+str$(k)
160 ll%=40
170 poke 53248,0:a$=chr$(13)+"\_50x":&:m=peek(6272):poke 53248,1
175 if m<>1 then f=f+1:f$=f$+" tab50-caller40"+str$(m)
180 print chr$(147);"failed:";f$:print "done";f;"failed":end
900 if left$(a$,2)="\_" and mid$(a$,3,2)=e$ then return
910 f=f+1:f$=f$+" "+x$+"(want "+e$+" got "+mid$(a$,3,2)+")":return
