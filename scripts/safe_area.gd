class_name SafeArea


# DisplayServer reports the safe area in screen pixels; this maps it into the viewport's units.
static func in_viewport(viewport: Viewport) -> Rect2:
	var window := Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area()).intersection(window)
	safe.position -= window.position
	return viewport.get_screen_transform().affine_inverse() * safe
