
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

float project(float value, float lower, float upper) {
    return value * abs(upper - lower) + min(lower, upper);
}

#ifdef PIXEL

uniform float radius;
uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 10;

    float aspect_factor = love_ScreenSize.x / love_ScreenSize.y;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos.x *= aspect_factor;

    float n_rows = 100;
    float radius = 1 / n_rows;
    float grid_size = radius * 2;

    int x_i = int(floor(pos.x / grid_size));
    int y_i = int(floor(pos.y / grid_size));

    vec2 center = vec2(float(x_i) * grid_size + radius, float(y_i) * grid_size + radius);
    float rng = random(vec2(x_i / grid_size, y_i / grid_size) + vec2(time, -time));
    radius = clamp(project(rng, 0.7 * radius, radius), 0, radius);

    float border = 0.005;
    float dist = radius - distance(pos, center);

    float value = 0.0;
    if (dist > border)
        value = 1.0;
    else if (dist > 0.0)
        value = dist / border;  // draw with feathered edge

    value = value * 0.2;
    return vec4(vec3(value), 1);
}

#endif
