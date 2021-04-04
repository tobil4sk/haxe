package haxe;

class BuildCall {
	public var help:Bool = false;
	public var version:Bool = false;
	public final args:Array<String> = [];

	function new(help:Bool, version:Bool, args:Array<String>){
		this.help = help;
		this.version = version;
		this.args = args;
	}

	/** Create an empty call object **/
	public static function createEmpty() {
		return new BuildCall(false, false, []);
	}

	public function reset():Void {
		help = false;
		version = false;
		while (args.length != 0)
			args.pop();
	}

	/** Returns a copy of the build object **/
	public function copy():BuildCall {
		return new BuildCall(help, version, args.copy());
	}

	/** Return a new build call with combined settings of `first` and `other` **/
	public static function combine(first:BuildCall, other:BuildCall){
		return new BuildCall(
			(first.help || other.help),
			(first.version || other.version),
			first.args.concat(other.args)
		);
	}

}
