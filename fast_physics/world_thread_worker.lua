require "common.common"
require "common.serialize"
require "love.timer"

ffi = require "ffi"
ffi.cdef[[
typedef void b2TaskCallback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext );
]]

main_to_worker, thread_id = ...

while true do
    local task = main_to_worker:demand()
    local callback = ffi.cast("void**", task.callback:getFFIPointer())[0]
    local context = ffi.cast("void**", task.context:getFFIPointer())[0]
    ffi.cast("b2TaskCallback*", callback)(task.start_i, task.end_i, thread_id, context)
    task.semaphore:push(thread_id)
end