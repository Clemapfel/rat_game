--- @class bt.VerboseInfo
bt.VerboseInfo = meta.new_type("VerboseInfo", rt.Widget, function()
    return meta.new(bt.VerboseInfo, {
        _visible_pages = {}, -- Table<bt.VerboseInfo.Page>
        _pages = {},
        _position_x = 0,
        _position_y = 0,
        _final_width = 0,
        _final_height = 0
    })
end)

function bt.VerboseInfo:_add(make_visible, ...)
    if make_visible then
        self._visible_pages = {}
    end
    for t in range(...) do
        local object = t[1]
        local page

        if t[2] == nil then
            page = self._pages[object]
        else
            page = self._pages[object]
            if page ~= nil then
                page = page[t[2]]    -- page caching for new durations / n uses
            end
        end

        if page == nil then
            if meta.isa(object, bt.Entity) then
                page = bt.VerboseInfo.Page.ENTITY(table.unpack(t))
            elseif meta.isa(object, bt.Move) then
                page = bt.VerboseInfo.Page.MOVE(table.unpack(t))
            elseif meta.isa(object, bt.Status) then
                page = bt.VerboseInfo.Page.STATUS(table.unpack(t))
            elseif meta.isa(object, bt.GlobalStatus) then
                page = bt.VerboseInfo.Page.GLOBAL_STATUS(table.unpack(t))
            elseif meta.isa(object, bt.Consumable) then
                page = bt.VerboseInfo.Page.CONSUMABLE(table.unpack(t))
            elseif meta.isa(object, bt.Equip) then
                page = bt.VerboseInfo.Page.EQUIP(table.unpack(t))
            else
                rt.error("In bt.VerboseInfo.add: unhandled entity type `" .. meta.typeof(object) .. "`")
            end

            page:realize()

            if t[2] == nil then
                self._pages[object] = page
            else
                self._pages[object] = {}
                self._pages[object][t[2]] = page
            end
        end

        if make_visible then
            table.insert(self._visible_pages, page)
        end
    end

    self:reformat()
end

--- @brief cache all infos immediately
function bt.VerboseInfo:add(...)
    self:_add(false, ...)
end

--- @brief
--- @vararg Table<Table<bt.Any, Number?>>
function bt.VerboseInfo:show(...)
    self:_add(true, ...)
end

--- @override
function bt.VerboseInfo:size_allocate(x, y, width, height)
    -- first pass, measure
    local max_width = 0
    for pages in values(self._pages) do
        for page in values(pages) do
            page:fit_into(0, 0, POSITIVE_INFINITY, POSITIVE_INFINITY)
            max_width = math.max(max_width, page._requested_width)
        end
    end

    local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY

    -- second pass, reformat to max width
    local current_x, current_y = 0, 0
    for page in values(self._visible_pages) do
        local once = false
        ::restart::

        page:fit_into(current_x, current_y, max_width, POSITIVE_INFINITY)
        local h = page._requested_height
        page:_initialize_backdrop(max_width, h)
        local xm, ym = page:_get_backdrop_margins()
        local thickness = page._backdrop:get_thickness()
        current_y = current_y + h + 2 * ym + 2 * thickness

        -- realign when wrapping
        if current_y > y + height then
            current_x = current_x + max_width + 2 * xm + 2 * thickness
            current_y = 0
            if once == false then
                once = true
                goto restart
            end
        end

        max_x = math.max(max_x, current_x + max_width + 2 * xm + 2 * thickness)
        max_y = math.max(max_y, current_y)
    end

    self._position_x = x
    self._position_y = y
    self._final_width = max_x
    self._final_height = max_y

    if #self._visible_pages > 0 then
        self._visible_pages[1]._backdrop:set_color(rt.Palette.SELECTION)
    end
end

--- @override
function bt.VerboseInfo:draw()
    rt.graphics.push()
    rt.graphics.translate(self._position_x, self._position_y)
    for page in values(self._visible_pages) do
        page:draw()
    end
    rt.graphics.pop()
end

--- @override
function bt.VerboseInfo:measure()
    return self._final_width, self._final_height
end

-- ### PAGE ###

