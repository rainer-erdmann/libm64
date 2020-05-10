;
;	FILENAME :        f64_poly.asm          
;
;	DESCRIPTION :
;		different methods to calculate polynomials
;		 - SSE scalar double
;		 - SSE packed double
;		 - FMA scalar double
;		 - FMA packed double
;		 - x87
;		these routines were intended to test the 
;		different methods
;
;		assembly module written for MASM/NASM
;		x86 and x64 code
;
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

	IFDEF _M_X64								; 64bit

	.code

;	SSE scalar only, use a single result reg

;"double __cdecl APOLY0(double,double * const,int)" (?APOLY0@@YANNQEANH@Z)
ENTRY APOLY0, YANNQEANH@Z

;	shl		r8, 3
	movsd	xmm1, _X [rdx+r8*8]	; r = coef[n] 
	sub		r8, 1
	jc		.done

.lp:
	mulsd	xmm1, xmm0
	addsd	xmm1, _Q [rdx+r8*8]
	sub		r8, 1
	jnc		.lp

.done:
	movdqa	xmm0, xmm1

	ret

;	SSE scalar only, use 2 result regs
;	does not reduce the number of ops,
;	but the two result sets can be calculated 
;	in parallel; 
;	gives almost the performance of the K version
;	uses 4 regs total
ENTRY APOLY0P, YANNQEANH@Z

;	mov	ebx, 111
;	db 64h, 67h, 90h
	btr		r8, 0

	movdqa	xmm3, xmm0
	mulsd	xmm3, xmm3
	movsd	xmm2, [rdx+r8*8+8]
	movsd	xmm1, [rdx+r8*8]
	sub		r8, 2
	jc		.done3

.lp3:
	mulsd	xmm2, xmm3
	addsd	xmm2, [rdx+r8*8+8]
	mulsd	xmm1, xmm3
	addsd	xmm1, [rdx+r8*8]
	sub		r8, 2
	jnc		.lp3
.done3:
	mulsd	xmm0, xmm2
	addsd	xmm0, xmm1
;	mov	ebx, 222
;	db 64h, 67h, 90h
	ret

;	loopless 
ENTRY APOLY0P3, YANNQEANH@Z

	movdqa	xmm3, xmm0
	mulsd	xmm3, xmm3
	movsd	xmm2, [rdx+2*8+8]
	movsd	xmm1, [rdx+2*8]

	mulsd	xmm2, xmm3
	addsd	xmm2, [rdx+0*8+8]
	mulsd	xmm1, xmm3
	addsd	xmm1, [rdx+0*8]

	mulsd	xmm0, xmm2
	addsd	xmm0, xmm1
	ret



	.data
ONE dq 1.0
	.code

;	packed version - opted
;	float domain inst instead of pshufd
;	gives 0.5 cy faster
;	movddup, avx mul, no r8 shift
;	together gives 0.5..1.5 cy faster
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0K2, YANNQEAU__m128d@@H@Z

;	overhead
;	movddup SSE3 1/1
;	pshufd  SSE 1/0.5
	movddup	xmm1, xmm0					; x
	vmulpd	xmm2, xmm1, xmm1			; x2 = x * x
;	overhead end
	btr		r8, 0

	movdqa	xmm0, _X [rdx+r8*8]	; r = coef[n] 
	sub		r8, 2
	jc		.done

.lp:
	mulpd	xmm0, xmm2
	addpd	xmm0, _X [rdx+r8*8]
	sub		r8, 2
	jnc		.lp

.done:
;	overhead	
	movhlps	xmm2, xmm0
	mulsd	xmm2, xmm1				; *x
	addsd	xmm0, xmm2
;	overhead end

	ret

;	and now in combination
;	one mul more overhead on start
;	one mul and one add on finish
;	using 4 regs
ENTRY APOLY0K4, YANNQEAU__m128d@@H@Z
ENTRY POLY0K4, YANNQEAU__m128d@@H@Z

;	overhead
;	movddup SSE3 1/1
;	pshufd  SSE 1/0.5
	movddup	xmm3, xmm0					; x
	vmulpd	xmm2, xmm3, xmm3			; x2 = x * x
	vmulpd	xmm4, xmm2, xmm2			; x4 
;	overhead end
	btr		r8, 0
	btr		r8, 1

	movdqa	xmm0, _X [rdx+r8*8]	; r = coef[n] 
	movdqa	xmm1, _X [rdx+r8*8+16]	; r = coef[n] 
	sub		r8, 4
	jc		.done

