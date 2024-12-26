uniform layout(rgba32f) image2D cell_texture_in;    // r: density, gb: velocity, z: unused
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

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture_in);
    vec4 self = imageLoad(cell_texture_in, position);
    const float viscosity = 0.5; // % outflow per second

    float total_outflow = 0.0;
    float total_inflow = 0.0;

    for (int i = 1; i < 9; ++i) {
        ivec2 neighbor_pos = position + ivec2(directions[i]);

        // Apply periodic boundary conditions
        neighbor_pos.x = (neighbor_pos.x + int(size.x)) % int(size.x);
        neighbor_pos.y = (neighbor_pos.y + int(size.y)) % int(size.y);

        vec4 neighbor = imageLoad(cell_texture_in, neighbor_pos);
        float gradient = self.r - neighbor.r;

        // Calculate outflow based on gradient and viscosity
        float outflow = max(0.0, gradient);
        total_outflow += outflow;

        // Calculate inflow from the neighbor
        float inflow = max(0.0, -gradient);
        total_inflow += inflow;
    }

    // Update the current cell's density
    float new_density = self.r + total_inflow - total_outflow;
    imageStore(cell_texture_out, position, vec4(new_density, self.g, self.b, self.a));
}