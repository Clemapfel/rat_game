rt.threads = {}

--- @class rt.MessageType
rt.MessageType = meta.new_enum({
    LOAD = "LOAD",
    REQUEST = "REQUEST",
    DELIVER = "DELIVER"
})

--- @class rt.Thread
rt.Thread = meta.new_type("Thread", function(id)
    local out = meta.new(rt.Thread, {
        _id = id,
        _native = {}
    })

    -- inject hardcoded thread ID into source
    local code = "rt = {} function rt.get_thread_id() return " .. tostring(out._id) .. " end\n" .. love.filesystem.read("src/thread_worker.lua")
    out._native = love.thread.newThread(code)
    out._native:start()

    return out
end)

--- @class
function rt.Thread:execute(code)
    meta.assert_isa(self, rt.Thread)
    if meta.is_string(code) then
        love.thread.getChannel(self._id):push({
            type = rt.MessageType.LOAD,
            code = code
        })
    else
        meta.assert_function(code)
        love.thread.getChannel(self._id):push({
            type = rt.MessageType.LOAD,
            code = string.dump(code)
        })
    end
end
