rt.settings.battle.priority_queue_element = {
    font = rt.settings.font.default,
    thumbnail_size = 32, -- resolution of subimage
    frame_thickness = 3,
    base_color = rt.color_darken(rt.Palette.GRAY_5, 0.05),
    frame_color = rt.Palette.GRAY_2,

    knocked_out_shape_alpha = 0.7,
    knocked_out_pulse = function(x) return (rt.sine_wave(x, 1 / 3) - 0.5) * 0.3 end,

    dead_base_color = rt.Palette.GRAY_6,
    dead_shape_alpha = 1,
    dead_frame_color = rt.Palette.GRAY_5,

    corner_radius = 10,
}

--- @class bt.PriorityQueueElement
bt.PriorityQueueElement = meta.new_type("PriorityQueueElement", rt.Widget, rt.Animation, function(queue, entity)
    return meta.new(bt.PriorityQueueElement, {
        _entity = entity,

        _sprite = rt.Sprite(entity:get_sprite_id()),
        _shader = rt.Shader("assets/shaders/priority_queue_element.glsl"),
        _frame = bt.GradientFrame(),

        _stencil = rt.Rectangle(),

        _id_offset_label_visible = false,
        _id_offset_label = {}, -- rt.Label

        _is_selected = false,
        _is_stunned = false,

        _state = bt.EntityState.ALIVE,
        _elapsed = 0
    })
end)

--- @brief
function bt.PriorityQueueElement:set_state(state)
    if self._state ~= state then
        self._state = state
        self:_update_state()
    end
end

--- @brief
function bt.PriorityQueueElement:set_is_stunned(b)
    self._is_stunned = b
    self:_update_state()
end

--- @brief
function bt.PriorityQueueElement:set_is_selected(b)
    self._is_selected = b
    self:_update_state()
end

--- @brief
function bt.PriorityQueueElement:_update_state()
    local frame_color, backdrop_color
    if self._state == bt.EntityState.ALIVE then
        frame_color = rt.settings.battle.priority_queue_element.frame_color
        backdrop_color = rt.settings.battle.priority_queue_element.base_color
        self._sprite:set_color(rt.RGBA(1, 1,1, 1))
    elseif self._state == bt.EntityState.KNOCKED_OUT then
        frame_color = rt.color_lighten(rt.Palette.KNOCKED_OUT, 0.15)
        backdrop_color = rt.Palette.KNOCKED_OUT
        self._sprite:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.knocked_out_shape_alpha))
    elseif self._state == bt.EntityState.DEAD then
        frame_color = rt.settings.battle.priority_queue_element.dead_frame_color
        backdrop_color = rt.settings.battle.priority_queue_element.dead_base_color
        self._sprite:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.dead_shape_alpha))
    end

    if self._is_selected then
        frame_color = rt.Palette.SELECTION
        self._frame:set_gradient_visible(false)
    else
        self._frame:set_gradient_visible(true)
    end

    self._sprite:set_opacity(ternary(not self._is_stunned, 1, 0.4))
    self._id_offset_label:set_opacity(ternary(not self._is_stunned, 1, 0.8))

    self._frame:set_color(frame_color, backdrop_color)
end

--- @override
function bt.PriorityQueueElement:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._sprite:realize()
    self._frame:realize()

    self._id_offset_label = rt.Glyph(
        rt.settings.battle.priority_queue_element.font,
        self._entity:get_id_offset_suffix(),
        {
            is_outlined = true,
            outline_color = rt.Palette.BLACK,
            font_style = rt.FontStyle.BOLD
        }
    )

    self._stencil = rt.Rectangle(0, 0, 1, 1)
    self._stencil:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)

    self:_update_state()
end

--- @override
function bt.PriorityQueueElement:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    -- make shape square
    local min = math.min(width, height)
    x = x + (width - min) / 2
    y = y + (height - min) / 2
    width, height = min, min

    local sprite_w, sprite_h = self._sprite:get_resolution()
    sprite_w = sprite_w * 3
    sprite_h = sprite_h * 3
    local sprite_align_x, sprite_align_y = self._sprite:get_origin()
    local origin_offset_x, origin_offset_y = (0.5 - sprite_align_x) * sprite_w, (0.5 - sprite_align_y) * sprite_h
    self._sprite:fit_into(
        math.floor(x + 0.5 * width - 0.5 * sprite_w + origin_offset_x),
        math.floor(y + 0.5 * height - 0.5 * sprite_h + origin_offset_y),
        sprite_w,
        sprite_h
    )
    self._frame:fit_into(x, y, width, height)

    local label_w, label_h = self._id_offset_label:get_size()
    local label_offset = 0.75
    self._id_offset_label:set_position(
        x + width - label_offset * label_w,
        y + height - label_offset * label_h
    )

    local thickness = rt.settings.battle.priority_queue_element.frame_thickness
    self._stencil:resize(x + thickness, y + thickness, width - 2 * thickness, height - 2 * thickness)
end

--- @override
function bt.PriorityQueueElement:draw()
    if self._is_realized ~= true then return end

    self._frame:draw()

    local stencil_value = meta.hash(bt.PriorityQueueElement) % 255
    rt.graphics.stencil(stencil_value, self._stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
    self._sprite:draw()
    rt.graphics.stencil()
    rt.graphics.set_stencil_test()

    if self._id_offset_label_visible then
        self._id_offset_label:draw()
    end
end

--- @override
function bt.PriorityQueueElement:update(delta)
    self._elapsed = self._elapsed + delta
end

--- @override
function bt.PriorityQueueElement:set_opacity(alpha)
    self._opacity = alpha
    for object in range(self._sprite) do
        object:set_opacity(alpha)
    end
end