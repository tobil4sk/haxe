private typedef Library = {
	var name:String;
	var version:String;
	var path:String;
}


/** Holds all of the information for a haxec call **/
class Build {

	final libraries:Array<Library>;
	public final args:Array<String>;

	function new(){
		libraries = [];
		args = [];
	}

	/**
		Run the haxec call
	**/
	public function run(){

	}

	/**
		Returns a copy of the build, copying its scope and compiler flags
	**/
	public function clone():Build{
		var newProcess = new Build();
		for (lib in libraries)
			newProcess.libraries.push(lib);
		for (arg in args)
			newProcess.args.push(arg);
		return newProcess;
	}

}
