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

    enki = ffi.load("enkiTS")
    MAX_TASKS = 64

    local cdef = love.filesystem.read("fast_physics/enki_cdef.h")
    ffi.cdef(cdef)
    box2d_extension = ffi.load("box2d_extension")
    ffi.cdef[[
    typedef struct TaskData {
        b2TaskCallback* callback;
        void* context;
    } TaskData;

    typedef struct UserContext {
        void* scheduler;
        void* tasks[64];
        TaskData task_data[64];
        int n_tasks;
    } UserContext;

    void b2ExtensionTest();
    void b2InvokeTask(int32_t start_i, int32_t end_i, int32_t worker_i, TaskData* context);
    ]]

    box2d_extension.b2ExtensionTest()

    task_main = function(start_i, end_i, worker_i, context)
        local data = ffi.cast("TaskData*", context)
        data.callback(start_i, end_i, worker_i, data.context)
    end

    enqueue_task = function(task_callback, n_items, min_range, task_context, user_context_ptr)
        local context = ffi.cast("UserContext*", user_context_ptr)
        if context.n_tasks < 64 then
            local task = ffi.cast("void*", context.tasks[context.n_tasks]) -- enkiTaskSet*
            local data = context.task_data[context.n_tasks]
            data.callback = task_callback
            data.context = task_context

            local params = ffi.typeof("enkiParamsTaskSet")()
            params.minRange = min_range
            params.setSize = n_items
            params.pArgs = data
            params.priority = 0

            enki.enkiSetParamsTaskSet(task, params)
            enki.enkiAddTaskSet(context.scheduler, task)
            context.n_tasks = context.n_tasks + 1

            --box2d_extension.b2InvokeTask(0, n_items, 0, data);
            return task
        else
            task_callback(0, n_items, 0, task_context)
            rt.warning("increase n tasks!")
            return ffi.CNULL
        end
    end

    finish_task = function(task_ptr, user_context)
        if task_ptr == ffi.CNULL then return end
        local context = ffi.cast("UserContext*", user_context)
        local task = ffi.cast("void*", task_ptr) -- enkiTaskSet*
        enki.enkiWaitForTaskSet(context.scheduler, task)
    end

    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)

    def.workerCount = n_threads
    def.enqueueTask = enqueue_task
    def.finishTask = finish_task

    local context = ffi.cast("UserContext*", ffi.C.malloc(ffi.sizeof("UserContext")))
    context.n_tasks = 0
    context.scheduler = enki.enkiNewTaskScheduler()
    local config = enki.enkiGetTaskSchedulerConfig(context.scheduler)
    config.numTaskThreadsToCreate = n_threads - 1
    enki.enkiInitTaskSchedulerWithConfig(context.scheduler, config)

    for task_i = 1, MAX_TASKS do
        context.tasks[task_i - 1] = enki.enkiCreateTaskSet(context.scheduler, box2d_extension.b2InvokeTask)
    end

    def.userTaskContext = context

    return setmetatable({
        _native = box2d.b2CreateWorld(def),
        _user_context = context
    }, {
        __index = b2.World
    })
end