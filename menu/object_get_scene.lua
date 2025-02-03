rt.settings.menu.object_get_scene = {
    n_shakes_per_second = 0.5,
    reveal_duration = 0.5,
    sprite_scale = 3
}

--- @class mn.ObjectGetScene
mn.ObjectGetScene = meta.new_type("ObjectGetScene", rt.Scene, function(state, ...)
    local out = meta.new(mn.ObjectGetScene, {
        _state = state,
        _objects = {},
        _slots = {},
        _slot_reveal_shader = rt.Shader("menu/object_get_scene_reveal.glsl"),
        _center_y = 0, -- TODO

        _background = rt.Background(),
        _background_overlay_shader = rt.Shader("menu/object_get_scene_overlay.glsl"),
        _background_overlay_mesh = nil, -- rt.VertexShape
        _background_overlay_texture_texture = nil, -- rt.RenderTexture
        _background_active = true,
        _background_elapsed = 0,

        _fireworks = nil, -- mn.Fireworks
        _control_indicator = nil, -- rt.ControlIndicator

        _elapsed = 0,
        _input = rt.InputController(),
    })
    --out:set_objects(...)
    out:set_objects(
        bt.EquipConfig("DEBUG_EQUIP"),
        bt.EquipConfig("DEBUG_EQUIP"),
        bt.MoveConfig("DEBUG_MOVE"),
        bt.ConsumableConfig("DEBUG_CONSUMABLE")
    )
    return out
end)

--- @brief
function mn.ObjectGetScene:set_objects(...)
    for i = 1, select("#", ...) do
        local object = select(i, ...)
        if not (
            meta.isa(object, bt.EquipConfig) or
                meta.isa(object, bt.ConsumableConfig) or
                meta.isa(object, bt.MoveConfig)
        ) then
            rt.error("In mn.ObjectGetScene.set_objects: invalid object of type `" .. meta.typeof(object) .. "`")
        end
    end

    self._objects = {...}
    self:_create_slots()

    if self:get_is_realized() then
        self:reformat()
    end
end

--- @brief
function mn.ObjectGetScene:_create_slots()
    local sprite_scale = rt.settings.menu.object_get_scene.sprite_scale
    local m = rt.settings.margin_unit
    local shake_duration = 1 / rt.settings.menu.object_get_scene.n_shakes_per_second
    local color_duration = rt.settings.menu.object_get_scene.reveal_duration
    local angle_magnitude = 0.05 * math.pi

    self._slots = {}
    for object in values(self._objects) do
        local slot = {
            object = object,
            position_x = 0,
            position_y = 0,

            name = rt.Label("<o><b>" .. object:get_name() .. "</b></o>"),
            sprite = rt.Sprite(object:get_sprite_id()),
            reveal_started = true,
            reveal_animation = rt.TimedAnimation(
                rt.settings.menu.object_get_scene.reveal_duration
            ),
            texture_resolution = {0, 0},
            opacity = 1,

            shake_started = true,
            shake_animation = rt.TimedAnimation(shake_duration,
                -angle_magnitude, angle_magnitude,
                rt.InterpolationFunctions.SINE_WAVE
            ),
            shake_origin_x = 0,
            shake_origin_y = 0,
            angle = 0,

            width = 0,
            height = 0
        }

        slot.name:set_justify_mode(rt.JustifyMode.CENTER)
        for to_realize in range(
            slot.name,
            slot.sprite
        ) do
            to_realize:realize()
        end

        local sprite_w, sprite_h = slot.sprite:measure()
        sprite_w = sprite_w * sprite_scale
        sprite_h = sprite_h * sprite_scale
        slot.sprite:set_minimum_size(sprite_w, sprite_h)
        slot.texture_resolution = {slot.sprite._spritesheet:get_texture_resolution()}

        slot.shake_animation:set_should_loop(true)
        slot.shake_origin_x = 0.5 * sprite_w
        slot.shake_origin_y = 1 * sprite_h

        local name_w, name_h = slot.name:measure()
        slot.width = math.max(sprite_w, name_w)
        slot.height = sprite_h + name_h + m

        slot.sprite:fit_into(0, 0, sprite_w, sprite_h)
        slot.name:fit_into(0, sprite_h + m, sprite_w, POSITIVE_INFINITY)

        table.insert(self._slots, slot)
    end
end

--- @brief
function mn.ObjectGetScene:_reformat_slots(left_x, center_y, width)
    local total_w, n_slots, mean_height = 0, 0, 0
    for slot in values(self._slots) do
        total_w = total_w + slot.width
        mean_height = mean_height + slot.height
        n_slots = n_slots + 1
    end
    mean_height = mean_height / n_slots

    local m = rt.settings.margin_unit
    local slot_m = math.min((width - total_w) / (n_slots - 1), rt.settings.margin_unit)
    local y_offset = -0.25 * mean_height
    local current_x = left_x + 0.5 * width - 0.5 * (total_w + (n_slots - 1) * slot_m)
    local current_y = center_y
    for slot in values(self._slots) do
        local sprite_w, sprite_h = slot.sprite:measure()
        slot.position_x =  current_x + 0.5 * slot.width - 0.5 * sprite_w
        slot.position_y = current_y - 0.5 * sprite_h + y_offset

        current_x = current_x + slot.width + slot_m
    end
