rt.settings.battle.priority_queue_element = {
    font = rt.settings.font.default,
    thumbnail_size = 32, -- resolution of subimage
    frame_thickness = 5,
    base_color = rt.color_darken(rt.Palette.GRAY_4, 0.05),
    frame_color = rt.Palette.GRAY_3,
    selected_frame_color = rt.Palette.YELLOW_2,

    knocked_out_shape_alpha = 0.7,
    knocked_out_pulse = function(x) return (rt.sine_wave(x, 1 / 3) - 0.5) * 0.3 end,

    dead_base_color = rt.Palette.GRAY_6,
    dead_shape_alpha = 1,
    dead_frame_color = rt.Palette.GRAY_5,

    corner_radius = 10,
    change_indicator_up_color = rt.Palette.GREEN,
    change_indicator_down_color = rt.Palette.RED,
    change_indicator_none_color = rt.Palette.GRAY_2
}

--- @class bt.PriorityQueueElement
bt.PriorityQueueElement = meta.new_type("PriorityQueueElement", rt.Widget, rt.Animation, function(queue, entity)
    return meta.new(bt.PriorityQueueElement, {
        _entity = entity,
        _parent = queue,

        _shape = {}, -- rt.Shape
        _spritesheet = {}, -- rt.SpriteAtlasEntry
        _shader = rt.Shader("assets/shaders/priority_queue_element.glsl"),

        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _frame_gradient = {}, -- rt.LogGradient

        _id_offset_label_visible = false,
        _id_offset_label = {}, -- rt.Glyph

        _change_direction = rt.Direction.NONE,
        _change_indicator = {}, -- rt.DirectionIndicator
        _change_indicator_visible = false,

        _is_selected = false,
        _is_stunned = false,

        _state = bt.EntityState.ALIVE,
        _elapsed = 0
    })
end)

--- @brief
function bt.PriorityQueueElement:set_change_indicator(direction)
    self._change_direction = direction
    if self._is_realized == true then
        self._change_indicator:set_direction(direction)
        if direction == rt.Direction.UP then
            self._change_indicator:set_color(rt.settings.battle.priority_queue_element.change_indicator_up_color)
        elseif direction == rt.Direction.DOWN then
            self._change_indicator:set_color(rt.settings.battle.priority_queue_element.change_indicator_down_color)
        elseif direction == rt.Direction.NONE then
            self._change_indicator:set_color(rt.settings.battle.priority_queue_element.change_indicator_none_color)
        end
    end

    if not (direction == rt.Direction.NONE or direction == rt.Direction.UP or direction == rt.Direction.DOWN) then
        rt.error("In bt.PriorityQueueElement: direction `" .. direction .. "` is not UP, DOWN or NONE")
    end
end


--- @brief
function bt.PriorityQueueElement:set_change_indicator_visible(b)
    self._change_indicator_visible = b
end

function bt.PriorityQueueElement:set_state(state)
    if self._state ~= state then
        self._state = state
        self:_update_state()
    end
end

function bt.PriorityQueueElement:set_is_stunned(b)
    self._is_stunned = b
    self:_update_state()
end

function bt.PriorityQueueElement:set_is_selected(b)
    self._is_selected = b
    self:_update_state()
end

function bt.PriorityQueueElement:_update_frame_color()
    if self._is_selected then
        self._frame:set_color(rt.settings.battle.priority_queue_element.selected_frame_color)
    elseif self._state == bt.EntityState.ALIVE then
        self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color)
    elseif self._state == bt.EntityState.KNOCKED_OUT then
        self._frame:set_color(rt.color_lighten(rt.Palette.KNOCKED_OUT, 0.15))
    elseif self._state == bt.EntityState.DEAD then
        self._frame:set_color(rt.settings.battle.priority_queue_element.dead_frame_color)
    end
end

--- @brief
function bt.PriorityQueueElement:_update_state()
    if self._state == bt.EntityState.ALIVE then
        self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
        for i = 1, 4 do
            self._shape:set_vertex_color(i, rt.RGBA(1, 1,1, 1))
        end
    elseif self._state == bt.EntityState.KNOCKED_OUT then
        self._backdrop:set_color(rt.Palette.KNOCKED_OUT)
        for i = 1, 4 do
            self._shape:set_vertex_color(i, rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.knocked_out_shape_alpha))
        end
    elseif self._state == bt.EntityState.DEAD then
        self._backdrop:set_color(rt.settings.battle.priority_queue_element.dead_base_color)
        for i = 1, 4 do
            self._shape:set_vertex_color(i, rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.dead_shape_alpha))
        end
    end

    if self._is_stunned then
        self._shape:set_opacity(ternary(not self._is_stunned, 1, 0.4))
        self._id_offset_label:set_opacity(ternary(not self._is_stunned, 1, 0.8))
    end

    self:_update_frame_color()
