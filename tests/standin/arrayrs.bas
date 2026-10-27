1 rem &,28 (put the array pointers back) as im's line 304 runs it: it drops
2 rem the variables and arrays made since &,27, among them line 306's string
3 rem arrays bb$(), dt$(), ed$(), nn$(), and moves the arrays saved before
4 rem (tt$() ... co$() ...) down. the strings of everything kept have to
5 rem link to their new places, and the dropped arrays' strings have to be
6 rem garbage, or fre(1) writes through stale links. 20 rounds; co$() and
7 rem tt$(1) checked after each. tools/strcheck.py --port 6537 at the end.
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
40 dim tt$(254),dv%(36),dr%(36),co$(9),hs$(10),bf(6),st(38),im$(5),pf$(10)
50 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
60 print chr$(147);"arrayrs":f=0:for i=1 to 9:co$(i)="computer"+str$(i):next:tt$(1)="kept"+""
70 k=0:i=0:x=0:&,27,1
80 for k=1 to 20:print k;
90 &,28,1:dim bb$(31),dt$(61),ed$(61),nn$(61):dim a%(61),c%(61),d%(61),e%(31),f%(61),ac%(31),so%(31)
100 bb$(1)="bb"+str$(k):nn$(5)="nn"+str$(k):w1=1:w2=2:w3=3:w4=4:x=fre(1)
110 for i=1 to 9:if co$(i)<>"computer"+str$(i) then f=f+1:print "round";k;": co$(";i;")=";co$(i):k=20:i=9
120 next:if tt$(1)<>"kept" then f=f+1:print "round";k;": tt$(1)=";tt$(1):k=20
130 next
140 if f=0 then print "all 20 rounds passed: run strcheck":end
150 print "failed";f:end
