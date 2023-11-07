rt.InputHandler = {}
rt.InputHander._components = {}
meta.make_weak(rt.InputHandler._components, false, true)

--- @class rt.InputButton
rt.InputButton = meta.new_enum({
    A = "A",
    B = "B",
    X = "X",
    Y = "Y",
    UP = "UP",
    RIGHT = "RIGHT",
    BOTTOM = "BOTTOM",
    LEFT = "LEFT"
})

--- @class rt.InputController
rt.InputController = meta.new_type("InputController", function(holder)
    meta.assert_object(holder)
    local out = meta.new(rt.InputController, {
        _instance = holder
    }, rt.SignalEmitter)

    out:signal_add("pressed")
    out:signal_add("tick")
    out:signal_add("released")
    return out
end)