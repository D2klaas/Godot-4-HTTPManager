[![version](https://img.shields.io/badge/plugin%20version-0.2.0-blue)](https://github.com/D2klaas/dzPortals)
# Godot 4 - HTTPManager
A feature rich Godot HTTP manager addon

## Features
* multiple simultanious requests
* queue managment
* add GET and POST variables
* add upload files via POST request
* decodes response based on mime-type
* custom decoders for mime-types
* automatic progress display
* web cache based on etag and modified-since headers

## Imstall
Download files and add them to your addons folder in your godot project.
Enable the plugin in prohect-settings

## Usage
Create a HTTPManager node in your scene-tree
($HTTPManager referres to the created node)

<details>
<summary>Simple example</summary>

```
func _on_completed( result ):
	print( result.fetch() )


$HTTPManager.job(
	"https://filesamples.com/samples/code/html/sample1.html"
).on_success( #adds a callback that will be fired on success
	self._on_completed
).get()
```

</details>


<details>
<summary>Simple download example</summary>

```
$HTTPManager.job(
	"https://filesamples.com/samples/image/jpg/sample_640%C3%97426.jpg"
).download("path_to_the_download_file")
```
</details>


<details>
<summary>Get an image</summary>

```
func _on_completed( result ):
	var img = result.fetch()
	# when the web server sends the correct mime-type 
	# the file get decoded as image and can be used immediately in godot
	# if the image is corrupt or not an image recognised by godot the decoder returns null
	if img:
		#do something with this image
		pass


$HTTPManager.job(
	"https://filesamples.com/samples/image/jpg/sample_640%C3%97426.jpg"
).on_success( 
	self._on_completed
).get()
```

</details>


<details>
<summary>Get an image and force mime-type</summary>

```
func _on_completed( result ):
	var img = result.fetch()
	# the call forces the result to be an image
	# if the file is corrupt or not an image you get null on fetch
	# the file get decoded as image and can be used immediately in godot
	if img:
		#do something with this image
		pass


$HTTPManager.job(
	"https://filesamples.com/samples/image/jpg/sample_640%C3%97426.jpg"
).mime( #now we are forcing the image mime decoder to be used
	"image/jpeg"
).on_success( 
	self._on_completed
).get()
```

</details>


<details>
<summary>Add GET or/and POST variables to the request</summary>

```
$HTTPManager.job(
	"https://www.google.com/search"
).add_get(
	"g", "term" 
).on_success( 
	self._on_completed
).get()


$HTTPManager.job(
	"https://www.google.com/search"
).add_get(
	"g", "term" 
).add_get({
	"fieldname1": "fieldvalue 1", 
	"fieldname2": "fieldvalue 2", 
}).add_post(
	"post_fieldname", "post_fieldvalue" 
).add_post({
	"post_fieldname1": "post_fieldvalue 1", 
	"post_fieldname2": "post_fieldvalue 2", 
}).on_success( 
	self._on_completed
).get()
```

</details>


<details>
<summary>Upload a file to the server</summary>

```
$HTTPManager.job(
	"https://www.foo.bar/search"
).add_file(
	"fieldname","path_to_upload_file", "mime/type" 
).add_file( #like so
	"avatar","myface.jpg", "image/jpeg" 
).on_success( 
	self._on_completed
).get()
```

</details>


<details>
<summary>Add credencials to the request</summary>

```
$HTTPManager.job( #auth basic credencials should only be send via https as the are send in plain-text!
	"https://www.foo.bar/search"
).auth_basic(
	"username","password" 
.on_success( 
	self._on_completed
).get()
```

</details>


## Supported mime decoder (by now)
### application/octet-stream
Base decoder. Just provides the result as PackedByteArray

### application/json
Tries to decode the result as json.\
Returns a Dictionary or null on fetch().

### text/*
Tries to decode the result as text based on the content-type charset\
Returns a string or null on fetch().\
Supported charset formats are asccii, utf-8, utf-16, utf-32\

### image/*
Tries to decode the result as image.\
Returns a Image or null on fetch().\
Supported formats are png, jpg, tga, bmp, webp

### image/texture
Tries to decode the result as image.\
Then constructs a texture from the image.\
Returns a Texture or null on fetch().\
**!!You have to force the mime-type "image/texture"**\
.mime( "image/texture" )

## Make custom mime decoder
Add a scriptfile in the addons/HTTPManager/decoders folder\
Name it "mediatype_subtype.gd"\
If you name it "application_custom.gd" the decoder will be evoked when effective mime is "application/custom"\
If you name it "application.gd" the decoder will be evoked when mime is from mediatype "application", but will not be used when there is the more specific decoder "application_custom" is present.\
The script should extend "res://addons/HTTPManager/classes/decoders/application_octet-stream.gd" or any usefull subclass\
You should overwrite the fetch() function with your decoding. Have a look into the existing decoders (especially image_texture.gd for forced mime-types)\

## Documentation

### HTTPManager
The manager node that runs the queue

**Properties**
* parallel_connections_count:int = 5\
  number of parallel http connections
  Cannot be changed after _ready state is reachead!

* download_chunk_size:int = 65536\
  The size of the buffer used and maximum bytes to read per iteration. See HTTPClient.read_chunk_size.\
  Set this to a lower value (e.g. 4096 for 4 KiB) when downloading small files to decrease memory usage at the cost of download speeds.

* use_threads:bool = false\
  If true, multithreading is used to improve performance.

* accept_gzip:bool = true\
  If true, this header will be added to each request: Accept-Encoding: gzip, deflate telling servers that it's okay to compress response bodies.

* body_size_limit:int = -1\
  Maximum allowed size for response bodies. If the response body is compressed, this will be used as the maximum allowed size for the decompressed body.\
  
* max_redirects:int = 8\
  Maximum number of allowed redirects.
  
* timeout:float = 0\
  If set to a value greater than 0.0 before the request starts, the HTTP request will time out after timeout seconds have passed and the request is not completed yet. For small HTTP requests such as REST API usage, set timeout to a value between 10.0 and 30.0 to prevent the application from getting stuck if the request fails to get a response in a timely manner. For file downloads, leave this to 0.0 to prevent the download from failing if it takes too much time.

* max_retries:int = 3\
  maximal times the manager retries to request the job after failed connection
  
* use_cache:bool = false\
  use caching

* cache_directory:String = "user://http-manager-cache"\
  cache directory
  
* pause_on_failure:bool = true\
  automatically go into pause mode when a job failed
  
* signal_progress_interval:float = 0.5\
  the interval delay to update progress scene and fire progress signal

* display_progress:bool = false\
  automatically display the progress scene when the queue is progressed

* progress_scene:PackedScene = null\
  custom scene to display when the queue is progressed

* print_debug:bool = false\
  print debug messages

* cacher = null\
  instance of the caching class
  on _ready the "HTTPManagerCacher.gd" is used

**Signals**

* paused\
  emited when the manager goes into pause mode
  
* unpaused()
  emited when the manager unpause and resumes the queue

* completed()\
  emited when all jobs in the queue has finished
  
* progress( assigned_files, current_files, total_bytes, current_bytes )\
  emited when progressed interval fires\
  assigned_files before last completed or clear has been reached/called\
  current_files number of files still in cue\
  total_bytes to download of all jobs currently worked on\
  current_bytes downloaded of all jobs currently worked on\
  
* job_failed( job:HTTPManagerJob )\
  emited when a job failed\
  on connection error or any result-code other than 200 or 304

* job_succeded( job:HTTPManagerJob )\
  emited when a job succeeded\
  result-code is 200 or 304
  
* job_completed( job:HTTPManagerJob )\
  emited when a job is completed successfully or not

**Methods**

* job( url:String ) -> HTTPManagerJob\
  creates a job

* pause()\
  pauses queue execution\
  running requests will complete but no further requests will be started

* unpause()\
  resumes queue processing

### HTTPManagerJob
A http request object that will be stored in the queue

**Properties**

there are no properties intended do be changed, use the appropriate functions instead

**Signals**

there are no signals for this object, use HTTPManager signals or the callback functions

**Methods**

most methods return self for method chaining

* func add_get( name, value=null ) -> HTTPManagerJob:\
  adds a GET field to the request\
  you can add fields with name of field an value of field\
  or a Dictionary containing fieldname:fieldvalue pairs\
  add_get( "fieldname", "fieldvalue" ) or add_get( {"fieldname":"fieldvalue"} )

* func add_post( name, value=null ) -> HTTPManagerJob:\
  adds a POST field to the request\
  you can add fields with name of field an value of field\
  or a Dictionary containing fieldname:fieldvalue pairs\
  add_get( "fieldname", "fieldvalue" ) or add_get( {"fieldname":"fieldvalue"} )

* func add_post_file( name:String, filepath:String, mime:String="application/octet-stream" ) -> HTTPManagerJob\
  adds a FILE(filepath) to the POST section(request body) with fieldname(name) and the mime-type(mime)\

* func add_post_buffer( name:String, buffer:PackedByteArray, mime:String="application/octet-stream" ) -> HTTPManagerJob\
  adds a binary buffer(buffer) to the POST section(request body) with fieldname(name) and the mime-type(mime)\

* add_header( name, value=null ) -> HTTPManagerJob\
  adds a HEADER to the request\
  you can add headers with name of header an value of header\
  or a Dictionary containing headername:headervalue pairs\
  add_header( "headername", "headervalue" ) or add_header( {"headername":"headervalue"} )\
  headers will be overwritten when set
  
* auth_basic( name:String, password:String )\
  adds auth basic credentials to the request header

* cache( use_cache:bool=true ) -> HTTPManagerJob\
  wether to use cache for this request or not\
  caching must be enabled in manager to be used

* mime( mime:String ) -> HTTPManagerJob\
  forces a specific mime-type to be used on decoding the response of the server

* charset( charset:String ) -> HTTPManagerJob\
  forces a specific charset to be used on decoding the response of the server\
  only used when decoding text

* unsafe() -> HTTPManagerJob\
  do not validate TLS\
  this makes the call to https more unsafe as the certificate of the server will not be checkedß
  
* add_callback( callback = null ) -> HTTPManagerJob\
  adds a callback that will be fired after completion

* on_success( callback:Callable ) -> HTTPManagerJob\
  adds callback to be fired when http-response-code succeeded with code 200 or 304

* on_success_set( object:Object, property:String ) -> HTTPManagerJob\
  sets property of object with the result  of the call on success

* on_failure( callback:Callable ) -> HTTPManagerJob\
  adds callback to be fired when http-response-code is not 200 or 304 or any connection error occured after all retries

* on_code( code:int, callback:Callable ) -> HTTPManagerJob\
  adds callback to be fired when http-response-code is code

* on_result( result:int, callback:Callable ) -> HTTPManagerJob\
  adds callback to be fired when connections result is result
 
* get( callback = null )\
  send the job to the queue and start dispatching\
  a callback can be added thats fires on completion (like add_callback) whether call is successful or not

* download( filepath:String, callback = null )\
  send the job to the queue and start dispatching\
  saves the response-body as file in filepath\
  a callback can be added thats fires on completion (like add_callback) whether call is successful or not
  
  
## Result Object
All callbacks of jobs will be called with a result object (decoder).\
The object provides the following informations:\

**Properties**

* request_headers:Dictionary
* request_get:Dictionary
* request_post:Dictionary
* request_files:Array[Dictionary]
---
* result:int
---
* response_code:int
* response_headers:Dictionary
* response_body:PackedByteArray
* response_mime:Array
* response_charset:String
---
* forced_mime:Array[String]
* forced_charset:String

**Methods**

* fetch()\
  will return the decoded document

