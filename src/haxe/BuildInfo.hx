package haxe;

import haxe.io.Path;

import haxe.Args;

typedef BuildInfo = {
	buildDir:String,
	haxecPath:String,
	builds:Array<BuildCall>
}

function generateBuildInfo(dir:String, args:Args):BuildInfo {
	// work out build directory
	final buildDir = getBuildDirectory(dir, args.specialArgs.get("cwd"));

	// get the absolute path for the override path, if specified.
	final overridePath = getLockFilePath(args.specialArgs.get("lock-file"), buildDir);

	// start library resolver
	final resolver = new Resolver(buildDir, overridePath);

	final haxecPath = "haxec";

	final individualCalls = generateBuildCalls(args.mainArgs, resolver);

	return {
		buildDir : buildDir,
		builds : individualCalls,
		haxecPath : haxecPath
	};
}

private function getBuildDirectory(dir:String, cwdArg:Null<String>):String {
	if (cwdArg == null)
		return dir;

	if (Path.isAbsolute(cwdArg))
		return cwdArg;

	return Path.join([dir, cwdArg]);
}

private function getLockFilePath(overridePath:Null<String>, buildDir:String):String {
	if (overridePath == null || Path.isAbsolute(overridePath))
		return overridePath;

	return Path.join([buildDir, overridePath]);
}


private function generateBuildCalls(args:haxe.iterators.ArrayIterator<ArgType>, resolver:Resolver):Array<BuildCall> {
	// separate arrays of arguments for individual calls, if --each and --next are used
	final individualCalls:Array<BuildCall> = [];

	// arguments for every call
	var eachCall:BuildCall = BuildCall.createEmpty();
	// current call, a "buffer" whose contents can be moved to each or individual calls
	var currentCall:BuildCall = BuildCall.createEmpty();

	function next() {
		final newCall = BuildCall.combine(eachCall, currentCall);
		individualCalls.push(newCall);
		currentCall.reset();
	}

	final map = [
		SingleArg("each") => function(){
			eachCall = currentCall.copy();
			currentCall.reset();
		},
		SingleArg("next") => next,
		SingleArg("help") => function(){
			currentCall.help = true;
		},
		SingleArg("version") => function() {
			currentCall.version = true;
		}
	];

	for (arg in args) {
		switch (arg) {
			case arg if (map.exists(arg)):
				map[arg]();
				trace(arg);
			case PairArg("library", name):
				final libPath = resolver.libPath(name);


			// resolve library
			case Rest(arg):
				currentCall.args.push(arg);
			default:
				throw "Error working through arguments...";
		}
	}

	next();

	return individualCalls;
}
