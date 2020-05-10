;
;	FILENAME :        f64_truncd.asm          
;
;	DESCRIPTION :
;		double truncd(double v)
;		double ceild(double v)
;		double floord(double v)
;		double rintd(double v)
;		long lrintd(double v)
;		long long llrintd(double v)
;		double roundd(double v)
;		long lroundd(double v)
;		long long llroundd(double v)
;		int isintegerd(double v)
;
;		assembly module written for MASM/NASM
;		x86 and x64 code
;		we grouped these function into one file 
;		because we do really use self modifying 
;		code here for the x86 versions.
;		we do not need cpu dispatching for x64 
;		because almost all x64 cpus support sse4.1
;		the x86 versions use sse2 code as default 
;		and can be switched to sse4.1 code.
;
;		remarks:
;		 -	we do not yet dispatch the sse3 inst fisttp
;			used in the x86 version of llround
;			
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

	IMPORT C10,		?C10@@3NB,	QWORD 
	IMPORT C05,		?C05@@3NB 
	IMPORT M7FF,	?M7FF@@3XA
	IMPORT useSSE41, ?useSSE41@@3_NA

	.data
AMASK	dq 08000000000000000h, 08000000000000000h
;	this is nextdown(0.5)
OMASK	dq 03fdfffffffffffffh, 03fdfffffffffffffh 
ZERO	dq 0, 0

RIFA64	dq 04330000000000000h; 	03ff0000000000000h + (52<<52)
		dq 04330000000000000h;	03ff0000000000000h + (52<<52)

_MM_FROUND_TO_NEAREST_INT	EQU 0
_MM_FROUND_TO_NEG_INF		EQU 1
_MM_FROUND_TO_POS_INF		EQU 2
_MM_FROUND_TO_ZERO			EQU 3

	IFDEF _M_X64						; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	IF 0
isintd_o	dq 0
truncd_o	dq 0
rintd_o		dq 0
roundd_o	dq 0
floord_o	dq 0
ceild_o		dq 0

	%macro PATCH 2
	mov		al , [%1]
	cmp		al, 0ebh				; rel8 jmp
	jnz		%%neb
	movzx	eax, _W [%1]
	mov		_D [%2], eax
	mov		_W [%1], 09090h	; replace by nop
	jmp		%%do1
%%neb:
	cmp		al, 0e9h				; rel32
	jnz		%%do1
	mov		rax, _Q [%1]
	mov		byte [%2], al
	shr		rax, 8
	mov		_D [%2+1], eax
	mov		byte [%1], 090h
	mov		_D [%1+1], 090909090h
%%do1:
	%endmacro

	%macro UNPATCH 2
	mov		al , [%2]
	cmp		al, 0ebh				; rel8 jmp
	jnz		%%neb
	movzx	eax, _W [%2]
	mov		_W [%1], ax
	jmp		%%do1
%%neb:
	cmp		al, 0e9h				; rel32
	jnz		%%do1
	mov		rax, _Q [%2]
	mov		byte [%1], al
	shr		rax, 8
	mov		_D [%1+1], eax
%%do1:
	%endmacro
	ENDIF

	.code
 
;	segment mytext PUBLIC ALIGN=16 exec write
;	segment RWCODE;  PUBLIC ALIGN=16

;	global rintt
	PUBLIC rintt 
rintt  dq rintp, rintn, rintd

;	not a good idea; because x64
;	uses rip-relative addressing
;	means we cannot use memory references
;	in the moved code!!!
;	we can use a different technique
;	place a jmp in the first func
;	and changing the offset
;	jmps are
;	EB <rel8> or
;	E9 <rel32>
;	and we have to set the offset to 0
;	the jmp costs ~2.5cy
;	other way:
;	NO sm code;
;	just testing a bit and jumping
;	costs 0.75 if not taken and 2 if taken
ENTRY init_sse41, YAXH@Z

	ret

	IF 0
	test	ecx, ecx
	jz		.no

	test	_B [useSSE41], 1
	jz		.no

	PATCH	isintd_v, isintd_o
	PATCH	truncd_v, truncd_o
	PATCH	rintd_v, rintd_o
	PATCH	roundd_v, roundd_o
	PATCH	floord_v, floord_o
	PATCH	ceild_v, ceild_o

	IF 0

	mov		esi, rintd_vsse41s
	mov		ecx, rintd_vsse41e
	sub		ecx, esi
	mov		edi, rintd_v
