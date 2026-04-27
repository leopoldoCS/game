extends Node

signal progress_loaded(data)
signal purchase_completed(data)
signal game_result_completed(data)
signal request_failed(message)

const DEFAULT_API_BASE_URL := "https://mamh.onrender.com/api/v1"

var api_base_url := ""
var auth_token := ""

var _progress_request: HTTPRequest
var _purchase_request: HTTPRequest
var _game_result_request: HTTPRequest


func _ready() -> void:
	api_base_url = OS.get_environment("MAMH_API_BASE_URL").strip_edges()
	auth_token = OS.get_environment("MAMH_AUTH_TOKEN").strip_edges()
	_load_web_config()
	if api_base_url == "":
		api_base_url = DEFAULT_API_BASE_URL

	_progress_request = HTTPRequest.new()
	add_child(_progress_request)
	_progress_request.request_completed.connect(_on_progress_completed)

	_purchase_request = HTTPRequest.new()
	add_child(_purchase_request)
	_purchase_request.request_completed.connect(_on_purchase_completed)

	_game_result_request = HTTPRequest.new()
	add_child(_game_result_request)
	_game_result_request.request_completed.connect(_on_game_result_completed)


func _load_web_config() -> void:
	if not OS.has_feature("web"):
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return

	var search = str(JavaScriptBridge.eval("window.location.search", true))
	if search == "":
		return

	var query_string = search.trim_prefix("?")
	for pair in query_string.split("&", false):
		if pair == "":
			continue
		var pieces = pair.split("=", true, 1)
		var raw_key = pieces[0]
		var raw_value = pieces[1] if pieces.size() > 1 else ""
		var key = raw_key.uri_decode()
		var value = raw_value.uri_decode()
		if key == "token" and auth_token == "":
			auth_token = value
		elif key == "apiBaseUrl" and api_base_url == "":
			api_base_url = value


func get_progress() -> void:
	if auth_token == "":
		request_failed.emit("Missing MAMH_AUTH_TOKEN")
		return

	var headers := PackedStringArray([
		"Authorization: Bearer %s" % auth_token,
		"Accept: application/json",
	])
	var error := _progress_request.request("%s/student/progress" % api_base_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		request_failed.emit("Could not load player progress")


func purchase_item(item_id: String, item_name: String, slot: String, cost: int) -> void:
	if auth_token == "":
		request_failed.emit("Missing MAMH_AUTH_TOKEN")
		return

	var headers := PackedStringArray([
		"Authorization: Bearer %s" % auth_token,
		"Content-Type: application/json",
		"Accept: application/json",
	])
	var body := JSON.stringify({
		"item_id": item_id,
		"name": item_name,
		"slot": slot,
		"cost": cost,
	})
	var error := _purchase_request.request(
		"%s/student/inventory/purchase" % api_base_url,
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	if error != OK:
		request_failed.emit("Could not purchase item")


func complete_run(placement: int) -> void:
	if auth_token == "":
		request_failed.emit("Missing MAMH_AUTH_TOKEN")
		return

	var headers := PackedStringArray([
		"Authorization: Bearer %s" % auth_token,
		"Content-Type: application/json",
		"Accept: application/json",
	])
	var body := JSON.stringify({"placement": placement})
	var error := _game_result_request.request(
		"%s/game/complete-run" % api_base_url,
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	if error != OK:
		request_failed.emit("Could not submit race result")


func _on_progress_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		request_failed.emit("Progress request failed: %s" % response_code)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Progress response was invalid")
		return

	progress_loaded.emit(parsed)


func _on_purchase_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var parsed_error = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed_error) == TYPE_DICTIONARY and parsed_error.has("detail"):
			request_failed.emit(str(parsed_error["detail"]))
			return
		request_failed.emit("Purchase request failed: %s" % response_code)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Purchase response was invalid")
		return

	purchase_completed.emit(parsed)


func _on_game_result_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var parsed_error = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed_error) == TYPE_DICTIONARY and parsed_error.has("detail"):
			request_failed.emit(str(parsed_error["detail"]))
			return
		request_failed.emit("Race reward request failed: %s" % response_code)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Race reward response was invalid")
		return

	game_result_completed.emit(parsed)
