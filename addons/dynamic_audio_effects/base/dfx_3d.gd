@tool
@icon("res://addons/dynamic_audio_effects/icons/dfx_3d.png")
extends Node3D
class_name DFX3D
## Mixes the strength of DFX children, based on a target's 3D distance to itself.

## The remote node, using for calculating distance-based mixing.
## When set to null, the viewport's Camera3D is used instead.
@export var target: Node3D = null

## When the target is below this distance, the DFX children will be fully mixed.
@export var minimum_distance := 64.0

## When the target is above this distance, the DFX children will be fully unmixed.
@export var maximum_distance := 256.0

## An additional mix factor, for further tuning effect balance.
@export_range(0.0, 1.0, 0.0001) var mix := 1.0

var _pre_mix := 0.0
var _post_mix := 0.0

var _dfx_children: Array[DFXBase] = []

func _ready() -> void:
	child_entered_tree.connect(_child_entered_tree)
	child_exiting_tree.connect(_child_exiting_tree)
	get_children().map(_child_entered_tree)
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return
	_physics_process(0.0)
	_post_mix = _pre_mix
	_process(0.0)

func _child_entered_tree(c: Node):
	if c is DFXBase:
		_dfx_children.append(c)
		update_configuration_warnings()

func _child_exiting_tree(c: Node):
	if c is DFXBase:
		_dfx_children.erase(c)
		update_configuration_warnings()

func _process(_delta: float) -> void:
	_set_child_mix(lerpf(_pre_mix, _post_mix, Engine.get_physics_interpolation_fraction()) * mix)

func _physics_process(_delta: float) -> void:
	# Obtain target.
	var t: Node3D = target
	if not target:
		var v := get_viewport()
		if not v: return
		t = v.get_camera_3d()
		if not t: return
	
	# Update pre/post mix values.
	_pre_mix = _post_mix
	_post_mix = clampf(
		1.0 - inverse_lerp(
			minimum_distance, maximum_distance,
			global_position.distance_to(t.global_position)
		), 0.0, 1.0
	)

func _set_child_mix(x: float):
	for dfx in _dfx_children:
		dfx._positional_mix = x

func _get_configuration_warnings() -> PackedStringArray:
	if not _dfx_children:
		return PackedStringArray(["This node has no DFX children, so it will have no function."])
	return PackedStringArray()
