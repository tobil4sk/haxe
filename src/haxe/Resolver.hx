package haxe;

import sys.FileSystem;
import haxe.io.Path;

import haxelib.client.Main as Haxelib;

final LOCK_FILE = "haxelib-lock.json";
final GLOBAL_LOCK_FILE = "haxelib-global-lock.json";
final GLOBAL_LOCK_VAR = "HAXELIB_OVERRIDE_PATH";

/** Structure of a library taken out of a lock file **/
private typedef LibRaw = {path:String, version:String, ?url:String, ?dependencies:Array<String>, ?ref:String}

/** Information on a specific library loaded from lock file **/
@:structInit
private class Lib {
	public final version:String;
	public final path:String;
	public final dependencies:Array<String>;
}

/** Information on a git or hg library **/
@:structInit
private class VCSLib extends Lib {
	public final url:String;
	public final ref:String;
}

/** Map that stores libraries and their information **/
private typedef LockFormat = Map<String, Lib>;

private class PathParseError extends Error {}

private class LibraryMissing extends Error {
	public function new(lib:String, scoped = true) {
		var errorString = 'Library ${lib} not installed in current scope : run \'haxelib install ${lib}\'';

		if (!scoped)
			errorString = 'Library ${lib} not installed : run \'haxelib install ${lib}\'';

		super(errorString);
	}
}

private class LibraryVersionMissing extends Error {
	public function new(lib:String, version:String, scoped = true) {
		var errorString = 'Library ${lib} version ${version} not installed in current scope';

		if (!scoped)
			errorString = 'Library ${lib} version ${version} not installed';

		super(errorString);
	}
}

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

function isVCS(version:String):Bool {
	return version == "git" || version == "hg";
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

	final haxelibPath:String;

	/**
		Create a resolver instance in `dir`, optionally with an override file specified at `overridePath`.
		if `useGlobals` is set to false, then ignore global override file, if it exists.
	 **/
	public function new(dir:String, ?overridePath:Null<String>, useGlobals = true){
		haxelibPath = getHaxelibPath();

		localLockData = loadLocalLockFiles(dir, overridePath);
		// if lockData is empty at this point, the resolution isn't scoped.
		scoped = localLockData == null;

		// if meant to use globals, check if the global file exists
		if(useGlobals){
			globalLockData = loadGlobalLockFile();
			this.useGlobals = (globalLockData != null);
		} else {
			globalLockData = null;
			this.useGlobals = false;
		}


		for (i => j in localLockData) {
			trace(i, j.version, j.path);
		}
	}

	static function getHaxelibPath():String {
		var path = Sys.getEnv("HAXELIB_LIBRARY_PATH");
		if (path != null)
			return path;
		return Haxelib.findRepository();
	}

	/** Change environment variables in `path` to their values and return **/
	function getAbsolute(path:String):String {
		var newPath = "";

		var index = 0;

		while (index < path.length){
			if(path.substr(index, 2) == "${"){
				var name = "";
				index += 2;
				var char = "";

				do {
					name += char;
					char = path.charAt(index++);
				} while (char != "}" && char != "");

				if(char == "")
					throw new PathParseError('variable \'${name}\' is not closed with a \'}\'');

				var variable = getVariable(name);
				if(variable == null)
					throw new PathParseError('variable ${name} not found');

				newPath = Path.join([newPath, variable]);
			}
			newPath += path.charAt(index);
			index++;
		}
		trace(newPath);
		return newPath;
	}

	function getVariable(name:String):Null<String> {
		if (name == "haxelib")
			return haxelibPath;
		return Sys.getEnv(name);
	}

	function getLibDataFromRaw(lib:LibRaw):Lib {
		final dependencies = if (lib.dependencies == null) [] else lib.dependencies;

		if (isVCS(lib.version)) {
			final normalized:VCSLib = {
				path: getAbsolute(lib.path),
				version: lib.version,
				dependencies: dependencies,
				url: lib.url,
				ref: lib.ref
			};
			return normalized;
		}
		return {
			path: getAbsolute(lib.path),
			version: lib.version,
			dependencies: dependencies
		};
	}

	/**
		Loads LockFormat map with normalized paths from path
	**/
	function load(path:String):LockFormat {
		final content:DynamicAccess<LibRaw> = haxe.Json.parse(sys.io.File.getContent(path));

		final lock:LockFormat = [];
		for (name => lib in content) {
			try {
				lock[name] = getLibDataFromRaw(lib);
			} catch (e:PathParseError) {
				throw 'Could not parse path of library \'${name}\' in lockfile ${path}: \n ${e.message}';
			} catch (e) {
				trace(e.stack);
				throw 'Library ${name} in lockfile ${path} has illegal fields';
			}
		}
		return lock;
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
					final lock = load(path);
					for (lib in lock.keys())
						localLockData[lib] = lock[lib];
					return;
				} //catch(e:Exception){}
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
		final globalLockData = load(Path.join([globalLockPath, GLOBAL_LOCK_FILE]));

		if (!globalLockData.keys().hasNext())
			return null;
		return globalLockData;
	}

	/** Get the path for a library, optionally with a specific version.
		If the resolution method is scoped and the library cannot be found,
		throws an error, otherwise resolve it using `.current` files. **/
	public function getLibPath(lib:String, ?version:Null<String>):String{
		final checkVersion = version != null;
		var localLibData:Null<Lib> = null;
		var libData:Null<Lib>;

		// if scoped, throw errors if lib not found in scope,
		// whether or not dev or global will override
		if(scoped){
			localLibData = localLockData.get(lib);
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
				return libData.path;

		if (scoped) {
			// from local lock data
			// if version matches or version match not necessary
			if (!checkVersion || (version == localLibData.version))
				return localLibData.path;

		} else {
			// resolve from haxelib .current files

		}


		return "";
	}

}