--- @class
bt.VerboseInfo.Page = meta.new_abstract_type("VerboseInfoPage", rt.Widget, {
    _requested_width = 0,
    _requested_height = 0,
    _content = {}
})

--- @brief [internal]
function bt.VerboseInfo.Page:_get_backdrop_margins()
    return rt.settings.margin_unit * 2, rt.settings.margin_unit
end

--- @brief [internal]
function bt.VerboseInfo.Page:_initialize_backdrop(width, height)
    self._backdrop = rt.Frame()
    self._backdrop_backing = rt.Spacer()

    local xm, ym = self:_get_backdrop_margins()
    self._backdrop:set_child(self._backdrop_backing)
    self._backdrop:realize()
    self._backdrop:fit_into(0, 0, width + 2 * xm, height + 2 * ym)
end

--- @override
function bt.VerboseInfo.Page:draw()
    rt.graphics.push()
    local bounds = self._bounds
    local xm, ym = self:_get_backdrop_margins()
    rt.graphics.translate(bounds.x, bounds.y)
    self._backdrop:draw()
    rt.graphics.translate(xm, ym)
    for widget in values(self._content) do
        widget:draw()
    end
    rt.graphics.pop()
end

function bt.VerboseInfo.Page._new_label(...)
    local str = ""
    for _, v in pairs({...}) do
        str = str .. tostring(v)
    end
    local out = rt.Label(str, rt.settings.font.default_small, rt.settings.font.default_mono_small)
    out:realize()
    out:set_justify_mode(rt.JustifyMode.LEFT)
    return out
end

bt.VerboseInfo.Page._gray = "GRAY_3"
bt.VerboseInfo.Page._number_prefix = "<b><color=" .. bt.VerboseInfo.Page._gray .. ">:</color></b>    <mono>"
bt.VerboseInfo.Page._number_postfix = "</mono>"

bt.VerboseInfo.Page._create_stat_prefix = function(label)
    return "<b>" .. label .. "</b>"
end

bt.VerboseInfo.Page._create_name = function(name)
    return "<u><b>" .. name .. "</b></u> "
end

function bt.VerboseInfo.Page._create_offset_label(x)
    if x > 0 then
        return "+" .. x
    elseif x < 0 then
        return "-" .. math.abs(x)
    else
        return "\u{00B1}" .. x -- plusminus
    end
end

function bt.VerboseInfo.Page._create_factor_label(x)
    x = math.abs(x)
    if x > 1 then
        return "+" .. math.round((x - 1) * 100) .. "%"
    elseif x < 1 then
        return "-" .. math.round((1 - x) * 100) .. "%"
    else
        return "\u{00B1}0%" -- plusminus
    end
end

-- ### ENTITY ###

bt.VerboseInfo.Page.ENTITY = meta.new_type("VerboseInfoPage_ENTITY", bt.VerboseInfo.Page, function(entity)
    return meta.new(bt.VerboseInfo.Page.ENTITY, {
        _entity = entity
    })
end)

--- @override
function bt.VerboseInfo.Page.ENTITY:realize()
    self._is_realized = true

    local entity = self._entity
    local new_label = bt.VerboseInfo.Page._new_label
    self._name_label = new_label(bt.VerboseInfo.Page._create_name(entity:get_name()))

    local gray = bt.VerboseInfo.Page._gray
    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix
    local create_stat_prefix = bt.VerboseInfo.Page._create_stat_prefix

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

    local description = entity:get_description()
    if description ~= "" then
        local description_prefix = "<b><u>Description</u></b>"
        self._description_label = new_label(description_prefix .. ": " .. description .. "")
    end

    self._requested_width = 0
    self._requested_height = 0

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

--- @override
function bt.VerboseInfo.Page.ENTITY:size_allocate(_, _, width, height)
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

    local stat_align = current_x + 7 * self._name_label:get_font():get_size()
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

    if self._description_label ~= nil then
        self._description_label:fit_into(current_x, current_y, width, label_h)
        current_y = current_y + select(2, self._description_label:measure())
    end

    self._requested_width = max_x
    self._requested_height = current_y
end

--- ### MOVE ###

