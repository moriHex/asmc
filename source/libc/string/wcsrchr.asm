; WCSRCHR.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include string.inc

    .code

wcsrchr proc uses rdi s1:ptr wchar_t, wc:wchar_t

    ldr     rdi,s1
    ldr     dx,wc

    xor     eax,eax
    mov     ecx,-1
    repne   scasw
    not     ecx
    sub     rdi,2
    std
    mov     ax,dx
    repne   scasw
    mov     ax,0
    jne     @F
    lea     rax,[rdi+2]
@@:
    cld
    ret

wcsrchr endp

    end
