;
;	FILENAME :        f64_cmp.asm          
;
;	DESCRIPTION :
;		a set of comparisons safe against NAN
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
;
;

	IFDEF	@Version
	INCLUDE common.masm
	ELSE
	INCLUDE 'common.nasm' 
	ENDIF

	IFDEF _M_X64								; 64bit

	.data

	.code

;	bool __cdecl cmp_olt(double,double)
ENTRY cmp_olt, YA_NNN@Z
ENTRY islessd, YA_NNN@Z

	comisd	xmm0, xmm1
	setnz	dl							 
	setc	al
	and		al, dl						; CF=1 && ZF=0
	ret


;	bool __cdecl cmp_ole(double,double)
ENTRY cmp_ole, YA_NNN@Z
ENTRY islessequald, YA_NNN@Z

	comisd	xmm0, xmm1
	setnp	dl							 
	setbe	al
	and		al, dl						; (CF=1 || ZF=1) && PF=0
	ret


;	bool __cdecl cmp_ogt(double,double)
ENTRY cmp_ogt, YA_NNN@Z
ENTRY isgreaterd, YA_NNN@Z

	comisd	xmm0, xmm1
	seta	al							; CF=0 && ZF=0
	ret


;	bool __cdecl cmp_oge(double,double)
ENTRY cmp_oge, YA_NNN@Z
ENTRY isgreaterequald, YA_NNN@Z

	comisd	xmm0, xmm1
	setnc	al							; CF=0
	ret

;	false if equal or NAN
ENTRY islessgreaterd, YA_NNN@Z

	comisd	xmm0, xmm1
	setz	al
	ret

;	true if NAN
ENTRY isunorderedd, YA_NNN@Z

	comisd	xmm0, xmm1
	setp	al
	ret


;	bool __cdecl cmp_olta(double,double)
ENTRY cmp_olta, YA_NNN@Z

	psllq	xmm0, 1
	psrlq	xmm0, 1
	comisd	xmm0, xmm1
	setnp	dl
	setc	al
	and		al, dl
	ret

	ELSE
;	x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - x86 - 
	.code

;	a set of comparisons safe against NAN
;"bool __cdecl cmp_olt(double,double)" (?OLT@@YA_NNN@Z)
ENTRY cmp_olt, YA_NNN@Z
ENTRY islessd, YA_NNN@Z

	movsd	xmm0, _Q [esp+4]
	comisd	xmm0, _QM [esp+4+8]
	setnz	dl							 
	setc	al
	and		al, dl						; CF=1 && ZF=0
	ret

; "bool __vectorcall cmp_olt(double,double)" (?cmp_olt@@YQ_NNN@Z)
ENTRY cmp_olt, YQ_NNN@Z
ENTRY islessd, YQ_NNN@Z

	comisd	xmm0, xmm1
	setnz	dl							 
	setc	al
	and		al, dl						; CF=1 && ZF=0
	ret


;"bool __cdecl cmp_ole(double,double)" (?OLE@@YA_NNN@Z)
ENTRY cmp_ole, YA_NNN@Z
ENTRY islessequald, YA_NNN@Z

	movsd	xmm0, _Q [esp+4]
	comisd	xmm0, _QM [esp+4+8]
	setnp	dl							 
	setbe	al
	and		al, dl						; (CF=1 || ZF=1) && PF=0
	ret


ENTRY cmp_ole, YQ_NNN@Z
ENTRY islessequald, YQ_NNN@Z

	comisd	xmm0, xmm1
	setnp	dl							 
	setbe	al
	and		al, dl						; (CF=1 || ZF=1) && PF=0
	ret


;"bool __cdecl cmp_ogt(double,double)" (?OLT@@YA_NNN@Z)
ENTRY cmp_ogt, YA_NNN@Z
ENTRY isgreaterd, YA_NNN@Z

	movsd	xmm0, _Q [esp+4]
	comisd	xmm0, _QM [esp+4+8]
	seta	al							; CF=0 && ZF=0
	ret


ENTRY cmp_ogt, YQ_NNN@Z
ENTRY isgreaterd, YQ_NNN@Z

	comisd	xmm0, xmm1
	seta	al							; CF=0 && ZF=0
	ret

;"bool __cdecl cmp_oge(double,double)" (?OLT@@YA_NNN@Z)
ENTRY cmp_oge, YA_NNN@Z
ENTRY isgreaterequald, YA_NNN@Z

	movsd	xmm0, _Q [esp+4]
	comisd	xmm0, _QM [esp+4+8]
	setnc	al							; CF=0
	ret

ENTRY cmp_oge, YQ_NNN@Z
ENTRY isgreaterequald, YQ_NNN@Z

	comisd	xmm0, xmm1
	setnc	al							; CF=0
	ret


;	false if equal or NAN
ENTRY islessgreaterd, YA_NNN@Z

	movsd	xmm0, _Q [ARGS]
	comisd	xmm0, _QM [ARGS+8]
	setz	al
	ret

;	false if equal or NAN
ENTRY islessgreaterd, YQ_NNN@Z

	comisd	xmm0, xmm1
	setz	al
	ret

;	true if NAN
ENTRY isunorderedd, YA_NNN@Z

	movsd	xmm0, _Q [ARGS]
	comisd	xmm0, _QM [ARGS+8]
	setp	al
	ret

;	true if NAN
ENTRY isunorderedd, YQ_NNN@Z

	comisd	xmm0, xmm1
	setp	al
	ret


;"bool __cdecl cmp_olta(double,double)" (?OLT@@YA_NNN@Z)
ENTRY cmp_olta, YA_NNN@Z

	IF 0
;	10.0 SAN
;	using fcomip we get very slow on NANs
;	using fucomip we dont
	fld		_Q [esp+4+8]
	fld		_Q [esp+4]
	fabs
	fucomip	ST(0), ST(1)
	ffree	ST(0)
	setnp	dl
	setc	al
	and		al, dl
	ret
	ENDIF

; 9.8 SAN
	movsd	xmm0, _Q [esp+4]
	psllq	xmm0, 1
	psrlq	xmm0, 1
	comisd	xmm0, _QM [esp+4+8]
	setnp	dl
	setc	al
	and		al, dl
	ret


ENTRY cmp_olta, YQ_NNN@Z

	psllq	xmm0, 1
	psrlq	xmm0, 1
	comisd	xmm0, xmm1
	setnp	dl
	setc	al
	and		al, dl
	ret

FUNC	ENDP

	ENDIF

END

