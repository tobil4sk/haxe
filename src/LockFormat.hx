import haxe.ds.Either;

typedef Lib = {
	var version:String;
	var path:String;
	var dependencies:Either<Array<String>, Array<Lib>>;
}

typedef LockFormat = Map<String, Lib>;

/**
Loads a LockFormat map from a json object
**/
function load(content:Dynamic):LockFormat {
	var lock:LockFormat = [];
	for (field in Reflect.fields(content)){
		lock[field] = Reflect.field(content, field);
	}
	return lock;
}
