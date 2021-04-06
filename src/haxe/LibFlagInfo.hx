package haxe;

/** Information that can be passed in through -lib **/
typedef LibFlagInfo = {
	var name:String;
	var ?version:String;
	var ?url:String;
	var ?ref:String;
}

private class LibParsingError extends Error {}

/** Extract library info from string passed using -lib **/
function extract(libInfo:String):LibFlagInfo {
	var splitInfo = libInfo.split(":");

	if (splitInfo.length > 2) {
		if (!Resolver.isVCS(splitInfo[1]))
			throw new LibParsingError('\'${libInfo}\' is invalid: repository only allowed with version \'git\' or \'hg\'');

		// rejoin the last ones
		final last = splitInfo.splice(2, splitInfo.length - 2).join(":").split("#");
		for (item in last)
			splitInfo.push(item);
	}

	final fields = ["version", "url", "ref"];

	final extracted = {
		name: splitInfo.shift()
	};
	for (i in 0...splitInfo.length) {
		if (splitInfo[i] == "")
			throw new LibParsingError('library flag \'${libInfo}\' has a misplaced \':\'');

		Reflect.setField(extracted, fields[i], splitInfo[i]);
	}
	return extracted;
}
