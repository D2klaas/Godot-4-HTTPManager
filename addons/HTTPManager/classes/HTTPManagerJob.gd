extends Object
class_name HTTPManagerJob

var _manager

var url:String
var request_method:int = -1

var request_headers:Dictionary
var request_files:Array[Dictionary]
var request_get:Dictionary
var request_post:Dictionary

var request_get_query:String
var unsafe_ssl:bool =false
var force_mime:String
var force_charset:String
var use_cache:bool = true

var retries:int = 0
var download_filepath:String
var callbacks:Array[Dictionary]
var error:int


##add GET variable with ( name:String, value:Varying )
##or add variables with ( variables:Dictionary )
##returns self for function-chaining
func add_get( name, value=null ) -> HTTPManagerJob:
	if name is String and value != null:
		request_get[name] = str(value)
	elif name is Dictionary:
		request_get.merge( name )
	
	return self


##add POST variable with ( name:String, value:Varying )
##or add variables with ( variables:Dictionary )
##returns self for function-chaining
func add_post( name, value=null ) -> HTTPManagerJob:
	if name is String and value != null:
		request_post[name] = str(value)
	elif name is Dictionary:
		request_post.merge( name )
	
	return self


##add a file to the POST request
## name: name of the POST field
## path: path to the file to add
## mime: mime-type of the file
func add_post_file( name:String, filepath:String, mime:String="application/octet-stream" ) -> HTTPManagerJob:
	request_files.append({
		'name': name,
		'path': filepath,
		'mime': mime
	})
	
	return self


##add a buffer to the POST request
## name: name of the POST field
## path: path to the file to add
## mime: mime-type of the file
func add_post_buffer( name:String, buffer:PackedByteArray, mime:String="application/octet-stream" ) -> HTTPManagerJob:
	request_files.append({
		'name': name,
		'buffer': buffer,
		'mime': mime
	})
	
	return self


func add_header( name, value=null ) -> HTTPManagerJob:
	if name is String and value != null:
		request_headers[name] = str(value)
	elif name is Dictionary:
		request_headers.merge( name )
	
	return self


##adds auth-basic header to the request
##returns self for function-chaining
func auth_basic( name:String, password:String ):
	add_header("Authorization:","Basic "+Marshalls.utf8_to_base64(str(name, ":", password)))
	return self


##force a specific mime-type in response
##returns self for function-chaining
func cache( _use_cache:bool=true ) -> HTTPManagerJob:
	use_cache = _use_cache
	return self


##force a specific mime-type in response
##returns self for function-chaining
func mime( mime:String ) -> HTTPManagerJob:
	force_mime = mime
	return self


##force a specific charset in response
##only when response is of mime "text"
##returns self for function-chaining
func charset( charset:String ) -> HTTPManagerJob:
	force_charset = charset
	return self


##do not validate TLS 
##returns self for function-chaining
func unsafe() -> HTTPManagerJob:
	unsafe_ssl = true
	return self


##add REQUEST a header with ( name:String, value:Varying )
##or add headers with ( headers:Dictionary )
##returns self for function-chaining
##sends this job to the queue
##the response will be saved to a file when successfull
## filepath: filepath to where to store the file
## callback: a callable that will be called when job completes
func download( filepath:String, callback = null ):
	download_filepath = filepath
	if callback is Callable:
		callbacks.append({
			"callback": callback
		})
	_manager.add_job( self )


##sends this job to the queue
## callback: a callable that will be called when job completes
func get( callback = null ):
	if callback is Callable:
		callbacks.append({
			"callback": callback
		})

	_manager.add_job( self )


##add a callback that will be called no matter what
func add_callback( callback = null ) -> HTTPManagerJob:
	if callback is Callable:
		callbacks.append( callback )
	if callback is Array:
		for cb in callback:
			assert( cb is Callable )
			callbacks.append( cb )
	
	return self


##add a callback that will be called when request finished successfull with code 200
func on_success( callback:Callable ) -> HTTPManagerJob:
	callbacks.append({
		"result": HTTPRequest.RESULT_SUCCESS,
		"code": 200,
		"callback": callback
	})
	callbacks.append({
		"result": HTTPRequest.RESULT_SUCCESS,
		"code": 304,
		"callback": callback
	})
	
	return self


##set a object property with the decoded request result when successfull
func on_success_set( object:Object, property:String ) -> HTTPManagerJob:
	callbacks.append({
		"result": HTTPRequest.RESULT_SUCCESS,
		"code": 200,
		"do": "set",
		"object": object,
		"property": property,
	})
	callbacks.append({
		"result": HTTPRequest.RESULT_SUCCESS,
		"code": 304,
		"do": "set",
		"object": object,
		"property": property,
	})
	
	return self


