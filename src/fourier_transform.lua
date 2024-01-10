rt.settings.fourier_transform = {
    step_size = 64,
    overlap = 0
}

--- @class
rt.FourierTransform = meta.new_type("FourierTransform", function()
    local out = meta.new(rt.FourierTransform, {
        _data = {},     --- Table<Table<Number>>, fourier transform per step
        _initialized = false
    })
    return out
end)

rt.FourierTransform.transform_direction = meta.new_enum({
    TIME_DOMAIN_TO_SIGNAL_DOMAIN = false,
    SIGNAL_DOMAIN_TO_TIME_DOMAIN = true
})

--- @brief
--- @param audio rt.Audio
function rt.FourierTransform:compute_from_audio(audio, step_size)

    step_size = rt.settings.fourier_transform.step_size
    self._data_out = {}

    local n_samples = audio:get_n_samples()
    local step_i = 1
    local sample_i = 1
    while sample_i < n_samples do

        local samples = {}
        local c = 0
        for _ = 1, step_size do
            if sample_i <= n_samples then
                table.insert(samples, audio:get_sample(sample_i))
            else
                table.insert(samples, 0)
            end
            sample_i = sample_i + 1
        end

        local transformed = fft.fft(samples)
        table.insert(self._data_out, transformed)
        step_i = step_i + 1
    end
end

--- @brief convert to image
function rt.FourierTransform:as_image()
    local w, h = #self._data_out, #(self._data_out[1])
    local out = rt.Image(w, h)

    for x = 1, w do
        for y = 1, h do
            local value = self._data_out[x][y]
            out:set_pixel(x, y, rt.HSVA(0, 0, value, 1))
        end
    end

    return out
end