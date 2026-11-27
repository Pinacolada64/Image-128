1 rem i.LB's menu lines: the grid's labels read from bartbl (3330), page
2 rem 4's options from its table (38xx) by &,66,1 (3398), keys to options
3 rem (3392-3394, page 1: 12) and a toggle (3396). 40 columns
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,40
6 &chr$(147)
7 a$="0:e.lightbar":&,7,8,8
8 open 2,8,2,"0:e.lightdefs,s,r"
9 for x=0 to 7:&,2,2:for i=1 to 16:&,52,x*16+i-1,val(mid$(a$,i,1)):next:next:close 2
10 gosub 100:lb$="":for l=0 to 31:gosub 3330:lb$=lb$+" "+c$+" ":next
12 for i=0 to 3:a$=mid$(lb$,i*40+1,40):&chr$(18)+chr$(92)+"$a":next:&chr$(146)
20 p=4:m=16+4*(p=1):for n=1 to m:gosub 3398:l=int(k/2):gosub 3330
22 c$=c$+mid$("-L-R",(k and 1)*2+1,2):b$=mid$(o$,n,1):&"  "+chr$(92)+"$b. "+chr$(92)+"$c "+chr$(92)+"$a"+chr$(13):next
30 p=1:m=16+4*(p=1):r$="keys:":for x=1 to 8:read y:an$=chr$(y):gosub 3392:r$=r$+str$(n):next:&r$+chr$(13)
32 data 49,54,57,193,195,196,58,48
40 an$="1":gosub 3392:&,52,0,3:t0=a%:gosub 3398:if s=0 then:&,52,k,2
42 &,52,0,3:t1=a%:&,52,k,2
44 an$="6":gosub 3392:&,52,9,3:t2=a%:gosub 3398:if s=0 then:&,52,k,2
46 &,52,9,3:t3=a%:&"1:"+str$(t0)+str$(t1)+"  6: s"+str$(s)+str$(t2)+str$(t3)+chr$(13)
48 &"done"+chr$(13)
50 goto 50
100 o$="123456789"+chr$(193)+chr$(194)+chr$(195)+chr$(196)+chr$(197)+chr$(198)+chr$(199):return
3330 c$="":for j=0 to 2:c=peek(4880+l*3+j)and 127:if c<32 then c=c+64:goto 3334
3332 if c>63 then c=c+64-64*(c<96)
3334 c$=c$+chr$(c):next:return
3392 n=asc(an$)-48:if n>9 then n=n+58-asc(chr$(193))
3394 if n<1 or n>m then n=0
3395 return
3398 s=0:a%=3400+100*p+n:&,66,1:return
3501 k=0:a$="SysOp In/Out":return
3506 k=9:s=1:a$="Disable Modem":return
3801 k=48:a$="Emulate Image 1.3 Mode":return
3802 k=49:a$="40-Col Mask Shows P= V=":return
3803 k=50:a$="Disable 2nd Security Check":return
3804 k=51:a$="Logoff Lotto Menu Enabled":return
3805 k=52:a$="Super CPU Configured":return
3806 k=53:s=1:a$="Turbo Mode (System)":return
3807 k=54:a$="Alternate Last 10 at Idle":return
3808 k=55:a$="Alternate Idle Screen":return
3809 k=56:a$="Disable T/S Mode":return
3810 k=57:a$="Border Color on Event":return
3811 k=58:s=1:a$="Invert DCD (System Use)":return
3812 k=59:s=1:a$="Carrier Present (System Use)":return
3813 k=60:a$="Use DCD/DSR":return
3814 k=61:a$="Enable Rx/Tx Windows":return
3815 k=62:s=1:a$="CPU at 2 MHz (System)":return
3816 k=63:a$="(Not Used)":return
