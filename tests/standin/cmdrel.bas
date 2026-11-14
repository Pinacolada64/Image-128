1 rem cmd into a rel record (as i.sb 3446-3452 writes a post): does it reach the file?
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53248,1:r$=chr$(13)
110 open 15,8,15,"s0:cmdrel":close 15
120 open 15,8,15:open 2,8,2,"0:cmdrel,l,"+chr$(81)
130 x=2:gosub 900:cmd 2,;:print "text line one";r$;"text line two";r$;
140 x=1:gosub 900:print#2,"4";r$;"3";r$;"0"
150 x=2:gosub 900:input#2,a$,b$:print "rec 2: [";a$;"] [";b$;"]"
160 x=1:gosub 900:input#2,a$:print "rec 1: [";a$;"]"
170 close 2:close 15:print "done":end
900 print#15,"p"chr$(98)chr$(x and 255)chr$(x/256)chr$(1):return
