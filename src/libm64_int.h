
#include <types.h>
#include <intrin.h>
// #include <immintrin.h>
#include <emmintrin.h>

#define ENA_FMA 0
#define F64_ENA_FMA 0
#define F64_SIMD 1


// extern int useFMA;
// extern int useAVX2;
extern bool useFMA;
extern bool useAVX2;

#define FACT_USE_TABLE 1
#define BERN_USE_TABLE 1

#undef SFTYPE
#define SFTYPE double

#define PUBLIC 
#define LOCAL static 

void printfx(const char* _Format, ...);

// extern assy helper
extern SFTYPE tgammax(SFTYPE x, int i);

#define U64(x) (*(u64*)&x)
#define D64(x) (*(double*)&x)


#ifndef U32H
#define U32H(x) (((u32*)&x)[1])
#endif
#ifndef U32L
#define U32L(x) (((u32*)&x)[0])
#endif


struct __m128x {
	union {
		__m128i i;
		__m128d d;
	};

#if 1

	__m128x() {};
	__forceinline __m128x(double x)	{ *this = x; };
	__forceinline __m128x(i64 x)		{ i.m128i_i64[0] = i.m128i_i64[1] = x; };
	__forceinline __m128x(u64 x)		{ i.m128i_u64[0] = i.m128i_i64[1] = x; };
	__forceinline __m128x(__m128d x)	{ d = x; };

//	__m128d& operator=(double x)  { return d = _mm_loaddup_pd(&x); };  // immer noch die beste variante
	__forceinline __m128d& operator=(double x)  { return d = _mm_load_sd(&x); };
																	   
//	__m128x& operator=(double x)  { d = _mm_loaddup_pd(&x); return *this; };  // oder so, kein unterschied
//	__m128d& operator=(double x)  { return d = _mm_loadl_pd(d, &x); };  // auch scheisse
//	__m128d& operator=(double x) { return d = _mm_load_pd(&x); };  // compound
//	__m128d& operator=(double x)  { return d = _mm_set_sd(x); };
//	__m128d& operator=(double x)  { d.m128d_f64[0] = x; return d; };
//	__m128i& operator=(i64 x)	  { return i = _mm_set1_epi64x(x); };
//	__m128i& operator=(u64 x) { return i = _mm_set1_epi64x(x); };
	__forceinline __m128d& operator=(__m128d o) { return d = o; };
	__forceinline __m128i operator=(__m128i o) { return i = o; };

//	__forceinline operator __m128d() const { return d; };
	__forceinline operator __m128d() { return d; };
	__forceinline operator __m128i() { return i; };
//	operator double() const { return d.m128d_f64[0]; };
	__forceinline
	operator double() const { return _mm_cvtsd_f64(d); };

	//	operator u64() { return _mm_cvtsi128_si64(i); }; // DONT DO IT!

#endif

};

/*
__forceinline
__m128x operator +(__m128x a, __m128x b) { return _mm_add_pd(a, b); };
__forceinline
__m128x operator -(__m128x a, __m128x b) { return _mm_sub_pd(a, b); };
__forceinline
__m128x operator *(__m128x a, __m128x b) { return _mm_mul_pd(a, b); };
__forceinline
__m128x sqr(__m128x a) { return a * a; };

__forceinline
__m128x operator *(__m128x a, double b) { return _mm_mul_sd(a, *(__m128d*)&b); };
*/


// general useful constants
extern const SFTYPE C05;
extern const SFTYPE C10;
extern const SFTYPE C20;

extern SFTYPE D_INF;
extern SFTYPE D_NAN;

extern SFTYPE PID;
extern SFTYPE PIO2;
extern SFTYPE PIO4;
extern SFTYPE TOPI;		// 2/pi
extern SFTYPE FOPI;		// 4/pi


extern SFTYPE LN2H;
extern SFTYPE LN2L;
extern SFTYPE LN2HS;
extern SFTYPE LN2LS;

// more special constants

// 2 / sqrt(pi)
extern SFTYPE TOSPI;

// euler gamma 0.57721 - euler mascheroni also y0 = stieljes[0]
extern SFTYPE EUGAM;

// log(sqrt(2PI))
extern SFTYPE LS2PI;
extern SFTYPE LS2PIH;
extern SFTYPE LS2PIL;

