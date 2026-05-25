extends Control

## forestfloor = only background. Stumps vs man depth by feet Y vs stump base Y.

const STUMP_TEXTURE := "res://assets/trees/stumps_log_01.png"
const STUMP_SCALE := 0.5 * 1.5 * 2.0
const PROP_COUNT := 14
const PROP_MARGIN := Vector2(90.0, 90.0)
const CLEAR_RADIUS := 150.0
const PLAYER_FEET_OFFSET := 28.0

@onready var _town_a: TextureRect = $Layer7_ForestFloor/TownA
@onready var _town_b: TextureRect = $Layer7_ForestFloor/TownB
@onready var _world: Node2D = $Layer5_Gameplay/World
@onready var _player: CharacterBody2D = $Layer5_Gameplay/World/Player

var _show_town_a := true
var _stump_bottom_offset := 0.0
var _stump_holders: Array[Node2D] = []


func _ready() -> void:
	add_to_group("game")
	_apply_town_visibility()
	_populate_stumps()


func _process(_delta: float) -> void:
	_update_depth_sort()


func switch_background() -> void:
	_show_town_a = not _show_town_a
	_apply_town_visibility()


func _apply_town_visibility() -> void:
	_town_a.visible = _show_town_a
	_town_b.visible = not _show_town_a


func _populate_stumps() -> void:
	_stump_holders.clear()
	if _world == null:
		return
	for child in _world.get_children():
		if child == _player:
			continue
		child.queue_free()

	var tex: Texture2D = load(STUMP_TEXTURE) as Texture2D
	if tex == null:
		push_warning("Missing %s" % STUMP_TEXTURE)
		return

	_stump_bottom_offset = tex.get_height() * STUMP_SCALE * 0.5

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var vp := get_viewport().get_visible_rect().size
	var center := vp * 0.5

	for _i in range(PROP_COUNT):
		var center_pos := _random_prop_position(rng, vp, center)
		var holder := Node2D.new()
		holder.position = center_pos + Vector2(0.0, _stump_bottom_offset)

		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(STUMP_SCALE, STUMP_SCALE)
		spr.position = Vector2(0.0, -_stump_bottom_offset)
		holder.add_child(spr)
		_world.add_child(holder)
		_stump_holders.append(holder)

	_update_depth_sort()


func _update_depth_sort() -> void:
	if _player == null:
		return
	var feet_y := _player.global_position.y + PLAYER_FEET_OFFSET
	var draw_list: Array[Dictionary] = [
		{"node": _player, "sort_y": feet_y},
	]
	for holder in _stump_holders:
		if is_instance_valid(holder):
			draw_list.append({"node": holder, "sort_y": holder.global_position.y})
	draw_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.sort_y < b.sort_y
	)
	for i in draw_list.size():
		(draw_list[i].node as CanvasItem).z_index = i


func _random_prop_position(rng: RandomNumberGenerator, vp: Vector2, center: Vector2) -> Vector2:
	for _attempt in range(24):
		var p := Vector2(
			rng.randf_range(PROP_MARGIN.x, vp.x - PROP_MARGIN.x),
			rng.randf_range(PROP_MARGIN.y, vp.y - PROP_MARGIN.y)
		)
		if p.distance_to(center) >= CLEAR_RADIUS:
			return p
	return center + Vector2(CLEAR_RADIUS + 80.0, 0.0)
