uniform layout(rgba32f) image2D cell_texture_in;    // r: density, gb: velocity, z: elevation
uniform layout(rgba32f) image2D cell_texture_out;

uniform float delta = 1.0 / 60.0;

const vec2 directions[9] = vec2[9](
vec2( 0,  0),  // center

    vec2( 0,  1),  // top
    vec2( 1,  0),  // right
    vec2( 0, -1),  // bottom
    vec2(-1,  0),  // left

    vec2( 1,  1),  // top-right
    vec2( 1, -1),  // bottom-right
    vec2(-1, -1),  // bottom-left
    vec2(-1,  1)   // top-left
);

float norm_dot(vec2 a, vec2 b) {
    return (dot(normalize(a), normalize(b)) + 1) / 2.;
}

layout(local_size_x = 1, local_size_y = 1) in;
layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

}