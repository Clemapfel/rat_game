require "love.image"
require "love.audio"
require "love.sound"
require "love.timer"
require "love.math"

meta = {}
rt = {}
rt.test = {}

require "common"
require "meta"

-- globals handed from main during :start()
local args = {...}
main_to_worker = args[1]
worker_to_main = args[2]
main_to_worker_priority = args[3]
worker_to_main_priority = args[4]
rt.MessageType = args[5]

THREAD_ID = args[6]
IS_BLOCKING = false

-- main loop
while true do

    local message;
    if main_to_worker_priority:getCount() ~= 0 or IS_BLOCKING then
        message = main_to_worker_priority:demand()
    else
        message = main_to_worker:demand()
    end

    if message.type == rt.MessageType.KILL then
        break
    elseif message.type == rt.MessageType.BLOCK then
        IS_BLOCKING = true
        worker_to_main_priority:push({
            id = message.id,
            type = rt.MessageType.BLOCK_ACKNOWLEDGED,
            data = {}
        })
    elseif message.type == rt.MessageType.UNBLOCK then
        IS_BLOCKING = false
        worker_to_main_priority:push({
            id = message.id,
            type = rt.MessageType.UNBLOCK_ACKNOWLEDGED,
            data = {}
        })
    elseif message.type == rt.MessageType.PRINT then
        print("[" .. tostring(THREAD_ID) .. "] " .. tostring(message.data))
        worker_to_main:push({
            id = message.id,
            type = rt.MessageType.PRINT_DONE,
            data = message.data
        })
    elseif message.type == rt.MessageType.LOAD_AUDIO then
        local res = love.sound.newSoundData(message.data)
        worker_to_main:push({
            id = message.id,
            type = rt.MessageType.AUDIO_DONE,
            data = res
        })
    else
        error("In rt.ThreadPool.ThreadWorker: unhandled message type `" .. message.type .. "`")
    end
end