// extern assy POLY0(x) using x87
SFTYPE POLY0X(SFTYPE x, const SFTYPE p[], int n);
// extern assy POLY0(x^2) using x87
SFTYPE POLY0X2(SFTYPE x, const SFTYPE p[], int n);
// extern assy POLY0(x^2) using x87
SFTYPE POLY0X2M1(SFTYPE x, const SFTYPE p[], int n);

// extern assy POLY0(x) using AVX2 FMA
SFTYPE POLY0FA(SFTYPE x, const SFTYPE p[], int n);

#define MM_SHUF(a, b, c, d) ((a<<0)+(b<<2)+(c<<4)+(d<<6))

//	extended prec modular
//	(x - xn * f.hi) - xn * f.lo;
LOCAL __forceinline SFTYPE
EPMsub(SFTYPE x, __m128d f, SFTYPE xn) {
#if _M_X64 > 0
//	__m128x r = _mm_loaddup_pd(&xn);
	__m128x r;
	r.d = _mm_loaddup_pd(&xn);
#else
	__m128x r = _mm_set1_pd(xn);
#endif
#if 0
	r = _mm_mul_pd(r, f);
	x -= (double)r;
	r = _mm_shuffle_epi32(r, MM_SHUF(2,3,0,1));
	x -= (double)r;
#else
	r.d = _mm_mul_pd(r.d, f);
	x -= _mm_cvtsd_f64(r.d);
	r.i = _mm_shuffle_epi32(r.i, MM_SHUF(2,3,0,1));
//	r.d = _mm_shuffle_pd(r.d, r.d, 1);
	x -= _mm_cvtsd_f64(r.d);
#endif
	return x;
}



/* Evaluate P[n] x^n  +  P[n-1] x^(n-1)  +  ...  +  P[0] */
//	uncond use FMA
LOCAL __forceinline SFTYPE
POLY0F(SFTYPE x, const SFTYPE p[], int n) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_loaddup_pd(&p[n]);
	for (int i = n - 1; i >= 0; --i) {
		y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[i]));
	}
	return y.m128d_f64[0];
}


