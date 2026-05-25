extends CharacterBody2D

## Layer 6 — walks on screen (X/Y pixels). Crossing bounds triggers switch_background.

## Pixels per second (screen space). 80% / 95% slower than base, then +70%, then +40% faster.
const SPEED_BASE: float = 200.0 * 1.7 * 1.4
const SPEED_H: float = SPEED_BASE * 0.2
const SPEED_V: float = SPEED_BASE * 0.05
const MAP_MARGIN := Vector2(80.0, 80.0)

const WALK_TEXTURE := "res://assets/QWE-walk.png"
const WALK_COLS := 5
const WALK_ROWS := 5
const WALK_FPS := 10.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing_right := true


func _ready() -> void:
	if _sprite:
		_sprite.sprite_frames = _build_walk_frames()
		_sprite.play(&"walk")
		_sprite.stop()


func _physics_process(_delta: float) -> void:
	var input_dir := _read_move_input()
	if input_dir.length() > 0.01:
		velocity = Vector2(input_dir.x * SPEED_H, input_dir.y * SPEED_V)
		_update_facing(input_dir)
		if _sprite and not _sprite.is_playing():
			_sprite.play(&"walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED_H)
		if _sprite:
			_sprite.stop()

	move_and_slide()
	_clamp_to_play_area()


func _read_move_input() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y += 1.0
	return Vector2(x, y)


func _update_facing(input_dir: Vector2) -> void:
	if _sprite == null:
		return
	if absf(input_dir.x) > 0.05:
		_facing_right = input_dir.x > 0.0
	_sprite.flip_h = not _facing_right


func _clamp_to_play_area() -> void:
	var vp := get_viewport().get_visible_rect().size
	var min_p := MAP_MARGIN
	var max_p := vp - MAP_MARGIN
	var p := global_position
	var crossed := false
	if p.x > max_p.x:
		p.x = min_p.x + 40.0
		crossed = true
	elif p.x < min_p.x:
		p.x = max_p.x - 40.0
		crossed = true
	if p.y > max_p.y:
		p.y = min_p.y + 40.0
		crossed = true
	elif p.y < min_p.y:
		p.y = max_p.y - 40.0
		crossed = true
	if crossed:
		get_tree().call_group("game", "switch_background")
	global_position = p


func _build_walk_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"walk")
	sf.set_animation_loop(&"walk", true)
	sf.set_animation_speed(&"walk", WALK_FPS)
	var tex: Texture2D = load(WALK_TEXTURE)
	var fw := tex.get_width() / WALK_COLS
	var fh := tex.get_height() / WALK_ROWS
	for row in WALK_ROWS:
		for col in WALK_COLS:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			sf.add_frame(&"walk", at)
	return sf
