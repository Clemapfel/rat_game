bt.BattleScene = bt.Scene --TODO


--- @brief
function bt.BattleScene:safe_invoke(instance, callback_id, ...)
    self._state:clear_current_move_selection()
    meta.assert_isa(self, bt.BattleScene)
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

    self._state:restore_current_move_selection()
    return res
end
