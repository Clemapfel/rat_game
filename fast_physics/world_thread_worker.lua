require "common.common"
require "common.serialize"

ffi = require "ffi"
ffi.cdef[[
typedef void b2TaskCallback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext );
]]

worker_to_main, main_to_worker, thread_id = ...

while true do
    local task = main_to_worker:demand()
    ffi.cast("b2TaskCallback*", task.callback)(task.start_i, task.end_i, task.worker_i, ffi.cast("void*", task.context))
    worker_to_main:push(thread_id)
end