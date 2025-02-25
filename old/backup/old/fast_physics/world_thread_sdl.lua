
function b2_task_callback(task_ptr)
    --local task = ffi.cast("b2Task*", task_ptr)
    --task.callback(task.start_i, task.end_i, task.worker_i, task.context)
    --ffi.C.free(task)
    return 1
end

function b2.World:new_with_threads(gravity_x, gravity_y, n_threads)
    sdl2 = ffi.load("SDL2")
    ffi.cdef[[
        void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
        void SDL_WaitThread(void* thread, int *status);

        typedef struct b2ThreadDispatch {
            int32_t n_dispatched;
            void** threads;
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
            void* thread;
        } b2Task;

        void* malloc(size_t size);
        void free(void *ptr);
    ]]

    function test()
        while true do
            println("test")
        end
    end

    local thread = sdl2.SDL_CreateThread(test, " ", ffi.CNULL)
    sdl2.SDL_WaitThread(thread)

    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
    def.workerCount = n_threads

    local user_context = ffi.cast("b2UserContext*", ffi.C.malloc(ffi.sizeof("b2UserContext")))
    user_context.n_threads = n_threads
    def.userTaskContext = user_context

    def.enqueueTask = function(task_callback, item_count, min_range, task_context, user_context_ptr)
        local user_context = ffi.cast("b2UserContext*", user_context_ptr)
        local n_threads = user_context.n_threads

        local threads = {}
        local n_dispatched = 0

        local item_i = 0
        local worker_i = 0
        while item_i < item_count do
            local end_i = item_i + min_range
            if end_i > item_count then end_i = item_count end
            local start_i = item_i

            local task = ffi.cast("b2Task*", ffi.C.malloc(ffi.sizeof("b2Task")))
            task.start_i = start_i
            task.end_i = end_i
            task.worker_i = worker_i
            task.callback = task_callback
            task.context = task_context

            local name = ffi.cast("char*", ffi.C.malloc(ffi.sizeof("char") * 1))
            name[1] = 128
            sdl2.SDL_CreateThread(function()  end, " ", ffi.CNULL)

            --table.insert(threads, task.thread)
            --n_dispatched = n_dispatched + 1

            task.callback(task.start_i, task.end_i, 0, task.context)
            ffi.C.free(task)

            worker_i = worker_i + 1
            if worker_i > n_threads - 1 then worker_i = 0 end
            item_i = item_i + (end_i - start_i)
        end

        local dispatch = ffi.cast("b2ThreadDispatch*", ffi.C.malloc(ffi.sizeof("b2ThreadDispatch")))
        dispatch.n_dispatched = n_dispatched
        dispatch.threads = ffi.C.malloc(ffi.sizeof("void*") * n_dispatched)
        for i = 1, n_dispatched do
            dispatch.threads[i-1] = threads[i]
        end

        return dispatch
    end

    def.finishTask = function(dispatch_ptr, user_context_ptr)
        if dispatch_ptr == ffi.CNULL then return end
        local dispatch = ffi.cast("b2ThreadDispatch*", dispatch_ptr)
        for i = 1, dispatch.n_dispatched do
            local thread = dispatch.threads[i-1]
            local status = ffi.new("int[1]")
            sdl2.SDL_WaitThread(thread, status)
            --assert(status[0] == 1)
        end

        ffi.C.free(dispatch.threads)
        ffi.C.free(dispatch)
    end

    return setmetatable({
        _native = box2d.b2CreateWorld(def)
    }, {
        __index = b2.World
    })
end
