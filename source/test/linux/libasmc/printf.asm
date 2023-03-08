
include stdio.inc

    .code

main proc

  local signed_char     :sbyte
  local signed_short    :sword
  local signed_int      :sdword
  local signed_int64    :sqword

    mov rbx,-1
    mov signed_char,    bl
    mov signed_short,   bx
    mov signed_int,     ebx
    mov signed_int64,   rbx

    printf( "printf\n" )

    printf( "signed char    (-1): %d\n", signed_char )
    printf( "signed short   (-1): %d\n", signed_short )
    printf( "signed int     (-1): %d\n", signed_int )
    printf( "signed int64   (-1): %d\n", signed_int64 )
    printf( "unsigned char  (-1): %u\n", bl )
    printf( "unsigned short (-1): %u\n", bx )
    printf( "unsigned int   (-1): %u\n", ebx )
    printf( "unsigned int64 (-1): %llu\n\n", rbx )
   .return( 0 )

main endp

    end
