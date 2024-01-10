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

rt.FourierTransform._fftw_cdef = [[
extern double*fftw_alloc_real(size_t n);
extern void* fftw_alloc_complex(size_t n);
extern void* fftw_plan_dft_r2c_1d(int n, double* in, void* out, unsigned int flags);
extern void fftw_execute(const void* plan);
]]

rt.FourierTransform._fftw = ffi.load("/usr/lib64/libfftw3.so") -- TODO use local lib
ffi.cdef(rt.FourierTransform._fftw_cdef)

rt.FourierTransform.transform_direction = meta.new_enum({
    TIME_DOMAIN_TO_SIGNAL_DOMAIN = false,
    SIGNAL_DOMAIN_TO_TIME_DOMAIN = true
})

--- @brief
--- @param audio rt.Audio
--- @param window_size Number sliding window size
--- @param window_overlap_factor Number
--- @param first_sample Number index of first sample in audio clip
--- @param max_n_samples Number count of samples, starting at `first_sample`
function rt.FourierTransform:compute_from_audio(audio, window_size, window_overlap_factor, first_sample, max_n_samples)

    self._data_out = {}

    function gauss_window(x)
        return math.exp(-4 * (2 * x - 1)^2);
    end

    first_sample = which(first_sample, 1)
    local n_samples = which(max_n_samples, audio:get_n_samples())
    local audio_n_samples = audio:get_n_samples()
    local audio_native = audio._native
    local step_i = 1

    window_size = which(window_size, 2^8)

    local window_data = self._fftw.fftw_alloc_real(window_size)
    local transformed_data = self._fftw.fftw_alloc_complex(window_size)
    local plan = self._fftw.fftw_plan_dft_r2c_1d(window_size, window_data, transformed_data, 64)

    local window_overlap = which(window_overlap_factor, 128 / window_size) * window_size
    local n_windows = math.round(n_samples / (window_size / window_overlap))

    local offset = first_sample
    local window_i = 1
    while window_i < n_windows do

        local window = ffi.cast("double*", window_data)

        local sample_i = offset
        local data_i = 0
        while (sample_i < offset + window_size and sample_i < n_samples) do
            local weight = gauss_window((sample_i - offset) / window_size)

            local sample = 0
            if sample_i < audio_n_samples then
                sample = audio_native:getSample(sample_i - 1) * weight
            end

            window[data_i] = sample
            sample_i = sample_i + 1
            data_i = data_i + 1
        end

        self._fftw.fftw_execute(plan)

        local transformed = ffi.cast("double(*)[2]", transformed_data)

        -- cut out symmetrical section, flip, then normalize into [0, 1]
        local data = {}
        local half = math.floor(0.5 * window_size)
        local normalize_factor = 1 / math.sqrt(window_size)
        for i = 1, half do
            local complex = ffi.cast("double*", transformed[half - i - 1])
            local value = {complex[0], complex[1]}
            local magnitude = math.sqrt(value[1] * value[1] + value[2] * value[2]) -- take complex magnitude
            magnitude = magnitude * normalize_factor -- project into [0, 1]
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