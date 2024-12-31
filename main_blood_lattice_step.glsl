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

void computemain() {
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(cell_texture_in);

    // Read the current cell's data
    vec4 current_cell = imageLoad(cell_texture_in, cell_position);
    float current_depth = current_cell.x;
    vec2 current_velocity = current_cell.yz;

    // Initialize total_flux
    vec2 total_flux = vec2(0.0);

    // Iterate over all neighboring directions
    for (int i = 0; i < N; ++i) {
        ivec2 neighbor_position = cell_position + idirections[i];

        // Check if the neighbor is within bounds
        if (neighbor_position.x < 0 || neighbor_position.x >= size.x ||
        neighbor_position.y < 0 || neighbor_position.y >= size.y) {
            continue;
        }

        // Read the neighbor cell's data
        vec4 neighbor_cell = imageLoad(cell_texture_in, neighbor_position);
        float neighbor_depth = neighbor_cell.x;
        vec2 neighbor_velocity = neighbor_cell.yz;
        vec2 relative_velocity = neighbor_velocity - current_velocity;

        // Calculate the flux based on the relative velocity and depth difference
        total_flux += (current_depth - neighbor_depth) * directions[i];
    }

    // Update the current cell's depth
    float new_depth = current_depth + (total_flux.x + total_flux.y) * delta;
    new_depth = max(new_depth, 0);

    // Calculate the new velocity
    vec2 new_velocity = current_velocity + total_flux * delta ;

    // Write the updated depth and velocity back to the output texture
    imageStore(cell_texture_out, cell_position, vec4(new_depth, new_velocity, current_cell.w));
}