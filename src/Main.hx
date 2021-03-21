import sys.FileSystem;
import haxe.io.Path;

class Main {
	static final LOCK_FILE = "haxelib-lock.json";
	static final GLOBAL_LOCK_FILE = "haxelib-global-lock.json";

	final packageManager:PackageManager;

	function new(){
		packageManager = new PackageManager();

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
			build(dir, expandedArgs);
		} catch (e:Error) {
			Error.log(e);
		}

	}

	/**
	Run a haxe building command beginning in `dir` (overriden by `--cwd` flag) with `args` as
	arguments with which to run it. `args` can no longer contain .hxmls or commands that are not for building
	**/
	function build(dir:String, args:Args):Void {

		// check for --cwd first
		final newDir = args.getArgPair("cwd");

		if (newDir != null){
			Sys.setCwd(newDir);
		}

		final overridePath = args.getArgPair("lock-file");
		final lockData = loadLockFiles(dir, overridePath);

		for (i => j in lockData) {
			trace(i, j);
		}

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

	/**
	Return LockFormat Map containing library information. Look for `haxelib-lock.json` in `dir`, then
	get `overridePath` if specified
	**/
	function loadLockFiles(dir:String, ?overridePath:Null<String>):LockFormat{
		// open lock files
		trace(overridePath);
		var lockData:LockFormat = [];

		/** Parses a lockfile and if new values are set then overrides old ones */
		function loadLockFile(path:String, optional = true) {
			if (FileSystem.exists(path)) {
				var content = haxe.Json.parse(sys.io.File.getContent(path));
				var lock = LockFormat.load(content);
				for (lib in lock.keys())
					lockData[lib] = lock[lib];
			}

			if (!optional)
				throw new Error.FileError(path);
		}

		// local one
		loadLockFile(LOCK_FILE);

		// lock file given as argument, it is not optional so throw error if it is not found
		if(overridePath != null) {
			loadLockFile(overridePath, false);
		}

		// global lock file
		var globalLockPath = locateGlobalLockFile();
		var globalFile = Path.join([globalLockPath, GLOBAL_LOCK_FILE]);

		//trace(globalFile);

		loadLockFile(globalFile);

		return lockData;
	}

	/**
	Returns the path to the global lockfile
	**/
	public static function locateGlobalLockFile():String{
		var globalLockPath = Sys.getEnv("HAXELIB_OVERRIDE_PATH");
		if (globalLockPath == null) {
			var home = Sys.getEnv("HOME");
			if (home == null)
				// Windows
				home = Sys.getEnv("USERPROFILE");
			globalLockPath = home;
		}
		return globalLockPath;
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

		new Main().run(dir, args);
	}
}
