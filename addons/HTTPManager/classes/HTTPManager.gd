extends Node
class_name HTTPManager

## a feature rich HTTP-Request-Manager
##
## [b]Features:[/b][br]
## 
## - multiply parrallel request queue managment[br]
## - add GET and POST variables[br]
## - add upload files via POST request[br]
## - decodes response on mime-type[br]
## - custom decoders for mime-type[br]
## - automatic progress display[br]
## 


##number of parallel http connections
@export var parallel_connections_count:int = 5
##The size of the buffer used and maximum bytes to read per iteration. See HTTPClient.read_chunk_size.
##Set this to a lower value (e.g. 4096 for 4 KiB) when downloading small files to decrease memory usage at the cost of download speeds.
@export var download_chunk_size:int = 65536
##If true, multithreading is used to improve performance.
@export var use_threads:bool = false
##If true, this header will be added to each request: Accept-Encoding: gzip, deflate telling servers that it's okay to compress response bodies.
@export var accept_gzip:bool = true
##Maximum allowed size for response bodies. If the response body is compressed, this will be used as the maximum allowed size for the decompressed body.
@export var body_size_limit:int = -1
##Maximum number of allowed redirects.
@export var max_redirects:int = 8
##If set to a value greater than 0.0 before the request starts, the HTTP request will time out after timeout seconds have passed and the request is not completed yet. For small HTTP requests such as REST API usage, set timeout to a value between 10.0 and 30.0 to prevent the application from getting stuck if the request fails to get a response in a timely manner. For file downloads, leave this to 0.0 to prevent the download from failing if it takes too much time.
@export var timeout:float = 0
##maximal times the manager retries to request the job after failed connection
@export var max_retries:int = 3
##automatically go into pause mode when a job failed
@export var pause_on_failure:bool = true
##the interval delay to update progress scene and fire progress signal
@export var signal_progress_interval:float = 0.5
##automatically display the progress scene when the queue is progressed
@export var display_progress:bool = false
##custom scene to display when the queue is progressed
@export var progress_scene:PackedScene = null
##print debug messages
@export var print_debug:bool = false


var _HTTPPipe = preload("res://addons/HTTPManager/classes/HTTPPipe.gd")
var _pipes:Array[HTTPRequest] = []
var _client:HTTPClient
var _jobs:Array[HTTPManagerJob] = []
##queue processing is currently paused when true
var is_paused:bool = false
##multipart post--data boundary
var content_boundary:String = "GodotHTTPManagerContentBoundaryString"
var _progress_timer:Timer
var _max_assigned_files:int = 0
var _progress_scene

var _mime_decoders:Dictionary

# retry _jobs on this request results
var _retry_on_result:Array = [
	HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH,
	HTTPRequest.RESULT_CANT_CONNECT,
		#Request failed while connecting.
	HTTPRequest.RESULT_CONNECTION_ERROR,
		#Request failed due to connection (read/write) error.
	HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR,
		#Request failed on SSL handshake.
	HTTPRequest.RESULT_NO_RESPONSE,
		#Request does not have a response (yet).
	HTTPRequest.RESULT_TIMEOUT,
	#------------
	#HTTPRequest.RESULT_CANT_RESOLVE,
		#Request failed while resolving.
	#HTTPRequest.RESULT_REQUEST_FAILED,
		#Request failed (currently unused).
	#HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,
		#Request reached its maximum redirect limit, see max_redirects.
	#HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED,
		#Request exceeded its maximum size limit, see body_size_limit.
]

const _result_error_string = {
	0: "SUCCESS",
	1: "CHUNKED BODY SIZE MISMATCH",
	2: "CANT CONNECT",
	3: "CANT RESOLVE",
	4: "CONNECTION ERROR",
	5: "TLS HANDSHAKE ERROR",
	6: "NO RESPONSE",
	7: "BODY SIZE LIMIT EXCEEDED",
	8: "REQUEST FAILED",
	11: "REDIRECT LIMIT REACHED",
	12: "TIMEOUT"
}

