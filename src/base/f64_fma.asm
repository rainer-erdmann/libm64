;
;	FILENAME :        f64_fma.asm          
;
;	DESCRIPTION :
;		different implementation of fma ops
;		some of them are not "perfect" fma operations
;		they only use the additional 11bits of precision
;		between f64 and f80
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
	IFDEF	@Version
	INCLUDE common.masm 
	ELSE
	INCLUDE 'common.nasm' 
	ENDIF

	IMPORT useFMA, ?useFMA@@3_NA		; bool
	IMPORT M7FF, ?M7FF@@3XA

	.data
	align 16
CMAS dq	0fffffffff8000000h, 0fffffffff8000000h		; better choice

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

	IF 0
; "double __cdecl fmad(double const &,double const &,double const &)" (?fma@@YANAEBN00@Z)
ENTRY fmad, YANAEBN00@Z

	fld		_Q [rcx]
	fmul	_Q [rdx]
	fadd	_Q [r8]
	fstp	_Q [SPACE]
	movsd	xmm0, _X [SPACE]
	ret
	ENDIF


; ~10 SAN; limited prec
; ?fmad@@YANNNN@Z
ENTRY fmad, YANNNN@Z

	movsd	_X [SPACE], xmm0
	movsd	_X [SPACE+8], xmm1
	movsd	_X [SPACE+16], xmm2

	fld		_Q [SPACE]
	fmul	_Q [SPACE+8]
	fadd	_Q [SPACE+16]
	fstp	_Q [SPACE]
	movsd	xmm0, _X [SPACE]
	ret

; we could create a fma from this;
; NOT saving xmm1 (hi) and xmm0
; but simply adding xmm1 + c + xmm0 = hi + c + lo
; should give a full fma
;	result:
;	we will never have more than 1ulps deviation
;	but we have up to exactly 1ulps deviation



;	does not EXACTLY match the fma instr
;	in case the intermediate result of 
;	the mul gets an overflow
;	and the summation gets rounding errors
;	it would be easy to extend this
;	to the other functions
;	 - fms(a,b,c) a * b - c
;	 - fnma(a,b,c) -a * b + c
;	 - fnms(a,b,c) -a * b - c
;	7	HAS hardware FMA
;	11	HAS software FMA
;	14	SAN SSE, 13 SAN AVX
;	+/-2.0ulps
; "double __cdecl fma4d(double, double, double)" (?fma4d@@YANAEAN00@Z)
ENTRY fma4d, YANNNN@Z
	IF 1
	test	_B [useFMA], 1
	jz		.fma4s

	vfmadd213sd xmm0, xmm1, xmm2
	ret
	ENDIF

.fma4s:

	movlhps		xmm0, xmm1				; xmm0l = x, xmm0h = y
;	vandpd		xmm4, xmm0, [CMAS]		; x1, y1
	movapd		xmm4, [CMAS]
	andpd		xmm4, xmm0

	subpd		xmm0, xmm4				; x2, y2

	movhlps		xmm1, xmm4				; y1
	mulsd		xmm1, xmm4				; x1*y1
	shufpd		xmm4, xmm4, 1			; y1, x1
	addsd		xmm1, xmm2				; +c

	mulpd		xmm4, xmm0				; x2*y1, x1*y2
	movhlps		xmm5, xmm0
	addsd		xmm1, xmm4
	mulsd		xmm0, xmm5				; x2*y2

	movhlps		xmm4, xmm4
	addsd		xmm1, xmm4

	addsd		xmm0, xmm1

	ret

;	we should add in sequence:
;	hi + c
;	+ x2*y1, x1*y2
;	+ x2*y2

;	20200124 another approach
;	we use a dekker mul and a summation with 64bit prec
;	random tests show +/-0.50ulps error
;	more exact: +/-0.5007ulps error with 0.013% out of +/-0.5 10M samples
;	reference __f128
;	and ecex/latency is not bad
;	~14.5; some mod ~13.5
;	double fma6d(double x, double y, double z) 
ENTRY fma6d, YANNNN@Z

