1 rem the directory parse of setup's copy (sub.su.copy {:dir}): &,2,2,n a
2 rem line, then &,15,6 at the quotes. 11/07/2026: "i.nm/auto" came out
3 rem "i.nm/duto"; this prints each step's bytes for the i.nm lines
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53248,1:nl$=chr$(0):print chr$(147);
110 open 2,8,0,"$0":&,2,2,2:&,2,2,30
120 &,2,2,2:if a$=nl$+nl$ or st then 300
130 &,2,2,30:l$=a$:an$=mid$(a$,3,27):&,15,6,34:if an$="" then 120
140 r$=an$:&,15,6,34:n$=a$
150 if mid$(n$,1,4)<>"i.NM" then 120
160 print "raw ";:for i=3 to 16:print right$(hex$(asc(mid$(l$,i,1))),2);" ";:next:print
170 print "an$ ";:for i=1 to 9:print right$(hex$(asc(mid$(r$,i,1)+nl$)),2);" ";:next:print
180 print "n$  ";:for i=1 to len(n$):print right$(hex$(asc(mid$(n$,i,1))),2);" ";:next:print
190 goto 120
300 close 2:print "done":end
