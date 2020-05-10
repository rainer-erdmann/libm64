;
;	FILENAME :        f64_umul128.asm          
;
;	DESCRIPTION :
;		u64 _umul128a(u64 a, u64 b, u64* h)
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

;	mula(__f64ex&, const __f64ex&);
;	(?mula@@YAXAEAU__f64ex@@AEBU1@@Z)
ENTRY mula, YAXAEAU__f64ex@@AEBU1@@Z

	mov		rax, _Q [rdx]
	mov		r8d, _D [rdx+8]
	mul		_Q [rcx]
	add		r8d, _D [rcx+8]

	test	rdx, rdx
	js		.nsh

	shld	rdx, rax, 1
	mov		_Q [rcx], rdx
	mov		_D [rcx+8], r8d
	ret

.nsh:
	add		r8d, 1
	mov		_Q [rcx], rdx
	mov		_D [rcx+8], r8d
	ret

; "unsigned __int64 __cdecl _umul128a(unsigned __int64,unsigned __int64,unsigned __int64 *)" (?_umul128a@@YA_K_K0PEA_K@Z)

ENTRY _umul128a, YA_K_K0PEA_K@Z

	mov		rax, rdx
	mul		rcx
	mov		_Q [r8], rdx
	ret
	
	ELSE

	.code

;	with frame pointer
;	u64 __cdecl _umul128(u64, u64, u64 *)" (?_umul128@@YA_K_K0PA_K@Z)
ENTRY _umul128a, YA_K_K0PA_K@Z

%deftok $a	'ebp+8'
%deftok $b	'ebp+16'
%deftok $h	'ebp+24'

; %deftok $z0l 'esp-8'
; %deftok $z0h 'esp-12'

	push	ebp
	mov		ebp, esp

;	push	edi
;	push	esi
	push	ebx

	mov		ecx, _D [$b]
	mov		eax, _D [$a]
	mul		ecx			; _D [$b]
;	mov		_D [$z0l], eax
	movd	xmm0, eax

	mov		ebx, edx

	mov		eax, _D [$a+4]
	mul		ecx			; _D [$b]
	xor		ecx, ecx
	add		ebx, eax
	adc		ecx, edx

	mov		eax, _D [$a]
	mul		_D [$b+4]
;	xor		esi, esi
	add		ebx, eax
	adc		ecx, edx
;	adc		esi, 0
	setc	al
;	mov		_D [$z0h], ebx
	movd	xmm1, ebx

	mov		ebx, ecx
;	mov		ecx, esi
	movzx	ecx, al

	mov		eax, _D [$a+4]
	mul		_D [$b+4]
	add		ebx, eax
	adc		ecx, edx

;	mov		edi, _D [$h]
;	mov		_D [edi+0], ebx
;	mov		_D [edi+4], ecx
	mov		eax, _D [$h]
	mov		_D [eax+0], ebx
	mov		_D [eax+4], ecx

;	mov		eax, _D [$z0l]
;	mov		edx, _D [$z0h]
	movd	eax, xmm0
	movd	edx, xmm1

	pop		ebx
;	pop		esi
;	pop		edi
	mov		esp, ebp
	pop		ebp
	ret

;	fully functional 
;	without frame pointer
ENTRY _umul128, YA_K_K0PA_K@Z

%deftok $a	'esp+4+4'
%deftok $b	'esp+4+12'
%deftok $h	'esp+4+20'

	push	ebx

	mov		ecx, _D [$b]
	mov		eax, _D [$a]
	mul		ecx							; _D [$b]

	movd	xmm0, eax					; z0l
	mov		ebx, edx

	mov		eax, _D [$a+4]
	mul		ecx							; _D [$b]
	xor		ecx, ecx
	add		ebx, eax
	adc		ecx, edx

	mov		eax, _D [$a]
	mul		_D [$b+4]
	add		ebx, eax
	adc		ecx, edx
	setc	al
	movd	xmm1, ebx					; z0h

	mov		ebx, ecx
	movzx	ecx, al

	mov		eax, _D [$a+4]
	mul		_D [$b+4]
	add		ebx, eax
	adc		ecx, edx

	mov		eax, _D [$h]
	mov		_D [eax+0], ebx
	mov		_D [eax+4], ecx

	movd	eax, xmm0
	movd	edx, xmm1

	pop		ebx
	ret


; "void __cdecl mul(struct __f64ex &,struct __f64ex const &)" (?mul@@YAXAAU__f64ex@@ABU1@@Z)
ENTRY mula, YAXAAU__f64ex@@ABU1@@Z

%deftok $a	'esp+12+4'
%deftok $b	'esp+12+8'

	push	ebx
	push	esi
	push	edi

	mov		edi, [$a]
	mov		esi, [$b]


	mov		ecx, _D [esi]
	mov		eax, _D [edi]
	mul		ecx							; _D [$b]

;	movd	xmm0, eax					; z0l
	mov		ebx, edx

	mov		eax, _D [edi+4]
	mul		ecx							; _D [$b]
	xor		ecx, ecx
	add		ebx, eax
	adc		ecx, edx

	mov		eax, _D [edi]
	mul		_D [esi+4]
	add		ebx, eax
	adc		ecx, edx
	setc	al
	movd	xmm1, ebx					; z0h

	mov		ebx, ecx
	movzx	ecx, al

	mov		eax, _D [edi+4]
	mul		_D [esi+4]
	add		ebx, eax
	adc		ecx, edx

	mov		edx, [edi+8]		; a.ex
	add		edx, [esi+8]		; b.ex
	add		edx, 1

;	result h = ebx, ecx

	test	ecx, ecx
	js		.nsh
	movd	eax, xmm1
	shld	ecx, ebx, 1
	shld	ebx, eax, 1
	sub		edx, 1
.nsh:
	mov		_D [edi], ebx
	mov		_D [edi+4], ecx
	mov		_D [edi+8], edx

	pop		edi
	pop		esi
	pop		ebx
	ret


;	DAT WIRD ALLET NIX...
ENTRY _umul128b, YA_K_K0PA_K@Z
%deftok $a	'esp+4'
%deftok $b	'esp+12'
%deftok $h	'esp+20'

	movq	xmm1, _Q [$a]
	punpckldq xmm1, xmm3				; xmm1 = al, 0, ah, 0
	movq	xmm2, _Q [$b]
	punpckldq xmm2, xmm3				; xmm2 = bl, 0, bh, 0
	pshufd	xmm3, xmm2, (2<<0)+(3<<2)+(0<<4)+(1<<6) ; xmm3 = bh, 0, bl, 0

	pmuludq xmm2, xmm1					; xmm2 = bl*al, bh*ah
	pmuludq xmm1, xmm3					; xmm1 = al*bh, ah*bl

;	xmm2 DD0 is lo32bit
	movd	eax, xmm2

;	2. 32bit of result
	psrldq	xmm2, 4
	movd	edx, xmm2
	movd	ecx, xmm1
	add		edx, ecx
	pshufd	xmm3, xmm1, (2 << 0)+(3 << 2)+(0 << 4)+(1 << 6)
	movd	ecx, xmm3
	adc		edx, ecx

	setc	cl
	movzx	ecx, cl
	movd	xmm5, ecx
	psrldq	xmm2, 4
	paddq	xmm2, xmm5					; carries
	psrlq	xmm1, 32
	paddq	xmm2, xmm1
	psrlq	xmm3, 32
	paddq	xmm2, xmm3

	mov		ecx, [$h]
	movq	_Q [ecx], xmm2

	ret

	ENDIF


END



