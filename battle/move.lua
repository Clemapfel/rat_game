rt.settings.battle.move = {
    config_path = "assets/configs/moves",
    name = "Move",
    default_animation_id = "MOVE_DEFAULT"
}

--- @class bt.Move
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.Move = meta.new_type("Move", function(id)
    local out = bt.Move._atlas[id]
    if out == nil then
        local path = rt.settings.battle.move.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Move, {
            id = id,
            name = "UNINITIALIZED MOVE @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Move._atlas[id] = out
    end
    return out
end, {
    sprite_id = "",
    sprite_index = 1,
    animation_id = rt.settings.battle.move.default_animation_id,

    description = "(no effect)",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = false,
    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = false,
    can_target_ally = false,

    priority = 0,

    effect = function(self, user, targets)
        meta.assert_move_interface(self)
        meta.assert_entity_interface(user)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
    end,
})
bt.Move._atlas = {}

--- @brief
function bt.Move:realize()
    if self._is_realized == true then return end
    self.effect = nil

    local template = {
        id = rt.STRING,
        name = rt.STRING,
        max_n_uses = rt.UNSIGNED,
        can_target_multiple = rt.BOOLEAN,
        can_target_self = rt.BOOLEAN,
        can_target_enemy = rt.BOOLEAN,
        can_target_ally = rt.BOOLEAN,
        is_intrinsic = rt.BOOLEAN,
        priority = rt.SIGNED,
        description = rt.STRING,
        flavor_text = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        animation_id = rt.STRING,
        effect = rt.FUNCTION
    }

    meta.set_is_mutable(self, true)
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)

    if self.effect == nil then
        rt.error("In bt.Move:realize: config at `" .. self._path .. "` does not implement `effect`, value is left nil")
    end
end

--- @brief
function bt.Move:get_id()
    return self.id
end

--- @brief
function bt.Move:get_name()
    return self.name
end

--- @brief
function bt.Move:get_max_n_uses()
    return self.max_n_uses
end

--- @brief
function bt.Move:get_can_target_multiple()
    return self.can_target_multiple
end

--- @brief
function bt.Move:get_can_target_self()
    return self.can_target_self
end

--- @brief
function bt.Move:get_can_target_ally()
    return self.can_target_ally
end

function bt.Move:get_can_target_allies()
    return self:get_can_target_ally()
end

--- @brief
function bt.Move:get_can_target_enemy()
    return self.can_target_enemy
end

function bt.Move:get_can_target_enemies()
    return self:get_can_target_enemy()
end

--- @brief
function bt.Move:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.Move:get_description()
    return self.description
end

--- @brief
function bt.Move:get_flavor_text()
    return self.flavor_text
end

--- @brief
function bt.Move:get_priority()
    return self.priority
end

--- @brief
function bt.Move:get_is_intrinsic()
    return self.is_intrinsic
end