package haxe;

import haxe.Utils.joinUnlessAbsolute;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

import haxelib.client.RepoManager;

using haxe.LockFormat;
using StringTools;

final LOCK_FILE = "haxelib-lock.json";
final GLOBAL_LOCK_FILE = "haxelib-global-lock.json";
final GLOBAL_LOCK_VAR = "HAXELIB_OVERRIDE_PATH";

// the name of a library's extra hxml file
private final LIB_HXML = "extraParams.hxml";

/** Structure of a library taken out of a lock file **/
private typedef LibRaw = {path:String, version:String, ?dependencies:Array<String>, ?vcs:{type:String, url:String, ref:String, ?branch:String}}

/** Information on a specific library loaded from lock file **/
@:structInit
class Lib {
	public final version:String;
	public final path:String;
	public final dependencies:Array<String>;
	public final vcs:Null<VCSInfo>;
}

/** Information on a git or hg library **/
@:structInit
private class VCSInfo {
	public final type:String;
	public final url:String;
	public final ref:String;
	public final branch:Null<String>;
}

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

private class DevLibraryMissing extends Error {
	public function new(lib:String, path:String) {
		super('dev path for ${lib} is set to non existant path: ${path}');
	}
}

/**
	Returns the path to the global lockfile
**/
function locateGlobalLockFile():String {
	var globalLockDir = Sys.getEnv(GLOBAL_LOCK_VAR);
	if (globalLockDir == null) {
		var home = Sys.getEnv("HOME");
		if (home == null)
			// Windows
			home = Sys.getEnv("USERPROFILE");
		globalLockDir = home;
	}
	return Path.join([globalLockDir, GLOBAL_LOCK_FILE]);
}

function isVCS(version:String):Bool {
	return version == "git" || version == "hg";
}

private function getHaxelibPath(dir:String):String {
	final path = Sys.getEnv("HAXELIB_LIBRARY_PATH");
	if (path != null)
		return path;
	return RepoManager.findRepository(dir);
}

private function getHaxecPath():String {
	return "";
}

abstract class Resolver {
	/** Whether or not to ignore global lock file and .dev files **/
	final ignoreGlobals:Bool;

	/** Map containing special path variables used when resolving lock file path fields **/
	final pathByName:Map<String, String>;

	/** lockData with which to override current library version **/
	final overrideLockData:LockFormat;


	/**
		Create a resolver instance at the directory `dir`,
		optionally with an override file specified at `overridePath`.

		If `ignoreGlobals` is set to true, global lock file and .dev libraries
		will be ignored.
	 **/
	function new(dir:String, overridePath:Null<String>, ignoreGlobals:Bool){
		this.ignoreGlobals = ignoreGlobals;

		pathByName = [
			"haxelib" => getHaxelibPath(dir),
			"haxec" => getHaxecPath()
		];


		overrideLockData = if (overridePath != null) load(overridePath); else [];

		// if meant to use globals, check if the global file exists
		if(this.ignoreGlobals){
			// global lock file
			final globalLockData = load(locateGlobalLockFile());
			overrideLockData.overrideLock(globalLockData);
		}
	}

	// wanted this to be a module level field, but @:allow doesn't work with that
	/**
		Create a resolver at the directory `dir`.

		If a `haxelib-lock.json` file is found in this directory,
		it will use scoped resolution and throw an exception if a library
		in the scope has not been installed. If no `haxelib-lock.json`
		is found, reverts to old resolution method.

		Applies overrides from the file at `overridePath`
		if specified.

		If `ignoreOverrides` is set to true, global override file
		and `.dev` files will be ignored when resolving libraries.
	**/
	public static function create(dir:String, overridePath:Null<String> = null, ignoreOverrides = false):Resolver {
		dir = FileSystem.absolutePath(dir);

		if(overridePath != null)
			overridePath = joinUnlessAbsolute(dir, overridePath);

		if (FileSystem.exists(Path.join([dir, LOCK_FILE])))
			return new ScopedResolver(dir, overridePath, ignoreOverrides);

		return new ScopelessResolver(dir, overridePath, ignoreOverrides);
	}

