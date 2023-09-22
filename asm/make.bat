set C64LIST=..\C64List4_04.exe
set OUTPUT_PREFIX=ml 128 1_0.
:: %C64LIST% "boot.asm" -prg -ovr -verbose
:: %C64LIST% "boot.prg" -d64:test.d64::@BOOT -verbose

:: *.bin files are given load addresses higher than the program counter so they can
:: be swapped from under ROM to main memory and execute in the swapped-to address space

:: each of these files should include {uses:equates.asm},
:: there is no command-line switch to include symbols
for %%f in (rs232_user rs232_swift rs232 wedge intro editor gc ecs struct swap1 swap2 swap3) do %C64LIST% %%f.asm -bin:%%f.bin -ovr

   %C64LIST% ml.asm -prg:"%OUTPUT_PREFIX%prg"
:: %C64LIST% %OUTPUT_PREFIX.prg -d64:test.d64::"@ML 128 1.0" -verbose
