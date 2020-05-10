;
;	FILENAME :        f64_split.asm          
;
;	DESCRIPTION :
;		double (double v)
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
	IMPORT useAVX, ?useAVX@@3_NA		; bool

	.data

	align 16
CMAS dq	0fffffffff8000000h, 0fffffffff8000000h		; better choice
;CMAS dq	0fffffffffc000000h, 0fffffffffc000000h 

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

;	this calculates x^2
; __m128d sqr_splitf64x(double)
;	arg in xmm0, result in xmm0
ENTRY sqr_splitf64x, YA?AU__m128d@@N@Z
ENTRY sqr_splitf64x

	IF 0
	test	_B [useFMA], 1
	jz		.nfma
;	AVX FMA way
;	12 HAS latency
	vmulsd		xmm1, xmm0, xmm0
	vfmsub132sd xmm0, xmm1, xmm0		; l = fma(x, x, -h)	
	unpcklpd	xmm0, xmm1
	ret
	ENDIF

.nfma:
	IF 1

;	test	_B [useAVX], 1
;	jz		.navx

;	9 SAN; 12 INST AVX
	vmulsd      xmm1, xmm0, xmm0		; => hi

	vandpd		xmm4, xmm0, [CMAS]		; x1
	vsubsd		xmm3, xmm0, xmm4		; x2

	vmulsd		xmm0, xmm4, xmm4		; x1*x1			
	subsd		xmm0, xmm1				; -hi

	addsd		xmm4, xmm4				; *a 2 less LAT
	mulsd		xmm4, xmm3				; x1*x2
	addsd		xmm0, xmm4

	mulsd		xmm3, xmm3				; x2*x2
	addsd		xmm0, xmm3
	unpcklpd	xmm0, xmm1
	ret
	ENDIF

.navx:
;	this is clean sse

;	this xmm code is fast!!
;	~10.5 SAN 16 inst SSE
;	 18 HAS latency
;	x1 = (x - x1) + x1;
;	x2 = x - x1;
;	lo = (((x1 * x1 - hi) + x1 * x2) + x2 * x1) + x2 * x2;
;	should be an exact result to +/-1ulps of lo
;	but we do not need this full prec
;	movdqa		xmm1, xmm0
	movapd		xmm1, xmm0
	mulsd       xmm1, xmm1				; => hi

;	movdqa		xmm4, xmm0	
	movapd		xmm4, xmm0	
;	movdqa		xmm3, xmm0				; x
	movapd		xmm3, xmm0				; x
	andpd		xmm4, [CMAS]			; x1
	subsd		xmm3, xmm4				; x2

;	movdqa		xmm0, xmm4
	movapd		xmm0, xmm4
	mulsd		xmm0, xmm0				; x1*x1			
	subsd		xmm0, xmm1				; -hi

	addsd		xmm4, xmm4	; *a 2 less LAT
	mulsd		xmm4, xmm3				; x1*x2

	addsd		xmm0, xmm4
;	addsd		xmm0, xmm4	; *a
	mulsd		xmm3, xmm3				; x2*x2
	addsd		xmm0, xmm3
	unpcklpd	xmm0, xmm1
	ret

FUNC ENDP

	ELSE

	.code

; "struct __m128d __vectorcall sqr_splitf64x(double)" (?sqr_splitf64x@@YA?AU__m128d@@N@Z)
; arg in xmm0, result in xmm0
ENTRY sqr_splitf64x, YQ?AU__m128d@@N@Z

; this xmm code is faster!!
;	~10.5 SAN 16 inst SSE
;	  7.8 HAS
	movdqa		xmm1, xmm0
	mulsd       xmm1, xmm1				; => hi

	movdqa		xmm3, xmm0				; x
	movdqa		xmm4, xmm0	
	andpd		xmm4, _X [CMAS]			; x1
	subsd		xmm3, xmm4				; x2

	movdqa		xmm0, xmm4
	mulsd		xmm0, xmm0				; x1*x1			
	subsd		xmm0, xmm1				; -hi

	mulsd		xmm4, xmm3				; x1*x2
	addsd		xmm0, xmm4
	addsd		xmm0, xmm4

	mulsd		xmm3, xmm3				; x2*x2
	addsd		xmm0, xmm3
	unpcklpd	xmm0, xmm1
	ret


; "struct __m128d __cdecl sqr_splitf64x(double)" (?sqr_splitf64x@@YA?AU__m128d@@N@Z)
; arg in xmm0, result in xmm0
ENTRY sqr_splitf64x, YA?AU__m128d@@N@Z

	movsd		xmm0, [ARGS]
	movdqa		xmm1, xmm0
	mulsd       xmm1, xmm1				; => hi

	movdqa		xmm3, xmm0				; x
	movdqa		xmm4, xmm0	
	andpd		xmm4, _X [CMAS]			; x1
	subsd		xmm3, xmm4				; x2

	movdqa		xmm0, xmm4
	mulsd		xmm0, xmm0				; x1*x1			
	subsd		xmm0, xmm1				; -hi

	mulsd		xmm4, xmm3				; x1*x2
	addsd		xmm0, xmm4
	addsd		xmm0, xmm4
	mulsd		xmm3, xmm3				; x2*x2
	addsd		xmm0, xmm3
	unpcklpd	xmm0, xmm1
	ret

	ENDIF

	END
