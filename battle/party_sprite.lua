
--- @class bt.PartySprite
bt.PartySprite = meta.new_type("BattlePartySprite", bt.EntitySprite, function(entity)
    local entity_id_to_sprite_id = {
        ["RAT"] = "battle/rat_battle",
        ["GIRL"] = "battle/girl_battle",
        ["MC"] = "battle/mc_battle",
        ["PROF"] = "battle/prof_battle",
        ["WILDCARD"] = "battle/wildcard_battle"
    }

    return meta.new(bt.PartySprite, {
        _frame = rt.Frame(),

        _health_bar = bt.HealthBar(0, entity:get_hp_base(), entity:get_hp()),
        _speed_value = bt.SpeedValue(entity:get_speed()),
        _status_consumable_bar = bt.OrderedBox(),
        _name = rt.Label("<o>" .. entity:get_name() .. "</o>"),

        _gradient_visible = true,
        _gradient = rt.VertexRectangle(0, 0, 1, 1),

        _sprite = rt.Sprite(entity_id_to_sprite_id[entity:get_id()]),

        _snapshot = rt.RenderTexture(),
        _snapshot_position_x = 0,
        _snapshot_position_y = 0,

        _stunned_animation = bt.StunnedParticleAnimation()
    })
end)

--- @override
function bt.PartySprite:realize()
    if self:already_realized() then return end

    self._frame:realize()
    self._health_bar:realize()
    self._speed_value:realize()
    self._status_consumable_bar:realize()
    self._sprite:realize()

    self._name:set_justify_mode(rt.JustifyMode.RIGHT)
    self._name:realize()

    self._stunned_animation:realize()

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

    local label_w, label_h = self._name:measure()
    self._name:fit_into(x, current_y - label_h, POSITIVE_INFINITY, POSITIVE_INFINITY)
    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(x + width - xm - speed_value_w, current_y - label_h - speed_value_h + 0.5 * speed_value_h + 0.5 * label_h)
    current_y = current_y - label_h - ym

    local hp_bar_height = label_h
    local hp_bar_bounds = rt.AABB(x + xm, current_y - hp_bar_height, width - 2 * xm, hp_bar_height)
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

    local consumable_aabb = rt.AABB(x + xm, frame_aabb.y - hp_bar_height, frame_aabb.width - 2 * xm, hp_bar_height)
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
    local stunned_animation_h = sprite_w * rt.settings.battle.enemy_sprite.stunned_animation_width_to_height_ratio
    self._stunned_animation:fit_into(
        self._snapshot_position_x,
        self._snapshot_position_y - 0.5 * stunned_animation_h,
        sprite_w,
        stunned_animation_h
    )
end

--- @override
function bt.PartySprite:draw()
    if self._is_visible ~= true then return end

    self._frame:draw()
    self._snapshot:draw(self._snapshot_position_x, self._snapshot_position_y)

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

    self._name:draw()

    if self._speed_visible then
        self._speed_value:draw()
    end

    if self._health_visible then
        self._health_bar:draw()
    end

    if self._status_visible then
        self._status_consumable_bar:draw()
    end

    if self._is_stunned then
        self._stunned_animation:draw()
    end
end

--- @override
function bt.PartySprite:update(delta)
    self._health_bar:update(delta)
    self._speed_value:update(delta)
    self._status_consumable_bar:update(delta)

    local before = self._sprite:get_frame()
    self._sprite:update(delta)
    if self._sprite:get_frame() ~= before then
        self._snapshot:bind()
        self._sprite:draw()
        self._snapshot:unbind()
    end

    if self._is_stunned then
        self._stunned_animation:update(delta)
    end
end

--- @override
function bt.PartySprite:set_selection_state(state)
    self._frame:set_selection_state(state)
    self._gradient_visible = state ~= rt.SelectionState.ACTIVE
end

--- @override
function bt.PartySprite:get_position()
    local frame_x, frame_y, frame_w, frame_h = rt.aabb_unpack(self._frame:get_bounds())
    local sprite_x, sprite_y, sprite_w, sprite_h = rt.aabb_unpack(self._sprite:get_bounds())
    return frame_x, frame_y - sprite_h
end

--- @override
function bt.PartySprite:measure()
    local frame_x, frame_y, frame_w, frame_h = rt.aabb_unpack(self._frame:get_bounds())
    local sprite_x, sprite_y, sprite_w, sprite_h = rt.aabb_unpack(self._sprite:get_bounds())

    return frame_w, frame_y + frame_h - sprite_y
end