shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 10.0) = 10.0;
uniform vec4 outline_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);

    // If the pixel is fully transparent, we skip processing
    if (base_color.a == 0.0) {
        discard;
    }

    vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
    float max_alpha = 0.0;

    // Sample surrounding pixels to detect edges
    for (float x = -outline_width; x <= outline_width; x++) {
        for (float y = -outline_width; y <= outline_width; y++) {
            vec2 offset = vec2(x, y) * pixel_size;
            vec4 neighbor = texture(TEXTURE, UV + offset);
            max_alpha = max(max_alpha, neighbor.a);
        }
    }

    // If any surrounding pixel had transparency, apply outline color
    if (max_alpha > 0.0 && base_color.a < 1.0) {
        COLOR = outline_color;
    } else {
        COLOR = base_color;
    }
}