%deftok $xh 'SPACE'
%deftok $yh 'SPACE+8'
%deftok $xyl 'SPACE+16'
%deftok $z 'SPACE+24'

	movapd	xmm3, [CMAS]
	movsd	[$z], xmm2					; z
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0
	movsd	[$xyl], xmm4				; xl*yl

	fld		_Q [$xh]					; xh*yh must be done x87
	fmul	_Q [$yh]					; due to overflow
	fadd	_Q [$z] 					; z + xh*yh

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh
	movapd	[$xh], xmm3

	fadd	_Q [$xh]					; + xh*yl
	fadd	_Q [$xh+8]					; + xl*yh
	fadd	_Q [$xyl]					; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


; identical to fma6d	r = x * y + z
ENTRY fmadd, YANNNN@Z

%deftok $xh  'SPACE'
%deftok $yh  'SPACE+8'
%deftok $xyl 'SPACE+16'
%deftok $z   'SPACE+24'

	movapd	xmm3, [CMAS]
	movsd	[$z], xmm2					; z
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0
	movsd	[$xyl], xmm4				; xl*yl

	fld		_Q [$xh]					; xh*yh must be done x87
	fmul	_Q [$yh]					; due to overflow
	fadd	_Q [$z] 					; z + xh*yh

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh
	movapd	[$xh], xmm3

	fadd	_Q [$xh]					; + xh*yl
	fadd	_Q [$xh+8]					; + xl*yh
	fadd	_Q [$xyl]					; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


; r = x * y - z
ENTRY fmsub, YANNNN@Z

%deftok $xh  'SPACE'
%deftok $yh  'SPACE+8'
%deftok $xyl 'SPACE+16'
%deftok $z   'SPACE+24'

	movapd	xmm3, [CMAS]
	movsd	[$z], xmm2					; z
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0
	movsd	[$xyl], xmm4				; xl*yl

	fld		_Q [$xh]					; xh*yh must be done x87
	fmul	_Q [$yh]					; due to overflow
	fsub	_Q [$z] 					; xh*yh - z

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh
	movapd	[$xh], xmm3

	fadd	_Q [$xh]					; + xh*yl
	fadd	_Q [$xh+8]					; + xl*yh
	fadd	_Q [$xyl]					; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


; r = -x * y + z
ENTRY fnmadd, YANNNN@Z

%deftok $xh  'SPACE'
%deftok $yh  'SPACE+8'
%deftok $xyl 'SPACE+16'
%deftok $z   'SPACE+24'

	movapd	xmm3, [CMAS]
	movsd	[$z], xmm2					; z
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0
	movsd	[$xyl], xmm4				; xl*yl

	fld		_Q [$xh]					; xh*yh must be done x87
	fmul	_Q [$yh]					; due to overflow
	fchs
	fadd	_Q [$z] 					; z + xh*yh

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh
	movapd	[$xh], xmm3

	fsub	_Q [$xh]					; + xh*yl
	fsub	_Q [$xh+8]					; + xl*yh
	fsub	_Q [$xyl]					; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


; r = -x * y - z
ENTRY fnmsub, YANNNN@Z

%deftok $xh  'SPACE'
%deftok $yh  'SPACE+8'
%deftok $xyl 'SPACE+16'
%deftok $z   'SPACE+24'

	movapd	xmm3, [CMAS]
	movsd	[$z], xmm2					; z
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0
	movsd	[$xyl], xmm4				; xl*yl

	fld		_Q [$xh]					; xh*yh must be done x87
	fmul	_Q [$yh]					; due to overflow
	fchs
	fsub	_Q [$z] 					; xh*yh - z

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh
	movapd	[$xh], xmm3

	fsub	_Q [$xh]					; + xh*yl
	fsub	_Q [$xh+8]					; + xl*yh
	fsub	_Q [$xyl]					; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


	IF 0
;  "public: struct neumaier2 & __cdecl neumaier2::operator=(double)" (??4neumaier2@@QEAAAEAU0@N@Z) referenced in function "double __cdecl fma5d(double,double,double)" (?fma5d@@YANNNN@Z)
ENTRY ?4neumaier2, QEAAAEAU0@N@Z

	movsd	_Q [rcx], xmm1
	mov		_Q [rcx+8], 0
	mov		rax, rcx
	ret

;  "public: __cdecl neumaier2::operator double(void)" (??Bneumaier2@@QEAANXZ) referenced in function "double __cdecl fma5d(double,double,double)" (?fma5d@@YANNNN@Z)
ENTRY ?Bneumaier2, QEAANXZ

	movsd	xmm0, [rcx]	
	addsd	xmm0, [rcx+8]
	ret
	ENDIF

