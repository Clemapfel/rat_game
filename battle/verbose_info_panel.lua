rt.settings.battle.verbose_info = {
    base_color = rt.Palette.GRAY_6,
    frame_color = rt.Palette.GRAY_4,
    frame_thickness = 6,
    corner_radius = 5,

    collider_mass = 15,
    collider_speed = 2000
}

--- @class bt.VerboseInfo
bt.VerboseInfo = meta.new_type("VerboseInfo", rt.Widget, rt.Animation, function()
    return meta.new(bt.VerboseInfo, {
        -- slide animation
        _target_x = 0,
        _world = rt.PhysicsWorld(0, 0),
        _slide_collider = {}, -- rt.RectangleCollider

        _current_page = {}, -- rt.Drawable
        _pages = {}, -- Table<bt.Entity, bt.VerboseInfo.EntityPage / StatusPage / MovePage>
    })
end)

--- @override
function bt.VerboseInfo:realize()
    if self._is_realized then return end
    self._is_realized = true

    self:set_is_animated(true)
end

--- @override
function bt.VerboseInfo:size_allocate(x, y, width, height)
    self._slide_collider = rt.RectangleCollider(self._world, rt.ColliderType.DYNAMIC, x, y, width, height)
    self._target_x = x
    x, y = 0, 0 -- translate in draw

    if meta.isa(self._slide_collider, rt.Collider) then
        self._slide_collider:destroy()
    end
    self._slide_collider = rt.RectangleCollider(self._world, rt.ColliderType.DYNAMIC, x, y, 50, 50)
    self._slide_collider:set_mass(rt.settings.battle.verbose_info.collider_mass)
end

--- @override
function bt.VerboseInfo:draw()
    if self._is_realized then
        local x, y = self._slide_collider:get_position()
        rt.graphics.push()
        rt.graphics.translate(x, y)

        if meta.isa(self._current_page, rt.Drawable) then
            self._current_page:draw()
        end

        rt.graphics.pop()
    end
end

--- @override
function bt.VerboseInfo:update(delta)
    if self._is_realized then
        local collider = self._slide_collider;
        local current_x, current_y = collider:get_centroid()
        local target_x = self._target_x

        local angle = rt.angle(target_x - current_x, 0)
        local magnitude = rt.settings.battle.verbose_info.collider_speed
        local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
        collider:apply_linear_impulse(vx, vy)

        -- increase friction as object gets closer to target, to avoid overshooting
        local distance = rt.magnitude(target_x - current_x, 0)
        local damping = magnitude / (4 * distance)
        collider:set_linear_damping(damping)

        self._world:update(delta)
    end
end

--- @brief
function bt.VerboseInfo:set_is_hidden(b)
    if b == true then
        local w = self:get_bounds().width
        self._target_x = 0 - w - rt.settings.margin_unit
    else
        self._target_x = self:get_bounds().x
    end
end

--- @brief
function bt.VerboseInfo:_create_entity_page(entity, config)
    local page = self._pages[entity]
    if page == nil then
        page = bt.VerboseInfo.EntityPage()
        self._pages[entity] = page
    end
    page:create_from(config)
    page:reformat(self:get_bounds())

    self._current_page = page
end

--- @brief
function bt.VerboseInfo:_create_status_page(status)
    local page = self._pages[status]
    if page == nil then
        page = bt.VerboseInfo.StatusPage()
        self._pages[status] = page
    end
    page:create_from(status)
    page:reformat(self:get_bounds())

    self._current_page = page
end

--- @brief
function bt.VerboseInfo:_create_move_page(move, current_stance)
    local page = self._pages[move]
    if page == nil then
        page = bt.VerboseInfo.MovePage()
        self._pages[move] = page
    end
    page:create_from(move, current_stance)
    page:reformat(self:get_bounds())

    self._current_page = page
end