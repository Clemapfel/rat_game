
--- @class bt.EntityInfo
bt.EntityInfo = meta.new_type("EntityInfo", rt.Widget, function(entity)
    return meta.new(bt.EntityInfo, {
        _entity = entity,
        _backdrop = {}, -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer
        _name_label = {}, -- rt.Label
        _attack_preview = nil,
        _defense_preview = nil,
        _speed_preview = nil,
    })
end)


function bt.EntityInfo:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._backdrop = rt.Frame()
    self._backdrop_backing = rt.Spacer()
    self._backdrop:set_child(self._backdrop_backing)
    self._backdrop:realize()

    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label("<o>" .. str .. "</o>", rt.settings.font.default, rt.settings.font.default_mono)
        out:realize()
        out:set_justify_mode(rt.JustifyMode.LEFT)
        return out
    end

    self._name_label = new_label("<u><b>", self._entity:get_name(), "</b></u>")

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    local create_stat_prefix = function(label)
        return "<b>" .. label .. "</b>"
    end

    local hp_prefix = "<color=HP>"
    local hp_postfix = "</color>"
    self._hp_label_left = new_label(hp_prefix, create_stat_prefix("HP"), hp_postfix)
    if self._entity:get_is_dead() then
        self._hp_label_right = new_label("<color=GRAY_02>DEAD</color>")
    elseif self._entity:get_is_knocked_out() then
        self._hp_label_right = new_label("<color=RED>KNOCKED OUT</color>")
    else
        if false then --self._entity:get_is_enemy() then
            self._hp_label_right = new_label(number_prefix, hp_prefix, "? / ?", hp_postfix, number_postfix)
        else
            self._hp_label_right = new_label(number_prefix, hp_prefix, self._entity:get_hp_current(), " / ", self._entity:get_hp_base(), hp_postfix, number_postfix)
        end
    end

    local arrow_right = " → <u><b>"
    local arrow_right_postfix = "</u></b>"

    local attack_prefix = "<color=ATTACK>"
    local attack_postfix = "</color>"
    self._attack_label_left = new_label(attack_prefix, create_stat_prefix("ATK"), attack_postfix)
    if self._entity:get_is_enemy() == true then
        if self._attack_preview == nil then
            self._attack_label_right = new_label(number_prefix, attack_prefix, self._entity:get_attack(), attack_postfix, number_postfix)
        else
            self._attack_label_right = new_label(number_prefix, attack_prefix, self._entity:get_attack(), arrow_right, self._attack_preview, arrow_right_postfix, attack_postfix, number_postfix)
        end
    else
        if self._attack_preview ~= nil then
            self._attack_label_right = new_label(number_prefix, attack_prefix, "?", attack_postfix, number_postfix)
        else
            self._attack_label_right = new_label(number_prefix, attack_prefix, "?", arrow_right, "?", arrow_right_postfix, attack_postfix, number_postfix)
        end
    end

    local defense_prefix = "<color=DEFENSE>"
    local defense_postfix = "</color>"
    self._defense_label_left = new_label(defense_prefix, create_stat_prefix("DEF"), defense_postfix)
    if self._entity:get_is_enemy() == true then
        if self._defense_preview == nil then
            self._defense_label_right = new_label(number_prefix, defense_prefix, self._entity:get_defense(), defense_postfix, number_postfix)
        else
            self._defense_label_right = new_label(number_prefix, defense_prefix, self._entity:get_defense(), arrow_right, self._defense_preview, arrow_right_postfix, defense_postfix, number_postfix)
        end
    else
        if self._defense_preview ~= nil then
            self._defense_label_right = new_label(number_prefix, defense_prefix, "?", defense_postfix, number_postfix)
        else
            self._defense_label_right = new_label(number_prefix, defense_prefix, "?", arrow_right, "?", arrow_right_postfix, defense_postfix, number_postfix)
        end
    end

    local speed_prefix = "<color=SPEED>"
    local speed_postfix = "</color>"
    self._speed_label_left = new_label(speed_prefix, create_stat_prefix("SPD"), speed_postfix)
    if self._entity:get_is_enemy() == true then
        if self._speed_preview == nil then
            self._speed_label_right = new_label(number_prefix, speed_prefix, self._entity:get_speed(), speed_postfix, number_postfix)
        else
            self._speed_label_right = new_label(number_prefix, speed_prefix, self._entity:get_speed(), arrow_right, self._speed_preview, arrow_right_postfix, speed_postfix, number_postfix)
        end
    else
        if self._speed_preview ~= nil then
            self._speed_label_right = new_label(number_prefix, speed_prefix, "?", speed_postfix, number_postfix)
        else
            self._speed_label_right = new_label(number_prefix, speed_prefix, "?", arrow_right, "?", arrow_right_postfix, speed_postfix, number_postfix)
        end
    end

    local realize = function(x)
        x:realize()
        return x
    end

    self._status_label_left = new_label("<u><b>Status</b></u>")

    if is_empty(self._entity:get_status()) then
        self._status_label_right = new_label(number_prefix .. "(None)" .. number_postfix)
    else
        self._status_label_right = new_label("")
    end

    self._status_items = {}
    for status in values(self._entity:list_statuses()) do
        local elapsed = self._entity:get_status_n_turns_elapsed(status)
        local max = status:get_max_duration()
        local n_left_str = "    <mono><b>∞</b></mono>"

        if max ~= POSITIVE_INFINITY then
            local current = elapsed
            local n_left = max - current
            n_left_str = "<mono><b>" .. elapsed .. "</b></mono>" .. " turns left"
        end

        table.insert(self._status_items, {
            sprite = realize(rt.Sprite(status.sprite_id)),
            left = new_label(status.name),
            right = new_label(n_left_str)
        })
    end

    self._backdrop:realize()
