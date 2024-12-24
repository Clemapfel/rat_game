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

    // Load input velocities from textures
    vec4 top_in = imageLoad(velocity_texture_top_in, position);
    vec4 center_in = imageLoad(velocity_texture_center_in, position);
    vec4 bottom_in = imageLoad(velocity_texture_bottom_in, position);

    // Combine input velocities into an array
    float velocities_in[9] = float[9](
        center_in.g,           // center
        top_in.g,              // top
        top_in.b,              // top-right
        center_in.b,           // right
        bottom_in.b,           // bottom-right
        bottom_in.g,           // bottom
        bottom_in.r,           // bottom-left
        center_in.r,           // left
        top_in.r               // top-left
    );

    // Compute macroscopic quantities: density and velocity
    float density = 0.0;
    vec2 velocity = vec2(0.0);

    for (int i = 0; i < 9; i++) {
        density += velocities_in[i];
        velocity += velocities_in[i] * velocities[i];
    }

    velocity /= density;

    // Compute equilibrium distribution function
    float velocities_eq[9];
    for (int i = 0; i < 9; i++) {
        float dot_product = dot(velocity, velocities[i]);
        float velocity_square = dot(velocity, velocity);
        velocities_eq[i] = velocity_weights[i] * density * (1.0 + 3.0 * dot_product + 4.5 * dot_product * dot_product - 1.5 * velocity_square);
    }

    // Relaxation step
    float velocities_out[9];
    for (int i = 0; i < 9; i++) {
        velocities_out[i] = mix(velocities_in[i], velocities_eq[i], relaxation_factor);
    }

    // Write output velocities to textures
    imageStore(velocity_texture_top_out, position, vec4(velocities_out[8], velocities_out[1], velocities_out[2], 1.0));
    imageStore(velocity_texture_center_out, position, vec4(velocities_out[7], velocities_out[0], velocities_out[3], 1.0));
    imageStore(velocity_texture_bottom_out, position, vec4(velocities_out[6], velocities_out[5], velocities_out[4], 1.0));

    // Write macroscopic quantities to the macroscopic texture
    imageStore(macroscopic, position, vec4(density, velocity, 0.0));
}