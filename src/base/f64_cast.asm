;
;	FILENAME :        f64_cast.asm          
;
;	DESCRIPTION :
;		different up and downcasts
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
R43E	dq 043e0000000000000h				; 2^63
R41E	dq 041e0000000000000h				; 2^31


	IFDEF _M_X64						; 64bit

	.code
;	no code necessary x64
;	only as doc

ENTRY cast_int, YAHN@Z
	cvttsd2si eax, xmm0
	ret

ENTRY cast_uint, YAIN@Z
	cvttsd2si rax, xmm0
	ret

ENTRY cast_int64, YA_JN@Z
	cvttsd2si rax, xmm0
	ret

ENTRY cast_uint64, YA_KN@Z
; from CLANG
	movsd       xmm1, [R43E]  
	movapd      xmm2, xmm0  
	subsd       xmm2, xmm1  
	cvttsd2si   rax, xmm2  
	mov         rcx, 8000000000000000h  
	xor         rcx, rax  
	cvttsd2si   rax, xmm0  
	ucomisd     xmm0, xmm1  
	cmovae      rax, rcx  
	ret

;	although not branchless this is faster 
ENTRY cast_uint64b, YA_KN@Z

	movsd       xmm1, [R43E]  
	ucomisd     xmm0, xmm1  
	jae			.l
	cvttsd2si   rax, xmm0  
	ret
.l:
	subsd		xmm0, xmm1
	cvttsd2si   rax, xmm0  
	bts			rax, 63
	ret

	.code

	IF 0

;	u32 dtoui3(double)
ENTRY 	_dtoui3

	cvttsd2si	eax, xmm0
	ret

ENTRY	dtotest2, YQ_JN@Z

	sub		esp, 8
	movsd	_Q [esp], xmm0
	fld		_Q [esp]
	fisttp	_Q [esp]
	mov		eax, _D [esp]
	mov		edx, _D [esp+4]
	add		esp, 8
	ret


;	reference impl 
ENTRY	dtotest1, YA_JN@Z

	fld		_Q [esp+4]
	fisttp	_Q [esp+4]
	mov		eax, _D [esp+4]
	mov		edx, _D [esp+4+4]
	ret


;	i64 dtol3(double)
ENTRY 	_dtol3
;	u64 dtoul3(double)
ENTRY 	_dtoul3
dtol3:
	pextrw	ecx, xmm0, 3
	mov		edx, ecx
	and		ecx, 07fffh
	cmp		ecx, 03ff0h + (31 << 4)
	jge		.lrg8

	cvttsd2si	eax, xmm0
	cdq
	ret

.lrg8:
	mov		eax, ecx
	and		eax, 0fh
	or		eax, 10h
	pinsrw	xmm0, eax, 3	
	shr		ecx, 4
	cmp		ecx, 3ffh + 52
	ja		.left

	mov		eax, 3ffh + 52
	sub		eax, ecx
	movd	xmm2, eax
	psrlq	xmm0, xmm2
	test	edx, 08000h
	jnz		.neg1
	movd	eax, xmm0
	psrlq	xmm0, 32
	movd	edx, xmm0
	ret

.neg1:
	pxor	xmm2, xmm2
	psubq	xmm2, xmm0
	movd	eax, xmm2
	psrlq	xmm2, 32
	movd	edx, xmm2
	ret


.left:
	cmp		ecx, 3ffh + 63 
	jae		.ovr
	sub		ecx, 3ffh + 52
	movd	xmm2, ecx
	psllq	xmm0, xmm2
	test	edx, 08000h
	jnz		.neg2
	movd	eax, xmm0
	psrlq	xmm0, 32
	movd	edx, xmm0
	ret

.neg2:
	pxor	xmm2, xmm2
	psubq	xmm2, xmm0
	movd	eax, xmm2
	psrlq	xmm2, 32
	movd	edx, xmm2
	ret

.ovr:
	mov		edx, 080000000h
	xor		eax, eax
	ret


;	FLOAT

; u32 ftoui3(float)
ENTRY 	_ftoui3

	cvttss2si	eax, xmm0
	ret


