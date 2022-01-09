/**
	Functions ported mostly from the compiler
**/

package haxe;

using StringTools;

/**
	Takes in hxml string `content`, removes all empty lines and comments,
	and returns an array of arguments as would be passed to the compiler.
 **/
function parseHXML(content:String):Array<String>{
	final lines = splitLines(content);

	final args = [];

	var spaceIndex:Int;
	for(line in lines){
		// if it is a flag with information after it
		if (line.startsWith("-") && (spaceIndex = line.indexOf(" ")) != -1) {
			// split by spaces
			args.push(unquote(line.substring(0, spaceIndex)));
			args.push(unquote(line.substring(spaceIndex + 1).trim()));
			continue;
		}
		args.push(line);
	}
	return args;
}

/**
	Takes `content` of an hxml, and splits it into separate lines,
	trimming and unquoting, and removing comments.
**/
private function splitLines(content:String):Array<String>{
	return ~/[\r\n]+/g.split(content)
		.map(
			// trim and remove quotes
			(str) -> unquote(str.trim())
		)
		.filter(
			// remove empty lines and comments
			(line) -> line != "" && !line.startsWith("#")
		);
}

// for some reason the haxe compiler does this
private function unquote(str:String):String {
	if (str.startsWith('"') && str.endsWith('"') || str.startsWith("'") && str.endsWith("'"))
		return str.substring(1, str.length - 1);
	return str;
}