;  "public: struct neumaier2 & __cdecl neumaier2::operator+=(double)" (??Yneumaier2@@QEAAAEAU0@N@Z) referenced in function "double __cdecl fma5d(double,double,double)" (?fma5d@@YANNNN@Z)
ENTRY ?Yneumaier2, QEAAAEAU0@N@Z
;	how would a neumaier be encoded with sse?
;		T t;
;		t = s + c + v;
;		if (fabsd(s) >= fabsd(v)) {
;			c += (s - t) + v;
;		} else {
;			c += (v - t) + s;
;		}
;		s = t; 
;	xmm4 s, xmm5 c; xmm0 v; xmm3 = t
;	means we need 3 xmm regs; s, c, t
		movsd	xmm4, [rcx]
		movsd	xmm5, [rcx+8]

		movdqa	xmm3, xmm4			; s
		addsd	xmm3, xmm5			; s+c
		addsd	xmm3, xmm1				; t=s+c+v
		movq	rax, xmm4			; s
		btr		rax, 63
		movq	rdx, xmm1			; v
		btr		rdx, 63
		cmp		rax, rdx				; 
		jl		.lt
;		c += (s - t) + v;
		subsd	xmm4, xmm3
		addsd	xmm4, xmm1
		addsd	xmm5, xmm4
		jmp		.both
.lt:
;		c += (v - t) + s;
		subsd	xmm1, xmm3				; v-t
		addsd	xmm1, xmm4				; +s
		addsd	xmm5, xmm1				; c+=
.both:
;		movdqa	xmm4, xmm3			; s = t
		movsd	[rcx], xmm3
		movsd	[rcx+8], xmm5
		mov		rax, rcx
		ret

ENTRY fma_dummy
;	now we try to keep s, c in xmm5

		movhlps	xmm3, xmm5			; c
		addsd	xmm3, xmm5
		addsd	xmm3, xmm1			; t=s+c+v

		movq	rax, xmm5			; s
		btr		rax, 63
		movq	rdx, xmm1			; v
		btr		rdx, 63
		cmp		rax, rdx				; 
		jl		.lt
;		c += (s - t) + v;
;		subsd	xmm4, xmm3
;		addsd	xmm4, xmm1
;		addsd	xmm5, xmm4
		subsd	xmm5, xmm3			; s-t
		addsd	xmm5, xmm1			; + v
; now we need xmm5h = xmm5h+xmm5l; xmm5l = xmm3		
		haddpd	xmm5, xmm5
		movsd	xmm5, xmm3
		jmp		.both
.lt:
;		c += (v - t) + s;
		subsd	xmm1, xmm3				; v-t
		addsd	xmm5, xmm1				; +s
		haddpd	xmm5, xmm5
		movsd	xmm5, xmm3
.both:
		ret


		%macro NEUMAIER 3		; v, t, s
		movhlps	%2, %3			; c
		addsd	%2, %3			; c+s
		addsd	%2, %1			; t=s+c+v

		movq	rax, %3			; s
		btr		rax, 63
		movq	rdx, %1			; v
		btr		rdx, 63
		cmp		rax, rdx				; 
		jl		%%lt
;		c += (s - t) + v;
		subsd	%3, %2			; s-t
		addsd	%3, %1			; + v
; now we need xmm5h = xmm5h+xmm5l; xmm5l = xmm3		
		jmp		%%both
%%lt:
;		c += (v - t) + s;
		subsd	%1, %2				; v-t
		addsd	%3, %1				; +s
%%both:
		haddpd	%3, %3
		movsd	%3, %2
		%endmacro


		%macro NEUMAIER 4				; v, t, s, c
		movdqa	%2, %4					; c
		addsd	%2, %3					; c+s
		addsd	%2, %1					; t=s+c+v

		movq	rax, %3					; s
		btr		rax, 63
		movq	rdx, %1					; v
		btr		rdx, 63
		cmp		rax, rdx				; 
		jl		%%lt
;		c += (s - t) + v;
		subsd	%3, %2					; s-t
		addsd	%3, %1					; + v
; now we need xmm5h = xmm5h+xmm5l; xmm5l = xmm3		
		jmp		%%both