end

function bt.EntityInfo:size_allocate(x, y, width, height)
    local once = true

    local m = rt.settings.margin_unit
    local current_x, current_y = m, m
    ::restart::

    self._name_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self._name_label:measure()) + m

    local stat_align = current_x + 4 * self._name_label:get_font():get_size()
    current_y = current_y + m

    self._hp_label_left:fit_into(current_x, current_y, width, height)
    self._hp_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self._hp_label_left:measure())

    self._attack_label_left:fit_into(current_x, current_y, width, height)
    self._attack_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self._attack_label_left:measure())

    self._defense_label_left:fit_into(current_x, current_y, width, height)
    self._defense_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self._defense_label_left:measure())

    self._speed_label_left:fit_into(current_x, current_y, width, height)
    self._speed_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self._speed_label_left:measure())
    current_y = current_y + m

    self._status_label_left:fit_into(current_x, current_y, width, height)
    self._status_label_right:fit_into(stat_align, current_y, width, height)
    current_y = current_y + select(2, self._status_label_left:measure()) + m

    local max_width = 0
    for item in values(self._status_items) do
        local sprite_size = select(2, item.sprite:measure())
        item.sprite:fit_into(current_x + m, current_y, sprite_size, sprite_size)

        -- run resize twice, to properly gaige label height after wrapping
        local label_height = select(2, item.left:measure())
        local label_y = current_y + 0.5 * sprite_size - 0.5 * label_height
        local label_left_width = 2 * stat_align + m
        item.left:fit_into(current_x + sprite_size + 2 * m, label_y, label_left_width - 4 * m, sprite_size)
        item.right:fit_into(label_left_width, label_y, label_left_width - 4 * m, sprite_size)

        -- max width will be reached here
        local right_bounds = item.right:get_bounds()
        max_width = math.max(max_width, right_bounds.x + right_bounds.width - current_x)
        current_y = current_y + math.max(sprite_size, select(2, item.left:measure()))
    end

    -- restart size negotiation
    if max_width > width and once then
        once = false
        width = max_width
    end

    x, y, width, height = 0, 0, max_width, current_y - y

    self._backdrop:fit_into(x, y, width, current_y - y + 2 * m)
end

function bt.EntityInfo:draw()
    self._backdrop:draw()
    self._name_label:draw()

    for drawable in range(
        self._hp_label_left,
        self._hp_label_right,
        self._attack_label_left,
        self._attack_label_right,
        self._defense_label_left,
        self._defense_label_right,
        self._speed_label_left,
        self._speed_label_right,
        self._status_label_left,
        self._status_label_right
    ) do
        drawable:draw()
    end

    for item in values(self._status_items) do
        item.sprite:draw()
        item.left:draw()
        item.right:draw()
    end
end
