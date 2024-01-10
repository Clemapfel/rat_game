rt.settings.fourier_transform = {
    step_size = 64,
    overlap = 0
}

--- @class
rt.FourierTransform = meta.new_type("FourierTransform", function()
    local out = meta.new(rt.FourierTransform, {
        _data = {},     --- Table<Table<Number>>, fourier transform per step
        _min = 0,
        _max = 1,
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
function rt.FourierTransform:compute_from_audio(audio)

    self._data_out = {}

    function gauss_window(x)
        return math.exp(-4 * (2 * x - 1)^2);
    end

    local n_samples = audio:get_n_samples()
    local step_i = 1

    self._min, self._max = POSITIVE_INFINITY, NEGATIVE_INFINITY

    local window_size = 2048
    local window_overlap = 30
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
            value = ((value / math.sqrt(window_size / 2)) + 1) / 2

            if #value then value = value[1] end -- complex result
            data[i] = value

            self._min = math.min(self._min, value)
            self._max = math.max(self._max, value)
        end
        table.insert(self._data_out, data)

        dbg(self._min, " ", self._max)

        offset = offset + math.round(window_size / window_overlap)
        window_i = window_i + 1
    end
end

--- @brief convert to image
function rt.FourierTransform:as_image()

    local w, h = #self._data_out, #(self._data_out[1])
    local out = rt.Image(w, h)

    --[[
    for x, _ in pairs(self._data_out) do
        for i, y in ipairs(self._data_out[x]) do
            self._data_out[x][i] = y -- (y - min) / (max - min)
        end
    end
    ]]--

    for x = 1, w do
        for y = 1, h do
            local value = self._data_out[x][y]
            out:set_pixel(x, y, rt.HSVA(value,  1, value, 1))
        end
    end

    return out
end