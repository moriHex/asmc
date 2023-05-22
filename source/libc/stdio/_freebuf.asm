; _FREEBUF.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include malloc.inc

    .code

_freebuf proc uses rbx fp:LPFILE

    ldr rbx,fp
    mov eax,[rbx]._iobuf._flag

    .if ( eax & _IOREAD or _IOWRT or _IORW )

	.if ( eax & _IOMYBUF )

	    free( [rbx]._iobuf._base )

	    xor eax,eax
	    mov [rbx]._iobuf._ptr,rax
	    mov [rbx]._iobuf._base,rax
	    mov [rbx]._iobuf._flag,eax
	    mov [rbx]._iobuf._bufsiz,eax
	    mov [rbx]._iobuf._cnt,eax
	.endif
    .endif
    ret

_freebuf endp

    end
