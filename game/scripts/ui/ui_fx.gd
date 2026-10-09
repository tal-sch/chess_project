extends Node

var anim_speed: float = 1.0
var reduce_motion: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _center_pivot(node: Control):
	if not node: return
	if node.has_method("get_size"):
		node.pivot_offset = node.size / 2.0

func _get_tween(node: Node, key: String = "ui_tween") -> Tween:
	if not is_instance_valid(node) or not node.is_inside_tree(): return null
	
	if node.has_meta(key):
		var old_tween = node.get_meta(key)
		if is_instance_valid(old_tween) and old_tween.is_running():
			old_tween.kill()
			
	var t = node.get_tree().create_tween().bind_node(node)
	node.set_meta(key, t)
	return t

func hover_grow(node: Control):
	if reduce_motion or not is_instance_valid(node): return
	_center_pivot(node)
	var t = _get_tween(node, "ui_tween_scale")
	if not t: return
	t.tween_property(node, "scale", Vector2(1.05, 1.05), 0.2 * anim_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	# Slight brightness glow
	var mt = _get_tween(node, "ui_tween_modulate")
	if mt:
		mt.tween_property(node, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2 * anim_speed).set_trans(Tween.TRANS_SINE)

func hover_reset(node: Control):
	if not is_instance_valid(node): return
	var t = _get_tween(node, "ui_tween_scale")
	if t:
		t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.25 * anim_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		
	var mt = _get_tween(node, "ui_tween_modulate")
	if mt:
		mt.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25 * anim_speed).set_trans(Tween.TRANS_SINE)

func squish_press(node: Control):
	if reduce_motion or not is_instance_valid(node): return
	_center_pivot(node)
	var t = _get_tween(node, "ui_tween_scale")
	if not t: return
	t.tween_property(node, "scale", Vector2(1.02, 0.92), 0.12 * anim_speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	play_sound("click")

func spring_to(node: Node, property: String, value: Variant, duration: float = 0.3):
	if not is_instance_valid(node): return
	var t = _get_tween(node, "ui_tween_" + property)
	if not t: return
	t.tween_property(node, property, value, duration * anim_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func pop_in(node: Control, delay: float = 0.0):
	if not is_instance_valid(node): return
	if reduce_motion:
		node.visible = true
		node.scale = Vector2.ONE
		node.modulate.a = 1.0
		return
		
	node.visible = true
	_center_pivot(node)
	node.scale = Vector2(0.8, 0.8)
	node.modulate.a = 0.0
	
	var t = _get_tween(node, "ui_tween_pop")
	if not t: return
	
	if delay > 0:
		t.tween_interval(delay)
		
	t.set_parallel(true)
	t.tween_property(node, "scale", Vector2.ONE, 0.35 * anim_speed).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, 0.2 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	play_sound("pop")

func pop_out(node: Control, delay: float = 0.0):
	if not is_instance_valid(node): return
	if reduce_motion:
		node.visible = false
		return
		
	var t = _get_tween(node, "ui_tween_pop")
	if not t: return
	
	if delay > 0:
		t.tween_interval(delay)
		
	t.set_parallel(true)
	t.tween_property(node, "scale", Vector2(0.9, 0.9), 0.2 * anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(node, "modulate:a", 0.0, 0.2 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(func(): node.visible = false)

func fade_slide_in(node: Control, direction: Vector2 = Vector2(0, 30), delay: float = 0.0):
	if not is_instance_valid(node): return
	if reduce_motion:
		node.visible = true
		node.modulate.a = 1.0
		return
		
	node.visible = true
	var base_pos = node.position
	# Store the original position if we haven't already
	if not node.has_meta("base_pos"):
		node.set_meta("base_pos", base_pos)
	else:
		base_pos = node.get_meta("base_pos")
		
	node.position = base_pos + direction
	node.modulate.a = 0.0
	
	var t = _get_tween(node, "ui_tween_slide")
	if not t: return
	
	if delay > 0:
		t.tween_interval(delay)
		
	t.set_parallel(true)
	t.tween_property(node, "position", base_pos, 0.35 * anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, 0.25 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func shake(node: Node):
	if reduce_motion or not is_instance_valid(node): return
	
	# Only works on 3D or 2D nodes with position
	var base_pos = node.position
	if not node.has_meta("shake_base_pos"):
		node.set_meta("shake_base_pos", base_pos)
	else:
		base_pos = node.get_meta("shake_base_pos")
		
	var t = _get_tween(node, "ui_tween_shake")
	if not t: return
	
	var strength = 0.1 if node is Node3D else 10.0
	var prop = "position:x"
	
	t.tween_property(node, prop, base_pos.x + strength, 0.05 * anim_speed).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, prop, base_pos.x - strength, 0.05 * anim_speed).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, prop, base_pos.x + (strength/2), 0.05 * anim_speed).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, prop, base_pos.x, 0.05 * anim_speed).set_trans(Tween.TRANS_SINE)

func pulse(node: Control):
	if reduce_motion or not is_instance_valid(node): return
	_center_pivot(node)
	var t = _get_tween(node, "ui_tween_pulse")
	if not t: return
	
	t.tween_property(node, "scale", Vector2(1.1, 1.1), 0.15 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.3 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Optional placeholder audio hooks
func play_sound(type: String):
	pass
