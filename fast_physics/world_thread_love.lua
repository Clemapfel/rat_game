--- @brief
function b2.World:new_with_threads(gravity_x, gravity_y, n_threads)
    if n_threads == 0 then
        local def = box2d.b2DefaultWorldDef()
        def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
        return setmetatable({
            _native = box2d.b2CreateWorld(def),
        }, {
            __index = b2.World
        })
    end

    if sdl2 == nil then
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
    end

    local world = setmetatable({
        --_native = nil,
        _main_to_worker = {},
        _threads = {},
        _enqueue_task = nil,
        _finish_task = nil,
        _n_threads = n_threads,
        _step_i = 1,
        _step_i_to_semaphore = {},
        _n_semaphores = 32,
        _n_dispatched = 0,
    }, {
        __index = b2.World
    })

    for i = 1, world._n_semaphores do
        table.insert(world._step_i_to_semaphore, love.thread.newChannel())
    end

    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
    def.workerCount = n_threads

    local user_context = ffi.new("b2UserContext")
    user_context.n_threads = n_threads
    def.userTaskContext = user_context

    -- void* b2_enqueue_task(b2TaskCallback* task, int32_t item_count, int32_t min_range, void* task_context, void* user_context_ptr)
    world._enqueue_task = function (task_callback, item_count, min_range, task_context, _)
        if item_count >= min_range then
            -- if only one job, run serially
            task_callback(0, item_count, 0, task_context)
            return ffi.CNULL
        end

        local n_tasks = 0
        min_range = math.ceil(item_count / world._n_threads)

        local step_i = world._step_i
        local channel = world._step_i_to_semaphore[step_i]

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

            world._main_to_worker[worker_i + 1]:push({
                start_i = start_i,
                end_i = end_i,
                worker_i = worker_i,
                context = context_ptr,
                callback = callback_ptr,
                semaphore = channel
            })
            n_tasks = n_tasks + 1

            worker_i = worker_i + 1
            if worker_i > n_threads - 1 then worker_i = 0 end
            item_i = item_i + (end_i - start_i)
        end

        local dispatch = ffi.cast("b2ThreadDispatch*", ffi.C.malloc(sizeof("b2ThreadDispatch")))
        dispatch.n_dispatched = n_tasks
        dispatch.step_i = step_i

        world._step_i = (world._step_i + 1) % world._n_semaphores
        return dispatch
    end

    world._finish_task = function(dispatch_ptr, user_context_ptr)
        if dispatch_ptr == ffi.CNULL then return end

        local dispatch = ffi.cast("b2ThreadDispatch*", dispatch_ptr)
        local channel = world._step_i_to_semaphore[tonumber(dispatch.step_i)]
        local n_done = 0
        while n_done < dispatch.n_dispatched do
            channel:demand()
            n_done = n_done + 1
        end

        ffi.C.free(dispatch)
    end

    def.enqueueTask = world._enqueue_task
    def.finishTask = world._finish_task

    for i = 1, n_threads do
        world._main_to_worker[i] = love.thread.newChannel()
        local thread = love.thread.newThread("fast_physics/world_thread_worker.lua")
        thread:start(world._main_to_worker[i], i - 1)
    end

    world._native = box2d.b2CreateWorld(def)
    return world
end