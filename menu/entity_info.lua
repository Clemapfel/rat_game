--- @class mn.EntityInfo
mn.EntityInfo = meta.new_type("MenuEntityInfo", rt.Widget, function(entity)
    return meta.new(mn.EntityInfo, {
        _frame = rt.Frame(),
        _base = rt.Spacer(),

        _hp_value = entity:get_hp_base(),
        _attack_value = entity:get_attack_base(),
        _defense_value = entity:get_defense_base(),
        _speed_value = entity:get_speed_base(),

        _hp_preview_value = 0,
        _attack_preview_value = 0,
        _defense_preview_value = 0,
        _speed_preview_value = 0,

        _numerical_label_w = 0,
        _no_preview_x_offset = 100,
    })
end)

--- @override
function mn.EntityInfo:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:set_child(self._base)
    self._frame:realize()

    function new_label(...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default, rt.settings.font.default_mono)
        out:realize()
        out:set_justify_mode(rt.JustifyMode.LEFT)
        return out
    end

    for stat in range(
        -- varname  heading color
        {"hp", "HP", "HP"},
        {"attack", "Attack", "ATTACK"},
        {"defense", "Defense", "DEFENSE"},
        {"speed", "Speed", "SPEED"}
    ) do
        local heading_prefix = "<b>"
        local heading_postfix = "</b>"
        self["_" .. stat[1] .. "_heading_label"] = rt.Label(heading_prefix .. stat[2] .. heading_postfix)

        local number_prefix = "<mono>"
        local number_postfix = "</mono>"

        local stat_prefix = "<color=" .. stat[3] .. ">"
        local stat_postfix = "</color>"
        self["_" .. stat[1] .. "_colon"] = rt.Label("<color=GRAY><b> :</b></color>")
        self["_" .. stat[1] .. "_arrow"] = rt.Label("<color=GRAY> \u{2192}</color>")
        self["_" .. stat[1] .. "_value_label"] = rt.Label(stat_prefix .. number_prefix .. self["_" .. stat[1] .. "_value"] .. number_postfix .. stat_postfix)

        local preview_value = self["_" .. stat[1] .. "_preview_value"]
        if preview_value ~= nil then
            self["_" .. stat[1] .. "_preview_label"] = rt.Label(number_prefix .. preview_value .. number_postfix)
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

    local measure_label = new_label("<b>" .. "000" .. "</b>")
    self._numerical_label_w = select(1, measure_label:measure())
end

--- @override
function mn.EntityInfo:size_allocate(x, y, width, height)

    self._frame:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    local current_y = y + m

    local heading_max_w = NEGATIVE_INFINITY
    for stat in range("hp", "attack", "defense", "speed") do
        heading_max_w = math.max(heading_max_w, select(1, self["_" .. stat .. "_heading_label"]:measure()))
    end

    local value_max_w = self._numerical_label_w
    local preview_max_w = self._numerical_label_w

    local left_align = x + 2 * m
    local value_align = left_align + heading_max_w
    local preview_align = value_align + value_max_w
    local max_x = NEGATIVE_INFINITY
    local max_arrow_w = NEGATIVE_INFINITY
    for stat in range("hp", "attack", "defense", "speed") do
        local current_x = left_align
        self["_" .. stat .. "_heading_label"]:fit_into(current_x, current_y, POSITIVE_INFINITY)

        current_x = current_x + heading_max_w
        local colon_label = self["_" .. stat .. "_colon"]
        colon_label:fit_into(current_x, current_y, POSITIVE_INFINITY)

        local value_label = self["_" .. stat .. "_value_label"]
        local current_w = select(1, value_label:measure())
        current_x = value_align + select(1, colon_label:measure()) + value_max_w
        value_label:fit_into(current_x - current_w, current_y, POSITIVE_INFINITY)
        current_x = current_x

        local arrow_label = self["_" .. stat .. "_arrow"]
        arrow_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
        local arrow_w = select(1, arrow_label:measure())
        current_x = current_x + arrow_w
        max_arrow_w = math.max(max_arrow_w, arrow_w)

        local preview_label = self["_" .. stat .. "_preview_label"]
        local preview_w, preview_h = preview_label:measure()
        preview_label:fit_into(current_x + preview_max_w - preview_w, current_y, POSITIVE_INFINITY)

        current_y = current_y + select(2, self["_" .. stat .. "_heading_label"]:measure())

        local bounds = preview_label:get_bounds()
        max_x = math.max(max_x, bounds.x + preview_w)
    end

    self._no_preview_x_offset = preview_align - value_align + max_arrow_w
    self._frame:fit_into(x, y, max_x - x + 2 * m, current_y - y + m)
end

--- @override
function mn.EntityInfo:draw()
    self._frame:draw()

    for which in range("hp", "attack", "defense", "speed") do
        if self["_" .. which .. "_preview_value"] ~= nil then
            for label in range(
                self["_" .. which .. "_heading_label"],
                self["_" .. which .. "_value_label"]
            ) do
                label:draw()
            end

            for label in range(
                self["_" .. which .. "_colon"],
                self["_" .. which .. "_arrow"],
                self["_" .. which .. "_preview_label"]
            ) do
                label:draw()
            end
        else
            self["_" .. which .. "_heading_label"]:draw()
            self["_" .. which .. "_colon"]:draw()
            rt.graphics.translate(self._no_preview_x_offset, 0)
            self["_" .. which .. "_value_label"]:draw()
            rt.graphics.translate(-self._no_preview_x_offset, 0)
        end
    end
end

--- @brief
--- @param hp_preview Union<Number, Nil>
--- @param attack_preview Union<Number, Nil>
--- @param defense_preview Union<Number, Nil>
--- @param speed_preview Union<Number, Nil>
function mn.EntityInfo:set_preview_values(hp_preview, attack_preview, defense_preview, speed_preview)
    self._hp_preview_value = hp_preview
    self._attack_preview_value = attack_preview
    self._defense_preview_value = defense_preview
    self._speed_preview_value = speed_preview
end