rep	movsb	


	mov		esi, roundd_vsse41s
	mov		ecx, roundd_vsse41e
	sub		ecx, esi
	mov		edi, roundd_v
rep	movsb	
	ENDIF
	ret

.no:
	UNPATCH	isintd_v, isintd_o
	UNPATCH	truncd_v, truncd_o
	UNPATCH	rintd_v, rintd_o
	UNPATCH	roundd_v, roundd_o
	UNPATCH	floord_v, floord_o
	UNPATCH	ceild_v, ceild_o
	ENDIF
	ret

;	routines using round
;	most in truncd
;	sin, cos, tan
;	exp + co
;	sinh, cosh, tanh
;
;	again, again
;	how to trunc?
;	0 < x < 1
;	sub 0.5 and rint?
;	|x| > RIFA => isint

ENTRY isintegerd, YA_NN@Z

isintd_v:
	test	_B [useSSE41], 1
	jz		.n41

;	if we have sse4.1.. 
;	(except the very first all x64 cpus have sse4.1)
;	7.0 HAS
;	6.0..7.0 SAN
	roundsd	xmm1, xmm0, 3				; trunc
	subsd	xmm0, xmm1					
	movq	rax, xmm0					; might get trouble with -0
;	test	rax, rax					; but it does not
	shl		rax, 1
	setz	al
	ret


	xorpd	xmm2, xmm2
	comisd	xmm0, xmm2
;	comisd	xmm0, xmm1					; would tell us INF = integer
	setnp	dl
	setz	al
	and		al, dl
	ret

.n41:
	pextrw	eax, xmm0, 3
	shr		eax, 4

	and		eax, 07ffh
	sub		eax, 03ffh
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm3, ecx
	movdqa	xmm1, xmm0
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm3					; shift mask
	pand	xmm1, xmm2					; = trunc(x)

	comisd	xmm0, xmm1					; x == trunc(x)
	setz	al
	ret

.zero:
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setz	al
	ret

.int:
	cmp		eax, 0400h					; INF, NAN 
	setl	al
	ret


;"double __cdecl __trunc(double)" (?__trunc@@YANN@Z)
ENTRY truncd
ENTRY truncd, YANN@Z

;	test	_B [useSSE41], 1
;	jz		.n41
;	4.0..4.5 HAS
;	does not get slow on DEN, INF or NAN
;	6.0..6.6 SAN
;	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
;	ret
.n41:
;	does not get slow on DEN, INF or NAN
;	is correct and not much slower than roundsd SSE4
	movq	rax, xmm0
;	btr		rax, 63
;	shr		rax, 52
	add		rax, rax					; see ftest for this
	shr		rax, 53
	cmp		eax, 3ffh
	jl		.zero						; => |x| < 1.0

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int						; => |x| >= 2^52

	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
;	andpd	xmm0, xmm2
;	here the pand is faster (no domain change)
	pand	xmm0, xmm2
	ret

.zero:
	xorpd	xmm0, xmm0
	ret

.int:
	ret


;	how to trunc, if we only have round?
;	if (x >= 0)
;		if (x - y) > 0 ok, we rounded toward zero
;		else y -= 1
;	else
;		if (x - y) < 0 ok, we rounded toward zero
;		else y += 1

ENTRY ceild, YANN@Z
;	4.0..6.0 HAS; should be 6 from latency
	test	_B [useSSE41], 1
	jz		.n41
	roundsd	xmm0, xmm0, _MM_FROUND_TO_POS_INF
	ret

.n41:
	movq	rax, xmm0
	btr		rax, 63
	shr		rax, 52
	cmp		eax, 03ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax					; => shift
	jle		.int

	movd	xmm1, ecx					
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	andpd	xmm0, xmm2					; => trunc(x)

	comisd	xmm3, xmm0					; x < trunc(x)

	jbe		.nadd1
	addsd	xmm0, _Q [C10]
.nadd1:
	ret

.zero:
	movdqa	xmm3, xmm0
	xorpd	xmm0, xmm0		
	comisd	xmm3, xmm0
	jbe		.nadd2
	movsd	xmm0, _Q [C10]
.nadd2:
	ret

.int:
	ret


ENTRY floord, YANN@Z
;	4.0..6.0 HAS
	test	_B [useSSE41], 1
	jz		.n41
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEG_INF
	ret
