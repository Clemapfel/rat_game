rt.VSyncMode = {
    ADAPTIVE = -1,
    OFF = 0,
    ON = 1
}

rt.MSAAQuality = {
    OFF = 0,
    GOOD = 2,
    BETTER = 4,
    BEST = 8,
    MAX = 16
}

--- @class rt.GameState
rt.GameState = meta.new_type("GameState", function()
    local state = {
        -- graphics settings
        config = {
            vsync = rt.VSyncMode.ADAPTIVE,
            msaa = rt.MSAAQuality.BEST,
            resolution_x = 1280,
            resolution_y = 720
        },

        -- keybindings
        input_mapping = (function()
            local out = {}
            for key in range(
                rt.InputButton.A,
                rt.InputButton.B,
                rt.InputButton.X,
                rt.InputButton.Y,
                rt.InputButton.L,
                rt.InputButton.R,
                rt.InputButton.START,
                rt.InputButton.SELECT,
                rt.InputButton.UP,
                rt.InputButton.DOWN,
                rt.InputButton.LEFT,
                rt.InputButton.RIGHT
            ) do
                out[key] = {}
            end
        end)()
    }

    return meta.new(rt.GameState, {
        state
    })
end)

--- @brief
function rt.GameState:import_from_save_file(file)
    meta.assert_isa(file)
end

--- @brief
--- @return file
function rt.GameState:export_to_save_file()
end

--- @brief
function rt.GameState:load_input_mapping_from(file)

end