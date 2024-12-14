--- @class VerboseInfoPanel.Item
mn.VerboseInfoPanel.Item = meta.new_type("MenuVerboseInfoPanelItem", rt.Widget, function()
    local out = meta.new(mn.VerboseInfoPanel.Item, {
        aabb = rt.AABB(0, 0, 1, 1),
        height_above = 0,
        height_below = 0,
        frame = rt.Frame(),
        divider = rt.Line(0, 0, 1, 1),
        object = nil,
        final_height = 1,
        content = {} -- Table<rt.Drawable>
    })

    out.divider:set_color(rt.Palette.WHITE)
    out.frame:set_corner_radius(1)
    --out.frame:set_color(rt.Palette.GRAY_3)
    return out
end)

--- @override
function mn.VerboseInfoPanel.Item:draw()
    for object in values(self.content) do
        object:draw()
    end
end

--- @override
function mn.VerboseInfoPanel.Item:measure()
    return self._bounds.width, self.final_height
end

--- @brief
function mn.VerboseInfoPanel.Item:create_from(object)
    if meta.is_enum_value(object, rt.VerboseInfoObject) then
        self:create_from_enum(object)
    elseif meta.isa(object, bt.Entity) then
        self:create_from_entity(object)
    elseif meta.isa(object, bt.EquipConfig) then
        self:create_from_equip(object)
    elseif meta.isa(object, bt.MoveConfig) then
        self:create_from_move(object)
    elseif meta.isa(object, bt.ConsumableConfig) then
        self:create_from_consumable(object)
    elseif meta.isa(object, bt.StatusConfig) then
        self:create_from_status(object)
    elseif meta.isa(object, bt.GlobalStatusConfig) then
        self:create_from_global_status(object)
    elseif meta.isa(object, mn.Template) then
        self:create_from_template(object)
    else
        rt.error("In mn.VerboseInfoPanel.Item.create_from: unrecognized type `" .. meta.typeof(object) .. "`")
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
    local out = rt.Label("<color=GRAY><b>:</b></color>", mn.VerboseInfoPanel.Item._font())
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
        out = rt.Label("<mono>" .. value .. "</mono>", mn.VerboseInfoPanel.Item._font())
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

function mn.VerboseInfoPanel.Item._format_offset(x)
    if x > 0 then
        return "+" .. x
    elseif x < 0 then
        return "-" .. math.abs(x)
    else
        return rt.Translation.plus_minus .. x
    end
end

function mn.VerboseInfoPanel.Item._format_factor(x)
    x = math.abs(x)
    if x > 1 then
        return "+" .. math.round((x - 1) * 100) .. "%"
    elseif x < 1 then
        return "-" .. math.round((1 - x) * 100) .. "%"
    else
        return rt.Translation.plus_minus .. "0%"
    end
end

--- @brief equip
function mn.VerboseInfoPanel.Item:create_from_equip(equip)
    self.object = equip
    self._is_realized = false

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

        local translation = rt.Translation.verbose_info

        for stat_color_label in range(
            {"hp", "HP", translation.hp_label},
            {"attack", "ATTACK", translation.attack_label},
            {"defense", "DEFENSE", translation.defense_label},
            {"speed", "SPEED", translation.speed_label}
        ) do
            local stat = stat_color_label[1]
            local color = stat_color_label[2]

            local offset = equip[stat .. "_base_offset"]
            if offset ~= 0 then
                local prefix_label = self._prefix(stat_color_label[3], color)
                prefix_label:realize()
                local colon = self._colon()
                local value_label = self._number(self._format_offset(offset), color)

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
                local value_label = self._number(self._format_factor(factor), color)

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

        local at_least_one_stat_change = false
        for which in range("offset", "factor") do
            for stat in range("hp", "attack", "defense", "speed") do
                local prefix_label = self[stat .. "_" .. which .. "_prefix_label"]
                local colon_label = self[stat .. "_" .. which .. "_colon_label"]
                local value_label = self[stat .. "_" .. which .. "_value_label"]

                if value_label ~= nil then
                    local value_w, value_h = value_label:measure()
                    prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
                    local colon_w = select(1, colon_label:measure())
                    colon_label:fit_into(current_x + w / 2 - colon_w / 2, current_y, POSITIVE_INFINITY)
                    value_label:fit_into(current_x + w - max_value_w, current_y, POSITIVE_INFINITY)

                    current_y = current_y + value_h
                    at_least_one_stat_change = true
                end
            end
        end

        if at_least_one_stat_change then
            current_y = current_y + 2 * m
        end

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
            current_y = current_y + ym
        end

        local total_height = current_y - start_y + ym
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    return self
end

