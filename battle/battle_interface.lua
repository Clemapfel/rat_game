-- generate meta assertions
for which in values({
    {"entity", "bt.EntityInterface"},
    {"status", "bt.StatusInterface"},
    {"equip", "bt.EquipInterface"},
    {"consumable", "bt.ConsumableInterface"},
    {"global_status", "bt.GlobalStatusInterface"},
    {"move", "bt.MoveInterface"}
}) do
    local is_name = "is_" .. which[1] .. "_interface"

    --- @brief get whether type is interface
    meta["is_" .. which[1] .. "_interface"] = function(x)
        local metatable = getmetatable(x)
        return metatable ~= nil and metatable.type == which[2]
    end

    --- @brief throw if type is not interface
    meta["assert_" .. which[1] .. "_interface"] = function(x)
        if not meta[is_name](x) then
            rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `" .. which[2] .. "`, got `" .. meta.typeof(x) .. "`")
        end
    end
end

function bt.initialize_sandbox(env)
    -- common
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

    -- assertions
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

    -- ctors
    for name in range(
        "GlobalStatus",
        "Status",
        "Equip",
        "Consumable",
        "Move"
    ) do
        env[name] = function(id)
            return bt[name](id)
        end
    end

    -- forwards
    for type in range(
        bt.GlobalStatusInterface,
        bt.StatusInterface,
        bt.EntityInterface,
        bt.ConsumableInterface,
        bt.MoveInterface,
        bt.EquipInterface
    ) do
        for name, value in pairs(type) do
            if meta.is_function(value) then
                env[name] = function(self, ...)
                    if not meta.is_function(self[name]) then
                        rt.error("In " .. meta.typeof(self) .. "." .. name .. ": no such function")
                    end
                    self[name](self, ...)
                end
            end
        end
    end

    --

    return env
end