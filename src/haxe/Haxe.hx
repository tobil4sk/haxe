package haxe;
import haxe.io.Path;

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

	/** Run lib-setup, part of haxelib **/
	public function libSetup(args:Array<String>){
		trace(args, args.length);

		final path = switch (args.length){
		case 0: "";
		case 1: args[0];
		case _: throw new Error.ArgsError('lib-setup expects a maximum of one argument');
		}

		trace(path);

		Haxelib.setup(path);
	}

	/**
		Run a haxe building command with `args` as arguments with which to run it.
	**/
	public function build(argsArray:Array<String>):Void {
		final args = new Args(argsArray);

		// check for --cwd first
		final buildDir = switch(args.getSpecialArg("cwd")){
			case null: dir;
			case path: path;
		};

		// get the absolute path for the override path, if specified.
		final overridePath = switch(args.getSpecialArg("lock-file")){
			case null: null;
			case path if(!Path.isAbsolute(path)): Path.join([buildDir, path]);
			case absolutePath: absolutePath;
		};
		final resolver = new Resolver(buildDir, overridePath);


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
				process.libSetup(args.slice(1));
			} else {
				process.build(args);
			}
		} catch (e:Error) {
			Error.log(e);
		}
	}
}
