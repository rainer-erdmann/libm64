
#include "..\libm64.h"
#include "..\libm64_int.h"

//	important for NAN
#pragma float_control(precise, on)

struct id64 {
	union {
		double d64;
		u64 v64;
		u32 v32[2];
	};
	operator double() { return d64; };
};

//	#### not correct for x = +/- NAN 
double __vectorcall nextupd_(double x) {
#if 0
	id64& v = (id64&)x;

	if (x > 0) {
		if (v.v64 < 0x7ff00000'00000000)
			++v.v64;
	} else if (x < 0) {
		if (v.v64 <= 0xfff00000'00000000)
			--v.v64;
	} else {	// x == +/-0
		v.v64 = 0x01;
	}
	return v;
#elif 0
	u64 v = *(u64*)&x;
	if (x > 0) {
		if (v < 0x7ff00000'00000000)
			++v;
	} else if (x < 0) {
		if (v <= 0xfff00000'00000000)
			--v;
	} else {	// x == +/-0
		v = 0x01;
	}
	return *(double*)& v;
#else
	__m128x xx = _mm_load_sd(&x);
	if (x > 0) {
		if (x < D_INF) {
			xx = _mm_sub_epi64(xx, _mm_cmpeq_epi16(xx, xx));
		}
	} else if (x < 0) {
		if (x >= -D_INF) {
			xx = _mm_add_epi64(xx, _mm_cmpeq_epi16(xx, xx));
		}
	} else {
		if (x == x) {	// means x == 0
			xx = _mm_cvtsi32_si128(1);
		}		
	}
	return (double)xx;
#endif
}


double __vectorcall nextdownd_(double x) {
#if 0
	id64& v = (id64&)x;

	if (x > 0) {
		if (v.v64 <= 0x7ff00000'00000000)
			--v.v64;
	} else if (x < 0) {
		if (v.v64 < 0xfff00000'00000000)
			++v.v64;
	} else {	// x == +/-0
		v.v64 = 0x01;
		v.d64 = -v.d64;
	}
	return v;
#else
	__m128x xx = _mm_load_sd(&x);
	if (x > 0) {
		if (x <= D_INF) {
			xx = _mm_add_epi64(xx, _mm_cmpeq_epi16(xx, xx));
		}
	} else if (x < 0) {
		if (x > -D_INF) {
			xx = _mm_sub_epi64(xx, _mm_cmpeq_epi16(xx, xx));
		}
	} else {
		if (x == x) {
			xx = _mm_cvtsi32_si128(1);
			xx.d.m128d_f64[0] = -xx.d.m128d_f64[0]; 
		}
	}
	return (double)xx;
#endif
}


double __vectorcall _nextafterd(double x, double y) {

	double v;
	if (y > x) {
		v = nextupd(x);
	} else if (y < x) {
		v = nextdownd(x);
	} else {
		if (x != x) v = x;
		else v = y;
	}
	return v;
}
