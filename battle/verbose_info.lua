--- @class
bt.VerboseInfo = meta.new_type("VerboseInfo", rt.Widget, function()
    return meta.new(bt.VerboseInfo, {
        _pages = {}, -- Table<Any, bt.VerboseInfo.Page>
        _visible_page = nil,
    })
end)

--- @brief
function bt.VerboseInfo:size_allocate(x, y, width, height)
    if self._is_realized == false then return end

    local bounds = self._bounds
    local page = self._visible_page
    if page ~= nil then
        page._position_x = bounds.x
        page._position_y = bounds.y

        if self._visible_page._backdrop_initialized ~= nil then
            page._backdrop = rt.Frame()
            page._backdrop_backing = rt.Spacer()
            page._backdrop:realize()
            page._backdrop_backing:realize()
            page._backdrop:set_child(page._backdrop_backing)
        end

        local xm, ym = rt.settings.margin_unit * 2, rt.settings.margin_unit
        page._backdrop:fit_into(-xm, -ym, page._width + 2 * xm, page._height + 2 * ym)
    end
end

--- @brief
function bt.VerboseInfo:draw()
    local page = self._visible_page
    if page ~= nil then
        rt.graphics.push()
        rt.graphics.translate(page._position_x, page._position_y)
        page._backdrop:draw()
        for x in values(page._content) do
            x:draw()
        end
        rt.graphics.pop()
    end
end

--- @brief
function bt.VerboseInfo:add(object, ...)
    local new_page = bt.VerboseInfo.Page()
    self._pages[object] = new_page

    if meta.isa(object, bt.Entity) then
        new_page:create_from_entity(object, ...)
    elseif meta.isa(object, bt.Move) then
        new_page:create_from_move(object, ...)
    elseif meta.isa(object, bt.Status) then
        new_page:create_from_status(object, ...)
    elseif meta.isa(object, bt.GlobalStatus) then
        new_page:create_from_global_status(object, ...)
    elseif meta.isa(object, bt.Consumable) then
        new_page:create_from_consumable(object, ...)
    elseif meta.isa(object, bt.Equip) then
        new_page:create_from_equip(object, ...)
    else
        rt.error("In bt.VerboseInfo.add: unhandled entity type `" .. meta.typeof(object) .. "`")
    end

    return new_page
end

--- @brief
function bt.VerboseInfo:show(object, ...)
    local page = self._pages[object]
    if page == nil then
        page = self:add(object, ...)
    end

    self._visible_page = page
    self:reformat()
end

--- @class
bt.VerboseInfo.Page = meta.new_type("VerboseInfoPage", function()
    return meta.new(bt.VerboseInfo.Page, {
        _position_x = 0,
        _position_y = 0,
        _width = 1,
        _height = 1,
        _backdrop_initialized = false,
        _backdrop = {}, -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer
    })
end)

bt.VerboseInfo.Page._new_label = function(...)
    local str = ""
    for _, v in pairs({...}) do
        str = str .. tostring(v)
    end
    local out = rt.Label(str, rt.settings.font.default_small, rt.settings.font.default_mono_small)
    out:realize()
    out:set_justify_mode(rt.JustifyMode.LEFT)
    return out
end

