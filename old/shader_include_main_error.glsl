
#include "shader_include_01.glsl"

#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    return included_function_01();
    1234
}

#endif
