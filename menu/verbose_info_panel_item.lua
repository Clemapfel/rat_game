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
    local out = rt.Label("<b><color=FOREGROUND><u>" .. paste(...) .. "</u></color></b>", mn.VerboseInfoPanel.Item._font())
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

function mn.VerboseInfoPanel.Item._get_margin()
    local m = rt.settings.margin_unit
    return m, 2 * m, m
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

        -- TODO: stats

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,
            self.spacer,
            self.flavor_text_label
        }

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
        current_y = current_y + select(2, self.description_label:measure())

        current_y = current_y + m
        self.spacer:fit_into(current_x, current_y, w, 0)
        current_y = current_y + select(2, self.spacer:measure()) + m

        self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
        current_y = current_y + select(2, self.flavor_text_label:measure()) + m

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
    end
end

