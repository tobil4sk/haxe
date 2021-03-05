cd %HAXEPATH%
del haxe.exe
rename haxec.exe haxe.exe
REG delete HKCU\Environment /F /V HAXEC_PATH