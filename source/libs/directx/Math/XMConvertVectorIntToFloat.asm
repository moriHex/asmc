; XMCONVERTVECTORINTTOFLOAT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
include DirectXMath.inc

    .code

XMConvertVectorIntToFloat proc XM_CALLCONV VInt:FXMVECTOR, DivExponent:uint32_t

    ldr edx,DivExponent

    ;;
    ;; Convert DivExponent into 1.0f/(1<<DivExponent)
    ;;
    ;; uScale = 0x3F800000 - (DivExponent << 23)
    ;;
    ;; Splat the scalar value
    ;;
    shl edx,23
    mov eax,0x3F800000
    sub eax,edx
    movd xmm1,eax
    _mm_mul_ps(_mm_cvtepi32_ps(), XM_PERMUTE_PS(xmm1))
    ret

XMConvertVectorIntToFloat endp

    end
