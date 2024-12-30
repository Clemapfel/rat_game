
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

uniform layout(rgba32f) image2D cell_texture_in;    // x: depth, yz: velocity, w: elevation
uniform layout(rgba32f) image2D flux_texture_top_in;
uniform layout(rgba32f) image2D flux_texture_center_in;
uniform layout(rgba32f) image2D flux_texture_bottom_in;

uniform layout(rgba32f) image2D cell_texture_out;
uniform layout(rgba32f) image2D flux_texture_top_out;
uniform layout(rgba32f) image2D flux_texture_center_out;
uniform layout(rgba32f) image2D flux_texture_bottom_out;

uniform float delta = 1.0 / 60.0;
uniform float gravity = 2;
uniform float viscosity = 1;
uniform float delta_multiplier = 4;

#define MODE_UPDATE_FLUX 1
#define MODE_UPDATE_DEPTH 2
uniform int mode;

// https://www.sciencedirect.com/science/article/pii/S0022169422010198?via%3Dihub

float bernoulli_hydraulic_head(vec4 data) {
    // (1)
    float bed = data.w;
    float depth = data.x;
    vec2 velocity = data.yz;
    return bed + depth + (velocity.x * velocity.x + velocity.y + velocity.y) / (2 * gravity);
}

float norm_dot(vec2 a, vec2 b) {
    return dot(normalize(a), normalize(b));
}

const float MIN_WATER_DEPTH = 0;
const float MAX_FLUX = 10;

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture_in);
    vec4 self_data = imageLoad(cell_texture_in, cell_position);
    vec4 flux_data_top = imageLoad(flux_texture_top_in, cell_position);
    vec4 flux_data_center = imageLoad(flux_texture_center_in, cell_position);
    vec4 flux_data_bottom = imageLoad(flux_texture_bottom_in, cell_position);

    if (mode == MODE_UPDATE_FLUX) {
        float self_head = bernoulli_hydraulic_head(self_data);
        float flux_results[9];
        for (int i = 0; i < N; ++i) {
            if (i == 4) continue; // skip center

            ivec2 other_position = cell_position + idirections[i];
            if (other_position.x < 0 || other_position.x >= size.x || other_position.y < 0 || other_position.y >= size.y) {
                flux_results[i] = 0.0;
                continue;
            }

            vec4 other_data = imageLoad(cell_texture_in, other_position);
            float other_head = bernoulli_hydraulic_head(other_data);
            float average_depth = (self_data.x + other_data.x) / 2.0; // average depth at cell edge

            float head_difference = self_head - other_head;
            float flux = -1 * 1 / viscosity * gravity * average_depth * head_difference * (1 - dot(self_data.yz, other_data.yz));

            flux_results[i] = min(flux, MAX_FLUX);
        }

        imageStore(flux_texture_top_out, cell_position, vec4(
            flux_results[0],
            flux_results[1],
            flux_results[2],
            1
        ));

        imageStore(flux_texture_center_out, cell_position, vec4(
            flux_results[3],
            0, // flux on self is always 0
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
    else if (mode == MODE_UPDATE_DEPTH) {
        float fluxes[N] = float[](
            flux_data_top.x, flux_data_top.y, flux_data_top.z,
            flux_data_center.x, flux_data_center.y, flux_data_center.z,
            flux_data_bottom.x, flux_data_bottom.y, flux_data_bottom.z
        );

        float flux_sum = 0.0;
        vec2 velocity_sum = vec2(0);
        vec2 old_velocity = self_data.yz;
        for (int i = 0; i < N; ++i) {
            flux_sum += fluxes[i];
            velocity_sum += old_velocity * fluxes[i] * directions[i];
        }

        if (cell_position.x == 0 || cell_position.x == size.x - 1) {
            velocity_sum.x *= -1;
        }
        if (cell_position.y == 0 || cell_position.y == size.y - 1) {
            velocity_sum.y *= -1;
        }


        float new_depth = self_data.x + flux_sum * delta * delta_multiplier;
        new_depth = max(new_depth, MIN_WATER_DEPTH);


        velocity_sum /= N;
        imageStore(cell_texture_out, cell_position, vec4(new_depth, velocity_sum, self_data.w));
    }
}