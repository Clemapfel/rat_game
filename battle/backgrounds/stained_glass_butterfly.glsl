#define PI 3.1415926535897932384626433832795

/// @brief voronoi noise
/// @param blur in [0, 1]
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/voronoise.glsl
float voronoise(vec3 p, float blur) {
    blur = clamp(blur, 0, 1);
    float u = 0.55;
    float k = 1.0 + 63.0 * pow(1.0 - blur, 6.0);
    vec3 i = floor(p);
    vec3 f = fract(p);

    float s = 1.0 + 31.0 * blur;
    vec2 a = vec2(0.0, 0.0);

    vec3 g = vec3(-2.0);
    for (g.z = -2.0; g.z <= 2.0; g.z++)
    for (g.y = -2.0; g.y <= 2.0; g.y++)
    for (g.x = -2.0; g.x <= 2.0; g.x++) {
        vec3 v = i + g;
        v = fract(v * vec3(.1031, .1030, .0973));
        v += dot(v, v.yxz + 19.19);
        vec3 o = fract((v.xxy + v.yzz) * v.zyx) * vec3(u, u, 1.);
        vec3 d = g - f + o + 0.5;
        float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
        a += vec2(o.z * w, w);
    }
    return a.x / a.y;
}


/// @brief worley noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/worley.glsl
float worley_noise(vec3 p) {
    vec3 n = floor(p);
    vec3 f = fract(p);

    float dist = 1.0;
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 g = vec3(i, j, k);

                vec3 p = n + g;
                p = fract(p * vec3(0.1031, 0.1030, 0.0973));
                p += dot(p, p.yxz + 19.19);
                vec3 o = fract((p.xxy + p.yzz) * p.zyx);

                vec3 delta = g + o - f;
                float d = length(delta);
                dist = min(dist, d);
            }
        }
    }

    return 1 - dist;
}


vec2 hash2( vec2 p )
{
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 voronoi( in vec2 x, in float offset )
{
    // source: https://www.shadertoy.com/view/ldl3W8

    vec2 ip = floor(x);
    vec2 fp = fract(x);

    vec2 mg, mr;

    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = hash2( ip + g );
        o = 0.5 + 0.5*sin( offset + 6.2831*o );
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
        o = 0.5 + 0.5*sin( offset + 6.2831*o );
        vec2 r = g + o - fp;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return vec3( md, mr );
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 pos = texture_coords.xy;
    pos.y *= love_ScreenSize.y / love_ScreenSize.x;

    vec3 tiled = voronoi(pos.xy * 10, elapsed / 10);
    float outline = smoothstep(0, 0.12, tiled.x);
    vec3 color = hsv_to_rgb(vec3(length(tiled.yz), 1, 1));
    return vec4(color, 1);
}

#endif
