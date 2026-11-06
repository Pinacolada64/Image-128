1 rem the bus scan's time, a device at a time: sub.sysdos im=2's checks
2 rem (lines 60020-60050 copied here), with the jiffy clock printed after
3 rem each device. drive 8 is the 1581, the rest absent
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 56328,0
20 print chr$(147);"scan times (jiffies)"
30 close 15:t0=ti:for d=8 to 30:t=ti:open 15,d,15:close 15:if st and 128 then 60
40 b=65188:n=2:gosub 100:c$=w$:print d;"id ";c$;ti-t;:b=58811:n=16:gosub 100:print "e5bb";ti-t;
50 b=42719:gosub 100:print "a6df";ti-t
60 if d<14 then print d;"done";ti-t;st
70 next:print "total";ti-t0:print "all passed":end
100 w$="":open 15,d,15,"m-r"+chr$(b-int(b/256)*256)+chr$(b/256)+chr$(n)
110 for i=1 to n:get#15,a$:w$=w$+chr$(asc(a$+chr$(0))):next:close 15:return
