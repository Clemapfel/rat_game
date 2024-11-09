rt.settings.sprite = {
    sprite_scale = 2
}

--- @class rt.Sprite
rt.Sprite = meta.new_type("Sprite", rt.Widget, rt.Updatable, function(id, index)
    if index == nil then index = 1 end

    local current_frame, current_animation
    if meta.is_number(index) then
        current_frame = index
    else
        meta.assert_string(index)
        current_animation = index
    end

    return meta.new(rt.Sprite, {
        _id = id,
        _current_animation = current_animation,
        _spritesheet = nil, -- rt.SpriteAtlasEntry
        _mesh = nil, -- love.mesh
        _mesh_x = 0,
        _mesh_y = 0,
        _mesh_w = 1,
        _mesh_h = 1,

        _frames = {},

        _current_frame = which(current_frame, 1),
        _frame_range_start = 1,
        _frame_range_end = 1,
        _frame_duration = 1,
        _should_loop = true,

        _elapsed = 0,
        _opacity = 1,

        _bottom_right_child = nil,
        _top_right_child = nil,
        _bottom_left_child = nil,
        _top_left_child = nil,

        _is_valid = true
    })
end, {
    _mesh_vertex_format = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
        --{name = "VertexColor", format = "floatvec4"},
    },
})

--- @override
function rt.Sprite:realize()
    if self:already_realized() then return end

    self._spritesheet = rt.SpriteAtlas:get(self._id)
    if self._spritesheet == nil then
        self._spritesheet = rt.SpriteAtlas:get("why")
        self._frames = {
            {0, 0, 1, 1}
        }
        self._frame_range_start = 1
        self._frame_range_end = 1
        self._current_frame = 1
        self._frame_duration = 1

        self._is_valid = false
    else
        self._frames = {}
        for frame_i = 1, self._spritesheet:get_n_frames() do
            local frame = self._spritesheet:get_frame(frame_i)
            table.insert(self._frames, {rt.aabb_unpack(frame)})
        end
        self._frame_range_start, self._frame_range_end = self._spritesheet:get_frame_range(self._current_animation)
        self._current_frame = self._frame_range_start
        self._frame_duration = 1 / self._spritesheet:get_fps()

        self._is_valid = true
    end

    local x, y, w, h = 0, 0, self._spritesheet:get_frame_size()
    local tx, ty, tw, th = table.unpack(self._frames[self._current_frame])

    local scale = rt.settings.sprite.sprite_scale
    w = w * scale
    h = h * scale

    self._mesh = love.graphics.newMesh(
        rt.Sprite._mesh_vertex_format,
        {
            {x + 0, y + 0,  tx +  0, ty + 0},
            {x + w, y + 0,  tx + tw, ty + 0},
            {x + w, y + h,  tx + tw, ty + th},
            {x + 0, y + h,  tx +  0, ty + th}
        },
        rt.MeshDrawMode.TRIANGLE_FAN
    )
    --self._mesh:setVertexMap(1, 2, 3, 1, 3, 4)
    self._mesh:setTexture(self._spritesheet:get_texture()._native)
    self._mesh_x, self._mesh_y = x, y
    self._mesh_w, self._mesh_h = w, h

    if self._is_valid then
        self:set_minimum_size(w, h)
    end

    for child in range(
        self._top_right_child,
        self._bottom_right_child,
        self._bottom_left_child,
        self._top_left_child
    ) do
        child:realize()
    end
end

--- @brief
function rt.Sprite:set_frame(i)
    self._current_frame = i
    local tx, ty, tw, th = table.unpack(self._frames[self._current_frame])

    self._mesh:setVertexAttribute(1, 2, tx, ty)
    self._mesh:setVertexAttribute(2, 2, tx + tw, ty)
    self._mesh:setVertexAttribute(3, 2, tx + tw, ty + th)
    self._mesh:setVertexAttribute(4, 2, tx, ty + th)
end

