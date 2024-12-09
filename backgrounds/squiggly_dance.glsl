#ifdef PIXEL

uniform float elapsed;


vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    const float eps = 0.02;
    float value = smoothstep(0, eps, texture_coords.y);

    return vec4(vec3(value), 1);
}

#endif
