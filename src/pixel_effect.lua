rt.settings.pixel_effect = {}
rt.settings.pixel_effect.vertex_shader_source = [[
#pragma language glsl3

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

float random(float x)
{
    return random(vec2(x, x));
}

float triangle_wave(float x)
{
    float pi = 2 * (335 / 113); // 2 * pi
    return 4 * abs((x / pi) + 0.25 - floor((x / pi) + 0.75)) - 1;
}

uniform int _instance_count;
uniform float _time;

flat varying int _instance_id;

vec4 position(mat4 transform, vec4 vertex_position)
{
    _instance_id = love_InstanceID;

    float speed = 70;
    float amplitude = 8;
    float frequency = 5;

    float wind_offset = (sin(_time / 20) + triangle_wave(_time / 20)) * 750 / 2;

    float seed = _instance_id * 2 * _instance_count;
    speed += random(vec2(seed, seed)) * 50;

    vertex_position.y += _time * speed;
    vertex_position.x += sin((_time + _instance_id) * frequency) * amplitude;
    vertex_position.x += wind_offset;

    vertex_position.xy = mod(vertex_position.xy, love_ScreenSize.xy);
    return transform * vertex_position;
}
]]

rt.settings.pixel_effect.fragment_shader_source = [[
#pragma language glsl3

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

float random(float x)
{
    return random(vec2(x, x));
}

uniform int _instance_count;
uniform float _time;

flat varying int _instance_id;

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    float hue = (random(_instance_id) + 0.4) / 1.4;
    return vec4(1, 1, 1, hue);
}
]]

--- @class rt.PixelEffect
rt.PixelEffect = meta.new_type("PixelEffect", function(n_instances)

    local attributes = {}
    for i = 1, n_instances do
        table.insert(attributes, {0, 0})
    end

    local out = meta.new(rt.PixelEffect, {
        _n_instances = n_instances,
        _data = love.graphics.newMesh(
            attributes,
            rt.MeshDrawMode.POINTS,
            rt.SpriteBatchUsage.STREAM
        ),
        _shape = love.graphics.newMesh(
            {{0, 0}},
            rt.MeshDrawMode.POINTS,
            rt.SpriteBatchUsage.STATIC
        ),
        _shader = love.graphics.newShader(
            rt.settings.pixel_effect.vertex_shader_source,
            rt.settings.pixel_effect.fragment_shader_source
        ),
        _elapsed = 0
    }, rt.Drawable)

    out._shader:send("_instance_count", out._n_instances)
    out._shape:attachAttribute(rt.VertexAttribute.POSITION, out._data, "perinstance")
    return out
end)

--- @overload rt.Drawable.draw
function rt.PixelEffect:draw()
    meta.assert_isa(self, rt.PixelEffect)
    self:update(love.timer.getDelta())

    love.graphics.setShader(self._shader)
    love.graphics.drawInstanced(self._shape, self._n_instances)
    love.graphics.setShader()
end

--- @overload rt.Animation.update
function rt.PixelEffect:update(delta)
    meta.assert_isa(self, rt.PixelEffect)
    self._elapsed = self._elapsed + delta
    self._shader:send("_time", self._elapsed)
    println(self._elapsed)
end

--- @brief [internal]
function rt.PixelEffect:_draw_data()
    love.graphics.draw(self._data)
end

--- @brief
function rt.PixelEffect:set_instance_position(index, x, y, z)
    meta.assert_isa(self, rt.PixelEffect)
    self._data:setVertexAttribute(index, 1, x, y, z)
end

--- @brief
function rt.PixelEffect:get_n_instances()
    meta.assert_isa(self, rt.PixelEffect)
    return self._n_instances
end