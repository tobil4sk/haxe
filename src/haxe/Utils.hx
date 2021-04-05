package haxe;

function joinUnlessAbsolute(absolute:String, path:String) {
	if (haxe.io.Path.isAbsolute(path))
		return path;
	return haxe.io.Path.join([absolute, path]);
}
