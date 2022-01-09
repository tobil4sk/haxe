package haxe;

class Error extends Exception {
	public function log() {
		Sys.println("Error: " + message);
	}
}

class FileError extends Error {
	public function new(path:String){
		super('file at path \'${path}\' not found');
	}
}

class ArgsError extends Error {}

class BuildError extends Error {}

function warn(warning:String) {
	Sys.println('Warning: $warning');
}
