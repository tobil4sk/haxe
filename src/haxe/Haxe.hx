package haxe;
import sys.FileSystem;

import haxe.io.Path;


import haxelib.client.Main as Haxelib;
class Haxe {

	/** Default directory from which build commands are run (overriden for individual builds by --cwd) **/
	public var dir(default, set):String;

	function set_dir(dir:String) {
		if(!sys.FileSystem.exists(dir))
			throw 'Path \'${dir}\' does not exist';
		return this.dir = dir;
	}

	/** Initialize the haxe frontend in a specific directory **/
	function new(dir:String){
		this.dir = dir;
	}

	/** Run lib-setup **/
	public function libSetup(args:Array<String>){

		var path = switch (args.length){
		case 0: "";
		case 1: args[0];
		case _: throw new Error.ArgsError('lib-setup expects a maximum of one argument');
		}

		var rep = try Haxelib.getGlobalRepositoryPath() catch (_:Dynamic) null;

		if (path == "") {
			if (rep == null)
				rep = Haxelib.getSuggestedGlobalRepositoryPath();
			Sys.println("Please enter haxelib repository path with write access");
			Sys.println("Hit enter for default (" + rep + ")");

			Sys.print("Path : ");
			path = Sys.stdin().readLine();
		}

		if (path != "") {
			var splitLine = path.split("/");
			if (splitLine[0] == "~") {
				var home = Haxelib.getHomePath();

				for (i in 1...splitLine.length) {
					home += "/" + splitLine[i];
				}
				path = home;
			}

			rep = path;
		}

		rep = try FileSystem.absolutePath(rep) catch (e:Dynamic) rep;

		Haxelib.saveSetup(rep);

		Sys.println("haxelib repository is now " + rep);
	}

	/**
		Run a haxe building command with `argsArray` as array of arguments with which to run it.
	**/
	public function build(argsArray:Array<String>):Void {
		final args = new Args(argsArray);

		// check for --cwd first
		final buildDir = switch(args.getSpecialArg("cwd")){
			case null: dir;
			case path: path;
		};

		// get the absolute path for the override path, if specified.
		final overridePath = switch(args.getSpecialArg("lock-file")){
			case null: null;
			case path if(!Path.isAbsolute(path)): Path.join([buildDir, path]);
			case absolutePath: absolutePath;
		};
		final resolver = new Resolver(buildDir, overridePath);


		// process arguments

		// resolve all -lib flags

		// separate calls if needed

		// Array of haxec calls that will be run at the end
		final builds:Array<Build> = [];

		// resolve haxec executable
		var haxecPath = "";

		// make calls
		for (build in builds) {
			// Sys.command(haxecPath, call.args);
		}
	}

	/** Entry point **/
	static function main():Void {
		final args = Sys.args();
		var dir = Sys.getCwd();

		//if haxelib call
		if (Sys.getEnv("HAXELIB_RUN") == "1"){
			dir = args.pop();
			Sys.setCwd(dir);
		}

		final process = new Haxe(dir);

		try {
			if (args[0] == "lib-setup") {
				args.shift();
				process.libSetup(args);
			} else {
				process.build(args);
			}
		} catch (e:Error) {
			Error.log(e);
		}
	}
}
