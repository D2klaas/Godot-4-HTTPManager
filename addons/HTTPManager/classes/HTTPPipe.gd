extends HTTPRequest

var manager
var is_busy:bool = false
var job:HTTPManagerJob



func _ready():
	connect("request_completed",self._on_pipe_request_completed)


func reset():
	cancel_request()
	job = null
	is_busy = false


func dispatch( _job:HTTPManagerJob ):
	is_busy = true
	job = _job
	
	if manager.use_cache and job.use_cache:
		manager.cacher.cache_request( job )
	var url = job.get_url()
	
	manager.d("starting request "+url)
	
	var method:int = HTTPClient.METHOD_GET
	if job.request_method == -1:
		if job.request_post.size() > 0 or job.request_files.size() > 0 or job.request_post.size() > 0:
			method = HTTPClient.METHOD_POST
		else:
			method = HTTPClient.METHOD_GET
	else:
		method = job.request_method
	
	var body:PackedByteArray
	if job.request_files.size() > 0:
		
		job.add_header("Content-Type", 'multipart/form-data;boundary="' + manager.content_boundary + '"')
		
		for file in job.request_files:
			var file_content:PackedByteArray
			if file.has("path"):
				if FileAccess.file_exists( file.path ):
					file_content = FileAccess.get_file_as_bytes( file.path )
					if file_content.size() == 0:
						manager.e("POST file size zero")
				else:
					manager.e("POST file not found \""+file.path+"\"")
				
			if file.has("buffer"):
				file_content = file.buffer
				if file_content.size() == 0:
					manager.e("POST buffer size zero")
			
			body.append_array(("--"+manager.content_boundary).to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array(('Content-Disposition: form-data; name="' + file.name +'"; filename="'+file.basename+'"').to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array(("Content-Type: " + file.mime).to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array(file_content)
			body.append_array("\r\n".to_utf8_buffer())
		
		for name in job.request_post:
			body.append_array(("--"+manager.content_boundary).to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array(('Content-Disposition: form-data; name="' + name +'"').to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
			body.append_array(job.request_post[name].to_utf8_buffer())
			body.append_array("\r\n".to_utf8_buffer())
		
		body.append_array(("--"+manager.content_boundary+"--").to_utf8_buffer())
		body.append_array("\r\n".to_utf8_buffer())
	
	elif job.request_post.size() > 0:
		var query = manager.query_string_from_dict(job.request_post)
		job.add_header("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
		job.add_header("Content-Length", str(query.length()) )
		body = query.to_utf8_buffer()
	
	var headers:PackedStringArray = PackedStringArray()
	if job.request_headers.size() > 0:
		for h in job.request_headers:
			headers.append( h + ": " + job.request_headers[h] )
	
	if job.unsafe_ssl:
		set_tls_options ( TLSOptions.client_unsafe() )
	else:
		set_tls_options ( TLSOptions.client() )
	job.error = request_raw( url, headers, method, body )
	
	if job.error != OK:
		_on_pipe_request_completed( HTTPRequest.RESULT_REQUEST_FAILED, 0, [], [])


func _on_pipe_request_completed( result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray ):
	#analyse result
	if result != RESULT_SUCCESS:
		if manager._retry_on_result.find(result) != -1:
			if retry_job():
				return
		else:
			manager.d("job failed because result is "+manager._result_error_string[result]+" and will not retry")
	
	job.dispatch( result, response_code, headers, body )
	set_completed()
	manager._on_pipe_request_completed( )


func retry_job():
	if job.retries >= manager.max_retries:
		#managed failed here
		set_completed()
	else:
		job.retries += 1
		manager.d("retry "+str(job.retries)+"/"+str(manager.max_retries)+" job")
		manager.add_job( job )
		set_completed()
		return true



func set_completed():
	reset()
	manager.dispatch()

