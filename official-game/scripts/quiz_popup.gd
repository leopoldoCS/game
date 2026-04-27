extends CanvasLayer

const QUIZ_URL = "http://127.0.0.1:8000/api/v1/game/local-quiz"

enum TileType {
	NORMAL,
	FREEZE,
	ANSWER_HELP
}

var tile_type
var test_mode = true

signal answered(was_correct)
signal wrong_answer


@onready var vbox = $PanelContainer/VBoxContainer
@onready var panel = $PanelContainer
@onready var feedback = $FeedbackLabel
@onready var question_label = $PanelContainer/VBoxContainer/QuestionHeader/QuestionLabel
@onready var grid = $PanelContainer/VBoxContainer/GridContainer

var _http_request: HTTPRequest
var _correct_index := -1

func _ready():
	feedback.visible = false
	_setup_buttons()
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	_set_loading_state()
	var error = _http_request.request(QUIZ_URL)
	if error != OK:
		_show_load_error("Could not reach local backend.")

func _set_loading_state():
	question_label.text = "Loading question..."
	for i in 4:
		var button = get_button(i)
		button.text = "..."
		button.disabled = true

func get_button(i):
	var names = ["ButtonA", "ButtonB", "ButtonC", "ButtonD"]
	return grid.get_node(names[i])

func _setup_buttons():
	for i in 4:
		var button = get_button(i)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(_on_answer_pressed.bind(i))

func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		_show_load_error("Backend returned %s." % response_code)
		if test_mode == true:
			_show_load_error("test mode")
			_on_answer("picked", "picked")
			return
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_show_load_error("Quiz response was invalid.")
		return

	var questions = parsed.get("questions", [])
	if questions.is_empty():
		_show_load_error("No quiz questions found.")
		return

	_render_question(questions.pick_random())

func _render_question(question: Dictionary):
	var answers = question.get("answers", [])
	if answers.size() < 4:
		_show_load_error("Question is missing answers.")
		return

	_correct_index = int(question.get("correct_index", -1))
	question_label.text = str(question.get("prompt", "Question unavailable"))
	for i in 4:
		var button = get_button(i)
		button.text = str(answers[i])
		button.disabled = false

func _show_load_error(message: String):
	question_label.text = message
	for i in 4:
		var button = get_button(i)
		button.text = "-"
		button.disabled = true
	feedback.text = "BACKEND OFFLINE"
	feedback.visible = true

func _on_answer_pressed(picked):
	_on_answer(picked, _correct_index)

func _on_answer(picked, correct):
	for j in 4:
		get_button(j).disabled = true

	var was_correct = (picked == correct)

	vbox.visible = false
	feedback.visible = true

	if was_correct && tile_type == TileType.NORMAL:
		feedback.text = "CORRECT!"
		panel.get_theme_stylebox("panel").bg_color = Color("#2ecc71")
	elif was_correct && tile_type == TileType.FREEZE:
		feedback.text = "Freeze!"
		panel.get_theme_stylebox("panel").bg_color = Color("82ccd3ff")
	elif was_correct && tile_type == TileType.ANSWER_HELP:
		feedback.text = "HELP!"
		panel.get_theme_stylebox("panel").bg_color = Color("f6f55cff")
	else:
		feedback.text = "SPINOUT!"
		panel.get_theme_stylebox("panel").bg_color = Color("#e74c3c")

	await get_tree().create_timer(1.5).timeout
	panel.get_theme_stylebox("panel").bg_color = Color("#d9d9d9")

	if was_correct:
		emit_signal("answered", true)
		queue_free()
	else:
		emit_signal("wrong_answer")
		vbox.visible = true
		feedback.visible = false
		for j in 4:
			get_button(j).disabled = false
