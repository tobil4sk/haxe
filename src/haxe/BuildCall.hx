package haxe;

import haxe.Error.ArgsError;

private class MultipleLibraryVersions extends ArgsError{}

class BuildCall {
	public var help:Bool = false;
	public var version:Bool = false;

	final args:Array<String>;
	/** Array of libraries included, used to keep track and prevent conflicting inclusions **/
	final libs:Map<String, LibFlagInfo>;

	function new(help:Bool, version:Bool, args:Array<String>, ?libs:Map<String, LibFlagInfo>){
		this.help = help;
		this.version = version;
		this.args = args;
		this.libs = if(libs != null) libs else [];
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
		libs.clear();
	}

	/** Returns a copy of the build object **/
	public function copy():BuildCall {
		return new BuildCall(help, version, args.copy());
	}

	/** Return a new build call with combined settings of `first` and `other` **/
	public static function combine(first:BuildCall, other:BuildCall):BuildCall {
		final newCall = new BuildCall(
			(first.help || other.help),
			(first.version || other.version),
			first.args.concat(other.args)
		);

		// add libraries from both call instances
		for(lib in first.libs)
			newCall.addLib(lib);
		for(lib in other.libs)
			newCall.addLib(lib);

		return newCall;
	}

	public function addArg(arg:String):Void {
		args.push(arg);
	}

	public function getArgs():Array<String> {
		return args;
	}

	/** Add lib info to call **/
	public function addLib(info:LibFlagInfo):Void {
		// first ensure the library hasn't already been included
		final current = libs.get(info.name);

		if (current != null) {
			if(info.version != null && current.version != null)
				if (info.version != current.version)
					throw new MultipleLibraryVersions('library \'${info.name}\' has two versions included : ${current.version} and ${info.version}');
				else if(Resolver.isVCS(info.version))
					if(info.url != null && current.url != null)
						if(info.url != current.url)
							throw new MultipleLibraryVersions('library \'${info.name}\' has two ${info.version} versions included from different URLs : ${current.url} and ${info.url}');
						if(info.ref != null && current.ref != null && info.ref != current.ref)
							throw new MultipleLibraryVersions('library \'${info.name}\' has two ${info.version} versions included with different hashes : ${current.ref} and ${info.ref}');
			return;
		}
		// if everything is alright and it isn't already present then add it
		libs[info.name] = info;
	}
}
