	[list -]
;
;	FILENAME :        common.nasm          
;
;	DESCRIPTION :
;		common include header 
;		NASM specific
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
;	it is not the easiest job to get a simple 
;	assembly source running on more than 
;	one assembler.
;	we tried to get our small set of sources
;	running on MASM and NASM both in 
;	x86 (32bit) and x64 (64bit) mode
;

%deftok XMM ''
%deftok xmmword ''
%deftok ptr ''
%deftok tbyte 'tword'
%deftok offset ''

%deftok _B 'byte'
%deftok _W 'word'
%deftok _D 'dword'
%deftok _Q 'qword'
%deftok _QM ''
%deftok _T 'tword'
%deftok _X ''

; %deftok ELSEIF '%elif'				; does not work

%deftok GT '>'
%deftok LT '<'
%deftok EQ '=='

%define END 
%define FUNC
%deftok .data 'SECTION .data'
%deftok .text 'SECTION .text'
;%deftok .code 'SECTION .code'
%deftok .code 'SECTION .text'
%deftok REAL8 'dq'
%deftok REAL10 'dt'
%deftok PUBLIC 'global'


	IFDEF _M_X64
;	x64 only
%deftok SPACE 'rsp+8'
	ELSE
;	x86 only
%deftok ARGS 'esp+4'
	ENDIF


%define ST(x) ST%+ x					; x87 syntax: masm ST(n), nasm STn

; why masm, when there are easier ways?

%macro ENTRY 1							; NAME only
	align 16
	global %1
%1:
%endmacro

%macro ENTRY 2							; NAME, TYP
	align 16
	global ?%1@@%2
?%1@@%2:
%endmacro

%macro IMPORT 1
	EXTERN %1
%endmacro

%macro IMPORT 2
	EXTERN %2
	%1 EQU %2
%endmacro

%macro IMPORT 3
	EXTERN %2
	%1 EQU %2
%endmacro

	SCW EQU 0

%macro SAVECW 2
	IF SCW > 0
	fnstcw	word [%1]
	fnstcw	word [%2]
	or		word [%1], 0300h	; set prec to 64bit
	fldcw	word [%1]
    ENDIF
%endmacro

%macro RESTCW 1
	IF SCW > 0
	fldcw	word [%1]
	ENDIF
%endmacro

;%macro DEF 2
;	%define %1 %2
;%endmacro

%ideftok mov_q 'movq'

	default rel
	[WARNING -orphan-labels]
	[list +]