--- @brief move
function mn.VerboseInfoPanel.Item:create_from_move(move)
    self.object = move
    self._is_realized = false

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

        self.n_uses_prefix_label = self._prefix(rt.Translation.verbose_info.move_n_uses)
        self.n_uses_colon_label = self._colon()

        local n_uses = move:get_max_n_uses()
        local n_uses_str
        if n_uses == POSITIVE_INFINITY then
            n_uses_str = "<b>" .. rt.Translation.infinity .. "</b>"
        else
            n_uses_str = tostring(n_uses)
        end
        self.n_uses_value_label = self._number(n_uses_str)

        self.priority_prefix_label = self._prefix(rt.Translation.verbose_info.move_priority)
        self.priority_colon_label = self._colon()

        local prio = move:get_priority()
        local priority_str
        if prio > 0 then
            priority_str = "+"
        elseif prio < 0 then
            priority_str = "-"
        else
            priority_str = rt.Translation.plus_minus
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

        for which in range("n_uses", "priority") do
            local prefix_label = self[which .. "_prefix_label"]
            local colon_label = self[which .. "_colon_label"]
            local value_label = self[which .. "_value_label"]

            local value_w, value_h = value_label:measure()
            prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
            local colon_w = select(1, colon_label:measure())
            colon_label:fit_into(current_x + w / 2 - colon_w / 2, current_y, POSITIVE_INFINITY)
            value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)

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
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    return self
end

--- @brief consumable
function mn.VerboseInfoPanel.Item:create_from_consumable(consumable)
    self.object = consumable
    self._is_realized = false

    self.realize = function(self)
        self._is_realized = true
        self.frame:realize()

        self.title_label = self._title(consumable:get_name())
        self.description_label = self._description(consumable:get_description())
        self.sprite = self._sprite(consumable)

        local flavor_text = consumable:get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(consumable:get_flavor_text())
        end

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,

            self.spacer, -- may be nil
            self.flavor_text_label,
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

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY) -- alloc to measure
        current_y = current_y + select(2, self.description_label:measure()) + 2 * m

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
        end

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

