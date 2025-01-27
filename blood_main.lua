require "include"

rt.settings.fluid_simulation = {
    particle_radius = 11.5,
    density_kernel_resolution = 50
}

local screen_size_div = 1
local SCREEN_W, SCREEN_H = 800, 600  --math.round(1600 / screen_size_div), math.round(900 / screen_size_div)
local n_particles = 5000
local VSYNC = 1

local sim = nil
love.load = function()
    love.window.setMode(SCREEN_W, SCREEN_H, {
        vsync = VSYNC
    })

    sim = rt.FluidSimulation(SCREEN_W, SCREEN_H, n_particles)
    sim:realize()
end

love.update = function(delta)
    sim:update(delta)
end

love.keypressed = function(which)
    if which == "x" then
        sim:realize()
        sim:update(1 / 60)
    end
end

local mean_fps = 0
local mean_n_frames = 60 * 3
local last_frame_durations = table.rep(1 / 60, mean_n_frames)
local frame_duration_sum = mean_n_frames * 1 / 60

function love.run()
    if love.load then love.load() end
    if love.timer then love.timer.step() end

    local dt = 0
    return function()
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        local before, after = love.timer.getTime(), nil

        if love.timer then dt = love.timer.step() end
        if love.update then love.update(dt) end

        if love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end
            after = love.timer.getTime()
            love.graphics.present()
        end

        do
            local old = last_frame_durations[1]
            local new = after - before

            frame_duration_sum = frame_duration_sum - old + new
            mean_fps = 1 / (frame_duration_sum / mean_n_frames)
            mean_fps = math.floor(mean_fps * 10e5) / 10e5

            table.remove(last_frame_durations, 1)
            table.insert(last_frame_durations, after - before)
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end

love.draw = function()
    sim:draw()

    -- show fps
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(sim._n_particles .. " | " .. mean_fps, 0, 0, POSITIVE_INFINITY)
end