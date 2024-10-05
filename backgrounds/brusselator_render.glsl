#ifdef PIXEL

#define MODE_RENDER 1
#define MODE_INITIALIZE = 2

uniform int mode;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    if (mode == MODE_RENDER) {
        vec4 value = Texel(image, texture_coords);
        return vec4(value.xyz, 1);
    }
    else if (mode == MODE_INITIALIZE) {
        return vec4(0, 0, 0, 1);
    }
}

#endif
