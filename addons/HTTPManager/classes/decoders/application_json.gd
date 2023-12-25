class_name ApplicationJsonDecoder
extends TextDecoder


func fetch() -> Variant:
	var charset := response_charset
	if forced_charset != "":
		charset = forced_charset
	var text = as_text( charset )
	return JSON.parse_string( text )
