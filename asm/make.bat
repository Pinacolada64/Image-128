set C64LIST="..\C64List.exe"
%C64LIST% "boot.asm" -prg -ovr -verbose
%C64LIST% "boot.prg" -d64:test.d64::@BOOT -verbose

%C64LIST% "ml 128 1_0.lbl" -prg -ovr -verbose
%C64LIST% "ml 128 1_0.prg" -d64:test.d64::"@ML 128 1.0" -verbose
