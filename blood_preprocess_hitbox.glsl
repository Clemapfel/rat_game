layout(r8) uniform readonly image2D input_texture; // x: is wall
layout(r8) uniform writeonly image2D output_texture; // x: is wall

const float infinity = 1 / 0.f;
uniform float threshold = 0;
uniform float particle_radius;

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in; // dispatch with texture_width / 16, texture_height / 16
void computemain() {
    ivec2 tex_size = imageSize(input_texture);
    ivec2 tex_coord = ivec2(gl_GlobalInvocationID.xy);

    float max_value = 0.0;
    float radius = particle_radius * particle_radius;

    for (int y = -int(floor(particle_radius)); y <= int(ceil(particle_radius)); ++y) {
        for (int x = -int(floor(particle_radius)); x <= int(ceil(particle_radius)); ++x) {
            if (float(x * x + y * y) <= radius) {
                ivec2 neighbor_coord = tex_coord + ivec2(x, y);

                if (neighbor_coord.x >= 0 && neighbor_coord.x < tex_size.x && neighbor_coord.y >= 0 && neighbor_coord.y < tex_size.y) {
                    float value = imageLoad(input_texture, neighbor_coord).r;
                    max_value = max(max_value, value);
                }
            }
        }
    }

    imageStore(output_texture, tex_coord, vec4(max_value));
}