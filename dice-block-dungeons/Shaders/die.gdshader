shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    color.rgb = vec3(1.0) - color.rgb; // Invert RGB colors
    COLOR = color;
}
