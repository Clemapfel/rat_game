function bt.Scene:safe_invoke(instance, callback_id, ...)
    meta.assert_isa(self, bt.Scene)
    meta.assert_string(callback_id)
    local scene = self

    -- setup fenv, done everytime to reset any globals
    local env = {}
    for common in range(
        "pairs",
        "ipairs",
        "values",
        "keys",
        "range",
        "tostring",
        "print",
        "println",
        "dbg",

        "sizeof",
        "is_empty",
        "clamp",
        "project",
        "mix",
        "smoothstep",
        "fract",
        "ternary",
        "which",
        "splat",
        "slurp",
        "select",
        "serialize",

        "INFINITY",
        "POSITIVE_INFINITY",
        "NEGATIVE_INFINITY"
    ) do
        assert(_G[common] ~= nil)
        env[common] = _G[common]
    end

    env.rand = rt.rand
    env.random = {}
    env.math = math
    env.table = table
    env.string = string

    -- blacklist
    for no in range(
        "assert",
        "collectgarbage",
        "dofile",
        "error",
        "getmetatable",
        "setmetatable",
        "load",
        "loadfile",
        "require",
        "rawequal",
        "rawget",
        "rawset",
        "setfenv",
        "getfenv"
    ) do
        env[no] = nil
    end

    -- whitelist assertions
    env.meta = {}
    for yes in range(
        "status", "global_status", "entity", "equip", "consumable", "move"
    ) do
        local is_name = "is_" .. yes .. "_interface"
        env.meta[is_name] = meta[is_name]
        env.meta["assert_" .. yes .. "_interface"] = meta["assert_" .. yes .. "_interface"]
    end

    for yes in range(
        "number", "string", "function", "nil"
    ) do
        env.meta["is_" .. yes] = meta["is_" .. yes]
        env.meta["assert_" .. yes] = meta["assert_" .. yes]
    end

    -- shared environment, not reset between calls
    if scene._safe_invoke_shared == nil then scene._safe_invoke_shared = {} end
    env._G = scene._safe_invoke_shared

    scene:_load_scene_interface(env)

    setmetatable(env, {})
    local metatable = getmetatable(env)
    metatable.__index = function(self, key)
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: trying to access `" .. key .. "` which is not part of the sandboxed environment")
        return nil
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: trying to modify sandboxed environment, but it is immutable. Only use `local` variables, or write to the `_G` shared table")
        return nil
    end

    -- safely invoke callback
    local callback = instance[callback_id]
    debug.setfenv(callback, env)
    local res, error_maybe

    local args = {...}
    if bt._safe_invoke_catch_errors then
        res, error_maybe = pcall(function()
            return callback(table.unpack(args))
        end)

        if error_maybe ~= nil then
            rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": Error: " .. error_maybe)
        end
    else
        res = callback(table.unpack(args))
    end

    if res ~= nil then
        rt.warning("In bt.safe_invoke: In " .. instance:get_id() .. "." .. callback_id .. ": callback returns `" .. serialize(res) .. "`, but it should return nil")
    end

    return res
end

--- @brief
function bt.Scene:_message(string)
    return bt.Animation.MESSAGE(self, string)
end

--- @brief
function bt.Scene:_animate_apply_status(holder, status)
    meta.assert_isa(holder, bt.Entity)
    meta.assert_isa(status, bt.Status)
    if status.is_silent == true then return end
    local sprite = self._ui:get_sprite(holder)
    local apply = bt.Animation.STATUS_APPLIED(sprite, status)
    local message = self:_message(self:format_name(holder) .. "s " .. self:format_name(status) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:_animate_apply_consumable(holder, consumable)
    meta.assert_isa(holder, bt.Entity)
    meta.assert_isa(consumable, bt.Consumable)
    local sprite = self._ui:get_sprite(holder)
    local apply = bt.Animation.CONSUMABLE_APPLIED(sprite, consumable)
    local message = self:_message(self:format_name(holder) .. "s " .. self:format_name(consumable) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:_animate_apply_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    if global_status.is_silent == true then return end
    local apply = bt.Animation.GLOBAL_STATUS_APPLIED(self._ui, global_status)
    local message = self:_message(self:format_name(global_status) .. " activated")
    self:play_animations({apply, message})
end

--- @brief
function bt.Scene:start_battle(battle)
    meta.assert_isa(battle, bt.Battle)
    self._state = battle
    self._ui:clear()

    local animations = {}
    local messages = {}
    for entity in values(self._state:list_entities()) do
        self._ui:add_entity(entity)
        if entity:get_is_enemy() then
            table.insert(animations, bt.Animation.ENEMY_APPEARED(self._ui:get_sprite(entity)))
            table.insert(messages, self:format_name(entity) .. " appeared")
        else
            table.insert(animations, bt.Animation.ALLY_APPEARED(self._ui:get_sprite(entity)))
        end
    end
    table.insert(animations, self:_message(table.concat(messages, "\n")))

    local on_finish = function()
        self._ui:set_priority_order(self._state:get_entities_in_order())
    end

    self:play_animations(animations, nil, on_finish)
end
