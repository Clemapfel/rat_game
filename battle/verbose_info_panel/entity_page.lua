--- @class bt.VerboseInfo.EntityPage
bt.VerboseInfo.EntityPage = meta.new_type("VerboseInfo_EntityPage", rt.Drawable, function(config)
    return meta.new(bt.VerboseInfo.EntityPage, {
        backdrop = bt.Backdrop(),
        -- other members: cf. create_from
    })
end)

function bt.VerboseInfo.EntityPage:create_from(config)
    --[[
    EXAMPLE:
    entity_config = {
        name = "Overly Longly Named Boulder",
        hp_current = entity:get_hp(),
        hp_base = entity:get_hp_base(),
        should_censor = false,
        attack_current = entity.attack_base,
        attack_preview = nil,
        defense_current = entity.defense_base,
        defense_preview = nil,
        speed_current = entity.speed_base,
        speed_preview = nil,
        status = {
            [bt.Status("TEST")] = 2,
            [bt.Status("OTHER_TEST")] = 3
        },
        stance = bt.Stance("TEST")
    }
    ]]--

    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default, rt.settings.font.default_mono)
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

    local hp_prefix = "<color=HP>"
    local hp_postfix = "</color>"
    self.hp_label_left = new_label(hp_prefix, create_stat_prefix("HP"), hp_postfix)
    if config.is_dead then
        self.hp_label_right = new_label("<color=GRAY_02>DEAD</color>")
    elseif config.is_knocked_out then
        self.hp_label_right = new_label("<color=RED>KNOCKED OUT</color>")
    else
        if config.should_censor then
            self.hp_label_right = new_label(number_prefix, hp_prefix, "? / ?", hp_postfix, number_postfix)
        else
            self.hp_label_right = new_label(number_prefix, hp_prefix, config.hp_current, " / ", config.hp_base, hp_postfix, number_postfix)
        end
    end

    local arrow_right = " → <u><b>"
    local arrow_right_postfix = "</u></b>"

    local attack_prefix = "<color=ATTACK>"
    local attack_postfix = "</color>"
    self.attack_label_left = new_label(attack_prefix, create_stat_prefix("ATK"), attack_postfix)
    if config.should_censor ~= true then
        if config.attack_preview == nil then
            self.attack_label_right = new_label(number_prefix, attack_prefix, config.attack_current, attack_postfix, number_postfix)
        else
            self.attack_label_right = new_label(number_prefix, attack_prefix, config.attack_current, arrow_right, config.attack_preview, arrow_right_postfix, attack_postfix, number_postfix)
        end
    else
        if config.attack_preview == nil then
            self.attack_label_right = new_label(number_prefix, attack_prefix, "?", attack_postfix, number_postfix)
        else
            self.attack_label_right = new_label(number_prefix, attack_prefix, "?", arrow_right, "?", arrow_right_postfix, attack_postfix, number_postfix)
        end
    end

    local defense_prefix = "<color=DEFENSE>"
    local defense_postfix = "</color>"
    self.defense_label_left = new_label(defense_prefix, create_stat_prefix("DEF"), defense_postfix)
    if config.should_censor ~= true then
        if config.defense_preview == nil then
            self.defense_label_right = new_label(number_prefix, defense_prefix, config.defense_current, defense_postfix, number_postfix)
        else
            self.defense_label_right = new_label(number_prefix, defense_prefix, config.defense_current, arrow_right, config.defense_preview, arrow_right_postfix, defense_postfix, number_postfix)
        end
    else
        if config.defense_preview == nil then
            self.defense_label_right = new_label(number_prefix, defense_prefix, "?", defense_postfix, number_postfix)
        else
            self.defense_label_right = new_label(number_prefix, defense_prefix, "?", arrow_right, "?", arrow_right_postfix, defense_postfix, number_postfix)
        end
    end

    local speed_prefix = "<color=SPEED>"
    local speed_postfix = "</color>"
    self.speed_label_left = new_label(speed_prefix, create_stat_prefix("SPD"), speed_postfix)
    if config.should_censor ~= true then
        if config.speed_preview == nil then
            self.speed_label_right = new_label(number_prefix, speed_prefix, config.speed_current, speed_postfix, number_postfix)
        else
            self.speed_label_right = new_label(number_prefix, speed_prefix, config.speed_current, arrow_right, config.speed_preview, arrow_right_postfix, speed_postfix, number_postfix)
        end
    else
        if config.speed_preview == nil then
            self.speed_label_right = new_label(number_prefix, speed_prefix, "?", speed_postfix, number_postfix)
        else
            self.speed_label_right = new_label(number_prefix, speed_prefix, "?", arrow_right, "?", arrow_right_postfix, speed_postfix, number_postfix)
        end
    end

    local realize = function(x)
        x:realize()
        return x
    end

    self.stance_sprite = realize(rt.Sprite(config.stance.sprite_id))
    self.stance_sprite:set_animation(config.stance.sprite_index)

    self.stance_label_left = new_label("Stance")
    self.stance_label_right = new_label(number_prefix, number_postfix)--"<color=" .. config.stance.color_id .. ">" .. config.stance:get_name() .. "</color>", number_postfix)

    self.status_label_left = new_label("<u><b>Status</b></u>")

    if is_empty(config.status) then
        self.status_label_right = new_label(number_prefix .. "(None)" .. number_postfix)
    else
        self.status_label_right = new_label("")
    end

    self.status_items = {}
    for status, elapsed in pairs(config.status) do
        local max = status.max_duration
        local n_left_str = number_prefix .. "</mono><b>∞</b><mono>" .. number_postfix

        if max ~= POSITIVE_INFINITY then
            local current = elapsed
            local n_left = max - current
            n_left_str = number_prefix .. "<b>" .. elapsed .. "</b>" .. number_postfix .. " turns left"
        end

        table.insert(self.status_items, {
            sprite = realize(rt.Sprite(status.sprite_id)),
            left = new_label(status.name),
            right = new_label(n_left_str)
        })
    end

    self.backdrop:realize()