--- @brief
function mn.VerboseInfoPanel.Item:create_from_status(status)
    self.object = status
    self._is_realized = false

    self.realize = function(self)
        self._is_realized = true
        self.frame:realize()

        self.title_label = self._title(status:get_name())
        self.description_label = self._description(status:get_description())
        self.sprite = self._sprite(status)

        self.max_duration_prefix_label = self._prefix(rt.Translation.verbose_info.status_max_duration)
        self.max_duration_colon_label = self._colon()

        local duration = status:get_max_duration()
        local duration_str
        if duration == POSITIVE_INFINITY then
            duration_str = "<b>" .. rt.Translation.infinity .. "</b>"
        else
            duration_str = tostring(duration)
        end
        self.max_duration_value_label = self._number(duration_str)

        local flavor_text = status:get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(status:get_flavor_text())
        end

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,
            self.max_duration_prefix_label,
            self.max_duration_colon_label,
            self.max_duration_value_label,

            self.spacer, -- may be nil
            self.flavor_text_label,
        }

        local translation = rt.Translation.verbose_info
        for name_color_prefix in range(
            {"attack", "ATTACK", translation.attack_label},
            {"defense", "DEFENSE", translation.defense_label},
            {"speed", "SPEED", translation.speed_label},
            {"damage_dealt", "ATTACK", translation.damage_dealt_label},
            {"damage_received", "ATTACK", translation.damage_taken_label},
            {"healing_performed", "HEALTH", translation.healing_performed_label},
            {"healing_received", "HEALTH", translation.healing_received_label}
        ) do
            local name, color, prefix = table.unpack(name_color_prefix)

            local offset = self.object[name .. "_offset"]
            if offset ~= 0 then
                local prefix_label = self._prefix(prefix)
                local colon_label = self._colon()
                local value_label = self._number(self._format_offset(offset), color)
                self[name .. "_offset_prefix_label"] = prefix_label
                self[name .. "_offset_colon_label"] = colon_label
                self[name .. "_offset_value_label"] = value_label

                for w in range(prefix_label, colon_label, value_label) do
                    table.insert(self.content, w)
                end
            end

            local factor = self.object[name .. "_factor"]
            if factor ~= 1 then
                local prefix_label = self._prefix(prefix)
                local colon_label = self._colon()
                local value_label = self._number(self._format_factor(offset), color)
                self[name .. "_factor_prefix_label"] = prefix_label
                self[name .. "_factor_colon_label"] = colon_label
                self[name .. "_factor_value_label"] = value_label

                for w in range(prefix_label, colon_label, value_label) do
                    table.insert(self.content, w)
                end
            end
        end
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

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY) -- alloc to measure
        current_y = current_y + select(2, self.description_label:measure()) + 2 * m

        self.max_duration_prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
        local value_w, value_h = self.max_duration_value_label:measure()
        self.max_duration_value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)
        local colon_w, colon_h = self.max_duration_colon_label:measure()
        self.max_duration_colon_label:fit_into(current_x + 0.5 * w - 0.5 * colon_w, current_y, POSITIVE_INFINITY)

        current_y = current_y + math.max(value_h, colon_h) + m

        local attribute_active = false
        for name in range(
            "attack",
            "defense",
            "speed",
            "damage_dealt",
            "damage_received",
            "healing_performed",
            "healing_received"
        ) do
            local offset_prefix_label = self[name .. "_offset_prefix_label"]
            local offset_colon_label = self[name .. "_offset_colon_label"]
            local offset_value_label = self[name .. "_offset_value_label"]

            if offset_prefix_label ~= nil then
                local colon_w, colon_h = offset_colon_label:measure()
                local value_w, value_h = offset_value_label:measure()
                offset_prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
                offset_colon_label:fit_into(current_x + 0.5 * w - 0.5 * colon_w, current_y, POSITIVE_INFINITY)
                offset_value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)
                current_y = current_y + value_h

                attribute_active = true
            end

            local factor_prefix_label = self[name .. "_factor_prefix_label"]
            local factor_colon_label = self[name .. "_factor_colon_label"]
            local factor_value_label = self[name .. "_factor_value_label"]

            if factor_prefix_label ~= nil then
                local colon_w, colon_h = factor_colon_label:measure()
                local value_w, value_h = factor_value_label:measure()
                factor_prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
                factor_colon_label:fit_into(current_x + 0.5 * w - 0.5 * colon_w, current_y, POSITIVE_INFINITY)
                factor_value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)
                current_y = current_y + value_h

                attribute_active = true
            end
        end

        if attribute_active then current_y = current_y + m end

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
        end

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

--- @brief
function mn.VerboseInfoPanel.Item:create_from_global_status(status)
    self.object = status
    self._is_realized = false

    self.realize = function(self)
        self._is_realized = true
        self.frame:realize()

        self.title_label = self._title(status:get_name())
        self.description_label = self._description(status:get_description())
        self.sprite = self._sprite(status)

        self.max_duration_prefix_label = self._prefix(rt.Translation.verbose_info.global_status_max_duration)
        self.max_duration_colon_label = self._colon()

        local duration = status:get_max_duration()
        local duration_str
        if duration == POSITIVE_INFINITY then
            duration_str = "<b>" .. rt.Translation.infinity .. "</b>"
        else
            duration_str = tostring(duration)
        end
        self.max_duration_value_label = self._number(duration_str)

        local flavor_text = status:get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(status:get_flavor_text())
        end

        self.content = {
            self.title_label,
            self.sprite,
            self.description_label,
            self.max_duration_prefix_label,
            self.max_duration_colon_label,
            self.max_duration_value_label,

            self.spacer, -- may be nil
            self.flavor_text_label,
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

        self.description_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY) -- alloc to measure
        current_y = current_y + select(2, self.description_label:measure()) + 2 * m

        self.max_duration_prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
        local value_w, value_h = self.max_duration_value_label:measure()
        self.max_duration_value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)
        local colon_w, colon_h = self.max_duration_colon_label:measure()
        self.max_duration_colon_label:fit_into(current_x + 0.5 * w - 0.5 * colon_w, current_y, POSITIVE_INFINITY)

        current_y = current_y + math.max(value_h, colon_h) + m

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
        end

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

