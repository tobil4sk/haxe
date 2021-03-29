/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe;


import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;


using StringTools;

private final IS_WINDOWS = (Sys.systemName() == "Windows");

/**
	Some static methods ripped straight out of haxelib code
**/
class Haxelib {
	static final print = Sys.println;

	static final REPNAME = "lib";
	static final REPODIR = ".haxelib";

	/** Get the repository path, whether it is global or local **/
	public static function getRepository(global = false):String {
		if (!global)
			return switch getLocalRepository() {
				case null: getGlobalRepository();
				case repo: Path.addTrailingSlash(FileSystem.fullPath(repo));
			}
		else
			return getGlobalRepository();
	}

	/** Get the local repository, looking upwards recursively **/
	static function getLocalRepository():Null<String> {
		var dir = Path.removeTrailingSlashes(Sys.getCwd());
		while (dir != null) {
			var repo = Path.addTrailingSlash(dir) + REPODIR;
			if (FileSystem.exists(repo) && FileSystem.isDirectory(repo)) {
				return repo;
			} else {
				dir = new Path(dir).dir;
			}
		}
		return null;
	}

	static function getGlobalRepository():String {
		var rep = getGlobalRepositoryPath(true);
		if (!FileSystem.exists(rep))
			throw "haxelib Repository " + rep + " does not exist. Please run `haxe lib-setup` again.";
		else if (!FileSystem.isDirectory(rep))
			throw "haxelib Repository " + rep + " exists, but is a file, not a directory. Please remove it and run `haxe lib-setup` again.";
		return Path.addTrailingSlash(rep);
	}

	static function getGlobalRepositoryPath(create = false):String {
		// first check the env var
		var rep = Sys.getEnv("HAXELIB_PATH");
		if (rep != null)
			return rep.trim();

		// try to read from user config
		rep = try File.getContent(getConfigFile()).trim() catch (_:Dynamic) null;
		if (rep != null)
			return rep;

		if (!IS_WINDOWS) {
			// on unixes, try to read system-wide config
			rep = try File.getContent("/etc/.haxelib").trim() catch (_:Dynamic) null;
			if (rep == null)
				throw "Package manager not set up. Please run `haxe lib-setup`";
		} else {
			// on windows, try to use haxe installation path
			rep = getWindowsDefaultGlobalRepositoryPath();
			if (create)
				try
					safeDir(rep)
				catch (e:Dynamic)
					throw 'Error accessing Haxelib repository: $e';
		}

		return rep;
	}

	/** The Windows haxe installer will setup %HAXEPATH%. We will default haxelib repo to %HAXEPATH%/lib.
	When there is no %HAXEPATH%, we will use a "haxelib" directory next to the config file, ".haxelib".**/
	static function getWindowsDefaultGlobalRepositoryPath():String {
		var haxepath = Sys.getEnv("HAXEPATH");
		if (haxepath != null)
			return Path.addTrailingSlash(haxepath.trim()) + REPNAME;
		else
			return Path.join([Path.directory(getConfigFile()), "haxelib"]);
	}


	static function getConfigFile():String {
		return Path.addTrailingSlash(getHomePath()) + ".haxelib";
	}

	static function getHomePath():String {
		var home:String = null;
		if (IS_WINDOWS) {
			home = Sys.getEnv("USERPROFILE");
			if (home == null) {
				var drive = Sys.getEnv("HOMEDRIVE");
				var path = Sys.getEnv("HOMEPATH");
				if (drive != null && path != null)
					home = drive + path;
			}
			if (home == null)
				throw "Could not determine home path. Please ensure that USERPROFILE or HOMEDRIVE+HOMEPATH environment variables are set.";
		} else {
			home = Sys.getEnv("HOME");
			if (home == null)
				throw "Could not determine home path. Please ensure that HOME environment variable is set.";
		}
		return home;
	}

	/**  **/
	public static function setup(path:String) {
		var rep = try getGlobalRepositoryPath() catch (_:Dynamic) null;

		var configFile = getConfigFile();

		if (path == "") {
			if (rep == null)
				rep = getSuggestedGlobalRepositoryPath();
			print("Please enter haxelib repository path with write access");
			print("Hit enter for default (" + rep + ")");

			Sys.print("Path : ");
			path = Sys.stdin().readLine();
		}

		if (path != "") {
			var splitLine = path.split("/");
			if (splitLine[0] == "~") {
				var home = getHomePath();

				for (i in 1...splitLine.length) {
					home += "/" + splitLine[i];
				}
				path = home;
			}

			rep = path;
		}

		rep = try FileSystem.absolutePath(rep) catch (e:Dynamic) rep;

		if (isSamePath(rep, configFile))
			throw "Can't use " + rep + " because it is reserved for config file";

		safeDir(rep);
		File.saveContent(configFile, rep);

		print("haxelib repository is now " + rep);
	}

	/** Returns the default repository path **/
	static function getSuggestedGlobalRepositoryPath():String {
		if (IS_WINDOWS)
			return getWindowsDefaultGlobalRepositoryPath();

		return if (FileSystem.exists("/usr/share/haxe")) // for Debian
			'/usr/share/haxe/$REPNAME' else if (Sys.systemName() == "Mac") // for newer OSX, where /usr/lib is not writable
			'/usr/local/lib/haxe/$REPNAME' else '/usr/lib/haxe/$REPNAME'; // for other unixes
	}

}

// other functions from fsutils

/** Checks a directory for write access **/
private function safeDir(dir:String, checkWritable = false):Bool {
	if (FileSystem.exists(dir)) {
		if (!FileSystem.isDirectory(dir)) {
			try {
				// if this call is successful then 'dir' it is not a file but a symlink to a directory
				FileSystem.readDirectory(dir);
			} catch (ex:Dynamic) {
				throw 'A file is preventing the required directory $dir to be created';
			}
		}
		if (checkWritable) {
			var checkFile = dir+"/haxelib_writecheck.txt";
			try {
				sys.io.File.saveContent(checkFile, "This is a temporary file created by Haxelib to check if directory is writable. You can safely delete it!");
			} catch (_:Dynamic) {
				throw '$dir exists but is not writeable, chmod it';
			}
			FileSystem.deleteFile(checkFile);
		}
		return false;
	} else {
		try {
			FileSystem.createDirectory(dir);
			return true;
		} catch (_:Dynamic) {
			throw 'You don\'t have enough user rights to create the directory $dir';
		}
	}
}

/** Returns whether two paths are the same **/
private function isSamePath(a:String, b:String):Bool {
	a = Path.normalize(a);
	b = Path.normalize(b);
	if (IS_WINDOWS) { // paths are case-insensitive on Windows
		a = a.toLowerCase();
		b = b.toLowerCase();
	}
	return a == b;
}
