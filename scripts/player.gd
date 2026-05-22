extends CharacterBody3D

## Walks on the XZ plane. Crossing MAP_HALF triggers switch_background on Main.

const SPEED: float = 3.5
const MAP_HALF: Vector2 = Vector2(7.0, 7.0)
const FOOT_HEIGHT: float = 0.0

var _anim: AnimationPlayer


func _ready() -> void:
	_anim = _find_animation_player(self)
	if _anim:
		var list := _anim.get_animation_list()
		for anim_name in list:
			var anim := _anim.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
		if list.size() > 0:
			_anim.play(_pick_walk_or_first())


func _physics_process(_delta: float) -> void:
	var input_dir := _read_move_input()
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
		_play_walk_if_needed()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		if _anim:
			_anim.stop()

	velocity.y = 0.0
	move_and_slide()
	global_position.y = FOOT_HEIGHT
	_check_map_edge()


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


func _check_map_edge() -> void:
	var p := global_position
	var crossed := false
	if p.x > MAP_HALF.x:
		p.x = -MAP_HALF.x + 0.75
		crossed = true
	elif p.x < -MAP_HALF.x:
		p.x = MAP_HALF.x - 0.75
		crossed = true
	if p.z > MAP_HALF.y:
		p.z = -MAP_HALF.y + 0.75
		crossed = true
	elif p.z < -MAP_HALF.y:
		p.z = MAP_HALF.y - 0.75
		crossed = true
	if crossed:
		get_tree().call_group("game", "switch_background")
	global_position = p


func _play_walk_if_needed() -> void:
	if _anim == null:
		return
	var name := _pick_walk_or_first()
	if _anim.current_animation != String(name) or not _anim.is_playing():
		_anim.play(name)


func _pick_walk_or_first() -> StringName:
	if _anim == null:
		return &""
	var list := _anim.get_animation_list()
	for anim_name in list:
		var s := String(anim_name).to_lower()
		if s.contains("walk") or s.contains("mixamo"):
			return anim_name
	if list.size() > 0:
		return list[0]
	return &""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_animation_player(c)
		if r:
			return r
	return null
