// Protean clouds by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/3l23Rh
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	Technical details:

	The main volume noise is generated from a deformed periodic grid, which can produce
	a large range of noise-like patterns at very cheap evalutation cost. Allowing for multiple
	fetches of volume gradient computation for improved lighting.

	To further accelerate marching, since the volume is smooth, more than half the the density
	information isn't used to rendering or shading but only as an underlying volume	distance to 
	determine dynamic step size, by carefully selecting an equation	(polynomial for speed) to 
	step as a function of overall density (not necessarily rendered) the visual results can be 
	the	same as a naive implementation with ~40% increase in rendering performance.

	Since the dynamic marching step size is even less uniform due to steps not being rendered at all
	the fog is evaluated as the difference of the fog integral at each rendered step.

*/

uniform float elapsed;

float linstep(in float mn, in float mx, in float x){
    return (x - mn) / (mx - mn);
}

float project(float value, float lower, float upper) {
    return value * abs(upper - lower) + min(lower, upper);
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

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

#define FBM_N_STEPS 2
vec2 map(vec3 p, float spikyness)
{
    const mat3 m3 = mat3(
         0.33338, 0.56034, -0.71817,
        -0.87887, 0.32651, -0.15323,
         0.15162, 0.69596,  0.61339
    ) * 2.5;
    float prm1 = spikyness + 0.5;
    float cl = length(p.xy) * length(p.xy);
    float d = 0.;
    float z = 1;
    float trk = 1.;
    for(int i = 0; i < FBM_N_STEPS; i++)
    {
        p += sin(p.zxy * 0.75 * trk + elapsed * trk * .8) * 0.001;
        d -= abs(dot(cos(p), sin(p.yzx)) * (z));
        z *= 0.56;
        trk *= 1.4;
        p = p * m3;
    }
    d = abs(d + prm1 * 3.) + prm1 / 3 - 2.5;
    return vec2(d + cl * .2 + 0.25, cl);
}

#define STEPS 100
#define STEP_SIZE 0.1
/// @param spikyness in [-1, 1]
vec4 render(in vec3 ray_direction, float spikyness, float time)
{
    vec4 result = vec4(0); // accumulated color

    float t = 0;
    float fog_transparency = 0.;

    for (int i = 0; i < STEPS; i++)
    {
        if (result.a > 0.99) break;

        vec3 pos = vec3(0, 0, -time) + t * ray_direction;
        vec2 mpv = map(pos, spikyness);
        float density = clamp(mpv.x - 0.3, 0., 1.) * 1.12;

        vec4 col = vec4(0);
        if (mpv.x > 0.6)
        {
            col = vec4(sin(vec3(5., 0.4, 0.2) + mpv.y * 0.1 + sin(pos.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5, 0.08);
            col *= density * density * density;
            col.rgb *= clamp(linstep(4., -2.5, mpv.x), 0, 1) * 2.3;
            col.rgb *= density * (vec3(0.045, 0.045, 0.045));
        }

        float fog_color = (t - 4);
        col.rgba += clamp(fog_color - fog_transparency, 0., 1.) * 0.01;
        fog_transparency = fog_color;
        result = result + col * (1. - result.a);
        t += STEP_SIZE;
    }

    result.xyz = vec3(max(max(result.x, result.y), max(result.y, result.z)));
    return clamp(result, 0.0, 1.0);
}

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 position = (vertex_position.xy - 0.5 * love_ScreenSize.xy) / love_ScreenSize.y;

    position *= 1.5;

    float time = elapsed / 50;
    vec3 ray_direction = (position.x * vec3(1, 0, 0) + position.y * vec3(0, 1, 0)) - vec3(0, 0, 1);
    ray_direction = normalize(ray_direction);

    ray_direction.xy = rotate(ray_direction.xy, time / 3);
    return vec4(max(render(ray_direction, sin(time) * 0.5, elapsed / 5).rgb, vec3(0)), 1.0);
}