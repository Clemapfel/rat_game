uniform float elapsed;

float sdf_circle(vec2 point, vec2 center,  float radius) {
    return length(point - center) - radius;
}

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float smooth_min(float a, float b, float smoothness) {
    float h = max(smoothness - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / smoothness;
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float normalization_factor = love_ScreenSize.y / love_ScreenSize.x;
    vec2 position = vertex_position / love_ScreenSize.xy * vec2(1, normalization_factor);
    vec2 center = vec2(0.5, 0.5) * vec2(1, normalization_factor);

    const float radius = 0.1;
    const float smoothness = 0.3;
    float value_1 = sdf_circle(position, center + vec2(cos(elapsed) * 0.1, 0), radius);
    float value_2 = sdf_circle(position, center + vec2(0, sin( 2 * elapsed) * 0.1), radius);

    const float light_factor = 0.4;
    float light_1 = sdf_circle(position, center + vec2(cos(elapsed) * 0.1, 0) - (1 - light_factor) * radius * 2, light_factor * radius);
    float light_2 = sdf_circle(position, center + vec2(0, sin(elapsed) * 0.1) - (1 - light_factor) * radius * 2, light_factor * radius);

    vec3 pink = hsv_to_rgb(vec3(318. / 360., 60. / 100., 100. / 100.));
    vec3 light_pink = hsv_to_rgb(vec3(318. / 360., 36. / 100., 100.));

    float signed_distance = smooth_min(light_1, light_2, smoothness); // + smooth_min(value_1, value_2, 0.02); //, smoothness);

    const float border = 0.001;
    float final = smoothstep(-border, +border, signed_distance);
    return vec4(vec3(1 - final) * pink, final);
}