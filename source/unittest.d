module unit_test;

import std.stdio;
import pile;

void test() {
	writeln();
	writeln("Starting tests...");
	pileTemplate!(int).Pile* testpile = new pileTemplate!(int).Pile(10);
	int[] test = new int[20];

	for(int i = 0; i < 20; i++) {
		testpile.add(i);
		test[i] = i;
	}

	assert(testpile.size() == 20);

	for(int i = 0; i < 20; i++) {
		assert(testpile.contains(i));
	}

	testpile.itr_start();
	while(testpile.itr_hasNext()) {
		if(testpile.itr_next() % 2 == 0) {
			testpile.itr_remove();
		}
	}
	testpile.itr_done();

	test = [1,3,5,7,9,11,13,15,17,19];
	for(int i = 0; i < test.length; i++) {
		assert(testpile.contains(test[i]));
	}
	assert(!testpile.contains(2));
	assert(!testpile.contains(4));
	assert(!testpile.contains(10));

	pileTemplate!(int).Pile* test2 = new pileTemplate!(int).Pile(2);
	//one-hundred million
	int NUMBER = 10000000;
	for(int i = 0; i < NUMBER; i++) {
		test2.add(i);
	}

	int k = 0;
	test2.itr_start();
	while(test2.itr_hasNext()) {
		if(test2.itr_next() % 2 == 0) {
			test2.itr_remove();
		}
		k++;
	}
	test2.itr_done();

	test2 = new pileTemplate!(int).Pile(2);
	for(int i = 0; i < 100; i++) {
		test2.add(i);
	}
	/*i = 0;
	test2.itr_start();
	while(test2.itr_hasNext()) {
		assert(2 * i == test2.itr_next());
		i++;
	}
	test2.itr_done();*/

	for(int j = 1; j < 100; j+=2) {
		assert(test2.contains(j));
	}

	writeln();
	writeln("Tests finished");
	writeln();
}