--- @override
function rt.Sprite:size_allocate(x, y, width, height)
    if self._mesh_w ~= width or self._mesh_h ~= height then
        self._mesh:setVertexAttribute(1, 1, 0, 0)
        self._mesh:setVertexAttribute(2, 1, 0 + width, 0)
        self._mesh:setVertexAttribute(3, 1, 0 + width, 0 + height)
        self._mesh:setVertexAttribute(4, 1, 0, 0 + height)
        self._mesh_w = width
        self._mesh_h = height
    end

    self._mesh_x = x
    self._mesh_y = y

    if self._top_left_child ~= nil then
        local w, h = self._top_left_child:measure()
        self._top_left_child:fit_into(
            0 - w,
            0 - h,
            w, h
        )
    end

    if self._top_right_child ~= nil then
        local w, h = self._top_right_child:measure()
        self._top_right_child:fit_into(
            0 + width - w,
            0 + h,
            w, h
        )
    end

    if self._bottom_right_child ~= nil then
        local w, h = self._bottom_right_child:measure()
        self._bottom_right_child:fit_into(
            0 + width - w,
            0 + height - h,
            w, h
        )
    end

    if self._bottom_left_child ~= nil then
        local w, h = self._bottom_left_child:measure()
        self._bottom_left_child:fit_into(
            x - w,
            y + height - h,
            w, h
        )
    end
end

for which in range("top_right", "bottom_right", "bottom_left", "top_left") do
    --- @brief set_top_right_child, set_bottom_right_child, set_bottom_left_child, set_top_left_child
    rt.Sprite["set_" .. which .. "_child"] = function(self, widget)
        if meta.is_string(widget) then widget = rt.Label(widget, rt.settings.font.default_tiny, rt.settings.font.default_mono_tiny) end
        meta.assert_isa(widget, rt.Widget)
        self["_" .. which .. "_child"] = widget

        if self._is_valid then
            widget:realize()
            self:reformat()
        end
    end

    --- @brief get_top_right_child, get_bottom_right_child, get_bottom_left_child, get_top_left_child
    rt.Sprite["get_" .. which .. "_child"] = function(self)
        return self["_" .. which .. "_child"]
    end
end

--- @override
function rt.Sprite:draw()
    local x, y = self._mesh_x, self._mesh_y
    love.graphics.translate(x, y)
    love.graphics.setColor(1, 1, 1, self._opacity)
    love.graphics.draw(self._mesh)

    if self._top_left_child ~= nil then
        self._top_left_child:draw()
    end

    if self._top_right_child ~= nil then
        self._top_right_child:draw()
    end

    if self._bottom_right_child ~= nil then
        self._bottom_right_child:draw()
    end

    if self._bottom_left_child ~= nil then
        self._bottom_left_chlid:draw()
    end

    love.graphics.translate(-x, -y)
end

--- @override
function rt.Sprite:get_resolution()
    if not self:get_is_realized() then self:realize() end
    return self._spritesheet:get_frame_size()
end

--- @brief
function rt.Sprite:get_frame()
    return self._current_frame
end

--- @brief
function rt.Sprite:set_animation(id)
    self._current_animation = id
    self._frame_range_start, self._frame_range_end = self._spritesheet:get_frame_range()
    if self._current_frame < self._frame_range_start or self._current_frame > self._frame_range_end then
        self._current_frame = self._frame_range_start
    end
    self:update(0)
end

--- @override
function rt.Sprite:update(delta)
    if not self._is_realized then return end
    self._elapsed = self._elapsed + delta

    local start = self._frame_range_start
    local n_frames = self._frame_range_end - self._frame_range_start
    if n_frames == 0 then return end

    local offset = math.round(self._elapsed / self._frame_duration)
    if self._should_loop then
        offset = offset % (n_frames + 1)
    elseif offset > n_frames then
        offset = n_frames
    end

    self:set_frame(start + offset)

    if self._top_left_child ~= nil then
        self._top_left_child:update(delta)
    end

    if self._top_right_child ~= nil then
        self._top_right_child:update(delta)
    end

    if self._bottom_right_child ~= nil then
        self._bottom_right_child:update(delta)
    end

    if self._bottom_left_child ~= nil then
        self._bottom_left_chlid:update(delta)
    end
end