1 rem ++ chatmode (asm/chatmode.asm) on a lt. kernal: run by
2 rem tools/ltk_chatmode.py, the stand-in on a 1581 at device 9, the lt.
3 rem kernal at 8 (vice's emulation, its config set to boot 128 mode).
4 rem one station (local mode: the keyboard is the user's): alice goes
5 rem online, nobody else is; in the chat room the script types hello and
6 rem /x; the transcript then has her joining, her line, and leaving
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 print chr$(147);"++ chatmode":p=7171:f=0
80 a$="0:++ chatmode":&,7,9,2
90 a$="alice":&,16,4,1:a=peek(p):print "online";a;"port";peek(p+2)
100 &,16,2:b=peek(p):print "status";b;"others";peek(p+3)
110 a$="alice":&,16,3:c=peek(p):print "chat";c
120 print "transcript:":&,16:d=peek(p):e=peek(p+1):print "replay";d;e
130 a$="alice":&,16,4,0:g=peek(p)
140 if a or b or c or d or g or e<1 then f=1
170 if f=0 then print "all passed":end
180 print "failed";a;b;c;d;e;g:end
