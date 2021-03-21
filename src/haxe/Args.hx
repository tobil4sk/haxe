package haxe;

private enum ArgType {
	SingleArg(arg:String);
	PairArg(arg:String);
	Hxml(file:String);
	Rest(arg:String);
}

/**
	An abstract type over an array of strings, that allows getting individual
**/
class Args {
	/** All possible single arguments with their aliases **/
	static final SINGLE_ARGS = [
		"version"=>[],
		"help"=>["h"],
		"next"=>[],
		"each"=>[]
	];

	/** All possible paired arguments with aliases **/
	static final PAIR_ARGS = [
		"cwd"=>["C"],
		"lock-file"=>[],
		"library" => ["L", "lib"]
	];

	/** single haxe arguments **/
	final singleArgs:Array<String>;

	/** haxe arguments that come in a pair**/
	final pairArgs:Map<String, String>;

	/** The remaining arguments, which will be passed onto the compiler**/
	final rest:Array<String>;

	public function new(args:Array<String>) {
		singleArgs = [];
		pairArgs = [];
		rest = [];

		sortArgs(args);

		trace("ARGS SORTED!");
		trace(singleArgs);
		trace(pairArgs);
		trace(rest);
	}


	/** Work out what types of arguments are in the array `args` and separate them accordingly. Parse .hxml files and sort their arguments recursively **/
	function sortArgs(args:Array<String>):Void {
		var current:String;
		while (args.length > 0) {
			current = args[0];
			switch (getArgType(current)) {
				case SingleArg(arg):
					args.splice(0, 1);
					singleArgs.push(arg);
				case PairArg(arg):
					if(args.length == 1)
						//error
						throw new Error.IncompleteOptionError(arg);
					pairArgs[arg] = args.splice(0, 2).pop();
				case Hxml(file):
				// incomplete
				case Rest(arg):
					args.splice(0, 1);
					rest.push(arg);
			}
		}
	}

	/**
		If `arg` exists as a single argument, remove it and return true, otherwise return false.
	**/
	public function getSingleArg(arg:String):Bool {
		return singleArgs.remove(arg);
	}

	/** If a flag exists, pop it along with the following value, and return. Else return null **/
	public function getArgPair(arg:String):Null<String> {
		var value = pairArgs.get(arg);
		pairArgs.remove(arg);
		return value;
	}

	/** Evaluates the type of an argument and returns it as an enum **/
	static function getArgType(arg:String): ArgType {
		switch(arg){
			case getMainAlias(_, SINGLE_ARGS) => arg if (arg != null):
				return SingleArg(arg);
			case getMainAlias(_, PAIR_ARGS) => arg if (arg != null):
				return PairArg(arg);
			case file if(file.substring(file.length - 5) == ".hxml") :
				return Hxml(file);
			case arg:
				return Rest(arg);
		}

	}

	/**
		If the argument has a "-" in front of it, return it without it, otherwise return an empty string.
	**/
	static function stripDash(arg:String):String {
		var match = ~/-[^-]/;
		if (match.match(arg))
			return arg.substring(1);
		return "";
	}

	/**
	If the argument has a "-" or "--" in front of it, return it without it, otherwise return an empty string
	**/
	static function stripDashes(arg:String):String {
		var match = ~/--[^-].+/;
		if(match.match(arg))
			return arg.substring(2);
		return stripDash(arg);
	}

	/** If an argument exists in a map, return its main alias, otherwise return null **/
	static function getMainAlias(rawArg:String, map:Map<String, Array<String>>):Null<String>{
		// check if it matches the maps keys if the dashes are removed
		var arg = stripDashes(rawArg);
		if(map.exists(arg))
			return arg;
		// if it is in their aliases

		// the first alias requires a single dash
		var first = true;
		for(main => aliases in map) {
			if (first){
				first = false;
				if(aliases.contains(stripDash(rawArg)))
					return main;
				continue;
			}
			if (aliases.contains(arg))
				return main;
		}
		return null;
	}

}