; i64 ftol3(float)
ENTRY 	_ftol3
; u64 ftoul3(float)
ENTRY 	_ftoul3

;	pextrw	ecx, xmm0, 3
	movd	ecx, xmm0
	mov		edx, ecx
	shr		ecx, 23
	and		ecx, 0ffh
	cmp		ecx, 07fh + 31
	jge		.lrg8

	cvttss2si	eax, xmm0
	cdq
	ret

.lrg8:
	mov		eax, edx
	and		eax, 007fffffh
	or		eax, 00800000h
	cmp		ecx, 7fh + 22
	ja		.left

	mov		dl, 7fh + 22
	sub		dl, cl
	mov		cl, dl
	shr		eax, cl

	test	edx, edx
	js		.neg1
	ret

.neg1:
	pxor	xmm2, xmm2
	psubq	xmm2, xmm0
	movd	eax, xmm2
	psrlq	xmm2, 32
	movd	edx, xmm2
;	pextrd	edx, xmm2, 1		; SSE4.1
	ret


.left:
	cmp		ecx, 7fh + 63 
	jae		.ovr
	sub		ecx, 7fh + 22

	movd	xmm2, ecx
	movd	xmm0, eax
	psllq	xmm0, xmm2
	test	edx, edx
	js		.neg2
	movd	eax, xmm0
	psrlq	xmm0, 32
	movd	edx, xmm0
	ret

.neg2:
	pxor	xmm2, xmm2
	psubq	xmm2, xmm0
	movd	eax, xmm2
	psrlq	xmm2, 32
	movd	edx, xmm2
	ret

.ovr:
	mov		edx, 080000000h
	xor		eax, eax
	ret


; u64 ftoul3(float)
;ENTRY 	_ftoul3
	cvtss2sd xmm0, xmm0
	jmp	dtol3


;	integers to float

;	u64 to double 
ENTRY	_ultod3
	cvtsi2sd xmm1, edx
	shr		edx, 31
	addsd	xmm1, [K2BY32+edx*8]
	cvtsi2sd xmm0, ecx
	shr		ecx, 31
	mulsd	xmm1, [K2BY32+8]
	addsd	xmm0, [K2BY32+ecx*8]
	addsd	xmm0, xmm1
	ret

;	i64 to double 
ENTRY	_ltod3 
; 9.0 HAS SSE
; 11.0 HAS FMA
	cvtsi2sd xmm1, edx
	cvtsi2sd xmm0, ecx
	shr		ecx, 31
	mulsd	xmm1, [K2BY32+8]
	addsd	xmm0, [K2BY32+ecx*8]
	addsd	xmm0, xmm1
; FMA:
;	addsd	xmm0, [K2BY32+ecx*8]
;	vfmadd231sd xmm0, xmm1, [K2BY32+8]

	ret

	ENDIF

ENTRY testfunc 


	ret

FUNC	ENDP


	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 

	.code



;	double to integer types

; ENTRY cast_int, 
ENTRY cast_int, YAHN@Z

	cvttsd2si eax, _Q [ARGS]
	ret

ENTRY cast_int, YQHN@Z

	cvttsd2si eax, xmm0
	ret


ENTRY cast_uint, YAIN@Z
;	from CLANG

	movsd	xmm2, _Q [ARGS]  
	movsd   xmm0, [R41E]  
	movapd	xmm1, xmm2  
	cvttsd2si ecx, xmm2  
	subsd   xmm1, xmm0  
	cvttsd2si eax, xmm1  
	xor     eax, 80000000h  
	ucomisd xmm2, xmm0  
	cmovb   eax, ecx  
	ret


ENTRY cast_uint, YQIN@Z
;	from CLANG

	movsd   xmm2, [R41E]  
	movapd	xmm1, xmm0  
	cvttsd2si ecx, xmm0					; convert < 2^31
	subsd   xmm1, xmm2					; x - 2^31
	cvttsd2si eax, xmm1  
	xor     eax, 80000000h				; r += 2^31
	ucomisd xmm0, xmm2  
	cmovb   eax, ecx  
	ret

	IF 0
