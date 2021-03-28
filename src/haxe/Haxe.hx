package haxe;

import haxe.io.Path;

class Haxe {

	//final packageManager:PackageManager;

	function new(){
		//packageManager = new PackageManager();

	}

	/**
	Run a haxe command. Work out if building, or doing something else (e.g. --version or --help)
	beginning in `dir` with `args` as arguments with which to run it
	**/
	public function run(dir:String, args:Array<String>):Void {
		// expand all .hxml files
		trace(args);
		try {
			final expandedArgs = new Args(args);

			final setup = expandedArgs.getSpecialArg("lib-setup");
			if(setup != null){
				libSetup(setup);
			} else {
				build(dir, expandedArgs);
			}
		} catch (e:Error) {
			Error.log(e);
		}

	}

	/** Run lib setup, part of haxelib **/
	function libSetup(path:String){
		Haxelib.setup(path);
	}

	/**
	Run a haxe building command beginning in `dir` (overriden by `--cwd` flag) with `args` as
	arguments with which to run it. `args` can no longer contain .hxmls or commands that are not for building
	**/
	function build(dir:String, args:Args):Void {

		// check for --cwd first
		final newDir = args.getSpecialArg("cwd");

		if (newDir != null){
			Sys.setCwd(newDir);
		}

		final overridePath = args.getSpecialArg("lock-file");
		final resolver = new Resolver(dir, overridePath);


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




	/** entry point **/
	static function main():Void {
		var args = Sys.args();
		var dir = Sys.getCwd();

		//if haxelib call
		if (Sys.getEnv("HAXELIB_RUN") == "1"){
			dir = args.pop();
			Sys.setCwd(dir);
		}

		new Haxe().run(dir, args);
	}
}
