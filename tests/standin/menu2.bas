1 rem ++ menu2 (the cursor menu): loaded as im loads it (&,7), four items added
2 rem with &,16,0 and drawn with &,16,2 as i.im does; cursor down and return
3 rem choose the second: a% is 1. im's variables first, in its order: the
4 rem ml finds a% and b% by their place
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
70 a$="0:++ menu2":&,7,8,2
80 n=4:dim m%(16,n)
90 &,16,0,34,m%(0,1),"a","","first item"
100 &,16,0,34,m%(0,2),"b","","second item"
110 &,16,0,34,m%(0,3),"c","","third item"
120 &,16,0,34,m%(0,4),"d","","fourth item"
130 print chr$(147);"menu test"
140 &,16,2,34,m%(0,1),n,17,2,n/2+.5,2,6,0:print:print:print "chose";a%
150 if a%=1 then print "all passed":end
160 print "failed":end
