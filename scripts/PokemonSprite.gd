extends Sprite3D

const Classes = preload("res://scripts/classes/classes.gd");

signal nextAnimFrame;

@onready
var sprite : Sprite3D = $"Sprite3D";

var actorType : String;
var pokemonID : String;
var animID : String;

var animDir : Classes.Direction;
var frameIndex : int;

var animOffsets : Texture2D;
var animShadow : Texture2D;

var animData : Dictionary;
var currentAnim : Dictionary;

var animRect : Rect2;

var animFrames : Array;


func setPokemon(poke : String):
	pokemonID = poke;
	var expression = Expression.new();
	expression.parse(FileAccess.get_file_as_string("res://sprites/pokemon/%s/AnimData.json" % [pokemonID]));
	animData = expression.execute();

func setActorType(_actorType : String):
	actorType = _actorType;

func _findAnim():
	for animDict in animData["Anims"]:
		if animDict["Name"] == animID:
			currentAnim = animDict;
			if "CopyOf" in currentAnim.keys():
				animID = currentAnim["CopyOf"];
				_findAnim();
			return;

func setAnimation(anim : String, shouldLoop : bool):
	animID = anim;
	_findAnim();
	sprite.texture.atlas = load("res://sprites/pokemon/%s/%s-Anim.png" % [pokemonID, animID]);
	sprite.hframes = len(currentAnim["Durations"]);
	sprite.vframes = 1;
	animOffsets = load("res://sprites/pokemon/%s/%s-Offsets.png" % [pokemonID, animID]);
	animShadow = load("res://sprites/pokemon/%s/%s-Shadow.png" % [pokemonID, animID]);
	frameIndex = 0;
	animFrames = [];
	for i in range(len(currentAnim["Durations"])):
		for j in range(currentAnim["Durations"][i]):
			animFrames.append(i);
	while frameIndex < len(animFrames):
		sprite.frame = animFrames[frameIndex];
		frameIndex += 1;
		if frameIndex >= len(animFrames) and shouldLoop:
			frameIndex = 0;
		await nextAnimFrame;

func setDirection(dir : Classes.Direction):
	animRect = Rect2(0, int(currentAnim["FrameHeight"]) * int(dir), int(currentAnim["FrameWidth"]) * len(currentAnim["Durations"]), int(currentAnim["FrameHeight"]));
	sprite.texture.region = animRect;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	nextAnimFrame.emit();
	pass
