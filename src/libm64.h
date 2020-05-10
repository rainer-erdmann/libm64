
#pragma once

// #include <immintrin.h>

#pragma push_macro("SFTYPE")
#undef SFTYPE
#define SFTYPE double

#if _M_X64 > 0
//	x64 is always vectorcall
#define F64_CALL
// #define F64_CALL __vectorcall
#else
//	x86 can be vectorcall or cdecl
#define F64_CALL __vectorcall
// #define F64_CALL __cdecl
#endif



// =====================================================

//	support functions

__declspec (dllexport)
SFTYPE	F64_CALL	fabsd(SFTYPE x);
SFTYPE	F64_CALL	_fabsd(SFTYPE x);
__declspec(dllexport)
// SFTYPE	F64_CALL	copysignd(SFTYPE x, SFTYPE y);
SFTYPE	__vectorcall copysignd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	fdimd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	chgsignd(SFTYPE x);

bool	F64_CALL	signbitd(SFTYPE x);

int		F64_CALL	ilogbd(SFTYPE x);
SFTYPE	F64_CALL	logbd(SFTYPE x);
SFTYPE	F64_CALL	frexpd(SFTYPE x, int* e);

SFTYPE	F64_CALL	ldexpd(SFTYPE x, int e);
// SFTYPE	F64_CALL	ldexpd2(SFTYPE x, int e);
SFTYPE				ldexpd2(SFTYPE x, int e);	// never vcall
SFTYPE	F64_CALL	scalbnd(SFTYPE x, int e);

//	rounding

SFTYPE	F64_CALL	truncd(SFTYPE x);
SFTYPE	F64_CALL	ceild(SFTYPE x);
SFTYPE	F64_CALL	floord(SFTYPE x);
SFTYPE	F64_CALL	roundd(SFTYPE x);
long	F64_CALL	lroundd(SFTYPE x);
long long F64_CALL	llroundd(SFTYPE x);
SFTYPE	F64_CALL	rintd(SFTYPE x);
long	F64_CALL	lrintd(SFTYPE x);
long long F64_CALL	llrintd(SFTYPE x);

//	modulo / remainder

SFTYPE	F64_CALL	modfd(SFTYPE x, SFTYPE *ipart);
SFTYPE	F64_CALL	fmodd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	remainderd(SFTYPE x, SFTYPE y);
//	#### we should also have remquo


//	nextafter & co

SFTYPE	F64_CALL	nexttowardd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	nextafterd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	nextupd(SFTYPE x);
SFTYPE	F64_CALL	nextdownd(SFTYPE x);
SFTYPE	F64_CALL	emptyd(SFTYPE x);

//	sqrt, cbrt, hypot

SFTYPE	F64_CALL	sqrtd(SFTYPE x);
SFTYPE	F64_CALL	sqrtds(SFTYPE x);				// software impl. only for comparison
// SFTYPE	F64_CALL	sqrt_87(SFTYPE x);
SFTYPE				sqrt_87(SFTYPE x);
SFTYPE	F64_CALL	cbrtd(SFTYPE x);
// SFTYPE	F64_CALL	cbrt_87(SFTYPE x);
SFTYPE				cbrt_87(SFTYPE x);
inline
SFTYPE	F64_CALL	cbrtp(SFTYPE x)	{ return cbrt_87(x); };

// SFTYPE	F64_CALL	hypotd(const SFTYPE x, const SFTYPE y);
// SFTYPE	F64_CALL	hypot87(const SFTYPE x, const SFTYPE y);
// SFTYPE	F64_CALL	hypot387(const SFTYPE x, const SFTYPE y, const SFTYPE z);
SFTYPE				hypotd(const SFTYPE x, const SFTYPE y);
SFTYPE				hypot87(const SFTYPE x, const SFTYPE y);
SFTYPE				hypot387(const SFTYPE x, const SFTYPE y, const SFTYPE z);
SFTYPE	F64_CALL	hypot3d(const SFTYPE x, const SFTYPE y, const SFTYPE z);

//	sin, cos, tan