;(?cast_int64@@YQHN@Z)
ENTRY cast_int64, YQ_JN@Z
;	from CLANG
	sub		esp, 16
	movsd	[esp+8], xmm0
	fld		_Q [esp+8]
	fnstcw	_W [esp]  
	movzx   eax, _W [esp]  
    or      eax, 0C00h  
	mov     _W [esp+4],ax  
	fldcw   _W [esp+4]  
	fistp   _Q [esp+8]  
    fldcw   _W [esp]  
	mov		eax, _D[esp+8]
	mov		edx, _D[esp+12]
	add		esp, 16
	ret
	ENDIF

	IF 0
;	we take our dtol3
ENTRY cast_int64, YQ_JN@Z

	pextrw	ecx, xmm0, 3
	mov		edx, ecx					; save for later use
	btr		ecx, 15						; clear sign
	cmp		ecx, 03ff0h + (31 SL 4)		; >=2^31
	jge		.lrg8

	cvttsd2si	eax, xmm0				; easiest way
	cdq
	ret

.lrg8:
	mov		eax, ecx					; org high word
	and		eax, 0fh					; clear exp
	or		eax, 10h					; set hidden bit
	pinsrw	xmm0, eax, 3	

	shr		ecx, 4
	cmp		ecx, 3ffh + 52				; >2^52?
	ja		.left						; => shift left

	mov		eax, 3ffh + 52
	sub		eax, ecx
	movd	xmm2, eax					
	psrlq	xmm0, xmm2					; shift right 		
	test	edx, 08000h					; x < 0?
	jnz		.neg1

	movd	eax, xmm0					; lo part
	pshufd	xmm0, xmm0, (1 SL 0) + (0 SL 1)
	movd	edx, xmm0					; hi part
	ret

.neg1:
	pxor	xmm2, xmm2					
	psubq	xmm2, xmm0					; n = 0 - n				
	movd	eax, xmm2					; lo part
	pshufd	xmm2, xmm2, (1 SL 0) + (0 SL 1)
	movd	edx, xmm2					; hi part
	ret


.left:
	cmp		ecx, 3ffh + 63 
	jae		.ovr

	sub		ecx, 3ffh + 52
	movd	xmm2, ecx
	psllq	xmm0, xmm2					; shift 
	test	edx, 08000h
	jnz		.neg2

	movd	eax, xmm0
	pshufd	xmm0, xmm0, (1 SL 0) + (0 SL 1)
	movd	edx, xmm0
	ret

.neg2:
	pxor	xmm2, xmm2
	psubq	xmm2, xmm0					; n = 0 - n
	movd	eax, xmm2
	pshufd	xmm2, xmm2, (1 SL 0) + (0 SL 1)
	movd	edx, xmm2
	ret

.ovr:
	mov		edx, 080000000h				; return 0x80000000'00000000
	xor		eax, eax
	ret
	ENDIF



;	we take our dtol3 - again, but use gp to shift
ENTRY cast_int64, YQ_JN@Z

	pextrw	ecx, xmm0, 3
	btr		ecx, 15						; clear sign
	cmp		ecx, 03ff0h + (31 SL 4)		; >=2^31
	jge		.lrg8

	cvttsd2si	eax, xmm0				; easiest way
	cdq
	ret

.lrg8:
;	x is positive
	movd	eax, xmm0					; lo
	pshufd	xmm0, xmm0, (1 SL 0) + (0 SL 1)
	movd	edx, xmm0					; hi
	test	edx, edx
	js		.neg

	and		edx, 000fffffh				; strip exp
	or		edx, 00100000h				; set hidden	

	shr		ecx, 4
	cmp		ecx, 3ffh + 52				; >2^52?
	ja		.leftp						; => shift left

	neg		ecx
	add		ecx, 3ffh + 52
;	can cl be > 31 here? no - CANNOT

	shrd	eax, edx, cl
	shr		edx, cl
	ret

.leftp:
	cmp		ecx, 3ffh + 63 
	jae		.ovr

	sub		ecx, 3ffh + 52
	shld	edx, eax, cl
	shl		eax, cl
	ret

