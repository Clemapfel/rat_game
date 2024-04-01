require "love.image"
require "love.audio"
require "love.sound"
require "love.timer"

-- globals handed from main during :start()
local args = {...}
main_to_worker = args[1]
worker_to_main = args[2]
rt = {}; rt.MessageType = args[3]
THREAD_ID = args[4]

-- main loop
while true do
    -- retrieve message and handle it
    local message = main_to_worker:demand()

    -- Message Type #1: KILL This will safely shutdown the thread
    if message.type == rt.MessageType.KILL then
        break
    elseif message.type == rt.MessageType.PRINT then
        -- Message Type #2: PRINT this will print to the console from the thread, useful for debugging
        print("Thread #" .. tostring(THREAD_ID) .. " prints: " .. tostring(message.data))
        worker_to_main:push({
            id = message.id,
            type = rt.MessageType.PRINT_DONE,
            data = message.data
        })
    elseif message.type == rt.MessageType.LOAD_AUDIO then
        -- Message Type #3: LOAD_AUDIO receives a path as message.data, and loads it into memory, then sends the memory back to the worker
        local res = love.sound.newSoundData(message.data)
        worker_to_main:push({
            id = message.id,
            type = rt.MessageType.AUDIO_DONE,
            data = res
        })
    --- MESSAGE Type #4: TODO add your own message type and thread-side behavior here
    elseif message.type == "TODO" then
        -- todo
    else
        error("In rt.ThreadPool.ThreadWorker: unhandled message type `" .. message.type .. "`")
    end
end