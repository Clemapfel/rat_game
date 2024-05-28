--- @class
bt.MoveInfo = meta.new_type("MoveInfo", rt.Widget, function(move)
    return meta.new(bt.MoveInfo, {
        _move = move,
        _backdrop = {}, -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer
        _name_label = {}, -- rt.Label
        _target_label = {},
        _effect_label = {},
        _priority_label = {}
    })
end)

--- @brief
function bt.MoveInfo:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._backdrop = rt.Frame()
    self._backdrop_backing = rt.Spacer()
    self._backdrop:set_child(self._backdrop_backing)
    self._backdrop:realize()
    self._backdrop:set_opacity(rt.settings.spacer.default_opacity)

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

    self._name_label = new_label("<u><b>", self._move:get_name(), "</b></u>  (", ternary(self._move:get_max_n_uses() == POSITIVE_INFINITY, "\u{221E}", tostring(self._move:get_max_n_uses())), ")")

    local sprite_id, sprite_index = self._move:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_animation(sprite_index)

    local gray = "GRAY_3"
    local number_prefix = "<b><color=" .. gray .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    -- target
    local me, enemy, ally = self._move:get_can_target_self(), self._move:get_can_target_enemy(), self._move:get_can_target_ally()

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
    if self._move:get_can_target_multiple() == false then
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

    self._target_label = new_label("<u>Targets</u> <color=" .. gray .. "><b>:</b></color> ", target_str)
    self._effect_label = new_label("<u>Effect</u>: " .. self._move:get_description() .. ".")

    local priority_str = ""
    local prio = self._move:get_priority()
    while prio > 0 do
        priority_str = priority_str .. "\u{2191}"   -- upwards arrow
        prio = prio - 1
    end

    while prio < 0 do
        priority_str = priority_str .. "\u{2193}"   -- downwards arrow
        prio = prio + 1
    end

    if priority_str == "" then priority_str = "0" end
    self._priority_label = new_label("<u>Priority</u>: <mono><b>" .. priority_str .. "</b></mono>")
end

--- @brief
function bt.MoveInfo:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    self._backdrop:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    local current_x, current_y = x + 2 * m, y + m

    local sprite_w, sprite_h = self._sprite:measure()
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2

    self._sprite:fit_into(x + width - sprite_w - m, y + m, sprite_w, sprite_h)

    local name_h = select(2, self._name_label:measure())
    self._name_label:fit_into(current_x, current_y + 0.5 * sprite_h - 0.5 * name_h, width - 2 * m - sprite_w - m, height)
    current_y = current_y + sprite_h + m

    self._effect_label:fit_into(current_x, current_y, width - 2 * m, height)
    current_y = current_y + select(2, self._effect_label:measure()) + m

    self._priority_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self._priority_label:measure()) + m

    self._target_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self._target_label:measure())

    current_y = current_y + 2 * m
    self._backdrop:fit_into(x, y, width, current_y - y)
end

--- @brief
function bt.MoveInfo:draw()
    self._backdrop:draw()

    self._sprite:draw()
    self._name_label:draw()
    self._effect_label:draw()
    self._target_label:draw()
    self._priority_label:draw()
end