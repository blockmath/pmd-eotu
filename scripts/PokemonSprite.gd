extends Sprite3D

const Classes = preload("res://scripts/classes/classes.gd");

@onready
var sprite : Sprite3D = $"Sprite3D";

var actorType : String;
var pokemonID : String;
var animID : String;

var animDir : Classes.Direction;
var frameIndex : int;

var animOffsets : Texture2D;

var currentAnim : Dictionary;

func xmlTok(xml : Array): # [String]
	var token;
	var endIndex;
	if xml[0][0] == '<':
		endIndex = xml[0].find('>');
	else:
		endIndex = min(xml[0].find('<'), xml[0].find(' '), xml[0].find('\t')) - 1;
	token = xml[0].substr(0, endIndex);
	xml[0] = xml[0].substr(endIndex + 1);
	while xml[0].begins_with(' ') or xml[0].begins_with('\t'):
		xml[0] = xml[0].substr(1);
	return token;

func addDataAtPath(path : Array, data): # path = [path, to, data] (/path/to/data)
	var pwd : Dictionary = currentAnim;
	while len(path) > 1:
		if path[0] not in pwd:
			pwd[path[0]] = {};
		pwd = pwd[path[0]];
		path.pop_front();
	pwd[path[0]] = data;

func setPokemon(poke : String):
	pokemonID = poke;
	# TODO: load AnimData.xml into currentAnim
	var file = [FileAccess.get_file_as_string("res://sprites/pokemon/%s/AnimData.xml".format(pokemonID))];
	var dataPath = [];

func setActorType(_actorType : String):
	actorType = _actorType;

func setAnimation(anim : String):
	animID = anim;
	sprite.texture.atlas = load("res://sprites/pokemon/%s/%s-Anim.png".format(pokemonID, animID));
	animOffsets = load("res://sprites/pokemon/%s/%s-Offsets.png".format(pokemonID, animID));
	frameIndex = 0;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
