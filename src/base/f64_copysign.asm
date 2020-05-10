;
;	FILENAME :        f64_copysign.asm          
;
;	DESCRIPTION :
;		double copysignd(double u, double v)
;		double chgsignd(double u)
;		bool signbitd(double u)
;
;		assembly module written for MASM/NASM
;
;	AUTHOR :    Rainer Erdmann
;
;	Copyright 2016-2019 Rainer Erdmann
;
;	License: see accompanying file license.txt
;
;	CHANGES :
;
;	REF NO  VERSION DATE		WHO			DETAIL
;
	IFDEF @Version
	INCLUDE common.masm
	ELSE
	INCLUDE 'common.nasm'
	ENDIF

	IMPORT M7FF, ?M7FF@@3XA
	IMPORT M800, ?M800@@3XA

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

ENTRY signbitd
ENTRY signbitd, YA_NN@Z

	psrlq	xmm0, 63
	movd	eax, xmm0
	ret


ENTRY chgsignd, YANN@Z
ENTRY chgsignd, YQNN@Z
ENTRY _chgsignd, YANN@Z
ENTRY _chgsignd, YQNN@Z

	xorpd	xmm0, [M800]
	ret


;	double copysignd(double, double)
ENTRY copysignd, YANNN@Z
ENTRY copysignd, YQNNN@Z

	xorpd	xmm0, xmm1
	andpd	xmm0, [M7FF]
	xorpd	xmm0, xmm1
	ret

FUNC ENDP

	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 

	.code

;	vectorcall
ENTRY signbitd
ENTRY signbitd, YQ_NN@Z

	psrlq	xmm0, 63
	movd	eax, xmm0
	ret

;	cdecl
ENTRY signbitd, YA_NN@Z

	mov		eax, _D [ARGS+4]
	shr		eax, 31
	ret


;	double __cdecl 
ENTRY copysignd, YANNN@Z

;	6.4..7.5 SAN
	fld		_Q [ARGS]
	mov		eax, [ARGS+4]
	xor		eax, [ARGS+4+8]
	jns		.ret
	fchs
.ret: 
	ret


;"double __vectorcall copysignd(double, double)" 
ENTRY copysignd, YQNNN@Z

	; 5 SAN correct
	pxor	xmm0, xmm1
	pand	xmm0, [M7FF]
	pxor	xmm0, xmm1
	ret


;	double __vectorcall
ENTRY _chgsignd, YQNN@Z

	xorpd	xmm0, [M800]
	ret

;	double __cdecl 
ENTRY _chgsignd, YANN@Z

	fld		_Q [ARGS]
	fchs
	ret

FUNC ENDP

	ENDIF

END
