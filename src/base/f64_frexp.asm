;
;	FILENAME :        f64_frexpd.asm          
;
;	DESCRIPTION :
;		double frexpd(double v, int n)
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

IMPORT MASK,	?M7FF@@3XA
IMPORT C10,		?C10@@3NB

	.data

EMSK dq 07ff0000000000000h, 0
ESUB dq 03fe0000000000000h, 0

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

;	double __cdecl frexpd(double,int *)
ENTRY frexpd								; extern "C"
ENTRY frexpd, YANNPEAH@Z

	movq	rax, xmm0
	shr		rax, 52
	and		eax, 07ffh					; strip sign
	jz		.xdz
	cmp		eax, 07feh					; in range?
	ja		.x_no

	sub		eax, 03feh					; extracted exp	
	mov     [rdx], eax 

	shl		rax, 52
	movq	xmm1, rax
	psubw	xmm0, xmm1					; psubd/q would also work

	ret

;	x is ZERO, DEN or NAN/INF
.x_no:	
	jns		.xnani						; x is INF or NAN

;	x is DEN or ZERO
.xdz:
;	works nicely for positive numbers
	movsd	xmm1, [C10]
	orpd	xmm0, xmm1
;	copy the sign of xmm0 to xmm1
	xorpd	xmm1, xmm0
	andpd	xmm1, [MASK]
	xorpd	xmm1, xmm0

	subsd	xmm0, xmm1

	movq	rax, xmm0
	shr		rax, 52
	and		eax, 07ffh					; strip sign
	jz		.xz

	sub		eax, 03feh					; extracted exp	
	lea		ecx, [eax - 1022]
	mov     [rdx], ecx 

	shl		rax, 52
	movq	xmm1, rax
	psubw	xmm0, xmm1					; psubd/q would also work
	ret

.xz:
	mov		_D [edx], 0
	ret
	
; x is INF or NAN
.xnani:
	mov		_D [edx], -1
	ret

	FUNC ENDP

	ELSE 
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86

	.code

ENTRY frexpd, YANNPAH@Z

	movsd	xmm0, _X [esp+4]
	mov		edx, _D [esp+4+8]
	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh					; strip sign
	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh-1				; extracted exp	
	mov     [edx], eax 

	movd	xmm1, eax
	psllq	xmm1, 52
	psubw	xmm0, xmm1					; psubd/q would also work
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

;	x is ZERO, DEN or NAN/INF
.x_no:	
	jns		.xnani						; x is INF or NAN

;	x is DEN or ZERO
.xdz:
	mov		eax, _D [esp+4+4]
	add		eax, eax
	or		eax, _D [esp+4]
	jz		.xz

;	x is DEN
	mov		eax, _D [esp+4+4]
	btr		eax, 31
	bsr		eax, eax
	jnz		.hh
	bsr		eax, _D [esp+4]
	sub		eax, 32
.hh:
	mov		ecx, 20
	sub		ecx, eax
	sub		eax, 1023 - 2 + 52 + 1 - 33; 
	mov		_D [edx], eax						
	movd	xmm1, ecx
	psllq	xmm0, xmm1
	mov		eax, 3fdh
	mov		ecx, _D [esp+4+4]
	shr		ecx, 20
	or		eax, ecx
	movd	xmm1, eax
	psllq	xmm1, 52
	paddw	xmm0, xmm1
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.xz:
	mov		_D [edx], 0
	fldz
	ret
	
; x is INF or NAN
.xnani:
	mov		_D [edx], 0
	fld		_Q [esp+4]
	ret

;	double __vectorcall frexpd(double,int *) (?frexpd@@YQNNPAH@Z)
ENTRY frexpd, YQNNPAH@Z

	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh					; strip sign
	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh-1				; extracted exp	
	mov     [ecx], eax 

	movd	xmm1, eax
	psllq	xmm1, 52
	psubw	xmm0, xmm1					; psubd/q would also work
	ret

;	x is ZERO, DEN or NAN/INF
.x_no:	
	jns		.xnani						; x is INF or NAN

;	x is DEN or ZERO
.xdz:
	pxor	xmm1, xmm1
	comisd	xmm0, xmm1
	jz		.xz

;	x is DEN
	mov		edx, 20
	movdqa	xmm1, xmm0
	psrlq	xmm1, 32					; tho get the hi dword
	movd	eax, xmm1
	btr		eax, 31						; clr sign
	bsr		eax, eax
	jnz		.hh
	movd	eax, xmm0
	bsr		eax, eax
	sub		eax, 32
.hh:
	sub		edx, eax
	sub		eax, 1023 - 2 + 52 + 1 - 33; 
	mov		_D [ecx], eax						
	movd	xmm2, edx
	psllq	xmm0, xmm2					; shift man into place
	mov		eax, 3fdh
	movd	xmm2, eax
	psrlq	xmm1, 20					; shift sign into place
	por		xmm2, xmm1
	psllq	xmm2, 52
	paddw	xmm0, xmm2
	ret

.xz:
	mov		_D [ecx], 0
	ret
	
; x is INF or NAN
.xnani:
	mov		_D [ecx], 0
	ret

	FUNC ENDP

	ENDIF

	END
