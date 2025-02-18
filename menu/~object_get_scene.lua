rt.settings.menu.object_get_scene = {
    n_shakes_per_second = 0.5,
    reveal_duration = 0.5
}

--- @class mn.ObjectGetScene
mn.ObjectGetScene = meta.new_type("ObjectGetScene", rt.Scene, function(state)
    return meta.new(mn.ObjectGetScene, {
        _state = state,
        _objects = {
            bt.MoveConfig("DEBUG_MOVE"),
            bt.ConsumableConfig("DEBUG_CONSUMABLE")
        },

        _sprites = {},
        _background_rainbow_shader = rt.Shader("menu/object_get_scene_rainbow.glsl"),
        _background_overlay_shader = rt.Shader("menu/object_get_scene_overlay.glsl"),
        _background_overlay = nil, -- rt.RenderTexture
        _background_mesh = nil, -- rt.VertexRectangle
        _background_active = false,
        _background_elapsed = 0,

        _reveal_animation = rt.TimedAnimation(1.5, 0, 0.8, rt.InterpolationFunctions.LINEAR),

        _input = rt.InputController(),

    })
end, {
    _reveal_shader = rt.Shader("menu/object_get_scene_reveal.glsl")
})

--- @brief
function mn.ObjectGetScene:realize()
    if self:already_realized() then return end

    local black = rt.Palette.BLACK
    self._reveal_shader:send("black", {black.r, black.g, black.b})

    local shake_duration = 1 / rt.settings.menu.object_get_scene.n_shakes_per_second
    local color_duration = rt.settings.menu.object_get_scene.reveal_duration
    local angle_magnitude = 0.05 * math.pi
    for object in values(self._objects) do
        local sprite = rt.Sprite(object:get_sprite_id())
        sprite:realize()
        local sprite_w, sprite_h = sprite:measure()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        sprite:fit_into(0, 0, sprite_w, sprite_h)
        table.insert(self._sprites, {
            sprite = sprite,
            sprite_w = sprite_w,
            sprite_h = sprite_h,
            x = 0.5 * love.graphics.getWidth() - 0.5 * sprite_w,
            y = 0.5 * love.graphics.getHeight() - 0.5 * sprite_h,
            shake_animation = rt.TimedAnimation(shake_duration, -angle_magnitude, angle_magnitude, rt.InterpolationFunctions.SINE_WAVE),
            shake_animation_start = true,
            center_x = 0.5 * sprite_w,
            center_y = 1 * sprite_h,
            angle = 0,
            color = 0,
            color_animation = rt.TimedAnimation(color_duration, 0, 1, rt.InterpolationFunctions.LINEAR),
            color_animation_started = true,

            slot_mesh_top = nil, -- rt.VertexRectangle
            slot_mesh_bottom = nil, -- rt.VertexRectangle
            slots_visible = true
        })
    end

    local w, h = love.graphics.getDimensions()
    local bottom = 0.9 * h
    local top = 0.25 * h
    self._fireworks = mn.Fireworks(
        {0.25 * w, bottom, 0.2 * w, top},
        {0.5 * w, bottom, 0.5 * w, top},
        {0.75 * w, bottom, 0.8 * w, top}
    )

    self._fireworks:realize()

    local target = rt.Texture("assets/sprites/why.png")
    self._target = target
    self._target_scale = 5
    self._target_opacity = 0

    self._sprite_morph = mn.SpriteMorph(target)
    self._sprite_morph:realize()

    self._sprite_morph:signal_connect("done", function(_)
        self._background_active = true
        self._fireworks:start()
    end)

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.X then
            self._background_active = false
            self._reveal_animation:reset()
            self._background_elapsed = 0
            self._target_opacity = 0
            self._sprite_morph:start()
        elseif which == rt.InputButton.Y then
            self._background_rainbow_shader:recompile()
            self._background_overlay_shader:recompile()
        elseif which == rt.InputButton.B then
            self._fireworks:start()
        end
    end)
end

