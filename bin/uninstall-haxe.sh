if [ ! -n "$HAXEPATH" ]
then
	# use default path if $HAXEPATH isn't defined
	HAXEPATH="/usr/bin"
fi

echo Renaming compiler back to haxe, overwriting new haxe executable
mv $HAXEPATH/haxec $HAXEPATH/haxe
exit 0
