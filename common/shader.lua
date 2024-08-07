--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(filename)
    return meta.new(rt.Shader, {
        _native = love.graphics.newShader(filename),
        _filename = filename,
        _before = nil,
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.Shader:send(name, value)
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

--- @brief
function rt.Shader:recompile()
    self._native = love.graphics.newShader(self._filename)
end