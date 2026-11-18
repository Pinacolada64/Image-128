1 rem a lt. kernal (device 8) as sub.su.copy and setup's drives part use a
2 rem drive: run by tools/ltk_dos.py (the stand-in on a 1581 at 9), which
3 rem reads the screen after each part and pokes the next part's number
4 rem into $0b00 (2816). 1: setup's m-r reads (sub.sysdos im=2). 2: the
5 rem line lengths of "$", "$0", "$10". 3: which lu "name", "0:name",
6 rem "10:name" reach; scratch with "s10:", "s0:", "s:". 4: ++ copier
7 rem copies "boot 128" from the 1581 to lu 5 and compares it
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 poke 2816,0:print chr$(147);"lt. kernal dos":d=8
80 b=65188:n=2:gosub 900:print "m-r fea4:";w$
82 b=58811:n=16:gosub 900:print "m-r e5bb:";w$
84 b=42719:n=16:gosub 900:print "m-r a6df:";w$
86 q=1:gosub 950
100 for f=1 to 3:read d$:open 2,d,0,d$:get#2,a$,a$:print d$;":";:n=0
110 get#2,a$:n=n+1:if st then 130
120 if n>4 and a$="" then print n;:n=0
125 goto 110
130 print " end";n:close 2:next
140 data "$","$0","$10"
150 q=2:gosub 950
200 open 15,d,15
210 open 2,d,2,"t.lu,s,w":print#2,"current":close 2:input#15,e,e$:print "w t.lu";e;e$
220 open 2,d,2,"0:t.lu,s,w":print#2,"lu 0":close 2:input#15,e,e$:print "w 0:t.lu";e;e$
230 a$="":open 2,d,2,"10:t.lu,s,r":input#2,a$:close 2:input#15,e,e$:print "r 10:t.lu ";a$;e
240 a$="":open 2,d,2,"t.lu,s,r":input#2,a$:close 2:input#15,e,e$:print "r t.lu ";a$;e
250 a$="":open 2,d,2,"0:t.lu,s,r":input#2,a$:close 2:input#15,e,e$:print "r 0:t.lu ";a$;e
260 print#15,"s10:t.lu":input#15,e,e$,t:print "s10:t.lu";e;e$;t
270 print#15,"s0:t.lu":input#15,e,e$,t:print "s0:t.lu";e;e$;t
280 open 2,d,2,"t.lu,s,w":print#2,"x":close 2:print#15,"s:t.lu":input#15,e,e$,t:print "s:t.lu";e;e$;t
290 close 15:q=3:gosub 950
300 a$="0:++ copier":&,7,9,2:print "++ copier loaded";e%
310 open 15,d,15,"s5:boot 128":input#15,e,e$,t:print "s5:";e;e$;t
320 open 3,9,3,"0:boot 128,p,r":open 2,d,2,"5:boot 128,p,w":input#15,e,e$:print "open 5:w";e;e$
330 &,16,0:close 2:close 3:close 15:print "copied"
340 open 3,9,3,"0:boot 128,p,r":open 2,d,2,"5:boot 128,p,r":a%=9:&,16,3:close 2:close 3
350 print "compare a%";a%;"b%";b%
360 print "done":end
900 w$="":open 15,d,15,"m-r"+chr$(b-int(b/256)*256)+chr$(b/256)+chr$(n)
910 for i=1 to n:get#15,a$:a=asc(a$+chr$(0)):w$=w$+right$(hex$(a),2)+" ":next:close 15:return
950 print "--- part";q;"done"
955 if peek(2816)<q then 955
960 print chr$(147);:return
