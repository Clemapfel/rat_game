--- @class bt.PartySprite
bt.PartySprite = meta.new_type("PartySprite", bt.EntitySprite, function(entity)
    return meta.new(bt.PartySprite, {
        _entity = entity,
        _sprite_id = entity:get_config():get_sprite_id(),
        _name = rt.Label("<o><b>" .. entity:get_name() .. "</b></o>"),
        _frame = rt.Frame(),
        _gradient = rt.VertexRectangle(0, 0, 1, 1),
        _gradient_visible = true,
        _final_bounds = rt.AABB(0, 0, 1, 1),

        _move_choice_sprite = nil, -- rt.Sprite
        _move_choice_sprite_aabb = rt.AABB(0, 0, 1, 1)
    })
end)

--- @override
function bt.PartySprite:realize()
    if self:already_realized() then return end
    self:_realize_super(self._sprite_id)

    self._name:realize()
    self._frame:realize()

    local top_color = rt.RGBA(1, 1, 1, 1)
    local bottom_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    self._gradient:set_vertex_color(1, top_color)
    self._gradient:set_vertex_color(2, top_color)
    self._gradient:set_vertex_color(3, bottom_color)
    self._gradient:set_vertex_color(4, bottom_color)
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local xm, ym = rt.settings.margin_unit, rt.settings.margin_unit
    local frame_thickness = self._frame:get_thickness()
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    local total_frame_thickness = frame_thickness + 2 * frame_outline_thickness
    local current_y = y + height - ym

    local bar_h = rt.settings.battle.entity_sprite.bar_height

    local label_w, label_h = self._name:measure()
    self._name:fit_into(x + xm, current_y - label_h, POSITIVE_INFINITY) -- always one line
    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(x + width - xm, current_y - label_h - speed_value_h + 0.5 * speed_value_h + 0.5 * label_h)
    current_y = current_y - label_h - 0.5 * ym

    local hp_bar_height = label_h
    local hp_bar_bounds = rt.AABB(x + xm, current_y - hp_bar_height, width - 2 * xm, bar_h)
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - hp_bar_bounds.height - ym

    local backdrop_bounds = rt.AABB(x, current_y, width, y + height - current_y)
    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:fit_into(frame_aabb)
    self._gradient:reformat(
        frame_aabb.x, frame_aabb.y,
        frame_aabb.x + frame_aabb.width, frame_aabb.y,
        frame_aabb.x + frame_aabb.width, frame_aabb.y + frame_aabb.height,
        frame_aabb.x, frame_aabb.y + frame_aabb.height
    )

    local consumable_aabb = rt.AABB(x + xm, frame_aabb.y - hp_bar_height, frame_aabb.width - 2 * xm, bar_h)
    self._status_consumable_bar:fit_into(consumable_aabb)

    local sprite_overlap = 0.3;
    local sprite_w, sprite_h = self._sprite:get_resolution()
    self._sprite:fit_into(
        0, 0,
        sprite_w,
        sprite_h
    )

    self._snapshot_position_x = frame_aabb.x + 0.5 * frame_aabb.width - 0.5 * sprite_w - 0.25 * frame_aabb.width
    self._snapshot_position_y = frame_aabb.y - (1 - sprite_overlap) * sprite_h

    local current_w, current_h = self._snapshot:get_size()
    if current_w ~= sprite_w or current_h ~= sprite_h then
        self._snapshot = rt.RenderTexture(sprite_w, sprite_h)
        self._snapshot:bind()
        self._sprite:draw()
        self._snapshot:unbind()
    end

    local stunned_animation_w = sprite_w
    local stunned_animation_h = sprite_w * rt.settings.battle.stunned_particle_animation.height_to_width
    self._stunned_animation:fit_into(
        self._snapshot_position_x,
        self._snapshot_position_y - 0.5 * stunned_animation_h,
        sprite_w,
        stunned_animation_h
    )

    self._final_bounds = rt.AABB(
        frame_aabb.x - frame_outline_thickness,
        self._snapshot_position_y,
        frame_aabb.width + 2 * frame_outline_thickness,
        (y + height) - self._snapshot_position_y + 2 * frame_outline_thickness
    )
end

--- @override
function bt.PartySprite:draw()
    if self._snapshot_visible then
        self:draw_snapshot()
    end

    if self._ui_visible then
        self._frame:draw()

        if self._gradient_visible then
            local value = meta.hash(self) % 254 + 1
            rt.graphics.stencil(value, function()
                self._frame:_draw_frame()
            end)
            rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, value)
            rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
            self._gradient:draw()
            rt.graphics.set_stencil_test()
            rt.graphics.set_blend_mode()
        end

        for widget in range(
            self._health_bar,
            self._speed_value,
            self._status_consumable_bar,
            self._name:draw()
        ) do
            widget:draw()
        end
    end
end

--- @override
function bt.PartySprite:update(delta)
    self:_update_super(delta)
end

--- @override
function bt.PartySprite:set_selection_state(state)
    self._selection_state = state
    self._frame:set_selection_state(state)
    self._gradient_visible = state ~= rt.SelectionState.ACTIVE
    local opacity = ternary(state == rt.SelectionState.UNSELECTED, 0.5, 1)
    for widget in range(
        self._status_consumable_bar,
        self._health_bar,
        self._speed_value,
        self._name
    ) do
        widget:set_opacity(opacity)
    end
end

--- @override
function bt.PartySprite:measure()
    return self._final_bounds.width, self._final_bounds.height
end

--- @override
function bt.PartySprite:get_position()
    return self._final_bounds.x, self._final_bounds.y
end

--- @override
function bt.PartySprite:get_sprite_selection_node()
    local out = rt.SelectionGraphNode(self._frame:get_bounds())
    out.object = self._entity
    return out
end