end

--- @override
function bt.PriorityQueueElement:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local sprite_id, sprite_index = self._entity:get_sprite_id()
    sprite_index = which(sprite_index, 1)
    self._spritesheet = rt.SpriteAtlas:get(sprite_id)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._shape:set_texture(self._spritesheet:get_texture())
    self._spritesheet:get_texture():set_wrap_mode(rt.TextureWrapMode.ZERO)
    local frame = self._spritesheet:get_frame(sprite_index)
    self._shape:reformat_texture_coordinates(
        frame.x, frame.y,
        frame.x + frame.width, frame.y,
        frame.x + frame.width, frame.y + frame.height,
        frame.x, frame.y + frame.height
    )

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
    self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    self._frame_gradient = rt.LogGradient(
        rt.RGBA(0.8, 0.8, 0.8, 1),
        rt.RGBA(1, 1, 1, 1)
    )
    self._frame_gradient:set_is_vertical(true)

    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)
    end

    self._id_offset_label = rt.Glyph(
            rt.settings.battle.priority_queue_element.font,
            self._entity:get_id_offset_suffix(),
            {
                is_outlined = true,
                outline_color = rt.Palette.BLACK,
                font_style = rt.FontStyle.BOLD
            }
    )

    self._change_indicator = rt.DirectionIndicator(self._change_direction)
    self._change_indicator:realize()
    self:set_change_indicator(self._change_direction)

    self:_update_state()
    self:set_is_animated(true)
end

--- @brief
function bt.PriorityQueueElement:set_change_indicator_visible(b)
    self._change_indicator_visible = b
end

--- @override
function bt.PriorityQueueElement:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local sprite_id, sprite_index = self._entity:get_sprite_id()
    sprite_index = which(sprite_index, 1)
    self._spritesheet = rt.SpriteAtlas:get(sprite_id)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._shape:set_texture(self._spritesheet:get_texture())
    self._spritesheet:get_texture():set_wrap_mode(rt.TextureWrapMode.ZERO)
    local frame = self._spritesheet:get_frame(sprite_index)
    self._shape:reformat_texture_coordinates(
        frame.x, frame.y,
        frame.x + frame.width, frame.y,
        frame.x + frame.width, frame.y + frame.height,
        frame.x, frame.y + frame.height
    )

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
    self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    self._frame_gradient = rt.LogGradient(
        rt.RGBA(0.8, 0.8, 0.8, 1),
        rt.RGBA(1, 1, 1, 1)
    )
    self._frame_gradient:set_is_vertical(true)

    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)
    end

    self._id_offset_label = rt.Glyph(
        rt.settings.battle.priority_queue_element.font,
        self._entity:get_id_offset_suffix(),
        {
            is_outlined = true,
            outline_color = rt.Palette.BLACK,
            font_style = rt.FontStyle.BOLD
        }
    )

    self._change_indicator = rt.DirectionIndicator(self._change_direction)
    self._change_indicator:realize()
    self:set_change_indicator(self._change_direction)
    self:_update_state()
    self:set_is_animated(true)
end

