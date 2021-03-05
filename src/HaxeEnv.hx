class HaxeEnv {


	// commands

	// haxelib command
	final haxelib:String;

	
	public function new(){
		haxelib = "haxelib";

		
	}






	public function runHaxelib(args:Array<String>):String{
		return new sys.io.Process(haxelib, args).stdout.readLine();
	}

}