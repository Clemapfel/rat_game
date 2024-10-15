//#pragma language glsl4

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

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

layout(rgba16f) uniform image2D position_texture;
layout(rgba8) uniform image2D color_texture;

const float PI = 3.14159265359;

uniform vec4 aabb;
uniform sampler2D snapshot;
uniform vec2 snapshot_size;
uniform float pixel_size;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    vec2 position = gl_GlobalInvocationID.xy;
    vec2 texture_coords = position / snapshot_size * pixel_size;
    vec4 color = texture(snapshot, texture_coords);
    imageStore(color_texture, ivec2(position.x, position.y), color);

    float x = aabb.x;
    float y = aabb.y;
    float width = aabb.z;
    float height = aabb.w;
    vec2 center = aabb.xy + 0.5 * aabb.zw;

    vec2 current = vec2(x, y) + texture_coords * vec2(width, height);

    float direction = sign(current.y - center.y);
    vec2 diff = current - center;

    vec2 previous = translate_point_by_angle(current, 1 + abs(random(gl_GlobalInvocationID.xy) * 10), -PI * 1.5 + random(gl_GlobalInvocationID.xy) * PI / 12);
    previous.x = previous.x + 2;

    if (abs(diff.y + 0.1 * height) < height * 0.05)
        previous.x = previous.x + 20;

    imageStore(position_texture, ivec2(position.x, position.y), vec4(current, previous));
}