.lp:
	mulpd	xmm0, xmm4
	addpd	xmm0, _X [rdx+r8*8]
	mulpd	xmm1, xmm4
	addpd	xmm1, _X [rdx+r8*8+16]
	sub		r8, 4
	jnc		.lp

.done:
;	overhead
	mulpd	xmm1, xmm2				; x^2
	addpd	xmm0, xmm1
	movhlps	xmm2, xmm0
	mulsd	xmm2, xmm3				; *x
	addsd	xmm0, xmm2
;	overhead end
	ret


;	packed version - little bit more opted
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0K, YANNQEAU__m128d@@H@Z

;	overhead
;	movddup SSE3 1/1
;	pshufd  SSE 1/0.5
;	movddup	xmm1, xmm0		; xn
	pshufd	xmm1, xmm0, (0<<0) + (1<<2) + (0<<4) + (1<<6)
	movdqa	xmm2, xmm1	
	mulpd	xmm2, xmm2		; x2
;	overhead end
	shr		r8, 1
	shl		r8, 4

	movdqa	xmm0, _X [rdx+r8]	; r = coef[n] 
	sub		r8, 16
	jc		.done

.lp:
	mulpd	xmm0, xmm2
	addpd	xmm0, _X [rdx+r8]
	sub		r8, 16
	jnc		.lp

.done:
;	overhead	
	pshufd	xmm2, xmm0, (2<<0) + (3<<2) + (0<<4) + (1<<6)
	mulsd	xmm2, xmm1				; *x
	addsd	xmm0, xmm2
;	overhead end
	ret


;	packed version (original)
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0K_org, YANNQEAU__m128d@@H@Z

;	overhead
	movddup	xmm1, xmm0		; xn
	movdqa	xmm2, xmm1	
	mulpd	xmm2, xmm2		; x2
	movsd	xmm3, [ONE]
	movsd	xmm1, xmm3
;	overhead end
	shr		r8, 1
	shl		r8, 4

	movdqa	xmm0, _X [rdx+r8]	; r = coef[n] 
	sub		r8, 16
	jc		.done

.lp:
	mulpd	xmm0, xmm2
	addpd	xmm0, _X [rdx+r8]
	sub		r8, 16
	jnc		.lp

.done:
;	overhead	
	mulpd	xmm0, xmm1				; *xn
	pshufd	xmm1, xmm0, (2<<0) + (3<<2) + (0<<4) + (1<<6)
	addpd	xmm0, xmm1
;	overhead end
	ret

;	polynomial calculated using x87
;	"double __cdecl POLY0X(double,double const * const,int)" (?POLY0X@@YANNQEBNH@Z)
ENTRY POLY0X, YANNQEBNH@Z
ENTRY POLY0X, YANNQEANH@Z

	movsd	[SPACE], xmm0
	fld		_Q [SPACE]				; x
	fld		_Q [rdx+r8*8]			; coef[n]
	sub		r8, 1
	jc		.done

.lp:
	fmul	ST(0), ST(1)
	fadd	_Q [rdx+r8*8]
	sub		r8, 1
	jnc		.lp

.done:
	fstp	ST(1)
	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret

;	also try a parallel version 
ENTRY POLY0XP, YANNQEBNH@Z
ENTRY POLY0XP, YANNQEANH@Z
	IF 0
	movsd	[SPACE], xmm0
	btr		r8, 0
	fld		_Q [rdx+r8*8+8]			; coef[n]
	fld		_Q [rdx+r8*8]
	fld		_Q [SPACE]				; x
	fmul	ST(0), ST(0)			; x2
	sub		r8, 2
	jc		.done

.lp:
	fmul	ST(2), ST(0)
	fmul	ST(1), ST(0)
	fld		_Q [rdx+r8*8+8]
	faddp	ST(3), ST(0)
	fld		_Q [rdx+r8*8]
	faddp	ST(2), ST(0)
	sub		r8, 2
	jnc		.lp

.done:
	fxch	ST(2), ST(0)
	ffree	ST(2)
	fmul	_Q [SPACE]
	faddp	ST(1), ST(0)
	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret
	ENDIF

	IF 1
