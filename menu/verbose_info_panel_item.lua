--- @class VerboseInfoPanel.Item
mn.VerboseInfoPanel.Item = meta.new_type("MenuVerboseInfoPanelItem", rt.Widget, function()
    local out = meta.new(mn.VerboseInfoPanel.Item, {
        aabb = rt.AABB(0, 0, 1, 1),
        height_above = 0,
        height_below = 0,
        frame = rt.Frame(),
        object = nil,
        final_height = 1,
        content = {}, -- Table<rt.Drawable>
    })

    out.frame:set_corner_radius(1)
    out.frame:set_color(rt.Palette.GRAY_3)
    return out
end)

function mn.VerboseInfoPanel.Item:draw()
    self.frame:draw()
    for object in values(self.content) do
        object:draw()
    end
end

function mn.VerboseInfoPanel.Item:measure()
    return self._bounds.width, self.final_height
end

function mn.VerboseInfoPanel.Item._font()
    return rt.settings.font.default_small, rt.settings.font.default_mono_small
end

function mn.VerboseInfoPanel.Item._font_tiny()
    return rt.settings.font.default_tiny, rt.settings.font.default_mono_tiny
end

function mn.VerboseInfoPanel.Item._title(...)
    local out = rt.Label("<b><u>" .. paste(...) .. "</u></b>", mn.VerboseInfoPanel.Item._font())
    out:set_justify_mode(rt.JustifyMode.LEFT)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._description(...)
    local out = rt.Label("" .. paste(...), mn.VerboseInfoPanel.Item._font())
    out:set_justify_mode(rt.JustifyMode.LEFT)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._flavor_text(...)
    local out = rt.Label("<color=GRAY_2><i>" .. paste(...) .. "</color></i>", mn.VerboseInfoPanel.Item._font_tiny())
    out:set_justify_mode(rt.JustifyMode.CENTER)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._sprite(object)
    local out = rt.Sprite(object:get_sprite_id())
    local res_w, res_h = out:get_resolution()
    res_w = res_w * 2
    res_h = res_h * 2
    out:set_minimum_size(res_w, res_h)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._hrule()
    local out = rt.Spacer()
    out:set_minimum_size(0, 2)
    out:set_color(rt.Palette.GRAY_4)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._colon()
    local out = rt.Label("<color=GRAY_2><b>:</b></color>", mn.VerboseInfoPanel.Item._font())
    out:set_justify_mode(rt.JustifyMode.LEFT)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._get_margin()
    local m = rt.settings.margin_unit
    return m, 2 * m, m
end

function mn.VerboseInfoPanel.Item._number(value, color)
    local out
    if color ~= nil then
        out = rt.Label("<color=" .. color .. "><mono>" .. value .. "</mono></color>", mn.VerboseInfoPanel.Item._font())
    else
        out = rt.Label(value, mn.VerboseInfoPanel.Item._font())
    end
    out:realize()
    out:set_justify_mode(rt.JustifyMode.LEFT)
    return out
end

function mn.VerboseInfoPanel.Item._prefix(str, color)
    local out
    if color ~= nil then
        out = rt.Label("<color=" .. color .. ">" .. str .. "</color>", mn.VerboseInfoPanel.Item._font())
    else
        out = rt.Label(str, mn.VerboseInfoPanel.Item._font())
    end
    out:realize()
    out:set_justify_mode(rt.JustifyMode.LEFT)
    return out
end

