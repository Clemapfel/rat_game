--- @class bt.VerboseInfo.MovePage
bt.VerboseInfo.MovePage = meta.new_type("VerboseInfo_MovePage", rt.Drawable, function(config)
    return meta.new(bt.VerboseInfo.MovePage, {
        backdrop = bt.Backdrop(),
        -- other members: cf. create_from
    })
end)

--- @brief
function bt.VerboseInfo.MovePage:create_from(config, current_stance)

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

    self.sprite = rt.Sprite(config.sprite_id)
    self.sprite:realize()
    
    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    local function format_priority(x)
        return ternary(x > 0, "+", "") .. tostring(x)
    end

    self.stance_label_left = new_label("Alignment")
    self.stance_sprite = nil
    if config.stance_alignment == bt.StanceAlignment.ALL then
        self.stance_label_right = new_label(number_prefix, "<rainbow>" .. "ALL" .. "</rainbow>", number_postfix)
    elseif config.stance_alignment == bt.StanceAlignment.NONE then
        self.stance_label_right = new_label(number_prefix, "<color=" .. gray .. ">" .. "None" .. "</color>", number_postfix)
    else
        self.stance_label_right = new_label(number_prefix, "", number_postfix)
        local stance = bt.Stance(config.stance_alignment)
        self.stance_sprite = rt.Sprite(stance.sprite_id)
        self.stance_sprite:realize()
        self.stance_sprite:set_animation(stance.sprite_index)
    end

    self.priority_label_visible = config.priority ~= 0
    self.priority_label_left = new_label("Priority")
    self.priority_label_right = new_label(number_prefix, format_priority(config.priority), number_postfix)

    -- target
    local me, enemy, ally = config.can_target_self, config.can_target_enemy, config.can_target_ally

    local function _ally(str)
        return "<b>" .. str .. "</b>" --"<color=ALLY>" .. str .. "</color>"
    end

    local function _enemy(str)
        return "<b>" .. str .. "</b>" --"<color=ENEMY>" .. str .. "</color>"
    end

    local function _me(str)
        return "<b>" .. str "</b>" --"<color=SELF>" .. str .. "</color>"
    end

    local function _field()
        return "<b>" .. "field" .. "</b>" --"<color=GRAY_2>" .. " ――― " .. "</color>"
    end

    local function _everyone(str)
        return "<b>" .. str "<b>"--"<color=FIELD>" .. str .. "</color>"
    end

    local target_str = ""

    if self.can_target_multiple == false then
        if         me and not ally and not enemy then
            target_str = _me("self")
        elseif     me and     ally and     enemy then
            target_str = _me("self") .. " or " .. _ally("single ally") .. " or " .. _enemy("single enemy")
        elseif     me and     ally and not enemy then
            target_str = _me("self") .. " or " .. _ally("single ally")
        elseif     me and not ally and     enemy then
            target_str = _me("self") .. " or " .. _enemy("single enemy")
        elseif not me and     ally and not enemy then
            target_str = _ally("single ally")
        elseif not me and not ally and     enemy then
            target_str = _enemy("single enemy")
        elseif not me and     ally and     enemy then
            target_str = _ally("single ally") .. " or " .. _enemy("single enemey")
        elseif not me and not ally and not enemy then
            target_str = _field()
        end
    else
        if         me and not ally and not enemy then
            target_str = _me("self")
        elseif     me and     ally and     enemy then
            target_str = _everyone("all enemies and all allies")
        elseif     me and     ally and not enemy then
            target_str = _ally("all allies and self")
        elseif     me and not ally and     enemy then
            target_str = _me("self") .. " and " .. _enemy("all enemies")
        elseif not me and     ally and not enemy then
            target_str = _ally("all allies") .. " except " .. _me("self")
        elseif not me and not ally and     enemy then
            target_str = _enemy("all enemies")
        elseif not me and     ally and     enemy then
            target_str = _everyone("all enemies and all allies") .. " except " .. _me("self")
        elseif not me and not ally and not enemy then
            target_str = _field()
        end
    end

    self.target_label_left = new_label("<u>Targets</u>")
    self.target_label_right = new_label(number_prefix, "</mono>", target_str, "<mono>", number_postfix)

    self.effect_label = new_label("<u>Effect</u>: " .. config.description)

    local bonus_prefix, bonus_postfix = "", ""
    if not current_stance:matches_alignment(config.stance_alignment) then
        bonus_prefix = "<color=" .. "GRAY_4" .. "><s>Bonus: "
        bonus_postfix = "</color></s>"
    else
        bonus_prefix = "<rainbow><b>Bonus</b></rainbow>: "
        bonus_postfix = ""
    end
    self.bonus_effect_label = new_label(bonus_prefix, config.bonus_description, bonus_postfix)
