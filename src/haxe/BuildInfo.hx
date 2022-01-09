package haxe;

import haxe.Args;

typedef BuildInfo = {
	haxecPath:String,
	builds:Array<BuildCall>
}

/**
	Generate information for building in `dir` with `args`
**/
function generateBuildInfo(dir:String, args:Args):BuildInfo {
	// get the absolute path for the override path, if specified.
	final overridePath = args.specialArgs.get("lock-file");

	// start library resolver
	final resolver = Resolver.create(overridePath);

	final haxecPath = "haxec";

	final individualCalls = generateBuildCalls(args.mainArgs, resolver);

	return {
		builds : individualCalls,
		haxecPath : haxecPath
	};
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
			case PairArg("library", flag):

				final libInfo = LibFlagInfo.extract(flag);

				//final libArgs = resolver.getArgsFromFlag(libInfo);

				//for (libArg in libArgs) {
				//	currentCall.addArg(libArg);
				//}

				currentCall.addLib(libInfo);

			// resolve library
			case Rest(arg):
				currentCall.addArg(arg);
			default:
				throw "Error working through arguments...";
		}
	}

	next();

	return individualCalls;
}
