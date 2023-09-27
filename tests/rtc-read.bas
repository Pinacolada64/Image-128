3000 rem "rtc-read.bas"
3002 rem this is example of using ds12c887 rtc from basic
3004 rem using ytm's demo program
3006 rem 2014-09-19 18:46: enhanced by pinacolada for image bbs 1.2
3008 rem 2019-05-28 12:34: and again for image bbs 1.3/2.0
3010 rem 2023-09-25 09:38: and again for image 128
3012 ba=dec("d700"):rem base address of chip (55040)
3014 c=.
3016 print "Get time/date from DS12C887 RTC:"
3018 poke ba,4 :gosub 3080:hr=d:rem hour
3020 if hr=. then print "RTC not present at $"hex$(ba)".":end
3022 poke ba,2 :gosub 3080:mi=d:rem minute
3024 poke ba,0 :gosub 3080:sc=d:rem second
3026 poke ba,6 :gosub 3080:dw=d:rem day of week (1=sun...7=sat)
3028 poke ba,7 :gosub 3080:dt=d:rem day of month
3030 poke ba,8 :gosub 3080:mo=d:rem month (1...12)
3032 poke ba,9 :gosub 3080:yr=d:rem year
3034 poke ba,50:gosub 3080:ce=d:rem century
3036 rem show what we have got
3038 a=hr:b=mo:print using "1) hr: ##";a;:printtab(20):print using "5) mo: ##";b
3040 a=mi:b=dt:print using "2) mi: ##";a;:printtab(20):print using "6) dt: ##";b
3042 a=sc:b=ce:print using "3) sc: ##";a;:printtab(20):print using "7) ce: ##";b
3044 a=dw:b=yr:print using "4) dw: ##";a;:printtab(20):print using "8) yr: ##";b
3046 print mid$("SunMonTueWedThuFriSat",dw*3-2,3)+" ";
3048 print mid$("JanFebMarAprMayJunJulAugSepOctNovDec",mo*3-2,3)+" ";
3050 d%=dt:c%=ce:y%=yr:m%=mi:s%=sc
3052 h%=hr:if h%>12 then h%=h%-12:rem convert 24-hour to 12-hour time
3054 print using "##, #### ##:##:## ";dt,ce*100+yr,h%,mi,sc;
3056 print mid$("AP",2+(hr<12),1)+"M":rem am or pm
3072 rem that's all folks
3074 end
3080 rem get value b from register, convert b (bcd) to d (dec)
3082 b=peek(ba+1):d=int(b/16)*10+(b-16*int(b/16))
3084 c=c+1:print using "#) in: bcd=##, out: dec=##";c,b,d
3086 return
4000 f$="read ds rtc":scratch(f$),u8:dsave(f$),onu8
