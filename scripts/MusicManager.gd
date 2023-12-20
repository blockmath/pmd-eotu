extends Node
class_name MusicManager;

signal nextFrameBeat;

# For simplicity, the AudioSlot enum values are the offset into the channel array which the audio slot starts at.
enum AudioSlot {
	MUSIC_0 = 0,
	MUSIC_1 = 16,
	SFX_0 = 32,
	SFX_1 = 36,
	SFX_2 = 40,
	SFX_3 = 44,
	SFX_4 = 48,
	SFX_5 = 52,
	SFX_6 = 56,
	SFX_7 = 60
}

# The audio player has 64 total channels.
# There are two music slots with 16 channels each that can be faded in/out independently,
# and 8 SFX slots with 4 channels each.
var _streamPlayers : Array;

var globalVolume;
var _slotVolumes : Dictionary = {};
var _channelVolumes : Array = [];


var _silence : AudioStreamMP3 = preload("res://audio/silence.mp3");

func dbToLinear(db):
	return 10 ** (db / 10.0);

func linearToDB(f):
	return 10 * log(f);

func recalculateChannelVolume(channel : int):
	var slotVolume : float;
	if (channel < 16):
		slotVolume = _slotVolumes[int(AudioSlot.MUSIC_0)];
	elif (channel < 32):
		slotVolume = _slotVolumes[int(AudioSlot.MUSIC_1)];
	else:
		slotVolume = _slotVolumes[int(channel / 4.0) * 4];
	_streamPlayers[channel].volume_db = linearToDB(globalVolume * slotVolume * _channelVolumes[channel]);

func recalculateChannelVolumes():
	for i in range(64):
		recalculateChannelVolume(i);

func _verifySlotValidity(slot : AudioSlot, channel : int):
	assert(channel >= 0);
	if (slot == AudioSlot.MUSIC_0 or slot == AudioSlot.MUSIC_1):
		assert(channel < 16);
	else:
		assert(channel < 4);

func getChannelOfAudioSlot(slot : AudioSlot, channel : int):
	_verifySlotValidity(slot, channel);
	return _streamPlayers[slot + channel];

func loadMusicSlot(slot : AudioSlot, musicFile : String):
	assert(slot == AudioSlot.MUSIC_0 or slot == AudioSlot.MUSIC_1);
	const fileNameFormat : String = "res://audio/music/%s/channel-%02d.mp3";
	for i in range(16):
		var fileName = fileNameFormat % [musicFile, i];
		if (FileAccess.file_exists(fileName)):
			getChannelOfAudioSlot(slot, i).stream = load(fileName);
		else:
			getChannelOfAudioSlot(slot, i).stream = _silence;

func loadSFXSlot(slot : AudioSlot, sfxFile : String):
	const fileNameFormat : String = "res://audio/sfx/%s/channel-%02d.mp3";
	for i in range(4):
		var fileName = fileNameFormat % [sfxFile, i];
		if (FileAccess.file_exists(fileName)):
			getChannelOfAudioSlot(slot, i).stream = load(fileName);
		else:
			getChannelOfAudioSlot(slot, i).stream = _silence;

func setSlotVolume(slot : AudioSlot, volume):
	_slotVolumes[int(slot)] = volume;
	recalculateChannelVolumes();

func setChannelVolume(slot : AudioSlot, channel : int, volume):
	_verifySlotValidity(slot, channel);
	var channelID : int = slot + channel;
	_channelVolumes[channelID] = volume;
	recalculateChannelVolume(channelID);

func fadeSlot(slot : AudioSlot, volumeStart, volumeEnd, timeFrames : int):
	for i in range(timeFrames):
		var f = float(i) / timeFrames;
		setSlotVolume(slot, lerp(volumeStart, volumeEnd, f));
		await nextFrameBeat;
	setSlotVolume(slot, volumeEnd);

func fadeChannel(slot : AudioSlot, channel : int, volumeStart, volumeEnd, timeFrames : int):
	_verifySlotValidity(slot, channel);
	for i in range(timeFrames):
		var f = float(i) / timeFrames;
		setChannelVolume(slot, channel, lerp(volumeStart, volumeEnd, f));
		await nextFrameBeat;
	setChannelVolume(slot, channel, volumeEnd);

func forEachChannelInSlot(slot : AudioSlot, callback):
	var n : int;
	if (slot == AudioSlot.MUSIC_0 or slot == AudioSlot.MUSIC_1):
		n = 16;
	else:
		n = 4;
	for i in range(slot, slot + n):
		callback.call_deferred(_streamPlayers[i]);

func pauseSlot(slot : AudioSlot):
	forEachChannelInSlot(slot, func (channel : AudioStreamPlayer):
		channel.set_stream_paused(true);
	);

func resumeSlot(slot : AudioSlot):
	forEachChannelInSlot(slot, func (channel : AudioStreamPlayer):
		channel.set_stream_paused(false);
	);

func startSlot(slot : AudioSlot):
	forEachChannelInSlot(slot, func (channel : AudioStreamPlayer):
		channel.play();
	);

func stopSlot(slot : AudioSlot):
	forEachChannelInSlot(slot, func (channel : AudioStreamPlayer):
		channel.stop();
	);

# Called when the node enters the scene tree for the first time.
func _ready():
	_streamPlayers = self.get_children();
	globalVolume = 0.5;
	for i in range(64):
		_channelVolumes.append(1.0);
	for i in AudioSlot.keys():
		_slotVolumes[int(i)] = 1.0;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	nextFrameBeat.emit();
