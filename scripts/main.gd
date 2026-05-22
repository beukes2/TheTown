extends Node3D

## Fixed isometric-style view: camera follows the player with a constant world offset.

const CAM_OFFSET := Vector3(14.0, 16.0, 14.0)

## Kenney Nature Kit (CC0) — see `res://assets/forest/LICENSE-Kenney-Nature-Kit.txt`.
const FOREST_PROPS: Array[String] = [
	"res://assets/forest/tree_default.fbx",
	"res://assets/forest/tree_detailed.fbx",
	"res://assets/forest/tree_cone.fbx",
	"res://assets/forest/plant_bush.fbx",
	"res://assets/forest/plant_bushLarge.fbx",
	"res://assets/forest/grass_large.fbx",
	"res://assets/forest/ground_grass.fbx",
	"res://assets/forest/ground_pathStraight.fbx",
]
const FOREST_COUNT := 38
const FOREST_HALF := Vector2(6.2, 6.2)
const FOREST_CLEAR_RADIUS := 1.8

@onready var _player: CharacterBody3D = $Player
@onready var _cam: Camera3D = $Camera3D
@onready var _town_a: Node3D = $World/TownA
@onready var _town_b: Node3D = $World/TownB
@onready var _forest: Node3D = $World/Forest

var _show_town_a := true


func _ready() -> void:
	add_to_group("game")
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = 7.5
	_apply_town_visibility()
	_populate_forest()


func _process(_delta: float) -> void:
	if _player and _cam:
		var target := _player.global_position
		_cam.global_position = target + CAM_OFFSET
		_cam.look_at(target, Vector3.UP)


func switch_background() -> void:
	_show_town_a = not _show_town_a
	_apply_town_visibility()


func _apply_town_visibility() -> void:
	_town_a.visible = _show_town_a
	_town_b.visible = not _show_town_a


func _populate_forest() -> void:
	if _forest == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _n in range(FOREST_COUNT):
		var path_str := FOREST_PROPS[rng.randi_range(0, FOREST_PROPS.size() - 1)]
		var ps: PackedScene = load(path_str) as PackedScene
		if ps == null:
			push_warning("Forest: could not load %s" % path_str)
			continue
		var inst := ps.instantiate()
		var xz := Vector2.ZERO
		for _attempt in range(16):
			xz = Vector2(
				rng.randf_range(-FOREST_HALF.x, FOREST_HALF.x),
				rng.randf_range(-FOREST_HALF.y, FOREST_HALF.y)
			)
			if xz.length() >= FOREST_CLEAR_RADIUS:
				break
		inst.position = Vector3(xz.x, 0.0, xz.y)
		inst.rotation.y = rng.randf() * TAU
		var sc := rng.randf_range(0.85, 1.35)
		inst.scale = Vector3(sc, sc, sc)
		_forest.add_child(inst)
