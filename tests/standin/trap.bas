1 rem image's error trap (&,37 on, &,38 off) against basic 7.0's trap and
2 rem resume, and whether basic's er and el agree with what image's trap
3 rem saves: the error in peek(6) (.a), its line in peek(7)+256*peek(8)
4 rem (.x .y). see programming.md
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 print "1) basic's trap, image's off":&,38:trap 500
12 x=1/0:print "   resumed after the error":trap
20 print "2) both on":&,37:trap 600
22 x=1/0
30 print "   not reached":end
500 print "   basic's trap: er"er"el"el:print "   image's saved:"peek(6)peek(7)+256*peek(8):resume next
600 print "   basic's trap won":end
2000 e=peek(6):l=peek(7)+256*peek(8):print "   image's trap won: er"er"el"el:print "   image's saved:"e;l
2010 if er=e and el=l then print "   er, el match":end
2020 print "   er, el differ":end
