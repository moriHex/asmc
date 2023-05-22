; _WOUTPUT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include conio.inc
include stdlib.inc
include limits.inc
include wchar.inc
include fltintrn.inc

    option wstring:on

define BUFFERSIZE      512     ; ANSI-specified minimum is 509

define MAXPRECISION    BUFFERSIZE

define FL_SIGN         0x0001  ; put plus or minus in front
define FL_SIGNSP       0x0002  ; put space or minus in front
define FL_LEFT         0x0004  ; left justify
define FL_LEADZERO     0x0008  ; pad with leading zeros
define FL_LONG         0x0010  ; long value given
define FL_SHORT        0x0020  ; short value given
define FL_SIGNED       0x0040  ; signed data given
define FL_ALTERNATE    0x0080  ; alternate form requested
define FL_NEGATIVE     0x0100  ; value is negative
define FL_FORCEOCTAL   0x0200  ; force leading '0' for octals
define FL_LONGDOUBLE   0x0400  ; long double
define FL_WIDECHAR     0x0800
define FL_LONGLONG     0x1000  ; long long or REAL16 value given
define FL_I64          0x8000  ; 64-bit value given

define ST_NORMAL       0       ; normal state; outputting literal chars
define ST_PERCENT      1       ; just read '%'
define ST_FLAG         2       ; just read flag character
define ST_WIDTH        3       ; just read width specifier
define ST_DOT          4       ; just read '.'
define ST_PRECIS       5       ; just read precision specifier
define ST_SIZE         6       ; just read size specifier
define ST_TYPE         7       ; just read type specifier

ifdef FORMAT_VALIDATIONS
define NUMSTATES       (ST_INVALID + 1)
else
define NUMSTATES       (ST_TYPE + 1)
endif

externdef __lookuptable:byte

    .code

write_char proc private wc:wchar_t, fp:LPFILE, pNumWritten:ptr int_t

ifndef _WIN64
    mov edx,fp
endif
    .if ( [rdx]._iobuf._file == 1 || [rdx]._iobuf._file == 2 )

        .if ( _putwch( wc ) == WEOF )
            movsx eax,ax
        .endif
    .else
        fputwc( wc, rdx )
    .endif

    mov rcx,pNumWritten
    .if ( eax == -1 )
        mov [rcx],eax
    .else
        inc int_t ptr [rcx]
    .endif
    ret

write_char endp


write_string proc private uses rsi rdi string:LPWSTR, len:uint_t, fp:LPFILE, pNumwritten:ptr int_t

ifdef _WIN64
    mov rsi,rcx
    mov edi,edx
else
    mov esi,string
    mov edi,len
endif

    .fors ( : edi > 0 : edi-- )

        movzx ecx,word ptr [rsi]
        add rsi,2

        .ifd ( write_char( cx, fp, pNumwritten ) == -1 )
            .break
        .endif
    .endf
    ret

write_string endp


write_multi_char proc private c:wchar_t, num:int_t, fp:LPFILE, pNumWritten:ptr int_t

    .for ( : num > 0 : num-- )
        .ifd ( write_char( c, fp, pNumWritten ) == -1 )
            .break
        .endif
    .endf
    ret

write_multi_char endp