--- @brief party info
function mn.VerboseInfoPanel.Item:create_from_template(template)
    self.object = nil
    self._is_realized = false

    local format_title = function(str)
        return "<b><u>" .. str .. "</u></b>"
    end

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        local translation = rt.Translation.verbose_info

        self.title_label = rt.Label(format_title(template:get_name()))
        self.title_label:realize()
        self.title_label:set_justify_mode(rt.JustifyMode.LEFT)

        self.created_on_label = self._flavor_text(translation.template_created_on_f(template:get_creation_date()))

        self.content = {
            self.title_label,
            self.created_on_label
        }

        local translation = rt.Translation.verbose_info

        self.entities = {}
        local font, mono_font = rt.settings.font.default_small, rt.settings.font.default_mono_small
        for entity in values(template:list_entities()) do
            local to_push = {
                entity = entity,
                name_label = rt.Label("<u>" .. entity:get_name() .. "</u>", font, mono_font),
                move_label = rt.Label(translation.template_move_heading, font, mono_font),
                move_sprites = {},
                equip_and_consumable_label = rt.Label(translation.template_equipment_heading, font, mono_font),
                equip_sprites = {},
                consumable_sprites = {},
                hrule = self._hrule()
            }

            local small_sprite = function(...)
                local out = rt.Sprite(...)
                out:set_minimum_size(out:get_resolution())
                return out
            end

            local n_move_slots, move_slots = template:list_move_slots(entity)
            for i = 1, n_move_slots do
                if move_slots[i] ~= nil then
                    table.insert(to_push.move_sprites, small_sprite(move_slots[i]:get_sprite_id()))
                end
            end

            if sizeof(to_push.move_sprites) == 0 then
                table.insert(to_push.move_sprites, self._description(translation.no_moves))
            end

            local n_equip_slots, equip_slots = template:list_equip_slots(entity)
            for i = 1, n_equip_slots do
                if equip_slots[i] ~= nil then
                    table.insert(to_push.equip_sprites, small_sprite(equip_slots[i]:get_sprite_id()))
                end
            end

            local n_consumable_slots, consumable_slots = template:list_consumable_slots(entity)
            for i = 1, n_consumable_slots do
                if consumable_slots[i] ~= nil then
                    table.insert(to_push.consumable_sprites, small_sprite(consumable_slots[i]:get_sprite_id()))
                end
            end

            if sizeof(to_push.equip_sprites) == 0 and sizeof(to_push.consumable_sprites) == 0 then
                table.insert(to_push.equip_sprites, self._description(translation.no_equips))
            end

            for widget in range(to_push.name_label, to_push.move_label, to_push.equip_and_consumable_label, to_push.hrule) do
                widget:realize()
                table.insert(self.content, widget)
            end

            for t in range(to_push.move_sprites, to_push.equip_sprites, to_push.consumable_sprites) do
                for sprite in values(t) do
                    sprite:realize()
                    table.insert(self.content, sprite)
                end
            end

            table.insert(self.entities, to_push)
        end
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        local start_y = y + 2 * ym
        local start_x = x + xm
        local current_x, current_y = start_x, start_y
        local w = width - 2 * xm

        self.title_label:fit_into(current_x, current_y, w)
        current_y = current_y + select(2, self.title_label:measure()) + m

        local sprite_w, sprite_h = 32, 32
        local tab = 2 * xm
        for element in values(self.entities) do
            element.name_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
            current_y = current_y + select(2, element.name_label:measure()) + m

            element.move_label:fit_into(current_x + xm, current_y)
            current_y = current_y + select(2, element.move_label:measure()) + 0.5 * m

            local sprite_start_x = current_x + xm + xm
            local sprite_x = current_x + xm + xm

            local n_moves = sizeof(element.move_sprites)
            for i = 1, n_moves do
                local sprite = element.move_sprites[i]
                sprite:fit_into(sprite_x, current_y, sprite_w, sprite_h)
                sprite_x = sprite_x + sprite_w

                if sprite_x + sprite_w > start_x + w - xm and i ~= n_moves then
                    sprite_x = sprite_start_x
                    current_y = current_y + sprite_w
                end
            end

            current_y = current_y + sprite_w + m

            element.equip_and_consumable_label:fit_into(current_x + xm, current_y)
            current_y = current_y + select(2, element.move_label:measure()) + 0.5 * m

            sprite_x = sprite_start_x
            local n_equips = sizeof(element.equip_sprites)
            for i = 1, n_equips do
                local sprite = element.equip_sprites[i]
                sprite:fit_into(sprite_x, current_y, sprite_w, sprite_h)
                sprite_x = sprite_x + sprite_w

                if sprite_x + sprite_w > start_x + w - xm then
                    sprite_x = sprite_start_x
                    current_y = current_y + sprite_h
                end
            end

            local n_consumables = sizeof(element.consumable_sprites)
            for i = 1, n_consumables do
                local sprite = element.consumable_sprites[i]
                sprite:fit_into(sprite_x, current_y, sprite_w, sprite_h)
                sprite_x = sprite_x + sprite_w

                if sprite_x + sprite_w > start_x + w - xm and i + n_equips < n_equips + n_consumables then
                    sprite_x = sprite_start_x
                    current_y = current_y + sprite_h
                end
            end

            current_y = current_y + sprite_h + m
            element.hrule:fit_into(current_x, current_y, w, 0)
            current_y = current_y + 2 * m + 3
        end

        current_y = current_y - m

        self.created_on_label:fit_into(start_x, current_y, w)
        current_y = current_y + select(2, self.created_on_label:measure()) + 2 * ym

        local total_height = current_y - y
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

