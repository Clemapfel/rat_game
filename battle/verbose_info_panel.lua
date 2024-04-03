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

        -- backdrop & slide animation
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _target_x = 0,
        _world = rt.PhysicsWorld(0, 0),
        _slide_collider = {}, -- rt.RectangleCollider

        _current_page = {}, -- rt.Drawable
        _entity_pages = {}, -- Table<bt.Entity, Table>
    })
end)

--- @override
function bt.VerboseInfo:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.verbose_info.base_color)
    self._frame:set_color(rt.settings.battle.verbose_info.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    local frame_thickness = rt.settings.battle.verbose_info.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    self._frame:set_line_width(frame_thickness)
    self._frame_outline:set_line_width(frame_outline_thickness)

    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.verbose_info.corner_radius)
    end

    self:set_is_animated(true)
end

--- @override
function bt.VerboseInfo:size_allocate(x, y, width, height)
    self._slide_collider = rt.RectangleCollider(self._world, rt.ColliderType.DYNAMIC, x, y, width, height)
    self._target_x = x
    x, y = 0, 0 -- translate in draw

    self._backdrop:resize(x, y, width, height)
    local frame_thickness = rt.settings.battle.verbose_info.frame_thickness
    local frame_aabb = rt.AABB(
    x + 0.5 * frame_thickness,
    y + 0.5 * frame_thickness,
    width - frame_thickness,
    height - frame_thickness
    )
    self._frame:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
    self._frame_outline:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)

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

        self._backdrop:draw()
        --self._frame_outline:draw()
        --self._frame:draw()

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

-- #### Entity ###

bt.VerboseInfo.EntityPage = meta.new_type("VerboseInfo_EntityPage", rt.Drawable, function(config)
    return meta.new(bt.VerboseInfo.EntityPage)
end)

function bt.VerboseInfo.EntityPage:create_from(config)
    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default_small, rt.settings.font.default_mono_small)
        out:realize()
        out:set_alignment(rt.Alignment.START)
        return out
    end

    self.name_label = new_label("<u><b>", config.name, "</b></u>")

    local grey = "GRAY_3"
    local number_prefix = "<b><color=" .. grey .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    local create_stat_prefix = function(label)
        return "<b>" .. label .. "</b>"
    end

    local hp_prefix = create_stat_prefix("HP")
    self.hp_label_left = new_label(hp_prefix)
    if config.is_dead then
        self.hp_label_right = new_label("<color=GRAY_02>DEAD</color>")
    elseif config.is_knocked_out then
        self.hp_label_right = new_label("<color=RED>KNOCKED OUT</color>")
    else
        if config.should_censor then
            self.hp_label_right = new_label(number_prefix, "? / ?", number_postfix)
        else
            self.hp_label_right = new_label(number_prefix, config.hp_current, " / ", config.hp_base, number_postfix)
        end
    end

    local arrow_right = " → "
    local up_indicator = "(+)"
    local down_indicator = "(-)"

    self.attack_label_left = new_label(create_stat_prefix("ATK"))
    if config.should_censor ~= true then
        if config.attack_preview == nil then
            self.attack_label_right = new_label(number_prefix, config.attack_current, number_postfix)
        else
            self.attack_label_right = new_label(number_prefix, config.attack_current, arrow_right, config.attack_preview, number_postfix)
        end
    else
        if config.attack_preview == nil then
            self.attack_label_right = new_label(number_prefix, "?", number_postfix)
        else
            self.attack_label_right = new_label(number_prefix, "?", arrow_right, "?", number_postfix)
        end
    end

    self.defense_label_left = new_label(create_stat_prefix("DEF"))
    if config.should_censor ~= true then
        if config.defense_preview == nil then
            self.defense_label_right = new_label(number_prefix, config.defense_current, number_postfix)
        else
            self.defense_label_right = new_label(number_prefix, config.defense_current, arrow_right, config.defense_preview, number_postfix)
        end
    else
        if config.defense_preview == nil then
            self.defense_label_right = new_label(number_prefix, "?", number_postfix)
        else
            self.defense_label_right = new_label(number_prefix, "?", arrow_right, "?", number_postfix)
        end
    end

    self.speed_label_left = new_label(create_stat_prefix("SPD"))
    if config.should_censor ~= true then
        if config.speed_preview == nil then
            self.speed_label_right = new_label(number_prefix, config.speed_current, number_postfix)
        else
            self.speed_label_right = new_label(number_prefix, config.speed_current, arrow_right, config.speed_preview, number_postfix)
        end
    else
        if config.speed_preview == nil then
            self.speed_label_right = new_label(number_prefix, "?", number_postfix)
        else
            self.speed_label_right = new_label(number_prefix, "?", arrow_right, "?", number_postfix)
        end
    end

    self.stance_label_left = new_label("<b>Stance</b>")
    self.stance_label_right = new_label(number_prefix, "<o><color=" .. config.stance.color_id .. ">" .. config.stance:get_name() .. "</color></o>", number_postfix)

    self.status_label_left = new_label("<u><b>Status</b></u>")

    if is_empty(config.status) then
        self.status_label_right = new_label(number_prefix .. "(None)" .. number_postfix)
    else
        self.status_label_right = new_label("")
    end

    local realize = function(x)
        x:realize()
        return x
    end

    self.status_items = {}
    for status, elapsed in pairs(config.status) do
        local max = status.max_duration
        local n_left_str = number_prefix .. "</mono><b>∞</b><mono>" .. number_postfix

        if max ~= POSITIVE_INFINITY then
            local current = elapsed
            local n_left = max - current
            n_left_str = number_prefix .. elapsed .. number_postfix .. " turns left"
        end

        table.insert(self.status_items, {
            sprite = realize(rt.Sprite(status.sprite_id)),
            left = new_label(status.name),
            right = new_label(n_left_str)
        })
    end
