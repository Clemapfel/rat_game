/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
                     dot(p, vec3(127.1, 311.7, 74.7)),
                     dot(p, vec3(269.5, 183.3, 246.1)),
                     dot(p, vec3(113.5, 271.9, 124.6)))
                 ) * 43758.5453123);
}

/// @brief gradient noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/gnoise.glsl
float gradient_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    return mix( mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
                          dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
                     mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
                          dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
                mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
                          dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
                     mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
                          dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

float noise(vec2 position, float offset) {
    float value = gradient_noise(vec3(position, offset));
    if (value > 0.7)
        return value * 2 - 1;
    else
        return value;
}

#ifndef TEXTURE_FORMAT
#define TEXTURE_FORMAT rg16f
#endif

layout(TEXTURE_FORMAT) uniform image2D texture_out;

uniform float a;
uniform float b;
uniform float perturbation;
uniform float scale = 10;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 image_size = imageSize(texture_out);
    ivec2 position = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    // Calculate the distance from the current fragment to the circle center
    float circle = smoothstep(0.3, 0.3 + 0.05, distance(position / image_size, vec2(0)));

    imageStore(texture_out, position, vec4(position.y / image_size.y));

    /*
    float rand_1 = noise(vec2(position.xy) / image_size * scale, 1);
    float rand_2 = smoothstep(-0.1, 0.1, distance(position / image_size, vec2(0))); //noise(vec2(position.xy) / image_size * scale, 10);
    imageStore(texture_out, position, vec4(
        (a + perturbation * rand_2),
        (b / a + perturbation * rand_2),
        0, 1
    ));
*/
}
