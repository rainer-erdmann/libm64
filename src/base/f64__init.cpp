
#include "..\libm64.h"
#include "..\libm64_int.h"


/*
	our minimum x86 platform 'SDE'
	means the x86 code could would run on a PM
cpu features:
     SSE     yes
     SSE2    yes
     SSE3    no
     SSSE3   no
     SSE41   no
     SSE42   no
     FMA     no
     MOVBE   no
     AVX     no
     RDRAND  no
     AVX2    no
     BMI1    no
     BMI2    no
     RDSEED  no
     LZCNT   no

	our minimum x64 platform 'P4P'
	means the x64 code would run on a prescott
cpu features:
     SSE     yes
     SSE2    yes
     SSE3    yes
     SSSE3   no
     SSE41   no
     SSE42   no
     FMA     no
     MOVBE   no
     AVX     no
     RDRAND  no
     AVX2    no
     BMI1    no
     BMI2    no
     RDSEED  no
     LZCNT   no
*/

void init_sse41(int v);

int f64_init();
int local = f64_init();					// force call to f64_init

bool hasSSE41 = 0;
bool hasAVX   = 0;
bool hasAVX2  = 0;
bool hasFMA   = 0;
extern bool hasPOPCNT= 0;

bool useSSE41 = 0;
bool useAVX   = 0;
bool useAVX2  = 0;
bool useFMA   = 0;


u8 bit(int v, int b) {

	return (v & (1 << b)) != 0;
}

//	we decode only the features we need
//	in f32 and f64

__declspec(noinline)
int f64_init() {

	int regs[4];
	enum {  EAX = 0, EBX = 1, ECX = 2, EDX = 3, };

	__cpuidex(regs, 0x01, 0);
	hasSSE41 = bit(regs[ECX], 19);

	hasPOPCNT = bit(regs[ECX], 23);

	hasFMA =  (regs[ECX] >> 12) & 0x01;

	hasAVX =  (regs[ECX] >> 28) & 0x01;

	__cpuidex(regs, 0x07, 0);
	hasAVX2 =  (regs[EBX] >> 5) & 0x01;


	useSSE41 = hasSSE41;
	useAVX2  = hasAVX2;
	useAVX   = hasAVX;
	useFMA   = hasFMA;

	return 1;
}
