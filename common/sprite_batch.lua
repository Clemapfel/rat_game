--- @class rt.SpriteBatch
rt.SpriteBatch = meta.new_type("SpriteBatch", rt.Drawable, function(texture, n_instances)
    meta.assert_isa(texture, rt.Texture)

    local out = meta.new(rt.SpriteBatch, {
        _texture = texture,
        _shader = love.graphics.newShader("common/sprite_batch.glsl"),
        _n_instances = n_instances,
        _n_added = 0
    })
    out:realize()
    return out
end)

do
    local _vertex_format = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
    }

    local x, y, width, height = -1, -1, 2, 2
    local _vertex_data = {
        { x, y, 0, 0 },
        { x + width, y, 1, 0 },
        { x + width, y + height, 1, 1 },
        { x, y + height, 0, 1 }
    }
    
    local _position_format = {
        { name = "position", format = "floatvec2" }
    }

    local _texcoord_format = {
        { name = "texture_coordinate", format = "floatvec2"}
    }

    local _discard_format = {
        { name = "should_discard", format = "uint32"}
    }

    local _buffer_mode = {
        shaderstorage = true,
        format = "dynamic"
    }
    
    --- @brief
    function rt.SpriteBatch:realize()
        self._shape = love.graphics.newMesh(_vertex_format, _vertex_data, "fan", "static")
        --self._shape:setTexture(self._texture._native)
        self._position_buffer = love.graphics.newBuffer(_position_format, self._n_instances, _buffer_mode)
        self._texcoord_buffer = love.graphics.newBuffer(_texcoord_format, self._n_instances, _buffer_mode)
        self._discard_buffer = love.graphics.newBuffer(_discard_format, self._n_instances, _buffer_mode)

        self._position_data = {}
        self._texcoord_data = {}
        self._discard_data = {}

        for i = 1, self._n_instances do
            table.insert(self._position_data, {
                0, 0
            })

            table.insert(self._texcoord_data, {
                0, 0
            })

            table.insert(self._discard_data, {
                1
            })
        end

        self._needs_update = true
    end

    --- @brief
    function rt.SpriteBatch:_update()
        self._position_buffer:setArrayData(self._position_data)
        self._texcoord_buffer:setArrayData(self._texcoord_data)
        self._discard_buffer:setArrayData(self._discard_data)

        if self._shader:hasUniform("position_buffer") then
            self._shader:send("position_buffer", self._position_buffer)
        end

        if self._shader:hasUniform("texcoord_buffer") then
            self._shader:send("texcoord_buffer", self._texcoord_buffer)
        end

        if self._shader:hasUniform("discard_buffer") then
            self._sahder:send("discard_buffer", self._discard_buffer)
        end
    end
end

--- @brief
--- @return Number shape id
function rt.SpriteBatch:add(x, y, w, h, texture_x, texture_y, texture_w, texture_h)
    meta.assert_number(x, y, w, h, texture_x, texture_y, texture_w, texture_h)
    local id = self._n_added
    self._position_data[id + 1] = {x, y}
    self._texcoord_data[id + 1] = {0, 0}
    self._discard_data[id + 1] = 0

    self._n_added = self._n_added + 1
    self._needs_update = true
    return id
end

--- @brief
function rt.SpriteBatch:set_position(id, position_x, position_y)
    self._position_data[id] = { position_x, position_y }
    self._needs_update = true
end

--- @brief
function rt.SpriteBatch:set_texture_coordinates(texture_x, texture_y, texture_w, texture_h)
end

--- @brief
function rt.SpriteBatch:draw()
    if self._needs_update then
        self._needs_update = false
        self:_update()
    end

    love.graphics.setShader(self._shader)
    love.graphics.drawInstanced(self._shape, self._n_instances)
    love.graphics.setShader()
end