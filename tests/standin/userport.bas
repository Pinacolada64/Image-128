1 rem user port driver: load ml.rs232 and install the user port driver as im does
2 rem (&,16,0), set 1200 baud (rsbaud), then show and echo back whatever arrives
3 rem on device 2. needs x128 -userportdevice 2 -rsuserdev 0 -rsuserbaud 1200 -rsdev1 <host:port>
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
6 &chr$(147)
10 a$="0:ml.rs232":&,7,8,2:&,16,0
12 open 131,2,134,chr$(6):sys 6433,2
14 &"user port test: what arrives is shown and echoed back"+chr$(13)
16 print#131,"hello from image 128"+chr$(13);
20 get#131,a$:if a$="" then 20
22 print#131,a$;:&""+a$
24 goto 20
