if [ $1 != "update" ]
then
	# if it is a first time installation or after a haxe update, rename the haxe compiler to haxec
	mv $HAXEPATH/haxe $HAXEPATH/haxec
fi

# copy the new haxe executable into the haxe path
cp ./haxe $HAXEPATH/