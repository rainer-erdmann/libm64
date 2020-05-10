
// #include <types.h>
#include "..\libm64.h"
#include "..\libm64_int.h"

#define SFTYPE double

// important
#pragma float_control(precise, on, push)  

#define FLT64_MANT_DIG 53

//	can also be written as:
//	hi = x * x;
//	lo = fma(x, x, -hi)
//	but only if we have a real fma!

//	the assy x87 version does not give exactly the same result;
//	it only gives 11+1bit of lo


//	not that slow...
void sqr_splitf64a(SFTYPE& hi, SFTYPE& lo, SFTYPE& x) {

	// Apply Dekker's algorithm.
	hi = x * x;
# define C ((1LL << (FLT64_MANT_DIG + 1) / 2) + 1)
	SFTYPE x1 = x * C;
# undef C
	x1 = (x - x1) + x1;
	SFTYPE x2 = x - x1;
	lo = (((x1 * x1 - hi) + x1 * x2) + x2 * x1) + x2 * x2;
}


// this method is a little bit faster than a)
// slower than x87 but fully precise
// in assy we tested the mask should be ..ff'f8
void sqr_splitf64c_(SFTYPE& hi, SFTYPE& lo, SFTYPE& x) {

	hi = x * x;
	SFTYPE x1, x2;

//	x1 = (SFTYPE)(float)x;
	x1 = x; U64(x1) &= 0xffffffff'fc000000;
	x2 = x - x1;
	lo = (((x1 * x1 - hi) + x1 * x2) + x2 * x1) + x2 * x2;
}



void 
mul_splitf64a(SFTYPE& hi, SFTYPE& lo, SFTYPE& x, SFTYPE& y) {
	// Apply Dekker's algorithm.
	hi = x * y;
# define C ((1LL << (FLT64_MANT_DIG + 1) / 2) + 1)
	SFTYPE x1 = x * C;
	SFTYPE y1 = y * C;
# undef C
	x1 = (x - x1) + x1;
	y1 = (y - y1) + y1;
	SFTYPE x2 = x - x1;
	SFTYPE y2 = y - y1;
	lo = (((x1 * y1 - hi) + x1 * y2) + x2 * y1) + x2 * y2;
}


extern "C" double fma(double a, double b, double c);
#if 0
void sqr_splitf64b(SFTYPE& hi, SFTYPE& lo, SFTYPE& x) {

	hi = x * x;
	lo = fma(x, x, -hi);

	return;






// without handling of lo this is already slower than a)

	u64 e = U64(x) >> 52;

	u64 a = (U64(x) & 0x000fffff'ffffffff) | 0x00100000'00000000;

	u64 h, l;
	l = _umul128(a, a, &h);

	int n = nlz64(h);
	h = __shiftleft128(l, h, n-11);
	h = (h & 0x000fffff'ffffffff);
	
	h |= (e + e - 0x3ff) << 52;

	lo = 0;
	U64(hi) = h;
}
#endif

#pragma float_control(pop)  