%%lt:
;		c += (v - t) + s;
		subsd	%1, %2					; v-t
		addsd	%3, %1					; +s
%%both:
		addsd	%4, %3					; c+=
		movdqa	%3, %2					; s=t
		%endmacro


;	1. entry 
		%macro NEUMAIER1 4				; v, t, s, c
;		movdqa	%2, %4					; c
;		addsd	%2, %3					; c+s
		movdqa	%2, %3
		addsd	%2, %1					; t=s+c+v

		movq	rax, %3					; s
		btr		rax, 63
		movq	rdx, %1					; v
		btr		rdx, 63
		cmp		rax, rdx				; 
		jl		%%lt
;		c += (s - t) + v;
		subsd	%3, %2					; s-t
		addsd	%3, %1					; + v
; now we need xmm5h = xmm5h+xmm5l; xmm5l = xmm3		
		jmp		%%both
%%lt:
;		c += (v - t) + s;
		subsd	%1, %2					; v-t
		addsd	%3, %1					; +s
%%both:
;		addsd	%4, %3					; c+=
		movdqa	%4, %3
		movdqa	%3, %2					; s=t
		%endmacro





;	really working; 
;	but ~48; with neumaier4 ~38;
;	addition xl*yh, yl*xh without neumaier
;	does not get errors, ~29
ENTRY fma7d, YANNNN@Z

	movapd	xmm3, [CMAS]
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0					; xh, yh	

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0					; xl*yl

	movhlps	xmm1, xmm3					; yh
	mulsd	xmm1, xmm3					; xh

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh

	xorpd	xmm0, xmm0					; c=0 
	movdqa	xmm5, xmm2					; s=z		

	NEUMAIER xmm1, xmm2, xmm5, xmm0

	movhlps xmm1, xmm3
	addsd	xmm1, xmm3		; ++
	NEUMAIER xmm1, xmm2, xmm5, xmm0		; yl*xh
;--	NEUMAIER xmm3, xmm2, xmm5, xmm0		; xl*yh	

	NEUMAIER xmm4, xmm2, xmm5, xmm0		; xl*yl

	addsd	xmm0, xmm5					; c+s

	ret


ENTRY fma6d_002, YANNNN@Z

%deftok $xh 'SPACE'
%deftok $yh 'SPACE+8'
%deftok $xl 'SPACE+16'
%deftok $yl 'SPACE+24'


	movapd	[SPACE], xmm2
	fld		_Q [SPACE]					; r = z

	movapd	xmm3, [CMAS]
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3			
	movapd	[$xl], xmm0					; xl, yl = x - xh, y - yh

	fld		_Q [$xh]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; z + xh*yh

	fld		_Q [$xh]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xh*yl

	fld		_Q [$xl]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; + xl*yh

	fld		_Q [$xl]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret


	IF 0
	movsd	[SPACE], xmm2		; z
	fld		_Q [SPACE]

	movdqa	xmm5, [CMAS]
	movdqa	xmm3, xmm0
	andpd	xmm3, xmm5			; xh
	movsd	[SPACE], xmm3

	movdqa	xmm4, xmm1
	andpd	xmm4, xmm5			; yh
	movsd	[SPACE+8], xmm4

	subsd	xmm0, xmm3			; xl = x - xh
	movsd	[SPACE+16], xmm0
	subsd	xmm1, xmm4			; yl = y - yh
	movsd	[SPACE+24], xmm1

	fld		_Q [SPACE]			; xh
	fmul	_Q [SPACE+8]		; yh
	faddp	ST(1), ST(0)		; z + xh*yh

	fld		_Q [SPACE]			; xh
	fmul	_Q [SPACE+24]		; xh*yl
	faddp	ST(1), ST(0)		; + xh*yl

	fld		_Q [SPACE+16]		; xl
	fmul	_Q [SPACE+8]		; xl*yh
	faddp	ST(1), ST(0)		; + xl*yh

	fld		_Q [SPACE+16]		; xl
	fmul	_Q [SPACE+24]		; xl*yl
	faddp	ST(1), ST(0)		; + xl*yl

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret
	ENDIF