--- @brief
function bt.VerboseInfo.Page:create_from_entity(entity)
    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default_small, rt.settings.font.default_mono_small)
        out:realize()
        out:set_justify_mode(rt.JustifyMode.LEFT)
        return out
    end

    self._name_label = new_label("<u><b>", entity:get_name(), "</b></u>")

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    local create_stat_prefix = function(label)
        return "<b>" .. label .. "</b>"
    end

    local hp_prefix = "<color=HP>"
    local hp_postfix = "</color>"
    self._hp_label_left = new_label(hp_prefix, create_stat_prefix("HP"), hp_postfix)

    if entity:get_is_dead() then
        self._hp_label_right = new_label("<color=GRAY_02>DEAD</color>")
    elseif entity:get_is_knocked_out() then
        self._hp_label_right = new_label("<color=RED>KNOCKED OUT</color>")
    else
        if entity:get_is_enemy() then
            self._hp_label_right = new_label(number_prefix, hp_prefix, "? / ?", hp_postfix, number_postfix)
        else
            self._hp_label_right = new_label(number_prefix, hp_prefix, entity:get_hp_current(), " / ", entity:get_hp_base(), hp_postfix, number_postfix)
        end
    end

    local attack_prefix = "<color=ATTACK>"
    local attack_postfix = "</color>"
    self._attack_label_left = new_label(attack_prefix, create_stat_prefix("ATK"), attack_postfix)
    if entity:get_is_enemy() == false then
        self._attack_label_right = new_label(number_prefix, attack_prefix, entity:get_attack(), attack_postfix, number_postfix)
    else
        self._attack_label_right = new_label(number_prefix, attack_prefix, "?", attack_postfix, number_postfix)
    end

    local defense_prefix = "<color=DEFENSE>"
    local defense_postfix = "</color>"
    self._defense_label_left = new_label(defense_prefix, create_stat_prefix("DEF"), defense_postfix)
    if entity:get_is_enemy() == false then
        self._defense_label_right = new_label(number_prefix, defense_prefix, entity:get_defense(), defense_postfix, number_postfix)
    else
        self._defense_label_right = new_label(number_prefix, defense_prefix, "?", defense_postfix, number_postfix)
    end

    local speed_prefix = "<color=SPEED>"
    local speed_postfix = "</color>"
    self._speed_label_left = new_label(speed_prefix, create_stat_prefix("SPD"), speed_postfix)
    if entity:get_is_enemy() == false then
        self._speed_label_right = new_label(number_prefix, speed_prefix, entity:get_speed(), speed_postfix, number_postfix)
    else
        self._speed_label_right = new_label(number_prefix, speed_prefix, "?", speed_postfix, number_postfix)
    end

    local description_prefix = "<b><u>Description</u></b>"
    self._description_label = new_label(description_prefix .. ": " .. entity:get_description() .. "")

    -- size allocate

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY

    self._name_label:fit_into(current_x, current_y, label_w, label_h)
    measure(self._name_label)
    current_y = current_y + h

    local stat_align = current_x + 6 * self._name_label:get_font():get_size()
    current_y = current_y + m

    self._hp_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._hp_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._hp_label_right)
    current_y = current_y + h

    self._attack_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._attack_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._attack_label_right)
    current_y = current_y + h

    self._defense_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._defense_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._defense_label_right)
    current_y = current_y + h

    self._speed_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._speed_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._speed_label_right)
    current_y = current_y + h + m

    self._description_label:fit_into(current_x, current_y, max_x, label_h)
    current_y = current_y + select(2, self._description_label:measure())

    self._width = max_x
    self._height = current_y

    self._content = {
        self._name_label,
        self._hp_label_left,
        self._hp_label_right,
        self._attack_label_left,
        self._attack_label_right,
        self._defense_label_left,
        self._defense_label_right,
        self._speed_label_left,
        self._speed_label_right,
        self._description_label
    }
end

