package haxe;

enum ArgType {
	SingleArg(arg:String);
	PairArg(arg:String, value:Null<String>);
	Rest(arg:String);
}

private enum UnparsedArgType {
	USpecialArg(arg:String);
	USingleArg(arg:String);
	UPairArg(arg:String);
	UHxml(file:String);
	URest(arg:String);
}
/**
	A class that parses hxmls and works out if an argument is single or comes in a pair.
**/
class Args {

	/** arguments that need to be processed before anything else **/
	static final SPECIAL_ARGS = [
		"cwd"=>["C"],
		"lock-file"=>[],
		"lib-setup"=>[]
	];

	/** All possible single arguments with their aliases **/
	static final SINGLE_ARGS = [
		"version"=>[],
		"help"=>["h"],
		"next"=>[],
		"each"=>[]
	];

	/** All possible paired arguments with aliases **/
	static final PAIR_ARGS = [
		"library" => ["L", "lib"]
	];

	/** priority arguments that need to be retrievable at the beginning **/
	final specialArgs:Map<String, Null<String>>;

	/** The args that will be looped through **/
	final argsArray:Array<ArgType>;

	public function new(args:Array<String>) {
		specialArgs = [];
		argsArray = [];

		sortArgs(args);

		trace("ARGS SORTED!");
		trace(argsArray);
	}


	/** Work out what types of arguments are in the array `args` and separate them accordingly. Parse .hxml files and sort their arguments recursively **/
	function sortArgs(args:Array<String>):Void {
		var current:String;
		while (args.length > 0) {
			current = args[0];
			switch (getArgType(current)) {

			case USpecialArg(arg):
				specialArgs[arg] = args.splice(0, 2).pop();

			case USingleArg(arg):
				args.splice(0, 1);
				argsArray.push(SingleArg(arg));

			case UPairArg(arg):
				trace(args.length, arg);
				if(args.length == 1) {
					// error unless it is lib-setup
					if (arg != "lib-setup")
						throw new Error.IncompleteOptionError(current);
					args.shift();
					argsArray.push(PairArg(arg, ""));
				} else
					argsArray.push(PairArg(arg, args.splice(0, 2).pop()));

			case URest(arg):
				args.splice(0, 1);

				argsArray.push(Rest(arg));

			case UHxml(file):
				final out = HXML.fromHXML(file);
				args.shift();

				// add all the extracted arguments to the list
				while(out.length > 0)
					args.unshift(out.pop());

			}
		}
	}

	public function next(){
		return argsArray.shift();
	}

	public function hasNext(){
		return argsArray.length > 0;
	}

	/** If a special arg exists, return its value. Else return null **/
	public function getSpecialArg(arg:String): Null<String>{
		return specialArgs.get(arg);
	}
	/** Return true if a special arg is present, otherwise false **/
	public function specialArgExists(arg:String):Bool{
		return specialArgs.exists(arg);
	}

	/** Evaluates the type of an argument and returns it as an enum **/
	static function getArgType(arg:String): UnparsedArgType {
		switch (arg) {
			case getMainAlias(_, SPECIAL_ARGS) => arg if (arg != null):
				return USpecialArg(arg);
			case getMainAlias(_, SINGLE_ARGS) => arg if (arg != null):
				return USingleArg(arg);
			case getMainAlias(_, PAIR_ARGS) => arg if (arg != null):
				return UPairArg(arg);
			case file if(file.substring(file.length - 5) == ".hxml") :
				return UHxml(file);
			case arg:
				return URest(arg);
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
	If the argument has "--" in front of it, return it without it, otherwise return an empty string
	**/
	static function stripDashes(arg:String):String {
		var match = ~/--[^-].+/;
		if(match.match(arg))
			return arg.substring(2);
		return "";
	}

	/** If an argument exists in a map, return its main alias, otherwise return null **/
	static function getMainAlias(rawArg:String, map:Map<String, Array<String>>):Null<String>{
		// check if it matches the maps keys if the dashes are removed
		var arg = stripDashes(rawArg);
		if(map.exists(arg))
			return arg;
		// if it is in their aliases

		// aliases require a single dash
		var stripSingle = stripDash(rawArg);
		for(main => aliases in map)
			if(aliases.contains(stripSingle))
				return main;

		return null;
	}

}
