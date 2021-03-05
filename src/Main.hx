
import haxe.io.Path;

class Main {

	final dir:Path;

	final args:Array<String>;

	final haxeEnv:HaxeEnv;

	/** Array of haxec calls that will be run at the end **/
	final processes:Array<Process>;

	function new(dir:String, args:Array<String>){
		this.dir = new Path(dir);
		this.args = args;

		haxeEnv = new HaxeEnv();

		// get the haxelib library path to set the 'haxelib' environment variable
		var haxelibPath = Sys.getEnv("HAXELIB_LIBRARY_PATH");
		if (haxelibPath == null)
			// get the haxelib library path from haxelib
			haxelibPath = new sys.io.Process("haxelib", ["config"]).stdout.readLine();
		
		Sys.putEnv("haxelib", haxelibPath);

		processes = [];
	}
	
	/**
		Run haxe
	**/
	function run(){
		// expand all .hxml files



		// find libraries

		if (args.contains("--lock-file")) {
			var index = args.indexOf("--lock-file");
			var filePath = args[index + 1];
			trace(index, filePath);
		}


		// resolve all -lib flags



		// separate calls if needed


		// resolve haxec executable
		var haxecPath = "";

		// make calls
		for (call in processes){
			//Sys.command(haxecPath, call.args);
		}
	}

	/**
		Parses a lockfile and if new values are set then overrides old ones
	 */
	function loadLockFile(text:String, vars:Map<String, String>) {}

	/** entry point **/
	static function main():Void {
		var args = Sys.args();
		var dir = Sys.getCwd();

		new Main(dir, args).run();
	}
}