_woutput proc public uses rsi rdi rbx fp:LPFILE, format:wstring_t, arglist:ptr

   .new charsout            : int_t = 0
   .new hexoff              : uint_t
   .new state               : uint_t = 0
   .new curadix             : uint_t
   .new prefix[2]           : wchar_t
   .new textlen             : uint_t = 0
   .new prefixlen           : uint_t
   .new no_output           : uint_t
   .new fldwidth            : uint_t
   .new bufferiswide        : uint_t = 0
   .new padding             : uint_t
   .new flags               : uint_t ; esi
   .new precision           : uint_t ; edi
   .new text                : wstring_t
   .new mbuf[MB_LEN_MAX+1]  : wint_t
   .new buffer[BUFFERSIZE]  : wchar_t

    .while 1

        lea   rcx,__lookuptable
        mov   rax,format
        add   format,wchar_t
        movzx eax,wchar_t ptr [rax]
        mov   edx,eax

        .break .if ( !eax || charsout > INT_MAX )

        .if ( eax >= ' ' && eax <= 'x' )

            mov al,[rcx+rax-32]
            and eax,15
        .else
            xor eax,eax
        .endif

        shl eax,3
        add eax,state
        mov al,[rcx+rax]
        shr eax,4
        and eax,0x0F
        mov state,eax

        .if ( eax <= 7 )

            .switch eax

            .case ST_NORMAL
                mov bufferiswide,1
                mov ecx,edx
                write_char( cx, fp, &charsout )
               .endc

            .case ST_PERCENT
                xor eax,eax
                mov no_output,eax
                mov fldwidth,eax
                mov prefixlen,eax
                mov bufferiswide,eax
                xor esi,esi ; flags
                mov edi,-1  ; precision
               .endc

            .case ST_FLAG
                movzx eax,dx
                .switch pascal eax
                .case '+': or esi,FL_SIGN       ; '+' force sign indicator
                .case ' ': or esi,FL_SIGNSP     ; ' ' force sign or space
                .case '#': or esi,FL_ALTERNATE  ; '#' alternate form
                .case '-': or esi,FL_LEFT       ; '-' left justify
                .case '0': or esi,FL_LEADZERO   ; '0' pad with leading zeros
                .endsw
                .endc

            .case ST_WIDTH
                .if ( dx == '*' )
                    mov rax,arglist
                    add arglist,size_t
                    mov eax,[rax]
                    .ifs ( eax < 0 )
                        or  esi,FL_LEFT
                        neg eax
                    .endif
                    mov fldwidth,eax
                .else
                    movsx edx,dl
                    imul  eax,fldwidth,10
                    add   eax,edx
                    add   eax,-48
                    mov   fldwidth,eax
                .endif
                .endc

            .case ST_DOT
                xor edi,edi
                .endc

            .case ST_PRECIS
                .if ( dl == '*' )
                    mov rax,arglist
                    add arglist,size_t
                    mov edi,[rax]
                    .ifs ( edi < 0 )
                        mov edi,-1
                    .endif
                .else
                    imul eax,edi,10
                    movsx edi,dl
                    add edi,eax
                    add edi,-48
                .endif
                .endc

            .case ST_SIZE
                .switch edx
                .case 'l'
                    .if !( esi & FL_LONG )
                        or esi,FL_LONG
                       .endc
                    .endif
                    ;
                    ; case ll => long long
                    ;
                    and esi,NOT FL_LONG
                    or  esi,FL_LONGLONG
                   .endc
                .case 'L'
                    or  esi,FL_LONGDOUBLE or FL_I64
                   .endc
                .case 'I'
                    mov rax,format
                    mov ecx,[rax]
                    .switch cx
                    .case '6' ; I64
                        .gotosw(2:ST_NORMAL) .if ( ecx != 0x00340036 )
                        or  esi,FL_I64
                        add rax,4
                        mov format,rax
                       .endc
                    .case '3' ; I32
                        .gotosw(2:ST_NORMAL) .if ( ecx != 0x00320033 )
                        and esi,not FL_I64
                        add rax,4
                        mov format,rax
                        .endc
                    .case 'd'
                    .case 'i'
                    .case 'o'
                    .case 'u'
                    .case 'x'
                    .case 'X'
                        .endc
                    .default
                        .gotosw(2:ST_NORMAL)
                    .endsw
                    .endc
                .case 'h'
                    or esi,FL_SHORT
                   .endc
                .case 'w'
                    or esi,FL_WIDECHAR  ; 'w' => wide character
                   .endc
                .endsw
                .endc

            .case ST_TYPE

                mov eax,edx
                .switch eax
                .case 'b'
                    ;
                    ; CONSIDER: non-standard binary output
                    ;
                    mov rax,arglist
                    add arglist,size_t
                    mov edx,[rax]
                    xor ecx,ecx
                    bsr ecx,edx
                    inc ecx
                    mov textlen,ecx
                    lea rbx,buffer
                    .repeat
                        xor eax,eax
                        shr edx,1
                        adc al,'0'
                        mov [rbx+rcx*2-2],ax
                    .untilcxz
                    mov text,rbx
                   .endc

                .case 'C' ; ISO wide character
                    .if ( !( esi & ( FL_SHORT or FL_LONG or FL_WIDECHAR ) ) )
                        ;
                        ; CONSIDER: non-standard
                        ;
                        or esi,FL_WIDECHAR ; ISO std.
                    .endif

                .case 'c'
                    ;
                    ; print a single character specified by int argument
                    ;
                    mov bufferiswide,1
                    mov rax,arglist
                    add arglist,size_t
                    mov edx,[rax]
                    lea rax,buffer
                    mov [rax],dx
                    mov textlen,1 ; print just a single character
                    mov text,rax
                   .endc

                .case 'S' ; ISO wide character string
                    .if ( !( esi & ( FL_SHORT or FL_LONG or FL_WIDECHAR ) ) )

                        or esi,FL_WIDECHAR
                    .endif
                .case 's'

                    ; print a string --
                    ; ANSI rules on how much of string to print:
                    ;   all if precision is default,
                    ;   min(precision, length) if precision given.
                    ; prints '(null)' if a null string is passed

                    mov rax,arglist
                    add arglist,size_t
                    mov rax,[rax]
                    mov ecx,edi
                    .if ( edi == -1 )
                        mov ecx,INT_MAX
                    .endif
                    .if ( rax == NULL )
                        lea rax,@CStr(L"(null)")
                    .endif
                    mov text,rax
                    .repeat
                        .break .if ( wchar_t ptr [rax] == 0 )
                        add rax,wchar_t
                    .untilcxz
                    sub rax,text
                    shr eax,1
                    mov textlen,eax
                   .endc

                .case 'n'
                    mov rax,arglist
                    add arglist,size_t
                    mov rdx,[rax-size_t]
                    mov eax,charsout
                    mov [rdx],eax
                    .if ( esi & FL_LONG )
                        mov no_output,1
                    .endif
                    .endc