--- @brief party info
function mn.VerboseInfoPanel.Item:create_from_entity(entity)
    self.object = entity
    self._is_realized = false

    local format_title = function(str)
        return "<b><u>" .. str .. "</u></b>"
    end

    -- TODO: don't use global STATE

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.title_label = rt.Label(format_title(entity:get_name()))
        self.title_label:realize()
        self.title_label:set_justify_mode(rt.JustifyMode.LEFT)

        self.content = {
            self.title_label
        }

        local translation = rt.Translation.verbose_info

        for stat_color_label in range(
            {"hp", "HP", translation.hp_label},
            {"attack", "ATTACK", translation.attack_label},
            {"defense", "DEFENSE", translation.defense_label},
            {"speed", "SPEED", translation.speed_label}
        ) do
            local stat, color, label = table.unpack(stat_color_label)
            local prefix_label = self._prefix(label, color)
            prefix_label:realize()
            local colon = self._colon()
            local value_label = self._number("<color=" .. color .. ">" .. tostring(STATE["entity_get_" .. stat](STATE, entity)) .. "</color>")

            self[stat .. "_prefix_label"] = prefix_label
            self[stat .. "_colon_label"] = colon
            self[stat .. "_value_label"] = value_label

            for label in range(prefix_label, colon, value_label) do
                table.insert(self.content, label)
            end
        end

        local font, mono_font = rt.settings.font.default_small, rt.settings.font.default_mono_small
        self.move_label = rt.Label(translation.entity_move_heading, font, mono_font)
        self.move_sprites = {}
        self.move_names = {}

        self.equip_label = rt.Label(translation.entity_equip_heading, font, mono_font)
        self.equip_sprites = {}
        self.equip_names = {}

        self.consumable_label = rt.Label(translation.entity_consumable_heading, font, mono_font)
        self.consumable_sprites = {}
        self.consumable_names = {}

        local n_move_slots, move_slots = STATE:entity_list_move_slots(entity)
        for i = 1, n_move_slots do
            if move_slots[i] ~= nil then
                table.insert(self.move_sprites, rt.Sprite(move_slots[i]:get_sprite_id()))
                table.insert(self.move_names, self._prefix(move_slots[i]:get_name()))
            end
        end

        if sizeof(self.move_sprites) == 0 then
            table.insert(self.move_names, self._description(translation.no_moves))
        end

        local n_equip_slots, equip_slots = STATE:entity_list_equip_slots(entity)
        for i = 1, n_equip_slots do
            if equip_slots[i] ~= nil then
                table.insert(self.equip_sprites, rt.Sprite(equip_slots[i]:get_sprite_id()))
                table.insert(self.equip_names, self._prefix(equip_slots[i]:get_name()))
            end
        end

        if sizeof(self.equip_sprites) == 0 then
            table.insert(self.equip_names, self._description(translation.no_equips))
        end

        local n_consumable_slots, consumable_slots = STATE:entity_list_consumable_slots(entity)
        for i = 1, n_consumable_slots do
            if consumable_slots[i] ~= nil then
                table.insert(self.consumable_sprites, rt.Sprite(consumable_slots[i]:get_sprite_id()))
                table.insert(self.consumable_names, self._prefix(consumable_slots[i]:get_name()))
            end
        end

        if sizeof(self.consumable_sprites) == 0 then
            table.insert(self.consumable_names, self._description(translation.no_consumables))
        end

        for widget in range(self.name_label, self.move_label, self.equip_label, self.consumable_label, self.hrule) do
            widget:realize()
            table.insert(self.content, widget)
        end

        for t in range(self.move_sprites, self.equip_sprites, self.consumable_sprites) do
            for sprite in values(t) do
                sprite:set_minimum_size(sprite:get_resolution())
                sprite:realize()
                table.insert(self.content, sprite)
            end
        end

        for t in range(self.move_names, self.equip_names, self.consumable_names) do
            for label in values(t) do
                table.insert(self.content, label)
            end
        end

        local flavor_text = entity:get_config():get_flavor_text()
        if #flavor_text ~= 0 then
            self.spacer = self._hrule()
            self.flavor_text_label = self._flavor_text(flavor_text)

            table.insert(self.content, self.spacer)
            table.insert(self.content, self.flavor_text_label)
        end
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        local start_y = y + 2 * ym
        local start_x = x + xm
        local current_x, current_y = start_x, start_y
        local w = width - 2 * xm

        self.title_label:fit_into(current_x, current_y, w)
        current_y = current_y + select(2, self.title_label:measure()) + m

        for stat in range("hp", "attack", "defense", "speed") do
            local prefix_label = self[stat .. "_prefix_label"]
            local colon_label = self[stat .. "_colon_label"]
            local value_label = self[stat .. "_value_label"]

            if value_label ~= nil then
                local value_w, value_h = value_label:measure()
                prefix_label:fit_into(current_x, current_y, POSITIVE_INFINITY)
                local colon_w = select(1, colon_label:measure())
                colon_label:fit_into(current_x + w / 2 - colon_w / 2, current_y, POSITIVE_INFINITY)
                value_label:fit_into(current_x + w - value_w, current_y, POSITIVE_INFINITY)

                current_y = current_y + value_h
            end
        end

        current_y = current_y + m

        local sprite_w, sprite_h = 32, 32
        local tab = 2 * xm

        local sprite_start_x = current_x + xm
        local sprite_x = sprite_start_x

        for which in range("move", "consumable", "equip") do
            self[which .. "_label"]:fit_into(current_x, current_y)
            current_y = current_y + select(2, self.move_label:measure()) + 0.5 * m

            local n = sizeof(self[which .. "_names"])
            for i = 1, n do
                local sprite = self[which .. "_sprites"][i]
                local label = self[which .. "_names"][i]

                local label_w, label_h = label:measure()
                local row_h = math.max(label_h, sprite_h)

                if sprite ~= nil then
                    sprite:fit_into(sprite_x, current_y + 0.5 * row_h - 0.5 * sprite_h, sprite_w, sprite_h)
                end
                label:fit_into(sprite_x + sprite_w + m, current_y + 0.5 * row_h - 0.5 * label_h, POSITIVE_INFINITY)

                current_y = current_y + row_h
            end
        end

        current_y = current_y + m

        if self.spacer ~= nil then
            self.spacer:fit_into(current_x, current_y, w, 0)
            current_y = current_y + select(2, self.spacer:measure()) + m

            self.flavor_text_label:fit_into(current_x, current_y, w, POSITIVE_INFINITY)
            current_y = current_y + select(2, self.flavor_text_label:measure()) + m
            current_y = current_y + ym
        end

        local total_height = current_y - y
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