;	generalized
	movsd	[SPACE], xmm0
	btr		r8, 0
	fld		_Q [SPACE]				; x
	fld		_Q [rdx+r8*8+8]			; coef[n]
	fld		_Q [rdx+r8*8]
	fld		ST(2)
	fmul	ST(0), ST(0)			; x2
	sub		r8, 2
	jc		.done

.lp:
	fmul	ST(2), ST(0)
	fmul	ST(1), ST(0)
	fld		_Q [rdx+r8*8+8]
	faddp	ST(3), ST(0)
	fld		_Q [rdx+r8*8]
	faddp	ST(2), ST(0)
	sub		r8, 2
	jnc		.lp

.done:
	fxch	ST(3), ST(0)
;	ffree	ST(3)
	fmul	ST(2)
	ffree	ST(3)
	faddp	ST(1), ST(0)
	fstp	_Q [SPACE]
	ffree	ST(0)
	movsd	xmm0, [SPACE]
	ret
	ENDIF



;	polynomial calculated using AVX2 FMA
; "double __cdecl POLY0X(double,double const * const,int)" (?POLY0X@@YANNQEBNH@Z)
ENTRY POLY0FA, YANNQEBNH@Z
ENTRY POLY0FA, YANNQEANH@Z

; fma version
;	vzeroupper
;	shl		r8, 3
	movsd	xmm1, _X [rdx+r8*8]
	sub		r8, 1
	jc		.done

.lp:
	vfmadd213sd xmm1, xmm0, _Q[rdx+r8*8]
	sub		r8, 1
	jnc		.lp

.done:
	movdqa	xmm0, xmm1
	ret


;	packed version with AVX2 FMA
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0KF, YANNQEAU__m128d@@H@Z

;	overhead
;	movddup	xmm1, xmm0		; xn
	pshufd	xmm1, xmm0, (0<<0) + (1<<2) + (0<<4) + (1<<6)
	vmulpd	xmm2, xmm1, xmm1
;	overhead end
	shr		r8, 1
	shl		r8, 4

	movdqa	xmm0, _X [rdx+r8]	; r = coef[n] 
	sub		r8, 16
	jc		.done

.lp:
	vfmadd213pd xmm0, xmm2, _X[rdx+r8]
	sub		r8, 16
	jnc		.lp

.done:
;	overhead	
	pshufd	xmm2, xmm0, (2<<0) + (3<<2) + (0<<4) + (1<<6)
;	we need xmm0 = xmm0 + xmm1 * xmm2
	vfmadd231sd xmm0, xmm1, xmm2
;	overhead end
	ret



;	was a test
; return poly(x^2, C[]...)
; "double __cdecl POLY0X2(double,double const * const,int)" (?POLY0X@@YANNQEBNH@Z)
ENTRY POLY0X2, YANNQEBNH@Z

	shl		r8, 3
;	movdqu	xmmword ptr [rsp], xmm0
;	movdqa	[SPACE], xmm0
	movsd	[SPACE], xmm0
	fld		_Q [SPACE]					; x
	fmul	ST(0), ST(0)
	fld		_Q [rdx+r8]					; coef[n]
	sub		r8, 8
	jc		.done

.lp:
	fmul	ST(0), ST(1)
	fadd	_Q [rdx+r8]
	sub		r8, 8
	jnc		.lp

.done:
	fstp	ST(1)
	fstp	_Q [SPACE]
;	movdqa	xmm0, [SPACE]
	movsd	xmm0, [SPACE]
	ret

; return poly(x^2, C[]...)
; "double __cdecl POLY0X2(double,double const * const,int)" (?POLY0X@@YANNQEBNH@Z)
ENTRY POLY0X2M1, YANNQEBNH@Z

	shl		r8, 3
;	movdqu	xmmword ptr [rsp], xmm0
	movdqa	[SPACE], xmm0
	fld		_Q [SPACE]				; x
	fmul	ST(0), ST(0)
	fld		_Q [rdx+r8]			; coef[n]
	sub		r8, 8
	jc		.don2

.lp2:
	fmul	ST(0), ST(1)
	fadd	_Q [rdx+r8]
	sub		r8, 8
	jz		.don2
	jnc		.lp2

.don2:
	fstp	ST(1)
	fstp	_Q [SPACE]
	movdqa	xmm0, [SPACE]
	ret


FUNC ENDP

	ELSE
	.code
; "double __vectorcall APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YQNNQAU__m128d@@H@Z) referenced in function _main

