extends Node2D

const DataManager = preload("res://scripts/DataManager.gd");
const Classes = preload("res://scripts/classes/classes.gd");

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
var colorRect : ColorRect = $"ColorRect";
@onready
var actors : Dictionary = {
	"chara": get_tree().find_node("chara-root"),
	"player": get_tree().find_node("player-root"),
	"poke": get_tree().find_node("poke-root")
}

var cutsceneName : String;
var cutscene : Array; # Array<String>

var cutsceneRunning : bool;
var cutsceneIndex : int;

var keepGoing : bool;

func _input(event):
	if (event.is_action_pressed("A")):
		advanceDialog.emit();


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
	pass

func runDialog(line : String):
	if keepGoing and line != "</async>":
		await nextFrame;
	if (line.begins_with('<')):
		# Command
		var command = line.substr(1, line.find('>')).split(' ', false);
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
				pl.texture.atlas = load("res://portraits/pokemon/%04d.png".format(pkmn));
				pl.texture.region = Rect2((expressions.find(expression) % 5) * 40, floor(expressions.find(expression) / 5) * 40, 40, 40);
				pbl.visible = true;
			["portrait", "right", var chara, var expression]:
				var pkmn : int;
				if chara.is_valid_int():
					pkmn = int(chara);
				else:
					pkmn = DataManager.lookup("pkmn-id", chara);
				pbl.visible = false;
				pr.texture.atlas = load("res://portraits/pokemon/%04d.png".format(pkmn));
				var is_asym : bool = DataManager.lookup("pkmn-is-asym", pkmn);
				pr.texture.region = Rect2((expressions.find(expression) % 5) * 40, floor(expressions.find(expression) / 5) * (40 + (160 if is_asym else 0)), 40, 40);
				pr.flip_h = is_asym;
				pbr.visible = true;
			["await"]:
				await advanceDialog;
				textboxLabel.clear();
			["anim", var type, var actor, var anim]:
				actors[type].find_node(actor).setAnimation(anim);
			["async"]:
				keepGoing = true;
			["/async"]:
				keepGoing = false;
			["branch", var branchTarget]:
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
				var storedAnim : String = actor.animID;
				actor.setAnimation("Walk");
				var dt_frames : float = dt * Engine.get_frames_per_second();
				for i in range(int(dt_frames)):
					actor.transform = actor.transform.translated(Vector3(float(dx) / dt_frames, 0, float(dy) / dt_frames));
					await nextFrame;
				actor.transform = actor.transform.translated(Vector3(float(dx), 0, float(dy)));
				actor.setAnimation(storedAnim);
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
			["n"]:
				textboxLabel.append_text("\n");
			["gender", var chara, var case]:
				textboxLabel.append_text(DataManager.pronouns[DataManager.lookup("gender", chara)][case]);
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
			["trigger", "load", "map", var mapName]:
				get_tree().change_scene_to_file("res://scenes/scenes/%s.tscn".format(mapName));
				colorRect.color.a = 255;
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
	cutsceneIndex += 1;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	nextFrame.emit();
	
	pass
