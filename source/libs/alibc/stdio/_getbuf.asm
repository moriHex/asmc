; _GETBUF.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include malloc.inc

    .code

    assume rbx:ptr FILE

_getbuf proc uses rbx fp:ptr FILE

    mov rbx,rdi

    .if malloc(_INTIOBUF)

	or  [rbx]._flag,_IOMYBUF
	mov [rbx]._bufsiz,_INTIOBUF
    .else
	or  [rbx]._flag,_IONBF
	mov [rbx]._bufsiz,4
	lea rax,[rbx]._charbuf
    .endif
    mov [rbx]._ptr,rax
    mov [rbx]._base,rax
    mov [rbx]._cnt,0
    ret

_getbuf endp

    end
