rt.settings.battle.move = {
    config_path = "battle/configs/moves",
    name = "move"
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

    sprite_id = "",
    sprite_index = 1,
    animation_id = "",
    animation_index = 1,

    description = "(no effect)",
    flavor_text = ""
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
        animation_index = rt.UNSIGNED,
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


--[[
self    enemy   ally
1       0       0       SELF
1       1       0       SELF_AND_ENEMY
1       0       1       SELF_AND_ALLY
1       1       1       SELF_AND_ALLY_AND_ENEMY
0       0       0       FIELD
0       1       0       ENEMY
0       0       1       ALLY
0       1       1       ENEMY_AND_ALLY
1       1       1       SELF_AND_ENEMY_AND_ALLY

bt.PossibleTargets = meta.new_enum({
    -- single
    SELF = "SELF",
    ENEMY = "ENEMY",
    ALLY = "ALLY",
    -- multiple
    ALLIES = "SELF_AND_ALLIES",
    ENEMIES = "SELF_AND_ENEMIES",
    SELF_AND_ALLIES = "SELF_AND_ALLIES",
    SELF_AND_ENEMIES = "SELF_AND_ENEMIES",
    ALLIES_AND_ENEMIES = "ALLIES_AND_ENEMIES",
    ALL = "ALL",
    -- nobody
    FIELD = "FIELD"
})

bt.SELF = bt.PossibleTargets.SELF
bt.ENEMY = bt.PossibleTargets.ENEMY
bt.ALLY = bt.PossibleTargets.ALLY
bt.ALLIES = bt.PossibleTargets.SELF_AND_ALLIES
bt.ENEMIES = bt.PossibleTargets.SELF_AND_ENEMIES
bt.SELF_AND_ALLIES = bt.PossibleTargets.SELF_AND_ALLIES
bt.SELF_AND_ENEMIES = bt.PossibleTargets.SELF_AND_ENEMIES
bt.ALLIES_AND_ENEMIES = bt.PossibleTargets.ALLIES_AND_ENEMIES
bt.ALL = bt.PossibleTargets.ALL
bt.FIELD = bt.PossibleTargets.FIELD
]]--