end

--- @brief
function bt.VerboseInfo.MovePage:reformat(aabb)
    local x, y, width, height = aabb.x, aabb.y, aabb.width, aabb.height

    local once = true
    ::restart::

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit

    local sprite_size = 2 * select(1, self.sprite:get_resolution())
    self.name_label:fit_into(current_x, current_y, width - 2 * m - sprite_size - m, height)
    current_y = current_y + select(2, self.name_label:measure()) + m

    self.sprite:fit_into(x + width - sprite_size - 1 * m, y + 1 * m, sprite_size, sprite_size)

    local stat_align = current_x + 4 * self.name_label:get_font():get_size()

    local stance_sprite_size = select(2, self.stance_label_right:measure())
    local stance_label_height = select(2, self.stance_label_left:measure())
    local stance_label_y = current_y + 0.5 * stance_sprite_size - 0.5 * stance_label_height
    self.stance_label_left:fit_into(current_x, stance_label_y, width, height)
    self.stance_label_right:fit_into(math.max(select(1, self.stance_label_left:measure()) + 2 * m, stat_align), stance_label_y, width, height)

    if meta.isa(self.stance_sprite, rt.Sprite) then
        local resolution = select(1, self.stance_sprite:get_resolution())
        self.stance_sprite:fit_into(math.max(select(1, self.stance_label_left:measure()) + 6 * m, stat_align), stance_label_y, resolution, resolution)
    end
    current_y = current_y + stance_sprite_size
    current_y = current_y + m

    if self.priority_label_visible then
        self.priority_label_left:fit_into(current_x, current_y, width, height)
        self.priority_label_right:fit_into(math.max(select(1, self.priority_label_left:measure()) + 2 * m, stat_align), current_y, width, height)
        current_y = current_y + select(2, self.priority_label_left:measure())
        current_y = current_y + m
    end

    self.target_label_left:fit_into(current_x, current_y, width, height)
    local target_right_align = math.max(select(1, self.target_label_left:measure()) + 2 * m)
    self.target_label_right:fit_into(target_right_align, current_y, width, height)
    current_y = current_y + select(2, self.target_label_left:measure())
    current_y = current_y + m

    local max_length = select(1, self.target_label_left:measure()) + select(1, self.target_label_right:measure()) + 6 * m

    if max_length > width then
        width = max_length
        once = false
        goto restart
    end

    self.effect_label:fit_into(current_x, current_y, width - 2 * m, height)
    current_y = current_y + select(2, self.effect_label:measure())

    self.bonus_effect_label:fit_into(current_x, current_y, width - 2 * m, height)
    current_y = current_y + select(2, self.bonus_effect_label:measure())


    x, y, width, height = 0, 0, width, current_y - y
    x = x - 2 * m
    y = y - 2 * m
    width = width
    height = height + math.max(2 * self.name_label:get_font():get_size(), 5 * m)
    self.backdrop:fit_into(x, y, width, height)
    self.sprite:fit_into(x + width - sprite_size - 1 * m, y + 1 * m, sprite_size, sprite_size)
end

--- @brief
function bt.VerboseInfo.MovePage:draw()
    self.backdrop:draw()
    self.name_label:draw()
    self.sprite:draw()

    self.stance_label_left:draw()
    self.stance_label_right:draw()
    if self.stance_sprite ~= nil then
        self.stance_sprite:draw()
    end

    if self.priority_label_visible then
        self.priority_label_left:draw()
        self.priority_label_right:draw()
    end

    self.target_label_left:draw()
    self.target_label_right:draw()

    self.effect_label:draw()
    self.bonus_effect_label:draw()
end