;	1. version
ENTRY fma6d_01, YANNNN@Z

	movdqa	xmm5, [CMAS]
	movdqa	xmm3, xmm0
	andpd	xmm3, xmm5			; xh
	movsd	[SPACE], xmm3
	movdqa	xmm4, xmm1
	andpd	xmm4, xmm5			; yh
	movsd	[SPACE+8], xmm4
	movsd	[SPACE+16], xmm2	; z 

	fld		_Q [SPACE]			; xh
	fmul	_Q [SPACE+8]		; yh
	fadd	_Q [SPACE+16]		; xh*yh + z

	subsd	xmm0, xmm3			; xl = x - xh
	movsd	[SPACE+16], xmm0
	subsd	xmm1, xmm4			; yl = y - yh
	movsd	[SPACE+24], xmm1

	fld		_Q [SPACE]			; xh
	fmul	_Q [SPACE+24]		; xh*yl
	faddp	ST(1), ST(0)

	fld		_Q [SPACE+16]		; xl
	fmul	_Q [SPACE+8]		; xl*yh
	faddp	ST(1), ST(0)

	fld		_Q [SPACE+16]		; xl
	fmul	_Q [SPACE+24]		; xl*yl
	faddp	ST(1), ST(0)

	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret

FUNC ENDP

	ELSE

	.code

; ?fmad@@YANNNN@Z
ENTRY fmad, YANNNN@Z

	fld		_Q [ARGS]
	fmul	_Q [ARGS+8]
	fadd	_Q [ARGS+16]
	ret


ENTRY fma4d, YANNNN@Z
	test	_B [useFMA], 1
	jz		.fma4s
	movsd	xmm0, [ARGS]
	movsd	xmm1, [ARGS+8]
	vfmadd213sd xmm0, xmm1, [ARGS+16]
	movsd	[ARGS], xmm0
	fld		_Q [ARGS]

	ret

.fma4s:
	movsd		xmm0, [ARGS]
	movsd		xmm1, [ARGS+8]

;	14 SAN
	movsd       xmm3, xmm0				; x  
	mulsd       xmm3, xmm1				; hi  

	movdqa		xmm4, xmm0				; x	
	andpd		xmm4, _X [CMAS]			; x1
	subsd		xmm0, xmm4				; x2

	movdqa		xmm5, xmm1				; y
	andpd		xmm5, _X [CMAS]			; y1
	subsd		xmm1, xmm5				; y2

	movdqa		xmm2, xmm4				; x1
	mulsd		xmm2, xmm5				; x1*y1			
	subsd		xmm2, xmm3				; -hi

	mulsd		xmm4, xmm1				; x1*y2
	addsd		xmm2, xmm4
	mulsd		xmm5, xmm0				; y1*x2
	addsd		xmm2, xmm5

	mulsd		xmm0, xmm1				; x2*y2
	addsd		xmm2, xmm0

	addsd		xmm3, [ARGS+16]			; hi + c
	addsd		xmm2, xmm3				; + lo
	movsd		[ARGS], xmm2
	fld			_Q [ARGS]

	ret

;	double __vectorcall
;	15..17
ENTRY fma6d, YQNNNN@Z

%deftok $xh 'esp'
%deftok $yh 'esp+8'
%deftok $xl 'esp+16'
%deftok $yl 'esp+24'
%deftok $xy 'esp+32'

	mov		edx, esp
	sub		esp, 48
	and		esp, 0ffffffe0h

	unpcklpd xmm0, xmm1					; faster than unpck xmm0, mem
	movsd	_Q [$xh], xmm2
	fld		_Q [$xh]					; r = z

	movapd	xmm3, [CMAS]
	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3			
	movapd	[$xl], xmm0					; xl, yl = x - xh, y - yh
	shufpd	xmm3, xmm3, 1
	mulpd	xmm0, xmm3					; xh*yl, xl*yh
	movapd	[$xy], xmm0

	fld		_Q [$xh]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; z + xh*yh
	fadd	_Q [$xy]					; + xh*yl
	fadd	_Q [$xy+8]					; + xl*yh
	fld		_Q [$xl]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xl*yl

	fstp	_Q [$xh]
	movsd	xmm0, _Q [$xh]

	mov		esp, edx
	ret


;	double __vectorcall
;	16..18
ENTRY fma6d__00, YQNNNN@Z

