#ifdef PIXEL

uniform float strength; // in [0, 1]

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    int radius = int(strength * 15);

    vec3 sum = vec3(0.0);
    int count = 0;

    for (int x = -radius; x <= radius; ++x) {
        for (int y = -radius; y <= radius; ++y) {
            vec2 offset = vec2(float(x), float(y)) / textureSize(image, 0);
            sum += Texel(image, texture_coords + offset).rgb;
            count++;
        }
    }

    return vec4(sum / float(count), 1.0);
}

#endif