#define PI 3.1415926535897932384626433832795

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

vec3 random_3d(in vec3 p)
{
    return fract(sin(vec3(
             dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)))
     ) * 43758.5453123);
}


float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}


#ifdef VERTEX

attribute vec4 xyzw;

uniform int instance_count;
uniform float elapsed;

flat varying int instance_id;
flat varying float focus;

vec4 position(mat4 transform, vec4 vertex_position)
{
    instance_id = love_InstanceID;
    vec2 position = xyzw.xy * love_ScreenSize.xy;
    float radius = mix(0, 200, xyzw.z); //mix(100, 200, xyzw.z);
    focus = xyzw.w;

    //radius = gaussian(distance(focus, 0.5), 1) * 200;
    //focus = clamp(distance(xyzw.z, 0.5), 0, 1);

    // position
    vec2 center = position.xy;

    vertex_position.xy = translate_point_by_angle(center, radius, atan(vertex_position.y, vertex_position.x));

    return transform * vertex_position;
}
#endif

#ifdef PIXEL

uniform int mode;
uniform float focus_point;

flat varying float focus;
flat varying int instance_id;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float radius = 0.1;
    float border = clamp(focus * 0.15, 0, 1); // * (1 - gaussian(distance(focus, 0.5), 1)); //clamp(focus * random_3d(vec3(instance_id)).x, 0.1, 1);
    vec2 center = vec2(0.5, 0.5);
    vec2 pos = texture_coords;

    float value = 1 - smoothstep(radius - border, radius + border, distance(pos, center));
    float offset = random_3d(vec3(instance_id)).x;
    return vec4(vec4(value)) * (1 - offset * 0.2);
}

#endif
