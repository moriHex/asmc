; ASSERT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include stdlib.inc
include assert.inc
include errno.inc
include tchar.inc

.assert:on

    .data
    A dd 9,8,7,6,5,4,3,2,1,0
    B dd 0,1,2,3,4,5,6,7,8,9

    .code

compare proc private a:ptr, b:ptr

    mov rax,a
    mov rdx,b
    mov eax,[rax]
    mov edx,[rdx]

    .if eax > edx
        mov eax,1
    .elseif eax < edx
        mov eax,-1
    .else
        xor eax,eax
    .endif
    ret

compare endp

m   proto fastcall :abs, :abs, :abs, :abs, :abs {
    _1(_2, _3, _4)
    .assert( strcmp(rbx, _5) == 0 )
    }
mw  proto fastcall :abs, :abs, :abs, :abs, :abs {
    _1(_2, _3, _4)
    .assert( _wcsicmp(rbx, _5) == 0 )
    }
m_s proto fastcall :abs, :abs, :abs, :abs, :abs, :abs {
    _1(_2, _3, _4, _5)
    _get_errno(&e)
    .assert( e == _6 )
    }

main proc

    .assertd( atol("") == 0 )
    .assertd( atol("1") == 1 )
    .assertd( atol("-1") == -1 )
    .assertd( atol("00999") == 999 )
    .assertd( atol("-2147483648") == 0x80000000 )
    .assertd( atol("2147483647") == 0x7FFFFFFF )
    .assertd( atol("4294967295") == -1 )

    .assertd( _atoi64("0") == 0 )
    .assertd( _atoi64("1") == 1 )
    .assertd( _atoi64("-1") == -1 )
    .assertd( _atoi64("00999") == 999 )
    .assertd( _atoi64("-2147483648") == 0x80000000 )
    .assertd( _atoi64("2147483647") == 0x7FFFFFFF )
    .assertd( _atoi64("4294967295") == -1 )
    .assert( _atoi64("18446744073709551615") == -1 )

ifdef _WIN64
    mov rbx,0x7FFFFFFFFFFFFFFF
    .assert( _atoi64("9223372036854775807") == rbx )
    mov rbx,0x8000000000000000
    .assert( _atoi64("-9223372036854775808") == rbx )
else
    _atoi64("9223372036854775807")
    .assert( eax == -1 && edx == 0x7FFFFFFF )
    mov ebx,0x80000000
    _atoi64("-9223372036854775808")
    .assert( eax == 0 && edx == ebx )
endif

define __CHAR_BIT__         8
define __SIZEOF_INT128__    128
define INT128_MAX           ( ( 1 shl ( ( __SIZEOF_INT128__ * __CHAR_BIT__ ) - 1 ) ) - 1 )
define INT128_MIN           ( -INT128_MAX - 1 )
define UINT128_MAX          ( ( 2 * INT128_MAX ) + 1 )

    .new o:int128_t
    .assert( _atoi128( "0", &o ) == 0 )
    .assert( _atoi128( "1", &o ) == 1 )
    .assert( _atoi128( "-1", &o ) == -1 )
    .assert( _atoi128( "00999", &o ) == 999 )

    _atoi128("170141183460469231731687303715884105727", &o )
ifdef _WIN64
    mov rcx,0x7FFFFFFFFFFFFFFF
else
    mov ecx,0xFFFFFFFF
endif
    .assert( rax == -1 && rdx == rcx )
ifndef _WIN64
    .assert( dword ptr o[8] == 0xFFFFFFFF && dword ptr o[12] == 0x7FFFFFFF )
endif
    _atoi128("-170141183460469231731687303715884105728", &o )
ifdef _WIN64
    .assert( rax == 0 && rdx == rbx )
else
    .assert( eax == 0 && edx == 0 )
    .assert( dword ptr o[8] == 0 && dword ptr o[12] == ebx )
endif
    _atoi128("340282366920938463463374607431768211455", &o )
    .assert( rax == -1 && rdx == -1 )
ifndef _WIN64
    .assert( dword ptr o[8] == 0xFFFFFFFF && dword ptr o[12] == 0xFFFFFFFF )
