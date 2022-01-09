import utest.Runner;
import utest.ui.Report;

import tests.*;

function main() {
	final runner = new Runner();
	runner.addCase(new TestHXML());
	runner.addCase(new TestScope());
	Report.create(runner);

	runner.run();

}
