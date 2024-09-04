
--- @brief
function b2._initialize_threads(world_def, n_threads)
    sdl2 = ffi.load("SDL2")
    ffi.cdef[[
    void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
    void SDL_WaitThread(void* thread, int *status);

    typedef struct b2ThreadContext {
        b2TaskCallback* task;
        int32_t start;
        int32_t finish;
        int32_t worker_index;
        int32_t n_items;
        void* task_context;
    } ThreadContext;

    typedef struct b2ThreadDispatch {
        void** threads;
        int32_t n_threads;
    } ThreadDispatch;
    ]]

    world_def.workerCount = n_threads
    world_def.enqueueTask = b2_enqueue_task
    world_def.finishTask = b2_finish_task
    world_def.userTaskContext = ffi.CNULL;
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

-- void* b2_enqueue_task(b2TaskCallback* task, int32_t item_count, int32_t min_range, void* task_context, void* user_context_ptr)
function b2_enqueue_task(task_callback, item_count, min_range, task_context, _)
    task_callback(0, item_count, 0, task_context)
    return ffi.CNULL
end

-- void b2_finish_task(void* dispatch_ptr, void* user_context_ptr) {
function b2_finish_task(dispatch_ptr, user_context_ptr)
end

