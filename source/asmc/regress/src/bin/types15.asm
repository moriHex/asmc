;
; v2.24: http://masm32.com/board/index.php?topic=6117.msg65190#msg65190
;
	.386
	.model flat
	.code

	lea edx,[esp + TYPEOF edx ]
	lea edx,[esp + TYPEOF(edx)]

	end
