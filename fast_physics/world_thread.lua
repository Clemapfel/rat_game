
--- @brief
function b2.World:new_with_threads(gravity_x, gravity_y, n_threads)
    sdl2 = ffi.load("SDL2")
    ffi.cdef[[
    void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
    void SDL_WaitThread(void* thread, int *status);

    typedef struct b2ThreadDispatch {
        int32_t n_dispatched;
    } b2ThreadDispatch;

    typedef struct b2UserContext {
        int n_threads;
    } b2UserContext;

    typedef struct b2Task {
        int32_t start_i;
        int32_t end_i;
        int32_t worker_i;
        b2TaskCallback* callback;
        void* context;
    } b2Task;

    void* malloc(size_t size);
    void free(void *ptr);
    ]]

    local world = setmetatable({
        --_native = nil,
        _worker_to_main = love.thread.newChannel(),
        _main_to_worker_channels = {},
        _threads = {},
        _n_threads = n_threads,
        _n_dispatched = 0,
    }, {
        __index = b2.World
    })

    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
    def.workerCount = n_threads

    for i = 1, n_threads do
        table.insert(world._main_to_worker_channels, love.thread.newChannel())
    end

    local user_context = ffi.cast("b2UserContext*", ffi.C.malloc(ffi.sizeof("b2UserContext")))
    user_context.n_threads = n_threads
    def.userTaskContext = user_context

    -- void* b2_enqueue_task(b2TaskCallback* task, int32_t item_count, int32_t min_range, void* task_context, void* user_context_ptr)
    def.enqueueTask = function (task_callback, item_count, min_range, task_context, _)
        local n_items_per_worker = item_count--math.ceil(item_count / world._n_threads)
        if n_items_per_worker < min_range then
            n_items_per_worker = min_range
        end

        local tasks = {}
        local n_tasks = 0

        local item_i = 0
        local worker_i = 0
        while item_i < item_count do
            local end_i = item_i + min_range
            if end_i > item_count then end_i = item_count end
            local start_i = item_i

            table.insert(tasks, {
                start_i = start_i,
                end_i = end_i,
                worker_i = worker_i,
                context = tonumber(ffi.cast("uint64_t", task_context)),
                callback = tonumber(ffi.cast("uint64_t", task_callback))
            })
            n_tasks = n_tasks + 1

            worker_i = worker_i + 1
            if worker_i > n_threads - 1 then worker_i = 0 end
            item_i = item_i + (end_i - start_i)
        end

        for task in values(tasks) do
            world._main_to_worker_channels[task.worker_i + 1]:push(task)
        end

        local dispatch = ffi.cast("b2ThreadDispatch*", ffi.C.malloc(sizeof("b2ThreadDispatch")))
        dispatch.n_dispatched = n_tasks
        return dispatch
    end
    
    def.finishTask = function(dispatch_ptr, user_context_ptr)
        local dispatch = ffi.cast("b2ThreadDispatch*", dispatch_ptr)
        while dispatch.n_dispatched > 0 do
            local done_id = world._worker_to_main:demand()
            dispatch.n_dispatched = dispatch.n_dispatched - 1
        end
        worffi.C.free(dispatch)
    end

    for i = 1, n_threads do
        local thread = love.thread.newThread("fast_physics/world_thread_worker.lua")
        thread:start(world._worker_to_main, world._main_to_worker_channels[i], i - 1)
    end

    world._native = box2d.b2CreateWorld(def)
    return world
end

b2_THREAD_SUCCESS = 123
-- int b2_task_callback(void* thread_context_pointer)
function b2_task_callback(thread_context_ptr)
    local context = ffi.cast("ThreadContext*", thread_context_ptr)
    context.task(
        context.start,
        context.finish,
        context.worker_index,
        context.task_context
    )

    ffi.C.delete(context)
    return b2_THREAD_SUCCESS
end

-- void b2_finish_task(void* dispatch_ptr, void* user_context_ptr) {
function b2_finish_task(dispatch_ptr, user_context_ptr)
end

