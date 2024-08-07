//#pragma language glsl4

#define PI 3.1415926535897932384626433832795

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ###

#ifdef VERTEX

uniform int instance_count;
varying vec3 color;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    int instance_id = love_InstanceID;
    int vertex_id = gl_VertexID;

    color = hsv_to_rgb(vec3(float(id) / float(instance_count), 1, 1));
    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec3 color;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    return vec4(color, 1);

/*
    vec2 vector = value.xy;
    float state = value.z / max_state;
    float age = value.w;

    float hue = (atan(vector.x, vector.y) + PI) / (2 * PI); // map angle to [0, 1]

    return vec4(hsv_to_rgb(as_hsv), state == 0 ? 0 : 1);
*/
}

#endif