function mn.ObjectGetScene:size_allocate(x, y, width, height)
    local total_w, max_h, max_w = 0, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local n_sprites = 0
    for entry in values(self._sprites) do
        total_w = total_w + entry.sprite_w
        max_h = math.max(max_h, entry.sprite_h)
        max_w = math.max(max_w, entry.sprite_w)
        n_sprites = n_sprites + 1
    end

    local slot_h = 2 * max_h
    local slot_w = max_w

    local black = rt.Palette.BLACK
    local non_black = rt.RGBA(black.r, black.g, black.b, 0)

    local margin = math.max((0.5 * width - total_w) / (n_sprites - 1), rt.settings.margin_unit)
    margin = 0
    local current_x = x + 0.5 * width - 0.5 * total_w
    local current_y = y + 0.5 * height
    for entry in values(self._sprites) do
        entry.x = current_x
        entry.y = current_y - 0.5 * entry.sprite_h

        entry.slot_mesh_bottom = rt.VertexRectangle(entry.x, entry.y + 0.5 * entry.sprite_w, slot_w, slot_h)
        entry.slot_mesh_top = rt.VertexRectangle(entry.x, entry.y + 0.5 * entry.sprite_w - slot_h, slot_w, slot_h)

        entry.slot_mesh_bottom:set_vertex_color(1, black)
        entry.slot_mesh_bottom:set_vertex_color(2, black)
        entry.slot_mesh_bottom:set_vertex_color(3, non_black)
        entry.slot_mesh_bottom:set_vertex_color(4, non_black)

        entry.slot_mesh_top:set_vertex_color(1, non_black)
        entry.slot_mesh_top:set_vertex_color(2, non_black)
        entry.slot_mesh_top:set_vertex_color(3, black)
        entry.slot_mesh_top:set_vertex_color(4, black)

        entry.slots_visible = true
        current_x = current_x + entry.sprite_w + margin
    end

    self._background_mesh = rt.VertexRectangle(x, y, width, height)
    self._background_overlay = rt.RenderTexture(width, height, 0, rt.TextureFormat.RGBA8)

    self._fireworks:fit_into(x, y, width, height)
    self._sprite_morph:fit_into(x, y, width, height)
end

--- @brief
function mn.ObjectGetScene:update(delta)
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

    if self._background_active then
        self._background_elapsed = self._background_elapsed + delta
        self._background_rainbow_shader:send("elapsed", self._background_elapsed)
        self._background_overlay_shader:send("elapsed", self._background_elapsed)

        self._reveal_animation:update(delta)
        self._target_opacity = self._reveal_animation:get_value()
    end

    self._fireworks:update(delta)
    self._sprite_morph:update(delta)
end

--- @brief
function mn.ObjectGetScene:draw()
    self._background_rainbow_shader:bind()
    self._background_mesh:draw()
    self._background_rainbow_shader:unbind()

    self._background_overlay:bind()
    love.graphics.clear(0, 0, 0, 1)
    rt.graphics.set_blend_mode(rt.BlendMode.SUBTRACT, rt.BlendMode.SUBTRACT)
    love.graphics.setColor(1, 1, 1, 1)
    self._background_overlay_shader:bind()
    self._background_mesh:draw()
    self._background_overlay_shader:unbind()

    self._sprite_morph:draw()
    rt.graphics.set_blend_mode(nil)
    self._background_overlay:unbind()
    self._background_overlay:draw()


    love.graphics.push()
    love.graphics.translate(
        0.5 * self._bounds.width - 0.5 * self._target:get_width() * self._target_scale,
        0.5 * self._bounds.height - 0.5 * self._target:get_height() * self._target_scale
    )
    love.graphics.scale(self._target_scale, self._target_scale)
    love.graphics.setColor(1, 1, 1, self._target_opacity)
    love.graphics.draw(self._target._native)

    love.graphics.pop()
    self._fireworks:draw()

    --[[
    for entry in values(self._sprites) do
        love.graphics.push()
        love.graphics.origin()

        if entry.slots_visible then
            entry.slot_mesh_top:draw()
            entry.slot_mesh_bottom:draw()
        end

        self._reveal_shader:bind()
        love.graphics.translate(entry.x, entry.y)
        love.graphics.translate(entry.center_x, entry.center_y)
        love.graphics.rotate(entry.angle)
        love.graphics.translate(-entry.center_x, -entry.center_y)
        self._reveal_shader:send("color", entry.color)
        entry.sprite:draw()
        self._reveal_shader:unbind()

        love.graphics.pop()
    end
    ]]--

    self._background_overlay_shader:bind()
    self._background_mesh:draw()
    self._background_overlay_shader:unbind()
end

--- @override
function mn.ObjectGetScene:make_active()
    -- TODO
end

--- @override
function mn.ObjectGetScene:make_inactive()

end