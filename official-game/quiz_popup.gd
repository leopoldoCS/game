extends CanvasLayer

var questions = [
	{"question": "What is 2 + 2?", "answers": ["1", "4", "5", "12"], "correct": 1},
	{"question": "What is 5 x 3?", "answers": ["8", "12", "15", "20"], "correct": 2},
	{"question": "What is 10 - 7?", "answers": ["2", "3", "4", "5"], "correct": 1},
	{"question": "What is 9 / 3?", "answers": ["2", "3", "6", "1"], "correct": 1},
	{"question": "What is 6 + 7?", "answers": ["11", "14", "13", "12"], "correct": 2},
	{"question": "What is 8 x 2?", "answers": ["18", "14", "16", "12"], "correct": 2},
	{"question": "What is 20 - 5?", "answers": ["25", "10", "5", "15"], "correct": 3},
	{"question": "What is 36 / 6?", "answers": ["5", "7", "8", "6"], "correct": 3},
	{"question": "What is 4 x 4?", "answers": ["16", "12", "8", "20"], "correct": 0},
	{"question": "What is 50 - 25?", "answers": ["30", "15", "20", "25"], "correct": 3},
]

signal answered(was_correct)

@onready var vbox = $PanelContainer/VBoxContainer
@onready var panel = $PanelContainer
@onready var feedback = $FeedbackLabel
@onready var question_label = $PanelContainer/VBoxContainer/QuestionHeader/QuestionLabel
@onready var grid = $PanelContainer/VBoxContainer/GridContainer

func _ready():
	feedback.visible = false
	var q = questions.pick_random()
	question_label.text = q["question"]
	for i in 4:
		get_button(i).text = q["answers"][i]
		get_button(i).pressed.connect(_on_answer.bind(i, q["correct"]))

func get_button(i):
	var names = ["ButtonA", "ButtonB", "ButtonC", "ButtonD"]
	return grid.get_node(names[i])

func _on_answer(picked, correct):
	for j in 4:
		get_button(j).disabled = true

	var was_correct = (picked == correct)

	vbox.visible = false
	feedback.visible = true

	if was_correct:
		feedback.text = "BOOST!"
		panel.get_theme_stylebox("panel").bg_color = Color("#2ecc71")
	else:
		feedback.text = "SPINOUT!"
		panel.get_theme_stylebox("panel").bg_color = Color("#e74c3c")

	await get_tree().create_timer(1.5).timeout
	panel.get_theme_stylebox("panel").bg_color = Color("#d9d9d9")
	emit_signal("answered", was_correct)
	queue_free()
