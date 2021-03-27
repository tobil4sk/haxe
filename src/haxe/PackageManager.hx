package haxe;

/**
	Class
**/
class PackageResolver {
	// paths to commands
	// haxe compiler path
	//var haxeCompiler:String;

	// path to the package manager executable
	final packageManagerCmd:String;

	final vars:Map<String, String>;

	public function new(){
		// package manager specifics
		// could possibly be changed to look in a config file to support other package managers
		packageManagerCmd = Sys.getEnv("HAXEPATH") + "/haxelib";
		// the name of the variable that is set to the pm's library path
		var libPathVar = "haxelib";


		// get the library path to set the 'haxelib' environment variable
		var libPath = Sys.getEnv("HAXELIB_LIBRARY_PATH");
		if (libPath == null)
			// get the haxelib library path from haxelib
			libPath = runPackageManager(["config"]);


		vars = [];
		vars[libPathVar] = libPath;
	}

	function runPackageManager(args:Array<String>):String{
		return new sys.io.Process(packageManagerCmd, args).stdout.readLine();
	}

}
