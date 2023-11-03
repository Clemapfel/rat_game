--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(code_or_filename)
    meta.assert_string(code_or_filename)
    return meta.new(rt.Shader, {
        _native = love.graphics.newShader(code_or_filename)
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.Shader:send(name, value)
    meta.assert_isa(self, rt.Shader)
    local to_send = value
    if meta.is_vector2(value) then
        to_send = {value.x, value.y}
    elseif meta.is_vector3(value) then
        to_send = {value.x, value.y, value.z}
    end
    self._native:send(name, value)
end

rt.settings.default_fragment_shader = [[
vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    return Texel(texture, texture_coords) * vertex_color;
}
]]