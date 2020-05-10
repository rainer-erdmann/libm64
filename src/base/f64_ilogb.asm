;
;	FILENAME :        f64_ilogb.asm          
;
;	DESCRIPTION :
;		int ilogbd(double v)
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

	IFDEF _M_X64 								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.data 

	.code

ILOGB0		EQU 080000000h	
ILOGBNAN	EQU 07fffffffh

; "int __cdecl ilogbd(double)" (?ilogbd@@YAHN@Z)
ENTRY ilogbd, YAHN@Z

	movq	rax, xmm0
	shr		rax, 52
	and		eax, 07ffh					; strip sign
	jz		.xdz						; => DEN or ZERO

	cmp		eax, 07feh					; in range?
	ja		.xnani						; => INF or NAN

	sub		eax, 03ffh					; extracted exp	
	ret

;	x is DEN or ZERO
.xdz:
	movq	rax, xmm0
	add		rax, rax					; clear sign
	jz		.xz

	bsr		rax, rax
	sub		eax, 1023 + 52;		 
	ret

.xz:
	mov		eax, ILOGB0					; ILOGB0
	ret

; x is INF or NAN
.xnani:
	mov		eax, ILOGBNAN				; ILOGBNAN
	ret

FUNC ENDP

	ELSE ; x86

	.code

ENTRY ilogbd, YAHN@Z

	mov		eax, [esp+4+4]
	shr		eax, 20
	and		eax, 07ffh					; strip sign
	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh					; extracted exp	
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
	ret

.hh:
	sub		eax, 1023 + 20 - 1;		 
	ret

.xz:
	mov		eax, 080000000h				; ILOGB0
	ret
	
; x is INF or NAN
.xnani:
	mov		eax, 07fffffffh				; ILOGBNAN
	ret


; "int __vectorcall ilogbd(double)" (?ilogbd@@YQHN@Z)
ENTRY ilogbd, YQHN@Z
; 8.0 SAN
; ~7.0 HAS BMI
	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh					; strip sign
;	mov		ecx, (11 << 8) + 4
;	bextr	eax, eax, ecx				; BMI1

	sub		eax, 1
	cmp		eax, 07fdh					; in range?
	ja		.x_no

	sub		eax, 03feh					; extracted exp	
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
	ret

.hh:
	sub		eax, 1023 + 20 - 1;		 
	ret

.xz:
	mov		eax, 080000000h				; ILOGB0
	ret
	
; x is INF or NAN
.xnani:
	mov		eax, 07fffffffh				; ILOGBNAN
	ret

FUNC ENDP

	ENDIF

	END
