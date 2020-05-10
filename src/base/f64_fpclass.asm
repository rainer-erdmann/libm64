;
;	FILENAME :        f64_fpclass.asm          
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

	USE_XMM EQU 1
	USE_GP	EQU 0

IMPORT M7FF, 	?M7FF@@3XA
IMPORT D_INF,	?D_INF@@3NA

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.data

INFS	dq	0ffe0000000000000h
	.code

; counterpart to our __f128 + __f256 fpclass

;	we have the following definition:
;	-1	<  0
;	0	== 0
;	1	>  0
;	2	+/-INF
;	3	+/-NAN

;	int __cdecl fpclassd(double)
ENTRY fpclassd, YAHN@Z

;	~5.5 SAN
;	~12.5 HAS ???
	pextrw	eax, xmm0, 3				; hi word
	xor		edx, edx					
	btr		eax, 15						; make positive
	setc	dl							; remember sign 

	cmp		eax, 07ff0h
	jge		.z10ni						; NAN/INF

	test	eax, eax
	jz		.z10dz						; DEN/ZERO
	
	mov		eax, 1
	sub		eax, edx
	sub		eax, edx
	ret

;	x is +/-NAN or +/-INF
.z10ni:									; NAN/INF
	movq	rcx, xmm0
	xor		eax, eax
	shl		rcx, 12						; shift out exp+sign
	setnz	al							; 1 on NAN
	add		eax, 2
	ret

;	x is DEN or ZERO; edx is 0 if pos, 1 if neg
.z10dz:									; DEN/ZERO
	movq	rcx, xmm0
	xor		eax, eax
	shl		rcx, 1						; shift out sign
	setnz	al
	and		edx, eax
	sub		eax, edx
	sub		eax, edx
	ret


;	int __cdecl _isnand(double)
ENTRY _isnand, YAHN@Z

	xor		eax, eax
	comisd	xmm0, xmm0
	setp	al
	ret



	.data
	ALIGN 16
M800	dq	08000000000000000h, 08000000000000000h 
M3FE	dq	03fe0000000000000h, 03fe0000000000000h

	.code


;	round from trunc(x +/- 0.5)
	ALIGN 16
;"double __cdecl _roundd(double)" (?_roundd@@YANN@Z)
ENTRY _roundd, YANN@Z

; 7.2..7.4 san
	vpsrlq	xmm1, xmm0, 63		; copy and isolate sign
	psllq	xmm1, 63			; sign of x without mask
	por		xmm1, _X [M3FE]
	addsd	xmm0, xmm1
	roundsd	xmm0, xmm0, 08h+03h ; no except, toward zero
	ret

	ALIGN 16

; 7.2..7.4 san
;	faster than C
	vpand	xmm1, xmm0, [M800]	
	por		xmm1, _X [M3FE]
	addsd	xmm0, xmm1
	roundsd	xmm0, xmm0, 08h+03h ; no except, toward zero
	ret

	ALIGN 16
;	using generated constants; slightly slower than C
;	we need the sign bit
	vpsrlq	xmm1, xmm0, 63
	psllq	xmm1, 63
;	we need 0.5
	pcmpeqw	xmm2, xmm2
	psllq	xmm2, 55
	psrlq	xmm2, 2
;	
	por		xmm1, xmm2
	addsd	xmm0, xmm1
	roundsd	xmm0, xmm0, 08h+03h ; no except, toward zero
	ret


;	needed in fapm_cheby
	IF 1
; "void __cdecl fma3_f80(struct __f80 &,struct __f80 &,struct __f80 &)" (?fma3_f80@@YAXAEAU__f80@@00@Z)
ENTRY fma3_f80, YAXAEAU__f80@@00@Z

	fld		_T [rcx]
	fld		_T [rdx]
	fmulp	ST(1), ST(0)
	fld		_T [r8]
	faddp	ST(1), ST(0)
	fstp	_T [rcx]
	ret	
	ENDIF

FUNC ENDP

	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 
	.code

;"double __vectorcall _fabsd(double)" (?_fabsd@@YANN@Z)
ENTRY _fabsd, YQNN@Z
	psllq	xmm0, 1
	psrlq	xmm0, 1
	ret


ENTRY fpclassd, YQHN@Z

	pextrw	eax, xmm0, 3				; hi word
	xor		edx, edx					
	btr		eax, 15						; make positive
	setc	dl							; remember sign 

	cmp		eax, 07ff0h
	jge		_z10ni						; NAN/INF

	test	eax, eax
	jz		_z10dz						; DEN/ZERO
	
	mov		eax, 1
	sub		eax, edx
	sub		eax, edx
	ret

;	x is +/-NAN or +/-INF
_z10ni:									; NAN/INF
	movd	ecx, xmm0					
	psrlq	xmm0, 32
	movd	edx, xmm0
	xor		eax, eax
	shl		edx, 12						; shift out exp+sign
	or		edx, ecx
	setnz	al							; 1 on NAN
	add		eax, 2
	ret

;	x is DEN or ZERO; edx is 0 if pos, 1 if neg
_z10dz:									; DEN/ZERO
	movd	eax, xmm0
	psrlq	xmm0, 32
	movd	ecx, xmm0
	shl		ecx, 1						; shift out sign
	or		ecx, eax
	setnz	al
	movzx	eax, al
	and		edx, eax
	sub		eax, edx
	sub		eax, edx
	ret



	ENDIF


END

