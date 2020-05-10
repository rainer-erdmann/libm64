;
;	FILENAME :        f64_ldexp.asm          
;
;	DESCRIPTION :
;		double ldexpd(double v, int n)
;		double scalbnd(double v, int n)
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

	IFDEF @Version
	COPYSIGN MACRO DST, SRC
	pxor	DST, SRC
	pand	DST, [M7FF]
	pxor	DST, SRC
	ENDM
	ELSE
	%macro COPYSIGN 2
	pxor	%1, %2
	pand	%1, [M7FF]
	pxor	%1, %2
	%endmacro
	ENDIF

IMPORT C10,		?C10@@3NB 
IMPORT D_INF,	?D_INF@@3NA 
IMPORT M7FF,	?M7FF@@3XA

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.data
	align 16
MASK	dq	0800fffffffffffffh, 0
ESUB	dq	03fe0000000000000h, 0
MMSK	dq	0000fffffffffffffh, 0
	.code

;	"double __cdecl __ldexp(double,int)" (?__ldexp@@YANNH@Z)
ENTRY ldexpd, YANNH@Z
ENTRY scalbnd, YANNH@Z
;	this is the shortest and the (normally) fastest way;
;	it gets very slow on DENS, not on ZERO, INF or NAN
;	and we have a different rounding behavior on DENs
;	the original truncates, we round
;	(by definition, rounding is the correct behavior)
	cmp		edx, 03ffh
	jge		.of
	cmp		edx, -1023
	jle		.uf
	add		edx, 03ffh

;	if we would check x for DEN here
;	we would get slower on the main path
;	how much?
;	7.5 with check, 6.5 without
;	movq	rax, xmm0
;	btr		rax, 63
;	shr		rax, 52
;	jz		.spec0

.cont:
	shl		rdx, 52
	movq	xmm1, rdx
	mulsd	xmm0, xmm1
	ret

;.spec0:
;	jmp		.cont

.of:
; in case edx is >= 7fe we need a special handling
	cmp		edx, 07feh
	jge		.gt7fe

	mov		eax, edx
	shr		eax, 1
	sub		edx, eax
	add		edx, 03ffh
	add		eax, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

.gt7fe:
; edx is >= 0x7fe
	mov		eax, 07feh	
	sub		edx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, 03ffh
	jle		.lt3ff

	sub		edx, 03ffh
	mulsd	xmm0, xmm1
	cmp		edx, 03ffh
	jle		.lt3ff

	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

.lt3ff:
	add		edx, 03ffh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

; ----------------

.uf:
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03feh					; why 3fe here and 3ff above?
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03ffh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

;	already correct
.gem3fe:
	add		edx, 03feh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret


ENTRY ldexpd2, YANNH@Z
ENTRY ldexpd

;	this surely works absolutely correct
;	but it gets deadly slow on DENs
	IF 0
	movsd	[SPACE], xmm0
	mov		[SPACE+8], edx
	fild	_D [SPACE+8]
	fld		_Q [SPACE]
	fscale
	fstp	ST(1)
	fstp	_Q [SPACE]
	movsd	xmm0, [SPACE]
	ret
	ENDIF



;	but already xdenz and this is fast
;	8cy main range
;	and all special cases <16cy
;	the slowest is DEN x and DEN y 14cy
	pextrw	eax, xmm0, 3
	btr		eax, 15
	shr		eax, 4
	jz		.xdenz4						; x is DEN or ZERO

	cmp		eax, 07ffh
	jz		.xinf4

;	we do not check edx here in the moment
	add		eax, edx
	jle		.zden4

	cmp		eax, 07ffh
	jge		.zinf4

	shl		rax, 52
	movq	xmm1, rax
	pand	xmm0, [MASK]
	por		xmm0, xmm1
;	andpd	xmm0, [MASK]
;	orpd	xmm0, xmm1
	ret


	add		edx, 3ffh
	shl		rdx, 52
	movq	xmm1, rdx
	mulsd	xmm0, xmm1
	ret

;	we must handle all special cases here
;	x is DEN or ZERO
.xdenz4:
	movdqa	xmm2, xmm0					;+++
	andpd	xmm0, [M7FF]				; fabs

	movsd	xmm1, [C10]
	orpd	xmm0, xmm1
	subsd	xmm0, xmm1

	movq	rax, xmm0
	shr		rax, 52
	jz		.xz5

	orpd	xmm0, xmm1
