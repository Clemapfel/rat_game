
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

uniform layout(rgba32f) image2D cell_texture_in;
uniform layout(rgba32f) image2D flux_texture_top_in;
uniform layout(rgba32f) image2D flux_texture_center_in;
uniform layout(rgba32f) image2D flux_texture_bottom_in;

uniform layout(rgba32f) image2D cell_texture_out;
uniform layout(rgba32f) image2D flux_texture_top_out;
uniform layout(rgba32f) image2D flux_texture_center_out;
uniform layout(rgba32f) image2D flux_texture_bottom_out;

uniform float delta = 1.0 / 60.0;
uniform float gravity = 1;
uniform float viscosity = 1;

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

const float MIN_WATER_DEPTH = 0;
const float cell_length = 1;

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);
    vec4 self_data = imageLoad(cell_texture_in, cell_position);
    vec4 flux_data_top = imageLoad(flux_texture_top_in, cell_position);
    vec4 flux_data_center = imageLoad(flux_texture_center_in, cell_position);
    vec4 flux_data_bottom = imageLoad(flux_texture_bottom_in, cell_position);

    if (mode == MODE_UPDATE_FLUX) {

        float self_head = bernoulli_hydraulic_head(self_data);
        float flux_results[9];
        for (int i = 0; i < N; ++i) {
            if (i == 4) continue; // skip center

            vec4 other_data = imageLoad(cell_texture_in, cell_position + idirections[i]);
            float other_head = bernoulli_hydraulic_head(other_data);
            float average_depth = (self_data.x + other_data.x) / (2 * length(directions[i])); // average depth at cell edge

            float mann_flux = 1 / viscosity * pow(average_depth, 5 / 3) * sqrt(self_head - other_head);

            float h0 = self_head - max(self_data.w, other_data.w);
            float hi = other_head - max(self_data.w, other_data.w);
            float psi = pow(1 - pow(hi / h0, 1.5), 0.385);
            float weir_flux = 2 / 3 * sqrt(2 * gravity) * pow(psi, 3 / 2);

            flux_results[i] = max(mann_flux, weir_flux);
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

        float flux_sum = 0;
        for (int i = 0; i < N; ++i) {
            flux_sum += fluxes[i];
        }

        float new_depth = self_data.x - delta * flux_sum;
        imageStore(cell_texture_out, cell_position, vec4(new_depth, self_data.yzw));
    }

    /*
    if (mode == MODE_UPDATE_FLUX) {
        if (cell_data.x <= MIN_WATER_DEPTH) return;

        float self_head = bernoulli_hydraulic_head(cell_data);
        if (cell_data.x > MIN_WATER_DEPTH)
            return;

        float [4] self_flux = float[](
            flux_data.x,
            flux_data.y,
            flux_data.z,
            flux_data.w
        );

        float results[N] = float[](1, 1, 1, 1);
        for (int i = 0; i < N; ++i) {
            ivec2 neighbor_position = cell_position + idirections[i];
            vec4 neighbor_cell_data = imageLoad(cell_texture_in, neighbor_position);

            float neighbor_head = bernoulli_hydraulic_head(neighbor_cell_data);
            if (!(
                self_head >= neighbor_head && // self higher than other
                self_flux[i] >= 0 // flux outward
            )) {
                continue;
            }

            // (4)
            float edge_depth = mix(cell_data.x, neighbor_cell_data.x, 0.5);
            float head_delta = (self_head - neighbor_head) / cell_length;
            float mann_flux = 1 / viscosity * pow(edge_depth, -5 / 3) * sqrt(head_delta);

            // (5)
            float z_bar = max(cell_data.w, neighbor_cell_data.w);
            float h0 = self_head - z_bar;
            float hi = max(0, neighbor_head - z_bar);
            float phi = pow(1 - pow((hi / h0), 1.5), 0.385);// (6)
            float weir_flux = 2 / 3 * cell_length * sqrt(2 * gravity) * phi * pow(h0, 3/2);

            results[i] = min(mann_flux, weir_flux);
        }

        imageStore(flux_texture_out, cell_position, vec4(results[0], results[1], results[2], results[3]));
        return;
    }
    else if (mode == MODE_UPDATE_DEPTH) {

        cell_data.x += delta / (cell_length * cell_length) * (
             1 * flux_data.x +
            -1 * flux_data.y +
            -1 * flux_data.z +
             1 * flux_data.w
        ); // (7)

        cell_data.x = max(cell_data.x, 0);
        imageStore(cell_texture_out, cell_position, cell_data);
    }
    */
}