.n41:
	movq	rax, xmm0
	btr		rax, 63
	shr		rax, 52
	cmp		eax, 03ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax					; => shift
	jle		.int

	movd	xmm1, ecx					
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	andpd	xmm0, xmm2					; => trunc(x)

	comisd	xmm3, xmm0					; x < trunc(x)
	jae		.nadd
	subsd	xmm0, [C10]
.nadd:
	ret

.zero:
	movdqa	xmm3, xmm0
	xorpd	xmm0, xmm0		
	comisd	xmm3, xmm0
	jae		.nadd2
	subsd	xmm0, [C10]
.nadd2:
	ret

.int:
	ret


ENTRY rintd, YANN@Z
;	4.0..6.0 HAS; should be 6 from latency
	test	_B [useSSE41], 1
	jz		.n41
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEAREST_INT
	ret
.n41:
	IF 0
;	7/9 HAS
	comisd	xmm0, [ZERO]
	jb		.rintn
	addpd	xmm0, [RIFA64]
	subpd	xmm0, [RIFA64]
	ret
.rintn:
	subpd	xmm0, [RIFA64]
	addpd	xmm0, [RIFA64]
	ret
	ENDIF

;	8 HAS
	movsd	xmm1, [RIFA64]
; now copy the sign of x to xmm1
	xorpd	xmm1, xmm0
	andpd	xmm1, _X [M7FF]
	xorpd	xmm1, xmm0
	addsd	xmm0, xmm1
	subsd	xmm0, xmm1
	ret

;	we do not know the sign
;	we always round xmm1 
;	and do not use any other reg
;	and we operate on both packed doubles
ENTRY	rintd
	comisd	xmm1, [ZERO]
	jb		.rintn
	addpd	xmm1, [RIFA64]
	subpd	xmm1, [RIFA64]
	ret
	align 16
.rintn:
	subpd	xmm1, [RIFA64]
	addpd	xmm1, [RIFA64]
	ret

;	we know the sign of xmm1 is pos or zero
ENTRY	rintp
	addpd	xmm1, [RIFA64]
	subpd	xmm1, [RIFA64]
	ret

;	we know the sign of xmm0 is neg or zero
ENTRY	rintn
	subpd	xmm1, [RIFA64]
	addpd	xmm1, [RIFA64]
	ret


;"long __cdecl lrintd(double)" (?lrintd@@YAJN@Z)
ENTRY lrintd, YAJN@Z
;	5.5..6.0 HAS
;	6.0 SAN

	cvtsd2si	eax, xmm0
	ret

;"__int64 __cdecl llrintd(double)" (?llrintd@@YA_JN@Z)
ENTRY llrintd, YA_JN@Z
;	5.0..5.0 HAS
;	6.0 SAN

	cvtsd2si	rax, xmm0
	ret

ENTRY roundd, YANN@Z
roundd_v:
	test	_B [useSSE41], 1
	jz		.n41
;	6.0..6.3 SSE SAN
;	5.0..5.0 HAS 
	movdqa	xmm1, xmm0
	andpd	xmm0, _X [AMASK]
	orpd	xmm0, _X [OMASK]
	addsd	xmm0, xmm1
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	ret

.n41:
	movdqa	xmm1, xmm0
	andpd	xmm0, _X [AMASK]
	orpd	xmm0, _X [OMASK]
	addsd	xmm0, xmm1
	movq	rax, xmm0
	btr		rax, 63
	shr		rax, 52
	cmp		eax, 03ffh
	jl		.zero

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int

	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	andpd	xmm0, xmm2
	ret

.zero:
	xorpd	xmm0, xmm0
	ret

.int:
	ret






	align 16	
;	6.0..7.3 AVX SAN
	vandpd	xmm1, xmm0, _X [AMASK]
	orpd	xmm1, _X [OMASK]
	addpd	xmm0, xmm1
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	ret


ENTRY lroundd, YAJN@Z
;	4.0..5.5 HAS 
;	6.0 SSE SAN

	movdqa	xmm1, xmm0
	andpd	xmm0, _X [AMASK]
	orpd	xmm0, _X [OMASK]
	addsd	xmm0, xmm1
	cvttsd2si	eax, xmm0
	ret

	align 16
	vandpd	xmm1, xmm0, _X [AMASK]
	orpd	xmm1, _X [OMASK]
	addpd	xmm0, xmm1
	cvttsd2si	eax, xmm0
	ret

