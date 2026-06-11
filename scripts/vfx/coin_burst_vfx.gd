extends "res://scripts/vfx/one_shot_animated_vfx.gd"
class_name CoinBurstVfx

@export var coin_sound_player_1: AudioStreamPlayer2D
@export var coin_sound_player_2: AudioStreamPlayer2D
@export var coin_sound_player_3: AudioStreamPlayer2D
@export var coin_sound_cutoff_seconds: float = 0.72

var _sound_stop_tween: Tween
var _coin_sound_random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_coin_sound_random.randomize()
	super._ready()


func play() -> void:
	super.play()
	_play_random_coin_sound()


func _play_random_coin_sound() -> void:
	var available_players: Array[AudioStreamPlayer2D] = []
	if coin_sound_player_1 != null:
		available_players.append(coin_sound_player_1)
	if coin_sound_player_2 != null:
		available_players.append(coin_sound_player_2)
	if coin_sound_player_3 != null:
		available_players.append(coin_sound_player_3)
	if available_players.is_empty():
		return

	_stop_coin_sounds()
	var selected_index: int = _coin_sound_random.randi_range(0, available_players.size() - 1)
	var selected_player: AudioStreamPlayer2D = available_players[selected_index]
	selected_player.play()

	if _sound_stop_tween != null and _sound_stop_tween.is_valid():
		_sound_stop_tween.kill()
	_sound_stop_tween = create_tween()
	_sound_stop_tween.tween_interval(maxf(coin_sound_cutoff_seconds, 0.0))
	_sound_stop_tween.tween_callback(_stop_coin_sounds)


func _stop_coin_sounds() -> void:
	if coin_sound_player_1 != null:
		coin_sound_player_1.stop()
	if coin_sound_player_2 != null:
		coin_sound_player_2.stop()
	if coin_sound_player_3 != null:
		coin_sound_player_3.stop()


func _resolve_child_references() -> void:
	super._resolve_child_references()
	if coin_sound_player_1 == null:
		coin_sound_player_1 = get_node_or_null("CoinSoundPlayer1") as AudioStreamPlayer2D
	if coin_sound_player_2 == null:
		coin_sound_player_2 = get_node_or_null("CoinSoundPlayer2") as AudioStreamPlayer2D
	if coin_sound_player_3 == null:
		coin_sound_player_3 = get_node_or_null("CoinSoundPlayer3") as AudioStreamPlayer2D