;	packed version
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0K, YQNNQAU__m128d@@H@Z

;	overhead
;	movddup SSE3 1/1
;	pshufd  SSE 1/0.5
;	movddup	xmm1, xmm0		; xn
	pshufd	xmm1, xmm0, (0<<0) + (1<<2) + (0<<4) + (1<<6)
	movdqa	xmm2, xmm1	
	mulpd	xmm2, xmm2		; x2
;	overhead end
	shr		edx, 1
	shl		edx, 4

	movdqa	xmm0, _X [ecx+edx]	; r = coef[n] 
	sub		edx, 16
	jc		.done

.lp:
	mulpd	xmm0, xmm2
	addpd	xmm0, _X [ecx+edx]
	sub		edx, 16
	jnc		.lp

.done:
;	overhead	
	pshufd	xmm2, xmm0, (2<<0) + (3<<2) + (0<<4) + (1<<6)
	mulsd	xmm2, xmm1				; *x
	addsd	xmm0, xmm2
;	overhead end
	ret


; "double __vectorcall POLY0X(double,double * const,int)" (?POLY0X@@YQNNQANH@Z) referenced in function _main

;	polynomial calculated using x87
;	"double __cdecl POLY0X(double,double const * const,int)" (?POLY0X@@YANNQEBNH@Z)
ENTRY POLY0X, YQNNQANH@Z

	shl		edx, 3
	sub		esp, 8
	movsd	[esp], xmm0
	fld		_Q [esp]				; x
	fld		_Q [ecx+edx]			; coef[n]
	sub		edx, 8
	jc		.done

.lp:
	fmul	ST(0), ST(1)
	fadd	_Q [ecx+edx]
	sub		edx, 8
	jnc		.lp

.done:
	fstp	ST(1)
	fstp	_Q [esp]
	movsd	xmm0, [esp]
	add		esp, 8
	ret


; "double __vectorcall POLY0FA(double,double * const,int)" (?POLY0FA@@YQNNQANH@Z) referenced in function _main
ENTRY POLY0FA, YQNNQANH@Z

; fma version
;	vzeroupper
	shl		edx, 3
	movsd	xmm1, _X [ecx+edx]
	sub		edx, 8
	jc		.done

.lp:
	vfmadd213sd xmm1, xmm0, _Q[ecx+edx]
	sub		edx, 8
	jnc		.lp

.done:
	movdqa	xmm0, xmm1
	ret


; "double __vectorcall APOLY0KF(double,struct __m128d * const,int)" (?APOLY0KF@@YQNNQAU__m128d@@H@Z) referenced in f

;	packed version with FMA
;"double __cdecl APOLY0K(double,struct __m128d * const,int)" (?APOLY0K@@YANNQEAU__m128d@@H@Z)
ENTRY APOLY0KF, YQNNQAU__m128d@@H@Z

;	overhead
;	movddup	xmm1, xmm0		; xn
	pshufd	xmm1, xmm0, (0<<0) + (1<<2) + (0<<4) + (1<<6)
	vmulpd	xmm2, xmm1, xmm1
;	overhead end
	shr		edx, 1
	shl		edx, 4

	movdqa	xmm0, _X [ecx+edx]	; r = coef[n] 
	sub		edx, 16
	jc		.done

.lp:
	vfmadd213pd xmm0, xmm2, _X[ecx+edx]
	sub		edx, 16
	jnc		.lp

.done:
;	overhead	
	pshufd	xmm2, xmm0, (2<<0) + (3<<2) + (0<<4) + (1<<6)
;	we need xmm0 = xmm0 + xmm1 * xmm2
	vfmadd231sd xmm0, xmm1, xmm2
;	overhead end
	ret



; "double __vectorcall APOLY0(double,double *,int)" (?APOLY0@@YQNNPANH@Z)
; xmm0 = x, ecx = C*; edx = n
ENTRY APOLY0, YQNNPANH@Z	
ENTRY APOLY0, YQNNQANH@Z	

	shl		edx, 3
	movsd	xmm1, _X [ecx+edx]			; r = coef[n] 
	sub		edx, 8
	jc		.done

.lp:
	mulsd	xmm1, xmm0
	addsd	xmm1, _Q [ecx+edx]
	sub		edx, 8
	jnc		.lp

.done:
	movdqa	xmm0, xmm1
	ret

	ENDIF

END
