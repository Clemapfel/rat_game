require "thread_pool"

love.load = function()
    love.window.setMode(1920 / 2, 1080 / 2, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("ThreadPool Test")

    -- tasks to run multi-threaded: print 4 message
    test_messages = {
        "First Message",
        "Second Message",
        "Third Message",
        "Fourth Message",
    }

    -- and load one music file
    test_audio = {
        "assets/music/test_music_03.mp3"
    }

    -- this is where the results will be stored
    futures = {}

    -- create the thread pool
    thread_pool = rt.ThreadPool(8)
    thread_pool:startup()

    -- queue tasks for the thread pool
    for _, message in pairs(test_messages) do
        table.insert(futures, thread_pool:request_debug_print(message))
    end

    for _, path in pairs(test_audio) do
        table.insert(futures, thread_pool:request_load_sound_data(path))
    end
end

love.update = function()
    local delta = love.timer.getDelta()

    -- one or more times per frame, the threadpool needs to be updated
    -- this will set the values of our `futures`, if their value becomes available
    local ready_futures = thread_pool:update(delta)

    -- we can use the futures stored in `future`, but `update` also returns all newly updated futures that turn
    for _, future in pairs(ready_futures) do
        assert(future:is_ready())
        print("Main Received Future #" .. tostring(future.id) .. ":", future:get_result(), "\n")
    end

    -- if all futures are done, safely shutdown thread pool, then love
    local is_done = true
    for _, future in pairs(futures) do
        if not future:is_ready() then
            is_done = false
            break
        end
    end

    if is_done then
        println("succesfully received all futures")
        love.event.quit()
    end
end

