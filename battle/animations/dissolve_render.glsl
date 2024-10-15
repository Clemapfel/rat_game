//#pragma language glsl3


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

uniform sampler2D position_texture;
uniform sampler2D color_texture;
uniform vec2 snapshot_size;
uniform float elapsed;
uniform vec3 red;

const float color_velocity = 5;

#ifdef VERTEX

varying vec4 vertex_color;
flat varying int instance_id;

vec4 position(mat4 transform, vec4 vertex_position)
{
    instance_id = love_InstanceID;

    vec2 texture_coordinates = vec2(instance_id / snapshot_size.x, mod(instance_id, snapshot_size.x));
    vec4 position_data = texelFetch(position_texture, ivec2(texture_coordinates), 0);
    vertex_position.xy += position_data.xy;

    vec4 color_data = texelFetch(color_texture, ivec2(texture_coordinates), 0);
    vertex_color = color_data;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 vertex_color;
flat varying int instance_id;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 screen_coords)
{
    vec2 texture_coordinates = vec2(instance_id / snapshot_size.x, mod(instance_id, snapshot_size.x));
    vec4 position_data = texelFetch(position_texture, ivec2(texture_coordinates), 0);
    vec2 distance_normalization = (snapshot_size / 20);
    float time = elapsed * distance(position_data.xy / distance_normalization, position_data.zw / distance_normalization) ;

    vec3 darkened_red = red - (random(vec2(instance_id)) / 2 + 1) * 0.4 - elapsed / 2;
    vec3 color = mix(vertex_color.rgb, darkened_red, clamp(time * color_velocity, 0, 1));
    return vec4(color, 1);
}
#endif