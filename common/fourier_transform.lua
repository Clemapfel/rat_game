rt.settings.fourier_transform = {
    use_high_precision = true, -- if false, use float32, else use float64
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

do
    if rt.settings.fourier_transform.use_high_precision then
        rt.FourierTransform._fftw_cdef = [[
        extern double* fftw_alloc_real(size_t n);
        extern void* fftw_alloc_complex(size_t n);
        extern void* fftw_plan_dft_r2c_1d(int n, double* in, void* out, unsigned int flags);
        extern void fftw_execute(const void* plan);
        ]]

        local fftw = ffi.load("/usr/lib64/libfftw3.so")

        rt.FourierTransform._fftw = fftw
        ffi.cdef(rt.FourierTransform._fftw_cdef)

        rt.FourierTransform._alloc_real = fftw.fftw_alloc_real
        rt.FourierTransform._alloc_complex = fftw.fftw_alloc_complex
        rt.FourierTransform._plan_dft_r2c_1d = fftw.fftw_plan_dft_r2c_1d
        rt.FourierTransform._plan_mode = 64 -- FFTW_ESTIMATE
        rt.FourierTransform._execute = fftw.fftw_execute

        rt.FourierTransform._real_data_t = "double*"
        rt.FourierTransform._complex_data_t = "double(*)[2]"
        rt.FourierTransform._complex_t = "double*"
    else
        rt.FourierTransform._fftw_cdef = [[
        extern float* fftwf_alloc_real(size_t n);
        extern void* fftwf_alloc_complex(size_t n);
        extern void* fftwf_plan_dft_r2c_1d(int n, float* in, void* out, unsigned int flags);
        extern void fftwf_execute(const void* plan);
        ]]

        local fftwf = ffi.load("/usr/lib64/libfftw3f.so")

        rt.FourierTransform._fftw = fftwf
        ffi.cdef(rt.FourierTransform._fftw_cdef)

        rt.FourierTransform._alloc_real = fftwf.fftwf_alloc_real
        rt.FourierTransform._alloc_complex = fftwf.fftwf_alloc_complex
        rt.FourierTransform._plan_dft_r2c_1d = fftwf.fftwf_plan_dft_r2c_1d
        rt.FourierTransform._plan_mode = 64 -- FFTW_ESTIMATE
        rt.FourierTransform._execute = fftwf.fftwf_execute

        rt.FourierTransform._real_data_t = "float*"
        rt.FourierTransform._complex_data_t = "float(*)[2]"
        rt.FourierTransform._complex_t = "float*"
    end
end

rt.FourierTransform.transform_direction = meta.new_enum({
    TIME_DOMAIN_TO_SIGNAL_DOMAIN = false,
    SIGNAL_DOMAIN_TO_TIME_DOMAIN = true
})

--- @brief
--- @param audio rt.Audio
--- @param window_size Number sliding window size
--- @param window_overlap Number
--- @param first_sample Number index of first sample in audio clip
--- @param max_n_samples Number count of samples, starting at `first_sample`
function rt.FourierTransform:compute_from_audio(audio, window_size, window_overlap, first_sample, max_n_samples)

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

    local window_data = self._alloc_real(window_size)
    local transformed_data = self._alloc_complex(window_size)
    local plan = self._plan_dft_r2c_1d(window_size, window_data, transformed_data, self._plan_mode)

    local n_windows = math.ceil(n_samples / (window_size / window_overlap))

    if n_windows < 2 then n_windows = 2 end

    local offset = first_sample
    local window_i = 0
    while window_i < n_windows do

        local window = ffi.cast(self._real_data_t, window_data)

        local sample_i = offset
        local data_i = 1
        while (sample_i < offset + window_size) and sample_i < n_samples do
            local weight = gauss_window((sample_i - offset) / window_size)

            local sample = 0
            if sample_i < audio_n_samples and sample_i > 1 then
                sample = audio_native:getSample(sample_i - 1) * weight
            end

            window[data_i - 1] = sample
            sample_i = sample_i + 1
            data_i = data_i + 1
        end

        self._execute(plan)

        local transformed = ffi.cast(self._complex_data_t, transformed_data)

        -- cut out symmetrical section, flip, then normalize into [0, 1]
        local data = {}
        local half = math.floor(0.5 * window_size)
        local normalize_factor = 1 / math.sqrt(window_size)
        for i = 1, half do
            local complex = ffi.cast(self._complex_t, transformed[half - i - 1])
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
            out:set_pixel(x, y, rt.HSVA(0,  0, value, 1))
        end
    end
    return out
end

--- @brief
function rt.test.fourier_transform()
    rt.add_scene("debug")

    audio = rt.Audio("assets/sound/test_sound_effect_mono.mp3")
    transform = rt.FourierTransform()

    clock = rt.Clock()
    transform:compute_from_audio(audio, 1024, 128, 1, nil)
    println("transform: ", clock:restart():as_seconds())

    image = transform:as_image()
    println("image: ", clock:restart():as_seconds())

    display = rt.ImageDisplay(image)
    rt.current_scene:set_child(display)

    -- ######################

    love.load = function()
        love.window.setMode(800, 600, {
            vsync = 1,
            msaa = 8,
            stencil = true,
            resizable = true
        })
        love.window.setTitle("rat_game")
        rt.current_scene:run()
    end

    love.draw = function()
        love.graphics.clear(1, 0, 1, 1)
        rt.current_scene:draw()
    end

    love.update = function()
        local delta = love.timer.getDelta()
        rt.current_scene:update(delta)
    end
end