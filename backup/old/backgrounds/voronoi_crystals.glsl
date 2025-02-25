//#pragma language glsl4

#define PI 3.1415926535897932384626433832795

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


vec2 hash2( vec2 p )
{
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 voronoi( in vec2 x , float offset)
{
    // src: https://www.shadertoy.com/view/ldl3W8
    vec2 ip = floor(x);
    vec2 fp = fract(x);


    vec2 mg, mr;

    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = hash2( ip + g );
        o = 0.5 + 0.5 * sin( offset * o );
        vec2 r = g + o - fp;
        float d = dot(r,r);

        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }

    md = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        vec2 o = hash2( ip + g );
        o = 0.5 + 0.5*sin( offset * o );
        vec2 r = g + o - fp;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return vec3( md, mr );
}

float sine_wave(in float x) {
    return (sin(x * 2 * PI) + 1) / 2;
}

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

float smooth_min(float a, float b, float smoothness) {
    float h = max(smoothness - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / smoothness;
}


vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}


// ###

uniform float elapsed;

#ifdef PIXEL
vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 pos = texture_coords;
    pos = rotate(pos - vec2(0.5), -(1 / 8.) * elapsed);
    pos *= 10;

    float angle = mod(-1 * elapsed, 2 * PI);
    vec3 tiled = voronoi(pos, 10 * sine_wave(0.04 * elapsed) * 150 * distance(texture_coords, vec2(0.5)) * 0.4);

    const float max_value = 0.01;
    float value = cos(angle) * tiled.y + sin(angle) * tiled.z;
    value = mix(value, tiled.x, 0.6666);
    value = smoothstep(0, 0.5, value);
    return vec4(vec3(value), 1);
    return vec4(hsv_to_rgb(vec3(tiled.x, length(tiled.yz), 1)), 1);
}

#endif

