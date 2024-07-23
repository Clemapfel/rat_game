--- @class VerboseInfoPanel.Item
mn.VerboseInfoPanel.Item = meta.new_type("MenuVerboseInfoPanelItem", rt.Widget, function()
    return meta.new(mn.VerboseInfoPanel.Item, {
        aabb = rt.AABB(0, 0, 1, 1),
        height_above = 0,
        height_below = 0,
        frame = rt.Frame(),
        object = nil,
        content = {}, -- Table<rt.Drawable>
    })
end)

function mn.VerboseInfoPanel.Item:draw()
    self.frame:draw()
    for object in values(self.content) do
        object:draw()
    end
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
    local out = rt.Label("<color=GRAY_2><b>:</b></color>")
    out:set_justify_mode(rt.JustifyMode.LEFT)
    out:realize()
    return out
end

function mn.VerboseInfoPanel.Item._get_margin()
    local m = rt.settings.margin_unit
    return m, 2 * m, m
end

function mn.VerboseInfoPanel.Item._number(value, color)
    local out = rt.Label("<color=" .. color .. "><mono>" .. value .. "</mono></color>")
    out:realize()
    out:set_justify_mode(rt.JustifyMode.LEFT)
    return out
end

function mn.VerboseInfoPanel.Item:create_from_equip(equip)
    self.object = equip
    self.realize = function(self)
        self._is_realized = true

        self.title_label = self._title(equip:get_name())
        self.description_label = self._description(equip:get_description())
        self.sprite = self._sprite(equip)
        self.spacer = self._hrule()
        self.flavor_text_label = self._flavor_text(equip:get_flavor_text())

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,
            self.spacer,
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
                local prefix_label = rt.Label("<color=" .. color .. ">" .. stat_color_label[3] .. "</color>")
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
                local prefix_label = rt.Label("<color=" .. color .. ">" .. stat_color_label[3] .. "</color>")
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
        self.title_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.title_label:measure())
        current_y = current_y + m

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.description_label:measure()) + 1 * m

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
                    value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)

                    current_y = current_y + value_h
                end
            end
        end

        current_y = current_y + 2 * m
        self.spacer:fit_into(current_x, current_y, w, 0)
        current_y = current_y + select(2, self.spacer:measure()) + m

        self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.flavor_text_label:measure()) + m

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
    end
end

