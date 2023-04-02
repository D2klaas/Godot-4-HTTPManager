[![version](https://img.shields.io/badge/plugin%20version-0.2.0-blue)](https://github.com/D2klaas/dzPortals)
# Godot - HTTPManager
A feature rich Godot HTTP manager addon

## Features
* multiple simultanious requests
* queue managment
* add GET and POST variables
* add upload files via POST request
* decodes response on mime-type
* custom decoders for mime-types
* automatic progress display

## Imstall
Download files and add them to your addons folder in your godot project.

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
).add_post(
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
	"https://www.google.com/search"
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
<summary>Add credecials to the request</summary>

```
$HTTPManager.job(
	"https://www.google.com/search"
).auth_basic(
	"username","password" 
.on_success( 
	self._on_completed
).get()
```

</details>


## Supported mime decoder (by now)
### application/octet
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

## Result Object
All callbacks will be called with a result object (decoder).\
The object provides the following informations:\

* request_headers:Dictionary
* request_get:Dictionary
* request_post:Dictionary
* request_files:Array[Dictionary]
* ---
* result:int
* ---
* response_code:int
* response_headers:Dictionary
* response_body:PackedByteArray
* response_mime:Array
* response_charset:String
* ---
* forced_mime:Array[String]
* forced_charset:String

The fetch() function provides the mime-type specific result or null if it fails to decode request result