ENTRY llroundd, YA_JN@Z
;	4.0..6.0 HAS 
;	6.0..6.5 SSE SAN

	movdqa	xmm1, xmm0
	andpd	xmm0, _X [AMASK]
	orpd	xmm0, _X [OMASK]
	addpd	xmm0, xmm1
	cvttsd2si	rax, xmm0
	ret

	align 16	
	vandpd	xmm1, xmm0, _X [AMASK]
	orpd	xmm1, _X [OMASK]
	addpd	xmm0, xmm1
	cvttsd2si	rax, xmm0
	ret

FUNC ENDP

	ELSE								
; x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 

	.data

	PUBLIC rintt 
rintt  dd rintp, rintn, rintd

	.code

;	void __cdecl init_sse41(int)
;	WARNING:
;	we USE self modifying code here!
;	always check code sizes after changes
;
ENTRY init_sse41, YAXH@Z

	mov		eax, _D [ARGS]
	test	eax, eax
	jz		.no

	test	_B [useSSE41], 1
	jz		.no

	push	edi
	push	esi

	mov		esi, isintd_csse41s
	mov		ecx, isintd_csse41e
	sub		ecx, esi
	mov		edi, isintd_c
rep	movsb	

	mov		esi, truncd_csse41s
	mov		ecx, truncd_csse41e
	sub		ecx, esi
	mov		edi, truncd_c
rep	movsb	

	mov		esi, truncd_vsse41s
	mov		ecx, truncd_vsse41e
	sub		ecx, esi
	mov		edi, truncd_v
rep	movsb	

	mov		esi, ceild_csse41s
	mov		ecx, ceild_csse41e
	sub		ecx, esi
	mov		edi, ceild_c
rep	movsb	

	mov		esi, ceild_vsse41s
	mov		ecx, ceild_vsse41e
	sub		ecx, esi
	mov		edi, ceild_v
rep	movsb	

	mov		esi, floord_csse41s
	mov		ecx, floord_csse41e
	sub		ecx, esi
	mov		edi, floord_c
rep	movsb	

	mov		esi, floord_vsse41s
	mov		ecx, floord_vsse41e
	sub		ecx, esi
	mov		edi, floord_v
rep	movsb	

	mov		esi, rintd_csse41s
	mov		ecx, rintd_csse41e
	sub		ecx, esi
	mov		edi, rintd_c
rep	movsb	

	mov		esi, rintd_vsse41s
	mov		ecx, rintd_vsse41e
	sub		ecx, esi
	mov		edi, rintd_v
rep	movsb	

	mov		esi, roundd_csse41s
	mov		ecx, roundd_csse41e
	sub		ecx, esi
	mov		edi, roundd_c
rep	movsb	

	mov		esi, roundd_vsse41s
	mov		ecx, roundd_vsse41e
	sub		ecx, esi
	mov		edi, roundd_v
rep	movsb	

	pop		esi
	pop		edi

.no:
	ret

; "bool __cdecl isintegerd(double)" (?isintegerd@@YA_NN@Z)
ENTRY isintegerd, YA_NN@Z
;	8.0..9.0 HAS SSE2
;	slower SAN
	IF 0
isintd_c:
	mov		eax, _D [esp+4+4]
	shr		eax, 20
	and		eax, 07ffh
	sub		eax, 03ffh
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm3, ecx
	movsd	xmm0, _X [esp+4]			; x
	movdqa	xmm1, xmm0
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm3					; shift mask
	pand	xmm1, xmm2					; = trunc(x)
.sub:
	subsd	xmm0, xmm1					; x - trunc(x)
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setz	al
	ret


.zero:
	movsd	xmm0, _X [esp+4]
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setz	al
	ret


.int:
	cmp		eax, 0400h					; INF, NAN 
	setl	al
	ret

	ELSE

isintd_c:
;	10..13 SAN 
	movsd	xmm0, _Q [ARGS]
	pextrw	eax, xmm0, 3
	shr		eax, 4

	and		eax, 07ffh
	sub		eax, 03ffh
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm3, ecx
	movdqa	xmm1, xmm0
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm3					; shift mask
	pand	xmm1, xmm2					; = trunc(x)

	comisd	xmm0, xmm1					; x == trunc(x)
	setz	al
	ret

.zero:
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setz	al
	ret

.int:
	cmp		eax, 0400h					; INF, NAN 
	setl	al
	ret
	ENDIF


	align 16
isintd_csse41s:
; if we have sse4.1...
;	7.4..8.4 HAS
;	9.0 SAN
	movsd	xmm0, _X [ARGS]
	roundsd	xmm1, xmm0, 3
	subsd	xmm0, xmm1					; sub necc to handle INF
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setnp	ah
	setz	al
	and		al, ah
	ret
