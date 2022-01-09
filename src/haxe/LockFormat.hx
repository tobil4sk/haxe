package haxe;

/** Map that stores libraries and their information **/
typedef LockFormat = Map<String, Resolver.Lib>;

function overrideLock(first:LockFormat, other:LockFormat):Void {
	for (name => data in other) {
		first.set(name, data);
	}
}