LOCAL __forceinline SFTYPE
POLY0F12(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_load_sd(&p[12]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[11]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[10]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[9]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[8]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[7]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[6]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}

LOCAL __forceinline SFTYPE
POLY0F12(__m128d xd, const SFTYPE p[]) {

	__m128d y  = _mm_load_sd(&p[12]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[11]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[10]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[9]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[8]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[7]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[6]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}



LOCAL __forceinline SFTYPE
POLY0F8(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_load_sd(&p[8]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[7]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[6]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}

LOCAL __forceinline SFTYPE
POLY0F7(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_load_sd(&p[7]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[6]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}

LOCAL __forceinline SFTYPE
POLY0F6(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_load_sd(&p[6]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}

LOCAL __forceinline SFTYPE
POLY0F5(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_load_sd(&p[5]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[0]));
	return y.m128d_f64[0];
}

//	Evaluate P[n] x^n  +  P[n-1] x^(n-1)  +  ...  +  P[0]
//	uncond not using FMA
LOCAL __forceinline SFTYPE
POLY0S(SFTYPE x, const SFTYPE p[], int n) {

	SFTYPE y = p[n];

	for (int i = n - 1; i >= 0; --i) {
		y = y * x + p[i];
	}
	return y; 
}



//	Evaluate P[n] x^n  +  P[n-1] x^(n-1)  +  ...  +  P[0]
//	cond use FMA
LOCAL __forceinline SFTYPE
POLY0(SFTYPE x, const SFTYPE p[], int n) {

//	extern int hasFMA;

	if (useFMA) {
		__m128d xd = _mm_loaddup_pd(&x);
		__m128d y  = _mm_loaddup_pd(&p[n]);
		for (int i = n - 1; i >= 0; --i) {
			y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[i]));
		}
		return y.m128d_f64[0];
 
	} else {
		SFTYPE y = p[n];

		for (int i = n - 1; i >= 0; --i) {
			y = y * x + p[i];
		}
		return y; 
	}
}


#if 0

//	uncond use FMA
__declspec(dllexport)
SFTYPE
__forceinline
fma64(SFTYPE a, SFTYPE b, SFTYPE c) {

	__m128d y = _mm_fmadd_sd(_mm_loaddup_pd(&a), _mm_loaddup_pd(&b), *(__m128d*)&c); 
//	__m128d y = _mm_fmadd_sd(_mm_load_sd(&a), _mm_load_sd(&b), *(__m128d*)&c); 
	return y.m128d_f64[0];
}

__declspec(dllexport)
SFTYPE
__forceinline
fms64(SFTYPE a, SFTYPE b, SFTYPE c) {

	__m128d y = _mm_fmsub_sd(_mm_loaddup_pd(&a), _mm_loaddup_pd(&b), *(__m128d*)&c); 
	return y.m128d_f64[0];
}

__declspec(dllexport)
SFTYPE
__forceinline
fnma64(SFTYPE a, SFTYPE b, SFTYPE c) {

	__m128d y = _mm_fnmadd_sd(_mm_loaddup_pd(&a), _mm_loaddup_pd(&b), *(__m128d*)&c); 
//	__m128d y = _mm_fmadd_sd(_mm_load_sd(&a), _mm_load_sd(&b), *(__m128d*)&c); 
	return y.m128d_f64[0];
}

__declspec(dllexport)
SFTYPE
__forceinline
fnms64(SFTYPE a, SFTYPE b, SFTYPE c) {

	__m128d y = _mm_fnmsub_sd(_mm_loaddup_pd(&a), _mm_loaddup_pd(&b), *(__m128d*)&c); 
	return y.m128d_f64[0];
}

#endif

#if 0

#define DE __declspec(dllexport)
#define FI __forceinline

DE FI __m128x fma64(__m128x a, __m128x b, __m128x c) {
	return _mm_fmadd_sd(a, b, c);
}

DE FI __m128x fma64(__m128x a, __m128x b, double c) {
	return _mm_fmadd_sd(a, b, *(__m128d*)&c);
}

DE FI __m128x fma64(__m128x a, double b, __m128x c) {
	return _mm_fmadd_sd(a, _mm_load_sd(&b), c);
}

#undef DE
#undef FI

#endif





LOCAL SFTYPE
POLY1(SFTYPE x, const SFTYPE coef[], int n) {

	SFTYPE r = coef[n] + x;
	for (int i = n-1; i >= 0; --i) {
		r = r * x + coef[i];
	}
	return r;
}


// Evaluate P[n] x^n  +  P[n-1] x^(n-1)  +  ...   
// without the last step
__forceinline
LOCAL SFTYPE
POLY0M1 (SFTYPE x, const SFTYPE p[], int n) {

	SFTYPE y;
	
	y = p[n];

	for (int i = n - 1; i >= 1; --i) {
		y = y * x + p[i];
	}
	return y; 
}

// =====================================



LOCAL __forceinline SFTYPE
POLY0M1F7(SFTYPE x, const SFTYPE p[]) {

	__m128d xd = _mm_loaddup_pd(&x);
	__m128d y  = _mm_loaddup_pd(&p[7]);
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[6]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[5]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[4]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[3]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[2]));
	y = _mm_fmadd_sd(y, xd, *(__m128d*)(&p[1]));
	return y.m128d_f64[0];
}

//	fmadd_sd	a*b+c
//	fmsub_sd	a*b-c
//	nfmadd_sd	-a*b+c
//	nfmsub_sd	-a*b-c


//	the compiler does not unroll the loop
//	so we use the switch/case which is 
//	optimized away for constant n
__forceinline
static double POLY0K(double x, const __m128d coef[], int n) {

	__m128x x2;
	__m128x xn;
	__m128x r;

	xn = _mm_set_sd(x);
//	xn = _mm_shuffle_epi32(xn, MM_SHUF(0,1,0,1));
//	xn = _mm_unpacklo_pd(xn, xn);
	xn = _mm_shuffle_pd(xn, xn, 0);
	x2 = _mm_mul_pd(xn, xn);
#if 0
	int nh = n / 2;
	r  = _mm_load_pd((double*)&coef[nh]);
	for (int i = nh-1; i >= 0; --i) { 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[i]);
	}