--- @brief equip
function mn.VerboseInfoPanel.Item:create_from_equip(equip)
    self.object = equip
    self.realize = function(self)
        self._is_realized = true

        self.title_label = self._title(equip:get_name())
        self.description_label = self._description(equip:get_description())
        self.sprite = self._sprite(equip)

        local flavor_text = equip:get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(equip:get_flavor_text())
        end

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,

            self.spacer, -- may be nil
            self.flavor_text_label
        }

        local function format_offset(x)
            if x > 0 then
                return "+" .. x
            elseif x < 0 then
                return "-" .. math.abs(x)
            else
                return "\u{00B1}" .. x -- plusminus
            end
        end

        local function format_factor(x)
            x = math.abs(x)
            if x > 1 then
                return "+" .. math.round((x - 1) * 100) .. "%"
            elseif x < 1 then
                return "-" .. math.round((1 - x) * 100) .. "%"
            else
                return "\u{00B1}0%" -- plusminus
            end
        end

        for stat_color_label in range(
            {"hp", "HP", "HP"},
            {"attack", "ATTACK", "ATK"},
            {"defense", "DEFENSE", "DEF"},
            {"speed", "SPEED", "SPD"}
        ) do
            local stat = stat_color_label[1]
            local color = stat_color_label[2]

            local offset = equip[stat .. "_base_offset"]
            if offset ~= 0 then
                local prefix_label = self._prefix(stat_color_label[3], color)
                prefix_label:realize()
                local colon = self._colon()
                local value_label = self._number(format_offset(offset), color)

                self[stat .. "_offset_prefix_label"] = prefix_label
                self[stat .. "_offset_colon_label"] = colon
                self[stat .. "_offset_value_label"] = value_label

                for label in range(prefix_label, colon, value_label) do
                    table.insert(self.content, label)
                end
            end

            local factor = equip[stat .. "_base_factor"]
            if factor ~= 1 then
                local prefix_label = self._prefix(stat_color_label[3], color)
                prefix_label:realize()
                local colon = self._colon()
                local value_label = self._number(format_factor(factor), color)

                self[stat .. "_factor_prefix_label"] = prefix_label
                self[stat .. "_factor_colon_label"] = colon
                self[stat .. "_factor_value_label"] = value_label

                for label in range(prefix_label, colon, value_label) do
                    table.insert(self.content, label)
                end
            end
        end

        self.frame:realize()
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        local start_y = y + ym
        local current_x, current_y = x + xm, start_y
        local w = width - 2 * xm

        local sprite_w, sprite_h = self.sprite:measure()
        local title_w, title_h = self.title_label:measure()

        local title_max_h = math.max(sprite_h, title_h)
        local title_y = current_y + 0.5 * title_max_h - 0.5 * title_h
        self.title_label:fit_into(current_x, title_y, w, POSITIVE_INFINITY)
        self.sprite:fit_into(current_x + w - sprite_w, current_y + 0.5 * title_max_h - 0.5 * sprite_h, sprite_w, sprite_h)

        current_y = current_y + title_max_h

        local title_ym = current_y - title_y - title_h

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.description_label:measure())
        current_y = current_y + title_ym

        local max_prefix_w = NEGATIVE_INFINITY
        local max_value_w = NEGATIVE_INFINITY
        for stat in range("hp", "attack", "defense", "speed") do
            for which in range("offset", "factor") do
                local prefix_label = self[stat .. "_" .. which .. "_prefix_label"]
                if prefix_label ~= nil then
                    max_prefix_w = math.max(max_prefix_w, select(1, prefix_label:measure()))
                end

                local value_label = self[stat .. "_" .. which .. "_value_label"]
                if value_label ~= nil then
                    max_value_w = math.max(max_prefix_w, select(1,value_label :measure()))
                end
            end
        end

        local align_w = select(2, self.description_label:measure())
        for which in range("offset", "factor") do
            for stat in range("hp", "attack", "defense", "speed") do
                local prefix_label = self[stat .. "_" .. which .. "_prefix_label"]
                local colon_label = self[stat .. "_" .. which .. "_colon_label"]
                local value_label = self[stat .. "_" .. which .. "_value_label"]

                if value_label ~= nil then
                    local value_w, value_h = value_label:measure()
                    prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
                    local colon_w = select(1, colon_label:measure())
                    colon_label:fit_into(current_x + w / 2 - colon_w, current_y, POSITIVE_INFINITY)
                    value_label:fit_into(current_x + align_w - value_w, current_y, POSITIVE_INFINITY)

                    current_y = current_y + value_h
                end
            end
        end

        current_y = current_y + 2 * m

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
        end

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.final_height = total_height
    end
end

--- @brief move
function mn.VerboseInfoPanel.Item:create_from_move(move)
    self.object = move
    self.realize = function(self)
        self._is_realized = true
        self.frame:realize()

        self.title_label = self._title(move:get_name())
        self.description_label = self._description(move:get_description())
        self.sprite = self._sprite(move)

        local flavor_text = move:get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(move:get_flavor_text())
        end

        self.n_uses_prefix_label = self._prefix("Uses")
        self.n_uses_colon_label = self._colon()

        local n_uses = move:get_max_n_uses()
        local n_uses_str
        if n_uses == POSITIVE_INFINITY then
            n_uses_str = "<b>\u{221E}</b>" -- infinity
        else
            n_uses_str = tostring(n_uses)
        end
        self.n_uses_value_label = self._number(n_uses_str)

        self.priority_prefix_label = self._prefix("Priority")
        self.priority_colon_label = self._colon()

        local prio = move:get_priority()
        local priority_str
        if prio > 0 then
            priority_str = "+"
        elseif prio < 0 then
            priority_str = "-"
        else
            priority_str = "\u{00B1}" -- plusminus
        end
        priority_str = priority_str .. prio
        self.priority_value_label = self._number(priority_str)

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,

            self.spacer, -- may be nil
            self.flavor_text_label,

            self.n_uses_prefix_label,
            self.n_uses_colon_label,
            self.n_uses_value_label,

            self.priority_prefix_label,
            self.priority_colon_label,
            self.priority_value_label
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        local start_y = y + ym
        local current_x, current_y = x + xm, start_y
        local w = width - 2 * xm

        local sprite_w, sprite_h = self.sprite:measure()
        local title_w, title_h = self.title_label:measure()

        local title_max_h = math.max(sprite_h, title_h)
        local title_y = current_y + 0.5 * title_max_h - 0.5 * title_h
        self.title_label:fit_into(current_x, title_y, w, POSITIVE_INFINITY)
        self.sprite:fit_into(current_x + w - sprite_w, current_y + 0.5 * title_max_h - 0.5 * sprite_h, sprite_w, sprite_h)

        current_y = current_y + title_max_h

        local max_prefix_w = NEGATIVE_INFINITY
        for which in range("n_uses", "priority") do
            max_prefix_w = math.max(max_prefix_w, self[which .. "_prefix_label"]:measure())
        end

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY) -- alloc to measure
        local align_w = select(1, self.description_label:measure())
        for which in range("n_uses", "priority") do
            local prefix_label = self[which .. "_prefix_label"]
            local colon_label = self[which .. "_colon_label"]
            local value_label = self[which .. "_value_label"]

            local value_w, value_h = value_label:measure()
            prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
            local colon_w = select(1, colon_label:measure())
            colon_label:fit_into(current_x + w / 2 - colon_w, current_y, POSITIVE_INFINITY)
            value_label:fit_into(current_x + align_w - value_w, current_y, POSITIVE_INFINITY)

            current_y = current_y + value_h
        end

        current_y = current_y + 2 * m

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.description_label:measure()) + 2 * m

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
        end

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.final_height = total_height
    end
end

