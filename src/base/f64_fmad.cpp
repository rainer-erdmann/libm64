
#include "..\libm64.h"
#include "..\libm64_int.h"

// #include <stdlib.h>

__declspec(align(16))
union {
	u64 u[2];
} K = {
	0x0fffffffff8000000, 0x0fffffffff8000000 
};

#if 0
void swap(double a, double b) {
	double t = a;
	a = b; b = t;
}
#endif

typedef double T;

struct neumaier {

	T s;
	T c;

	neumaier() {};

	neumaier& operator =(T v) {	
		s = v; c = 0; return *this;
	};

	neumaier& operator+=(T v) { 
#if 0  // original
		float t;
		t = s + v;
		if (fabsd(s) >= fabsd(v)) {
			c += (s - t) + v;
		} else {
			c += (v - t) + s;
		}
		s = t; 
#endif

#if 1  // modified
		T t;
		t = s + c + v;
#if 1
		if (fabsd(s) >= fabsd(v)) {
			c += (s - t) + v;
		} else {
			c += (v - t) + s;
		}
		s = t; 
#else
		if (fabs(s) >= fabs(v)) {
			swap(s, v);
		}
		c += (v - t) + s;
		s = t;
#endif
#endif
		return *this;
	}

	operator T() {
		return s + c;
	}
};


struct neumaier2 {

	T s;
	T c;

	neumaier2() {};

	neumaier2& operator =(T v) {	
		s = v; c = 0; return *this;
	};

	neumaier2& operator+=(T v); /* { 
		T t;
		t = s + c + v;
		if (fabsd(s) >= fabsd(v)) {
			c += (s - t) + v;
		} else {
			c += (v - t) + s;
		}
		s = t; 
		return *this;
	} */

	operator T() {
		return s + c;
	}
};



struct kahan {

	T s;
	T c;

	kahan() {};

	kahan& operator =(T v) {	
		s = v; c = 0; return *this;
	};

	kahan& operator+=(T v) { 
		T t, y;
		y = v - c;	
		t = s + y;

		c = (t - s) - y;
		s = t;
		return *this;
	}

	operator T() {
		return s + c;
	}
};


int fmatrace = 0;

//	this is the maximum precision
//	with "normal" methods
//	with neumaier we get the same as hardware fma
//	with double we get not the same
//	so - the add ops..
//	with neumaier: +/-0.50ulps
//	exactly +/-0.50000ulps
//	with kahan: +/-1.00ulps
//	with double: +/-1.8ulps straight add
//	with double: +/-1.4ulps second term common add
double fma5d(double x, double y, double z) {

	double xl, xh, yl, yh;
	neumaier r;
//	neumaier2 r;
//	kahan r;
//	double r;
//	RAHH - intrinsics

	xh = _mm_cvtsd_f64(_mm_and_pd(_mm_load_sd(&x), *(__m128d*)&K));
	xl = x - xh;
	yh = _mm_cvtsd_f64(_mm_and_pd(_mm_load_sd(&y), *(__m128d*)&K));
	yl = y - yh;

	r = z;
	r += xh * yh;
	r += xh * yl;
	r += xl * yh;
//	r += (xh * yl) + (xl * yh); // also possible
	r += xl * yl;
	return (double)r;
}


