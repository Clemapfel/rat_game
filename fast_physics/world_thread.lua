
--- @brief
function b2.World:new_with_threads(gravity_x, gravity_y, n_threads)
    if n_threads == 0 then
        local def = box2d.b2DefaultWorldDef()
        def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
        return setmetatable({
            _native = box2d.b2CreateWorld(def),
            _worker_to_main = nil,
            _main_to_worker_channels = {},
            _threads = {},
            _enqueue_task = nil,
            _finish_task = nil,
            _n_threads = n_threads,
            _step_i = 0,
            _n_dispatched = 0,
        }, {
            __index = b2.World
        })
    end

    sdl2 = ffi.load("SDL2")
    ffi.cdef[[
void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
void SDL_WaitThread(void* thread, int *status);

typedef struct b2ThreadDispatch {
    int32_t n_dispatched;
    int64_t step_i;
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
        _enqueue_task = nil,
        _finish_task = nil,
        _n_threads = n_threads,
        _step_i = 0,
        _step_i_to_semaphore = {},
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
    world._enqueue_task = function (task_callback, item_count, min_range, task_context, _)

        --[[
        if item_count >= min_range then
            task_callback(0, item_count, 0, task_context)
            return ffi.CNULL
        end
        ]]--

        local tasks = {}
        local n_tasks = 0

        local step_i = world._step_i
        world._step_i = world._step_i + 1

        local item_i = 0
        local worker_i = 0
        while item_i < item_count do
            local end_i = item_i + min_range
            if end_i > item_count then end_i = item_count end
            local start_i = item_i

            local context_ptr = love.data.newByteData(ffi.sizeof("void*"))
            ffi.cast("void**", context_ptr:getFFIPointer())[0] = task_context

            local callback_ptr = love.data.newByteData(ffi.sizeof("void*"))
            ffi.cast("void**", callback_ptr:getFFIPointer())[0] = task_callback

            table.insert(tasks, {
                start_i = start_i,
                end_i = end_i,
                worker_i = worker_i,
                context = context_ptr,
                callback = callback_ptr,
                step_i = step_i
            })
            n_tasks = n_tasks + 1

            worker_i = worker_i + 1
            if worker_i > n_threads - 1 then worker_i = 0 end
            item_i = item_i + (end_i - start_i)
        end

        for task in values(tasks) do
            world._main_to_worker_channels[task.worker_i + 1]:push(task)
        end

        world._n_dispatched = world._n_dispatched + n_tasks

        local dispatch = ffi.cast("b2ThreadDispatch*", ffi.C.malloc(sizeof("b2ThreadDispatch")))
        dispatch.n_dispatched = n_tasks
        dispatch.step_i = step_i
        return dispatch
    end

    world._finish_task = function(dispatch_ptr, user_context_ptr)

        if dispatch_ptr == ffi.CNULL then return end
        local dispatch = ffi.cast("b2ThreadDispatch*", dispatch_ptr)

        while world._n_dispatched > 0 do
            world._worker_to_main:demand()
            world._n_dispatched = world._n_dispatched - 1
        end
    end

    def.enqueueTask = world._enqueue_task
    def.finishTask = world._finish_task

    for i = 1, n_threads do
        local thread = love.thread.newThread("fast_physics/world_thread_worker.lua")
        thread:start(world._worker_to_main, world._main_to_worker_channels[i], i - 1)
    end

    world._native = box2d.b2CreateWorld(def)
    return world
end