bt.VerboseInfo.Page.MOVE = meta.new_type("VerboseInfoPage_MOVE", bt.VerboseInfo.Page, function(move, n_uses)
    return meta.new(bt.VerboseInfo.Page.MOVE, {
        _move = move,
        _n_uses = n_uses
    })
end)

function bt.VerboseInfo.Page.MOVE:realize()
    self._is_realized = true
    local move = self._move

    local new_label = bt.VerboseInfo.Page._new_label
    self._name_label = new_label(bt.VerboseInfo.Page._create_name(move:get_name()))

    local sprite_id, sprite_index = move:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_animation(sprite_index)

    local gray = bt.VerboseInfo.Page._gray
    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix

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

    local stat_prefix = "<color=" .. gray .. "><b>:</b></color> "
    self._n_uses_label_left = new_label("AP")
    self._n_uses_label_right = new_label(stat_prefix, ternary(self._n_uses == POSITIVE_INFINITY, "unlimited", self._n_uses)) -- infinity

    self._target_label_left = new_label("Targets")
    self._target_label_right = new_label(stat_prefix, target_str)

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
    self._priority_label_left = new_label("Priority")
    self._priority_label_right = new_label(stat_prefix, priority_str)
    self._priority_label_visible = prio ~= 0

    self._content = {
        self._sprite,
        self._name_label,
        self._effect_label,
        self._n_uses_label_left,
        self._n_uses_label_right,
        self._target_label_left,
        self._target_label_right,
    }

    if self._priority_label_visible then
        table.insert(self._content, self._priority_label_left)
        table.insert(self._content, self._priority_label_right)
    end
end

function bt.VerboseInfo.Page.MOVE:size_allocate(_, _, width, height)
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

    local stat_align = current_x + 4 * self._name_label:get_font():get_size()

    self._n_uses_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._n_uses_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._n_uses_label_right)
    current_y = current_y + h

    self._target_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._target_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._target_label_right)
    current_y = current_y + h


    if self._priority_label_visible then
        self._priority_label_left:fit_into(current_x, current_y, label_w, label_h)
        self._priority_label_right:fit_into(stat_align, current_y, label_w, label_h)
        measure(self._priority_label_right)
        current_y = current_y + h + m
    else
        current_y = current_y + m
    end

    self._effect_label:fit_into(current_x, current_y, width, label_h)
    w, h = self._effect_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(width - sprite_w, 0, sprite_w, sprite_h)

    self._requested_width, self._requested_height = max_x, current_y
end

-- ### STATUS ###

bt.VerboseInfo.Page.STATUS = meta.new_type("VerboseInfoPage_STATUS", bt.VerboseInfo.Page, function(status, n_turns_left)
    return meta.new(bt.VerboseInfo.Page.STATUS, {
        _status = status,
        _n_turns_left = n_turns_left
    })
end)

function bt.VerboseInfo.Page.STATUS:realize()
    self._is_realized = true
    local status = self._status
    local n_turns_left = self._n_turns_left

    local new_label = bt.VerboseInfo.Page._new_label

    self._name_label = new_label(bt.VerboseInfo.Page._create_name(status:get_name()))
    self._sprite = rt.Sprite(status:get_sprite_id())
    self._sprite:realize()

    local gray = bt.VerboseInfo.Page._gray
    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix

    self._duration_label_left = new_label("# Turns Left")

    if status:get_max_duration() == POSITIVE_INFINITY then
        self._duration_label_right = new_label(number_prefix, "\u{221E}", number_postfix)
    else
        self._duration_label_right = new_label(number_prefix, n_turns_left, number_postfix)
    end

    self._description_label = new_label("<u>Effect</u>: " .. status:get_description())

    self._content = {}
    for label in range(self._name_label, self._sprite, self._duration_label_left, self._duration_label_right, self._description_label) do
        table.insert(self._content, label)
    end

    local create_stat_prefix = bt.VerboseInfo.Page._create_stat_prefix
    local create_offset_label = bt.VerboseInfo.Page._create_offset_label
    local create_factor_label = bt.VerboseInfo.Page._create_factor_label

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
            self[factor_label .. "_right"] = new_label(number_prefix, prefix, create_factor_label(factor), postfix, number_postfix)
            table.insert(self._content, self[factor_label .. "_left"])
            table.insert(self._content, self[factor_label .. "_right"])
        end
    end

    self._stun_label_left = new_label("Stun")
    self._stun_label_right = new_label(number_prefix, ternary(status.is_stun, "<b>yes</b>", "no"), number_postfix)
    table.insert(self._content, self._stun_label_left)
    table.insert(self._content, self._stun_label_right)
