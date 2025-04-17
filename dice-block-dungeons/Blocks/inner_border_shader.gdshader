shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;
}
