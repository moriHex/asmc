; FCLOSE.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include io.inc

    .code

fclose proc uses rsi rbx fp:LPFILE

    ldr rcx,fp
    mov eax,[rcx]._iobuf._flag
    and eax,_IOREAD or _IOWRT or _IORW
    .ifz
        dec rax
       .return
    .endif

    mov rbx,rcx
    mov rsi,fflush( rcx )
    _freebuf( rbx )

    xor eax,eax
    mov [rbx]._iobuf._flag,eax
    mov ecx,[rbx]._iobuf._file
    dec eax
    mov [rbx]._iobuf._file,eax

    .if ( _close( ecx ) == 0 )

        mov rax,rsi
    .endif
    ret

fclose endp

    end