end

function bt.VerboseInfo.EntityPage:reformat(aabb)
    local x, y, width, height = aabb.x, aabb.y, aabb.width , aabb.height

    local once = true
    ::restart::

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit

    self.name_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self.name_label:measure()) + m

    local stat_align = current_x + 4 * self.name_label:get_font():get_size()

    local stance_sprite_size = select(2, self.stance_sprite:measure())
    local stance_label_height = select(2, self.stance_label_left:measure())
    local stance_label_y = current_y + 0.5 * stance_sprite_size - 0.5 * stance_label_height
    self.stance_label_left:fit_into(current_x, stance_label_y, width, height)
    self.stance_label_right:fit_into(stat_align, stance_label_y, width, height)
    self.stance_sprite:fit_into(stat_align + stance_sprite_size, current_y, stance_sprite_size, stance_sprite_size)

    current_y = current_y + stance_sprite_size
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

    local max_width = 0
    for item in values(self.status_items) do
        local sprite_size = select(2, item.sprite:measure())
        item.sprite:set_horizontal_alignment(rt.Alignment.START)
        item.sprite:set_vertical_alignment(rt.Alignment.CENTER)
        item.sprite:fit_into(current_x + m, current_y, sprite_size, sprite_size)

        -- run resize twice, to properly gaige label height after wrapping
        local label_height = select(2, item.left:measure())
        local label_y = current_y + 0.5 * sprite_size - 0.25 * label_height
        local label_left_width = 2 * stat_align + m
        item.left:fit_into(current_x + sprite_size + 2 * m, label_y, label_left_width - 4 * m, sprite_size)
        item.right:fit_into(label_left_width, label_y,  label_left_width - 4 * m, sprite_size)

        -- max width will be reached here
        local right_bounds = item.right:get_bounds()
        max_width = math.max(max_width, right_bounds.x + right_bounds.width - current_x)
        current_y = current_y + math.max(sprite_size, select(2, item.left:measure()))
    end

    -- restart size negotiation
    if max_width > width and once then
        once = false
        width = max_width
        goto restart
    end

    x, y, width, height = 0, 0, max_width, current_y - y

    x = x - 2 * m
    y = y - 2 * m
    width = width + 4 * m
    height = height + math.max(2 * self.name_label:get_font():get_size(), 5 * m)
    self.backdrop:fit_into(x, y, width, height)
end

function bt.VerboseInfo.EntityPage:draw()
    self.backdrop:draw()
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
        self.stance_sprite,
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