ifndef _STDCALL_SUPPORTED

                .case 'E'
                .case 'G'
                .case 'A'
                    or  esi,_ST_CAPEXP  ; capitalize exponent
                    add dl,'a' - 'A'    ; convert format char to lower
                    ;
                    ; DROP THROUGH
                    ;
                .case 'e'
                .case 'f'
                .case 'g'
                .case 'a'
                    ;
                    ; floating point conversion -- we call cfltcvt routines
                    ; to do the work for us.
                    ;
                    or  esi,FL_SIGNED   ; floating point is signed conversion
                    lea rax,buffer      ; put result in buffer
                    mov text,rax
                    ;
                    ; compute the precision value
                    ;
                    .ifs ( edi < 0 )
                        mov edi,6       ; default precision: 6
                    .elseif ( !edi && dl == 'g' )
                        mov edi,1       ; ANSI specified
                    .endif
                    mov rcx,arglist
                    add arglist,size_t
                    mov rax,[rcx]
                    mov ebx,edx
                    mov edx,esi
                    and edx,_ST_CAPEXP
                    ;
                    ; do the conversion
                    ;
                    .if ( esi & FL_LONGDOUBLE )
ifndef _WIN64
                        add arglist,12
                        mov eax,ecx
endif
                        or edx,_ST_LONGDOUBLE
                        _cldcvt( rax, text, ebx, edi, edx )
                    .elseif ( esi & FL_LONGLONG )
ifndef _WIN64
                        add arglist,8
                        mov eax,ecx
endif
                        or edx,_ST_QUADFLOAT
                        _cqcvt( rax, text, ebx, edi, edx )
                    .else
ifndef _WIN64
                        add arglist,4
