uniform layout(rgba32f) image2D cell_texture_in;    // x: depth, yz: velocity, w: elevation
uniform layout(rgba32f) image2D flux_texture_top_in; // x: top-left y:top z:top-right
uniform layout(rgba32f) image2D flux_texture_center_in; // x: left y:center z:right
uniform layout(rgba32f) image2D flux_texture_bottom_in; // x:bottom-left y:bottom z:bottom-right

uniform layout(rgba32f) image2D cell_texture_out;
uniform layout(rgba32f) image2D flux_texture_top_out;
uniform layout(rgba32f) image2D flux_texture_center_out;
uniform layout(rgba32f) image2D flux_texture_bottom_out;

uniform float delta = 1.0 / 60.0;
uniform float gravity = 2;
uniform float viscosity = 1;

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
    // (1)
    float bed = data.w;
    float depth = data.x;
    vec2 velocity = data.yz;
    return bed + depth + (velocity.x * velocity.x + velocity.y + velocity.y) / (2 * gravity);
}

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture_in);

    // Load current cell data
    vec4 self_data = imageLoad(cell_texture_in, cell_position);
    float depth = self_data.x;
    vec2 velocity = self_data.yz;
    float elevation = self_data.w;

    // Load flux data
    vec4 flux_data_top = imageLoad(flux_texture_top_in, cell_position);
    vec4 flux_data_center = imageLoad(flux_texture_center_in, cell_position);
    vec4 flux_data_bottom = imageLoad(flux_texture_bottom_in, cell_position);

    // Calculate net flux
    float net_flux =
        -1 * flux_data_top.x + -1 * flux_data_top.y + 1 * flux_data_top.z +
        -1 * flux_data_center.x + 0 * flux_data_center.y + 1 * flux_data_center.z +
        -1* flux_data_bottom.x + 1 * flux_data_bottom.y + 1 * flux_data_bottom.z;

    // Update depth
    float new_depth = max(depth - delta * net_flux, 0);

    float pressure_gradient_x = elevation * gravity * (flux_data_center.z - flux_data_center.x);
    float pressure_gradient_y = elevation * gravity * (flux_data_top.y - flux_data_bottom.y);

    vec2 new_velocity = velocity + delta * vec2(pressure_gradient_x, pressure_gradient_y);
    imageStore(cell_texture_out, cell_position, vec4(new_depth, new_velocity, elevation));

    // update flux

    float self_head = bernoulli_hydraulic_head(self_data);
    float flux_results[9];
    for (int i = 0; i < N; ++i) {
        ivec2 other_position = cell_position + idirections[i];
        if (other_position.x < 0 || other_position.x >= size.x || other_position.y < 0 || other_position.y >= size.y) {
            flux_results[i] = 0.0;
            continue;
        }

        vec4 other_data = imageLoad(cell_texture_in, other_position);
        float other_head = bernoulli_hydraulic_head(other_data);
        float average_depth = (self_data.x + other_data.x) / 2.0; // average depth at cell edge

        float head_difference = self_head - other_head;
        float flux = gravity * head_difference * pow(average_depth, 5 / 3);

        flux_results[i] = flux;
    }

    imageStore(flux_texture_top_out, cell_position, vec4(
        flux_results[0],
        flux_results[1],
        flux_results[2],
        1
    ));

    imageStore(flux_texture_center_out, cell_position, vec4(
        flux_results[3],
        flux_results[4],
        flux_results[5],
        1
    ));

    imageStore(flux_texture_bottom_out, cell_position, vec4(
        flux_results[6],
        flux_results[7],
        flux_results[8],
        1
    ));

}