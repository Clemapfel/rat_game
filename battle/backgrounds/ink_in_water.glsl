#define PI 3.1415926535897932384626433832795

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 uv = vertex_position / love_ScreenSize.xy;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float time = elapsed;

    float freq = cos(time *.05)/1.825;
    for(float i=1.;i<75.;i++)  {
        uv.x += freq/i*cos(i*uv.y+ time) +0.494*i;
        uv.y += freq/i*sin(i*uv.x+ time) -0.458*i;
    }

    float bias = abs(sin(uv.y/0.5));
    vec3 col_a = vec3(1.5, .06, .09);
    vec3 col_b = vec3(.5, 2., 2.4);
    vec3 col   = ((col_a*col_a)*bias+(col_b*col_b)*(1.-bias))/2.;

    return vec4(sqrt(col), 1.0);
}

#endif
