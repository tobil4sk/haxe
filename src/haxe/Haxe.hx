package haxe;
import sys.io.Process;
import sys.FileSystem;

import haxe.io.Path;

import haxe.Error.BuildError;
import haxe.Args;
import haxe.Args.ArgType;

import haxe.BuildCall;

import haxelib.client.Main as Haxelib;

typedef BuildInfo = {
	buildDir:String,
	haxecPath:String,
	builds:Array<BuildCall>
}

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
		final args = Args.parse(argsArray);

		// process arguments
		final buildInfo = generateBuildInfo(args);

		// temporary solution, would be better to avoid Sys.setCwd()
		Sys.setCwd(buildInfo.buildDir);

		// make calls
		for (build in buildInfo.builds) {
			Sys.command(buildInfo.haxecPath, build.args);
		}

		// back to default directory
		Sys.setCwd(dir);
	}

	function generateBuildInfo(args:ArgsInfo):BuildInfo {
		// work out build directory
		final buildDir = getBuildDirectory(args.specialArgs.get("cwd"));

		// get the absolute path for the override path, if specified.
		final overridePath = getLockFilePath(args.specialArgs.get("lock-file"), buildDir);

		// start library resolver
		final resolver = new Resolver(buildDir, overridePath);

		var haxecPath = "";

		final individualCalls = generateBuildCalls(args.mainArgs, resolver);

		return {
			buildDir : buildDir,
			builds : individualCalls,
			haxecPath : haxecPath
		};
	}

	function getBuildDirectory(cwdArg:Null<String>):String {
		if (cwdArg == null)
			return dir;

		if (Path.isAbsolute(cwdArg))
			return cwdArg;

		return Path.join([dir, cwdArg]);
	}

	function getLockFilePath(overridePath:Null<String>, buildDir:String):String {
		if (overridePath == null || Path.isAbsolute(overridePath))
			return overridePath;

		return Path.join([buildDir, overridePath]);
	}


	function generateBuildCalls(args:haxe.iterators.ArrayIterator<ArgType>, resolver:Resolver){
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
				case PairArg("library", name):
					final libPath = resolver.libPath(name);


				// resolve library
				case Rest(arg):
					currentCall.args.push(arg);
				default:
					throw "Error working through arguments...";
			}
		}

		next();

		return individualCalls;
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
