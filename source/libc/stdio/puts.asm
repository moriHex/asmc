; PUTS.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include io.inc
include string.inc

    .code

puts proc string:LPSTR

    _write( 1, string, strlen( string ) )
    ret

puts endp

    end
