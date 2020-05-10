;
;	FILENAME :        f64__initsupp.asm          
;
;	DESCRIPTION :
;		int Setx87Mode(int v)
;		set x87 precision to [24, 53, 64] bit
;		return previous setting
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

;	IFDEF __NASM_VER__
;	db __NASM_VER__
;	ENDIF		


	IFDEF _M_X64	 							; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

;	war nur mal wieder ein test...
;	rep movsq hat keinen zweck;
;	braucht für kleine blöcke doppelt so lange wie sse
;"void * __cdecl __memcpy2(void *,void const *,unsigned __int64)" (?__memcpy2@@YAPEAXPEAXPEBX_K@Z)
ENTRY __memcpy2, YAPEAXPEAXPEBX_K@Z

	push	rdi
	push	rsi
	mov		rdi, rcx
	mov		rax, rcx
	mov		rsi, rdx
	mov		rcx, r8

	shr		rcx, 3
	rep		movsq

	pop		rsi
	pop		rdi
	ret







; int Getx87cw(void)
ENTRY Getx87cw, YAHXZ

	fnstcw	[SPACE]
	movzx	eax, _W [SPACE]
	ret


ENTRY Setx87cw, YAHH@Z

	mov		_W [SPACE], cx
	fldcw	[SPACE]
	ret


ENTRY Setx87init, YAHH@Z

	test	ecx, ecx
	jz		.done
	fninit
.done:
	mov		eax, ecx
	ret


;"int __cdecl Setx87Mode(int)" (?Setx87Mode@@YAHH@Z)

ENTRY Setx87Mode, YAHH@Z

	fnstcw	[SPACE]
	movzx	eax, _W [SPACE]
	mov		edx, eax
	and		eax, 0fcffh					; clear prec field
	cmp		ecx, 60
	jl		.n64
	or		eax, 0300h					; prec 64bit
	jmp		.all
.n64:
	cmp		ecx, 50
	jl		.n53
	or		eax, 0200h					; prec 53bit
	jmp		.all
.n53:
	cmp		ecx, 20
	jl		.n24
	jmp		.all						; 0 prec 24bit 
.n24:
	or		eax, 0300h					; prec 64bit
	jmp		.all

.all:
	mov		_W [SPACE], ax	
	fldcw	[SPACE]
	and		edx, 0300h
	cmp		edx, 0300h
	mov		eax, 64
	jz		.ret
	cmp		edx, 0200h
	mov		eax, 53
	jz		.ret
	cmp		edx, 0000h
	mov		eax, 24
	jz		.ret
	mov		eax, 64
.ret:
	ret

FUNC ENDP

	ELSE ; x86
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 
	.code
	%deftok SPACE 'esp-16'


; ENTRY Getx87cw
; ?Getx87cw@@YAHXZ
ENTRY Getx87cw, YAHXZ

	fnstcw	[SPACE]
	movzx	eax, _W [SPACE]
	ret


ENTRY Setx87Mode, YAHH@Z

	mov		ecx, _D [ARGS]
	sub		esp, 010h
	fnstcw	[ARGS+6]
	fnstcw	[ARGS+8]

	movzx	eax, _W [ARGS+6]
	and		eax, 0fcffh					; clear prec field
	cmp		ecx, 64
	jne		.n64
	or		eax, 0300h					; prec 64bit
	jmp		.all
.n64:
	cmp		ecx, 53
	jne		.n53
	or		eax, 0200h					; prec 53bit
	jmp		.all
.n53:
	cmp		ecx, 24
	jne		.n24
	jmp		.all						; 0 prec 24bit 
.n24:
	or		eax, 0300h					; prec 64bit
	jmp		.all

.all:
;	mov		_W [esp+0ah], ax	
;	fldcw	[esp+0ah]
	mov		_W [ARGS+6], ax	
	fldcw	[ARGS+6]

;	movzx	edx, word ptr [esp+0ch]
	movzx	edx, word ptr [ARGS+8]
	and		edx, 0300h
	cmp		edx, 0300h
	mov		eax, 64
	jz		.ret
	cmp		edx, 0200h
	mov		eax, 53
	jz		.ret
	cmp		edx, 0000h
	mov		eax, 24
	jz		.ret
	mov		eax, 64
.ret:
	add		esp, 010h
	ret

FUNC	ENDP

	ENDIF

	END