##emited when the manager goes into pause mode
signal paused
##emited when the manager unpause and resumes the queue
signal unpaused
##emited when the all _jobs in the queue has finished
signal completed
##emited when progressed interval fires
signal progress
##emited when a job failed
signal job_failed
##emited when a job succeeded
signal job_succeded
##emited when a job is completed
signal job_completed


func _ready():
	#load all mime decoders in the addon decoders directory
	var dir_name = "res://addons/HTTPManager/classes/decoders/"
	var dir = DirAccess.open( dir_name )
	if dir:
		var files = dir.get_files()
		for file_name in files:
			_mime_decoders[file_name.get_basename()] = dir_name+file_name
	
	#make a HTTPClient for utillity use
	_client = HTTPClient.new()
	
	#create the progress timer
	_progress_timer = Timer.new()
	_progress_timer.wait_time = signal_progress_interval
	_progress_timer.connect("timeout", self._on_progress_interval )
	add_child(_progress_timer)
	_progress_timer.start()
	_progress_timer.paused = true
	
	#load the custom progress scene
	if not progress_scene:
		progress_scene = load("res://addons/HTTPManager/progress/progress.tscn")
	
	#add the progress scene
	_progress_scene = progress_scene.instantiate()
	add_child( _progress_scene )
	_progress_scene.hide()
	
	#create the http _pipes
	for i in parallel_connections_count:
		var pipe = _HTTPPipe.new()
		_pipes.append( pipe )
		pipe.manager = self
		pipe.accept_gzip = accept_gzip
		pipe.body_size_limit = body_size_limit
		pipe.download_chunk_size = download_chunk_size
		pipe.max_redirects = max_redirects
		pipe.use_threads = use_threads
		add_child( pipe )


##creates a http job object with given request url
##returns HTTPManagerJob
func job( url:String ) -> HTTPManagerJob:
	var job = HTTPManagerJob.new()
	job.manager = self
	job.url = url
	return job


##add the job to the queue and starts processing the queue
func add_job( job:HTTPManagerJob ):
	_max_assigned_files += 1
	d("job added "+job.url)
	_jobs.append( job )
	dispatch()


func dispatch():
	if is_paused:
		#if paused dont dispacth a new job
		return
	
	#if _jobs in queue
	if _jobs.size() > 0:
		#check every pipe if not busy
		for pipe in _pipes:
			if not pipe.is_busy:
				#pop a job from the queue and pdispatch it
				var job = _jobs.pop_front()
				_progress_timer.paused = false
				if display_progress:
					_progress_scene.popup_centered()
				pipe.dispatch( job )
				
				if _jobs.size() <= 0:
					#when this was the last job in queue, return
					return


func query_string_from_dict( dict:Dictionary ):
	return _client.query_string_from_dict( dict )


func _on_pipe_request_completed():
	if _jobs.size() > 0:
		dispatch()
		return
	
	for pipe in _pipes:
		if pipe.is_busy:
			return
	
	#no more _jobs in queue or still in pipe, end execution
	_progress_timer.paused = true
	if display_progress:
		_progress_scene.hide()
	_max_assigned_files = 0
	emit_signal("completed")


func _on_progress_interval():
	var current_files = _jobs.size()
	var total_bytes:float = 0.00001
	var current_bytes:float = 0
	for pipe in _pipes:
		if pipe.is_busy:
			total_bytes += pipe.get_body_size ( )
			current_files += 1
			current_bytes += pipe.get_downloaded_bytes()
	
	if _progress_scene:
		emit_signal("progress", _max_assigned_files, current_files, total_bytes, current_bytes )
		_progress_scene.httpmanager_progress_update( _max_assigned_files, current_files, total_bytes, current_bytes )


##stops all _jobs and clears the queue
func clear():
	d("clear")
	_jobs.clear()
	for pipe in _pipes:
		pipe.reset()


##pauses queue execution 
##running requests will complete but no further requests will be started
func pause():
	d("paused")
	is_paused = true
	emit_signal("paused")


##resumes queue processing
func unpause():
	d("unpaused")
	is_paused = false
	emit_signal("unpaused")
	dispatch()


func d( msg ):
	if print_debug:
		print( "HTTPManager: "+str(msg) )


