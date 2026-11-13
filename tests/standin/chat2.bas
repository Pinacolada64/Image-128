1 rem ++ chatmode between two stations (ports 0 and 1 of the lt. kernal):
2 rem run on both x128s by tools/ltk_chat2.py, which types the lines.
3 rem the station's port picks the handle: 0 alice, 1 bob. each goes
4 rem online, lists the others, enters the chat room, and when it has
5 rem left, shows the transcript and goes offline
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 print chr$(147);"++ chatmode, two stations":p=7171
80 a$="0:++ chatmode":&,7,9,2
90 a$="?":&,16,4,1:q=peek(p+2):h$="alice":if q then h$="bob"
100 a$=h$:&,16,4,1:print "port";q;"as ";h$;", status";peek(p)
110 print "online:":&,16,2
120 a$=h$:&,16,3:c=peek(p)
130 print "transcript:":&,16
140 a$=h$:&,16,4,0
150 print "done";c;peek(p)
