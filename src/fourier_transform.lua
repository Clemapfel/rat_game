--- @class
rt.FourierTransform = meta.new_type("FourierTransform", function()
    local out = meta.new(rt.FourierTransform, {
        _data_in = {},      --- Table<Complex>
        _data_out = {},     --- Table<Number>
        _initialized = false
    })
    return out
end)

--- @brief
--- @param audio rt.Audio
function rt.FourierTransform:compute_from(audio)

end

--- @brief
function rt.FourierTransform:compute()

end