end

--- @brief
function mn.ObjectGetScene:_update_slots(delta)
    for slot in values(self._slots) do
        slot.sprite:update(delta)
        slot.name:update(delta)

        if slot.reveal_started then
            slot.reveal_animation:update(delta)
            slot.opacity = slot.reveal_animation:get_value()
            slot.sprite:set_opacity(slot.opacity)
        end

        if slot.shake_started then
            slot.shake_animation:update(delta)
            slot.angle = slot.shake_animation:get_value()
        end
    end
end

--- @brief
function mn.ObjectGetScene:_draw_slots()
    for slot in values(self._slots) do
        love.graphics.push()
        love.graphics.translate(slot.position_x, slot.position_y)
        love.graphics.push()
        love.graphics.translate(slot.shake_origin_x, slot.shake_origin_y)
        love.graphics.rotate(slot.angle)
        love.graphics.translate(-slot.shake_origin_x, -slot.shake_origin_y)

        self._slot_reveal_shader:bind()
        self._slot_reveal_shader:send("value", slot.opacity)
        self._slot_reveal_shader:send("texture_resolution", slot.texture_resolution)
        slot.sprite:draw()
        self._slot_reveal_shader:unbind()
        love.graphics.pop()

        slot.name:draw()
        love.graphics.pop()
    end
end

--- @brief
function mn.ObjectGetScene:realize()
    if self:already_realized() then return end
    
    local w, h = love.graphics.getDimensions()
    local bottom = 0.9 * h
    local top = 0.25 * h
    self._fireworks = mn.Fireworks(
        {0.25 * w, bottom, 0.2 * w, top},
        {0.5 * w, bottom, 0.5 * w, top},
        {0.75 * w, bottom, 0.8 * w, top}
    )

    self._fireworks:realize()
    self._background:set_implementation(rt.Background.CELEBRATION)
    self._background:realize()

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.X then

        elseif which == rt.InputButton.Y then
            self._background:set_implementation(rt.Background.CELEBRATION)
            self._background_overlay_shader:recompile()
            self._slot_reveal_shader:recompile()
        elseif which == rt.InputButton.B then
            self._fireworks:start()
        end
    end)
end

function mn.ObjectGetScene:size_allocate(x, y, width, height)
    if self._background_overlay_texture == nil or (self._background_overlay_texture:get_width() ~= width or self._background_overlay_texture:get_height() ~= height) then
        self._background_overlay_texture = rt.RenderTexture(width, height, 0, rt.TextureFormat.RGBA8)
    end

    local outer_margin = 2 * rt.settings.margin_unit
    local center_y = y + 0.5 * height
    self._center_y = center_y
    self:_reformat_slots(
        outer_margin,
        center_y,
        width - 2 * outer_margin
    )

    self._background_overlay_mesh = rt.VertexRectangle(x, y, width, height)
    self._background:fit_into(x, y, width, height)
    self._fireworks:fit_into(x, y, width, height)
end

--- @brief
function mn.ObjectGetScene:update(delta)
    self._elapsed = self._elapsed + delta

    for entry in values(self._sprites) do
        if entry.shake_animation_start then
            entry.shake_animation:update(delta)
        end
        entry.angle = entry.shake_animation:get_value()

        if entry.color_animation_started then
            entry.color_animation:update(delta)
        end
        entry.color = entry.color_animation:get_value()
    end

    self:_update_slots(delta)
    self._background:update(delta)
    if self._background_active then
        self._background_overlay_shader:send("elapsed", self._elapsed)
    end

    self._fireworks:update(delta)
end

--- @brief
function mn.ObjectGetScene:draw()
    self._background:draw()
    self._background_overlay_texture:bind()
    local black = rt.Palette.BLACK
    self._slot_reveal_shader:send("black", {black.r, black.g, black.b})
    love.graphics.clear(black.r, black.g, black.b, 1)
    rt.graphics.set_blend_mode(rt.BlendMode.SUBTRACT, rt.BlendMode.SUBTRACT)
    love.graphics.setColor(1, 1, 1, 1)
    self._background_overlay_shader:bind()
    self._background_overlay_mesh:draw()
    self._background_overlay_shader:unbind()
    self._background_overlay_texture:unbind()
    rt.graphics.set_blend_mode()
    self._background_overlay_texture:draw()

    self:_draw_slots()

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(0, self._center_y, love.graphics.getWidth(), self._center_y)
    self._fireworks:draw()
end

--- @override
function mn.ObjectGetScene:make_active()
    -- TODO
end

--- @override
function mn.ObjectGetScene:make_inactive()

end