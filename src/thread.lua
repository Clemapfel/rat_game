--- @class rt.MessageType
rt.MessageType = meta.new_enum({
    INVOKE = 1,     -- call function
    LOAD = 2,       -- compile code
    DATA = 3,       -- transmit data
})

rt.threads = {}

--- @brief
function rt.is_message(x)
    return meta.is_table(x) and not meta.is_nil(x.type)
end

--- @brief
function rt.assert_message(x)
    if not meta.is_message(x) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `Message`, got `" .. meta.typeof(x) .. "`")
    end
end

--- @brief
function rt.threads.handle_message(message)
    meta.assert_message(message)
    if message.type == rt.MessageType.LOAD then
        rt.threads._handle_load_message(message)
    elseif message.type == rt.MessageType.INVOKE then
        rt.threads._handle_invoke_message(message)
    elseif message.type == rt.MessageType.DATA then
        rt.threads._handle_data_message(message)
    end
end

--- @brief [internal] compile code
function rt.threads._handle_load_message(message)
    assert(message.type == rt.MessageType.LOAD)
    meta.assert_string(message.code)
    local f, error = load(message)
    if meta.is_nil(f) then
        error("In rt.threads._handle_load_message: compilation failed: " .. error)
    end
    f()
end

--- @brief
function rt.threads.send_load_message(id, code)
    meta.assert_number(id)
    meta.assert_string(code)
    local channel = love.thread.getChannel(id)
    channel:push({
        type = rt.MessageType.LOAD,
        code = code
    })
end

--- @brief