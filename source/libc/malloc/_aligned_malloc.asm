; _ALIGNED_MALLOC.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include malloc.inc

    .code

_aligned_malloc proc uses rdi dwSize:size_t, Alignment:size_t

    ldr rdi,Alignment
    ldr rcx,dwSize

    lea rcx,[rcx+rdi+HEAP]

    .if malloc( rcx )

        dec rdi
        .if ( rax & rdi )

            lea rdx,[rax-HEAP]
            lea rax,[rax+rdi+HEAP]
            not rdi
            and rax,rdi
            lea rcx,[rax-HEAP]
            mov [rcx].HEAP.prev,rdx
            mov [rcx].HEAP.type,_HEAP_ALIGNED
        .endif
    .endif
    ret

_aligned_malloc endp

    end
