package haxe;


import haxe.Exception;

class Error extends Exception {

}

class ArgsError extends Error {


}

class FileError extends Error {
	public function new(path:String){
		super('file at path \'${path}\' not found');
	}
}

class IncompleteOptionError extends ArgsError {

	public function new(arg:String){
		super('option \'${arg}\' needs an argument');
	}

}


function warn(warning:String) {
	Sys.println('Warning: ${warning}');
}


function log(e:Error){
	Sys.println("Error: "+ e.message);
}
