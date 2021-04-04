package haxe;

import haxe.Error.LibraryVersionMissing;
import haxe.Error.LibraryMissing;
import sys.FileSystem;
import haxe.io.Path;
import haxe.ds.Either;

final LOCK_FILE = "haxelib-lock.json";
final GLOBAL_LOCK_FILE = "haxelib-global-lock.json";
final GLOBAL_LOCK_VAR = "HAXELIB_OVERRIDE_PATH";

typedef Lib = {
	var version:String;
	var path:String;
	var dependencies:Either<Array<String>, LockFormat>;
}

typedef LockFormat = Map<String, Lib>;

/**
	Returns the path to the global lockfile
**/
function locateGlobalLockFile():String {
	var globalLockPath = Sys.getEnv(GLOBAL_LOCK_VAR);
	if (globalLockPath == null) {
		var home = Sys.getEnv("HOME");
		if (home == null)
			// Windows
			home = Sys.getEnv("USERPROFILE");
		globalLockPath = home;
	}
	return globalLockPath;
}

/**
	Loads a LockFormat map from a json object
**/
function load(content:Dynamic):LockFormat {
	var lock:LockFormat = [];
	for (field in Reflect.fields(content)){
		lock[field] = Reflect.field(content, field);
	}
	return lock;
}

class Resolver {
	/** Whether local lock files are used in library resolution **/
	public final scoped:Bool;
	/** Whether global lock file is used in library resolution **/
	public final useGlobals:Bool;

	/** lockData from local files **/
	final localLockData:Null<LockFormat>;
	/** lockData from global lock file **/
	final globalLockData:Null<LockFormat>;

	final haxelibPath:Path;

	/**
		Create a resolver instance in `dir`, optionally with an override file specified at `overridePath`.
		if `useGlobals` is set to false, then ignore global override file, if it exists.
	 **/
	public function new(dir:String, ?overridePath:Null<String>, useGlobals = true){

		localLockData = loadLocalLockFiles(dir, overridePath);
		// if lockData is empty at this point, the resolution isn't scoped.
		scoped = lockData == null;

		// if meant to use globals, check if the global file exists
		if(useGlobals){
			globalLockData = loadGlobalLockFile();
			this.useGlobals = (globalLockData != null);
		} else {
			globalLockData = null;
			this.useGlobals = false;
		}

		haxelibPath = new Path(Haxelib.getRepository());

		for (i => j in localLockData) {
			trace(i, j);
		}
	}


	/**
		Return LockFormat Map containing library information. Look for `haxelib-lock.json`, then
		override with `overridePath` if specified. Returns null if neither of these can be found.
	**/
	function loadLocalLockFiles(dir:String, overridePath:Null<String>):Null<LockFormat> {
		trace(overridePath);
		final localLockData:LockFormat = [];
		/** Parses a lockfile and if new values are set then overrides old ones */
		function loadLockFile(path:String, optional = true) {
			if (FileSystem.exists(path)) {
				try {
					final content = haxe.Json.parse(sys.io.File.getContent(path));
					final lock = load(content);
					for (lib in lock.keys())
						localLockData[lib] = lock[lib];
					return;
				} catch(e:Exception){}
			}

			if (!optional)
				throw new Error.FileError(path);
		}
		// local one
		loadLockFile(Path.join([dir, LOCK_FILE]));

		// lock file given as argument, it is not optional so throw error if it is not found
		if (overridePath != null) {
			loadLockFile(overridePath, false);
		}

		if (!localLockData.keys().hasNext())
			return null;
		return localLockData;
	}

	/**
		Return LockFormat Map containing global library information. Returns null if not found.
	**/
	function loadGlobalLockFile():Null<LockFormat>{
		// global lock file
		final globalLockPath = locateGlobalLockFile();
		final lockData = load(Path.join([globalLockPath, GLOBAL_LOCK_FILE]));

		if(!lockData.keys().hasNext())
			return null;
		return lockData;
	}

	/** Change environment variables in `path` to their values and return as a Path object **/
	function getAbsolute(path:String):Path{


		return new Path(path);
	}

	/** Get the path for a library, optionally with a specific version.
		If the resolution method is scoped and the library cannot be found,
		throws an error, otherwise resolve it using `.current` files. **/
	public function libPath(lib:String, ?version:Null<String>):Path{
		final checkVersion = version != null;
		var localLibData:Null<Lib> = null;
		var libData:Null<Lib>;

		// if scoped, throw errors if lib not found in scope,
		// whether or not dev or global will override
		if(scoped){
			localLibData = lockData.get(lib);
			if(localLibData == null)
				throw new LibraryMissing(lib);
			if(checkVersion && (version != localLibData.version))
				throw new LibraryVersionMissing(lib, version);
		}

		// get dev version first

		// global data
		libData = globalLockData.get(lib);
		if(libData != null)
			// if version matches or version match not necessary
			if(!checkVersion || (version == libData.version))
				return getAbsolute(libData.path);

		if (scoped) {
			// from local lock data
			// if version matches or version match not necessary
			if (!checkVersion || (version == localLibData.version))
				return getAbsolute(localLibData.path);

		} else {
			// resolve from haxelib .current files

		}


		return new Path("");
	}

}
