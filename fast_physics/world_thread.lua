
--- @brief
function b2.World:new_with_threads(gravity_x, gravity_y, n_threads)
    sdl2 = ffi.load("SDL2")
    ffi.cdef[[
    void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
    void SDL_WaitThread(void* thread, int *status);

    typedef struct b2ThreadDispatch {
        void** threads;
        int32_t n_threads;
    } b2ThreadDispatch;

    typedef struct b2UserContext {
        int n_threads;
    } b2UserContext;

    void* malloc(size_t size);
    ]]

    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
    def.workerCount = n_threads

    local user_context = ffi.cast("b2UserContext*", ffi.C.malloc(sizeof("b2UserContext"))) -- TODO: this leaks a single number per world
    user_context.n_threads = n_threads
    def.userTaskContext = user_context

    local id = box2d.b2CreateWorld(def)
    local out = setmetatable({
        _native = id,
        _worker_to_main = love.thread.newChannel(),
        _main_to_worker = love.thread.newChannel(),
        _threads = {},
        _n_threads = n_threads
    }, {
        __index = b2.World
    })

    -- void* b2_enqueue_task(b2TaskCallback* task, int32_t item_count, int32_t min_range, void* task_context, void* user_context_ptr)
    function b2_enqueue_task(task_callback, item_count, min_range, task_context, user_context)
        user_context = ffi.cast("b2UserContext*", user_context)

        local n_items_per_worker = math.ceil(item_count / user_context.n_threads - 1)
        if n_items_per_worker < min_range then
            n_items_per_worker = min_range
        end

        local item_i = 0
        local worker_i = 0
        while item_i < item_count do
            local end_i = item_i + min_range
            if end_i > item_count then
                end_i = item_count
            end

            local context = {
                start_i = item_i,
                end_i = end_i,
                worker_index = worker_i,
                task_context = task_context,
                task_callback = task_callback
            }

            worker_i = worker_i + 1
            item_i = item_i + min_range
        end


        --task_callback(0, item_count, 0, task_context)

        --local dispatch = ffi.new("ThreadDispatch")
        --dispatch.n_threads = ffi.C.malloc(ffi.sizeof("void*") * )
        return ffi.CNULL
    end

    -- void b2_finish_task(void* dispatch_ptr, void* user_context_ptr) {
    function b2_finish_task(dispatch_ptr, user_context_ptr)
    end

    for i = 1, n_threads do
        local thread = love.thread.newThread("fast_physics/world_thread_worker.lua")
        thread:start(out._worker_to_main, out._main_to_worker, i - 1)
    end

    return out
end

