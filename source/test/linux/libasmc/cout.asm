include iostream

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

    cout << "cout" << endl
    cout << endl

    cout << "signed char    (-1): " << signed_char  << endl
    cout << "signed short   (-1): " << signed_short << endl
    cout << "signed int     (-1): " << signed_int   << endl
    cout << "signed int64   (-1): " << signed_int64 << endl
    cout << "unsigned char  (-1): " << bl           << endl
    cout << "unsigned short (-1): " << bx           << endl
    cout << "unsigned int   (-1): " << ebx          << endl
    cout << "unsigned int64 (-1): " << rbx          << endl
    cout << endl

   .return(0)

main endp

    end
