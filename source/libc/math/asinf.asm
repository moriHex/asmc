; ASINF.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include math.inc

    .code

asinf proc x:float
ifdef __SSE__
    cvtss2sd xmm0,xmm0
    asin(xmm0)
    cvtsd2ss xmm0,xmm0
else
    fld     x
    fld     st(0)
    fmul    st(1),st(0)
    fld1
    fsubr
    fsqrt
    fpatan
endif
    ret

asinf endp

    end
