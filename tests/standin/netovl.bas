1 rem ++ path, ++ netsub, ++ netlist and ++ net, the network overlays, each
2 rem loaded as im loads them (&,7) and run with &,16 as the nm modules do.
3 rem prints pass or fail for each check, then "all passed" or the count
4 rem of failures. im's variables first, in its order: the ml finds a$,
5 rem an$, a%, b%, qe, rc and dv% by their place
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
70 print chr$(147);"network overlays":dv%=8:f=0
100 rem ++ path: a 3-node list, aaa-bbb-ccc, as a prg (count, 8 bytes a node)
110 open 2,8,2,"@0:t.nodes,p,w"
120 print#2,chr$(0);chr$(0);chr$(3);
130 print#2,"aaa";chr$(0);chr$(2);chr$(0);chr$(0);chr$(0);
140 print#2,"bbb";chr$(0);chr$(1);chr$(3);chr$(0);chr$(0);
150 print#2,"ccc";chr$(0);chr$(2);chr$(0);chr$(0);chr$(0);:close 2
160 a$="0:++ path":&,7,8,2
170 a$="0:t.nodes":a%=0:&,16:t$="path load":ok=a%=3:gosub 900
180 a$="ccc":a%=0:&,16,2:t$="path node":ok=a%=3:gosub 900
190 a$="aaa":b$="ccc":a%=0:b%=0:&,16,1:x$=an$
195 rem the path ends with "/" too (srch08 writes it before it checks for the end)
200 t$="path aaa-ccc "+x$:ok=x$="/aaa/bbb/ccc/":gosub 900
210 a$="zzz":a%=0:&,16,2:t$="path no node":ok=a%=0:gosub 900
300 rem ++ netsub: two tables of names and numbers
310 a$="0:++ netsub":&,7,8,2
320 a%=0:&,16,255:t$="netsub version":ok=a%=10:gosub 900
330 &,16,6:a$="aaa":qe=5:&,16,1:a$="bbb":qe=7.5:&,16,1
340 a$="aaa":rc=9:qe=0:&,16:t$="netsub get":ok=rc=0 and qe=5:gosub 900
350 &,16,7:a$="bbb":rc=0:qe=0:&,16:t$="netsub copy":ok=rc=7.5 and qe=7.5:gosub 900
360 &,16,5,0:x$=an$:t$="netsub rec 0 "+x$:ok=x$="aaa" and qe=5:gosub 900
370 a$="0:t.netsub":&,16,3,dv%:&,16,6:&,16,5,0:t$="netsub clear":ok=qe=-1:gosub 900
380 a$="0:t.netsub":&,16,2,dv%:&,16,5,1:x$=an$
390 t$="netsub load "+x$:ok=x$="bbb" and qe=7.5:gosub 900
400 a$="aaa":&,16,4:t$="netsub delete":ok=qe=5:gosub 900
410 &,16,5,0:x$=an$:t$="netsub moved up "+x$:ok=x$="bbb":gosub 900
500 rem ++ netlist: a name, a list and a%(1)-a%(60)
510 dim a%(60):a$="0:++ netlist":&,7,8,2
520 a%=0:&,16,255:t$="netlist version":ok=a%=9:gosub 900
530 a$="my bbs":an$="abc":a%(1)=100:a%(30)=-5:a%(59)=1234:&,16,1
540 a$="0:t.netlist":&,16,3,dv%
550 a$="":an$="":for i=0 to 60:a%(i)=0:next
560 a$="0:t.netlist":&,16,2,dv%:&,16:x$=a$:y$=an$
570 t$="netlist name "+x$:ok=x$="my bbs":gosub 900
580 t$="netlist list":ok=y$="abc"+left$("------------------------------------------------",45):gosub 900
590 t$="netlist a%()":ok=a%(1)=100 and a%(30)=-5 and a%(59)=1234:gosub 900
600 rem ++ net: loads; &,16,6 (the modem chat) with no carrier returns, rc 1:
605 rem image's "minusone" (&,32) is $81,0,0,0,0, +1, on the c64 too
610 a$="0:++ net":&,7,8,2
620 a$="":b$="x":rc=0:&,16,6,10:t$="net chat rc="+str$(rc)+" b$="+b$:ok=b$="" and rc=1:gosub 900
800 print:if f=0 then print "all passed":end
810 print f;"failed":end
900 if ok then print "pass ";t$:return
910 print "fail ";t$:f=f+1:return
