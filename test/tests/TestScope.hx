package tests;

import haxe.LibFlagInfo;
import utest.Test;
import utest.Assert;

import haxe.Resolver;

class TestScope extends Test {
	var scope:Resolver;

	public function setupClass(){
		final path = "test/files";
		scope = Resolver.create(path);
	}

	function testLibFlags(){
		// name

		Assert.notNull(scope.resolveLibFlag(extract("libname")));

		Assert.isNull(scope.resolveLibFlag(extract("missinglib")));

		// versions

		Assert.notNull(scope.resolveLibFlag(extract("libname:1.1.1")));

		Assert.isNull(scope.resolveLibFlag(extract("libname:1.1.2")));
		Assert.isNull(scope.resolveLibFlag(extract("libname:git")));



	}

	function testVCSLibFlags(){
		Assert.notNull(scope.resolveLibFlag(extract("gitlib:git:correct:url")));
		Assert.notNull(scope.resolveLibFlag(extract("gitlib:git:correct:url#branch")));
		Assert.notNull(scope.resolveLibFlag(extract("gitlib:git:correct:url#ref")));

		// wrong version
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:1.1.2")));
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:hg")));
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:hg:correct:url")));

		// wrong url
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:git:incorrect:url")));
		// wrong branch
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:git:correct:url#otherbranch")));
		Assert.isNull(scope.resolveLibFlag(extract("gitlib:git:correct:url#otheref")));

	}


}
