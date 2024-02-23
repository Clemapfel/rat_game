require("include")

local bins = {}

function inverse_logboost(x, ramp)
    return math.log(ramp / x) - math.log(ramp) + 1;
end

local texture_h = 200
local shader = rt.Shader("assets/shaders/fourier_transform_visualization.glsl")
local image_data_format = "rg16"

local image, texture, texture_shape

--shader:send("_texture_size", {image:getWidth(), image:getHeight()})

local active = false

local col_i = 0
local processor = rt.AudioProcessor("test_music_02.mp3", "assets/sound")
processor.on_update = function(magnitude, min, max)

    if is_empty(bins) then
        -- initialize bins on first time
        local size = 1
        local sum = 0
        while sum < #magnitude do
            local final_size = math.floor(size)
            if sum + final_size > #magnitude then break end -- toss out last few high-frequency components
            table.insert(bins, clamp(final_size, 0, math.abs(sum - #magnitude)))
            sum = sum + final_size
            size = size * (1 + 1 / 400)
        end
        println(#magnitude, " -> ", #bins)

        image = love.image.newImageData(#bins, texture_h, image_data_format)
        texture = love.graphics.newImage(image)
        texture:setFilter("linear", "linear", 2)
        texture:setWrap("clampzero", "clampzero")

        --shader:send("_spectrum_size", {texture_w, rt.settings.audio_processor.window_size / texture_w})
        texture_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        texture_shape._native:setTexture(texture)
    end

    if col_i >= texture_h then
        image = love.image.newImageData(#bins, texture_h, image_data_format)
        col_i = 0
    end

    -- compress by frequency
    local compressed = {}
    local current_i = 1
    for bin_i = 1, #bins, 1 do
        local bin = bins[#bins - bin_i + 1]
        local sum = 0
        local n = 0
        local start = current_i
        while current_i < start + bin do
            sum = sum + magnitude[current_i]
            current_i = current_i + 1
            n = n + 1
        end
        sum = sum / n
        table.insert(compressed, project(sum, min, max))
    end


    -- smooth distrbution
    if active then
        local smoothed = rt.math.kernel_density_estimation(
            compressed,
            rt.math.gaussian_kernel,
            5
        )

        for i = 1, #smoothed do
            image:setPixel(i - 1, col_i, smoothed[i], 0, 0, 1)
        end
    else
        for i = 1, #compressed do
            image:setPixel(i - 1, col_i, compressed[i], 0, 0, 1)
        end
    end
    texture:replacePixels(image)
    shader:send("_spectrum", texture)
    --shader:send("_on", ternary(active, 1, 0))
    --shader:send("_texture_size", {image:getWidth(), image:getHeight()})
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
