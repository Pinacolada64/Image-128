1 rem a rel file grown (status 50 record not present left in channel 15), then record#2,x,1 and the status (im 1/10 and 5, as sb-post 4076): the old 50, or 0?
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
110 open 15,8,15,"s0:recstat":close 15
120 open 15,8,15:open 2,8,2,"0:recstat,l,"+chr$(81)
130 x=3:gosub 900:print#2,"line 1";r$;"line 2";r$;"^"
140 x=1:gosub 900:print#2,"4"
150 x=6:gosub 950:print#2,"grown"
160 x=3:gosub 900:input#15,e%,e$,t%,s%:print "record:";e%;e$
170 x=6:gosub 950:print#2,"grown again"
180 x=3:gosub 950:input#15,e%,e$,t%,s%:print "p:";e%;e$
190 close 2:close 15:print "done":end
900 record#2,x,1:return
950 print#15,"p"chr$(98)chr$(x and 255)chr$(x/256)chr$(1):return
