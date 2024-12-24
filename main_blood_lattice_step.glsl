uniform layout(rgba32f) readonly image2D velocity_texture_top_in;    // r = top-left,    g = top,    b = top-right
uniform layout(rgba32f) readonly image2D velocity_texture_center_in; // r = left,        g = center, b = right
uniform layout(rgba32f) readonly image2D velocity_texture_bottom_in; // r = bottom-left, g = bottom, b = bottom-right

uniform layout(rgba32f) writeonly image2D velocity_texture_top_out;    // r = top-left,    g = top,    b = top-right
uniform layout(rgba32f) writeonly image2D velocity_texture_center_out; // r = left,        g = center, b = right
uniform layout(rgba32f) writeonly image2D velocity_texture_bottom_out; // r = bottom-left, g = bottom, b = bottom-right

uniform layout(rgba32f) writeonly image2D macroscopic; // r = density, g = x-velocity, b = y-velocity

uniform float relaxation_factor = 0.5;
uniform float delta = 1.0 / 60.0; // time delta

const vec2 velocities[9] = vec2[9](
    vec2( 0,  0),  // center
    vec2( 0,  1),  // top
    vec2( 1,  1),  // top-right
    vec2( 1,  0),  // right
    vec2( 1, -1),  // bottom-right
    vec2( 0, -1),  // bottom
    vec2(-1, -1),  // bottom-left
    vec2(-1,  0),  // left
    vec2(-1,  1)   // top-left
);

const float velocity_weights[9] = float[9](
    4.0 / 9.0,   // center
    1.0 / 9.0,   // top
    1.0 / 36.0,  // top-right
    1.0 / 9.0,   // right
    1.0 / 36.0,  // bottom-right
    1.0 / 9.0,   // bottom
    1.0 / 36.0,  // bottom-left
    1.0 / 9.0,   // left
    1.0 / 36.0   // top-left
);

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);


}