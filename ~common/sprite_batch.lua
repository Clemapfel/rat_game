--- @class rt.SpriteBatch
rt.SpriteBatch = meta.class("SpriteBatch", rt.Drawable)

function rt.SpriteBatch:instantiate(texture, n_instances)
    meta.assert(texture, "Texture")

    meta.install(self, {
        _texture = texture,
        _shader = love.graphics.newShader("common/sprite_batch.glsl"),
        _n_instances = n_instances,
        _n_vertices = 4,
        _n_added = 1,
    })
    self:realize()
    return self
end

do
    local _vertex_format = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
    }

    local x, y, width, height = -10, -10, 20, 20
    local _vertex_data = {
        { x, y, 0, 0 },
        { x + width, y, 1, 0 },
        { x + width, y + height, 1, 1 },
        { x, y + height, 0, 1 }
    }

    local _offset_format = {
        { name = "offsets", format = "floatvec2" }
    }

    local _alt_position_format = {
        { name = "positions", format = "floatmat4x2" }
    }
    
    local _position_format = {
        { name = "_01", format = "floatvec2" },
        { name = "_02", format = "floatvec2" },
        { name = "_03", format = "floatvec2" },
        { name = "_04", format = "floatvec2" }
    }

    local _texcoord_format = {
        { name = "texcoords", format = "floatmat2x4"}
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
        self._n_vertices = sizeof(_vertex_data)
        --self._shape:setTexture(self._texture._native)

        if self._shader:hasUniform("n_vertices_per_instance") then
            self._shader:send("n_vertices_per_instance", self._n_vertices)
        end

        self._position_buffer = love.graphics.newBuffer(_position_format, self._n_instances, _buffer_mode)
        self._alt_position_buffer = love.graphics.newBuffer(_alt_position_format, self._n_instances, _buffer_mode)
        self._texcoord_buffer = love.graphics.newBuffer(_texcoord_format, self._n_instances, _buffer_mode)
        self._discard_buffer = love.graphics.newBuffer(_discard_format, self._n_instances, _buffer_mode)
        self._offset_buffer = love.graphics.newBuffer(_offset_format, self._n_instances, _buffer_mode)

        self._position_data = {}
        self._texcoord_data = {}
        self._discard_data = {}
        self._offset_data = {}

        for i = 1, self._n_instances do
            table.insert(self._position_data, {
                0, 100, 100, 0,
                0, 0, 100, 100
                --[[
                0, 0,
                100, 0,
                100, 100,
                0, 100
                ]]--
            })

            table.insert(self._texcoord_data, {
                0, 0,
                1, 0,
                1, 1,
                0, 1,
            })

            table.insert(self._discard_data, {
                1
            })

            table.insert(self._offset_data, {
                0, 0
            })
        end

        self._texcoord_needs_update = true
        self._position_needs_update = true
        self._discard_needs_update = true
        self._offset_needs_update = true
    end

    --- @brief
    function rt.SpriteBatch:_update()
        local function has(x)
            return self._shader:hasUniform(x)
        end

        if self._position_needs_update == true then
            self._position_buffer:setArrayData(self._position_data)
            if has("position_buffer") then self._shader:send("position_buffer", self._position_buffer) end

            self._alt_position_buffer:setArrayData(self._position_data)
            if has("alt_position_buffer") then self._shader:send("alt_position_buffer", self._alt_position_buffer) end

            self._position_needs_update = false
        end

        if self._offset_needs_update == true then
            self._offset_buffer:setArrayData(self._offset_data)
            if has("offset_buffer") then self._shader:send("offset_buffer", self._offset_buffer) end
            self._offset_needs_update = false
        end

        if self._texcoord_needs_update == true then
            self._texcoord_buffer:setArrayData(self._texcoord_data)
            if has("texcoord_buffer") then self._shader:send("texcoord_buffer", self._texcoord_buffer) end
            self._texcoord_need_update = false
        end

        if self._discard_needs_update == true then
            self._discard_buffer:setArrayData(self._discard_data)
            if has("discard_buffer") then self._shader:send("discard_buffer", self._discard_buffer) end
            self._discard_needs_update = false
        end
    end
end

--- @brief
--- @return Number shape id
function rt.SpriteBatch:add(position_x, position_y, position_w, position_h, texture_x, texture_y, texture_w, texture_h)
    meta.assert_number(position_x, position_y, position_w, position_h, texture_x, texture_y, texture_w, texture_h)
    local id = self._n_added

    local px, py, pw, ph = position_x, position_y, position_w, position_h
    self._position_data[id] = {
        px, py,
        px + pw, py,
        px + pw, py + ph,
        px, py + ph,
    }

    self._position_data[id] = {
       px, px + pw, px + pw, px,
       py, py, py + ph, py + ph
    }

    local tx, ty, tw, th = texture_x, texture_y, texture_w, texture_h
    self._texcoord_data[id] = {
        tx, ty,
        tx + tw, ty,
        tx + tw, ty + th,
        tx, ty + th
    }

    self._discard_data[id] = {0}
    self._offset_data[id] = {0, 0}

    self._position_needs_update = true
    self._discard_needs_update = true
    self._texcoord_need_update = true

    self._n_added = self._n_added + 1
    return id
end

--- @brief
function rt.SpriteBatch:set_offset(id, x, y)
    local offset = self._offset_data[id]
    offset[1] = x
    offset[2] = y
    self._offset_needs_update = true
end

--- @brief
function rt.SpriteBatch:draw()
    self:_update()
    love.graphics.setShader(self._shader)
    love.graphics.drawInstanced(self._shape, self._n_instances)
    love.graphics.setShader()
end