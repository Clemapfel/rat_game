float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

vec2 rotate_point(vec2 point, vec2 pivot, float angle_dg)
{
    float angle = angle_dg * (3.14159 / 180.0);

    float s = sin(angle);
    float c = cos(angle);

    // translate point back to origin:
    point -= pivot;

    // rotate point
    point.x = point.x * c - point.y * s;
    point.y = point.x * s + point.y * c;

    // translate point back:
    point += pivot;

    return point;
}

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

// random
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


float get_angle(vec2 a, vec2 b)
{
    float dy = b.y - a.y;
    float dx = b.x - a.x;

    float theta = atan(dy, dx);
    return theta;
}

float symmetrical_mod(float x)
{
    x = (2.0 * mod(x, 1.0)) - 1.0;
    if (x > 0.0)
      return mod(x, 1.0);
    else
      return mod(1.0 - x, 1.0);
}

uniform float _time;

#define mint vec3(30.0 / 255.0, 255.0 / 255.0, 146.0 / 255.0)
#define pink vec3(1.0, 10.0 / 255.0, 243.0 / 255.0)

vec4 effect(vec4 _vertex_color, Image texture_in, vec2 texture_coords_in, vec2 _vertex_pos)
{
    float time = _time / 15.0;

    vec2 _screen_resolution = love_ScreenSize.xy;

    vec2 pos = _vertex_pos / _screen_resolution;
    pos *= 0.71276;

    pos.x *= _screen_resolution.x / _screen_resolution.y;

    float dist_left = distance(abs(pos.xx), vec2(0)) + time - 2000.1551;
    float dist_right = 1.0 - distance(abs(pos.xx), vec2(0)) + time + 1000.333;

    pos.x += pos.x + dist_left;
    pos.x += (1.0 - pos.x) + dist_right;

    pos.x = _vertex_pos.x + distance(vec2(0.5), vec2(random(pos.xy), random(pos.yx)));
    vec3 color = mix(mint, pink, symmetrical_mod(pos.x));

    return vec4(color, 1.0);
}