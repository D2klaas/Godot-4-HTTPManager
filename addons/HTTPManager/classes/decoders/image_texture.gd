class_name ImageTextureDecoder
extends ImageDecoder


func fetch() -> Variant:
	return as_texture()


func as_texture() -> ImageTexture:
	var img = as_image( response_mime )
	if img:
		return ImageTexture.create_from_image(img)
	
	return null

