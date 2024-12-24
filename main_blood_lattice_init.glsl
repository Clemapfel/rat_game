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

float sdf_ring(vec2 p, float outerRadius, float innerRadius) {
    float distToOuter = length(p) - outerRadius;
    float distToInner = length(p) - innerRadius;
    return max(distToInner, -distToOuter);
}

uniform layout(rgba32f) image2D cell_texture;

#define INIT_DISTANCE 1
#define INIT_GRADIENT 2
#define INIT_HITBOX 3

uniform int mode = INIT_DISTANCE;

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    vec2 size = imageSize(cell_texture);
    vec2 position = vec2(gl_GlobalInvocationID.xy);

    if (mode == INIT_DISTANCE) {
        float dist = distance(position, 0.5 * size) / min(size.x, size.y);
        dist = clamp(10 * gaussian(dist, 2), 0, 1);
        dist *= snoise(position / size * 1.5);

        vec4 current = imageLoad(cell_texture, ivec2(position.x, position.y));
        imageStore(cell_texture, ivec2(position.x, position.y), vec4(
            dist, current.yz, current.w
        ));
    }
    else if (mode == INIT_GRADIENT) {
        vec2 size = imageSize(cell_texture);
        ivec2 pos = ivec2(position);

        mat3 sobel_x = mat3(
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        );

        mat3 sobel_y = mat3(
            -1, -2, -1,
            0,  0,  0,
            1,  2,  1
        );

        float gradient_x = 0.0;
        float gradient_y = 0.0;

        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                ivec2 neighbor_pos = pos + ivec2(i, j);
                vec4 neighborColor = imageLoad(cell_texture, neighbor_pos);
                float value = neighborColor.r;

                int kernel_i = i + 1;
                int kernel_j = j + 1;

                gradient_x += value * sobel_x[kernel_i][kernel_j];
                gradient_y += value * sobel_y[kernel_i][kernel_j];
            }
        }

        vec2 gradient = normalize(vec2(gradient_x, gradient_y));

        vec4 current = imageLoad(cell_texture, ivec2(position.x, position.y));

        // perturb lowe rareas
        const float cutoff = 0.6;
        if (current.x < cutoff) {
            float noise = snoise(position / size * 20) * 2 * PI / 4;
            float c = cos(noise);
            float s = sin(noise);
            vec2 perturbed_gradient = vec2(
                gradient.x * c - gradient.y * s,
                gradient.x * s + gradient.y * c
            );
            gradient = mix(gradient, perturbed_gradient, current.x * cutoff);
        }

        imageStore(cell_texture, ivec2(position.x, position.y), vec4(
            current.x, gradient.xy, current.w
        ));
    }
    else if (mode == INIT_HITBOX) {

        vec4 current = imageLoad(cell_texture, ivec2(position.x, position.y));

        const float scale = 2.3;
        vec2 top_left = vec2(1) * vec2(snoise(vec2(-100) + position / size * scale), snoise(vec2(100) + position / size * scale));
        vec2 bottom_right = top_left + vec2(0.5, 0.5);

        float hitbox = 0;
        vec2 xy = position / size;
        const float edgeThickness = 0.03;
        float smoothX = smoothstep(top_left.x, top_left.x + edgeThickness, xy.x) * (1.0 - smoothstep(bottom_right.x - edgeThickness, bottom_right.x, xy.x));
        float smoothY = smoothstep(top_left.y, top_left.y + edgeThickness, xy.y) * (1.0 - smoothstep(bottom_right.y - edgeThickness, bottom_right.y, xy.y));
        hitbox = smoothX * smoothY;

        imageStore(cell_texture, ivec2(position.x, position.y), vec4(current.xyz, hitbox));
    }
}