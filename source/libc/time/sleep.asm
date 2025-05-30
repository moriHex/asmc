; SLEEP.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include time.inc
ifdef __UNIX__
include errno.inc
include sys/syscall.inc
else
include winbase.inc
endif

.code

_sleep proc milliseconds:uint_t

ifdef __UNIX__

   .new req:timespec
   .new rem:timespec

    ldr  ecx,milliseconds
    mov  eax,1000
    xor  edx,edx
    div  rcx
    mov  req.tv_sec,rax
    imul rax,rdx,1000
    mov  req.tv_nsec,rax

    nanosleep( &req, &rem )

    mov  rcx,rem.tv_nsec
    mov  eax,1000
    xor  edx,edx
    div  rcx
    imul rcx,rem.tv_sec,1000
    add  rax,rcx

else
    Sleep( ldr(milliseconds) )
endif
    ret

_sleep endp

    end