endif
    qsort (&A, 10, 4, &compare)
    mov eax,A
    .assert( A == 0 )

    lea rbx,A
    .assert( bsearch(&B, rbx, 10, 4, &compare) == rbx )

    xor eax,eax
    lea rsi,A
    lea rdi,B
    mov ecx,10
    repe cmpsd
    setnz al
    .assert( eax == 0 )

    .new e:errno_t
    .new buffer[256]:char_t

    lea rbx,buffer

    m(_itoa,    0, rbx,  2, "0" )
    m(_itoa,    1, rbx,  2, "1" )
    m(_itoa,    2, rbx,  2, "10" )

    m(_itoa,    0, rbx, 10, "0" )
    m(_itoa,    1, rbx, 10, "1" )
    m(_itoa,    2, rbx, 10, "2" )

    m(_itoa,    0, rbx, 16, "0" )
    m(_itoa,    1, rbx, 16, "1" )
    m(_itoa,    2, rbx, 16, "2" )
    m(_itoa,   15, rbx, 16, "F" )

    m(_itoa,    1000, rbx, 10, "1000" )
    m(_ltoa,    1000, rbx, 10, "1000" )
    m(_ultoa,   1000, rbx, 10, "1000" )
    m(_i64toa,  1000, rbx, 10, "1000" )
    m(_ui64toa, 1000, rbx, 10, "1000" )

    m(_itoa,    -1, rbx, 10, "-1" )
    m(_ltoa,    -1, rbx, 10, "-1" )
    m(_ultoa,   0xFFFFFFFF, rbx, 10, "4294967295" )
    m(_i64toa,  -1, rbx, 10, "-1" )
    m(_ui64toa, -1, rbx, 10, "18446744073709551615" )

    _set_errno(ENOERR)

    m_s(_itoa_s,    1, rbx, lengthof(buffer), 10, ENOERR )
    m_s(_ltoa_s,    1, rbx, lengthof(buffer), 10, ENOERR )
    m_s(_ultoa_s,   1, rbx, lengthof(buffer), 10, ENOERR )
    m_s(_i64toa_s,  1, rbx, lengthof(buffer), 10, ENOERR )
    m_s(_ui64toa_s, 1, rbx, lengthof(buffer), 10, ENOERR )

    m_s(_ltoa_s, 0, NULL, lengthof(buffer), 10, EINVAL )
    m_s(_ltoa_s, 0,  rbx, lengthof(buffer),  1, EINVAL )
    m_s(_ltoa_s, 0,  rbx, lengthof(buffer), 37, EINVAL )
    m_s(_ltoa_s, 0,  rbx,   1, 10, ERANGE )

ifndef __UNIX__
    mw(_itow,    0, rbx,  2, L"0" )
    mw(_itow,    1, rbx,  2, L"1" )
    mw(_itow,    2, rbx,  2, L"10" )

    mw(_itow,    0, rbx, 10, L"0" )
    mw(_itow,    1, rbx, 10, L"1" )
    mw(_itow,    2, rbx, 10, L"2" )

    mw(_itow,    0, rbx, 16, L"0" )
    mw(_itow,    1, rbx, 16, L"1" )
    mw(_itow,    2, rbx, 16, L"2" )
    mw(_itow,   15, rbx, 16, L"F" )

    mw(_itow,    1000, rbx, 10, L"1000" )
    mw(_ltow,    1000, rbx, 10, L"1000" )
    mw(_ultow,   1000, rbx, 10, L"1000" )
    mw(_i64tow,  1000, rbx, 10, L"1000" )
    mw(_ui64tow, 1000, rbx, 10, L"1000" )

    _set_errno(ENOERR)

    m_s(_itow_s,    1, rbx, lengthof(buffer)/2, 10, ENOERR )
    m_s(_ltow_s,    1, rbx, lengthof(buffer)/2, 10, ENOERR )
    m_s(_ultow_s,   1, rbx, lengthof(buffer)/2, 10, ENOERR )
    m_s(_i64tow_s,  1, rbx, lengthof(buffer)/2, 10, ENOERR )
    m_s(_ui64tow_s, 1, rbx, lengthof(buffer)/2, 10, ENOERR )

    m_s(_ltow_s, 0, NULL, lengthof(buffer)/2, 10, EINVAL )
    m_s(_ltow_s, 0,  rbx, lengthof(buffer)/2,  1, EINVAL )
    m_s(_ltow_s, 0,  rbx, lengthof(buffer)/2, 37, EINVAL )
    m_s(_ltow_s, 0,  rbx,   1, 10, ERANGE )
endif
    .return( 0 )

main endp

    end
