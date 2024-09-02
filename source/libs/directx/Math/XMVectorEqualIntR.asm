; XMVECTOREQUALINTR.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
include DirectXMath.inc

    .code

XMVectorEqualIntR proc XM_CALLCONV pCR:ptr uint32_t, V1:FXMVECTOR, V2:FXMVECTOR

    _mm_store_ps(xmm0, xmm1)
    _mm_cmpeq_epi32(xmm0, xmm2)

    xor edx,edx
    .if _mm_movemask_ps() == 0x0F

        mov edx,XM_CRMASK_CR6TRUE

    .elseif !eax
        ;;
        ;; All elements are not greater
        ;;
        mov edx,XM_CRMASK_CR6FALSE
    .endif
    mov [rcx],edx
    ret

XMVectorEqualIntR endp

    end
