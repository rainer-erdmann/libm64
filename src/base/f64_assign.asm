;
;	FILENAME :        f64_assign.asm          
;
;	DESCRIPTION :
;		different upcasts
;		assembly module written for MASM/NASM and VS201x
;
;	REMARKS:
;		no code is necessary for x64
;		all conversions are handled directly by the 
;		compiler without library calls
;		we include implementations here as samples 
;		and as documentation
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

	IFDEF	@Version
	SL TEXTEQU <SHL>
	ELSE
	%deftok SL '<<'
	ENDIF

	.data
R43E	dq 043e0000000000000h			; 2^63
R43F	dq 043f0000000000000h			; 2^64
R41E	dq 041e0000000000000h			; 2^31
R433	dq 04330000000000000h			; 2^52

	align 16
KK0		dd 43300000h, 45300000h, 0, 0	; 2^52, 2^84
KK1		dq 4330000000000000h, 4530000000000000h  

K2BY32	dq 0, 4294967296.0				; 2^32

	IFDEF _M_X64						; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - 
	.code

;	only as doc and test
;	castd(int)
ENTRY castd, YANH@Z
	cvtsi2sd xmm0, ecx
	ret

;	castd(unsigned int)
ENTRY castd, YANI@Z
	mov		ecx, ecx					; zero extend 
	cvtsi2sd xmm0, rcx
	ret

;	castd(__int64)
ENTRY castd, YAN_J@Z
	cvtsi2sd xmm0, rcx
	ret
	
;	castd(unsigned __int64)
ENTRY castd, YAN_K@Z
; from CLANG - tricky but working
	movq	 xmm0, rcx  
	unpcklps xmm0, [KK0] 
	subpd	 xmm0, [KK1]
;	haddpd   xmm0, xmm0					; do not use
	movhlps	 xmm1, xmm0
	addsd	xmm0, xmm1
	ret

;	here the branchless method is faster
ENTRY castdb, YAN_K@Z

	btr		rcx, 63
	cvtsi2sd xmm0, rcx
	jnc		.r2
	addsd	xmm0, [R43E]
.r2: ret


;	castd(float)
ENTRY castd, YANM@Z
	cvtss2sd xmm0, xmm0
	ret

FUNC	ENDP


	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 

	.code

; double __cdecl castd(int)
ENTRY castd, YANH@Z
	fild _D [ARGS]
	ret

; double __vectorcall castd(int) 
ENTRY castd, YQNH@Z
	cvtsi2sd xmm0, ecx
	ret


; double __cdecl castd(unsigned int)
ENTRY castd, YANI@Z
	fild	_D [ARGS]
	bt		_D [ARGS], 31
	jnc		.r
	fadd	_Q [K2BY32+8]
.r:
	ret


	IF 0
;	~7.5
; double __vectorcall castd(unsigned int)
ENTRY castd, YQNI@Z
	cvtsi2sd xmm0, ecx
	test	ecx, ecx
	jns		.r
	addsd	xmm0, _Q [K2BY32+8]
.r:
	ret
	ENDIF

;	from CLANG
; castd(unsigned int)
ENTRY castd, YQNI@Z
	movsd	xmm1, [R433]
	movd	xmm0, ecx
	orpd	xmm0, xmm1
	subsd	xmm0, xmm1
	ret

; castd(__int64)
ENTRY castd, YAN_J@Z
	fild	_Q [ARGS]
	ret


; castd(__int64)
ENTRY castd, YQN_J@Z
	cvtsi2sd xmm1, _D [ARGS+4]
	mov		ecx, [ARGS]
	cvtsi2sd xmm0, ecx
	shr		ecx, 31
	mulsd	xmm1, [K2BY32+8]
	addsd	xmm0, [K2BY32+ecx*8]
	addsd	xmm0, xmm1
	ret		8

; castd(unsigned __int64)
ENTRY castd, YAN_K@Z
;	cvtsi2sd xmm0, rcx
;	test rcx, rcx
;	jns .r
;	addsd	xmm0, [R43F]
;.r:	ret
	fild	_Q [ARGS]
	bt		_D [ARGS+4], 31
	jnc		.r
	fadd	_Q [R43F]
.r:	
	ret

	IF 0
; castd(unsigned __int64)
ENTRY castd, YQN_K@Z
	mov		edx, [ARGS+4]
	mov		ecx, [ARGS]

	cvtsi2sd xmm1, edx
	shr		edx, 31
	jz		.nadd
	addsd	xmm1, [K2BY32+edx*8]
;	addsd	xmm1, [K2BY32+8]
.nadd:
	cvtsi2sd xmm0, ecx
	shr		ecx, 31
	mulsd	xmm1, [K2BY32+8]
	addsd	xmm0, [K2BY32+ecx*8]
	addsd	xmm0, xmm1
	ret		8
	ELSE

;	
; castd(unsigned __int64)
ENTRY castd, YQN_K@Z
ENTRY castdb, YQN_K@Z
;	movsd   xmm1, [ARGS]	; this is slow on x86
	movss	xmm2, _D [ARGS+4]
	shufps	xmm2, xmm2, (1 SL 0) + (0 SL 2) + (1 SL 4) + (1 SL 6) 
	movss	xmm1, _D [ARGS] 
	orpd	xmm1, xmm2

	unpcklps xmm1, [KK0]  
	subpd   xmm1, [KK1]   
	movhlps	xmm0, xmm1
	addsd   xmm0, xmm1  
	ret		8
	ENDIF


; castd(float)
ENTRY castd, YANM@Z
	fld		_D [ARGS]
	ret

; castd(float)
ENTRY castd, YQNM@Z
	cvtss2sd	xmm0, xmm0
	ret

FUNC	ENDP


	
	ENDIF

END