	public function resolveLibFlag(flag:LibFlagInfo):Null<Lib> {
		if (!confirmLibFlag(flag))
			return null;

		final global = getOverride(flag.name);

		if (global != null)
			return global;

		return getCurrent(flag.name);
	}

	/**
		Change resolution variables and environment variables
		in `path` to their values and return.

		Return null if a value could not be found for a variable.
	 **/
	function getAbsolute(path:String):Null<String> {
		return ~/\${([A-Za-z0-9_]+)}/g.map(path, function(r) {
			final name = r.matched(1);
			final value = getVariable(name);
			if (value == null)
				return null;
			return "";
		});
	}

	/**
		Return the root path to where versions of `library` should be installed.
	**/
	function getLibRootPath(library:String):String {
		return Path.join([pathByName["haxelib"], library]);
	}

	/**
		Return the path to where `version` of `library` should be installed.
	**/
	function getLibVersionPath(library:String, version:String):String {
		return Path.join([pathByName["haxelib"], library, version.replace(".", ",")]);
	}

	/**
		If `library` has a dev version currently installed,
		return its data, else return null.

		If it is meant to exist but its directory is missing, throws an error.
	 **/
	function getDevLib(library:String):Null<Lib> {
		final devFile = Path.join([getLibRootPath(library), ".dev"]);

		if(!FileSystem.exists(devFile))
			return null;

		final devPath = {
			final content = File.getContent(devFile).trim();
			// environment variables on windows
			final path = ~/%([A-Za-z0-9_]+)%/g.map(content, function(r) {
				final env = Sys.getEnv(r.matched(1));
				return env == null ? "" : env;
			});
			if(isDevPathExcluded(path))
				return null;
			path;
		}
		if(!FileSystem.exists(devPath))
			throw new DevLibraryMissing(library, devPath);

		final version = "";
		final dependencies = [];
		final path = "";

		return {
			version: version,
			path: path,
			dependencies: dependencies,
			vcs: null
		};
	}

	/**
		If the environment variable `HAXELIB_DEV_FILTER` is set,
		returns true if `path` does not start with it or its values.

		Otherwise always returns false.
	**/
	function isDevPathExcluded(path:String):Bool {
		final filters = switch (Sys.getEnv("HAXELIB_DEV_FILTER")) {
			case null:
				return false;
			case filters:
				filters.split(";");
		}

		function normalize(path:String)
			return Path.normalize(path.toLowerCase());

		return !Lambda.exists(filters, function(flt) return normalize(path).startsWith(normalize(flt)));
	}

	function getVariable(name:String):Null<String> {
		final path = pathByName.get(name);
		if (path != null)
			return path;
		return Sys.getEnv(name);
	}

	function getLibDataFromRaw(lib:LibRaw):Lib {
		final dependencies = if (lib.dependencies == null) [] else lib.dependencies;

		final vcs:Null<VCSInfo> =
			if (lib.vcs != null)
				{
					type: lib.vcs.type,
					url: lib.vcs.url,
					ref: lib.vcs.ref,
					branch: lib.vcs.branch
				}
			else null;

		return {
			path: getAbsolute(lib.path),
			version: lib.version,
			dependencies: dependencies,
			vcs: vcs
		};
	}

	/**
		Loads LockFormat map with normalized paths from path
	**/
	function load(path:String):LockFormat {

		final rawText = try {
			sys.io.File.getContent(path);
		} catch(e:Exception){
			throw new Error.FileError(path);
		}

		final content:DynamicAccess<LibRaw> = haxe.Json.parse(rawText);

		final lock:LockFormat = [];
		for (name => lib in content) {
			try {
				lock[name] = getLibDataFromRaw(lib);
			} catch (e:PathParseError) {
				throw 'Could not parse path of library \'${name}\' in lockfile ${path}: \n ${e.message}';
			} catch (_) {
				throw 'Library ${name} in lockfile ${path} does not match format';
			}
		}
		return lock;
	}


