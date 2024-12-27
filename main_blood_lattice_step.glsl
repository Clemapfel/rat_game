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
void computemain() {
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture_in);
    vec4 self = imageLoad(cell_texture_in, position);
    const float viscosity = 30; // % outflow per second

    float total_outflow = 0.0;
    float total_inflow = 0.0;
    vec2 new_velocity = self.yz;

    float density_average = self.x;

    for (int i = 1; i < 9; ++i) {
        ivec2 neighbor_pos = position + ivec2(directions[i]);
        #ifdef BOUNDARY_CONDITIONS_REPEAT
            neighbor_pos.x = (neighbor_pos.x + int(size.x)) % int(size.x);
            neighbor_pos.y = (neighbor_pos.y + int(size.y)) % int(size.y);
        #else
            if (neighbor_pos.x < 0 || neighbor_pos.y < 0 || neighbor_pos.x >= size.x || neighbor_pos.y >= size.y)
                continue;
        #endif

        vec4 neighbor = imageLoad(cell_texture_in, neighbor_pos);
        float gradient = (self.x - neighbor.x);

        if (gradient > 0) {
            float alignment = norm_dot(directions[i], self.yz);
            float outflow = gradient * viscosity * delta * self.x * alignment;
            total_outflow += outflow;
            new_velocity += neighbor.yz * outflow;
        }
        else if (gradient < 0) {
            float alignment = 1 - norm_dot(directions[i], self.yz);
            float inflow = -gradient * viscosity * delta * neighbor.x * alignment;
            total_inflow += inflow;
            new_velocity -= neighbor.yz * inflow;
        }

        density_average += neighbor.x;
    }

    float new_density = self.x + total_inflow - total_outflow;

    // move towards average for mixing
    density_average /= 10;
    //new_density += (density_average - new_density) * viscosity * delta * delta;

    imageStore(cell_texture_out, position, vec4(max(new_density, 0), new_velocity, self.w));
}