isintd_csse41e:



ENTRY isintegerd, YQ_NN@Z

;	10..13 SAN 
;	movsd	xmm0, _Q [ARGS]
	pextrw	eax, xmm0, 3
	shr		eax, 4

	and		eax, 07ffh
	sub		eax, 03ffh
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm3, ecx
	movdqa	xmm1, xmm0
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm3					; shift mask
	pand	xmm1, xmm2					; = trunc(x)

	comisd	xmm0, xmm1					; x == trunc(x)
	setz	al
	ret

.zero:
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	setz	al
	ret

.int:
	cmp		eax, 0400h					; INF, NAN 
	setl	al
	ret

;	--------------------------------------
;	TRUNC 
;	--------------------------------------

ENTRY truncd, YANN@Z
;	if we do not have sse4.1 ... handmade with sse
;	~12 SAN SSE [1..1e6]
;	7.0 HAS SSE
truncd_c:
	mov		eax, _D [esp+4+4]
	shr		eax, 20
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 0
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm1, ecx
	movsd	xmm0, _X [esp+4]
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	pand	xmm0, xmm2
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.zero:
	fldz
	ret

.int:
	fld		_Q [esp+4]
	ret


;	easiest and fastest way if we have sse4.1
;	8..10 SAN
	align 16
truncd_csse41s:
	movsd	xmm0, _X [esp+4]	
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret
truncd_csse41e:


; "double __vectorcall truncd(double)" (?truncd@@YQNN@Z)

;	if we do not have sse4.1 ... handmade with sse
;	~10 SAN [1..1e6]
;	~8 SAN
ENTRY truncd, YQNN@Z
truncd_v:

	pextrw	eax, xmm0, 3
	btr		eax, 15
;	cmp		eax, 03ff0h + (52 << 4)
;	jge		.int
	cmp		eax, 03ff0h
	jl		.zero

	shr		eax, 4
	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	jle		.int

	movd	xmm1, ecx
;	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
;	psllq	xmm2, xmm1
;	pand	xmm0, xmm2
	psrlq	xmm0, xmm1
	psllq	xmm0, xmm1
	ret

.zero:
	pxor	xmm0, xmm0
	ret

.int:
	ret

	align 16
truncd_vsse41s:
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	ret
truncd_vsse41e:


;	--------------------------------------
;	CEIL
;	--------------------------------------

ENTRY ceild, YANN@Z
;	if we do not have sse4.1 ... handmade with sse
;	~14 SAN [1..1e6]
ceild_c:
	mov		eax, _D [esp+4+4]
	shr		eax, 20
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 0
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax					; => shift
	movd	xmm1, ecx					
	movsd	xmm0, _X [esp+4]
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	pand	xmm0, xmm2					; => trunc(x)

	subsd	xmm3, xmm0					; x - trunc(x)
.cmp:
	pxor	xmm1, xmm1	
	comisd	xmm3, xmm1
	jbe		.nadd
	addsd	xmm0, _Q [C10]
.nadd:
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.zero:
	movsd	xmm3, _X [esp+4]
	pxor	xmm0, xmm0		
	jmp		.cmp


.int:
	fld		_Q [esp+4]
	ret

;	the easiest and fastest way if we have sse4.1
	align 16
ceild_csse41s:
	movsd	xmm0, _X [esp+4]	
	roundsd	xmm0, xmm0, _MM_FROUND_TO_POS_INF
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret
ceild_csse41e:

;	vectorcall
ENTRY ceild, YQNN@Z
ceild_v:
	pextrw	eax, xmm0, 3
	btr		eax, 15
	cmp		eax, 03ff0h
	jl		.zero
	cmp		eax, 03ff0h + (52 << 4)
	jge		.int

	shr		eax, 4

	mov		ecx, 52 + 3ffh
	sub		ecx, eax					; => shift
	movd	xmm1, ecx					
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	pand	xmm0, xmm2					; => trunc(x)

	subsd	xmm3, xmm0					; x - trunc(x)
	pxor	xmm1, xmm1	
	comisd	xmm3, xmm1
	jbe		.nadd1
	addsd	xmm0, _Q [C10]
.nadd1:
	ret

.zero:
	movdqa	xmm3, xmm0
	pxor	xmm0, xmm0		
	comisd	xmm3, xmm0
	jbe		.nadd2
	movsd	xmm0, _Q [C10]
