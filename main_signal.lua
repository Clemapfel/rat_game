require("include")

local texture_h = 10000
local shader_i = 0
local shader = rt.Shader("assets/shaders/audio_processor_visualization.glsl")
local image_data_format = "rgba16"

local initialized = false
local magnitude_image, magnitude_texture, texture_shape
local energy_image, energy_texture
local total_energy_image, total_energy_texture

function hz_to_mel(hz)
    return 2595 * math.log10(1 + (hz / 700))
end

local col_i = 0
local index_delta = 0

-- source: https://haythamfayek.com/2016/04/21/speech-processing-for-machine-learning.html

-- parameters
local window_size = mix(2^11, 2^12, 0.5)   -- window size of fourier transform, results in window_size / 2 coefficients
local n_mel_frequencies = window_size / 12           -- mel spectrum compression, number of mel frequencies for cutoff spectrum
local one_to_one_frequency_threshold = 0                      -- compression override, the first n coefficients are kept one-to-one
local use_compression = true
local cutoff = 12000

local energy_bins = {
    {0, 0.7},
    {0.7, 0.9},
    {0.9, 1}
}

processor = rt.AudioProcessor("assets/sound/test_music_02.mp3", window_size)
processor:set_cutoff(cutoff)
local sample_rate = processor:get_sample_rate()