endif
                        or edx,_ST_DOUBLE
                        _cfltcvt( rcx, text, ebx, edi, edx )
                    .endif
                    ;
                    ; '#' and precision == 0 means force a decimal point
                    ;
                    .if ( ( esi & FL_ALTERNATE ) && !edi )

                        _forcdecpt( text )
                    .endif
                    ;
                    ; 'g' format means crop zero unless '#' given
                    ;
                    .if ( bl == 'g' && !( esi & FL_ALTERNATE ) )

                        _cropzeros( text )
                    .endif

                    ; check if result was negative, save '-' for later
                    ; and point to positive part (this is for '0' padding)

                    mov rcx,text
                    .if ( byte ptr [rcx] == '-' )

                        or  esi,FL_NEGATIVE
                        inc rcx
                        mov text,rcx
                    .endif

                    ; compute length of text

                    mov textlen,strlen(rcx)

                    ; convert to wide string

                    mov flags,esi
                    mov precision,edi

                    lea  rcx,[rax+1]
                    mov  rdx,text
                    lea  rsi,[rdx+rax]
                    lea  rdi,[rdx+rax*2]
                    xor  eax,eax
                    std
                    .repeat
                        lodsb
                        stosw
                    .untilcxz
                    cld
                    mov esi,flags
                    mov edi,precision
                   .endc

endif ; _STDCALL_SUPPORTED

                .case 'd'
                .case 'i'
                    ;
                    ; signed decimal output
                    ;
                    or  esi,FL_SIGNED
                .case 'u'
                    mov curadix,10
                    jmp COMMON_INT

                .case 'p'
                    ;
                    ; write a pointer -- this is like an integer or long
                    ; except we force precision to pad with zeros and
                    ; output in big hex.
                    ;
                    mov edi,size_t * 2
ifdef _WIN64
                    or  esi,FL_I64
endif
                    ;
                    ; DROP THROUGH to hex formatting
                    ;
                .case 'X' ; unsigned upper hex output
                    ;
                    ; set hexadd for uppercase hex
                    ;
                    mov hexoff,'A'-'9'-1
                    jmp COMMON_HEX

                .case 'x'
                    ;
                    ; unsigned lower hex output
                    ;
                    mov hexoff,'a'-'9'-1
                    ;
                    ; DROP THROUGH TO COMMON_HEX
                    ;
                    COMMON_HEX:

                    mov curadix,16
                    .if ( esi & FL_ALTERNATE )
                        ;
                        ; alternate form means '0x' prefix
                        ;
                        mov eax,'x' - 'a' + '9' + 1
                        add eax,hexoff
                        mov prefix,'0'
                        mov prefix[2],ax
                        mov prefixlen,2
                    .endif
                    jmp COMMON_INT

                .case 'o' ; unsigned octal output
                    mov curadix,8
                    .if ( esi & FL_ALTERNATE )
                        ;
                        ; alternate form means force a leading 0
                        ;
                        or esi,FL_FORCEOCTAL
                    .endif
                    ;
                    ; DROP THROUGH to COMMON_INT
                    ;
                   COMMON_INT:
                    ;
                    ; This is the general integer formatting routine.
                    ; Basically, we get an argument, make it positive
                    ; if necessary, and convert it according to the
                    ; correct radix, setting text and textlen
                    ; appropriately.
                    ;
                    xor edx,edx
                    mov rcx,arglist
                    mov eax,[rcx]
                    .if ( esi & ( FL_I64 or FL_LONGLONG ) )

                        mov edx,[rcx+4]
ifndef _WIN64
                        add ecx,size_t
endif
                    .endif
                    add rcx,size_t
                    mov arglist,rcx

                    .if ( esi & FL_SHORT )

                        .if ( esi & FL_SIGNED )
                            ; sign extend
                            movsx eax,ax
                        .else   ; zero-extend
                            movzx eax,ax
                        .endif

                    .elseif ( esi & FL_SIGNED )

                        .if ( !( esi & ( FL_I64 or FL_LONGLONG ) ) )

                            .ifs ( eax < 0 )

                                dec edx
                                or  esi,FL_NEGATIVE
                            .endif

                        .elseifs ( edx < 0 )

                            or  esi,FL_NEGATIVE
                        .endif
                    .endif
                    ;
                    ; check precision value for default; non-default
                    ; turns off 0 flag, according to ANSI.
                    ;
                    .ifs ( edi < 0 )
                        mov edi,1 ; default precision
                    .else
                        and esi,NOT FL_LEADZERO
                    .endif
                    ;
                    ; Check if data is 0; if so, turn off hex prefix
                    ;
                    .if ( !eax && !edx )
                        mov prefixlen,eax
                    .endif
                    ;
                    ; Convert data to ASCII -- note if precision is zero
                    ; and number is zero, we get no digits at all.
                    ;
                    .if ( esi & FL_SIGNED )

                        test edx,edx
                        .ifs
                            neg eax
                            neg edx
                            sbb edx,0
                            or  esi,FL_NEGATIVE
                        .endif
                    .endif

                    lea rbx,buffer[BUFFERSIZE*2-2]
