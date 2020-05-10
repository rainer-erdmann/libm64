;
;	FILENAME :        f64_nextafter.asm          
;
;	DESCRIPTION :
;		double nextupd(double v)
;		double nextdownd(double v)
;		double nextafterd(double u, double v)
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


IMPORT D_INF,	?D_INF@@3NA 

	.data
	align 16
IONE	dq 1h
MINF	dq 0fff0000000000000h

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

ENTRY emptyd, YANN@Z
	ret

;"double nextupd(double)" (?nextupd@@YANN@Z)
ENTRY nextupd, YANN@Z

;	using memory accesses
	xorpd	xmm2, xmm2
	comisd	xmm0, xmm2					;[ZERO]
	jbe		.lez						; x <= 0

	comisd	xmm0, [D_INF]
	jae		.inf1						; x >= INF

	paddq	xmm0, [IONE]					; integer

.inf1:
	ret

.lez:
	jae		.isz

	comisd	xmm0, [MINF]
	jb		.inf2						; x <= -INF

	psubq	xmm0, [IONE]					; integer

.inf2:
	ret

.isz:
	jp		.nan

	movq	xmm0, [IONE]					; integer
	
.nan:
	ret


;"double nextdownd(double)" (?nextdownd@@YQNN@Z)
ENTRY nextdownd, YANN@Z

	xorpd	xmm2, xmm2
	comisd	xmm0, xmm2
	jbe		.lez

	comisd	xmm0, [D_INF]
	ja		.inf1

	psubq	xmm0, [IONE]					; integer

.inf1:
	ret

.lez:
	jae		.isz

	comisd	xmm0, [MINF]
	jbe		.inf2

	paddq	xmm0, [IONE]					; integer

.inf2:
	ret

.isz:
	jp		.nan

	mov		rax, 8000000000000001h
	movq	xmm0, rax
	
.nan:
	ret

;"double __vectorcall nextafterd(double, double)" (?nextdownd@@YQNNN@Z)
ENTRY nextafterd, YANNN@Z
ENTRY nexttowardd, YANNN@Z

	comisd	xmm1, xmm0
	ja	?nextupd@@YANN@Z

	comisd	xmm0, xmm1
	ja	?nextdownd@@YANN@Z

	ucomisd	xmm0, xmm0				
	jp		.ret						; x is NAN

	movapd	xmm0, xmm1
.ret:
	ret

FUNC ENDP

	ELSE

	.code

ENTRY emptyd, YQNN@Z
	ret

;"double __vectorcall nextupd(double)" (?nextupd@@YQNN@Z)
ENTRY nextupd, YQNN@Z
;	7.2 HAS
	xorpd	xmm2, xmm2
	comisd	xmm0, xmm2
	jbe		.lez

;	comisd	xmm0, _X [?D_INF@@3NA]
	mov		eax, 07ff0h
	pinsrw	xmm2, eax, 3
	comisd	xmm0, xmm2
	jae		.inf1

	pcmpeqw	xmm1, xmm1
	psubq	xmm0, xmm1

.inf1:
	ret

.lez:
	jae		.isz

	mov		eax, 0fff0h
	pinsrw	xmm2, eax, 3
	comisd	xmm0, xmm2
	jb		.inf2

	pcmpeqw	xmm1, xmm1
	paddq	xmm0, xmm1

.inf2:
	ret

.isz:
;	ucomisd	xmm0, xmm0
	jp		.nan

	mov		eax, 1
	movd	xmm0, eax
	
.nan:
	ret

;"double __vectorcall nextdownd(double)" (?nextdownd@@YQNN@Z)
ENTRY nextdownd, YQNN@Z

	xorpd	xmm2, xmm2
	comisd	xmm0, xmm2
	jbe		.lez

	mov		eax, 07ff0h
	pinsrw	xmm2, eax, 3
	comisd	xmm0, xmm2
	ja		.inf1

	pcmpeqw	xmm1, xmm1
	paddq	xmm0, xmm1

.inf1:
	ret

.lez:
	jae		.isz

	mov		eax, 0fff0h
	pinsrw	xmm2, eax, 3
	comisd	xmm0, xmm2
	jbe		.inf2

	pcmpeqw	xmm1, xmm1
	psubq	xmm0, xmm1

.inf2:
	ret

.isz:
;	ucomisd	xmm0, xmm0
	jp		.nan

	mov		eax, 1
	movd	xmm0, eax
	mov		eax, 08000h
	pinsrw	xmm0, eax, 3
	
.nan:
	ret

;"double __vectorcall nextafterd(double, double)" (?nextdownd@@YQNNN@Z)
ENTRY nextafterd, YQNNN@Z
ENTRY nexttowardd, YQNNN@Z

	comisd	xmm1, xmm0
	ja	?nextupd@@YQNN@Z

	comisd	xmm0, xmm1
	ja	?nextdownd@@YQNN@Z

	ucomisd	xmm0, xmm0
	jp		.ret

	movapd	xmm0, xmm1
.ret:
	ret

FUNC ENDP

	ENDIF

END
