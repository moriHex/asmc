; _STRDUP.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include malloc.inc
include string.inc

    .code

_strdup proc string:LPSTR

    ldr rax,string
    .if rax

        .if malloc(&[strlen(rax)+1])

            strcpy(rax, string)
        .endif
    .endif
    ret

_strdup endp

    end
