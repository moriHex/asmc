; XMVECTORSETBYINDEX.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
include DirectXMath.inc

    .code

XMVectorSetByIndex proc XM_CALLCONV V:FXMVECTOR, f:float, i:size_t

    movd    edx,xmm1
    mov    dword ptr V[r8*4],edx
    movaps xmm0,V
    ret

XMVectorSetByIndex endp

    end