%deftok $xh 'esp'
%deftok $yh 'esp+8'
%deftok $xl 'esp+16'
%deftok $yl 'esp+24'

	mov		edx, esp
	sub		esp, 32
	and		esp, 0ffffffe0h

	unpcklpd xmm0, xmm1					; faster than unpck xmm0, mem
	movsd	_Q [$xh], xmm2
	fld		_Q [$xh]					; r = z

	movapd	xmm3, [CMAS]
	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3			
	movapd	[$xl], xmm0					; xl, yl = x - xh, y - yh

	fld		_Q [$xh]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; z + xh*yh

	fld		_Q [$xh]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xh*yl

	fld		_Q [$xl]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; + xl*yh

	fld		_Q [$xl]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xl*yl

	fstp	_Q [$xh]
	movsd	xmm0, _Q [$xh]

	mov		esp, edx
	ret


;	double __cdecl
ENTRY fma6d, YANNNN@Z

%deftok $xh 'esp'
%deftok $yh 'esp+8'
%deftok $xl 'esp+16'
%deftok $yl 'esp+24'

	movsd	xmm0, [ARGS]
	movsd	xmm1, [ARGS+8]
	unpcklpd xmm0, xmm1					; faster than unpck xmm0, mem
	fld		_Q [ARGS+16]				; r = z

	mov		edx, esp
	sub		esp, 32
	and		esp, 0ffffffe0h

	movapd	xmm3, [CMAS]
	andpd	xmm3, xmm0			
	movapd	[$xh], xmm3					; xh, yh

	subpd	xmm0, xmm3			
	movapd	[$xl], xmm0					; xl, yl = x - xh, y - yh

	fld		_Q [$xh]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; z + xh*yh

	fld		_Q [$xh]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xh*yl

	fld		_Q [$xl]			
	fmul	_Q [$yh]			
	faddp	ST(1), ST(0)				; + xl*yh

	fld		_Q [$xl]			
	fmul	_Q [$yl]			
	faddp	ST(1), ST(0)				; + xl*yl

	mov		esp, edx
	ret


		%macro NEUMAIER 4				; v, t, s, c
		movdqa	%2, %4					; c
		addsd	%2, %3					; c+s
		addsd	%2, %1					; t=s+c+v

;		movq	rax, %3					; s
;		btr		rax, 63
;		movq	rdx, %1					; v
;		btr		rdx, 63
;		cmp		rax, rdx				; 
		pextrw	eax, %3, 3
		and		eax, 07fffh
		pextrw	edx, %1, 3
		and		edx, 07fffh
		cmp		eax, edx
		jl		%%lt
;		c += (s - t) + v;
		subsd	%3, %2					; s-t
		addsd	%3, %1					; + v
; now we need xmm5h = xmm5h+xmm5l; xmm5l = xmm3		
		jmp		%%both
%%lt:
;		c += (v - t) + s;
		subsd	%1, %2					; v-t
		addsd	%3, %1					; +s
%%both:
		addsd	%4, %3					; c+=
		movdqa	%3, %2					; s=t
		%endmacro


ENTRY fma7d, YQNNNN@Z

	movapd	xmm3, [CMAS]
	unpcklpd xmm0, xmm1					; x, y

	andpd	xmm3, xmm0					; xh, yh	

	subpd	xmm0, xmm3					; xl, yl = x - xh, y - yh
	movhlps xmm4, xmm0
	mulsd	xmm4, xmm0					; xl*yl

	movhlps	xmm1, xmm3					; yh
	mulsd	xmm1, xmm3					; xh

	shufpd	xmm3, xmm3, 1				; yh, xh
	mulpd	xmm3, xmm0					; xl*yh, yl*xh

	xorpd	xmm0, xmm0					; c=0 
	movdqa	xmm5, xmm2					; s=z		

	NEUMAIER xmm1, xmm2, xmm5, xmm0

	movhlps xmm1, xmm3
	addsd	xmm1, xmm3		; ++
	NEUMAIER xmm1, xmm2, xmm5, xmm0		; yl*xh
;--	NEUMAIER xmm3, xmm2, xmm5, xmm0		; xl*yh	

	NEUMAIER xmm4, xmm2, xmm5, xmm0		; xl*yl

	addsd	xmm0, xmm5					; c+s

	ret



FUNC	ENDP

	ENDIF

END
