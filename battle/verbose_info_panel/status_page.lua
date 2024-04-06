--- @class bt.VerboseInfo.StatusPage
bt.VerboseInfo.StatusPage = meta.new_type("VerboseInfo_StatusPage", rt.Drawable, function(config)
    return meta.new(bt.VerboseInfo.StatusPage, {
        backdrop = bt.Backdrop(),
        -- other members: cf. create_from
    })
end)

--- @brief
function bt.VerboseInfo.StatusPage:create_from(config)
    self.backdrop:realize()
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

    self.duration_label_left = new_label("Duration")
    self.duration_label_right = new_label(number_prefix, ternary(config.max_duration == POSITIVE_INFINITY, "∞", config.max_duration), number_postfix)

    self.effect_label = new_label("<u>Effect</u>: " .. config.description)

    local create_stat_prefix = function(label)
        return "<b>" .. label .. "</b>"
    end

    local function create_offset_label(x)
        return ternary(x > 0, "+", ternary(x == 0, "±", "")) .. tostring(x)
    end

    local function create_factor_label(x)
        if x > 1 then
            return "+" .. tostring(math.round((x - 1) * 100)) .. "%"
        elseif x < 1 then
            return "-" .. tostring(math.round((1 - x) * 100)) .. "%"
        else
            return "±0%"
        end
    end

    local attack_prefix = "<color=ATTACK>"
    local attack_postfix = "</color>"
    self.attack_offset_label_visible = config.attack_offset ~= 0
    if self.attack_offset_label_visible then
        self.attack_offset_label_left = new_label(attack_prefix, create_stat_prefix("ATK"), attack_postfix)
        self.attack_offset_label_right = new_label(number_prefix, attack_prefix, create_offset_label(config.attack_offset), attack_postfix, number_postfix)
    end

    self.attack_factor_label_visible = config.attack_factor ~= 1
    if self.attack_factor_label_visible then
        self.attack_factor_label_left = new_label(attack_prefix, create_stat_prefix("ATK"), attack_postfix)
        self.attack_factor_label_right = new_label(number_prefix, attack_prefix, create_factor_label(config.attack_factor), attack_postfix, number_postfix)
    end

    local defense_prefix = "<color=DEFENSE>"
    local defense_postfix = "</color>"
    self.defense_offset_label_visible = config.defense_offset ~= 0
    if self.defense_offset_label_visible then
        self.defense_offset_label_left = new_label(defense_prefix, create_stat_prefix("DEF"), defense_postfix)
        self.defense_offset_label_right = new_label(number_prefix, defense_prefix, create_offset_label(config.defense_offset), defense_postfix, number_postfix)
    end

    self.defense_factor_label_visible = config.defense_factor ~= 1
    if self.defense_factor_label_visible then
        self.defense_factor_label_left = new_label(defense_prefix, create_stat_prefix("DEF"), defense_postfix)
        self.defense_factor_label_right = new_label(number_prefix, defense_prefix, create_factor_label(config.defense_factor), defense_postfix, number_postfix)
    end

    local speed_prefix = "<color=SPEED>"
    local speed_postfix = "</color>"
    self.speed_offset_label_visible = config.speed_offset ~= 0
    if self.speed_offset_label_visible then
        self.speed_offset_label_left = new_label(speed_prefix, create_stat_prefix("SPD"), speed_postfix)
        self.speed_offset_label_right = new_label(number_prefix, speed_prefix, create_offset_label(config.speed_offset), speed_postfix, number_postfix)
    end

    self.speed_factor_label_visible = config.speed_factor ~= 1
    if self.speed_factor_label_visible then
        self.speed_factor_label_left = new_label(speed_prefix, create_stat_prefix("SPD"), speed_postfix)
        self.speed_factor_label_right = new_label(number_prefix, speed_prefix, create_factor_label(config.speed_factor), speed_postfix, number_postfix)
    end

    self.sprite = rt.Sprite(config.sprite_id)
    self.sprite:realize()
end

--- @brief
function bt.VerboseInfo.StatusPage:reformat(aabb)
    local x, y, width, height = aabb.x, aabb.y, aabb.width, aabb.height
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit

    local sprite_size = 2 * select(1, self.sprite:get_resolution())
    self.name_label:fit_into(current_x, current_y, width - 2 * m - sprite_size - m, height)
    current_y = current_y + select(2, self.name_label:measure()) + m

    local stat_align = current_x + 4 * self.name_label:get_font():get_size()

    self.duration_label_left:fit_into(current_x, current_y, width, height)
    self.duration_label_right:fit_into(math.max(select(1, self.duration_label_left:measure()) + 2 * m, stat_align), current_y, width, height)
    current_y = current_y + select(2, self.duration_label_left:measure())
    current_y = current_y + m

    if self.attack_offset_label_visible then
        self.attack_offset_label_left:fit_into(current_x, current_y, width, height)
        self.attack_offset_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.attack_offset_label_left:measure())
    end

    if self.attack_factor_label_visible then
        self.attack_factor_label_left:fit_into(current_x, current_y, width, height)
        self.attack_factor_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.attack_factor_label_left:measure())
    end

    if self.defense_offset_label_visible then
        self.defense_offset_label_left:fit_into(current_x, current_y, width, height)
        self.defense_offset_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.defense_offset_label_left:measure())
    end

    if self.defense_factor_label_visible then
        self.defense_factor_label_left:fit_into(current_x, current_y, width, height)
        self.defense_factor_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.defense_factor_label_left:measure())
    end

    if self.speed_offset_label_visible then
        self.speed_offset_label_left:fit_into(current_x, current_y, width, height)
        self.speed_offset_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.speed_offset_label_left:measure())
    end

    if self.speed_factor_label_visible then
        self.speed_factor_label_left:fit_into(current_x, current_y, width, height)
        self.speed_factor_label_right:fit_into(stat_align, current_y, width, height)
        current_y = current_y + select(2, self.speed_factor_label_left:measure())
    end

    current_y = current_y + m
    self.effect_label:fit_into(current_x, current_y, width - 2 * m, height)
    current_y = current_y + select(2, self.effect_label:measure())

    x, y, width, height = 0, 0, width, current_y - y
    x = x - 2 * m
    y = y - 2 * m
    width = width
    height = height + math.max(2 * self.name_label:get_font():get_size(), 5 * m)
    self.backdrop:fit_into(x, y, width, height)

    self.sprite:fit_into(x + width - sprite_size - 1 * m, y + 1 * m, sprite_size, sprite_size)
end

--- @brief
function bt.VerboseInfo.StatusPage:draw()
    self.backdrop:draw()
    self.name_label:draw()
    self.duration_label_left:draw()
    self.duration_label_right:draw()
    self.effect_label:draw()
    self.sprite:draw()

    if self.attack_offset_label_visible then
        self.attack_offset_label_left:draw()
        self.attack_offset_label_right:draw()
    end

    if self.attack_factor_label_visible then
        self.attack_factor_label_left:draw()
        self.attack_factor_label_right:draw()
    end

    if self.defense_offset_label_visible then
        self.defense_offset_label_left:draw()
        self.defense_offset_label_right:draw()
    end

    if self.defense_factor_label_visible then
        self.defense_factor_label_left:draw()
        self.defense_factor_label_right:draw()
    end

    if self.speed_offset_label_visible then
        self.speed_offset_label_left:draw()
        self.speed_offset_label_right:draw()
    end

    if self.speed_factor_label_visible then
        self.speed_factor_label_left:draw()
        self.speed_factor_label_right:draw()
    end
end