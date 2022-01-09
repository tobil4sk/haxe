package haxe;

import sys.io.File;

import haxe.iterators.ArrayIterator;

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

typedef Args = {
	final specialArgs:Map<String, Null<String>>;
	final mainArgs:ArrayIterator<ArgType>;
}

/**
	A class that parses hxmls and works out if an argument is single or comes in a pair.
**/

/** arguments that need to be processed before anything else **/
private final SPECIAL_ARGS = [
	"cwd"=>["C"],
	"lock-file"=>[]
];

/** All possible single arguments with their aliases **/
private final SINGLE_ARGS = [
	"version"=>[],
	"help"=>["h"],
	"next"=>[],
	"each" => [],
	"help-haxec" => []
];

/** All possible paired arguments with aliases **/
private final PAIR_ARGS = [
	"library" => ["L", "lib"]
];

class IncompleteOptionError extends Error.ArgsError {
	public function new(arg:String) {
		super('option \'${arg}\' needs an argument');
	}
}

/**
	Create an Args object from the array `args`.

	`dir` is where to begin searching for .hxmls,
	but --cwd arguments will override it.

	Parse .hxml files and sort their arguments recursively

**/
function parse(dir:String, args:Array<String>):Args {
	/** priority arguments that need to be retrievable at the beginning **/
	final specialArgs:Map<String, Null<String>> = [];

	/** The args that will be looped through **/
	final argsArray = [];

	var current:String;
	while (args.length > 0) {
		current = args.shift();
		switch (getArgType(current)) {
			case USpecialArg(arg):
				if (args.length == 0)
					throw new IncompleteOptionError(arg);

				final value = specialArgs[arg] = args.shift();

				// update dir if it is cwd, as hxmls need to be looked for there
				if (arg == "cwd")
					dir = value;

			case USingleArg(arg):
				args.shift();
				argsArray.push(SingleArg(arg));

			case UPairArg(arg):
				trace(args.length, arg);
				if (args.length == 0)
					throw new IncompleteOptionError(arg);

				argsArray.push(PairArg(arg, args.shift()));

			case URest(arg):
				argsArray.push(Rest(arg));

			case UHxml(file):
				final path = Utils.joinUnlessAbsolute(dir, file);

				final out = getArgsFromHxml(path);
				// add all the extracted arguments to the list
				while (out.length > 0)
					args.unshift(out.pop());
		}
	}

	trace("ARGS SORTED!");
	trace(argsArray);
	return {
		specialArgs: specialArgs,
		mainArgs: argsArray.iterator()
	};
}

/** Parse an extraParams.hxml file. Throw an error if an illegal argument is found **/
function parseLibArgs(path:String):Array<String> {
	final args = HXML.parseHXML(path);

	final argsArray = [];
	var current:String;
	while (args.length > 0) {
		current = args.shift();
		switch (getArgType(current)) {
			case URest(arg):
				argsArray.push(arg);
			case UPairArg("library"):
				Error.warn('file ${path} contains argument \'${current}\', which is not necessary in extraParams.hxml files');
				args.shift();
			case _:
				Error.warn('file ${path} contains argument \'${current}\', which is not allowed in extraParams.hxml files');
		}
	}

	return argsArray;
}

private function getArgsFromHxml(path:String):Array<String> {
	final content =
		try
			File.getContent(path)
		catch (e:Exception)
			throw new Error.FileError(path);

	return HXML.parseHXML(content);
}

/** Evaluates the type of an argument and returns it as an enum **/
private function getArgType(arg:String): UnparsedArgType {
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
private function stripDash(arg:String):String {
	var match = ~/-[^-]/;
	if (match.match(arg))
		return arg.substring(1);
	return "";
}

/**
If the argument has "--" in front of it, return it without it, otherwise return an empty string
**/
private function stripDashes(arg:String):String {
	var match = ~/--[^-].+/;
	if(match.match(arg))
		return arg.substring(2);
	return "";
}

/** If an argument exists in a map, return its main alias, otherwise return null **/
private function getMainAlias(rawArg:String, map:Map<String, Array<String>>):Null<String>{
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
