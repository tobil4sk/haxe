package haxe;

import sys.FileSystem;

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
		final args = Args.parse(dir, argsArray);

		// process arguments
		final buildInfo = BuildInfo.generateBuildInfo(dir, args);

		// temporary solution, would be better to avoid Sys.setCwd()
		final tmp = Sys.getCwd();

		Sys.setCwd(buildInfo.buildDir);

		// make calls
		for (build in buildInfo.builds) {
			Sys.command(buildInfo.haxecPath, build.getArgs());
		}

		// back to default directory
		Sys.setCwd(tmp);
	}



	/** Print help information to console **/
	function help():Void{

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
			} else if(args.length == 0){
				process.help();
			} else {
				process.build(args);
			}
		} catch (e:Error) {
			e.log();
		}
	}
}
