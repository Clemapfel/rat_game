rt.settings.sprite = {
    shader_path = "common/sprite_scale_correction.glsl",
    scale_factor = 2
}

--- @class rt.Sprite
rt.Sprite = meta.new_type("Sprite", rt.Widget, rt.Updatable, function(id, index)
    meta.assert_string(id)
    return meta.new(rt.Sprite, {
        _id = id,
        _spritesheet = {}, -- rt.SpriteAtlasEntry
        _is_valid = false,
        _texture_resolution = {0, 0},
        _width = 0, -- 0 -> use frame resolution
        _height = 0,
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _current_frame = 1,
        _elapsed = 0,
        _should_loop = true,
        _frame_duration = 0,
        _n_frames = 0,
        _animation_id = index,
        _frame_range_start = 1,
        _frame_range_end = 1,
        _opacity = 1,
        _use_corrective_shader = false,

        _bottom_right_child = nil,
        _top_right_child = nil,
        _bottom_left_child = nil,
        _top_left_child = nil,
    })
end, {
    _shader = rt.Shader(rt.settings.sprite.shader_path)
})

--- @override
function rt.Sprite:realize()
    if self:already_realized() then return end

    self._spritesheet = rt.SpriteAtlas:get(self._id)
    if self._spritesheet == nil then
        self._is_valid = false
        self._shape:set_color(rt.RGBA(1, 0, 1, 1))
        return
    else
        self._is_valid = true
    end

    self._frame_duration = 1 / self._spritesheet:get_fps()
    self._n_frames = self._spritesheet:get_n_frames()
    self._width, self._height = self._spritesheet:get_frame_size()
    self._shape:set_texture(self._spritesheet:get_texture())
    self._texture_resolution = {self._spritesheet:get_texture_resolution()}

    self:reformat()
    self:set_frame(self._current_frame)

    local scale_factor = rt.settings.sprite.scale_factor
    self:set_minimum_size(self._width * scale_factor, self._height * scale_factor)

    if self._animation_id == "" then
        self._frame_range_start = 1
        self._frame_range_end = self._spritesheet:get_n_frames()
    else
        self:set_animation(self._animation_id)
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

--- @override
function rt.Sprite:draw()
    if self._use_corrective_shader then
        self._shader:bind()
        self._shader:send("texture_resolution", self._texture_resolution)
        self._shape:draw()
        self._shader:unbind()

        for child in range(
            self._top_right_child,
            self._bottom_right_child,
            self._bottom_left_child,
            self._top_left_child
        ) do
            child:draw()
        end
    else
        self._shape:draw()
    end
end

--- @override
function rt.Sprite:update(delta)
    if self._is_realized == true and self._is_valid then
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

    for child in range(
        self._top_right_child,
        self._bottom_right_child,
        self._bottom_left_child,
        self._top_left_child
    ) do
        child:update()
    end
end

--- @brief
function rt.Sprite:set_frame(i)
    self._current_frame = i
    if self._is_realized == true and self._is_valid then
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
function rt.Sprite:get_frame()
    return self._current_frame
end

--- @brief
function rt.Sprite:set_animation(id)
    if self:get_is_realized() == false then self:realize() end
    if not self._is_valid then return end
    if id == "" or id == nil then
        self:set_frame(1)
        self._frame_range_start = 1
        self._frame_range_end = self._spritesheet:get_n_frames()
    elseif meta.is_number(id) then
        self:set_frame(id)
    else
        if self._spritesheet:has_frame(id) == false then
            rt.warning("In rt.Sprite:set_animation: sprite at `" .. self._spritesheet.path .. "/" .. self._spritesheet.id .. "` has no animation with id `" .. id .. "`")
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
    if self._is_valid == false then return false end
    return self._spritesheet:has_frame(id)
end

--- @override
function rt.Sprite:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
    self:set_frame(self._current_frame)

    if self._top_left_child ~= nil then
        local w, h = self._top_left_child:measure()
        self._top_left_child:fit_into(
            x - w,
            y - h,
            w, h
        )
    end

    if self._top_right_child ~= nil then
        local w, h = self._top_right_child:measure()
        self._top_right_child:fit_into(
            x + width - w,
            y + h,
            w, h
        )
    end

    if self._bottom_right_child ~= nil then
        local w, h = self._bottom_right_child:measure()
        self._bottom_right_child:fit_into(
            x + width - w,
            y + height - h,
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
        if meta.is_string(widget) then widget = rt.Label(widget) end
        meta.assert_isa(widget, rt.Widget)
        self["_" .. which .. "_child"] = widget
        if self:get_is_realized() then widget:realize() end
        self:reformat()
    end

    --- @brief get_top_right_child, get_bottom_right_child, get_bottom_left_child, get_top_left_child
    rt.Sprite["get_" .. which .. "_child"] = function(self)
        return self["_" .. which .. "_child"]
    end
end

--- @brief
function rt.Sprite:get_resolution()
    if not self._is_realized then self:realize() end
    if not self._is_valid then return 16, 16 end
    return self._width, self._height
end

--- @brief
function rt.Sprite:set_opacity(alpha)
    self._opacity = clamp(alpha, 0, 1)
    self._shape:set_opacity(alpha)
end

--- @brief
function rt.Sprite:set_color(color)
    for i = 1, 4 do
        self._shape:set_vertex_color(i, color)
    end
end

--- @brief
function rt.Sprite:get_n_frames(animation_id_maybe)
    if self._is_valid == false then return 1 end
    return self._spritesheet:get_n_frames(animation_id_maybe)
end

--- @brief
function rt.Sprite:set_use_corrective_shader(b)
    self._use_corrective_shader = b
end
