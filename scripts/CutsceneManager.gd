extends Node2D

const DataManager = preload("res://scripts/DataManager.gd");
const Classes = preload("res://scripts/classes/classes.gd");
const MusicManager = preload("res://scripts/MusicManager.gd");

signal nextFrame;
signal advanceDialog;

const expressions = [
	"normal",
	"happy",
	"pain",
	"angry",
	"worried",
	"sad",
	"crying",
	"shouting",
	"teary-eyed",
	"determined",
	"joyous",
	"inspired",
	"surprised",
	"dizzy",
	"special0",
	"special1",
	"sigh",
	"stunned",
	"special2",
	"special3"
]

@onready
var textboxObj : Node2D = $Textbox;
@onready
var textboxLabel : RichTextLabel = $Textbox/RichTextLabel;
@onready
var pbl : Sprite2D = $"Textbox/Portrait box (left)";
@onready
var pl : Sprite2D = $"Textbox/Portrait box (left)/Portrait";
@onready
var pbr : Sprite2D = $"Textbox/Portrait box (right)";
@onready
var pr : Sprite2D = $"Textbox/Portrait box (right)/Portrait";
@onready
var camera : Camera3D = get_tree().find_node("Camera");
@onready
var musicManager : MusicManager = get_tree().find_node("MusicManager");
@onready
var colorRect : ColorRect = $"ColorRect";
@onready
var actors : Dictionary = {
	"chara": get_tree().find_node("chara-root"),
	"player": get_tree().find_node("player-root"),
	"poke": get_tree().find_node("poke-root"),
	"world": get_tree().find_node("world-root")
}

var cutsceneName : String;
var cutscene : Array; # Array<String>

var cutsceneQueued;

var cutsceneRunning : bool;
var cutsceneIndex : int;

var keepGoing : bool;

func _input(event):
	if (event.is_action_pressed("A")):
		advanceDialog.emit();

func clear_node_children(node : Node):
	for n in node.get_children():
		node.remove_child(n);
		n.queue_free();

func passesExpression(value1, relationOp, value2):
	match relationOp:
		"eq":
			return (value1 == value2);
		"lt":
			return (value1 < value2);
		"gt":
			return (value1 > value2);
		"ne":
			return (value1 != value2);
		_:
			return false;

func playCutscene(cutName : String):
	playCutsceneAsync(cutName);

func playCutsceneAsync(cutName : String):
	cutsceneName = cutName;
	# Preloading cutscene
	var file = FileAccess.get_file_as_string("dialog/" + DataManager.locale + "/" + cutName + ".pmd"); # load cutscene from file
	cutscene = file.split("\n"); # Split on newlines
	for lineIndex in range(len(cutscene)): # Strip leading whitespace
		while cutscene[lineIndex].begins_with(' ') or cutscene[lineIndex].begins_with('\t'):
			cutscene[lineIndex] = cutscene[lineIndex].substr(1);
	# Initializing variables
	cutsceneRunning = true;
	keepGoing = false;
	cutsceneIndex = 0;
	# Run cutscene
	while cutsceneRunning:
		if keepGoing:
			runDialog(cutscene[cutsceneIndex]);
		else:
			await runDialog(cutscene[cutsceneIndex]);
		cutsceneIndex += 1;
	pass

