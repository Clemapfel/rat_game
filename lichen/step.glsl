#pragma language glsl4

#define PI 3.1415926535897932384626433832795

// get angle between two vectors
float angle_between(vec2 v1, vec2 v2) {
    return (acos(clamp(dot(normalize(v1), normalize(v2)), -1.0, 1.0)) + PI) / (2 * PI);
}

// get angle of vector
float angle(vec2 v)
{
    return (atan(v.x, v.y) + PI) / (2 * PI);
}

// rotate vector
vec2 rotate(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * v;
}

// random
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float random(vec2 v, float offset)
{
    v.x += offset;
    v.y += offset;

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

// ###

layout(rgba16f) uniform image2D image_in;
layout(rgba16f) uniform image2D image_out;

uniform mat3x3 kernel;
uniform float rng;

float activation_function(float x)
{
    //return tanh(3 * (x - 0.5));
    return 2 * (x - 0.5);
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 image_size = imageSize(image_in);
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    int width = image_size.x;
    int height = image_size.y;

    float activation_threshold = 0.00;

    vec4 current = imageLoad(image_in, ivec2(x, y));
    float current_angle = angle(current.xy);

    float neighborhood_sum = 0;
    int n_active_neighbors = 0;

    float kernel_sum =
        kernel[0][0] + kernel[1][0] + kernel[2][0] +
        kernel[0][1] + kernel[1][1] + kernel[1][2] +
        kernel[0][2] + kernel[1][2] + kernel[2][2]
    ;

    for (int ix = -1; ix <= +1; ix++) {
        for (int iy = -1; iy <= +1; iy++) {
            float value = imageLoad(image_in, ivec2(x + ix, y + iy)).z;
            if (value > 0) {
                n_active_neighbors = n_active_neighbors + 1;
            }
            neighborhood_sum += value * kernel[ix + 1][iy + 1];
        }
    }

    neighborhood_sum = neighborhood_sum / kernel_sum;

    float offset = activation_function(rng);
    if (offset * neighborhood_sum * (1 / n_active_neighbors) > 0)
        neighborhood_sum += offset;


    imageStore(image_out, ivec2(x, y), vec4(current.xy, clamp(neighborhood_sum, 0, 1), 0));
}