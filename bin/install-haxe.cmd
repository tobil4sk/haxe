@echo off
if "%1" == "update" (
	echo Updating haxe executable in %HAXEPATH%
) else (
	REM Meant to be run only after a standard haxe installation
	echo Renaming haxe.exe executable to haxec.exe
	move %HAXEPATH%\haxe.exe %HAXEPATH%\haxec.exe
	echo Copying new haxe.exe executable into %HAXEPATH%
)
copy .\haxe.exe %HAXEPATH%