--- @brief party info
function mn.VerboseInfoPanel.Item:create_from_enum(which)
    self.object = nil
    self._is_realized = false

    if which == rt.VerboseInfoObject.MSAA_WIDGET then
        self:create_as_msaa_widget()
        return
    elseif which == rt.VerboseInfoObject.GAMMA_WIDGET then
        self:create_as_gamma_widget()
        return
    elseif which == rt.VerboseInfoObject.MOTION_EFFECTS_WIDGET then
        self:create_as_motion_effects_widget()
        return
    elseif which == rt.VerboseInfoObject.VISUAL_EFFECTS_WIDGET then
        self:create_as_visual_effects_widget()
        return
    elseif which == rt.VerboseInfoObject.DEADZONE_WIDGET then
        self:create_as_deadzone_widget()
        return
    end

    local format_title = function(str)
        return "<b><u>" .. str .. "</u></b>"
    end

    local translation = rt.Translation.verbose_info.objects
    local titles = {
        [rt.VerboseInfoObject.HP] = format_title(translation.hp_title),
        [rt.VerboseInfoObject.ATTACK] = format_title(translation.attack_title),
        [rt.VerboseInfoObject.DEFENSE] = format_title(translation.defense_title),
        [rt.VerboseInfoObject.SPEED] = format_title(translation.speed_title),

        [rt.VerboseInfoObject.CONSUMABLE] = format_title(translation.consumables_title),
        [rt.VerboseInfoObject.EQUIP] = format_title(translation.equips_title),
        [rt.VerboseInfoObject.MOVE] = format_title(translation.moves_title),
        [rt.VerboseInfoObject.TEMPLATE] = format_title(translation.templates_title),

        [rt.VerboseInfoObject.OPTIONS] = format_title(translation.options_title),
        [rt.VerboseInfoObject.VSYNC] = format_title(translation.vsync_title),
        [rt.VerboseInfoObject.GAMMA] = format_title(translation.gamma_title),
        [rt.VerboseInfoObject.FULLSCREEN] = format_title(translation.fullscreen_title),
        [rt.VerboseInfoObject.RESOLUTION] = format_title(translation.resolution_title),
        [rt.VerboseInfoObject.SOUND_EFFECTS] = format_title(translation.sound_effects_title),
        [rt.VerboseInfoObject.MUSIC] = format_title(translation.music_title),

        [rt.VerboseInfoObject.MOTION_EFFECTS] = format_title(translation.motion_effects_title),
        [rt.VerboseInfoObject.VISUAL_EFFECTS] = format_title(translation.visual_effects_title),
        [rt.VerboseInfoObject.MSAA] = format_title(translation.msaa_title),
        [rt.VerboseInfoObject.DEADZONE] = format_title(translation.deadzone_title),
        [rt.VerboseInfoObject.KEYMAP] = format_title(translation.keymap_title)
    }

    local descriptions = {
        [rt.VerboseInfoObject.HP] = translation.hp_description,
        [rt.VerboseInfoObject.ATTACK] = translation.attack_description,
        [rt.VerboseInfoObject.DEFENSE] = translation.defense_description,
        [rt.VerboseInfoObject.SPEED] = translation.speed_description,

        [rt.VerboseInfoObject.CONSUMABLE] = translation.consumables_description,
        [rt.VerboseInfoObject.EQUIP] = translation.equips_description,
        [rt.VerboseInfoObject.MOVE] = translation.moves_description,
        [rt.VerboseInfoObject.TEMPLATE] = translation.templates_description,

        [rt.VerboseInfoObject.OPTIONS] = translation.options_description,

        [rt.VerboseInfoObject.VSYNC] = translation.vsync_description,
        [rt.VerboseInfoObject.MSAA] = translation.msaa_description,
        [rt.VerboseInfoObject.GAMMA] = translation.gamma_description,
        [rt.VerboseInfoObject.FULLSCREEN] = translation.fullscreen_description,
        [rt.VerboseInfoObject.RESOLUTION] = translation.resolution_description,
        [rt.VerboseInfoObject.SOUND_EFFECTS] = translation.sound_effects_description,
        [rt.VerboseInfoObject.MUSIC] = translation.music_description,

        [rt.VerboseInfoObject.MOTION_EFFECTS] = translation.motion_effects_description,
        [rt.VerboseInfoObject.VISUAL_EFFECTS] = translation.visual_effects_description,

        [rt.VerboseInfoObject.DEADZONE] = translation.deadzone_description,
        [rt.VerboseInfoObject.KEYMAP] = translation.keymap_description
    }

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.title_label = rt.Label(titles[which])
        self.title_label:realize()
        self.title_label:set_justify_mode(rt.JustifyMode.LEFT)

        self.description_label = self._description(descriptions[which])

        self.content = {
            self.title_label,
            self.description_label,
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        local start_y = y + ym
        local current_x, current_y = x + xm, start_y + ym
        local w = width - 2 * xm

        self.title_label:fit_into(current_x, current_y, w)
        current_y = current_y + select(2, self.title_label:measure()) + m

        self.description_label:fit_into(current_x, current_y, w)

        current_y = current_y + select(2, self.description_label:measure()) + m

        local total_height = current_y - start_y + 2 * ym
        self.frame:fit_into(x, y, width, total_height)
        self.divider:resize(x, y + total_height, x + width, y + total_height)
        self.final_height = total_height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

function mn.VerboseInfoPanel.Item:create_as_gamma_widget()
    self.object = nil
    self._is_realized = false

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.widget = rt.Sprite("gamma_test_image")
        self.widget:realize()

        self.content = {
            self.widget
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        ym = 2 * ym
        local w = 0.75 * (width - 2 * xm)
        height = w + 2 * ym
        self.widget:fit_into(
            x + 0.5 * width - 0.5 * w,
            y + 0.5 * height - 0.5 * w,
            w,
            w
        )

        self.frame:fit_into(x, y, width, height)
        self.divider:resize(x, y + height, x + width, y + height)
        self.final_height = height
    end

    self.measure = function(self)
        return self._bounds.width, self.final_height
    end

    return self
end

function mn.VerboseInfoPanel.Item:create_as_visual_effects_widget()
    self.object = nil
    self._is_realized = false

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.widget = rt.Background(rt.Background.CONTRAST_TEST)
        self.widget:realize()

        self.content = {
            self.widget
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        ym = 2 * ym
        local w = 0.75 * (width - 2 * xm)
        height = w + 2 * ym
        self.widget:fit_into(
            x + 0.5 * width - 0.5 * w,
            y + 0.5 * height - 0.5 * w,
            w,
            w
        )

        self.frame:fit_into(x, y, width, height)
        self.divider:resize(x, y + height, x + width, y + height)
        self.final_height = height
    end

    self.update = function(self, delta)
        self.widget:update(delta)
    end
end

function mn.VerboseInfoPanel.Item:create_as_motion_effects_widget()
    self.object = nil
    self._is_realized = false

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.widget = mn.ShakeIntensityWidget()
        self.widget:realize()

        self.content = {
            self.widget
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        ym = 2 * ym
        local w = 0.75 * (width - 2 * xm)
        height = w + 2 * ym
        self.widget:fit_into(
            x + 0.5 * width - 0.5 * w,
            y + 0.5 * height - 0.5 * w,
            w,
            w
        )

        self.frame:fit_into(x, y, width, height)
        self.divider:resize(x, y + height, x + width, y + height)
        self.final_height = height
    end

    self.update = function(self, delta)
        self.widget:update(delta)
    end
end


function mn.VerboseInfoPanel.Item:create_as_msaa_widget()
    self.object = nil
    self._is_realized = false

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.widget = mn.MSAAIntensityWidget()
        self.widget:realize()

        self.content = {
            self.widget
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        ym = 2 * ym
        local w = 0.75 * (width - 2 * xm)
        height = w + 2 * ym
        self.widget:fit_into(
            x + 0.5 * width - 0.5 * w,
            y + 0.5 * height - 0.5 * w,
            w,
            w
        )

        self.frame:fit_into(x, y, width, height)
        self.divider:resize(x, y + height, x + width, y + height)
        self.final_height = height
    end

    self.update = function(self, delta)
        self.widget:update(delta)
    end
end

function mn.VerboseInfoPanel.Item:create_as_deadzone_widget()
    self.object = nil
    self._is_realized = false

    self.realize = function()
        self._is_realized = true
        self.frame:realize()

        self.widget = mn.DeadzoneVisualizationWidget()
        self.widget:realize()

        self.content = {
            self.widget
        }
    end

    self.size_allocate = function(self, x, y, width, height)
        local m, xm, ym = self._get_margin()
        ym = 2 * ym
        local w = 0.75 * (width - 2 * xm)
        height = w + 2 * ym
        self.widget:fit_into(
            x + 0.5 * width - 0.5 * w,
            y + 0.5 * height - 0.5 * w,
            w,
            w
        )

        self.frame:fit_into(x, y, width, height)
        self.divider:resize(x, y + height, x + width, y + height)
        self.final_height = height
    end

    self.update = function(self, delta)
        self.widget:update(delta)
    end
end


