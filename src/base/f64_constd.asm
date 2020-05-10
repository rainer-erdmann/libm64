;
;	FILENAME :        f64_constd.asm          
;
;	DESCRIPTION :
;		commonly used constants
;		assembly module written for MASM/NASM and VS201x
;
;	REMARKS:
;		originally we tried to find a system to support 
;		MASM and NASM with the same sources 
;		(only a little patchwork in the headers was necessary)
;		using floating point constants this wasn't anymore possible 
;		NASM supports 0x1.xyzp+n the "C99" syntax, 
;		MASM does not (exactly)
;		it supports 1.xyzp+n only without the leading '0x'. 
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

	align 16
	IFDEF @Version
;	EXPORT MACRO NAME, DEF
;		public NAME
;		NAME DEF
;	ENDM
	EXPORT MACRO NAME:REQ, DEF:VARARG 
		public NAME
		NAME::
		p@arg TEXTEQU <>
		FOR var, <DEF>
		  p@arg CATSTR p@arg, <var>, <,>
	    ENDM
		p@arg
	ENDM 
	ELSE
%macro EXPORT 1
	global %1
%1
%endmacro

%macro EXPORT 2+
	global %1
	%1 %2
%endmacro
	ENDIF

	align 16
EXPORT ?C10@@3NB,	dq 1.0, 1.0 
EXPORT ?C05@@3NB,	dq 0.5
EXPORT ?C20@@3NB,	dq 2.0

EXPORT ?D_INF@@3NA, dq 07ff0000000000000h
EXPORT ?D_NAN@@3NA, dq 07fffffffffffffffh

	IFDEF @Version
;	Masm

; EXPORT ?PIO4@@3NA,	DQ 1.921fb54442d18p-1; 7.8539816339744827e-01
;PIO4  0x1.921fb54442d18469898cc51701b80p-1;  0.78539816339744830961566084581987570
; EXPORT ?PIO2@@3NA,	DQ 1.921fb54442d18p+0; 1.5707963267948965e+00
;PIO2  0x1.921fb54442d18469898cc51701b80p+0;  1.5707963267948966192313216916397514
EXPORT ?PID@@3NA,	DQ 1.921fb54442d18p+1; 3.1415926535897931e+00
;PI  0x1.921fb54442d18469898cc51701b80p+1;  3.1415926535897932384626433832795028
; EXPORT ?TOPI@@3NA,	DQ 1.45f306dc9c883p-1; 6.3661977236758140e-01
;TOPI  0x1.45f306dc9c882a53f84eafa3ea6a0p-1;  0.63661977236758134307553505349005744
; EXPORT ?FOPI@@3NA,	DQ 1.45f306dc9c883p+0; 1.2732395447351627e+00
;FOPI  0x1.45f306dc9c882a53f84eafa3ea6a0p+0;  1.2732395447351626861510701069801149
;	log(sqrt(2pi))
EXPORT ?LS2PI@@3NA,	DQ 1.d67f1c864beb5p-1; // 9.1893853320467275e-01
;	log(sqrt(2pi)) top 32bit
EXPORT ?LS2PIH@@3NA,	DQ 1.d67f1c8600000p-1; // 9.1893853317014873e-01
;	log(sqrt(2pi)) low part
EXPORT ?LS2PIL@@3NA,	DQ 1.2fad29a4a5e48p-35; // 3.4524011502314602e-11

	ELSE
;	Nasm

EXPORT ?PIO4@@3NA,	DQ 0x1.921fb54442d18p-1; 7.8539816339744827e-01
EXPORT ?PIO2@@3NA,	DQ 0x1.921fb54442d18p+0; 1.5707963267948965e+00
EXPORT ?PID@@3NA,	DQ 0x1.921fb54442d18p+1; 3.1415926535897931e+00
EXPORT ?TOPI@@3NA,	DQ 0x1.45f306dc9c883p-1; 6.3661977236758140e-01

;	log(sqrt(2pi))
EXPORT ?LS2PI@@3NA,	DQ 0x1.d67f1c864beb5p-1; // 9.1893853320467275e-01
;	log(sqrt(2pi)) top 32bit
EXPORT ?LS2PIH@@3NA,	DQ 0x1.d67f1c8600000p-1; // 9.1893853317014873e-01
;	log(sqrt(2pi)) low part
EXPORT ?LS2PIL@@3NA,	DQ 0x1.2fad29a4a5e48p-35; // 3.4524011502314602e-11
	ENDIF


EXPORT ?SQRTH@@3NA,	DQ 0.70710678118654752440;

EXPORT ?LN2H@@3NA,	DQ +0.693359375;  // 8bit of LN2
EXPORT ?LN2L@@3NA,	DQ -2.121944400546905827679e-4;

;	top 32bit
EXPORT ?LN2HS@@3NA,	DQ 6.93147180369123816490e-01;	/* 3fe62e42 fee00000 */
EXPORT ?LN2LS@@3NA,	DQ 1.90821492927058770002e-10;	/* 3dea39ef 35793c76 */

;	2/sqrt(pi)
EXPORT ?TOSPI@@3NA,	DQ 1.1283791670955125738961589031;
EXPORT ?EUGAM@@3NA,	DQ 0.577215664901532860606512090;

	align 16
EXPORT ?M7FF@@3XA, dq 07fffffffffffffffh, 07fffffffffffffffh	
EXPORT ?M800@@3XA, dq 08000000000000000h, 08000000000000000h	

	IFDEF _M_X64 
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - 
	.code

	IF 0
ENTRY inf, YANXZ

	movsd	xmm0, [?D_INF@@3NA]
	ret

ENTRY qnan, YANPEBD@Z

	movsd	xmm0, [?D_NAN@@3NA]
	ret

ENTRY snan, YANPEBD@Z

	xor		eax, eax
	sub		eax, 1
	or		rax, [?D_INF@@3NA]
	movq	xmm0, rax
	ret
	ENDIF

	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 
	%deftok SPACE 'esp-16'

	.code
;"double __cdecl inf(void)" (?inf@@YANXZ) referenced in function "double __cdecl __atof64(char const *)" (?__atof64@@YANPBD@Z)
;"double __cdecl qnan(char const *)" (?qnan@@YANPBD@Z) referenced in function "double __cdecl __atof64(char const *)" (?__atof64@@YANPBD@Z)
;"double __cdecl snan(char const *)" (?snan@@YANPBD@Z) referenced in function "double __cdecl __atof64(char const *)" (?__atof64@@YANPBD@Z)

	IF 0
ENTRY inf, YANXZ

	movsd	xmm0, [?D_INF@@3NA]
	movsd	[SPACE], xmm0
	fld		_Q [SPACE]
	ret

ENTRY qnan, YANPBD@Z

	movsd	xmm0, [?D_NAN@@3NA]
	movsd	[SPACE], xmm0
	fld		_Q [SPACE]
	ret

ENTRY snan, YANPBD@Z

	xor		eax, eax
	sub		eax, 1
	movsd	xmm0, [?D_INF@@3NA]
	pinsrw	xmm0, eax, 0
	pinsrw	xmm0, eax, 1
	movsd	[SPACE], xmm0
	fld		_Q [SPACE]
	ret
	ENDIF

	ENDIF

END


