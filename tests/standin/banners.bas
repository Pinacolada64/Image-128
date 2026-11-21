1 rem i/lo.on's three reversed banners (4108, 4140, 4156), built by its
2 rem 4090/4092 (copied here): a bar from column 1 to ll%-2, the text
3 rem centered, with \_nn (pad to column nn) for both sides. ll% 40, then
4 rem 80 in 80 columns (the \vj separators left out). tools/banners.py checks.
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 dim c$,b$,t$,an$,w,ll%
30 print chr$(147);:for w=0 to 1:ll%=40+40*w:if ll%>rwindow(2) then 90
40 an$="Ryan":b$="Good Afternoon, "+an$+"!":gosub 4090:&" {cyn}"+c$+"{f6}"
50 b$="Xpress Login Active!":gosub 4090:&" {yel}"+c$+"{f6}"
60 b$="New User":t$=b$:b$="Welcome, "+t$+"!":gosub 4090:b$=t$:&" {lred}"+c$+"{f6}"
70 &"b$ kept: \$b{f6}"
90 next:print "done":end
4090 c$="{rvon}\_"+right$("0"+mid$(str$(int((ll%-len(b$))/2)),2),2)+b$
4092 c$=c$+"\_"+right$("0"+mid$(str$(ll%-1),2),2)+"{rvof}":return
