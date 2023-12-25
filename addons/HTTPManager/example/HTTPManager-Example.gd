extends Control

@export var http_manager: HTTPManager


func _on_button_pressed():
	http_manager.completed.connect(func(): print("all completed"), CONNECT_ONE_SHOT)
	
	http_manager.job("https://cdn2.thecatapi.com/images/ld.jpg").mime("image/*").on_success(func(response): print("all completed")).fetch()
	
	http_manager.job(
		"https://de.wiktionary.org/wiki/Hilfe:Sonderzeichen/Tabelle"
	).charset(
		"utf-8"
	).on_success_set(
		$TextEdit, "text"
	).fetch()

	http_manager.job(
		"https://support.oneskyapp.com/hc/en-us/article_attachments/202761727/example_2.json"
	).on_success( 
		func( response:BaseDecoder ): 
			print("This JSON is what i got:"); print(response.fetch())
	).fetch()

	http_manager.job(
		"https://godotengine.org/storage/blog/covers/maintenance-release-godot-4-0-2.jpg"
	).on_success_set( 
		$TextureRect, "texture"
	).mime("image/texture").fetch()

	http_manager.job(
		"https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
	).on_success_set( 
		$TextureRect2, "texture"
	).mime("image/texture").cache(false).on_success(
		func( _response ): 
			print("download finished, not from cache")
	).fetch()

	http_manager.job(
		"https://this.url.is.a.failure/"
	).on_success(
		func( _response ): print("realy?")
	).on_failure(
		func( _response ): print("i told this wont work!")
	).fetch()
	
	#--------------- use your own server here
	var server = "https://www.foo.bar"
	http_manager.job(
		server
	).add_post_file(
		"uploadfile_1", "res://icon.svg"
	).add_post_buffer(
		"uploadfile_2", PackedByteArray([1,1,1]), "auto", "filename.ext"
	).on_success(
		func( _response ): print("uploaded")
	).on_failure(
		func( _response ): print("something bad happend")
	).fetch()

#	------ A download example
#
#	http_manager.job(
#		"https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
#	).download("C:/Users/Klaas/Downloads/video.mp4")


