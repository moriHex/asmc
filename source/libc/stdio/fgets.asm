; FGETS.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc

    .code

    assume rbx:ptr _iobuf

fgets proc uses rsi rdi rbx buf:LPSTR, count:SINT, fp:LPFILE

    ldr rdi,buf
    ldr esi,count
    ldr rbx,fp

    .ifs ( esi <= 0 )
        .return( NULL )
    .endif

    dec esi
    .ifnz
        .repeat
            dec [rbx]._cnt
            .ifl

                .ifd ( _filbuf( rbx)  == -1 )

                    .break .if ( rdi != buf )
                    .return( NULL )
                .endif

            .else

                mov rcx,[rbx]._ptr
                inc [rbx]._ptr
                mov al,[rcx]
            .endif
            stosb
            .break .if ( al == 10 )
            dec esi
        .untilz
    .endif
    mov byte ptr [rdi],0
   .return( buf )

fgets endp

    end
