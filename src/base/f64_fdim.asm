;
;	FILENAME :        f64_fdim.asm          
;
;	DESCRIPTION :
;		double fdimd(double u, double v)
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

	IFDEF _M_X64								; 64bit

	.code

ENTRY fdimd, YANNN@Z

	comisd	xmm1, xmm0
	ja		.z
	subsd	xmm0, xmm1
	ret

.z:
	xorpd	xmm0, xmm0
	ret

	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 
	.code

; "double __vectorcall fdimd(double,double)" (?fdimd@@YQNNN@Z)
ENTRY fdimd, YQNNN@Z

	comisd	xmm1, xmm0
	ja		.z
	subsd	xmm0, xmm1
	ret

.z:
	xorpd	xmm0, xmm0
	ret

; cdecl
ENTRY fdimd, YANNN@Z

	movsd	xmm0, [ARGS]
	movsd	xmm1, [ARGS+8]

	comisd	xmm1, xmm0
	ja		.z
;	subsd	xmm0, xmm1
	fld		_Q [ARGS]
	fsub	_Q [ARGS+8]
	ret

.z:
	fldz
	ret

	ENDIF

END
