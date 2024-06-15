--- @class bt.Background
bt.Background = meta.new_abstract_type("BattleBackground", rt.Widget)

--- @override
function bt.Background:update(delta, spectrum)
    -- noop
end

-- ###

bt.ShaderOnlyBackground = meta.new_type("ShaderOnlyBackground", bt.Background, function(path, disabled_elapsed)
    return meta.new(bt.ShaderOnlyBackground, {
        _path = path,
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _elapsed = rt.random.number(0, 2^8),
        _disable_elapsed = disabled_elapsed
    })
end)

--- @override
function bt.ShaderOnlyBackground:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(self._path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.ShaderOnlyBackground:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.ShaderOnlyBackground:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta

    if self._disable_elapsed ~= false then
        self._shader:send("elapsed", self._elapsed)
    end
end

--- @override
function bt.ShaderOnlyBackground:draw()
    if self._is_realized ~= true then return end
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
end

-- include all implementations
for _, name in pairs(love.filesystem.getDirectoryItems("battle/backgrounds")) do
    if string.match(name, "%.lua$") ~= nil then
        local path = "battle.backgrounds." .. string.gsub(name, "%.lua$", "")
        require(path)
    end
end
