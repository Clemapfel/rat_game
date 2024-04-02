--- @class rt.ThreadPool
rt.ThreadPool = {}

--- @brief constructor
--- @param n_threads Number number of threads, default: 1
--- @return rt.ThreadPool
rt.ThreadPool = meta.new_type("ThreadPool", function(n_threads)
    if n_threads == nil then n_threads = 1 end
    local out = meta.new(rt.ThreadPool, {
        _threads = {},
        _futures = {},
        _n_threads = math.abs(n_threads),
        _main_to_worker = love.thread.newChannel(),
        _worker_to_main = love.thread.newChannel()
    })
    meta.make_weak(out._futures, false, true)
    return out
end)

rt.ThreadPool.FUTURE_ID = 0
rt.ThreadPool._thread_source = love.filesystem.read("common/thread_pool_worker.lua")
if rt.ThreadPool._thread_source == nil then
    error("In thread_pool: path to thread pool worker code is invalid, change the file location in thread_pool.lua, line 64")
end

--- @class rt.MessageType
rt.MessageType = {
    KILL = "KILL",
    BLOCK = "BLOCK",
    BLOCK_ACKNOWLEDGED = "BLOCK_ACKNOWLEDGED",
    UNBLOCK = "UNBLOCK",
    UNBLOCK_ACKNOWLEDGED = "BLOCK_ACKNOWLEDGED",
    LOAD_AUDIO = "LOAD_AUDIO",
    AUDIO_DONE = "AUDIO_DONE",
    PRINT = "PRINT",
    PRINT_DONE = "PRINT_DONE"
} -- sic, raw table instead of meta.enum

--- @class rt.ThreadPool.Message
--- @brief message to be passed between main and worker threads, these instruct the threads what to do
function rt.ThreadPool.Message(type, id, data)
    return {
        type = type,
        id = id,
        data = data
    }
end

--- @class rt.ThreadPool.Future
--- @brief when querying the threadpool, it will return a future object. Once the promised value is available, it will be automatically send to the future
function rt.ThreadPool.Future(id)
    return {
        id = id,
        result = nil,
        is_delivered = false,

        is_ready = function(self) return self.is_delivered end,
        get_result = function(self) return self.result end
    }
end

--- @brief allocate all threads and start them, they will run continuously from this point on
function rt.ThreadPool:startup()
    for i = 1, self._n_threads do
        local to_push = {
            id = i,
            thread = love.thread.newThread(
                rt.ThreadPool._thread_source
            ),
            main_to_worker_priority = love.thread.newChannel(),
            worker_to_main_priority = love.thread.newChannel()
        }
        self._threads[i] = to_push
        to_push.thread:start(       -- thread-side variables:
            self._main_to_worker,   -- main_to_worker
            self._worker_to_main,   -- worker_to_main
            to_push.main_to_worker_priority, -- main_to_worker_priority
            to_push.worker_to_main_priority, -- worker_to_main_priority
            rt.MessageType,         -- rt.MessageType
            i                       -- THREAD_ID
        )
    end
end

--- @brief [internal] distribute a message of given type to all threads
function rt.ThreadPool:_send_message(type, data)
    rt.ThreadPool.FUTURE_ID = rt.ThreadPool.FUTURE_ID + 1
    local id = rt.ThreadPool.FUTURE_ID
    local message = rt.ThreadPool.Message(type, id, data)
    local future = rt.ThreadPool.Future(id)

    self._main_to_worker:push(message)
    self._futures[id] = future
    return future
end

--- @brief [internal] distribute a message of given type to all threads
function rt.ThreadPool:_send_priority_message(thread_id, type, data)
    rt.ThreadPool.FUTURE_ID = rt.ThreadPool.FUTURE_ID + 1
    local id = rt.ThreadPool.FUTURE_ID
    local message = rt.ThreadPool.Message(type, id, data)
    local future = rt.ThreadPool.Future(id)

    self._threads[thread_id].main_to_worker_priority:push(message)
    self._futures[id] = future
    return future
end

--- @brief ask the thread pool to print a message thread-side
--- @return rt.ThreadPool.Future<String>
function rt.ThreadPool:request_debug_print(message)
    return self:_send_message(rt.MessageType.PRINT, message)
end

--- @brief ask the thread pool to load an audio file
--- @return rt.ThreadPool.Future<love.SoundData>
function rt.ThreadPool:request_load_sound_data(path_to_audio)
    return self:_send_message(rt.MessageType.LOAD_AUDIO, path_to_audio)
end

--- @brief flush queue and distribute results among futures
function rt.ThreadPool:update(delta)
    local futures = {}
    local flush = function(queue)
        while queue:getCount() > 0 do
            local message = self._worker_to_main:pop()
            local future = self._futures[message.id]
            if future ~= nil then -- may be nil bc self._future is weak table
                future.result = message.data
                future.is_delivered = true
                table.insert(futures, future)
                self._futures[message.id] = nil
            end
        end
    end

    for t in values(self._threads) do
        flush(t.worker_to_main_priority)
    end
    flush(self._worker_to_main)
    return futures
end

--- @brief pause all threads
function rt.ThreadPool:block_all()
    for t in values(self._threads) do
        self:_send_priority_message(t.id, rt.MessageType.BLOCK, {})
    end
end

--- @brief unpause all threads
function rt.ThreadPool:unblock_all()
    for t in values(self._threads) do
        self:_send_priority_message(t.id, rt.MessageType.UNBLOCK, {})
    end
end

--- @brief safely shutdown threadpool, waits for all tasks to finish
function rt.ThreadPool:shutdown()
    for i = 1, #self._threads do
        self._main_to_worker:push({
            type = rt.MessageType.KILL,
            data = nil,
            id = -1
        })
    end

    for t in values(self._threads) do
        t.thread:wait()
    end
end

--- @brief immediately shutdown threadpool, no matter what
function rt.ThreadPool:force_shutdown()
    for t in values(self._threads) do
        t.thread:kill()
        t.thread:wait()
    end
end