.neg:
;	x is negative
	and		edx, 000fffffh
	or		edx, 00100000h

	shr		ecx, 4
	cmp		ecx, 3ffh + 52				; >2^52?
	ja		.leftn						; => shift left

	neg		ecx							; sh = 52 - bex
	add		ecx, 3ffh + 52

	shrd	eax, edx, cl
	shr		edx, cl

	neg		eax
	adc		edx, 0
	neg		edx

	ret

.leftn:
	cmp		ecx, 3ffh + 63 
	jae		.ovr

	sub		ecx, 3ffh + 52				; sh = bex - 52
	shld	edx, eax, cl
	shl		eax, cl

	neg		eax
	adc		edx, 0
	neg		edx

	ret


.ovr:
	mov		edx, 080000000h				; return 0x80000000'00000000
	xor		eax, eax
	ret


	IF 0
ENTRY cast_uint64, YQ_KN@Z

	movsd	xmm3, [R43E]  
	movapd	xmm2, xmm0
	movapd	xmm4, xmm0
	cmpltsd xmm0, xmm3
	subsd	xmm2, xmm3
	movapd	xmm1, xmm0
	andnpd	xmm0, xmm2
	andpd	xmm1, xmm4
	orpd	xmm0, xmm1

    ucomisd	xmm4,xmm3  
	setae	cl
	shl		ecx, 31

	sub		esp, 16
	movsd	[esp+8], xmm0
	fld		_Q [esp+8]
	fnstcw	_W [esp]  
	movzx   eax, _W [esp]  
    or      eax, 0C00h  
	mov     _W [esp+4],ax  
	fldcw   _W [esp+4]  
	fistp   _Q [esp+8]  
    fldcw   _W [esp]  
	mov		eax, _D[esp+8]
	mov		edx, _D[esp+12]
	or		edx, ecx
	add		esp, 16

	ret
	ENDIF

;	again our dtoul3
ENTRY cast_uint64, YQ_KN@Z
ENTRY cast_uint64b, YQ_KN@Z

	pextrw	ecx, xmm0, 3
	mov		edx, ecx					; save for later use
	btr		ecx, 15						; clear sign
	cmp		ecx, 03ff0h + (31 SL 4)		; >=2^31
	jge		.lrg8

	cvttsd2si	eax, xmm0				; easiest way
	cdq
	ret

.lrg8:
	test	edx, 08000h
	jnz		.neg

;	x is positive
	movd	eax, xmm0					; lo
	pshufd	xmm0, xmm0, (1 SL 0) + (0 SL 1)
	movd	edx, xmm0
	and		edx, 000fffffh
	or		edx, 00100000h

	shr		ecx, 4
	cmp		ecx, 3ffh + 52				; >2^52?
	ja		.leftp						; => shift left

	neg		ecx
	add		ecx, 3ffh + 52
;	can cl be > 31 here? no - CANNOT

	shrd	eax, edx, cl
	shr		edx, cl
	ret

.leftp:
	cmp		ecx, 3ffh + 63 
	ja		.ovr				; here is the diff

	sub		ecx, 3ffh + 52
	shld	edx, eax, cl
	shl		eax, cl
	ret

.neg:
;	x is negative
	movd	eax, xmm0					; lo
	pshufd	xmm0, xmm0, (1 SL 0) + (0 SL 1)
	movd	edx, xmm0
	and		edx, 000fffffh
	or		edx, 00100000h

	shr		ecx, 4
	cmp		ecx, 3ffh + 52				; >2^52?
	ja		.leftn						; => shift left

	neg		ecx
	add		ecx, 3ffh + 52

	shrd	eax, edx, cl
	shr		edx, cl

	neg		eax
	adc		edx, 0
	neg		edx

	ret

.leftn:
	cmp		ecx, 3ffh + 63 
	jae		.ovr

	sub		ecx, 3ffh + 52
	shld	edx, eax, cl
	shl		eax, cl

	neg		eax
	adc		edx, 0
	neg		edx

	ret


.ovr:
	mov		edx, 080000000h				; return 0x80000000'00000000
	xor		eax, eax
	ret




ENTRY testfunc 


	ret

FUNC	ENDP


	
	ENDIF

END

