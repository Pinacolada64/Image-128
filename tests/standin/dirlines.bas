1 rem the line lengths of a directory listing on device 9 (a cmd hd): its
2 rem partition directory ("$=p") and partition 3's ("$3"): for each line,
3 rem the bytes up to and with its ending 0. are they all the same, so
4 rem &,2,lfn,n can read a line at once? 11/06/2026
10 for f=1 to 2:d$="$=p":if f=2 then d$="$3"
20 open 2,9,0,d$:get#2,a$,a$:print d$;":";
30 n=0
40 get#2,a$:n=n+1:if st then 70
50 if n>4 and a$="" then print n;:goto 30
60 goto 40
70 print " end";n:close 2:next
80 print "done"
