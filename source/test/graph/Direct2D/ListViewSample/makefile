include srcpath

ListViewSample.exe:
	asmc64 -q -Cs -peg -ws -frame -I$(inc_dir) $*.asm
	$@
	del $@

vs:
	project -p -w -u ListViewSample