##add a callback that will be called when request fails in any way
func on_failure( callback:Callable ) -> HTTPManagerJob:
	callbacks.append({
		"not_result": HTTPRequest.RESULT_SUCCESS,
		"not_code": 200,
		"callback": callback
	})
	
	return self


##add a callback that will be called when a specific HTTP response-code happend
func on_code( code:int, callback:Callable ) -> HTTPManagerJob:
	callbacks.append({
		"code": code,
		"callback": callback
	})
	
	return self


##add a callback that will be called when a specific connection result-code happend
func on_result( result:int, callback:Callable ) -> HTTPManagerJob:
	callbacks.append({
		"result": result,
		"callback": callback
	})
	
	return self


func get_url():
	var _url = url
	if request_get.size() > 0:
		_url += "?" + _manager.query_string_from_dict(request_get)
	return _url


func dispatch( result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray ):
	_manager.d("job "+url+" done")
	
	var response_headers:Dictionary
	var response_body:PackedByteArray
	var response_mime:Array
	var response_charset:String
	var forced_mime:Array
	var forced_charset:String
	var response_from_cache:bool
	
	#modify response by cahe control
	if _manager.use_cache and use_cache:
		var cache_result = _manager.cacher.cache_response( self, result, response_code, headers, body )
		headers = cache_result.headers
		body = cache_result.body
		response_from_cache = cache_result.from_cache
	
	for header in headers:
		var h = _string_to_header( header )
		if h:
			response_headers[h[0].to_lower()] = h[1]
	
	if response_headers.has("content-type"):
		var regex = RegEx.new()
		regex.compile("(\\w+)\\/(\\w+)")
		var r = regex.search(response_headers["content-type"])
		response_mime = Array()
		response_mime.resize(3)
		if r and r.strings.size() == 3:
			response_mime = Array(r.strings)
		regex.compile("response_charset\\=([-\\d\\w]+)")
		r = regex.search(response_headers["content-type"])
		if r and r.strings.size() == 2:
			response_charset = r.strings[1].to_lower()
	
	if force_mime != "":
		var regex = RegEx.new()
		regex.compile("(\\w+)\\/(\\w+)")
		var r = regex.search(force_mime)
		forced_mime = Array()
		forced_mime.resize(3)
		if r and r.strings.size() == 3:
			forced_mime = Array(r.strings)
	
	if force_charset != "":
		forced_charset = force_charset
	
	var response = null
	var mime = ["","",""]
	if response_mime.size() == 3:
		mime = response_mime
	if forced_mime.size() == 3:
		mime = forced_mime
	
	if _manager._mime_decoders.has(mime[1]+"_"+mime[2]):
		response = load(_manager._mime_decoders[mime[1]+"_"+mime[2]]).new()
	elif _manager._mime_decoders.has(mime[1]):
		response = load(_manager._mime_decoders[mime[1]]).new()
	else:
		response = load(_manager._mime_decoders["application_octet-stream"]).new()
	
	response_body = body
	
	response.request_url = url
	response.request_query = get_url()
	response.request_headers = request_headers
	response.request_get = request_get
	response.request_post = request_post
	response.request_files = request_files
	
	response.result = result
	response.from_cache = response_from_cache
	
	response.response_code = response_code
	response.response_headers = response_headers
	response.response_body = response_body
	response.response_mime = response_mime
	response.response_charset = response_charset
	
	#save to download file
	if download_filepath != "":
		DirAccess.make_dir_recursive_absolute(download_filepath.get_base_dir())
		var file = FileAccess.open(download_filepath, FileAccess.WRITE)
		if file:
			file.store_buffer( response.response_body )
	
	for cb in callbacks:
		if cb.has("result") and cb.result != result:
			continue
		if cb.has("code") and cb.code != response_code:
			continue
		if cb.has("not_result") and cb.not_result == result:
			continue
		if cb.has("not_code") and cb.not_code == response_code:
			continue
		if cb.has("callback"):
			cb.callback.call( response )
			continue
		
		if cb.has("do") and cb.do == "set":
			if is_instance_valid( cb.object ):
				cb.object.set(cb.property, response.fetch())
	
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 304):
		_manager.emit_signal("job_succeded",self)
	else:
		if _manager.pause_on_failure:
			_manager.pause()
		_manager.emit_signal("job_failed",self)
	
	_manager.emit_signal("job_completed",self)



func _string_to_header( header:String ):
	var p = header.split(":", false, 1 )
	if p.size() == 2:
		p[0] = p[0].to_lower()
		return p
	return null