end

function bt.VerboseInfo.Page.STATUS:size_allocate(_, _, width, height)
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 7 * self._name_label:get_font():get_size()

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

    self._description_label:fit_into(current_x, current_y, width, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(width - sprite_w, 0, sprite_w, sprite_h)

    self._requested_width = max_x
    self._requested_height = current_y
end

-- ### GLOBAL STATUS ###

bt.VerboseInfo.Page.GLOBAL_STATUS = meta.new_type("VerboseInfoPage_GLOBAL_STATUS", bt.VerboseInfo.Page, function(status, n_turns_left)
    return meta.new(bt.VerboseInfo.Page.GLOBAL_STATUS, {
        _status = status,
        _n_turns_left = n_turns_left
    })
end)

function bt.VerboseInfo.Page.GLOBAL_STATUS:realize()
    self._is_realized = true
    local status = self._status
    local n_turns_left = self._n_turns_left

    local new_label = bt.VerboseInfo.Page._new_label

    self._name_label = new_label(bt.VerboseInfo.Page._create_name(status:get_name()))
    self._sprite = rt.Sprite(status:get_sprite_id())
    self._sprite:realize()

    local gray = bt.VerboseInfo.Page._gray
    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix

    self._duration_label_left = new_label("Duration")

    if status:get_max_duration() == POSITIVE_INFINITY then
        self._duration_label_right = new_label(number_prefix, "\u{221E}", number_postfix)
    else
        self._duration_label_right = new_label(number_prefix, n_turns_left .. " turns left", number_postfix)
    end

    self._description_label = new_label("<u>Effect</u>: " .. status:get_description())

    self._content = {
        self._name_label,
        self._sprite,
        self._duration_label_left,
        self._duration_label_right,
        self._description_label
    }
end

function bt.VerboseInfo.Page.GLOBAL_STATUS:size_allocate(_, _, width, height)
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 7 * self._name_label:get_font():get_size()

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

    self._description_label:fit_into(current_x, current_y, width, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(width - sprite_w, 0, sprite_w, sprite_h)

    self._requested_width = max_x
    self._requested_height = current_y
end

-- ### CONSUMABLE ###

bt.VerboseInfo.Page.CONSUMABLE = meta.new_type("VerboseInfoPage_CONSUMABLE", bt.VerboseInfo.Page, function(consumable, n_uses_left)
    return meta.new(bt.VerboseInfo.Page.CONSUMABLE, {
        _consumable = consumable,
        _n_uses_left = n_uses_left
    })
end)

function bt.VerboseInfo.Page.CONSUMABLE:realize()
    self._is_realized = true
    local consumable = self._consumable
    local n_uses_left = self._n_uses_left

    local new_label = bt.VerboseInfo.Page._new_label

    local n_uses_postfix = "(" .. ternary(consumable:get_max_n_uses() == POSITIVE_INFINITY, "\u{221E}", n_uses_left) .. ")"
    self._name_label = new_label(bt.VerboseInfo.Page._create_name(consumable:get_name()))
    self._sprite = rt.Sprite(consumable:get_sprite_id())
    self._sprite:realize()

    self._n_uses_label_left = new_label("Duration")

    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix
    if consumable:get_max_n_uses() == POSITIVE_INFINITY then
        self._n_uses_label_right = new_label(number_prefix, "\u{221E}", number_postfix)
    else
        self._n_uses_label_right = new_label(number_prefix, n_uses_left .. " turns left", number_postfix)
    end

    self._description_label = new_label("<u>Effect</u>: " .. consumable:get_description())

    self._content = {
        self._name_label,
        self._sprite,
        self._n_uses_label_left,
        self._n_uses_label_right,
        self._description_label
    }
end

function bt.VerboseInfo.Page.CONSUMABLE:size_allocate(_, _, width, height)
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 7 * self._name_label:get_font():get_size()

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

    self._n_uses_label_left:fit_into(current_x, current_y, label_w, label_h)
    self._n_uses_label_right:fit_into(stat_align, current_y, label_w, label_h)
    measure(self._n_uses_label_right)
    current_y = current_y + h + m

    self._description_label:fit_into(current_x, current_y, width, label_h)
    w, h = self._description_label:measure()
    current_y = current_y + h + m

    self._sprite:fit_into(width - sprite_w, 0, sprite_w, sprite_h)

    self._requested_width = max_x
    self._requested_height = current_y
end

--- ### EQUIP ###

bt.VerboseInfo.Page.EQUIP = meta.new_type("VerboseInfoPage_EQUIP", bt.VerboseInfo.Page, function(equip)
    return meta.new(bt.VerboseInfo.Page.EQUIP, {
        _equip = equip
    })
end)

function bt.VerboseInfo.Page.EQUIP:realize()
    self._is_realized = true
    local equip = self._equip

    local new_label = bt.VerboseInfo.Page._new_label
    self._name_label = new_label(bt.VerboseInfo.Page._create_name(equip:get_name()))
    self._sprite = rt.Sprite(equip:get_sprite_id())
    self._sprite:realize()

    local description = equip:get_description()
    if description ~= "" then
        self._description_label = new_label("<u>Description</u>: " .. description)
    end

    self._content = {}
    for label in range(self._name_label, self._sprite, self._description_label) do
        table.insert(self._content, label)
    end

    local gray = bt.VerboseInfo.Page._gray
    local number_prefix = bt.VerboseInfo.Page._number_prefix
    local number_postfix = bt.VerboseInfo.Page._number_postfix

    local create_stat_prefix = bt.VerboseInfo.Page._create_stat_prefix
    local create_offset_label = bt.VerboseInfo.Page._create_offset_label
    local create_factor_label = bt.VerboseInfo.Page._create_factor_label

    for property_label_color in range(
        {"attack", "ATK", "ATTACK"},
        {"defense", "DEF", "DEFENSE"},
        {"speed", "SPD", "SPEED"}
    ) do
        local property = property_label_color[1]
        local label = property_label_color[2]
        local prefix = "<color=" .. property_label_color[3] .. ">"
        local postfix = "</color>"

        local offset = equip[property .. "_base_offset"]
        if offset ~= 0 then
            local offset_label = "_" .. property .. "_offset_label"
            self[offset_label .. "_left"] = new_label(prefix, label, postfix)
            self[offset_label .. "_right"] = new_label(number_prefix, prefix, create_offset_label(offset), postfix, number_postfix)
            table.insert(self._content, self[offset_label .. "_left"])
            table.insert(self._content, self[offset_label .. "_right"])
        end

        local factor = equip[property .. "_base_factor"]
        if factor ~= 1 then
            local factor_label = "_" .. property .. "_factor_label"
            self[factor_label .. "_left"] = new_label(prefix, label, postfix)
            self[factor_label .. "_right"] = new_label(number_prefix, prefix, create_factor_label(factor), postfix, number_postfix)
            table.insert(self._content, self[factor_label .. "_left"])
            table.insert(self._content, self[factor_label .. "_right"])
        end
    end
end

function bt.VerboseInfo.Page.EQUIP:size_allocate(_, _, width, height)
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit
    local max_x = NEGATIVE_INFINITY

    local sprite_w, sprite_h = self._sprite:measure()

    local label_w, label_h = POSITIVE_INFINITY, POSITIVE_INFINITY
    local stat_align = current_x + 7 * self._name_label:get_font():get_size()

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

    if self._description_label ~= nil then
        self._description_label:fit_into(current_x, current_y, width, label_h)
        w, h = self._description_label:measure()
        current_y = current_y + h
    end
    current_y = current_y + m

    self._sprite:fit_into(width - sprite_w, 0, sprite_w, sprite_h)

    self._requested_width = max_x
    self._requested_height = current_y
end

