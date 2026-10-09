extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	
	# Apply to existing nodes in case we missed them during startup
	_apply_to_tree(get_tree().root)

func _apply_to_tree(node: Node):
	if node is BaseButton:
		_bind_button(node)
	for child in node.get_children():
		_apply_to_tree(child)

func _on_node_added(node: Node):
	if node is BaseButton:
		_bind_button(node)

func _bind_button(btn: BaseButton):
	if btn.has_meta("has_ui_fx"): return
	btn.set_meta("has_ui_fx", true)
	
	# Change pivot point for scaling from center
	if btn.has_method("get_size"):
		btn.pivot_offset = btn.size / 2.0
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			UIFX.hover_grow(btn)
	)
	
	btn.mouse_exited.connect(func():
		if not btn.disabled:
			UIFX.hover_reset(btn)
	)
	
	btn.button_down.connect(func():
		if not btn.disabled:
			UIFX.squish_press(btn)
	)
	
	btn.button_up.connect(func():
		if not btn.disabled:
			# If mouse is still over it, reset to hover state. Otherwise, default.
			if btn.is_hovered():
				UIFX.hover_grow(btn)
			else:
				UIFX.hover_reset(btn)
	)
