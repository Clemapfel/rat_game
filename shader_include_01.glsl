#include "shader_include_folder/shader_include_02.glsl"

vec4 included_function_01() {
    return vec4(1, 0, 1, included_function_02());
}