--- @brief
function bt.VerboseInfo.Page:create_from_move(move)
    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default_small, rt.settings.font.default_mono_small)
        out:realize()
        out:set_justify_mode(rt.JustifyMode.LEFT)
        return out
    end

    self._name_label = new_label("<u><b>", move:get_name(), "</b></u>  (", ternary(move:get_max_n_uses() == POSITIVE_INFINITY, "\u{221E}", tostring(move:get_max_n_uses())), ")")

    local sprite_id, sprite_index = move:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_animation(sprite_index)

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    -- target
    local me, enemy, ally = move:get_can_target_self(), move:get_can_target_enemy(), move:get_can_target_ally()

    local function _ally(str)
        return "<b><color=ALLY>" .. str .. "</color></b>"
    end

    local function _enemy(str)
        return "<b><color=ENEMY>" .. str .. "</color></b>"
    end

    local function _me(str)
        return "<b><color=SELF>" .. str .. "</color></b>"
    end

    local function _field()
        return "<b><color=GRAY_2>" .. " ――― " .. "</color></b>"
    end

    local function _everyone(str)
        return "<b><color=FIELD>" .. str .. "</color></b>"
    end

    local target_str = ""
    if move:get_can_target_multiple() == false then
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
            target_str = _ally("single ally") .. " or " .. _enemy("single enemy")
        elseif not me and not ally and not enemy then
            target_str = _field()
        end
    else
        if         me and not ally and not enemy then
            target_str = _me("self")
        elseif     me and     ally and     enemy then
            target_str = _everyone("everyone")
        elseif     me and     ally and not enemy then
            target_str = _ally("all allies and self")
        elseif     me and not ally and     enemy then
            target_str = _me("self") .. " and " .. _enemy("all enemies")
        elseif not me and     ally and not enemy then
            target_str = _ally("all allies") .. " except " .. _me("self")
        elseif not me and not ally and     enemy then
            target_str = _enemy("all enemies")
        elseif not me and     ally and     enemy then
            target_str = _everyone("everyone") .. " except " .. _me("self")
        elseif not me and not ally and not enemy then
            target_str = _field()
        end
    end

    self._target_label = new_label("<u>Targets</u> <color=" .. gray .. "><b>:</b></color> ", target_str)
    self._effect_label = new_label("<u>Effect</u> <color=" .. gray .. "><b>:</b></color> " .. move:get_description() .. ".")

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
    self._priority_label = new_label("<u>Priority</u> <color=" .. gray .. "><b>:</b></color> <mono><b>" .. priority_str .. "</b></mono>")

    -- size allocate

    local m = rt.settings.margin_unit
    local current_x, current_y = 0, 0

    local sprite_w, sprite_h = self._sprite:measure()
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY

    local max_x = NEGATIVE_INFINITY
    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    w, h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * h, label_w, label_h)
    max_x = math.max(max_x, w + m + sprite_w)
    current_y = current_y + sprite_h

    self._priority_label:fit_into(current_x, current_y, label_w, label_h)
    measure(self._priority_label)
    current_y = current_y + h

    self._target_label:fit_into(current_x, current_y, label_w, label_h)
    measure(self._target_label)
    current_y = current_y + h + m

    self._effect_label:fit_into(current_x, current_y, max_x, label_h) -- _target_label determines width
    measure(self._effect_label)
    current_y = current_y + h + m

    self._sprite:fit_into(max_x - sprite_w, 0, sprite_w, sprite_h)

    self._content = {
        self._sprite,
        self._name_label,
        self._effect_label,
        self._priority_label,
        self._target_label,
    }

    self._width, self._height = max_x, current_y
end

