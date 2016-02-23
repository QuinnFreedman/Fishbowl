module util;

template utilities(T) {
	@nogc @safe nothrow
	T bound(T a, T lowerBound, T upperBound) {
		if(a < lowerBound) {
			return lowerBound;
		}

		if(a > upperBound) {
			return upperBound;
		}

		return a;
	}

	pure nothrow @nogc @safe 
	T max(T a, T b) {
		return a > b ? a : b;
	}
	pure nothrow @nogc @safe 
	T min(T a, T b) {
		return a < b ? a : b;
	}
}

alias boundf = utilities!(float).bound;
alias boundi = utilities!(int).bound;
alias bound = utilities!(int).bound;
alias max = utilities!(int).max;
alias min = utilities!(int).min;