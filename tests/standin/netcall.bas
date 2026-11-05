1 rem netmail exchange, the caller's side (netans.bas answers): i.nm_auto's
2 rem steps (3204-3274) with ++ net over the swiftlink: send 1 until the
3 rem answer's 2, then for each file its name block (&,16,2) and the file
4 rem (&,16,0). tools/netpair.py runs both, joined by tools/nullmodem.py.
5 rem prints pass or fail for each step, then "caller all passed"
10 dima$,a%,ac%,am,ag$,ak$,am$,an$,ao%
11 dimb$,b%,bd,bd$,bn$,bu
12 dimc$,c%,c1$,c2$,c3$,ca,cc,cc$,cd%,ch$,cm$,cn,co$,co%,cr,ct,ct%
13 dimd$,d%,d1$,d1%,d2$,d2%,d3%,d3$,d4$,d5$,d6$,da%,db%,dc,dc%,dd$,df%,dr,dr$,dv%
14 dime$,e%,e1,em,ef$,ep$,ec,ec%
15 dimf$,f%,f1,f2,f3,f4,ff$,fl,fl$,f1$,f2$,f3$,f4$,f5$,f6$,f7$,f8$
16 dimg$,g%
17 dimh$,h%,hx$
18 dimi$,i%,id,im$,im,in$,is
19 dimj$,j%
20 dimk$,k%,kk,kp%
21 diml$,l%,l1,l1$,l2,l2$,l3,l3$,lc,ld$,le,lf,lk%,ll$,ll%,lm$,lp,lt$,lt%,lw,lz$
22 dimm$,m%,mc,mf,ml$,mp$,mt$,mw,mp%,mn%
23 dimn$,n%,na$,nc,nf,nl,nl$,nm,nm$
24 dimo$,o%
25 dimp$,p%,p1%,p2%,p3%,pf,ph$,pl,pm,po$,pp$,pr,pr$,ps,pu$,pw$,p1$,p2$
26 dimq$,q%,qb,qe,qt$
27 dimr$,r%,rc,rn$,rp,rq
28 dims$,s%,sa%,sh,sg,sw
29 dimt$,t%,t1,tc%,tf,tk$,tr%,tt,tt$,tz$
30 dimu$,u%,uc,uh,ul,ur,uf$,uu$
31 dimv$,v%
32 dimw$,w%
33 dimx$,x%
34 dimy$,y%
35 dimz$,z%,zz
40 dim nm$(2):nm$(1)="t.small":nm$(2)="t.big"
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
65 poke 56328,0:rem start the tod clock as im does: tenwait counts its tenths
70 print chr$(147);"netmail caller":dv%=8:f=0
80 a$="0:ml.rs232":&,7,8,2:&,16,1:open 131,2,134,chr$(6):&,41,6
90 gosub 700
100 print "waiting for carrier"
110 if (peek(6352)and128)=0 then 110
120 print "carrier":a$="0:++ net":&,7,8,2
130 t=650
140 print#131,chr$(1);
150 t=t-1:if t<0 then print "fail no answer":f=f+1:goto 800
160 &,4:b=peek(6)and127:if b=2 then 200
170 if t/30=int(t/30) then 140
180 goto 150
200 print "answered"
210 for i=1 to 2:n$=nm$(i)
220 b$="bbb/aaa/r/"+n$:&,16,2:t$="name "+n$:ok=peek(512)=0:gosub 900
230 open 2,8,2,"0:"+n$+",s,r":&,16,0:close 2:x=b%
240 t$="send "+n$+","+str$(x)+" blocks":ok=peek(512)=0:gosub 900
250 next
260 goto 800
700 rem the files: t.small, two lines; t.big, 1500 bytes of every value
710 open 15,8,15,"s0:t.small,t.big":close 15:open 2,8,2,"0:t.small,s,w":print#2,"hello from aaa";chr$(13);"second line";chr$(13);:close 2
720 print "writing t.big":open 2,8,2,"0:t.big,s,w"
730 for k=0 to 1499:print#2,chr$((k*7+3)and255);:next:close 2:return
800 print:if f=0 then print "caller all passed":end
810 print f;"caller failed":end
900 if ok then print "pass ";t$:return
910 print "fail ";t$:f=f+1:return
