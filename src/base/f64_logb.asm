;
;	FILENAME :        f64_logb.asm          
;
;	DESCRIPTION :
;		double logbd(double v)
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

	.data

LOGB0 dq 0fff0000000000000h				; -INF

	IFDEF _M_X64 								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

;(?logbd@@YANN@Z)
ENTRY logbd, YANN@Z

	movq	rax, xmm0
	shr		rax, 52
	and		eax, 07ffh					; strip sign
	jz		.xdz						; => DEN or ZERO

	cmp		eax, 07feh					; in range?
	ja		.xnani						; => INF or NAN

	sub		eax, 03ffh					; extracted exp	
	cvtsi2sd xmm0, eax
	ret

;	x is DEN or ZERO
.xdz:
	movq	rax, xmm0
	add		rax, rax					; clear sign
	jz		.xz

	bsr		rax, rax
	sub		eax, 1023 + 52;		 
	cvtsi2sd xmm0, eax
	ret

.xz:
	movsd	xmm0, [LOGB0]
	ret

; x is INF or NAN; return it
.xnani:
	ret




FUNC ENDP

	ELSE 
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86

	.code
; "double __vectorcall logbd(double)" (?logbd@@YQNN@Z)
ENTRY logbd, YQNN@Z

	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh					; strip sign
	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh					; extracted exp	
	cvtsi2sd xmm0, eax	
	ret

;	x is ZERO, DEN or NAN/INF
.x_no:	
	jns		.xnani						; x is INF or NAN

;	x is DEN or ZERO
.xdz:
	pxor	xmm1, xmm1
	comisd	xmm0, xmm1
	jz		.xz

	movdqa	xmm1, xmm0
	psrlq	xmm1, 32
	movd	eax, xmm1
	btr		eax, 31
	bsr		eax, eax
	jnz		.hh

	movd	eax, xmm0
	bsr		eax, eax
	sub		eax, 1023 + 52 - 1;		 
	cvtsi2sd xmm0, eax	
	ret

.hh:
	sub		eax, 1023 + 20 - 1;		 
	cvtsi2sd xmm0, eax	
	ret

.xz:
	movsd	xmm0, [LOGB0]
	ret
	
; x is INF or NAN
.xnani:
	ret



; "double __cdecl logbd(double)" (?logbd@@YQNN@Z)
ENTRY logbd, YANN@Z

	mov		eax, _D [ARGS+4]
	shr		eax, 20
	and		eax, 07ffh					; strip sign
	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh					; extracted exp	
	cvtsi2sd xmm0, eax	

	ret

;	x is ZERO, DEN or NAN/INF
.x_no:	
	jns		.xnani						; x is INF or NAN

;	x is DEN or ZERO
.xdz:
	mov		edx, [esp+4]				; recover x
	mov		eax, [esp+4+4]
	add		eax, eax					; clear sign
	or		eax, edx	
	jz		.xz

	mov		eax, [esp+4+4]
	btr		eax, 31
	bsr		eax, eax
	jnz		.hh

	bsr		eax, [esp+4]
	sub		eax, 1023 + 52 - 1;		 
	mov		_D [ARGS], eax
	fild	_D [ARGS]
	ret

.hh:
	sub		eax, 1023 + 20 - 1;		 
	mov		_D [ARGS], eax
	fild	_D [ARGS]
	ret

.xz:
	fld		_Q [LOGB0]
	ret
	
; x is INF or NAN
.xnani:
;	mov		eax, 07fffffffh				; ILOGBNAN
	fld		_Q [ARGS]
	ret


FUNC ENDP

	ENDIF

END
