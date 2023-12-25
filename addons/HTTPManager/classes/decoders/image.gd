class_name ImageDecoder
extends BaseDecoder


func fetch() -> Variant:
	var mime := response_mime
	if forced_mime.size() == 3:
		mime = forced_mime
	return as_image( mime )


func as_image( mime:Array ) -> Image:
	var img:Image = Image.new()
	match mime[2].to_lower():
		"png":
			OK
			if img.load_png_from_buffer( response_body ) == OK:
				return img
		"jpg", "jpeg":
			if img.load_jpg_from_buffer( response_body ) == OK:
				return img
		"tga":
			if img.load_tga_from_buffer( response_body ) == OK:
				return img
		"webp":
			if img.load_webp_from_buffer( response_body ) == OK:
				return img
		"bmp":
			if img.load_bmp_from_buffer( response_body ) == OK:
				return img
	
	return null