--- @brief
function bt.VerboseInfo.Page:create_from_status(status, n_turns_left)
    local new_label = bt.VerboseInfo.Page._new_label

    self._name_label = new_label("<u><b>", status:get_name(), "</b></u>")
    self._sprite = rt.Sprite(status:get_sprite_id())
    self._sprite:realize()

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    self._duration_label_left = new_label("Duration")

    if status:get_max_duration() == POSITIVE_INFINITY then
        self._duration_label_right = new_label(number_prefix, "\u{221E}", number_postfix)
    else
        self._duration_label_right = new_label(number_prefix, n_turns_left .. " turns left", number_postfix)
    end

    self._description_label = new_label("<u>Effect</u>: " .. status:get_description())

    self._content = {}
    for label in range(self._name_label, self._sprite, self._duration_label_left, self._duration_label_right, self._description_label) do
        table.insert(self._content, label)
    end

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
            return "\u{00B1}0%" -- plusminus
        end
    end

    for property_label_color in range(
    --[[
    {"attack", "ATK", "ATTACK"},
    {"defense", "DEF", "DEFENSE"},
    {"speed", "SPD", "SPEED"},
    {"damage_dealt", "Damage Dealt", "ATTACK"},
    {"damage_received", "Damage Taken", "DEFENSE"},
    {"healing_performed", "Healing Performed", "HP"},
    {"healing_received", "Healing Received", "HP"}
    ]]--
    ) do
        local property = property_label_color[1]
        local label = property_label_color[2]
        local prefix = "<color=" .. property_label_color[3] .. ">"
        local postfix = "</color>"

        local offset = status[property .. "_offset"]
        if offset ~= 0 then
            local offset_label = "_" .. property .. "_offset_label"
            self[offset_label .. "_left"] = new_label(prefix, label, postfix)
            self[offset_label .. "_right"] = new_label(number_prefix, prefix, create_offset_label(offset), postfix, number_postfix)
            table.insert(self._content, self[offset_label .. "_left"])
            table.insert(self._content, self[offset_label .. "_right"])
        end

        local factor = status[property .. "_factor"]
        if factor ~= 1 then
            local factor_label = "_" .. property .. "_factor_label"
            self[factor_label .. "_left"] = new_label(prefix, label, postfix)
            self[factor_label .. "_right"] = new_label(number_prefix, prefix, create_factor_label(offset), postfix, number_postfix)
            table.insert(self._content, self[factor_label .. "_left"])
            table.insert(self._content, self[factor_label .. "_right"])
        end
    end

    self._stun_label_left = new_label("Is Stun")
    self._stun_label_right = new_label(number_prefix, ternary(status.is_stun, "<b>yes</b>", "no"), number_postfix)
    table.insert(self._content, self._stun_label_left)
    table.insert(self._content, self._stun_label_right)

    -- size allocate

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 6 * self._name_label:get_font():get_size()

    local max_x = NEGATIVE_INFINITY
    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    w, h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * h, label_w, label_h)
    max_x = math.max(max_x, w + m + sprite_w)
    measure(self._name_label)
    current_y = current_y + math.max(sprite_h, h) + m

    self._duration_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._duration_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._duration_label_right)
    current_y = current_y + h

    self._stun_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._stun_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._stun_label_right)
    current_y = current_y + h + m

    local is_present = false
    for property in range(
        "attack",
        "defense",
        "speed",
        "damage_dealt",
        "damage_received",
        "healing_performed",
        "healing_received"
    ) do
        local offset_label = "_" .. property .. "_offset_label"
        if self[offset_label .. "_left"] ~= nil then
            self[offset_label .. "_left"]:fit_into(current_x, current_y, label_w, label_h)
            self[offset_label .. "_right"]:fit_into(stat_align, current_y, label_w, label_h)
            measure(self[offset_label .. "_right"])
            current_y = current_y + h
            is_present = true
        end

        local factor_label = "_" .. property .. "_factor_label"
        if self[factor_label .. "_left"] ~= nil then
            self[factor_label .. "_left"]:fit_into(current_x, current_y, label_w, label_h)
            self[factor_label .. "_right"]:fit_into(stat_align, current_y, label_w, label_h)
            measure(self[factor_label .. "_right"])
            current_y = current_y + h
            is_present = true
        end

    end

    if is_present then current_y = current_y + m end

    self._description_label:fit_into(current_x, current_y, max_x, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(max_x - sprite_w, 0, sprite_w, sprite_h)

    self._width = max_x
    self._height = current_y
end


function bt.VerboseInfo.Page:create_from_global_status(status, n_turns_left)
    local new_label = bt.VerboseInfo.Page._new_label

    self._name_label = new_label("<u><b>", status:get_name(), "</b></u>")
    self._sprite = rt.Sprite(status:get_sprite_id())
    self._sprite:realize()

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    self._duration_label_left = new_label("Duration")

    if status:get_max_duration() == POSITIVE_INFINITY then
        self._duration_label_right = new_label(number_prefix, "\u{221E}", number_postfix)
    else
        self._duration_label_right = new_label(number_prefix, n_turns_left .. " turns left", number_postfix)
    end

    self._description_label = new_label("<u>Effect</u>: " .. status:get_description())

    self._content = {}
    for label in range(self._name_label, self._sprite, self._duration_label_left, self._duration_label_right, self._description_label) do
        table.insert(self._content, label)
    end

    -- size allocate

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 6 * self._name_label:get_font():get_size()

    local max_x = NEGATIVE_INFINITY
    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    w, h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * h, label_w, label_h)
    max_x = math.max(max_x, w + m + sprite_w)
    measure(self._name_label)
    current_y = current_y + math.max(sprite_h, h) + m

    self._duration_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._duration_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._duration_label_right)
    current_y = current_y + h + m

    self._description_label:fit_into(current_x, current_y, max_x, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(max_x - sprite_w, 0, sprite_w, sprite_h)

    self._width = max_x
    self._height = current_y
end

function bt.VerboseInfo.Page:create_from_consumable(consumable, n_uses_left)
    local new_label = bt.VerboseInfo.Page._new_label

    local n_uses_postfix = "(" .. ternary(consumable:get_max_n_uses() == POSITIVE_INFINITY, "\u{221E}", n_uses_left) .. ")"
    self._name_label = new_label("<u><b>", consumable:get_name(), "</b></u> ", n_uses_postfix)
    self._sprite = rt.Sprite(consumable:get_sprite_id())
    self._sprite:realize()

    self._description_label = new_label("<u>Effect</u>: " .. consumable:get_description())

    self._content = {}
    for label in range(self._name_label, self._sprite, self._description_label) do
        table.insert(self._content, label)
    end

    -- size allocate

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 6 * self._name_label:get_font():get_size()

    local max_x = NEGATIVE_INFINITY
    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    w, h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * h, label_w, label_h)
    max_x = math.max(max_x, w + m + sprite_w)
    measure(self._name_label)
    current_y = current_y + math.max(sprite_h, h) + m

    self._description_label:fit_into(current_x, current_y, max_x, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(max_x - sprite_w, 0, sprite_w, sprite_h)

    self._width = max_x
    self._height = current_y
end

function bt.VerboseInfo.Page:create_from_equip(equipment)
    local new_label = bt.VerboseInfo.Page._new_label
    self._name_label = new_label("<u><b>", equipment:get_name(), "</b></u> ")
    self._sprite = rt.Sprite(equipment:get_sprite_id())
    self._sprite:realize()

    self._description_label = new_label("<u>Effect</u>: " .. equipment:get_description())

    self._content = {}
    for label in range(self._name_label, self._sprite, self._description_label) do
        table.insert(self._content, label)
    end

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

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
            return "\u{00B1}0%" -- plusminus
        end
    end

    for property_label_color in range(
        {"attack", "ATK", "ATTACK"},
        {"defense", "DEF", "DEFENSE"},
        {"speed", "SPD", "SPEED"}
    ) do
        local property = property_label_color[1]
        local label = property_label_color[2]
        local prefix = "<color=" .. property_label_color[3] .. ">"
        local postfix = "</color>"

        local offset = equipment[property .. "_base_offset"]
        if offset ~= 0 then
            local offset_label = "_" .. property .. "_offset_label"
            self[offset_label .. "_left"] = new_label(prefix, label, postfix)
            self[offset_label .. "_right"] = new_label(number_prefix, prefix, create_offset_label(offset), postfix, number_postfix)
            table.insert(self._content, self[offset_label .. "_left"])
            table.insert(self._content, self[offset_label .. "_right"])
        end

        local factor = equipment[property .. "_base_factor"]
        if factor ~= 1 then
            local factor_label = "_" .. property .. "_factor_label"
            self[factor_label .. "_left"] = new_label(prefix, label, postfix)
            self[factor_label .. "_right"] = new_label(number_prefix, prefix, create_factor_label(offset), postfix, number_postfix)
            table.insert(self._content, self[factor_label .. "_left"])
            table.insert(self._content, self[factor_label .. "_right"])
        end
    end

    dbg(meta.get_properties(equipment))

    -- size allocate

    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 6 * self._name_label:get_font():get_size()

    local max_x = NEGATIVE_INFINITY
    local w, h
    local measure = function(label)
        w, h = label:measure()
        max_x = math.max(max_x, label:get_bounds().x + w)
    end

    w, h = self._name_label:measure()
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * h, label_w, label_h)
    max_x = math.max(max_x, w + m + sprite_w)
    measure(self._name_label)
    current_y = current_y + math.max(sprite_h, h) + m

    local is_present = false
    for property in range(
        "attack",
        "defense",
        "speed"
    ) do
        local offset_label = "_" .. property .. "_offset_label"
        if self[offset_label .. "_left"] ~= nil then
            self[offset_label .. "_left"]:fit_into(current_x, current_y, label_w, label_h)
            self[offset_label .. "_right"]:fit_into(stat_align, current_y, label_w, label_h)
            measure(self[offset_label .. "_right"])
            current_y = current_y + h
            is_present = true
        end

        local factor_label = "_" .. property .. "_factor_label"
        if self[factor_label .. "_left"] ~= nil then
            self[factor_label .. "_left"]:fit_into(current_x, current_y, label_w, label_h)
            self[factor_label .. "_right"]:fit_into(stat_align, current_y, label_w, label_h)
            measure(self[factor_label .. "_right"])
            current_y = current_y + h
            is_present = true
        end

    end

    if is_present then current_y = current_y + m end

    self._description_label:fit_into(current_x, current_y, max_x, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(max_x - sprite_w, 0, sprite_w, sprite_h)

    self._width = max_x
    self._height = current_y
end