ifdef _WIN64

                    mov r9d,curadix
                    shl rdx,32
                    or  rax,rdx

                    .fors ( : rax || edi > 0 : edi-- )

                        xor edx,edx
                        div r9
                        add dl,'0'
                        .ifs dl > '9'
                            add dl,byte ptr hexoff
                        .endif
                        mov [rbx],dx
                        sub rbx,2
                    .endf

else

                    .fors ( : eax || edx || edi > 0 : edi-- )

                        .if ( !edx || !curadix )

                            div curadix
                            mov ecx,edx
                            xor edx,edx

                        .else

                            push esi
                            push edi

                            .for ( ecx = 64, esi = 0, edi = 0 : ecx : ecx-- )

                                add eax,eax
                                adc edx,edx
                                adc esi,esi
                                adc edi,edi

                                .if ( edi || esi >= curadix )

                                    sub esi,curadix
                                    sbb edi,0
                                    inc eax
                                .endif
                            .endf
                            mov ecx,esi

                            pop edi
                            pop esi

                        .endif

                        add ecx,'0'
                        .ifs ( ecx > '9' )
                            add ecx,hexoff
                        .endif
                        mov [ebx],cx
                        sub ebx,2
                    .endf

endif
                    ; compute length of number

                    lea rax,buffer[BUFFERSIZE*2-2]
                    sub rax,rbx
                    shr eax,1
                    add rbx,2

                    ; text points to first digit now

                    ; Force a leading zero if FORCEOCTAL flag set

                    .if ( esi & FL_FORCEOCTAL )

                        .if ( !eax || wchar_t ptr [rbx] != '0' )

                            sub rbx,2
                            mov wchar_t ptr [rbx],'0'
                            inc eax
                        .endif
                    .endif
                    mov text,rbx
                    mov textlen,eax
                   .endc
                .endsw
                ;
                ; At this point, we have done the specific conversion, and
                ; 'text' points to text to print; 'textlen' is length.   Now we
                ; justify it, put on prefixes, leading zeros, and then
                ; print it.
                ;
                .if ( !no_output )
                    .if ( esi & FL_SIGNED )
                        .if ( esi & FL_NEGATIVE )
                            ; prefix is a '-'
                            mov prefix,'-'
                            mov prefixlen,1
                        .elseif ( esi & FL_SIGN )
                            ; prefix is '+'
                            mov prefix,'+'
                            mov prefixlen,1
                        .elseif ( esi & FL_SIGNSP )
                            ; prefix is ' '
                            mov prefix,' '
                            mov prefixlen,1
                        .endif
                    .endif
                    ;
                    ; calculate amount of padding -- might be negative,
                    ; but this will just mean zero
                    ;
                    mov eax,fldwidth
                    sub eax,textlen
                    sub eax,prefixlen
                    mov padding,eax
                    ;
                    ; put out the padding, prefix, and text, in the correct order
                    ;
                    .if ( !( esi & ( FL_LEFT or FL_LEADZERO ) ) )
                        ;
                        ; pad on left with blanks
                        ;
                        write_multi_char( ' ', padding, fp, &charsout )
                    .endif
                    ;
                    ; write prefix
                    ;
                    write_string( &prefix, prefixlen, fp, &charsout )

                    .if ( ( esi & FL_LEADZERO ) && !( esi & FL_LEFT ) )
                        ;
                        ; write leading zeros
                        ;
                        write_multi_char( '0', padding, fp, &charsout )
                    .endif
                    ;
                    ; write text
                    ;
                    write_string( text, textlen, fp, &charsout )
                    .if ( esi & FL_LEFT )
                        ;
                        ; pad on right with blanks
                        ;
                        write_multi_char( ' ', padding, fp, &charsout )
                    .endif
                .endif
                ;
                ; we're done!
                ;
            .endsw
        .endif
    .endw
    .return( charsout ) ; return value = number of characters written

_woutput endp

    end
