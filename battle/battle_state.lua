--- @brief
bt.State = meta.new_type("BattleState", {
    -- sandboxed script running utilities
    sandbox = {
        env = nil
    },
})

--- @brief
function bt.State:_setup_context()
    self.sandbox.env = {}
    local env = self.sandbox.env
    for common in range(
        "pairs",
        "ipairs",
        "dbg",
        "sizeof",
        "is_empty",
        "ternary",
        "which",
        "splat",
        "slurp",
        "select",

        "range",
        "step_range",

        "clamp",
        "project",
        "mix",
        "smoothstep",
        "fract",

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
end

--- @brief
function bt.State:_run(f, ...)
    if meta.is_nil(self.sandbox.env) then
        self:_setup_context()
    end

    debug.setfenv(f, self.sandbox.env)
    f(...)
end
