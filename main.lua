require("include")

rt.current_scene = ow.OverworldScene()

-- TODO
local spritesheet = rt.Spritesheet("assets/sprites/debug", "bouncy_ball")

for i = 1, 1 do
    local x, y = rt.random.integer(50, 800 - 200), rt.random.integer(50, 600 - 200)
    rt.current_scene:add_entity(ow.OverworldSprite(spritesheet, "bounce"), x, y)
end

sprite = ow.OverworldSprite(spritesheet, "bounce")
sprite:set_position(400, 300)
sprite:realize()
rt.current_scene:add_entity(sprite)

-- TODO

local input_component = rt.InputController()
input_component:signal_connect("pressed", function(self, which)
    if which == rt.InputButton.UP then
        sprite:set_frame(sprite:get_frame() + 1)
    elseif which == rt.InputButton.DOWN then
        sprite:set_frame(sprite:get_frame() - 1)
    end
end)

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
    love.graphics.clear(0.8, 0, 0.8, 1)
    rt.current_scene:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)

    love.window.setTitle("rat_game (" .. love.timer.getFPS() .. ")")
end

love.quit = function()

end


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

rt.current_scene = rt.add_scene("debug")
local scene = ow.OverworldScene()
rt.current_scene:set_child(scene)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        active = not active
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
        boost = boost + 0.5
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
        boost = boost - 0.5
    end
end)

-- ##

love.load = function()
    love.window.setMode(1200, 800, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(0.8, 0, 0.8, 1)
    rt.current_scene:draw()

    shader:bind()
    texture_shape:draw()
    shader:unbind()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    processor:update()
end

]]--
