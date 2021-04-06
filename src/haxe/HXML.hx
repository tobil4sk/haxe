/**
	Functions ported mostly from the compiler
**/

package haxe;

import sys.io.File;
import sys.FileSystem;


/** Load arguments as array of strings from an hxml **/
function fromHXML(path:String):Array<String>{
	if(!FileSystem.exists(path))
		throw new Error.FileError(path);

	final content = File.getContent(path);

	final lines = splitLines(content);

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

private function splitLines(content:String):Array<String>{
	final lines = [];

	final matches = ["\r", "\n"];

	var index = 0;
	var line:StringBuf;

	while (index < content.length) {
		line = new StringBuf();
		// get line content until newline reached or end of string
		while(!matches.contains(content.charAt(index)) && content.charAt(index) != ""){
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

// for some reason the compiler does this
private function unquote(str:String):String {
	final len = str.length;
	if (len > 0) {
		return switch ([str.charAt(0), str.charAt(len - 1)]) {
			case ['"', '"'] | ["'", "'"]:
				str.substring(1, len - 1);
			case _:
				str;
		}
	}
	return str;
}

// replaces List.concat in ocaml
private function flatten(array:Array<Array<String>>):Array<String> {
	final newArray = [];
	for (subArray in array)
		for (item in subArray)
			newArray.push(item);
	return newArray;
}
