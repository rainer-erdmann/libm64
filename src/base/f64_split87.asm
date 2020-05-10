;
;	FILENAME :        f64_split87.asm          
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

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.data


CFAK dq  41a0000002000000h
	align 16
CMAS dq	0fffffffff8000000h, 0fffffffff8000000h		; better choice
;CMAS dq	0fffffffffc000000h, 0fffffffffc000000h 

	.code

;	how could we avoid the rounding here?
;	(without changing the rounding mode!)
;"void __cdecl sqr_splitf64(double &h,double &l,double &x)" (?sqr_splitf64@@YAXAEAN00@Z)
ENTRY sqr_splitf64, YAXAEAN00@Z

sqr_splitf64:
	fld		_Q [r8]						; x
	fmul	ST(0), ST(0)				; x^2
	fst		_Q[rcx]						; => h
	fsub	_Q[rcx]						; - h
	fstp	_Q[rdx]						; => l
	ret

;"void __cdecl sqr_splitf64(double &h,double &l,double &x)" (?sqr_splitf64@@YAXAEAN00@Z)
ENTRY cub_splitf64, YAXAEAN00@Z

	fld		_Q [r8]						; x
	fmul	ST(0), ST(0)				; x^2
	fmul	_Q [r8]						; x^3
	fst		_Q[rcx]						; => h
	fsub	_Q[rcx]						; - h
	fstp	_Q[rdx]						; => l
	ret


ENTRY sqr_splitf64b, YAXAEAN00@Z

	test	_B [useFMA], 1
	jz		sqr_splitf64

	movsd	xmm0, _X [r8]				; x
	movdqa	xmm1, xmm0
	mulsd	xmm1, xmm1
	movsd	_X [rcx], xmm1				; => h
	vfmsub132sd xmm0, xmm1, xmm0		; l = fma(x, x, -h)	
	movsd	_X [rdx], xmm0				; => l
	ret


ENTRY sqr_splitf64c, YAXAEAN00@Z

	movsd       xmm1, _X [r8]  
	mulsd       xmm1,xmm1  
	movsd       _X [rcx],xmm1			; => hi
	movsd       xmm3, _X [r8]			; x 
	movdqa		xmm4, xmm3	
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
	movsd       _X [rdx],xmm0			; => lo
	ret




ENTRY sqr_splitf64d, YAXAEAN00@Z

	movsd       xmm1, _X [r8]  
	mulsd       xmm1,xmm1  
	movsd       _X [rcx],xmm1			; => hi
	movsd       xmm3, _X [r8]			; x 
	movdqa		xmm4, xmm3	
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
	movsd       _X [rdx],xmm0  
	ret


ENTRY sqr_splitf64f, YAXAEAN00@Z

	vzeroupper							; very important
	movsd	xmm0, _X [r8]				; x
	movdqa	xmm1, xmm0
	mulsd	xmm1, xmm1
	movsd	_X [rcx], xmm1				; => h
	vfmsub132sd xmm0, xmm1, xmm0		; l = fma(x, x, -h)	
	movsd	_X [rdx], xmm0				; => l
	ret


; this is faster than expected... 
;"void __cdecl mul_splitf64(double &h,double &l,double &x, double &y)" 
ENTRY mul_splitf64c, YAXAEAN000@Z

	movsd       xmm1, _X [r8]  
	movsd		xmm2, _X [r9]	
	mulsd       xmm1,xmm2  
	movsd       _X [rcx],xmm1			; => hi

	movsd       xmm3, _X [r8]			; x 
	movdqa		xmm4, xmm3	
	andpd		xmm4, _X [CMAS]			; x1
	subsd		xmm3, xmm4				; x2

	movdqa		xmm5, xmm2				; y
	andpd		xmm5, _X [CMAS]			; y1
	subsd		xmm2, xmm5				; y2

	movdqa		xmm0, xmm4
	mulsd		xmm0, xmm5				; x1*y1			
	subsd		xmm0, xmm1				; -hi

	mulsd		xmm4, xmm2				; x1*y2
	addsd		xmm0, xmm4
	mulsd		xmm5, xmm3				; y1*x2
	addsd		xmm0, xmm5

; do we get differences if we omit the last term? - yes we get
	mulsd		xmm3, xmm2				; x2*y2
	addsd		xmm0, xmm3
	movsd       _X [rdx],xmm0			; => lo
	ret



; exactly the "C" code with dekker
ENTRY sqr_splitf64cx, YAXAEAN00@Z

	movsd       xmm1, _X [r8]  
	mulsd       xmm1,xmm1  
	movsd       _X [rcx],xmm1			; => hi
	movsd       xmm3, _X [r8]			; x 
	movaps      xmm0,xmm3  
	movaps      xmm2,xmm3  
;	mulsd       xmm2, _Q [CFAC]  
	mulsd       xmm2, [CFAK]  
	subsd       xmm0,xmm2  
	addsd       xmm2,xmm0  
	subsd       xmm3,xmm2  
	movaps      xmm0,xmm3  
	mulsd       xmm3,xmm3  
	mulsd       xmm0,xmm2  
	mulsd       xmm2,xmm2  
	subsd       xmm2,xmm1  
	addsd       xmm2,xmm0  
	addsd       xmm2,xmm0  
	addsd       xmm2,xmm3  
	movsd       _X [rdx],xmm2  
	ret


; "void __cdecl mul_splitf64(double &,double &,double &,double &)" (?mul_splitf64@@YAXAEAN000@Z)
ENTRY mul_splitf64, YAXAEAN000@Z

	fld		_Q [r8]						; x
	fmul	_Q [r9]						; x*y
	fst		_Q [rcx]						; => h
	fsub	_Q [rcx]						; - h
	fstp	_Q [rdx]						; => l
	ret

FUNC ENDP

	ELSE

	.data

CFAC dq  41a0000002000000h
	align 16
CMAS dq	0fffffffff8000000h, 0fffffffff8000000h		; better choice

	.code

ENTRY sqr_splitf64c, YAXAAN00@Z

	mov		ecx, _D [esp+4]
	mov		edx, _D [esp+4+4]
	mov		eax, _D [esp+4+8]

	movsd       xmm1, _X [eax]  
	mulsd       xmm1,xmm1  
	movsd       _X [ecx],xmm1			; => hi
	movsd       xmm3, _X [eax]			; x 
	movdqa		xmm4, xmm3	
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
	movsd       _X [edx],xmm0  
	ret

	ENDIF

	END
