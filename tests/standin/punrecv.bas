1 rem ++ punter, the receiving side (punsend.bas sends): tools/punterpair.py
2 rem runs both. receives t.prcv1 (punter), t.prcv2 (relaxed) and t.prcv3
3 rem (image 1.3 punter); the script compares them with what was sent.
4 rem prints a%, b%, rc, filetyp for each; "done"
5 rem it waits 10 seconds before each next transfer: the sender is still ending one
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
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
65 poke 56328,0:rem start the tod clock as im does
70 print chr$(147);"punter receive":dv%=8:poke 6362,0
80 a$="0:ml.rs232":&,7,8,2:&,16,1:open 131,2,134,chr$(6):&,41,6
90 open 15,8,15,"s0:t.prcv1,t.prcv2,t.prcv3":close 15
100 print "waiting for carrier"
110 if (peek(6352)and128)=0 then 110
120 print "carrier":a$="0:++ punter":&,7,8,2:gosub 950
130 &,16,4,0:open 2,8,2,"0:t.prcv1,s,w":&,16,1:close 2:t$="1 punter":gosub 900
140 sleep 10:&,16,4,1:open 2,8,2,"0:t.prcv2,s,w":&,16,1:close 2:t$="2 relaxed":gosub 900
150 sleep 10:&,16,4,2:open 2,8,2,"0:t.prcv3,s,w":&,16,1:close 2:t$="3 image 1.3":gosub 900
180 print chr$(147);:for k=1 to rr:print r$(k):next:print "done":end
900 rr=rr+1:r$(rr)=t$+":"+str$(a%)+str$(b%)+str$(rc)+str$(peek(6362)):return
950 rem the clock (row 14) and counters (row 15) as sub.display draws them
955 print chr$(19);:for k=1 to 14:print:next:print "                00:00:00"
960 print " Good: 00000  Bad: 00000  Bytes: 000000";:return
