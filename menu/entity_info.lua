--- @class mn.EntityInfo
mn.EntityInfo = meta.new_type("MenuEntityInfo", rt.Widget, function(entity)
    return meta.new(mn.EntityInfo, {
        _frame = rt.Frame(),

        _hp_value = entity:get_hp_base(),
        _attack_value = entity:get_attack_base(),
        _defense_value = entity:get_defense_base(),
        _speed_value = entity:get_speed_base(),

        _hp_preview_value = 0,
        _hp_preview_active = false,
        _hp_no_preview_offset = 0,

        _attack_preview_value = 0,
        _attack_preview_active = false,
        _attack_no_preview_offset = 123,

        _defense_preview_value = 0,
        _defense_preview_active = false,
        _defense_no_preview_offset = 0,

        _speed_preview_value = 0,
        _speed_preview_active = false,
        _speed_no_preview_offset = 0,
    })
end)

--- @override
function mn.EntityInfo:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._frame:realize()

    for stat in range(
        -- varname  heading color
        {"hp", "Health", "HP"},
        {"attack", "Attack", "ATTACK"},
        {"defense", "Defense", "DEFENSE"},
        {"speed", "Speed", "SPEED"}
    ) do
        local heading_prefix = "<b><o>"
        local heading_postfix = "</b></o>"
        self["_" .. stat[1] .. "_heading_label"] = rt.Label(heading_prefix .. stat[2] .. heading_postfix)

        local number_prefix = "<mono><o>"
        local number_postfix = "</mono></o>"

        local stat_prefix = "<color=" .. stat[3] .. ">"
        local stat_postfix = "</color>"
        self["_" .. stat[1] .. "_colon"] = rt.Label("<color=GRAY><b><o> :</o></b></color>")
        self["_" .. stat[1] .. "_arrow"] = rt.Label("<color=GRAY> \u{2192}</color>")
        self["_" .. stat[1] .. "_value_label"] = rt.Label(stat_prefix .. number_prefix .. self["_" .. stat[1] .. "_value"] .. number_postfix .. stat_postfix)

        local preview_value = self["_" .. stat[1] .. "_preview_value"]
        if preview_value ~= nil then
            self["_" .. stat[1] .. "_preview_label"] = rt.Label(stat_prefix .. number_prefix .. preview_value .. number_postfix .. stat_postfix)
        end

        for label in range(
            self["_" .. stat[1] .. "_heading_label"],
            self["_" .. stat[1] .. "_colon"],
            self["_" .. stat[1] .. "_arrow"],
            self["_" .. stat[1] .. "_value_label"],
            self["_" .. stat[1] .. "_preview_label"]
        ) do
            label:realize()
        end
    end
end

function mn.EntityInfo:_update()
    for stat in range(
    -- varname  heading color
        {"hp", "HP", "HP"},
        {"attack", "Attack", "ATTACK"},
        {"defense", "Defense", "DEFENSE"},
        {"speed", "Speed", "SPEED"}
    ) do
        local number_prefix = "<mono><o>"
        local number_postfix = "</mono></o>"

        local stat_prefix = "<o><color=" .. stat[3] .. ">"
        local stat_postfix = "</color></o>"

        local value_label = self["_" .. stat[1] .. "_value_label"]
        value_label:set_text(stat_prefix .. number_prefix .. self["_" .. stat[1] .. "_value"] .. number_postfix .. stat_postfix)

        local preview_value = self["_" .. stat[1] .. "_preview_value"]
        if preview_value ~= nil then
            local preview_label = self["_" .. stat[1] .. "_preview_label"]
            preview_label:set_text(stat_prefix .. number_prefix .. preview_value .. number_postfix .. stat_postfix)
        end
    end
end