	/** Get the path for a library, optionally with a specific version.
		If the resolution method is scoped and the library cannot be found,
		throws an error, otherwise resolve it using `.current` files. **/
/*	public function getLibPath(lib:String, ?version:Null<String>):String{
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
*/

	/** Confirm that the library is available **/
	abstract function confirmLibFlag(data:LibFlagInfo):Bool;

	/**
		Get library data from overrides, or return null if not found
	**/
	abstract function getOverride(name:String):Null<Lib>;

	/**
		Get the current version of the library
	**/
	abstract function getCurrent(name:String):Lib;

}

class ScopedResolver extends Resolver {
	/** lockData from local files **/
	final localLockData:Null<LockFormat>;

	@:allow(haxe.Resolver)
	function new(dir:String, overridePath:Null<String>, ignoreGlobals:Bool) {
		super(dir, overridePath, ignoreGlobals);

		localLockData = load(Path.join([dir, LOCK_FILE]));

		for (i => j in localLockData) {
			trace(i, j.version, j.path);
		}

		checkLocalLibs();

		loadDevLibs(localLockData);
	}

	/** Throw exception if any of the libraries specified in localLockData are missing **/
	function checkLocalLibs():Void {
		for(name => data in localLockData){
			final rootPath = getLibRootPath(name);
			// if it doesn't exist or if it is empty
			if (!FileSystem.exists(rootPath) || FileSystem.readDirectory(rootPath).length == 0)
				throw new LibraryMissing(name);

			final versionPath = getLibVersionPath(name, data.version);
			if(!FileSystem.exists(versionPath))
				throw new LibraryVersionMissing(name, data.version);
		}
	}

	/** Override overrideLockData with dev versions of libraries **/
	function loadDevLibs(lockData:LockFormat):Void {
		final devLockData:LockFormat = [];
		var lib:Lib;
		for (name in lockData.keys()){
			lib = getDevLib(name);

			for(dependency in lib.dependencies)
				if(!localLockData.exists(dependency))
					throw new Error.Error('development version of library $name depends on $dependency which is missing from the current scope');
		}

		overrideLockData.overrideLock(devLockData);
	}

	/** Confirm that the library is installed in the current scope**/
	function confirmLibFlag(data:LibFlagInfo):Bool {
		final lockData = localLockData[data.name];

		trace(data, lockData);
		if(lockData == null)
			// library not in scope
			return false;

		// version is not specified ie: -lib name
		if (data.version == null)
			return true;

		// versions match, has to be number version, not git or hg
		// eg -lib name:1.2.3 will match but -lib name:git won't match
		if (data.version == lockData.version)
			return true;

		// if the names match but not the version, both have to be git or hg
		if (!isVCS(data.version) || lockData.vcs == null)
			return false;

		return matchVCS(data, lockData.vcs);
	}

	function matchVCS(data:LibFlagInfo, vcsinfo:VCSInfo):Bool {
		if(data.url == null)
			return true;
		else if (data.url == vcsinfo.url)
			if(data.ref == null)
				return true;
			else if(data.ref == vcsinfo.ref)
				return false;
		return true;
	}


	function getCurrent(name:String):Lib {
		return localLockData[name];
	}

	function getOverride(name:String):Lib {
		throw new haxe.exceptions.NotImplementedException();
	}
}

class ScopelessResolver extends Resolver {

	@:allow(haxe.Resolver.create)
	function new(dir:String, overridePath:Null<String>, ignoreOverrides:Bool) {
		super(dir, overridePath, ignoreOverrides);
	}

	/** Confirm that the library is installed **/
	function confirmLibFlag(data:LibFlagInfo):Bool {
		return false;
	}

	function getCurrent(name:String):Lib {
		throw new haxe.exceptions.NotImplementedException();
	}

	function getOverride(name:String):Lib {
		throw new haxe.exceptions.NotImplementedException();
	}
}
