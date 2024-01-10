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
--- @param window_size Number results in 2^window_size samples
function rt.FourierTransform:compute_from_audio(audio, window_size_exponent, window_overlap_factor)

    self._data_out = {}

    function gauss_window(x)
        return math.exp(-4 * (2 * x - 1)^2);
    end

    local n_samples = audio:get_n_samples()
    local step_i = 1

    window_size_exponent = which(window_size_exponent, 10)
    local window_size = 2^window_size_exponent

    local window_overlap = which(window_overlap_factor, 128 / window_size) * window_size
    local n_windows = math.round(n_samples / (window_size / window_overlap))

    local offset = 1
    local window_i = 1
    while window_i < n_windows do

        local window = {}
        local sample_i = offset
        while (sample_i < offset + window_size and sample_i < n_samples) do
            local weight = gauss_window((sample_i - offset) / window_size)
            local n = audio:get_sample(sample_i) * weight
            table.insert(window, n)
            sample_i = sample_i + 1
        end

        while #window < window_size do
            table.insert(window, 0)
        end

        assert(#window == window_size)
        local transformed = fft.fft(window)

        -- cut out symmetrical section and normalize into [0, 1]
        local data = {}
        local half = math.floor(0.5 * #transformed)
        for i = 1, half do
            local value = transformed[i + half]
            local magnitude = math.sqrt(value[1] * value[1] + value[2] * value[2]) -- take complex magnitude
            magnitude = magnitude / math.sqrt(window_size) -- project into [0, 1]
            data[i] = magnitude
        end
        table.insert(self._data_out, data)

        offset = offset + math.round(window_size / window_overlap)
        window_i = window_i + 1
    end
end

--- @brief convert to image
function rt.FourierTransform:as_image()

    local w, h = #self._data_out, #(self._data_out[1])
    local out = rt.Image(w, h)

    for x = 1, w do
        for y = 1, h do
            local value = self._data_out[x][y]
            out:set_pixel(x, y, rt.HSVA(value,  1, value, 1))
        end
    end

    return out
end