func runDialog(line : String):
	if keepGoing and line != "</async>":
		await nextFrame;
	if (line.begins_with('<')):
		# Command
		var command = line.substr(1, line.find('>')).split(' ', false);
		print_debug(str(command));
		match command:
			["portrait", "none"]:
				pbl.visible = false;
				pbr.visible = false;
			["portrait", "left", var chara, var expression]:
				var pkmn : int;
				if chara.is_valid_int():
					pkmn = int(chara);
				else:
					pkmn = DataManager.lookup("pkmn-id", chara);
				pbr.visible = false;
				pl.texture.atlas = load("res://portraits/pokemon/%04d.png" % pkmn);
				pl.texture.region = Rect2((expressions.find(expression) % 5) * 40, floor(expressions.find(expression) / 5.0) * 40, 40, 40);
				pbl.visible = true;
			["portrait", "right", var chara, var expression]:
				var pkmn : int;
				if chara.is_valid_int():
					pkmn = int(chara);
				else:
					pkmn = DataManager.lookup("pkmn-id", chara);
				pbl.visible = false;
				pr.texture.atlas = load("res://portraits/pokemon/%04d.png" % pkmn);
				var is_asym : bool = DataManager.lookup("pkmn-is-asym", pkmn);
				pr.texture.region = Rect2((expressions.find(expression) % 5) * 40, floor(expressions.find(expression) / 5.0) * (40 + (160 if is_asym else 0)), 40, 40);
				pr.flip_h = is_asym;
				pbr.visible = true;
			["await"]:
				await advanceDialog;
				textboxLabel.clear();
			["anim", var type, var actor, var anim]:
				actors[type].find_node(actor).setAnimation(anim, false);
			["anim", var type, var actor, var anim, "loop"]:
				actors[type].find_node(actor).setAnimation(anim, true);
			["anim", var type, var actor, var anim, "await"]:
				await actors[type].find_node(actor).setAnimation(anim, false);
			["async"]:
				keepGoing = true;
			["/async"]:
				keepGoing = false;
			["branch", var branchTarget]:
				cutsceneIndex = cutscene.find("<label " + branchTarget + ">") - 1;
			["if", "global", var variable, var relationOp, var value, "then", "branch", var branchTarget]:
				if passesExpression(DataManager.globals[variable], relationOp, int(value) if value.is_valid_int() else value):
					cutsceneIndex = cutscene.find("<label " + branchTarget + ">") - 1;
			["if", "compare", "global", var var1, var relationOp, "global", var var2, "then", "branch", var branchTarget]:
				if passesExpression(DataManager.globals[var1], relationOp, DataManager.globals[var2]):
					cutsceneIndex = cutscene.find("<label " + branchTarget + ">") - 1;
			["label", var _label]:
				pass
			["camera", "move", var dx, var dy, "seconds", var dt]:
				var dt_frames : float = dt * Engine.get_frames_per_second();
				for i in range(int(dt_frames)):
					camera.transform = camera.transform.translated(Vector3(float(dx) / dt_frames, 0, float(dy) / dt_frames));
					await nextFrame;
			["facing", var type, var actorName, var direction]:
				var dir : Classes.Direction = Classes.Direction.find_key(direction);
				var actor : Node3D = actors[type].find_node(actorName);
				actor.animDir = dir;
			["move", var type, var actorName, var dx, var dy, "seconds", var dt]:
				var actor : Node3D = actors[type].find_node(actorName);
				actor.setAnimation("Walk", true);
				var dt_frames : float = dt * Engine.get_frames_per_second();
				for i in range(int(dt_frames)):
					actor.transform = actor.transform.translated(Vector3(float(dx) / dt_frames, 0, float(dy) / dt_frames));
					await nextFrame;
				actor.transform = actor.transform.translated(Vector3(float(dx), 0, float(dy)));
				actor.setAnimation("Idle", false);
			["name", var chara]:
				var text : String;
				if chara == "player":
					textboxLabel.append_text("[color=yellow]");
					text = DataManager.globals["playerName"];
				elif chara == "partner":
					textboxLabel.append_text("[color=yellow]");
					text = DataManager.globals["partnerName"];
				else:
					textboxLabel.append_text("[color=blue]");
					text = DataManager.pkmnNames[DataManager.lookup("pkmn-id", chara)];
				for ch in text:
					textboxLabel.append_text(ch);
					if not Input.is_action_pressed("B"):
						await nextFrame;
				textboxLabel.append_text("[color=white]");
			["space"]:
				textboxLabel.append_text(" ");
			["n"]:
				textboxLabel.append_text("\n");
			["gender", var chara, var case]:
				textboxLabel.append_text(DataManager.pronouns[DataManager.lookup("gender", chara)][int(case)]);
			["wait", "frames", var nframes]:
				for i in range(nframes):
					await nextFrame;
			["wait", "seconds", var nseconds]:
				var nframes = nseconds * Engine.get_frames_per_second();
				for i in range(nframes):
					await nextFrame;
			["trigger", "textbox", var arg1]:
				textboxObj.visible = (arg1 != "inactive");
			["trigger", "increment", "global", var variable]:
				DataManager.globals[variable] += 1;
			["trigger", "decrement", "global", var variable]:
				DataManager.globals[variable] -= 1;
			["trigger", "clear", "actors", var actorType]:
				clear_node_children(actors[actorType]);
			["trigger", "spawn", var actorType, var id]:
				var obj = load("res://scenes/objects/pokemon_sprite.tscn").instance();
				var objScript = obj.find_children()[0];
				objScript.setPokemon("%04d" % DataManager.lookup("pkmn-id", id));
				objScript.setActorType(actorType);
				obj.set_name(id);
				actors[actorType].add_child(obj);
			["trigger", "load", "map", var mapName]:
				colorRect.color.a = 255;
				clear_node_children(actors["chara"]);
				clear_node_children(actors["world"]);
				var mapScene = load("res://scenes/scenes/%s.tscn" % mapName).instance();
				actors["world"].add_child(mapScene);
			["trigger", "cutscene", var nextCutscene]:
				cutsceneQueued = nextCutscene;
				cutsceneRunning = false;
			["trigger", "fade", "in"]:
				for i in range(0, 256, 4):
					colorRect.color.a = 255 - i;
					await nextFrame;
				colorRect.color.a = 0;
			["trigger", "fade", "out"]:
				for i in range(0, 256, 4):
					colorRect.color.a = i;
					await nextFrame;
				colorRect.color.a = 255;
			_:
				print_debug("There was an error in the cutscene " + cutsceneName + ": Unknown command " + line);
	else:
		# Text
		for ch in line:
			textboxLabel.append_text(ch);
			if not Input.is_action_pressed("B"):
				await nextFrame;
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	nextFrame.emit();
	if cutsceneQueued != null:
		playCutscene(cutsceneQueued);
		cutsceneQueued = null;
	pass
