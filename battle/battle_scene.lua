--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Widget, function()
    local out = meta.new(bt.BattleScene, {
        _debug_draw_enabled = false,
        _debug_layout_lines = {}, -- Table<rt.Line>

        _state = {}, -- bt.BattleState
        _ui = {}, -- bt.BattleUI

        _elapsed = 0
    })
    out._state = bt.BattleState(out)
    out._ui = bt.BattleUI(out)
    return out
end)

--- @brief
function bt.BattleScene:realize()
    self._is_realized = true

    self._state:update_entity_id_offsets()
    self._ui:realize()
    self._ui:set_priority_order(self._state:list_entities())
end

--- @brief
function bt.BattleScene:size_allocate(x, y, width, height)
    self._ui:fit_into(x, y, width, height)

    local length = width
    self._debug_layout_lines = {
        -- margin_left
        rt.Line(x + (0.5/16) * width, y, x + (0.5/16) * width, y + height),
        -- marign right
        rt.Line(x + (1 - 0.5/16) * width, y, x + (1 - 0.5/16) * width, y + height),
        -- margin top
        rt.Line(x, y + (0.5/9) * height, x + width, y + (0.5/9) * height),
        -- margin bottom
        rt.Line(x, y + (1 - 0.5/9) * height, x + width, y + (1 - 0.5/9) * height),
        -- left 4:3
        rt.Line(x + (3/16) * width, y, x + (3/16) * width, y + height),
        -- right 4:3
        rt.Line(x + (1 - 3/16) * width, y, x + (1 - 3/16) * width, y + height),
        -- horizontal center
        rt.Line(x, y + 0.5 * height, x + width, y + 0.5 * height)
    }
end

--- @brief
function bt.BattleScene:add_entity(entity)
    self._state:add_entity(entity)
    self._ui:add_entity(entity)
end

--- @brief
function bt.BattleScene:draw()
    self._ui:draw()

    if self._debug_draw_enabled then
        for _, line in pairs(self._debug_layout_lines) do
            line:draw()
        end
    end
end

--- @brief
function bt.BattleScene:update(delta)
    self._elapsed = self._elapsed + delta
end

--- @brief
function bt.BattleScene:get_elapsed()
    return self._elapsed
end

--- @brief
function bt.BattleScene:get_debug_draw_enabled()
    return self._debug_draw_enabled
end

--- @brief
function bt.BattleScene:set_debug_draw_enabled(b)
    self._debug_draw_enabled = b
end

--- @brief
function bt.BattleScene:format_name(entity)
    local name
    if meta.isa(entity, bt.BattleEntity) then
        name = entity:get_name()
        if entity.is_enemy == true then
            name = "<color=ENEMY><b>" .. name .. "</b></color> "
        end
    elseif meta.isa(entity, bt.Status) then
        name = "<b><i>" .. entity:get_name() .. "</b></i>"
    elseif meta.isa(entity, bt.Equip) then
        name = "<b>" .. entity:get_name() .. "</b>"
    elseif meta.isa(entity, bt.Consumable) then
        name = "<b>" .. entity:get_name() .. "</b>"
    else
        rt.error("In bt.BattleScene:get_formatted_name: unhandled entity type `" .. meta.typeof(entity) .. "`")
    end
    return name
end

--- @brief
function bt.BattleScene:format_hp(value)
    -- same as rt.settings.battle.health_bar.hp_color_100
    return "<color=LIGHT_GREEN_2><mono><b>" .. tostring(value) .. "</b></mono></color> HP"
end

--- @brief
function bt.BattleScene:format_damage(value)
    -- same as rt.settings.battle.health_bar.hp_color_10
    return "<color=RED><mono><b>" .. tostring(value) .. "</b></mono></color> HP"
end

--- @brief formated message insertions based on grammatical gender
function bt.BattleScene:format_pronouns(entity)
    local gender = entity.gender
    if gender == bt.Gender.NEUTRAL then
        return "it", "it", "its", "is"
    elseif gender == bt.Gender.MALE then
        return "he", "him", "his", "is"
    elseif gender == bt.Gender.FEMALE then
        return "she", "her", "hers", "is"
    elseif gender == bt.Gender.MULTIPLE or gender == bt.Gender.UNKNOWN then
        return "they", "their", "them", "are"
    else
        rt.error("In bt.BattleScene:format_prounouns: unhandled gender `" .. gender .. "` of entity `" .. entity:get_id() .. "`")
        return "error", "error", "error", "error"
    end
end

--- @brief
function bt.BattleScene:skip_animation()
    self._ui:skip()
end

--- @brief
--- @param animation_id String all caps, eg. "PLACEHOLDER_MESSAGE"
function bt.BattleScene:play_animation(entity, animation_id, ...)
    if bt.Animation[animation_id] == nil then
        rt.error("In bt.BattleScene:play_animation: no animation with id `" .. animation_id .. "`")
    end

    local sprite = self._ui:get_sprite(entity)
    if sprite == nil then
        rt.error("In bt.BattleScene:play_animation: unhandled animation target `" .. meta.typeof(entity) .. "`")
    end

    local animation = bt.Animation[animation_id](self, sprite, ...)
    sprite:add_animation(animation)
    return animation, sprite
end


