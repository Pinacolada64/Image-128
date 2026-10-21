1 rem swiftlink driver: load ml.rs232 and install the swiftlink driver as im does
2 rem (&,16,1), then show and echo back whatever arrives on device 2. needs
3 rem x128 -acia1 -acia1base 0xde00 -acia1irq 1 -acia1mode 1 -myaciadev 0 -rsdev1 <host:port>
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
6 &chr$(147)
10 a$="0:ml.rs232":&,7,8,2:&,16,1
12 open 131,2,134,chr$(6)
14 &"swiftlink test: what arrives is shown and echoed back"+chr$(13)
16 print#131,"hello from image 128"+chr$(13);
20 get#131,a$:if a$="" then 20
22 print#131,a$;:&""+a$
24 goto 20
