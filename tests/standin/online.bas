1 rem i/lo-online's time connected (copies of its 4500-4540, 4520 printing
2 rem what it got and what it should): lt$ and ls as at connect, the TOD
3 rem clock set to "now" (hours first, tenths last; writing hour 12 flips
4 rem the CIA's PM bit, so 146, $92, makes 12 AM). Prints "done"
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,80
6 &chr$(147)
10 read l$,v,hh,mm,ss,w$:if l$="end" then 90
12 lt$=l$:ls=v:poke 56331,hh:poke 56330,mm:poke 56329,ss:poke 56328,0
14 gosub 4500:goto 10
90 &"done"+chr$(13)
92 goto 92
100 data "52611271158",48,129,5,9,"1 hour, 6 minutes and 39 seconds"
102 data "52611279158",0,146,1,5,"3 minutes and 5 seconds"
104 data "52611279259",69,129,1,0,"1 minute and 15 seconds"
106 data "52611270930",5,9,48,7,"2 seconds"
108 data "end",0,0,0,0,""
4500 f1=1:if len(lt$)<11 then return
4502 x=val(mid$(lt$,8,2)):p=-(x>79):h=x-80*p:m=val(mid$(lt$,10,2)):s=(ls and 15)+10*int(ls/16):gosub 4530:t=c
4504 x=peek(56331):m=peek(56330):s=peek(56329):a=peek(56328)
4506 p=-((x and 128)>0):x=x and 31:h=(x and 15)+10*int(x/16):m=(m and 15)+10*int(m/16):s=(s and 15)+10*int(s/16):gosub 4530
4508 c=c-t:if c<0 then c=c+86400
4510 h=int(c/3600):m=int(c/60)-h*60:s=c-int(c/60)*60
4512 n=s:b$="second":gosub 4540:a$=x$:if h+m=0 then 4520
4514 n=m:b$="minute":gosub 4540:a$=x$+" and "+a$:if h=0 then 4520
4516 n=h:b$="hour":gosub 4540:a$=x$+", "+a$
4520 &a$+" | "+w$+mid$(" *",1-(a$<>w$),1)+chr$(13):return
4530 h=h+12*(h=12)+12*p:c=h*3600+m*60+s:return
4540 x$=mid$(str$(n),2)+" "+b$+left$("s",-(n<>1)):return
