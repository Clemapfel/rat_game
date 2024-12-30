layout(local_size_x = 1, local_size_y = 1) in;
uniform layout(rgba32f) image2D cell_texture_in;    // x: depth, yz: velocity, w: elevation
uniform layout(rgba32f) image2D cell_texture_out;

uniform float delta = 1.0 / 60.0;
uniform float gravity = 9.0;
uniform float viscosity = 1.0;

#define N 9
vec2 directions[N] = vec2[N](
vec2(-1.0, -1.0),  // top left
vec2( 0.0, -1.0),  // top
vec2( 1.0, -1.0),  // top right
vec2(-1.0,  0.0),  // left
vec2( 0.0,  0.0),  // center
vec2( 1.0,  0.0),  // right
vec2(-1.0,  1.0),  // bottom left
vec2( 0.0,  1.0),  // bottom
vec2( 1.0,  1.0)   // bottom right
);

ivec2 idirections[N] = ivec2[N](
ivec2(-1, -1),  // top left
ivec2( 0, -1),  // top
ivec2( 1, -1),  // top right
ivec2(-1,  0),  // left
ivec2( 0,  0),  // center
ivec2( 1,  0),  // right
ivec2(-1,  1),  // bottom left
ivec2( 0,  1),  // bottom
ivec2( 1,  1)   // bottom right
);

float bernoulli_hydraulic_head(vec4 data) {
    float bed = data.w;
    float depth = data.x;
    vec2 velocity = data.yz;
    return bed + depth + (velocity.x * velocity.x + velocity.y * velocity.y) / (2.0 * gravity);
}

void computemain() {
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(cell_texture_in);

    vec4 self_data = imageLoad(cell_texture_in, cell_position);
    float self_head = bernoulli_hydraulic_head(self_data);

    float other_heads[N];
    for (int i = 0; i < N; ++i) {
        ivec2 neighbor_position = cell_position + idirections[i];
        if (neighbor_position.x < 0 || neighbor_position.x >= size.x || neighbor_position.y < 0 || neighbor_position.y >= size.y) {
            other_heads[i] = self_head; // Use self_head for out-of-bound neighbors
        } else {
            vec4 neighbor_data = imageLoad(cell_texture_in, neighbor_position);
            other_heads[i] = bernoulli_hydraulic_head(neighbor_data);
        }
    }

    float fluxes[N];
    vec2 flux_velocity = vec2(0);
    float net_flux = 0;
    for (int i = 0; i < N; ++i) {
        float head_difference = self_head - other_heads[i];
        float flux = head_difference * gravity * delta;
        fluxes[i] = flux;
        flux_velocity += flux * directions[i];
        net_flux += flux;
    }

    float new_depth = max(self_data.x + net_flux * delta, 0.0);
    vec2 new_velocity = self_data.yz;
    if (new_depth > 0.0) {
        new_velocity += (flux_velocity / new_depth) * delta;
    }

    imageStore(cell_texture_out, cell_position, vec4(new_depth, new_velocity, self_data.w));
}