package tests;

import utest.Assert;
import utest.Test;

import haxe.HXML;

class TestHXML extends Test {
	function testBasic() {
		Assert.same(["-cp", "src", "-m", "Main", "--version"], parseHXML("-cp src \n-m Main\n--version"));

	}

	function testEmpty() {
		Assert.same([], parseHXML(""));
		Assert.same([], parseHXML("\n"));
		Assert.same([], parseHXML("           "));
		Assert.same([], parseHXML("           \n"));
		Assert.same([], parseHXML("\n\n\n\n"));
		Assert.same([], parseHXML("\r\n\r\n"));
	}

	function testWhiteSpaces(){
		// empty lines
		Assert.same(["-cp", "src", "-m", "Main", "--version"], parseHXML("-cp src\n    \n-m Main\n     \n\n"));
		// padded spaces
		Assert.same(["-cp", "src", "-m", "Main", "--version"], parseHXML("     -cp src       \n    \n    -m Main   \n     \n\n"));
		// internal spaces
		Assert.same(["-cp", "src", "-m", "Main", "--version"], parseHXML("-cp      src\n-m     Main\n"));
		Assert.same(["-cp", "src", "-m", "Main", "--version"], parseHXML("           -cp    src  \n    \n      -m Main   \n     \n"));

		// no line end
		Assert.same(["-cp", "src", "-m", "Main"], parseHXML("-cp src \n-m Main"));
	}

	function testQuotes() {

	}

}
