--- @class rt.Sprite
rt.Sprite = meta.new_type("Sprite", rt.Widget, rt.Animation, function(id)
    return meta.new(rt.Sprite, {
        _id = id,
        _spritesheet = {}, -- rt.SpriteAtlasEntry
        _width = 0, -- 0 -> use frame resolution
        _height = 0,
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _current_frame = 1,
        _elapsed = 0,
        _should_loop = true,
        _frame_duration = 0,
        _n_frames = 0,
        _animation_id = "",
        _frame_range_start = 1,
        _frame_range_end = 1,
        _opacity = 1
    })
end)

--- @override
function rt.Sprite:realize()
    if not self._is_realized then
        self._is_realized = true

        self._spritesheet = rt.SpriteAtlas:get(self._id)
        self._frame_duration = 1 / self._spritesheet:get_fps()
        self._n_frames = self._spritesheet:get_n_frames()
        self._width, self._height = self._spritesheet:get_frame_size()
        self._shape:set_texture(self._spritesheet:get_texture())

        self:reformat()
        self:set_frame(self._current_frame)
        self:set_minimum_size(self._width, self._height)

        if self._animation_id == "" then
            self._frame_range_start = 1
            self._frame_range_end = self._spritesheet:get_n_frames()
        else
            self:set_animation(self._animation_id)
        end

        self:set_opacity(self._opacity)
    end
end

--- @override
function rt.Sprite:draw()
    if self._is_realized and self:get_is_visible() then
        self._shape:draw()
    end
end

--- @override
function rt.Sprite:update(delta)
    if self._is_realized == true then
        self._elapsed = self._elapsed + delta
        local start = self._frame_range_start
        local n_frames = self._frame_range_end - self._frame_range_start + 1

        local offset = math.round(self._elapsed / self._frame_duration)
        if self._should_loop then
            offset = offset % n_frames
        else
            offset = math.min(offset, n_frames)
        end
        self:set_frame(start + offset)
    end
end

--- @brief
function rt.Sprite:set_frame(i)
    self._current_frame = i
    if self._is_realized == true then
        local frame = self._spritesheet:get_frame(self._current_frame)
        self._shape:reformat_texture_coordinates(
            frame.x, frame.y,
            frame.x + frame.width, frame.y,
            frame.x + frame.width, frame.y + frame.height,
            frame.x, frame.y + frame.height
        )
    end
end

--- @brief
function rt.Sprite:set_animation(id)
    if self._is_realized == false then self:realize() end
    if id == "" or id == nil then
        self:set_frame(1)
        self._frame_range_start = 1
        self._frame_range_end = self._spritesheet:get_n_frames()
    elseif meta.is_number(id) then
        self:set_frame(id)
    else
        if self._spritesheet:has_frame(id) == false then
            rt.warning("In rt.Sprite:set_animation: sprite at `" .. self._spritesheet.path .. "` has no animation with id `" .. id .. "`")
            return
        end

        self._animation_id = id
        local frame_range = self._spritesheet:get_frame_range(self._animation_id)
        self:set_frame(frame_range[1])
        self._frame_range_start = frame_range[1]
        self._frame_range_end = frame_range[2]
    end
end

--- @brief
function rt.Sprite:get_animation()
    return self._animation_id
end

--- @brief
function rt.Sprite:has_animation(id)
    return self._spritesheet:has_frame(id)
end

--- @override
function rt.Sprite:size_allocate(x, y, width, height)
    if self._is_realized == true then
        self._shape:set_vertex_position(1, x, y)
        self._shape:set_vertex_position(2, x + width, y)
        self._shape:set_vertex_position(3, x + width, y + height)
        self._shape:set_vertex_position(4, x, y + height)
        self:set_frame(self._current_frame)
    end
end

--- @brief
function rt.Sprite:get_resolution()
    if not self._is_realized then self:realize() end
    return self._width, self._height
end

--- @brief
function rt.Sprite:set_opacity(alpha)
    self._opacity = alpha

    if self._is_realized == true then
        self._shape:set_opacity(self._opacity)
    end
end

--- @brief
function rt.Sprite:set_color(color)
    for i = 1, 4 do
        self._shape:set_vertex_color(i, color)
    end
end
