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
            for key in values(meta.instances(rt.InputButton)) do
                out[key] = {}
            end
            return out
        end)()
    }

    local out = meta.new(rt.GameState, {
        _state = state
    })

    out:load_input_mapping()
    return out
end)

--- @brief
function rt.GameState:load_input_mapping()
    local file = rt.settings.input_controller.keybindings_path
    local chunk, error_maybe = love.filesystem.load(file)
    if error_maybe ~= nil then
        rt.error("In rt.GameState.load_input_mapping: Unable to load file at `" .. file .. "`: " .. error_maybe)
    end

    local state = self._state

    local mapping = chunk()
    local valid_keys = {}
    local reverse_mapping_count = {}
    for key in values(meta.instances(rt.InputButton)) do
        valid_keys[key] = 0
        state.input_mapping[key] = {}
    end

    for key, value in pairs(mapping) do
        if valid_keys[key] == nil then
            rt.error("In rt.GameState.load_input_mapping: encountered unexpected key `" .. key .. "`")
        else
            if meta.is_table(value) then
                for mapped in values(value) do
                    table.insert(state.input_mapping[key], mapped)
                    if reverse_mapping_count[mapped] == nil then
                        reverse_mapping_count[mapped] = {key}
                    else
                        table.insert(reverse_mapping_count[mapped], key)
                    end
                end
            else
                local mapped = value
                table.insert(state.input_mapping[key], mapped)
                if reverse_mapping_count[mapped] == nil then
                    reverse_mapping_count[mapped] = {key}
                else
                    table.insert(reverse_mapping_count[mapped], key)
                end
            end

            valid_keys[key] = valid_keys[key] + 1
        end
    end

    for key, count in pairs(valid_keys) do
        if count == 0 then
            rt.error("In rt.GameState.load_input_mapping: Key `" .. key .. "` does not have any keys or buttons assigned to it")
        end
    end

    for key, assigned in pairs(reverse_mapping_count) do
        if sizeof(assigned) > 1 then
            local error = "In rt.GameState.load_input_mapping: Constant `" .. key .. "` is assigned to multiple keys: "
            for k in values(assigned) do
                error = error .. k .. " "
            end
            rt.error(error)
        end
    end

    rt.InputControllerState.load_from_state(self)
    rt.log("Succesfully loaded input mapping from `" .. file .. "`")
end

--- @brief
function rt.GameState:get_input_mapping()
    return self._state.input_mapping
end