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

mat2 rotate(in float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

const mat3 m3 = mat3(0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339) * 2;

float magnitude_squared(vec2 p) {
    return length(p) * length(p);
}

float linstep(in float mn, in float mx, in float x){
    return clamp((x - mn) / (mx - mn), 0., 1.);
}

float prm1 = 0.;

vec2 displace(float t){
    return vec2(sin(t), cos(t)) ;
}

vec2 map(vec3 p)
{
    vec3 p2 = p;
    p2.xy -= displace(p.z).xy;
    p.xy *= rotate(sin(p.z+elapsed)*(0.1 + prm1*0.05) + elapsed*0.09);
    float cl = magnitude_squared(p2.xy);
    float d = 0.;
    p *= .61;
    float z = 1.;
    float trk = 1.;
    float dspAmp = 0.1 + prm1*0.2;
    for(int i = 0; i < 5; i++)
    {
        p += sin(p.zxy*0.75*trk + elapsed*trk*.8)*dspAmp;
        d -= abs(dot(cos(p), sin(p.yzx))*z);
        z *= 0.57;
        trk *= 1.4;
        p = p*m3;
    }
    d = abs(d + prm1*3.)+ prm1*.3 - 2.5;
    return vec2(d + cl*.2 + 0.25, cl);
}

#define STEPS 100
vec4 render(in vec3 rd)
{
    vec4 result = vec4(0); // accumulated color
    float t = 0; // distance from start
    float fog_transparency = 0.;
    for (int i = 0; i < STEPS; i++)
    {
        if (result.a > 0.99) break;

        vec3 pos = t * rd;
        vec2 mpv = map(pos);
        float den = clamp(mpv.x-0.3,0.,1.)*1.12;
        float dn = clamp((mpv.x + 2.),0.,3.);

        vec4 col = vec4(0);
        if (mpv.x > 0.6)
        {
            col = vec4(sin(vec3(5.,0.4,0.2) + mpv.y*0.1 +sin(pos.z*0.4)*0.5 + 1.8)*0.5 + 0.5,0.08);
            col *= den*den*den;
            col.rgb *= linstep(4.,-2.5, mpv.x)*2.3;
            float dif = clamp((den - map(pos+.8).x)/9., 0.001, 1. );
            dif += clamp((den - map(pos+.35).x)/2.5, 0.001, 1. );
            col.xyz *= den*(vec3(0.005,.045,.075) + 1.5*vec3(0.033,0.07,0.03)*dif);
        }

        float fog_color = exp(t*0.2 - 2.2);
        col.rgba += vec4(0.11, 0.11, 0.11, 0.11) * clamp(fog_color - fog_transparency, 0., 1.);
        fog_transparency = fog_color;
        result = result + col*(1. - result.a);
        t += clamp(0.5 - dn*dn*.05, 0.09, 0.3);
    }
    return clamp(result, 0.0, 1.0);
}

#define PI 3.14159

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 q = vertex_position.xy / love_ScreenSize.xy;
    vec2 p = (gl_FragCoord.xy - 0.5 * love_ScreenSize.xy) / love_ScreenSize.y;

    float time = elapsed*3.;
    float target_distance = 100;

    vec3 target = normalize(vec3(displace(target_distance) * 0.5, target_distance));
    vec3 rightdir = vec3(1, 0, 0);
    vec3 updir = vec3(0, 1, 0);

    vec3 rd = normalize((p.x * rightdir + p.y * updir) * 1. - target);
    prm1 = 0.4; // bulbousness of clouds

    return vec4(render(rd).rgb, 1.0);
}