;	xmm0	is normalized now to [1, 2[
	lea		eax, [eax - 1023 - 1022 + edx]
	cmp		eax, 1023
	jg		.zinf5
	cmp		eax, -1023
	jle		.zden5

;	result is a NORM
	add		eax, 3ffh
	shl		rax, 52
	movq	xmm1, rax
	mulsd	xmm0, xmm1

	pxor	xmm0, xmm2
	pand	xmm0, [M7FF]
	pxor	xmm0, xmm2
;	COPYSIGN xmm0, xmm2

	ret
	 

;	x is INF or NAN
.xinf4:
	ret		; finished
;	x is ZERO
.xz5:		; finished
	ret

;	z will be DEN or ZERO
.zden5:
;	x is normalized and positive
	add		eax, 1023
	neg		eax
	add		eax, 400h
	shl		rax, 52
	movq	xmm1, rax

	addsd	xmm0, xmm1
	pand	xmm0, [MASK]

	pxor	xmm0, xmm2
	pand	xmm0, [M7FF]
	pxor	xmm0, xmm2

	ret

.zden4:
;	x is unknown
;	thats it! (except we need the sign of x in xmm1)
	movdqa	xmm2, xmm0
	pand	xmm0, [MMSK]
	por		xmm0, [C10]
	neg		eax
	add		eax, 400h
	shl		rax, 52
	movq	xmm1, rax

	addsd	xmm0, xmm1
	pand	xmm0, [MMSK]

	pxor	xmm0, xmm2
	pand	xmm0, [M7FF]
	pxor	xmm0, xmm2

	ret

;	z will be INF - leave it to a mul to keep the sign
.zinf4:
	mulsd	xmm0, [D_INF]
	ret

.zinf5:
	movsd	xmm0, [D_INF]
	pxor	xmm0, xmm2
	pand	xmm0, [M7FF]
	pxor	xmm0, xmm2
	ret





	IF 0
;	yes it works...
;	was only a test; 
;	solution above IS faster
	movsd	_Q [SPACE], xmm0
	fld1	
	fstp	_T [SPACE+8]
	add		_W [SPACE+8+8], dx
	fld		_T [SPACE+8]
	fmul	_Q [SPACE]
	fstp	_Q [SPACE]
	movsd	xmm0, _Q [SPACE]
	ret
	ENDIF

	IF 1
;	n is >= 1023 or <= -1023
;	x is not yet checked
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	jz		.ret3						; x is ZERO or NAN
;	remaining: x is not ZERO, anything [DEN, INF]
	movq	rax, xmm0
	btr		rax, 63
	shr		rax, 52
	jz		.denx
	cmp		eax, 07ffh
	jz		.ret3						; x is INF
;	remaining: x is finite
	add		eax, edx					; combine
	jbe		.den						; result will be DEN
	cmp		eax, 07ffh
	jge		.inf						; result will be INF

	andpd	xmm0, [MASK]
	shl		rax, 52
	movq	xmm1, rax
	orpd	xmm0, xmm1
	ret

;	x is DEN
.denx:



.inf:
	mov		eax, 07ffh
	psrlq	xmm0, 52					; keep sign only
	movq	xmm1, rax
	por		xmm0, xmm1
	psllq	xmm0, 52
	ret

.den:
;	eax is the final (biased) exp
;	and the result will be a DEN
;	in case eax < -52 the result is ZERO
;	we would like to use the same trick as in frexp
	andpd	xmm0, [MASK]
	orpd	xmm0, [ESUB]	
;	x now is [0.5, 1[
;	add		eax, 3ffh
	mov		edx, 3ffh
	sub		edx, eax
; ### something missing
	movq	xmm1, rdx
	psllq	xmm1, 52
	addsd	xmm0, xmm1
	andpd	xmm0, [MASK]

	ret


.ret3:
	ret
	ENDIF

FUNC ENDP

	ELSE ; x86

	.code

;	"double __cdecl __ldexp(double,int)" (?__ldexp@@YANNH@Z)
ENTRY ldexpd2, YANNH@Z
;	this is the shortest way...
;	18..20 SAN
	fild	_D [esp+4+8]
	fld		_Q [esp+4]
	fscale
	fstp	ST(1)
	ret





;	this is the shortest and the (normally) fastest way;
;	it gets very slow on DENS, not on ZERO, INF or NAN

;	10.3 SAN
	movsd	xmm0, _X [esp+4]
	mov		edx, _D [esp+4+8]

	cmp		edx, 03ffh
	jge		.of
	cmp		edx, -1023
	jle		.uf
	add		edx, 03ffh

	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.of:
; in case edx is >= 7fe we need a special handling
	cmp		edx, 0x7fe
	jge		.gt7fe

	mov		eax, edx
	shr		eax, 1
	sub		edx, eax
	add		edx, 03ffh
	add		eax, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.gt7fe:
; edx is >= 0x7fe
	mov		eax, 07feh	
	sub		edx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, 03ffh
	jle		.lt3ff

	sub		edx, 03ffh
	mulsd	xmm0, xmm1
	cmp		edx, 03ffh
	jle		.lt3ff

	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.lt3ff:
	add		edx, 03ffh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

; ----------------

.uf:
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03feh					; why 3fe here and 3ff above?
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		edx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		edx, 03ffh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

;	already correct
.gem3fe:
	add		edx, 03feh
	movd	xmm1, edx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret


;	"double __cdecl ldexp(double,int)" (?ldexp@@YANNH@Z)
ENTRY ldexpd, YANNH@Z
;	this is the shortest and the (normally) fastest way;
;	it gets very slow on DENS, INF or NAN, not on ZERO

;	9.9 SAN
	fld		_Q [esp+4]
	mov		edx, _D [esp+4+8]

	cmp		edx, 03ffh
	jge		.of
	cmp		edx, -1023
	jle		.uf
	add		edx, 03ffh

	movd	xmm1, edx
	psllq	xmm1, 52
	movsd	_X [esp+4], xmm1
	fmul	_Q [esp+4]
	ret

.of:
	cmp		edx, 03fffh
	jge		.gt7fe

	fld1
	fstp	_T [esp+4]
	add		_W [esp+4+8], dx
	fld		_T [esp+4]
	fmulp	
	ret

.gt7fe:
	fld1
	fstp	_T [esp+4]
	add		_W [esp+4+8], 8192
	fld		_T [esp+4]
	fmulp	
	ret

; ----------------

.uf:
	cmp		edx, -16382
	jl		.l3fe

	fld1
	fstp	_T [esp+4]
	add		_W [esp+4+8], dx
	fld		_T [esp+4]
	fmulp	
	ret

.l3fe:
	fld1
	fstp	_T [esp+4]
	add		_W [esp+4+8], -8192
	fld		_T [esp+4]
	fmulp	
	ret


; "double __vectorcall ldexpd(double,int)" (?ldexpd@@YQNNH@Z)
ENTRY ldexpd, YQNNH@Z

	cmp		ecx, 03ffh
	jge		.of
	cmp		ecx, -1023
	jle		.uf
	add		ecx, 03ffh

	movd	xmm1, ecx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

.of:
; in case exp is >= 7fe we need a special handling
	cmp		ecx, 0x7fe
	jge		.gt7fe

	mov		eax, ecx
	shr		eax, 1
	sub		ecx, eax
	add		ecx, 03ffh
	add		eax, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	movd	xmm1, ecx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

.gt7fe:
; exp is >= 0x7fe
	mov		eax, 07feh	
	sub		ecx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		ecx, 03ffh
	jle		.lt3ff

	sub		ecx, 03ffh
	mulsd	xmm0, xmm1
	cmp		ecx, 03ffh
	jle		.lt3ff

	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

.lt3ff:
	add		ecx, 03ffh
	movd	xmm1, ecx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

; ----------------

.uf:
	cmp		ecx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		ecx, 03ffh
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		ecx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		ecx, 03feh					; why 3fe here and 3ff above?
	movd	xmm1, eax
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	cmp		ecx, -1022
	jg		.gem3fe

	mov		eax, 1
	add		ecx, 03ffh
	movd	xmm1, ecx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret

;	already correct
.gem3fe:
	add		ecx, 03feh
	movd	xmm1, ecx
	psllq	xmm1, 52
	mulsd	xmm0, xmm1
	ret


;	we need an internal version
;	with x in xmm0, exp in edx
;	returning y in st(0)
ENTRY ldexpd
;	this is the shortest way...
;	18..20 SAN
;	fild	_D [esp+4+8]
;	fld		_Q [esp+4]
	mov		[esp-8], edx
	movsd	[esp-16], xmm0
	fild	_D [esp-8]
	fld		_Q [esp-16]
	fscale
	fstp	ST(1)
	ret


	FUNC ENDP

	ENDIF

	END
