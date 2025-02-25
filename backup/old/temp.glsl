uniform float value; // in [0, 1], where 0: all occluded, 1: all visible

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 frag_position) {
    vec2 position = frag_position / love_ScreenSize.xy;
    position.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec2 center = vec2(0.5);
    center.x *= love_ScreenSize.x / love_ScreenSize.y;

    const float eps = 0.03;
    return color * vec4(vec3(smoothstep(value, value + eps, distance(position, center))), 1);
}