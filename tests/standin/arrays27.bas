1 rem &,27/&,28 levels. a level holds two offsets from vartab (strend and
2 rem arytab), not arrays of its own. tests the hypothesis that &,27,3,
3 rem dim tt$(10), &,27,4, dim tt$(10) keeps two independent tt$() arrays:
4 rem the 2nd dim is ?redim'd array, and both levels see one tt$(). also:
5 rem variables made after &,27 go at &,28; nested levels; levels 4-6 write
6 rem over daysofm ($13e0, 12 bytes), level 7 over emptym2 ($13ec).
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 dim f,e,i,l,t$,d$,dm$
30 print chr$(147);"arrays27":trap 900
40 dm$="":for i=0 to 11:dm$=dm$+chr$(peek(5088+i)):next
100 &,27,3:dim tt$(10):tt$(1)="level 3":print "1 &,27,3:dim tt$(10):tt$(1)=";chr$(34);"level 3";chr$(34)
120 print "2 &,27,4:dim tt$(10)";:&,27,4:e=0:dim tt$(10)
130 if e=0 then print ": no error, a second tt$()":f=f+1:else print ": ?";err$(e);" error, ok"
140 tt$(1)="level 4":print "  tt$(1)=";chr$(34);"level 4";chr$(34)
150 &,28,4:t$=tt$(1):print "3 &,28,4: tt$(1)=";chr$(34);t$;chr$(34);
160 if t$="level 3" then print ": two arrays, hypothesis holds":f=f+1:else print ": one array, hypothesis fails, ok"
170 &,28,3:t$=tt$(1):print "4 &,28,3: tt$(1)=";chr$(34);t$;chr$(34);
180 if t$<>"" then print ": tt$() kept, wrong":f=f+1:else print ": tt$() dropped, ok"
200 print "5 &,27,3:n9=9:&,28,3:n9=";:&,27,3:n9=9:&,28,3:print n9;:if n9 then f=f+1:print ": kept, wrong":else print ": dropped, ok"
300 print "6 nested: a$() at 3, b$() at 4"
310 &,27,3:dim a$(5):a$(1)="a":&,27,4:dim b$(5):b$(1)="b"
320 &,28,4:t$=a$(1)+"/"+b$(1):print "  &,28,4: a/b=";t$;:if t$<>"a/" then f=f+1:print " wrong":else print " ok"
330 &,28,3:t$=a$(1)+"/"+b$(1):print "  &,28,3: a/b=";t$;:if t$<>"/" then f=f+1:print " wrong":else print " ok"
400 gosub 800:print "7 daysofm after &,27,l (4 wrote over it in 2 and 6):"
410 for l=0 to 7:&,27,l:d$="":for i=0 to 11:d$=d$+chr$(peek(5088+i)):next
420 e=(d$<>dm$):print " ";l;mid$("same   changed",1-7*e,7);
430 if e<>(l>3 and l<7) then f=f+1:print "?";
440 gosub 800:next:print
500 if f then print f;"not as modelled":end
510 print "all as modelled":end
800 for i=0 to 11:poke 5088+i,asc(mid$(dm$,i+1)):next:return
900 e=er:resume next