--- @override
function bt.PriorityQueueElement:size_allocate(x, y, width, height)
    if self._is_realized == true then
        -- make shape square
        local min = math.min(width, height)
        x = x + (width - min) / 2
        y = y + (height - min) / 2
        width, height = min, min

        self._shape:set_vertex_position(1, x, y)
        self._shape:set_vertex_position(2, x + width, y)
        self._shape:set_vertex_position(3, x + width, y + height)
        self._shape:set_vertex_position(4, x, y + height)
        self._backdrop:resize(x, y, width, height)

        local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
        local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
        self._frame:set_line_width(frame_thickness)
        self._frame_outline:set_line_width(frame_outline_thickness)

        local frame_aabb = rt.AABB(x + frame_thickness / 2, y + frame_thickness / 2, width - frame_thickness , height - frame_thickness)
        self._frame:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
        self._frame_outline:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
        self._frame_gradient:resize(x, y, width, height)

        -- align texture
        local frame = self._spritesheet:get_frame(self._entity.sprite_index)
        local frame_x, frame_y, frame_w, frame_h = frame.x, frame.y, frame.width, frame.height
        local frame_res_w, frame_res_h = self._spritesheet:get_frame_size()

        local target_size = rt.settings.battle.priority_queue_element.thumbnail_size
        local current_size = math.min(frame_res_w, frame_res_h)

        -- get n*n sized square in the middle of frame
        local zoom_factor = (target_size / current_size)
        local size_offset_x = (frame_w - (zoom_factor * frame_w)) / 2
        local size_offset_y = (frame_h - (zoom_factor * frame_h)) / 2

        -- translate aligned portion, useful for picking which part of a big sprite is shown
        local origin_x, origin_y = self._spritesheet.origin_x, self._spritesheet.origin_y
        local origin_offset_x, origin_offset_y = (0.5 - (1 - origin_x)) * frame_w, (0.5 - (1 - origin_y)) * frame_h

        if frame_res_w > frame_res_h then
            local x_offset = ((1 - frame_res_h / frame_res_w) * frame_w) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x + x_offset + size_offset_x + origin_offset_x, frame_y + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w - x_offset - size_offset_x + origin_offset_x, frame_y + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w - x_offset - size_offset_x + origin_offset_x, frame_y + frame_h - size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(4, frame_x + x_offset + size_offset_x + origin_offset_x, frame_y + frame_h - size_offset_y + origin_offset_y)
        else
            local y_offset = ((1 - frame_res_w / frame_res_h) * frame_h) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x + size_offset_x+ origin_offset_x, frame_y + y_offset + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w - size_offset_x+ origin_offset_x, frame_y + y_offset + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w - size_offset_x+ origin_offset_x, frame_y + frame_h - y_offset - size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(4, frame_x + size_offset_x+ origin_offset_x, frame_y + frame_h - y_offset - size_offset_y + origin_offset_y)
        end

        -- align label
        local label_w, label_h = self._id_offset_label:get_size()
        local label_offset = 0.75
        self._id_offset_label:set_position(
                x + width - label_offset * label_w,
                y + height - label_offset * label_h
        )

        -- align direction
        local direction_size = rt.settings.battle.priority_queue_element.font:get_size()
        local direction_offset = -0.4
        self._change_indicator:fit_into(
                x + direction_offset * direction_size,
                y + direction_offset * direction_size,
                direction_size, direction_size
        )

    end
end

--- @override
function bt.PriorityQueueElement:draw()
    if self._is_realized == true then
        self._backdrop:draw()

        -- stencil away overlapping corners of shape
        rt.graphics.stencil(1, self._backdrop)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 1)
        self._shader:bind()

        if self._state == bt.EntityState.ALIVE then
            self._shader:send("_state", 1)
        elseif self._state == bt.EntityState.KNOCKED_OUT then
            self._shader:send("_state", 2)
        elseif self._state == bt.EntityState.DEAD then
            self._shader:send("_state", 3)
        end

        self._shape:draw()
        self._shader:unbind()
        rt.graphics.set_stencil_test()
        rt.graphics.stencil()

        self._frame_outline:draw()
        self._frame:draw()

        rt.graphics.stencil(2, self._frame)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 2)
        rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
        self._frame_gradient:draw()
        rt.graphics.set_blend_mode()
        rt.graphics.set_stencil_test()

        if self._id_offset_label_visible then
            self._id_offset_label:draw()
        end

        if self._change_indicator_visible and self._change_direction ~= rt.Direction.NONE then
            self._change_indicator:draw()
        end
    end
end

--- @override
function bt.PriorityQueueElement:update(delta)
    self._elapsed = self._elapsed + delta
    if self._state == bt.EntityState.KNOCKED_OUT then
        -- pulsing red animation
        local offset = rt.settings.battle.priority_queue_element.knocked_out_pulse(self._parent._elapsed)
        local color = rt.rgba_to_hsva(rt.Palette.KNOCKED_OUT)
        color.v = clamp(color.v + offset, 0, 1)
        self._backdrop:set_color(color)
    end
end

--- @brief
function bt.PriorityQueueElement:set_id_offset_label_visible(b)
    if b ~= self._id_offset_label_visible then
        self._id_offset_label_visible = b
        self._id_offset_label:set_text(self._entity:get_id_offset_suffix())
        self:reformat()
    end
end