--- @override
function mn.EntityInfo:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local start_x = x + 2 * m
    local end_x = x + width - 2 * m
    local start_y = y + m
    local end_y = y + height - m
    local current_x, current_y = start_x, start_y

    local max_heading_w = NEGATIVE_INFINITY
    local max_end_value_w = NEGATIVE_INFINITY
    for stat in range("hp", "attack", "defense", "speed") do
        max_heading_w = math.max(max_heading_w, select(1,  self["_" .. stat .. "_heading_label"]:measure()))

        if self["_" .. stat .. "_preview_active"] then
            max_end_value_w = math.max(max_end_value_w, select(1, self["_" .. stat .. "_preview_label"]:measure()))
        else
            max_end_value_w = math.max(max_end_value_w, select(1, self["_" .. stat .. "_value_label"]:measure()))
        end
    end

    local total_h = 0
    for stat in range("hp", "attack", "defense", "speed") do
        local heading_label = self["_" .. stat .. "_heading_label"]
        local heading_w, heading_h = heading_label:measure()

        local value_label = self["_" .. stat .. "_value_label"]
        local value_w, _ = value_label:measure()

        local preview_label = self["_" .. stat .. "_preview_label"]
        local preview_w, _ = preview_label:measure()

        local colon_label = self["_" .. stat .. "_colon"]
        local colon_w, _ = colon_label:measure()

        local arrow_label = self["_" .. stat .. "_arrow"]
        local arrow_w, _ = arrow_label:measure()

        heading_label:fit_into(math.floor(current_x), math.floor(current_y), POSITIVE_INFINITY)
        colon_label:fit_into(current_x + 0.5 * (end_x - start_x) - 0.5 * colon_w, current_y, POSITIVE_INFINITY)

        local preview_active = self["_" .. stat .. "_preview_active"]
        if preview_active then
            preview_label:fit_into(end_x - preview_w, current_y, POSITIVE_INFINITY)
            arrow_label:fit_into(end_x - max_end_value_w - m - arrow_w, current_y, POSITIVE_INFINITY)
            value_label:fit_into(end_x - max_end_value_w - m - arrow_w - m - value_w, current_y, POSITIVE_INFINITY)
        else
            value_label:fit_into(end_x - value_w, current_y, POSITIVE_INFINITY)
        end

        current_y = current_y + heading_h

        total_h = total_h + heading_h
    end

    self._frame:fit_into(x, y, width, height)
    self._y_center_offset = ((end_y - start_y) - total_h) / 2
end

--- @override
function mn.EntityInfo:draw()
    self._frame:draw()

    rt.graphics.translate(0, math.floor(self._y_center_offset))
    for stat in range("hp", "attack", "defense", "speed") do
        self["_" .. stat .. "_heading_label"]:draw()
        self["_" .. stat .. "_colon"]:draw()

        if self["_" .. stat .. "_preview_active"] then
            self["_" .. stat .. "_value_label"]:draw()
            self["_" .. stat .. "_arrow"]:draw()
            self["_" .. stat .. "_preview_label"]:draw()
        else
            self["_" .. stat .. "_value_label"]:draw()
        end
    end
    rt.graphics.translate(0, -math.floor(self._y_center_offset))
end

--- @brief
--- @param hp_preview Union<Number, Nil>
--- @param attack_preview Union<Number, Nil>
--- @param defense_preview Union<Number, Nil>
--- @param speed_preview Union<Number, Nil>
function mn.EntityInfo:set_preview_values(hp_preview, attack_preview, defense_preview, speed_preview)
    self._hp_preview_value = which(hp_preview, 0)
    self._hp_preview_active = hp_preview ~= nil

    self._attack_preview_value = which(attack_preview, 0)
    self._attack_preview_active = attack_preview ~= nil

    self._defense_preview_value = which(defense_preview, 0)
    self._defense_preview_active = defense_preview ~= nil

    self._speed_preview_value = which(speed_preview, 0)
    self._speed_preview_active = speed_preview ~= nil

    self:_update()
    self:reformat()
end

--- @brief
function mn.EntityInfo:set_values(hp, attack, defense, speed)
    self._hp_value = hp
    self._attack_value = attack
    self._defense_value = defense
    self._speed_value = speed

    self:_update()
    self:reformat()
end

--- @brief
function mn.EntityInfo:set_values_and_preview_values(hp, attack, defense, speed, hp_preview, attack_preview, defense_preview, speed_preview)
    self._hp_value = hp
    self._attack_value = attack
    self._defense_value = defense
    self._speed_value = speed

    self._hp_preview_value = which(hp_preview, 0)
    self._hp_preview_active = hp_preview ~= nil
    self._attack_preview_value = which(attack_preview, 0)
    self._attack_preview_active = attack_preview ~= nil
    self._defense_preview_value = which(defense_preview, 0)
    self._defense_preview_active = defense_preview ~= nil
    self._speed_preview_value = which(speed_preview, 0)
    self._speed_preview_active = speed_preview ~= nil

    self:_update()
    self:reformat()
end

--- @brief
function mn.EntityInfo:set_selection_state(state)
    self._frame:set_selection_state(state)
end