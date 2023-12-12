--- @class rt.TransformLayout
rt.TransformLayout = meta.new_type("TransformLayout", function()
    local out = meta.new(rt.BinLayout, {
        _child = {},
        _canvas = rt.RenderTexture(1, 1),
        _shader = rt.Shader(rt.TransformLayout._shader_source),
        _rgb_offsets = {0, 0, 0},
        _hsv_offset = {0, 0, 0},
        _alpha_offset = 0
    }, rt.Drawable, rt.Widget)
    return out
end)

rt.TransformLayout._shader_source = [[
#pragma glsl3

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

uniform float _r_offset;
uniform float _g_offset;
uniform float _b_offset;
uniform float _h_offset;
uniform float _s_offset;
uniform float _v_offset;
uniform float _a_offset;

vec4 effect(vec4 verte_xcolor, Image texture, vec2 texture_coordinates, vec2 vertex_position)
{
    vec4 color = Texel(tex, texture_coords);

    color.r += _r_offset;
    color.g += _g_offset;
    color.b += _b_offset;

    vec3 as_hsv = rgb_to_hsv(color)
    as_hsv.x += _h_offset;
    as_hsv.y += _s_offset;
    as_hsv.z += _v_offset;

    vec3 as_rgba = hsv_to_rgb(as_hsv);

    return as_rgba * vertex_color;
}
]]

--- @brief
function rt.TransformLayout:_cache()

    self._canvas:bind_as_render_target()
    self._child:draw()
    self._canvas:unbind_as_render_target()

    self._shader:bind()
    self._shader:send("_r_offset", self._rgb_offsets[1])
    self._shader:send("_g_offset", self._rgb_offsets[2])
    self._shader:send("_b_offset", self._rgb_offsets[3])
    self._shader:send("_h_offset", self._hsv_offsets[1])
    self._shader:send("_s_offset", self._hsv_offsets[2])
    self._shader:send("_v_offset", self._hsv_offsets[3])
    self._shader:send("_a_offset", self._alpha_offset)

    self._canvas:draw()

    self._shader:unbind()
end


--- @overload rt.Drawable.draw
function rt.TransformLayout:draw()
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end

    self._shader:bind()

end

--- @overload rt.Widget.size_allocate
function rt.TransformLayout:size_allocate(x, y, width, height)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.TransformLayout:set_child(child)
    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.TransformLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.TransformLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Widget.measure
function rt.TransformLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.TransformLayout:realize()

    if self:get_is_realized() then return end

    self._realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end
end