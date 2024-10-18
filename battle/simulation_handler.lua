--- @brief
function bt.BattleScene:create_simulation_environment()
    local scene = self
    local state = self._state

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
        "clamp",
        "project",
        "mix",
        "smoothstep",
        "fract",
        "ternary",
        "select",
        "serialize",

        "INFINITY",
        "POSITIVE_INFINITY",
        "NEGATIVE_INFINITY"
    ) do
        assert(_G[common] ~= nil)
        env[common] = _G[common]
    end

    -- make immutable
    local metatable = {}
    setmetatable(env, metatable)

end