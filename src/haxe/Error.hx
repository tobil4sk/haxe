package haxe;


import haxe.Exception;

class Error extends Exception {

}

class LibraryMissing extends Exception {
	public function new(lib:String, scoped=true) {
		var errorString = 'Library ${lib} not installed in current scope : run \'haxelib install ${lib}\'';

		if(!scoped)
			errorString = 'Library ${lib} not installed : run \'haxelib install ${lib}\'';

		super(errorString);
	}
}

class LibraryVersionMissing extends Exception {
	public function new(lib:String, version:String, scoped = true) {
		var errorString = 'Library ${lib} version ${version} not installed in current scope';

		if (!scoped)
			errorString = 'Library ${lib} version ${version} not installed';

		super(errorString);
	}
}


class FileError extends Error {
	public function new(path:String){
		super('file at path \'${path}\' not found');
	}
}

class ArgsError extends Error {}

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
