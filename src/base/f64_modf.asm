;
;	FILENAME :        f64_modf.asm          
;
;	DESCRIPTION :
;		double fmodd(double x, double y)
;		double remainderd(doublex, double y)
;		double modfd(double, double *)
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

	IMPORT useSSE41, ?useSSE41@@3_NA
	IMPORT M7FF,	?M7FF@@3XA

	.data
	align 16
RIFA64	dq 04330000000000000h; 	03ff0000000000000h + (52<<52)
		dq 04330000000000000h;	03ff0000000000000h + (52<<52)

	IFDEF _M_X64	 							; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code
;	missing C++11
;	remquo - we are not going to implement...
;	we have rem_pio2 for these cases

;	we should have compliant behaviour in case
;	of ZERO, INF, NAN
;	C: explicitely truncated

;	return x - y * trunc(x/y);
ENTRY fmodd, YANNN@Z 

	test	_B [useSSE41], 1
	jz		.n41

	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
	roundsd xmm2, xmm2, 3				; trunc
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

.n41:
	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
;	trunc xmm2, leave xmm1 and xmm0 intact
	movq	rax, xmm2
	add		rax, rax
	shr		rax, 53
	cmp		eax, 3ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int

	movd	xmm3, ecx
	pcmpeqw	xmm4, xmm4					; generate 0xff..ff
	psllq	xmm4, xmm3
	andpd	xmm2, xmm4					; trunc
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

;	|x| < 1; means ipart is zero 
.zero:
	ret

;	|x| > 2^5x, return 0
.int:
	xorpd	xmm0, xmm0
	ret

;	C: explicitely round to nearest
;	return x - y * rint(x/y);
ENTRY remainderd, YANNN@Z 

	test	_B [useSSE41], 1
	jz		.n41

	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
	roundsd xmm2, xmm2, 0				; nearest
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

.n41:
	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
;	this is rint without sse41
	movsd	xmm1, [RIFA64]
; now copy the sign of x to xmm1
	xorpd	xmm1, xmm2
	andpd	xmm1, _X [M7FF]
	xorpd	xmm1, xmm2
	addsd	xmm2, xmm1
	subsd	xmm2, xmm1

	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret


;	*ipart = trunc(x); return x - *ipart;
;	en.cppreference tells for modf:
;	+/-INF => ipart +/-INF, result 0
;	+/-NAN => ipart +/-NAN, result NAN
;	double __cdecl modfd(double,double *)
ENTRY modfd, YANNPEAN@Z

	test	_B [useSSE41], 1
	jz		.n41
;	jmp		.n41

;	if we have SSE4.1; not exactly in case of INF
	roundsd xmm1, xmm0, 3
	subsd	xmm0, xmm1
	movsd	[rdx], xmm1

	ret

.n41:
;	does not get slow on DEN, INF or NAN
;	is correct and not much slower than SSE4
	movq	rax, xmm0
	add		rax, rax
	shr		rax, 53
	cmp		eax, 3ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int

	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	andpd	xmm2, xmm0					; trunc
	subsd	xmm0, xmm2
	movsd	[rdx], xmm2
	ret

;	|x| < 1; means ipart is zero 
.zero:
	xorpd	xmm2, xmm2
	movsd	[rdx], xmm2
	ret

;	|x| > 2^5x, means *ipart = x; return 0
.int:
	movsd	[rdx], xmm0
	comisd	xmm0, xmm0
	jp		.nan
	xorpd	xmm0, xmm0
.nan:
	ret


	ELSE

;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 
	.code

;	return x - y * trunc(x/y);
ENTRY fmodd, YQNNN@Z 

	test	_B [useSSE41], 1
	jz		.n41

	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
	roundsd xmm2, xmm2, 3				; trunc
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

.n41:
	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
;	trunc xmm2, leave xmm1 and xmm0 intact
;	movq	rax, xmm2
;	add		rax, rax
;	shr		rax, 53
	pextrw	eax, xmm2, 3
	shr		eax, 4
	and		eax, 07ffh
	cmp		eax, 3ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int

	movd	xmm3, ecx
	pcmpeqw	xmm4, xmm4					; generate 0xff..ff
	psllq	xmm4, xmm3
	andpd	xmm2, xmm4					; trunc
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

;	|x| < 1; means ipart is zero 
.zero:
	ret

;	|x| > 2^5x, return 0
.int:
	xorpd	xmm0, xmm0
	ret

;	return x - y * rint(x/y);
ENTRY remainderd, YQNNN@Z 

	test	_B [useSSE41], 1
	jz		.n41

	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
	roundsd xmm2, xmm2, 0				; nearest
	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret

.n41:
	movdqa	xmm2, xmm0
	divsd	xmm2, xmm1					; x/y
;	this is rint without sse41
	movsd	xmm1, [RIFA64]
; now copy the sign of x to xmm1
	xorpd	xmm1, xmm2
	andpd	xmm1, _X [M7FF]
	xorpd	xmm1, xmm2
	addsd	xmm2, xmm1
	subsd	xmm2, xmm1

	mulsd	xmm2, xmm1
	subsd	xmm0, xmm2
	ret


;	*ipart = trunc(x); return x - *ipart;
;	en.cppreference tells for modf:
;	+/-INF => ipart +/-INF, result 0
;	+/-NAN => ipart +/-NAN, result NAN
;	double __cdecl modfd(double,double *)
ENTRY modfd, YQNNPAN@Z

	test	_B [useSSE41], 1
	jz		.n41
;	jmp		.n41

;	if we have SSE4.1; not exactly in case of INF
	roundsd xmm1, xmm0, 3
	subsd	xmm0, xmm1
	movsd	[ecx], xmm1

	ret

.n41:
;	does not get slow on DEN, INF or NAN
;	is correct and not much slower than SSE4
;	movq	rax, xmm0
;	add		rax, rax
;	shr		rax, 53
	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh

	cmp		eax, 3ffh
	jl		.zero

	mov		edx, 52 + 3ffh
	sub		edx, eax
	jle		.int

	movd	xmm1, edx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	andpd	xmm2, xmm0					; trunc
	subsd	xmm0, xmm2
	movsd	[ecx], xmm2
	ret

;	|x| < 1; means ipart is zero 
.zero:
	xorpd	xmm2, xmm2
	movsd	[ecx], xmm2
	ret

;	|x| > 2^5x, means *ipart = x; return 0
.int:
	movsd	[ecx], xmm0
	comisd	xmm0, xmm0
	jp		.nan
	xorpd	xmm0, xmm0
.nan:
	ret

	ENDIF
END