SFTYPE	F64_CALL	sind(SFTYPE x);
//SFTYPE	F64_CALL	sin_87(SFTYPE x);
//SFTYPE	F64_CALL	sin_87n(SFTYPE x);
SFTYPE	sin_87(SFTYPE x);
SFTYPE	sin_87n(SFTYPE x);
SFTYPE	F64_CALL	sinpid(SFTYPE x);
// SFTYPE	F64_CALL	sinpi_87(SFTYPE x);
SFTYPE	sinpi_87(SFTYPE x);
SFTYPE	F64_CALL	sincd(SFTYPE x);
SFTYPE	F64_CALL	sincpid(SFTYPE x);
//SFTYPE	sincpid(SFTYPE x);

SFTYPE	F64_CALL	cosd(SFTYPE x);
// SFTYPE	F64_CALL	cos_87(SFTYPE x);
// SFTYPE	F64_CALL	cos_87n(SFTYPE x);
SFTYPE	cos_87(SFTYPE x);
SFTYPE	cos_87n(SFTYPE x);
SFTYPE	F64_CALL	cospid(SFTYPE x);
// SFTYPE	F64_CALL	cospi_87(SFTYPE x);
SFTYPE	cospi_87(SFTYPE x);

void	F64_CALL	sincosd(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
// void	F64_CALL	sincos_87(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
// void	F64_CALL	sincos_87n(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
void	sincos_87(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
void	sincos_87n(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
void	F64_CALL	sincospid(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
// void	F64_CALL	sincospi_87(SFTYPE x, SFTYPE* sin, SFTYPE* cos);
void	sincospi_87(SFTYPE x, SFTYPE* sin, SFTYPE* cos);

SFTYPE	F64_CALL	tand(SFTYPE x);
SFTYPE	F64_CALL	tanda(SFTYPE x);
// SFTYPE	F64_CALL	tan_87(SFTYPE x);
// SFTYPE	F64_CALL	tan_87n(SFTYPE x);
SFTYPE	tan_87(SFTYPE x);
SFTYPE	tan_87n(SFTYPE x);
SFTYPE	F64_CALL	tanpid(SFTYPE x);
SFTYPE	F64_CALL	tanpi_87(SFTYPE x);

SFTYPE	F64_CALL	cotd(SFTYPE x);
// SFTYPE	F64_CALL	cotda(SFTYPE x);
SFTYPE	cotda(SFTYPE x);
SFTYPE	F64_CALL	cotpid(SFTYPE x);
// SFTYPE	F64_CALL	cot_87n(SFTYPE x);
SFTYPE	cot_87n(SFTYPE x);

SFTYPE	F64_CALL	cscd(SFTYPE x);
SFTYPE	F64_CALL	secd(SFTYPE x);
SFTYPE	F64_CALL	cscpid(SFTYPE x);
/*
SFTYPE		__sinda(SFTYPE x);
SFTYPE		__cosda(SFTYPE x);
SFTYPE		__tanda(SFTYPE x);
SFTYPE		__tandr(SFTYPE x);
*/

//	asin, acos, atan

SFTYPE	F64_CALL	asind(SFTYPE x);
SFTYPE	F64_CALL	__asinda(SFTYPE x);
SFTYPE	F64_CALL	__asindc(SFTYPE x);
SFTYPE	F64_CALL	asin_87(SFTYPE x);
// SFTYPE	F64_CALL	asin_87n(SFTYPE x);
SFTYPE	asin_87n(SFTYPE x);

SFTYPE	F64_CALL	acosd(SFTYPE x);
// SFTYPE	F64_CALL	acos_87(SFTYPE x);
// SFTYPE	F64_CALL	acos_87n(SFTYPE x);
SFTYPE				acos_87(SFTYPE x);
SFTYPE				acos_87n(SFTYPE x);

// SFTYPE	F64_CALL	atand(SFTYPE x);					// aztec method
// SFTYPE	F64_CALL	atan_87(SFTYPE x);
// SFTYPE	F64_CALL	atan_87n(SFTYPE x);
SFTYPE				atand(SFTYPE x);					// aztec method
SFTYPE				atan_87(SFTYPE x);
SFTYPE				atan_87n(SFTYPE x);
SFTYPE	F64_CALL	__atand(SFTYPE x);				// cephes method
SFTYPE				atan2d(SFTYPE u, SFTYPE v);

//	hyperbolic

// SFTYPE	F64_CALL	sinhd(SFTYPE x);
// SFTYPE	F64_CALL	coshd(SFTYPE x);
// SFTYPE	F64_CALL	tanhd(SFTYPE x);
SFTYPE	sinhd(SFTYPE x);
SFTYPE	coshd(SFTYPE x);
SFTYPE	tanhd(SFTYPE x);
// SFTYPE	F64_CALL	sinh_87(SFTYPE x);
// SFTYPE	F64_CALL	cosh_87(SFTYPE x);
// SFTYPE	F64_CALL	tanh_87(SFTYPE x);
SFTYPE				sinh_87(SFTYPE x);
SFTYPE				cosh_87(SFTYPE x);
SFTYPE				tanh_87(SFTYPE x);

SFTYPE	F64_CALL	asinhd(SFTYPE x);
SFTYPE	F64_CALL	acoshd(SFTYPE x);
SFTYPE	F64_CALL	atanhd(SFTYPE x);

// SFTYPE	F64_CALL	asinh_87(SFTYPE x);
// SFTYPE	F64_CALL	acosh_87(SFTYPE x);
// SFTYPE	F64_CALL	atanh_87(SFTYPE x);
SFTYPE	asinh_87(SFTYPE x);
SFTYPE	acosh_87(SFTYPE x);
SFTYPE	atanh_87(SFTYPE x);

SFTYPE	F64_CALL	gd(SFTYPE x);					// gudermannian
SFTYPE	F64_CALL	agd(SFTYPE x);					// gudermannian
SFTYPE	F64_CALL	logistic(SFTYPE x);

// =====================================================

//	log and exp

SFTYPE	F64_CALL	logd(SFTYPE x);
SFTYPE	F64_CALL	logd_(SFTYPE x);				// plauger version
SFTYPE	F64_CALL	__logdc(SFTYPE x);				// cephes version
SFTYPE	F64_CALL	__logda(SFTYPE x);				// aztec version
SFTYPE	F64_CALL	__logds(SFTYPE x);				// sun version uCLib
// SFTYPE	F64_CALL	log_87(SFTYPE x);			
// SFTYPE	F64_CALL	log_87n(SFTYPE x);			
SFTYPE	log_87(SFTYPE x);			
SFTYPE	log_87n(SFTYPE x);			

SFTYPE	F64_CALL	log1pd(SFTYPE x);
// SFTYPE	F64_CALL	log1p_87(SFTYPE x);			
// SFTYPE	F64_CALL	log1p_87n(SFTYPE x);			
SFTYPE	log1p_87(SFTYPE x);			
SFTYPE	log1p_87n(SFTYPE x);			

SFTYPE	F64_CALL	log2d(SFTYPE x);			
// SFTYPE	F64_CALL	log2_87(SFTYPE x);			
// SFTYPE	F64_CALL	log2_87n(SFTYPE x);			
SFTYPE	log2_87(SFTYPE x);			
SFTYPE	log2_87n(SFTYPE x);			

SFTYPE	F64_CALL	log10d(SFTYPE x);			
// SFTYPE	F64_CALL	log10_87n(SFTYPE x);			
SFTYPE	log10_87n(SFTYPE x);			


SFTYPE	F64_CALL	expd(SFTYPE x);					// aztec version
SFTYPE	F64_CALL	expds(SFTYPE x);
SFTYPE	F64_CALL	__expdc(SFTYPE x);				// cephes version
SFTYPE	F64_CALL	__expds(SFTYPE x);				// sun version
SFTYPE	F64_CALL	__expdr(SFTYPE x);				// erdi version

// SFTYPE	F64_CALL	exp_87(SFTYPE x);				// x87
// SFTYPE	F64_CALL	exp_87n(SFTYPE x);				// x87
SFTYPE	exp_87(SFTYPE x);				// x87
SFTYPE	exp_87n(SFTYPE x);				// x87

// SFTYPE	F64_CALL	expm1d(SFTYPE x);				// erdi version
// SFTYPE	F64_CALL	expm1_87(SFTYPE x);				
SFTYPE	expm1d(SFTYPE x);				// erdi version
SFTYPE	expm1_87(SFTYPE x);				

// SFTYPE	F64_CALL	exp2d(SFTYPE x);				// erdi version
SFTYPE	exp2d(SFTYPE x);				// erdi version
SFTYPE	F64_CALL	exp2ds(SFTYPE x);				// erdi version
// SFTYPE	F64_CALL	exp2_87(SFTYPE x);				// x87
// SFTYPE	F64_CALL	exp2_87n(SFTYPE x);				// x87
SFTYPE	exp2_87(SFTYPE x);				// x87
SFTYPE	exp2_87n(SFTYPE x);				// x87

SFTYPE	F64_CALL	expx2d(SFTYPE x);
// SFTYPE	F64_CALL	expx2_87(SFTYPE x);				// x87
SFTYPE	expx2_87(SFTYPE x);				// x87
SFTYPE	F64_CALL	expx2(SFTYPE x);				// emul of $ms

SFTYPE	F64_CALL	exp10d(SFTYPE x);				// erdi version
// SFTYPE	F64_CALL	exp10_87(SFTYPE x);				// x87
SFTYPE	exp10_87(SFTYPE x);				// x87

SFTYPE	F64_CALL	powd(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	__powd(SFTYPE x, SFTYPE y);


SFTYPE	F64_CALL	ipowd(int i, int n);
// SFTYPE ipow32(int i, int n);
SFTYPE	F64_CALL	pownd(SFTYPE x, int yi);
SFTYPE	F64_CALL	powpind(int k, int yi);
SFTYPE	F64_CALL	powphind(int yi);

SFTYPE	F64_CALL	rootd(SFTYPE x, int n);
SFTYPE	F64_CALL	root(SFTYPE x, int n);

//	special functions
//	error function and friends

SFTYPE	F64_CALL	erfd(SFTYPE x);
SFTYPE	F64_CALL	erfcd(SFTYPE x);

SFTYPE	F64_CALL	erf_c(SFTYPE x);
SFTYPE	F64_CALL	erfc_c(SFTYPE x);

SFTYPE	F64_CALL	erfcxd(SFTYPE x);
SFTYPE	F64_CALL	erfinvd1(SFTYPE x);
SFTYPE	F64_CALL	erfinvd(SFTYPE x);
SFTYPE	F64_CALL	erfcinvd(SFTYPE x);
SFTYPE	F64_CALL	erfid(SFTYPE x);

SFTYPE	F64_CALL	dawson(SFTYPE x);		// D+(x)
SFTYPE	F64_CALL	dawsonm(SFTYPE x);		// D-(x)

//	bessel 

SFTYPE	F64_CALL	j0d(SFTYPE x);
SFTYPE	F64_CALL	j1d(SFTYPE x);
SFTYPE	F64_CALL	jnd(int n, SFTYPE x);

SFTYPE	F64_CALL	y0d(SFTYPE x);
SFTYPE	F64_CALL	y1d(SFTYPE x);
SFTYPE	F64_CALL	ynd(int n, SFTYPE x);

SFTYPE	F64_CALL	j0dc(SFTYPE x);
SFTYPE	F64_CALL	y0dc(SFTYPE x);
SFTYPE	F64_CALL	j1dc(SFTYPE x);
SFTYPE	F64_CALL	y1dc(SFTYPE x);

SFTYPE	F64_CALL	j0dv(SFTYPE x);
SFTYPE	F64_CALL	y0dv(SFTYPE x);
SFTYPE	F64_CALL	j1dv(SFTYPE x);
SFTYPE	F64_CALL	y1dv(SFTYPE x);

//	modified bessel

SFTYPE	F64_CALL	i0(SFTYPE x);
SFTYPE	F64_CALL	i1(SFTYPE x);
SFTYPE	F64_CALL	i0e(SFTYPE x);
SFTYPE	F64_CALL	i1e(SFTYPE x);

SFTYPE	F64_CALL	k0(SFTYPE x);
SFTYPE	F64_CALL	k1(SFTYPE x);
SFTYPE	F64_CALL	k0e(SFTYPE x);
SFTYPE	F64_CALL	k1e(SFTYPE x);

SFTYPE	F64_CALL	i0d(SFTYPE x);
SFTYPE	F64_CALL	i1d(SFTYPE x);
SFTYPE	F64_CALL	ind(int n, SFTYPE x);

SFTYPE	F64_CALL	k0d(SFTYPE x);
SFTYPE	F64_CALL	k1d(SFTYPE x);
SFTYPE	F64_CALL	knd(int n, SFTYPE x);

//	spherical bessel

SFTYPE	F64_CALL	SphericalBesselj0(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselj1(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselj2(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselj3(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselj4(const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBesselj(int n, const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBessely0(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBessely1(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBessely2(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBessely3(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBessely4(const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBessely(int n, const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBesseli0(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesseli1(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesseli2(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesseli3(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesseli4(const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBesseli(int n, const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBesselk0(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselk1(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselk2(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselk3(const SFTYPE& x);
SFTYPE	F64_CALL	SphericalBesselk4(const SFTYPE& x);

SFTYPE	F64_CALL	SphericalBesselk(int n, const SFTYPE& x);


//	arithmetic geometric mean
SFTYPE	F64_CALL	agm(SFTYPE x, SFTYPE y);
SFTYPE	F64_CALL	ghm(SFTYPE x, SFTYPE y);

//	
SFTYPE	F64_CALL	hyper_2F1(double a, double b, double c, double x);

//	lambertw
SFTYPE	F64_CALL	lambertw(int k, SFTYPE x);

//	integrals

SFTYPE	F64_CALL	Ei(SFTYPE x);
SFTYPE	F64_CALL	li(SFTYPE x);

SFTYPE	F64_CALL	sinint_si(SFTYPE x);
SFTYPE	F64_CALL	cosint_ci(SFTYPE x);
SFTYPE	F64_CALL	cosint_cin(SFTYPE x);
SFTYPE	F64_CALL	FresnelS(SFTYPE x);
SFTYPE	F64_CALL	FresnelC(SFTYPE x);

SFTYPE	F64_CALL	comp_ellint_1d(SFTYPE x);
SFTYPE	F64_CALL	comp_ellint_2d(SFTYPE x);
SFTYPE	F64_CALL	comp_ellint_3d(SFTYPE n, SFTYPE m);

SFTYPE	F64_CALL	ellipticK(SFTYPE x);
SFTYPE	F64_CALL	ellipticE(SFTYPE x);
SFTYPE	F64_CALL	ellipticPi(SFTYPE n, SFTYPE m);


//	lgamma, tgamma 

SFTYPE	F64_CALL	lgammad(SFTYPE x);
SFTYPE	F64_CALL	lgammad2(SFTYPE x);
SFTYPE	F64_CALL	tgammad(SFTYPE x);
SFTYPE	F64_CALL	tgammam1d(SFTYPE x);

SFTYPE	F64_CALL	betad(SFTYPE x, SFTYPE y);

SFTYPE	F64_CALL	digamma(SFTYPE x);
SFTYPE	F64_CALL	polygamma(int n, SFTYPE x);

SFTYPE	F64_CALL	dilog(SFTYPE x);
SFTYPE	F64_CALL	rogers_dilog(SFTYPE x);
SFTYPE	F64_CALL	polylog(int n, SFTYPE x);

SFTYPE	F64_CALL	debyeD1(int n, SFTYPE x);
SFTYPE	F64_CALL	debyeD2(int n, SFTYPE x);


//	specfun integer sequences

//	primes
int factor(unsigned __int64 v, char* s);		// prime factorization
bool isprime(unsigned __int64 v);
unsigned __int64 prime(unsigned int n);				// nth prime
unsigned int nextprime(unsigned int n);
unsigned int nextprime(unsigned int n, int dir);
unsigned __int64 primetwin(unsigned int n);			// nth prime twin
unsigned __int64 primetwinnext(unsigned int n);
void primetriple(unsigned int* r, unsigned int n);
void primequad(unsigned int* r, unsigned int n);


//	factorials

SFTYPE	F64_CALL	factd(int n);
SFTYPE	F64_CALL	factd(int n, int ex);
SFTYPE	F64_CALL	factd(int n, int* ex);
SFTYPE	F64_CALL	dfactd(int n);
SFTYPE	F64_CALL	dfactdc(int n);
SFTYPE	F64_CALL	dfactd(int n, int ex);

SFTYPE	F64_CALL	factquod(int n, int k);
SFTYPE	F64_CALL	fibonaccid(int n);

SFTYPE	F64_CALL	belld(int n);
SFTYPE	F64_CALL	bellcd(int n);
SFTYPE	F64_CALL	lucasd(int n);
SFTYPE	F64_CALL	cataland(int n);
SFTYPE	F64_CALL	pelld(int n);


SFTYPE	F64_CALL	binomiald(int n, int k);
SFTYPE	F64_CALL	binomiald(SFTYPE n, int k);
SFTYPE	F64_CALL	binomiald(SFTYPE n, SFTYPE k);
SFTYPE	F64_CALL	pochhammerd(SFTYPE x, int n);
SFTYPE	F64_CALL	pochhammerd(int x, int n);

//	bernoulli, zeta, stieltjes

SFTYPE	F64_CALL	bernd(int n);
SFTYPE	F64_CALL	zetad(int n);
SFTYPE	F64_CALL	zetad(SFTYPE n);
SFTYPE	F64_CALL	zetacd(SFTYPE n);
SFTYPE	F64_CALL	etad(SFTYPE n);
SFTYPE	F64_CALL	lambdad(SFTYPE n);
SFTYPE	F64_CALL	hzeta(SFTYPE a, SFTYPE s);
SFTYPE	F64_CALL	hzeta(int n, SFTYPE z);
SFTYPE	F64_CALL	bernoullimodd(int n);
SFTYPE	F64_CALL	eulerd(int n);

SFTYPE	F64_CALL	stieltjesd(int n);

//	polynomials
//	laguerre, legendre, hermite

SFTYPE	F64_CALL	laguerred(int n, SFTYPE x);
SFTYPE	F64_CALL	assoc_laguerred(int n, int a, SFTYPE x);
SFTYPE	F64_CALL	legendred(int n, SFTYPE x);
SFTYPE	F64_CALL	assoc_legendred(int n, int a, SFTYPE x);
SFTYPE	F64_CALL	hermited(int n, SFTYPE x);
SFTYPE	F64_CALL	hermiteHed(int n, SFTYPE x);

SFTYPE	F64_CALL	legendreQd(int n, SFTYPE x);

SFTYPE	F64_CALL	bpoly(int n, SFTYPE x);




//	** internal **

// SFTYPE	F64_CALL	fmad(SFTYPE a, SFTYPE b, SFTYPE c);
SFTYPE	fmad(SFTYPE a, SFTYPE b, SFTYPE c);
// SFTYPE fma4ds(SFTYPE a, SFTYPE b, SFTYPE c);
// void fma3d(SFTYPE& a, SFTYPE& b, SFTYPE& c);
// SFTYPE fma4d(const SFTYPE& a, const SFTYPE& b, const SFTYPE& c);
// SFTYPE	F64_CALL	fma4d(SFTYPE a, SFTYPE b, SFTYPE c);
SFTYPE	fma4d(SFTYPE a, SFTYPE b, SFTYPE c);
// SFTYPE fma4dx(SFTYPE& a, SFTYPE& b, SFTYPE& c);

//	statistics

struct meand {

	SFTYPE a1[2];
	SFTYPE a2[2];

	struct neumaier& s1 = (neumaier&)a1;
	struct neumaier& s2 = (neumaier&)a2;

	int n;

	void reset();
	int sum(SFTYPE v, bool reset);
	int sum(SFTYPE v);
	SFTYPE mean() const;				// mean
	SFTYPE dev() const;					// standard deviation
	SFTYPE devs() const;				// sample standard deviation
};


struct it1d {

	SFTYPE a1[2];
	struct neumaier& s1 = (neumaier&)a1;
	SFTYPE tc;

	it1d() = delete;

	it1d(SFTYPE t) {
		tc = t;
	};	

	void reset();
	SFTYPE sum(SFTYPE v, bool reset);
	SFTYPE sum(SFTYPE v);

	SFTYPE val() const;					// mean
	operator SFTYPE() const;
};


// int isnand(SFTYPE x);
// int _isnand(SFTYPE x);
// int isfinited(SFTYPE x);


int		F64_CALL	fpclassd(SFTYPE x);
// int fpclassd_(SFTYPE x);

// ordered compares
bool	F64_CALL	cmp_olt(SFTYPE a, SFTYPE b);
bool	F64_CALL	cmp_ole(SFTYPE a, SFTYPE b);
bool	F64_CALL	cmp_ogt(SFTYPE a, SFTYPE b);
bool	F64_CALL	cmp_oge(SFTYPE a, SFTYPE b);

// ordered compare of abs(a)
bool	F64_CALL	cmp_olta(SFTYPE a, SFTYPE b);

//	we want to use the compilers fabs
//	without including "math.h" here 
//	this is the way it works
extern "C" SFTYPE fabs(SFTYPE);
#pragma intrinsic(fabs)

__forceinline
SFTYPE	F64_CALL	fabsd(SFTYPE x) {
	return fabs(x);
}

#pragma float_control(precise, on, push)  

// #pragma float_control(precise, off, push)  

/*
[C99 standard macros:]
#include <math.h>
int fpclassify(real-floating x );
int isfinite(real-floating x );
int isinf(real-floating x );
int isnan(real-floating x );
int isnormal(real-floating x );
*/

#if 0
#if _M_X64 > 0
bool isfinited(SFTYPE x);
#else
bool __vectorcall isfinited(SFTYPE x);
#endif

#else
#pragma optimize( "gty", on )
__forceinline static
bool isfinited(SFTYPE x) {
// int isfinited(SFTYPE x) {
#if 0
//	SFTYPE y = fabsd(x);
//	return (U64(y) < U64(D_INF));
//	return fabsd(x) < D_INF;
//	return D_INF > fabsd(x);
//	return (x - x) == 0.0;
	return int(x-x) == 0;		// seems this is fastest
//  but is also not idependend of float_control;
//	is sometimes optimized away...
//	#### that is not what we want to get ####
#else
//	__m128d y = _mm_load1_pd(&x);
//	y = _mm_sub_sd(y, y);
//	int i = _mm_cvttsd_i32(y);
//	return i == 0;

//	so gehts auch mit floatcontrol precise
	double z = x - x;
	return (z == z);
#endif
}
#pragma optimize( "", on )
#endif


#if 1
#if _M_X64 > 0
bool isnand(SFTYPE x);
#else
bool __vectorcall isnand(SFTYPE x);
#endif
#else
#pragma optimize( "gty", on )
__forceinline static
bool isnand(SFTYPE x) {

	extern SFTYPE D_INF;
	
//  this works correctly; but not if float_control precise is off!
//	return !(x <= D_INF);		// 3.5..4
//	this works also if float_control precise is off; but we cannot be sure
	return !(D_INF >= x);
//	this works also correctly; but not if float_control precise is off!
//	return x != x;
}
#pragma optimize( "", on )
#endif

bool __vectorcall isinfd(SFTYPE x);

#if 0
//	this works independent of float_control
__forceinline static
bool isinfd(SFTYPE x) {

	extern SFTYPE D_INF;
	return fabsd(x) == D_INF;
}
#endif

bool	F64_CALL	islessd(SFTYPE a, SFTYPE b);
bool	F64_CALL	islessequald(SFTYPE a, SFTYPE b);
bool	F64_CALL	isgreaterd(SFTYPE a, SFTYPE b);
bool	F64_CALL	isgreaterequald(SFTYPE a, SFTYPE b);
bool	F64_CALL	islessgreaterd(SFTYPE a, SFTYPE b);
bool	F64_CALL	isunorderedd(SFTYPE a, SFTYPE b);

//	not part of C99
__forceinline static
bool	F64_CALL	iszerod(SFTYPE x) {

	return x == 0.0;
}

bool	F64_CALL	isinteger(SFTYPE x);
extern "C" double trunc(double);

__forceinline
bool	F64_CALL	isinteger(double x) {
	return (x - trunc(x)) == 0;
}

bool	F64_CALL	isintegerd(SFTYPE x);

//	C99
__forceinline static
bool	F64_CALL	isnormald(SFTYPE x) {

	union du {
		SFTYPE d;
		unsigned __int64 u;
	};
	du& v = (du&)x;

	int ex = (v.u >> 52) & 0x7ff;
	return (ex > 0 && ex < 0x7ff);
}



#pragma float_control(pop)  

#pragma pop_macro("SFTYPE")
