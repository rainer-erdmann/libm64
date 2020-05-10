;
;	FILENAME :        f64_is_xy.asm          
;
;	DESCRIPTION :
;		bool isfinited(double v)
;		bool isnand(double v)
;		bool isinfd(double v)
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

IMPORT D_INF, ?D_INF@@3NA

	IFDEF _M_X64								; 64bit
;	x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64 - x64

	.code

ENTRY isfinited
ENTRY isfinited, YA_NN@Z
;	~6 incl call; 3 ftest
	subsd	xmm0, xmm0					; promotes INF to NAN
	comisd	xmm0, xmm0
	setnp	al
	ret


ENTRY isnand
ENTRY isnand, YA_NN@Z
	
	comisd	xmm0, xmm0
	setp	al
	ret

ENTRY isinfd
ENTRY isinfd, YQ_NN@Z
	IF 1
;	~6
	movq	rdx, xmm0
	btr		rdx, 63
	mov		rax, 07ff0000000000000h
	cmp		rdx, rax
;	cmp		rdx, [D_INF]
	setz	al
	ret
	ENDIF
;	~6
	comisd	xmm0, xmm0
	setnp	ah
	subsd	xmm0, xmm0
	comisd	xmm0, xmm0
	setp	al
	and		al, ah
	ret

;	~6
	psllq	xmm0, 1
	psrlq	xmm0, 1
	comisd	xmm0, [D_INF]
	setnp	ah
	setz	al
	and		al, ah
	ret

FUNC ENDP

	ELSE

	.data


	.code
;	"bool __vectorcall isfinited(double)" (?isfinited@@YQ_NN@Z)
ENTRY isfinited, YQ_NN@Z

	subsd	xmm0, xmm0
	cvttsd2si ecx, xmm0
	test	ecx, ecx
	setz	al
	ret

ENTRY isnand, YQ_NN@Z

	comisd	xmm0, xmm0
	setp	al
	ret

ENTRY isinfd, YQ_NN@Z

	psllq	xmm0, 1
	psrlq	xmm0, 1
	comisd	xmm0, [D_INF]
	setnp	ah
	setz	al
	and		al, ah
	ret

FUNC ENDP

	ENDIF

END