.nadd2:
	ret

.int:
	ret

	align 16
ceild_vsse41s:
	roundsd	xmm0, xmm0, _MM_FROUND_TO_POS_INF
	ret
	align 16
ceild_vsse41e:


;	--------------------------------------
;	FLOOR
;	--------------------------------------

ENTRY floord, YANN@Z

floord_c:
	mov		eax, _D [esp+4+4]
	shr		eax, 20
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 0
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax					; => shift
	movd	xmm1, ecx					
	movsd	xmm0, _X [esp+4]
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	pand	xmm0, xmm2					; => trunc(x)

	subsd	xmm3, xmm0					; x - trunc(x)
.cmp:
	pxor	xmm1, xmm1	
	comisd	xmm3, xmm1
	jae		.nadd
	subsd	xmm0, _X [C10]
.nadd:
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret

.zero:
	movsd	xmm3, _X [esp+4]
	pxor	xmm0, xmm0		
	jmp		.cmp


.int:
	fld		_Q [esp+4]
	ret

	align 16
floord_csse41s:
	movsd	xmm0, _X [esp+4]	
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEG_INF
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret
floord_csse41e:
	

ENTRY floord, YQNN@Z
floord_v:
	pextrw	eax, xmm0, 3
	shr		eax, 4		
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 0
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax					; => shift
	movd	xmm1, ecx					
	movdqa	xmm3, xmm0					; copy for later use
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1					; mask
	pand	xmm0, xmm2					; => trunc(x)

	subsd	xmm3, xmm0					; x - trunc(x)
.cmp:
	pxor	xmm1, xmm1	
	comisd	xmm3, xmm1
;	jbe		.nadd
	jae		.nadd
	subsd	xmm0, _X [C10]
.nadd:
	ret

.zero:
	movdqa	xmm3, xmm0
	pxor	xmm0, xmm0		
	jmp		.cmp

.int:
	ret

	align 16
floord_vsse41s:
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEG_INF
	ret
floord_vsse41e:

;	--------------------------------------
;	RINT
;	--------------------------------------

	.data
RIFA80 dd 3f800000h + (63<<23)
	.code

ENTRY rintd, YANN@Z
rintd_c:
	fld		_Q [ARGS]
	mov		eax, _D [ARGS+4]
	and		eax, 07ff00000h
	cmp		eax, 03ff00000h + (52 << 20)
	jge		.ret
	fadd	_D [RIFA80]
	fsub	_D [RIFA80]
.ret:
	ret
	





	fld		_Q [esp+4]
	frndint	
	ret
	align 16
	nop
	align 16
rintd_csse41s:
; 8 SAN
	movsd	xmm0, _X [esp+4]	
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEAREST_INT
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	ret
rintd_csse41e:

;	#### not correct for negative x! - but now..
;	vectorcall
ENTRY rintd, YQNN@Z
rintd_v:
	IF 0
	pextrw	eax, xmm0, 3
	bt		eax, 15
	jc		.neg
	addsd	xmm0, [RIFA64]
	subsd	xmm0, [RIFA64]
	ret
.neg:
	subsd	xmm0, [RIFA64]
	addsd	xmm0, [RIFA64]
	ret
	ENDIF

	movsd	xmm1, [RIFA64]
; now copy the sign of x to xmm1
	pxor	xmm1, xmm0
	pand	xmm1, [M7FF]
	pxor	xmm1, xmm0
	addsd	xmm0, xmm1
	subsd	xmm0, xmm1
	ret



	addsd	xmm0, [RIFA64]
	subsd	xmm0, [RIFA64]
	ret

	pextrw	eax, xmm0, 3
	and		eax, 07ff0h
	cmp		eax, 03ff0h + (31 << 4)
	jge		.ge31

	cvtsd2si	eax, xmm0
	cvtsi2sd	xmm0, eax
	ret

.ge31: 
	sub		esp, 8
	movsd	_X [esp], xmm0
	fld		_Q [esp]
	frndint	
	fstp	_Q [esp]
	movsd	xmm0, _X [esp]
	add		esp, 8
	ret

	align 16
rintd_vsse41s:
	roundsd	xmm0, xmm0, _MM_FROUND_TO_NEAREST_INT
	ret
rintd_vsse41e:


;	we do not know the sign
;	we always round xmm1 and do not use 
;	any other reg
ENTRY	rintd
	comisd	xmm1, [ZERO]
	jb		.rintn
	addpd	xmm1, [RIFA64]
	subpd	xmm1, [RIFA64]
	ret
	align 16
.rintn:
	subpd	xmm1, [RIFA64]
	addpd	xmm1, [RIFA64]
	ret

;	we know the sign of xmm1 is pos or zero
ENTRY	rintp
	addpd	xmm1, [RIFA64]
	subpd	xmm1, [RIFA64]
	ret

;	we know the sign of xmm0 is neg or zero
ENTRY	rintn
	subpd	xmm1, [RIFA64]
	addpd	xmm1, [RIFA64]
	ret



;	--------------------------------------
;	LRINT 
;	--------------------------------------

;	never a different way necessary
ENTRY lrintd, YAJN@Z

	cvtsd2si eax, _Q [ARGS]
	ret


;	"long __vectorcall lrintd(double)" (?lrintd@@YQJN@Z)
ENTRY lrintd, YQJN@Z

	cvtsd2si eax, xmm0
	ret

;	--------------------------------------
;	LLRINT
;	--------------------------------------

;"__int64 __cdecl llrintd(double)" (?llrintd@@YA_JN@Z)
ENTRY llrintd, YA_JN@Z
;	no xmm way...
;	no SSE3 used
;	<10 SAN
	fld		_Q [ARGS]
	fistp	_Q [ARGS]
	mov		eax, _D [ARGS]
	mov		edx, _D [ARGS+4]
	ret

;"__int64 __vectorcall llrintd(double)" (?llrintd@@YA_JN@Z)
ENTRY llrintd, YQ_JN@Z

	sub		esp, 8
	movsd	_Q [esp], xmm0
	fld		_Q [esp]
	fistp	_Q [esp]
	mov		eax, _D [esp]
	mov		edx, _D [esp+4]
	add		esp, 8
	ret

;	--------------------------------------
;	ROUND 
;	--------------------------------------

;	double __cdecl roundd(double)
ENTRY roundd, YANN@Z

	movsd	xmm0, _X [ARGS]	
	movdqa	xmm1, xmm0
	andpd	xmm1, _X [AMASK]
	orpd	xmm1, _X [OMASK]
	addpd	xmm0, xmm1
roundd_c:
	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 0
	jl		.zero
	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	pand	xmm0, xmm2
	movsd	_X [ARGS], xmm0
	fld		_Q [ARGS]
	ret

.zero:
	fldz
	ret

.int:
	movsd	_X [ARGS], xmm0
	fld		_Q [ARGS]
	ret

	align 16
roundd_csse41s:
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	movsd	_X [ARGS], xmm0
	fld		_Q [ARGS]
	ret
roundd_csse41e:


;	double __vectorcall roundd(double)
ENTRY roundd, YQNN@Z
; 10.4..10.9 SAN SSE
; 9.0 SAN SSE
roundd_v:
	movdqa	xmm1, xmm0
	pand	xmm0, _X [AMASK]
	por		xmm0, _X [OMASK]
	addsd	xmm0, xmm1
	pextrw	eax, xmm0, 3
	btr		eax, 15
	cmp		eax, 03ff0h + (31 << 4)
	jge		.diff

	cvttpd2dq	xmm0, xmm0
	cvtdq2pd	xmm0, xmm0
	ret

.diff:
	cmp		eax, 03ff0h + (52 << 4)
	jge		.int

	shr		eax, 4

	mov		ecx, 52 + 3ffh
	sub		ecx, eax
	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	pand	xmm0, xmm2
	ret

.zero:
	pxor	xmm0, xmm0
	ret

.int:
	ret

	align 16
roundd_vsse41s:
;	8.0 SAN
;	6.7..7.5 HAS
	movdqa	xmm1, xmm0
	pand	xmm1, _X [AMASK]
	por		xmm1, _X [OMASK]
	addsd	xmm0, xmm1
	roundsd	xmm0, xmm0, _MM_FROUND_TO_ZERO
	ret
roundd_vsse41e:

;	--------------------------------------
;	LROUND 
;	--------------------------------------

ENTRY lroundd, YAJN@Z

	IF 1
;	9.3..9.6 SAN
	movsd	xmm0, _X [ARGS]
	movdqa	xmm1, xmm0
	pand	xmm1, _X [AMASK]
	por		xmm1, _X [OMASK]
	addsd	xmm0, xmm1
	cvttsd2si eax, xmm0
	ret
	ENDIF

