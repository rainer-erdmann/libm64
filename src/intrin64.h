//
//	resemble some of the most often used 
//	x64 intrinsics for x86
//	less for performance, but for convencience

#pragma once

#include <types.h>
#include <intrin.h>

#ifndef _M_X64

#ifndef U32H
#define U32H(x) (((u32*)&x)[1])
#endif
#ifndef U32L
#define U32L(x) (((u32*)&x)[0])
#endif

inline
u8 _addcarry_u64(u8 cy, u64 a, u64 b, u64* sum) {
	u8 c;
	c = _addcarry_u32(cy, U32L(a), U32L(b), &U32L(sum));
	c = _addcarry_u32(c,  U32H(a), U32H(b), &U32H(sum));
	return c;
}

inline
u8 _subborrow_u64(u8 cy, u64 a, u64 b, u64* sum) {
	u8 c;
	c = _subborrow_u32(cy, U32L(a), U32L(b), &U32L(sum));
	c = _subborrow_u32(c,  U32H(a), U32H(b), &U32H(sum));
	return c;
}

//	mod 20200111
__declspec(dllexport)
inline
u64 __shiftleft128(u64 l, u64 h, u8 n) {

	u64 r;

	if (n < 32) {
		r = __ll_lshift(h, n) | __ull_rshift(U32H(l), 32-n);
	} else {
//		r = __ll_lshift(U32L(h), n-32) | __ull_rshift(l, 64-n);
//		r = __ll_lshift(h, n); //  | __ull_rshift(l, 64-n);
		U32H(r) = (U32L(h) << (n-32)) | (U32H(l) >> (64-n));
		U32L(r) = (U32H(l) << (n-32)) | (U32L(l) >> (64-n));
	}
	return r; 
}



//	mod 20200111
__declspec(dllexport)
inline
u64 __shiftright128(u64 l, u64 h, u8 n) {

	u64 r;

	if (n < 32) {
//		r = __ull_rshift(l, n) | __ll_lshift(U32L(h), 32-n);
		r = __ull_rshift(l, n) | (__ll_lshift(h, 32-n) << 32);
	} else {
		r = __ull_rshift(U32H(l), n-32) | __ll_lshift(h, 64-n);
	}
	return r; 
}

inline
u64 __lzcnt64(u64 v) {

	u32 n = __lzcnt(U32H(v));
	if (n == 32) {
		n += __lzcnt(U32L(v));
	}
	return n;
}

inline
char _BitScanReverse64(unsigned long* shift, u64 v) {

	u32 idx;

	char c = _BitScanReverse((unsigned long*)&idx, U32H(v));
	if (c) {
		*shift = idx + 32;
	} else {
		c = _BitScanReverse((unsigned long*)&idx, U32L(v));
		if (c) {
			*shift = idx;
		}
	}
	return c;
}

inline
u8 __popcnt64(u64 v) {
//	return __popcnt64f(v);
	return __popcnt(U32H(v)) + __popcnt(U32L(v));
}

#endif
