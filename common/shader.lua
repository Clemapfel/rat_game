--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(code_or_filename)
    return meta.new(rt.Shader, {
        _native = love.graphics.newShader(code_or_filename),
        _before = nil,
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.Shader:send(name, value)
    local to_send = value
    if meta.is_vector2(value) then
        to_send = {value.x, value.y}
    elseif meta.is_vector3(value) then
        to_send = {value.x, value.y, value.z}
    end
    self._native:send(name, value)
end

--- @brief make shader the current on
function rt.Shader:bind()
    self._before = love.graphics.getShader()
    love.graphics.setShader(self._native)
end

--- @brief
function rt.Shader:unbind()
    love.graphics.setShader(self._before)
end