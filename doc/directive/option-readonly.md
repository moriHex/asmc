Asmc Macro Assembler Reference

## OPTION [NO]READONLY

_Asmc default settings so option has no effect_.

Enables checking for instructions that modify code segments, thereby guaranteeing that read-only code segments are not modified. Same as the /p command-line option of MASM 5.1, except that it affects only segments with at least one assembly instruction, not all segments. The argument is useful for protected mode programs, where code segments must remain read-only.

#### See Also

[Option](option.md) | [Directives Reference](readme.md)
