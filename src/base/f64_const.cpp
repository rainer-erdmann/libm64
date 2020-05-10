
#include "..\libm64.h"
#include "..\libm64_int.h"


LOCAL int f64_init();

int test = f64_init();

LOCAL int f64_init() {
	return 1;
}

LOCAL const double TP4H = 0x1.921fb54400000p-1;
LOCAL const double TP4L = 0x1.0b4611a626331p-35;

double pio4(double f) {
	return (f * TP4H) + f * TP4L;
}

