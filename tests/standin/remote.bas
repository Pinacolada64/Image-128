1 rem ++ remote (asm/remote.asm): loaded with &,7; &,16 runs the basic
2 rem program a$ (drive dv%) and comes back to the statement after it.
3 rem guest: for/gosub, data, string garbage, input (the script types
4 rem bob), a file left open. im's for, gosub, data, strings, arrays and
5 rem file 15 have to be as they were. guest2: clr, then 1/0 (2, error 20
6 rem in 20). a missing file (3, 1). guest3 with no carrier, local off (1)
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
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 print chr$(147);"++ remote":dv%=8:f=0:p=7171
80 open 15,8,15,"s0:t.gfile":z$="im"+"str":dim q(5):q(2)=42:restore
90 a$="0:++ remote":&,7,8,2
100 gosub 500
110 t$="guest"+str$(peek(p))+str$(peek(p+1)):ok=peek(p)=0:gosub 900
120 t$="im kept "+z$+str$(q(2))+str$(lv):ok=z$="imstr" and q(2)=42 and lv=4:gosub 900
130 read e$:t$="im data "+e$:ok=e$="imdata":gosub 900
140 open 2,8,2,"0:t.gfile,s,r":input#2,e$:close 2:input#15,e,e1$
145 t$="guest's file "+e$+str$(e):ok=e$="bob" and e=0:gosub 900
150 a$="0:guest2":&,16:e=peek(p+2)+256*peek(p+3)
155 t$="guest2"+str$(peek(p))+str$(peek(p+1))+str$(e):ok=peek(p)=2 and peek(p+1)=20 and e=20:gosub 900
160 input#15,e,e1$:t$="file 15 after its clr"+str$(e):ok=e=0:gosub 900
170 a$="0:nosuch":&,16:t$="missing"+str$(peek(p))+str$(peek(p+1)):ok=peek(p)=3 and peek(p+1)=1:gosub 900
180 poke 53248,0:a$="0:guest3":&,16:poke 53248,1:t$="no carrier"+str$(peek(p)):ok=peek(p)=1:gosub 900
190 goto 800
500for lv=1 to 3:if lv=2 then a$="0:guest":&,16
510 next:return
800 print:if f=0 then print "all passed":end
810 print f;"failed":end
900 if ok then print "pass ";t$:return
910 print "fail ";t$:f=f+1:return
950 data imdata
