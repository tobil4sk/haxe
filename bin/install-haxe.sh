if [ ! -n "$HAXEPATH" ]
then
	# use default path if $HAXEPATH isn't defined
	HAXEPATH="/usr/bin"
fi

if [ "$1" = update ]
then
	echo Updating haxe executable in $HAXEPATH
else
	# Meant to be run only after a standard haxe installation
	echo Renaming haxe executable to haxec
	mv $HAXEPATH/haxe $HAXEPATH/haxec
	echo Copying new haxe executable into $HAXEPATH
fi

cp ./haxe $HAXEPATH
exit 0
