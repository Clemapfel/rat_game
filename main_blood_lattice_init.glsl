// Simplex noise implementation
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
    0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);

    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

#define PI 3.1415926535897932384626433832795
float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

#define MODE_INIT_DEPTH 1
#define MODE_INIT_VELOCITIES 2

uniform layout(rgba32f) image2D cell_texture; // r:depth, g:x-velocity, b:y-velocity, a:elevation
uniform layout(rgba32f) image2D flux_texture; // r:top g:right, b:bottom, a:left
uniform int mode;

uniform float delta = 1.0 / 60.0;
uniform float gravity = 1;
uniform float viscosity = 1;

float bernoulli_hydraulic_head(vec4 data) {
    // (1)
    float bed = data.w;
    float depth = data.x;
    vec2 velocity = data.yz;
    return bed + depth + (velocity.x * velocity.x + velocity.y + velocity.y) / (2 * gravity);
}


layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    vec2 size = imageSize(cell_texture);
    vec2 position = vec2(gl_GlobalInvocationID.xy);
    ivec2 cell_position = ivec2(gl_GlobalInvocationID.xy);

    const float wall = 0.01;
    if (cell_position.x <= wall * size.x || cell_position.x >= (1 - wall) * size.x || cell_position.y <= wall * size.x || cell_position.y >= (1 - wall) * size.y)
    {
        imageStore(cell_texture, cell_position, vec4(0, 0, 0, 999));
        imageStore(flux_texture, cell_position, vec4(0, 0, 0, 0));
        return;
    }

    if (mode == MODE_INIT_DEPTH) {
        position /= imageSize(cell_texture);
        float depth = gaussian(distance(position, vec2(0.5)), 2.75);;
        depth *= snoise(position * 2 + vec2(2));
        imageStore(cell_texture, cell_position, vec4(depth, 0, 0, 0));
    }
    else if (mode == MODE_INIT_VELOCITIES) {
        const mat3 sobel_x = mat3(
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        );

        const mat3 sobel_y = mat3(
            -1, -2, -1,
            0,  0,  0,
            1,  2,  1
        );

        float gradient_x = 0.0;
        float gradient_y = 0.0;

        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                ivec2 neighbor_pos = ivec2(position.x, position.y) + ivec2(i, j);
                vec4 neighbor_color = imageLoad(cell_texture, neighbor_pos);
                float value = neighbor_color.r;

                int kernel_i = i + 1;
                int kernel_j = j + 1;

                gradient_x += value * sobel_x[kernel_i][kernel_j];
                gradient_y += value * sobel_y[kernel_i][kernel_j];
            }
        }

        vec4 current = imageLoad(cell_texture, cell_position);
        imageStore(cell_texture, cell_position, vec4(current.r, gradient_x, gradient_y, current.a));

        const float scale = 0.01;

        float self_head = bernoulli_hydraulic_head(imageLoad(cell_texture, cell_position + ivec2(0, 0)));
        float up_head = bernoulli_hydraulic_head(imageLoad(cell_texture, cell_position + ivec2(0, -1)));
        float right_head = bernoulli_hydraulic_head(imageLoad(cell_texture, cell_position + ivec2(1, 0)));
        float bottom_head = bernoulli_hydraulic_head(imageLoad(cell_texture, cell_position + ivec2(0, 1)));
        float left_head = bernoulli_hydraulic_head(imageLoad(cell_texture, cell_position + ivec2(-1, 0)));

        imageStore(flux_texture, cell_position, vec4(
            self_head - up_head,
            self_head - right_head,
            self_head - bottom_head,
            self_head - left_head
        ));
    }
}