local bins = {} -- Table<Integer, Integer>, range of magnitude coefficients to sum
--do
    function mel_to_hz(mel)
        return 700 * (10^(mel / 2595) - 1)
    end

    function hz_to_mel(hz)
        return 2595 * math.log10(1 + (hz / 700))
    end

    function bin_to_hz(bin_i)
        -- src: https://dsp.stackexchange.com/a/75802
        return (bin_i - 1) * sample_rate / (window_size / 2)
    end

    function hz_to_bin(hz)
       return math.round(hz / (sample_rate / (window_size / 2)) + 1)
    end

    local n_mel_filters = n_mel_frequencies
    local bin_i_center_frequency = {}
    local mel_lower = 0
    local mel_upper = math.max(hz_to_mel(math.max(processor:get_cutoff(), bin_to_hz(one_to_one_frequency_threshold))))
    for mel in step_range(mel_lower, mel_upper, (mel_upper - mel_lower) / n_mel_filters) do
        table.insert(bin_i_center_frequency, hz_to_bin(mel_to_hz(mel)))
    end

    one_to_one_frequency_threshold = clamp(one_to_one_frequency_threshold, 0, hz_to_bin(mel_to_hz(mel_upper))) --hz_to_bin(60)
    for i = 1, one_to_one_frequency_threshold do
        table.insert(bins, {i, i})
    end

    for i = 2, #bin_i_center_frequency - 1 do
        if bin_i_center_frequency[i] > one_to_one_frequency_threshold then
            local left, center, right = bin_i_center_frequency[i-1], bin_i_center_frequency[i], bin_i_center_frequency[i+1]
            table.insert(bins, {
                math.floor(left), --mix(left, center, 0.5)),
                math.floor(right) --mix(center, right, 0.5))
            })
        end
    end

    bins[1][1] = 1
    bins[#bins][2] = bin_i_center_frequency[#bin_i_center_frequency]
--end


local active = true

processor.on_update = function(magnitude)
    local spectrum_size = #magnitude
    if not initialized then
        dbg(spectrum_size)
        if use_compression then
            magnitude_image = love.image.newImageData(texture_h, #bins, "rgba16")
            magnitude_texture = love.graphics.newImage(magnitude_image)
        else
            magnitude_image = love.image.newImageData(texture_h, #magnitude, "rgba16")
            magnitude_texture = love.graphics.newImage(magnitude_image)
        end

        total_energy_image = love.image.newImageData(texture_h, #energy_bins, "rg8")
        total_energy_texture = love.graphics.newImage(total_energy_image)

        texture_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        texture_shape._native:setTexture(magnitude_texture)
        for texture in range(magnitude_texture) do
            texture:setFilter("nearest", "linear", 16)
            texture:setWrap("clampzero", "clampzero")
        end

        initialized = true
    end

    if col_i >= texture_h then
        magnitude_image:release()
        magnitude_image = love.image.newImageData(texture_h, #bins, image_data_format)
        col_i = 0
    end

    local coefficients = {}
    local total_energy = 0
    if use_compression then
        for bin_i, bin in ipairs(bins) do
            local sum = 0
            local n = 1
            local width = bin[2] - bin[1]
            for i = bin[1], bin[2] do
                if i > 0 and i <= #magnitude  then
                    sum = sum + magnitude[i]
                    n = n + 1
                end
            end
            sum = sum / n
            total_energy = total_energy + sum
            table.insert(coefficients, sum)
        end
    else
        for _, value in pairs(magnitude) do
            table.insert(coefficients, value)
            total_energy = total_energy + value
        end
    end

    for bin_i, sum in ipairs(coefficients) do
        local previous, previous_delta, previous_delta_delta = magnitude_image:getPixel(clamp(col_i - 1, 0), bin_i - 1)

        local current = sum
        local current_delta = ((current - previous) + 1) / 2
        local current_delta_delta = ((current_delta - previous_delta) + 1) / 2

        magnitude_image:setPixel(col_i, bin_i - 1,
            current,                -- energy
            current_delta,          -- 1st derivative
            current_delta_delta,    -- 2nd derivative
            total_energy / #coefficients
        )
    end

    for bin_i, bin in ipairs(energy_bins) do
        local sum = 0
        local n = 0
        for i = math.floor(bin[1] * #coefficients), math.ceil(bin[2] * #coefficients) do
            if i > 0 and i <= #coefficients then
                sum = sum + coefficients[i]
                n = n + 1
            end
        end
        sum = sum / (#coefficients * (bin[2] - bin[1]))
        println(sum)

        local previous, previous_delta = total_energy_image:getPixel(clamp(col_i - 1, 0), bin_i - 1)
        local current = sum
        local current_delta = current - previous
        total_energy_image:setPixel(col_i, bin_i - 1, current, current_delta, 0, 0)
    end

    magnitude_texture:replacePixels(magnitude_image)
    total_energy_texture:replacePixels(total_energy_image)

    shader:send("_spectrum", magnitude_texture)
    shader:send("_total_energy", total_energy_texture)
    --shader:send("_spectrum_size", #coefficients)
    shader:send("_active", active)
    shader:send("_index", col_i)
    shader:send("_max_index", texture_h)

    col_i = col_i + 1
end

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        active = not active
        println(active)
    end
end)

love.load = function()
    love.window.setMode(1200, 800, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
end

love.draw = function()
    love.graphics.clear(0.8, 0, 0.8, 1)

    shader:bind()
    texture_shape:draw()
    shader:unbind()
end

love.update = function()
    local delta = love.timer.getDelta()
    processor:update(delta)
end

--[[
rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:realize()
end

love.draw = function()
    love.graphics.clear(0.8, 0.2, 0.8, 1)
    rt.current_scene:draw()

    do -- show fps
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)
end

love.quit = function()

end

--[[
sprite = rt.SpriteAtlasEntry("assets/sprites", "controller_buttons")
sprite:load()
dbg(sprite.texture_rectangles)

rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:realize()
end

love.draw = function()
    love.graphics.clear(0.8, 0.2, 0.8, 1)
    rt.current_scene:draw()

    do -- show fps
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end

    sprite.texture:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)
end

love.quit = function()

end

]]--

--[[
local texture_h = 10000
local shader_i = 0
local shader = rt.Shader("assets/shaders/fourier_transform_visualization.glsl")
local image_data_format = "r16"

local initialized = false
local magnitude_image, magnitude_texture, energy_image, energy_texture, texture_shape

local bins = {}
local bin_compress = false

local col_i = 0
local index_delta = 0
local processor = rt.AudioProcessor("assets/sound/test_music_02.mp3")
processor.on_update = function(magnitude)

    -- discard high frequency component
    local n_discarded = 0
    local to_be_distarded = 0 * #magnitude
    while n_discarded < to_be_distarded do
        table.remove(magnitude, 1)
        n_discarded = n_discarded + 1
    end

    local spectrum_size = #magnitude

    if not initialized then
        if bin_compress then
            local n_unit_bins = 30
            local bin_i = 1
            local size = 1
            local sum = 0
            while sum < spectrum_size do
                local final_size = ternary(bin_i < n_unit_bins, 1, math.floor(size))
                if sum + final_size > spectrum_size then break end -- toss out last few high-frequency components
                table.insert(bins, clamp(final_size, 0, math.abs(sum - spectrum_size)))
                sum = sum + final_size
                size = size * (1 + 1 / math.sqrt(spectrum_size))
                bin_i = bin_i + 1
            end

            magnitude_image = love.image.newImageData(texture_h, #bins, image_data_format)
            magnitude_texture = love.graphics.newImage(magnitude_image)
        else
            magnitude_image = love.image.newImageData(texture_h, #magnitude, image_data_format)
            magnitude_texture = love.graphics.newImage(magnitude_image)
        end

        texture_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        texture_shape._native:setTexture(magnitude_texture)
        for texture in range(magnitude_texture) do
            texture:setFilter("nearest", "linear", 16)
            texture:setWrap("clampzero", "clampzero")
        end

        initialized = true
    end

    if col_i >= texture_h then
        magnitude_image:release()
        magnitude_image = love.image.newImageData(texture_h, #bins, image_data_format)
        col_i = 0
    end

    -- non-linearly compress
    if bin_compress then
        local current_i = 1
        local compressed = {}
        for bin_i = 1, #bins, 1 do
            local bin = bins[#bins - bin_i + 1]
            local sum = 0
            local start = current_i
            while current_i < start + bin do
                sum = sum + magnitude[current_i]
                current_i = current_i + 1
            end

            sum = sum
            table.insert(compressed, sum)
            magnitude_image:setPixel(col_i, bin_i - 1, sum, 0, 0, 1)
        end
    else
        for i, magnitude in ipairs(magnitude) do
            magnitude_image:setPixel(col_i, i - 1, magnitude, 0, 0, 1)
        end
    end

    magnitude_texture:replacePixels(magnitude_image)
    shader:send("_spectrum", magnitude_texture)
    shader:send("_index", col_i)
    shader:send("_max_index", texture_h)
    col_i = col_i + 1

    dbg(magnitude)
end
]]--

--[[
love.load = function()
    love.window.setMode(1200, 800, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
end

love.draw = function()
    love.graphics.clear(0.8, 0, 0.8, 1)
    shader:bind()
    texture_shape:draw()
    shader:unbind()
end

love.update = function()
    local delta = love.timer.getDelta()
end
]]--
--[[
rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:realize()
end

love.draw = function()
    love.graphics.clear(0.8, 0.2, 0.8, 1)
    rt.current_scene:draw()

    do -- show fps
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)
end

love.quit = function()

end
]]--
--[[
local bins = {}
local energy_bins = {}

function inverse_logboost(x, ramp)
    return math.log(ramp / x) - math.log(ramp) + 1;
end

local texture_h = 200
local shader = rt.Shader("assets/shaders/fourier_transform_visualization.glsl")
local image_data_format = "r16"

local magnitude_image, magnitude_texture, energy_image, energy_texture, texture_shape

--shader:send("_texture_size", {image:getWidth(), image:getHeight()})

local active = false
local min_energy = POSITIVE_INFINITY
local max_energy = NEGATIVE_INFINITY
local n_energy_bins = 16

local col_i = 0
local processor = rt.AudioProcessor("assets/sound/test_music_02.mp3")
processor.on_update = function(magnitude, min, max, energy_sum)

    if is_empty(bins) then
        -- initialize bins on first time
        local n_unit_bins = 30
        local bin_i = 1
        local size = 1
        local sum = 0
        while sum < #magnitude do
            local final_size = ternary(bin_i < n_unit_bins, 1, math.floor(size))
            if sum + final_size > #magnitude then break end -- toss out last few high-frequency components
            table.insert(bins, clamp(final_size, 0, math.abs(sum - #magnitude)))
            sum = sum + final_size
            size = size * (1 + 1 / math.sqrt(#magnitude))
            bin_i = bin_i + 1
        end

        magnitude_image = love.image.newImageData(texture_h, #bins, image_data_format)
        magnitude_texture = love.graphics.newImage(magnitude_image)

        for texture in range(magnitude_texture, energy_texture) do
            texture:setFilter("nearest", "linear", 16)
            texture:setWrap("clampzero", "clampzero")
        end

        --shader:send("_spectrum_size", {texture_w, rt.settings.audio_processor.window_size / texture_w})
        texture_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        texture_shape._native:setTexture(magnitude_texture)

        energy_image = love.image.newImageData(texture_h, n_energy_bins, image_data_format)
        energy_texture = love.graphics.newImage(energy_image)
    end

    if col_i >= texture_h then
        magnitude_image:release()
        magnitude_image = love.image.newImageData(texture_h, #bins, image_data_format)
        energy_image:release()
        energy_image = love.image.newImageData(texture_h, n_energy_bins, image_data_format)
        col_i = 0
    end

    -- compress by frequency
    local current_i = 1
    local compressed = {}
    for bin_i = 1, #bins, 1 do
        local bin = bins[#bins - bin_i + 1]
        local sum = 0
        local start = current_i
        while current_i < start + bin do
            sum = sum + magnitude[current_i]
            current_i = current_i + 1
        end

        sum = sum / bin
        table.insert(compressed, sum)
        magnitude_image:setPixel(col_i, bin_i - 1, sum, 0, 0, 1)
    end

    -- calculate energy
    local current_i = 1
    for bin_i = 1, n_energy_bins, 1 do
        local bin = math.floor(#compressed / n_energy_bins)
        local sum = 0
        local start = current_i
        while current_i < start + bin do
            sum = sum + compressed[current_i]
            current_i = current_i + 1
        end

        sum = sum / bin
        energy_image:setPixel(col_i, bin_i - 1, sum, 0, 0, 1)
    end

    magnitude_texture:replacePixels(magnitude_image)
    energy_texture:replacePixels(energy_image)


    shader:send("_energy", energy_texture)
    shader:send("_spectrum", magnitude_texture)

    shader:send("_on", ternary(active, 1, 0))
    --shader:send("_spectrum_size", {magnitude_image:getWidth(), magnitude_image:getHeight()})
    shader:send("_energy_size", {energy_image:getWidth(), energy_image:getHeight()})

    --shader:send("_min_energy", min_energy)
    --shader:send("_max_energy", max_energy)
    ---:send("_index", col_i)
    --shader:send("_spectrum_size", #bins)

    --shader:send("_boost", boost)
    --shader:send("_col_offset", col_i)
    --shader:send("_window_size", processor._window_size)
    col_i = col_i + 1
end

love.load = function()
    love.window.setMode(1200, 800, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
end

love.draw = function()
    love.graphics.clear(0.8, 0, 0.8, 1)
    shader:bind()
    texture_shape:draw()
    shader:unbind()
end

love.update = function()
    local delta = love.timer.getDelta()
    processor:update()
end
]]--
