include math.inc
include stdio.inc
include tchar.inc

    .code

_tmain proc

  local x:real8

    fmod(1.5, 1.2)
ifdef __SSE__
    movsd x,xmm0
else
    fstp x
endif
    printf("%f\n", x)
    xor eax,eax
    ret

_tmain endp

    end _tstart