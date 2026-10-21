1 rem scroll and wrap: 30 lines scroll the console, then a 97-character line wraps
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
6 &chr$(147)
10 for i=1 to 30:&"line"+str$(i)+" of the scroll test"+chr$(13):next
20 &"long: 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 end"+chr$(13)
30 goto 30
