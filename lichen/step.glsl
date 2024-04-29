#pragma language glsl4

#define PI 3.1415926535897932384626433832795

// get angle between two vectors
float angle_between(vec2 v1, vec2 v2) {
    return (acos(clamp(dot(normalize(v1), normalize(v2)), -1.0, 1.0)) + PI) / (2 * PI);
}

// get angle of vector
float angle(vec2 v)
{
    return atan(v.x, v.y) + PI;
}

// translate by angle
vec2 translate_point_by_angle(vec2 xy, float distance, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * distance;
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

float random(vec2 v)
{
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
    return x;
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

    float kernel_sum =
        kernel[0][0] + kernel[1][0] + kernel[2][0] +
        kernel[0][1] + kernel[1][1] + kernel[1][2] +
        kernel[0][2] + kernel[1][2] + kernel[2][2]
    ;

    float n_neighbors = 0;
    float max_angle = -1. / 0.;
    float neighborhood_sum = 0;

    vec2 vector = vec2(0);
    for (int xx = x - 1; xx <= x + 1; xx++) {
        for (int yy = y - 1; yy <= y + 1; yy++) {
            //if (xx == x || yy == y) continue;

            vec4 current = imageLoad(image_in, ivec2(xx, yy));
            if (current.z > 0.97)
                n_neighbors++;

            for (int xxx = x-1; xxx <= x+1; xxx++) {
                for (int yyy = y - 1; yyy < y + 1; yyy++) {
                    vec4 other = imageLoad(image_in, ivec2(xxx, yyy));
                    max_angle = max(max_angle, angle_between(current.xy, other.xy) + PI);
                }
            }

            vec2 came_from = normalize(vec2(xx - x, yy - y));
            vector = current.z * (current.xy + came_from) / 2;
            vector = normalize(vector);

            neighborhood_sum = neighborhood_sum + current.z * kernel[xx - x + 1][yy - y + 1];
        }
    }

    neighborhood_sum = neighborhood_sum / kernel_sum;
    float rng_offset = random(vec2(x, y) + vec2(rng, -rng)) * 2;

    if (current.z <= 0 && n_neighbors > 1 * rng_offset && n_neighbors < 2 * rng_offset) {
        imageStore(image_out, ivec2(x, y), vec4(
            vector,
            1,
            0
        ));
    }
    else
    {
        imageStore(image_out, ivec2(x, y), vec4(
            vector,
            clamp(current.z - 0.01, 0, 1),//activation_function(neighborhood_sum) - 0.01,
            0
        ));
    }
}