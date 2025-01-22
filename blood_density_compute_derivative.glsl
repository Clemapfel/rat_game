//
// compute directional derivative of x and write to yz components
//

layout(rgba32f) uniform image2D density_texture;

const mat3 sobel_x = mat3(
    -1.0,  0.0,  1.0,
    -2.0,  0.0,  2.0,
    -1.0,  0.0,  1.0
);
const mat3 sobel_y = mat3(
    -1.0, -2.0, -1.0,
    0.0,  0.0,  0.0,
    1.0,  2.0,  1.0
);

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {

    ivec2 texture_coords = ivec2(gl_GlobalInvocationID.xy);
    ivec2 texture_size = imageSize(density_texture);

    if (texture_coords.x >= texture_size.x || texture_coords.y >= texture_size.y)
        return;

    float x_gradient = 0.0;
    float y_gradient = 0.0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            ivec2 position = texture_coords + ivec2(i, j);
            if (position.x < 0 || position.x >= texture_size.x || position.y < 0 || position.y >= texture_size.y)
            continue;

            float value = imageLoad(density_texture, position).r;

            x_gradient += value * sobel_x[j + 1][i + 1];
            y_gradient += value * sobel_y[j + 1][i + 1];
        }
    }

    vec4 current = imageLoad(density_texture, texture_coords);
    imageStore(density_texture, texture_coords, vec4(
        current.x,
        x_gradient,
        y_gradient,
        1
    ));
}