#else
	switch (n) {
	case 0: case 1:
		r  = _mm_load_pd((double*)&coef[0]); 
		break;
	case 2: case 3:
		r  = _mm_load_pd((double*)&coef[1]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 4: case 5:
		r  = _mm_load_pd((double*)&coef[2]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 6: case 7:
		r  = _mm_load_pd((double*)&coef[3]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 8: case 9:
		r  = _mm_load_pd((double*)&coef[4]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 10: case 11:
		r  = _mm_load_pd((double*)&coef[5]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 12: case 13:
		r  = _mm_load_pd((double*)&coef[6]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 14: case 15:
		r  = _mm_load_pd((double*)&coef[7]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[6]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 16: case 17:
		r  = _mm_load_pd((double*)&coef[8]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[7]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[6]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 18: case 19:
		r  = _mm_load_pd((double*)&coef[9]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[8]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[7]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[6]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 20: case 21:
		r  = _mm_load_pd((double*)&coef[10]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[9]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[8]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[7]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[6]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	case 22: case 23:
		r  = _mm_load_pd((double*)&coef[11]); 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[10]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[9]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[8]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[7]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[6]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[5]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[4]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[3]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[2]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[1]);
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[0]);
		break;
	}
#endif
//	#### should use a shufpd here
	x2 = _mm_shuffle_epi32(r, (2<<0) + (3<<2) + (0<<4) + (1<<6));
	x2 = _mm_mul_sd(x2, xn);
	r  = _mm_add_sd(r, x2);
	return (double)r;
}

/*
__forceinline
static double POLY0K(double x, const double coefd[], int n) {

	__m128x x2;
	__m128x xn;
	__m128x r;
	__m128d* coef = (__m128d*)coefd;

	xn = _mm_set_sd(x);
	xn = _mm_shuffle_epi32(xn, MM_SHUF(0,1,0,1));
	x2 = _mm_mul_pd(xn, xn);
	int nh = n / 2;
	r  = _mm_load_pd((double*)&coef[nh]);
	for (int i = nh-1; i >= 0; --i) { 
		r  = _mm_mul_pd(r, x2);
		r  = _mm_add_pd(r, coef[i]);
	}
	x2 = _mm_shuffle_epi32(r, (2<<0) + (3<<2) + (0<<4) + (1<<6));
	x2 = _mm_mul_sd(x2, xn);
	r  = _mm_add_sd(r, x2);
	return (double)r;
}
*/


LOCAL
int nlz64(u64 a) {
#ifdef _M_X64
	int n; char c;
	c = _BitScanReverse64((u_long*)&n, (u64)a);
	if (c) return 63 - n;
	return 64;
#else
	int n; char c;
	c = _BitScanReverse((u_long*)&n, U32H(a));
	if (c) return 31 - n;
	c = _BitScanReverse((u_long*)&n, U32L(a));
	if (c) return 63 - n;
	return 64;
#endif
}

#if 0
LOCAL __declspec(noinline)
int ilogbd_dz(SFTYPE x) {

	if (!(U64(x) << 1)) {
		return 0x80000000;
	} else {
// #### something to do here...

		return -2048;

	}
}
#endif

#if 0
__forceinline 
LOCAL
int ilogbd(SFTYPE x) {

	u64 ex = ((U64(x) >> 52) & 0x7ff);

	if (ex) {
		return (int)(ex - 0x3ff);
	} else { // DEN or ZERO
		return - 2048;
	}
}
#else

#endif

__forceinline 
int c_ilogb(const SFTYPE& x) {

	int ex = ((U64(x) >> 52) & 0x7ff) - 0x3ff;
	return ex;
}

//	we want to have it inlined
__forceinline static
double c_frexp(const double x, int* e) {

	__m128x xl = x;
	u64 ex = (xl.i.m128i_u64[0] >> 52) & 0x7ff;

	if (0 < ex && ex < 0x7ff) {	
	// no ZERO, DEN, INF, NAN
		ex -= 0x3fe;
		*e = (int)ex;	
#ifdef _M_X64
		xl.i = _mm_sub_epi64(xl, _mm_cvtsi64_si128(ex << 52));		
#else
		xl.i = _mm_sub_epi64(xl, _mm_slli_epi64(_mm_cvtsi32_si128((int)ex), 52));
#endif
		return xl.d.m128d_f64[0];
	} else {
//		double frexpd(double, int*);
		return frexpd(x, e);
	}
}

//	we want to have it inlined
__forceinline static
double c_frexp_bmi(const double x, int* e) {

	__m128x xl = x;
	u64 ex = (xl.i.m128i_u64[0] >> 52) & 0x7ff;

	if (0 < ex && ex < 0x7ff) {	
	// no ZERO, DEN, INF, NAN
		ex -= 0x3fe;
		*e = (int)ex;	
#ifdef _M_X64
		xl.i = _mm_sub_epi64(xl, _mm_cvtsi64_si128(ex << 52));		
#else
		xl.i = _mm_sub_epi64(xl, _mm_slli_epi64(_mm_cvtsi32_si128((int)ex), 52));
#endif
		return xl.d.m128d_f64[0];
	} else {
//		double frexpd(double, int*);
		return frexpd(x, e);
	}
}


__forceinline static
// void c_ldexp(double& x, int n) {
double c_ldexp(double x, int n) {
#if 0
	__m128i y;
	y = _mm_cvtsi32_si128(n);
	y = _mm_slli_epi64(y, 52);
	y = _mm_add_epi16((__m128i&)x, y);
//	U64(x) = y.m128i_u64[0];
	(__m128i&)x = y;
#else
	__m128x y = _mm_load_sd(&x);
	__m128x z;
	z = _mm_cvtsi32_si128(n);
	z = _mm_slli_epi64(z, 52);
	z = _mm_add_epi16(y, z);
	return (double)z;
#endif
}


__forceinline static
double fma4(double a, double b, double c) {

	return a * b + c;
}

// ASSY x87
void sqr_splitf64(SFTYPE& hi, SFTYPE& lo, SFTYPE& x);
// ASSY
void sqr_splitf64c(SFTYPE& hi, SFTYPE& lo, SFTYPE& x);

// ASSY FMA
void sqr_splitf64f(SFTYPE& hi, SFTYPE& lo, SFTYPE& x);


// ASSY
void mul_splitf64(SFTYPE& hi, SFTYPE& lo, SFTYPE& x, SFTYPE& y);


/*
struct d64ex {

	double hi;
	double lo;

	d64ex() {};
	d64ex(double x);

	explicit operator double() const;
};
*/

__forceinline LOCAL
SFTYPE sqr(SFTYPE x)		{	return x * x;	};

// inline SFTYPE sqrt(SFTYPE x)	{	return sqrtd(x);	};

__forceinline LOCAL
void swap(SFTYPE& x, SFTYPE& y) {
	SFTYPE t = x; x = y; y = t;
}

__forceinline LOCAL
SFTYPE max(SFTYPE x, SFTYPE y) {

	return x > y ? x : y;
}


//	extern assy using x87
#ifdef _M_X64
double __root_f64b(double, int n);
#else
double __vectorcall __root_f64b(double, int n);
#endif


extern const __m128x m7ff;

#if 0
__declspec(dllexport)
__forceinline
double copysignd(double x, double y) {
#if 1
//	12 SAN x86
	__m128x z = x;
	__m128x yy = y;
	yy = _mm_andnot_pd(m7ff, yy);
	z = _mm_and_pd(z, m7ff);
	z = _mm_or_pd(z, yy);
	return (double)z;
#else
//	25 SAN
	U32H(x) = U32H(x) & 0x7fffffff;
	U32H(x) |= U32H(y) & 0x80000000;
	return x;
#endif
}
#endif


#ifdef _M_X64
// ok; but cvtsd2si returns 0x80000000 on positive overflow!!
__forceinline static
long lrintd(double x) {
//	__m128x y = x;							
	__m128x y;
	y.d = _mm_load_sd(&x);
	return _mm_cvtsd_si32(y);
}
#endif

#if 0
__forceinline
long long llrintd(double x) {
#ifdef _M_X64
	__m128x y = x;							
	return _mm_cvtsd_si64(y);
#else
	__asm {
		fld  qword ptr [x]
		fist qword ptr [x]
		mov eax, dword ptr [x]
		mov edx, dword ptr [x+4]
	}
#endif
}
#endif

#if 0
#ifdef _M_X64
//	trunc always rounds toward zero 
// __declspec(dllexport)
LOCAL
__forceinline
double truncd(double x) {

	__m128x y;
	y = x;
	y = _mm_round_pd(y, _MM_FROUND_TRUNC);
	return y;
}

__forceinline
double ceild(double x) {

	__m128x y = x;
	y = _mm_round_pd(y, _MM_FROUND_CEIL);			// SSE4 - erst core 2 wolfdale ~2008
	return y;
}


__forceinline
double floord(double x) {

	__m128x y = x;
	y = _mm_round_pd(y, _MM_FROUND_FLOOR);
	return y;
}

// __declspec(dllexport)
LOCAL
__forceinline
double rintd(double x) {

	__m128x y = x;
	y = _mm_round_pd(y, _MM_FROUND_NINT);
	return y;
}

#endif
#endif

