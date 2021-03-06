if not "%1"	 == "update" (
	REM if it is a first time installation or after a haxe update, rename the haxe compiler to haxec
	move %HAXEPATH%\haxe.exe %HAXEPATH%\haxec.exe
)
REM copy the new haxe executable into the haxe path
copy .\haxe.exe %HAXEPATH%