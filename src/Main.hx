import sys.FileSystem;
import haxe.io.Path;

class Main {
	static final LOCKFILE = "haxelib-lock.json";
	static final GLOBAL_LOCKFILE = "haxelib-global-lock.json";

	final dir:Path;

	final args:Array<String>;

	final packageManager:PackageManager;

	final lockData:LockFormat;

	/** Array of haxec calls that will be run at the end **/
	final builds:Array<Build>;

	function new(dir:String, args:Array<String>){
		this.dir = new Path(dir);
		this.args = args;

		packageManager = new PackageManager();

		lockData = [];

		builds = [];
	}

	/**
		Run haxe
	**/
	function run(){
		// expand all .hxml files

		// open lock files

		// local one
		loadLockFile(LOCKFILE);

		// lock file given as argument
		if (args.contains("--lock-file")) {
			var index = args.indexOf("--lock-file");
			var filePath = args.splice(index, 2)[1];
			trace(index, filePath);

			// if given as an argument, it is not optional so throw error if it is not found
			loadLockFile(filePath, false);
		}

		// global lock file
		var globalLockPath = Sys.getEnv("HAXELIB_OVERRIDE_PATH");
		if (globalLockPath == null) {
			var home = Sys.getEnv("HOME");
			if (home == null)
				// Windows
				home = Sys.getEnv("USERPROFILE");
		}
		var globalFile = Path.join([globalLockPath, GLOBAL_LOCKFILE]);

		trace(globalFile);

		loadLockFile(globalFile);


		for (i => j in lockData){
			trace(i, j);
		}

		// process arguments

		// resolve all -lib flags



		// separate calls if needed


		// resolve haxec executable
		var haxecPath = "";

		// make calls
		for (build in builds){
			//Sys.command(haxecPath, call.args);
		}
	}

	/**
		Parses a lockfile and if new values are set then overrides old ones
	 */
	function loadLockFile(path:String, optional = true):Void {
		if (sys.FileSystem.exists(path)) {
			var content = haxe.Json.parse(sys.io.File.getContent('./${LOCKFILE}'));
			var lock = LockFormat.load(content);
			for(lib in lock.keys())
				lockData[lib] = lock[lib];
			return;
		}

		if(!optional)
			throw 'Lock file at ${path} not found';
	}

	/** entry point **/
	static function main():Void {
		var args = Sys.args();
		var dir = Sys.getCwd();
		//if haxelib call
		dir = args.pop();
		Sys.setCwd(dir);
		//
		new Main(dir, args).run();
	}
}
