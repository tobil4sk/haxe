package haxe;

import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

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
		"library" => ["L", "lib"],
		"lib-setup"=>[]
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
					trace(args.length, arg);
					if(args.length == 1) {
						// error unless it is lib-setup
						if (arg != "lib-setup")
							throw new Error.IncompleteOptionError(current);
						args.shift();
						pairArgs[arg] = "";
					} else
						pairArgs[arg] = args.splice(0, 2).pop();
				case Hxml(file):
					final out = fromHxml(file);
					args.shift();

					// add all the extracted arguments to the list
					while(out.length > 0)
						args.unshift(out.pop());

				// incomplete
				case Rest(arg):
					args.splice(0, 1);
					rest.push(arg);
			}
		}
	}

	/** Load arguments from an hxml. Mostly ported from compiler. **/
	function fromHxml(path:String):Array<String>{
		if(!FileSystem.exists(path))
			throw new Error.FileError(path);

		final content = File.getContent(path);

		final lines = splitLines(content);

		// for some reason the compiler does this
		final unquote = function(str:String):String {
			final len = str.length;
			if (len > 0){
				return
					switch([str.charAt(0), str.charAt(len-1)]){
					case ['"', '"'] | ["'", "'"]:
						str.substring(1, len -1);
					case _:
						str;
					}
			}
			return str;
		}

		// replaces List.concat in ocaml
		final flatten = function(array:Array<Array<String>>):Array<String>{
			final newArray = [];

			for (subArray in array)
				for(item in subArray)
					newArray.push(item);

			return newArray;
		}

		// function used to map lines
		final split = function(str:String):Array<String>{
			// trim and remove quotes
			str = unquote(StringTools.trim(str));
			// remove empty lines and comments
			if (str == "" || str.charAt(0) == "#")
				return [];
			// if it is a flag
			else if (str.charAt(0) == "-") {
				// split by spaces
				final split = str.split(" ");
				// if the flag has extra information following it
				if (split.length > 1) {
					final flag = split[0];
					final extra = split.slice(1, split.length).join(" ");
					return [unquote(flag), unquote(StringTools.trim(extra))];
				}
			}

			return [str];
		}

		final newlines = flatten(lines.map(split));

		return newlines;
	}

	static function splitLines(content:String):Array<String>{
		final lines = [];


		final match = ~/[\r\n]+/;
		final matches = ["\r", "\n"];

		var index = 0;
		var line:StringBuf;
		var space:String;
		while (index < content.length) {
			line = new StringBuf();
			// get line content until newline reached
			while(!matches.contains(content.charAt(index))){
				line.add(content.charAt(index++));
			}
			// wait for white spaces to end
			while(matches.contains(content.charAt(index))){
				index++;
			}
			lines.push(line.toString());
		}
		return lines;
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
