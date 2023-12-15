extends Node

class_name Classes

enum Direction {
	DOWN = 0,
	DOWN_RIGHT,
	RIGHT,
	UP_RIGHT,
	UP,
	UP_LEFT,
	LEFT,
	DOWN_LEFT
};

enum Gender {
	MALE, # he/him/his
	FEMALE, # she/her/hers
	NONBINARY, # they/them/theirs
	NEUTER # it/it/its
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
