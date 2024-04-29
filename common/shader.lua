--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(code_or_filename, inject_lib)

    local info = love.filesystem.getInfo(code_or_filename)
    inject_lib = which(inject_lib, false)

    local native
    if inject_lib then
        if info == nil then
            native = love.graphics.newShader(rt.Shader._common.src .. "\n" .. code_or_filename)
        else
            local code = love.filesystem.read(code_or_filename)
            native = love.graphics.newShader(rt.Shader._common.src .. "\n" .. code)
        end
    else
        native = love.graphics.newShader(code_or_filename)
    end

    return meta.new(rt.Shader, {
        _native = native,
        _before = nil,
    })
end)

rt.Shader._common = {
    src = love.filesystem.read("common/shader_functions.glsl")
}

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