module util;

import Dgame.Graphic.Color;
import std.random;
import std.math;

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
alias maxf = utilities!(float).max;
alias minf = utilities!(float).min;

class Gradient {
	private Color4b a;
	private Color4b b;
	this(Color4b _a, Color4b _b) {
		a = _a;
		b = _b;
	}

	Color4b lerp(float f, float min, float max) {
		float t = f / (max - min);
		return lerp(t);
	}

	Color4b lerp(float t) {
		//assert(t >= 0 && t <= 1, "invalid input");
		t = boundf(t, 0, 1);
		return Color4b(
			cast(ubyte)(boundf(a.red + (b.red - a.red) * t, 0, 255)),
			cast(ubyte)(boundf(a.green + (b.green - a.green) * t, 0, 255)),
			cast(ubyte)(boundf(a.blue + (b.blue - a.blue) * t, 0, 255))
		);
	}
}

float normalize(float x, float min, float max) {
	assert(min < max);
	return (x - min)/(max - min) * 2 - 1;
}

/* 
 * normal random variate generator
 * from http://www.taygeta.com/random/boxmuller
 * mean m, standard deviation s 
 */
float box_muller(float m, float s)	{
	float x1, x2, w, y1;
	static float y2;
	static int use_last = 0;

	if (use_last) // use value from previous call 
	{
		y1 = y2;
		use_last = 0;
	}
	else
	{
		do {
			x1 = uniform(-1.0, 1.0);
			x2 = uniform(-1.0, 1.0);
			w = x1 * x1 + x2 * x2;
		} while ( w >= 1.0 );

		w = sqrt( (-2.0 * log( w ) ) / w );
		y1 = x1 * w;
		y2 = x2 * w;
		use_last = 1;
	}

	return( m + y1 * s );
}