;	10.0..10.4 SAN
	fld		_Q [ARGS]
	mov		eax, _D [ARGS+4]
	fld		_Q [OMASK]
	test	eax, eax
	jns		.pos
	fchs
.pos:
	faddp	ST(1), ST(0)
	fisttp	_D [ARGS]					; SSE3
	mov		eax, _D [ARGS]
	ret

;	long __vectorcall lroundd(double)
ENTRY lroundd, YQJN@Z
	IF 1
;	8.0 SAN
;	7.4..7.8 HAS
	movdqa	xmm1, xmm0
	pand	xmm0, _X [AMASK]			; 0x80..00
	por		xmm0, _X [OMASK]			; 0x3fdf..ff
	addsd	xmm0, xmm1
	cvttsd2si eax, xmm0
	ret
	ELSE
;	7.4 HAS AVX; more inst, but no mem
;	8.3..8.9 SAN
;	8.0 SAN pand/por
	pcmpeqw	xmm3, xmm3					; 0xff..ff
	vpsllq	xmm2, xmm3, 63
;	vandpd	xmm1, xmm0, xmm2 
	vpand	xmm1, xmm0, xmm2 
	mov		eax, 03fdfh
	pinsrw	xmm3, eax, 3
;	orpd	xmm1, xmm3
	por		xmm1, xmm3
	addsd	xmm0, xmm1
	cvttsd2si eax, xmm0
	ret
	ENDIF

;	--------------------------------------
;	LLROUND 
;	--------------------------------------

ENTRY llroundd, YA_JN@Z
	IF 1
;	without SSE3
;	19 SAN
;	15.5..16.5 HAS
	movsd	xmm0, _X [ARGS]
	movdqa	xmm1, xmm0
	pand	xmm1, _X [AMASK]
	por		xmm1, _X [OMASK]
	addsd	xmm0, xmm1

	pextrw	eax, xmm0, 3
	shr		eax, 4
	and		eax, 07ffh
	sub		eax, 03ffh
	cmp		eax, 31
	jl		.short

	cmp		eax, 52
	jge		.int

	mov		ecx, 52
	sub		ecx, eax
	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	pand	xmm0, xmm2

.int:
	movsd	_X [esp+4], xmm0
	fld		_Q [esp+4]
	fistp	_Q [esp+4]
	mov		eax, _D [esp+4]
	mov		edx, _D [esp+4+4]
	ret

.short:
.zero:
	cvttsd2si eax, xmm0
	cdq
	ret

	ENDIF


ENTRY llroundd, YQ_JN@Z
	
;	without SSE3
;	19 SAN
;	15.5..16.5 HAS
;	~10 with fisttp; also the shortest code 
	movdqa	xmm1, xmm0
	pand	xmm0, _X [AMASK]
	por		xmm0, _X [OMASK]
	addsd	xmm0, xmm1

	IF 0
	sub		esp, 8
	movsd	_X [esp], xmm0
	fld		_Q [esp]
	fisttp	_Q [esp]
	pop		eax
	pop		edx
	ret
	ENDIF


	pextrw	eax, xmm0, 3
	btr		eax, 15
	cmp		eax, 3ff0h + (31 << 4)
	jge		.diff

	cvttsd2si eax, xmm0
	cdq
	ret

.diff:
	cmp		eax, 3ff0h + (52 << 4)
	jge		.int

	shr		eax, 4

	mov		ecx, 52 + 3ffh
	sub		ecx, eax

	movd	eax, xmm0
	psrlq	xmm0, 32
	movd	edx, xmm0

	test	edx, edx
	sets	ch

	and		edx, 000fffffh
	or		edx, 00100000h

	shrd	eax, edx, cl
	shr		edx, cl
	test	ch, ch
	jnz		.neg

	ret
.neg:
	neg		eax
	adc		edx, 0
	neg		edx
	ret

	movd	xmm1, ecx
	pcmpeqw	xmm2, xmm2					; generate 0xff..ff
	psllq	xmm2, xmm1
	pand	xmm0, xmm2					; => trunc

.int:
	sub		esp, 8
	movsd	_X [esp], xmm0
	fld		_Q [esp]
	fistp	_Q [esp]
	mov		eax, _D [esp]
	mov		edx, _D [esp+4]
	add		esp, 8
	ret

.short:
.zero:
	cvttsd2si eax, xmm0
	cdq
	ret

FUNC ENDP

	ENDIF

	END