end

function bt.VerboseInfo.EntityPage:reformat(aabb)
    local x, y, width, height = aabb.x, aabb.y, aabb.width, aabb.height
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit

    self.name_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self.name_label:measure()) + m

    local stat_align = current_x + 0.25 * width

    self.stance_label_left:fit_into(current_x, current_y, width, height)
    self.stance_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.stance_label_left:measure())

    current_y = current_y + m

    self.hp_label_left:fit_into(current_x, current_y, width, height)
    self.hp_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.hp_label_left:measure())

    self.attack_label_left:fit_into(current_x, current_y, width, height)
    self.attack_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.attack_label_left:measure())

    self.defense_label_left:fit_into(current_x, current_y, width, height)
    self.defense_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.defense_label_left:measure())

    self.speed_label_left:fit_into(current_x, current_y, width, height)
    self.speed_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.speed_label_left:measure())

    current_y = current_y + m

    self.status_label_left:fit_into(current_x, current_y, width, height)
    self.status_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self.status_label_left:measure()) + m

    for item in values(self.status_items) do
        local sprite_size = select(2, item.sprite:measure())
        item.sprite:set_horizontal_alignment(rt.Alignment.START)
        item.sprite:set_vertical_alignment(rt.Alignment.CENTER)
        item.sprite:fit_into(current_x + m, current_y, sprite_size, sprite_size)

        local label_height = select(2, item.left:measure())
        local label_y = current_y + 0.5 * sprite_size - 0.25 * label_height
        item.left:fit_into(current_x + sprite_size + 2 * m, label_y, width, sprite_size)
        item.right:fit_into(current_x + width - 2 * stat_align, label_y, width, sprite_size)
        current_y = current_y + math.max(sprite_size, label_height)
    end
end

function bt.VerboseInfo.EntityPage:draw()


    self.name_label:draw()

    for drawable in range(
        self.hp_label_left,
        self.hp_label_right,
        self.attack_label_left,
        self.attack_label_right,
        self.defense_label_left,
        self.defense_label_right,
        self.speed_label_left,
        self.speed_label_right,
        self.stance_label_left,
        self.stance_label_right,
        self.status_label_left,
        self.status_label_right
    ) do
        drawable:draw()
    end

    for item in values(self.status_items) do
        item.sprite:draw()
        item.left:draw()
        item.right:draw()
    end
end

--- @brief
function bt.VerboseInfo:_create_entity_page(entity, config)
    config = which(config, entity)
    --[[
    name, knocked_out / dead
    hp, hp_max, exact, precentage, censored
    attack, attack_preview, attack_censored,
    " defense
    " speed
    stance
    status


    |                               |
    | Friendly Boulder (100 / 123)
    ]]--

    local page = self._entity_pages[entity]
    if page == nil then
        page = bt.VerboseInfo.EntityPage()
        self._entity_pages[entity] = page
    end
    page:create_from(config)
    page:reformat(self:get_bounds())

    -- TODO
    if not meta.isa(self._current_page, rt.Drawable) then
        self._current_page = self._entity_pages[entity]
    end
end

-- ### Status ###

--- @brief
function bt.VerboseInfo:_create_status_page()

end

-- ### Move ###

--- @brief
function bt.VerboseInfo:_create_move_page()

end