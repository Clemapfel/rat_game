typedef struct enkiParamsTaskSet
{
    void*    pArgs;
    uint32_t setSize;
    uint32_t minRange;
    int      priority;
} enkiParamsTaskSet;

typedef void (*enkiProfilerCallbackFunc)( uint32_t threadnum_ );
typedef struct enkiProfilerCallbacks
{
    enkiProfilerCallbackFunc threadStart;
    enkiProfilerCallbackFunc threadStop;
    enkiProfilerCallbackFunc waitForNewTaskSuspendStart;      // thread suspended waiting for new tasks
    enkiProfilerCallbackFunc waitForNewTaskSuspendStop;       // thread unsuspended
    enkiProfilerCallbackFunc waitForTaskCompleteStart;        // thread waiting for task completion
    enkiProfilerCallbackFunc waitForTaskCompleteStop;         // thread stopped waiting
    enkiProfilerCallbackFunc waitForTaskCompleteSuspendStart; // thread suspended waiting task completion
    enkiProfilerCallbackFunc waitForTaskCompleteSuspendStop;  // thread unsuspended
} enkiProfilerCallbacks;

typedef void  (*enkiFreeFunc)(  void* ptr_,    size_t size_, void* userData_, const char* file_, int line_ );
typedef void* (*enkiAllocFunc)( size_t align_, size_t size_, void* userData_, const char* file_, int line_ );
typedef struct enkiCustomAllocator
{
    enkiAllocFunc alloc;
    enkiFreeFunc  free;
    void*         userData;
} enkiCustomAllocator;

typedef struct enkiTaskSchedulerConfig
{
    uint32_t              numTaskThreadsToCreate;
    uint32_t              numExternalTaskThreads;
    struct enkiProfilerCallbacks profilerCallbacks;
    struct enkiCustomAllocator   customAllocator;
} enkiTaskSchedulerConfig;

void enkiSetParamsTaskSet( void* pTaskSet_, enkiParamsTaskSet params_);
void enkiAddTaskSet( void* pETS_, void* pTaskSet_ );
void enkiWaitForTaskSet( void* pETS_, void* pTaskSet_ );

void* enkiNewTaskScheduler();
void enkiDeleteTaskScheduler(void* scheduler);

struct enkiTaskSchedulerConfig enkiGetTaskSchedulerConfig( void* pETS_ );
void enkiInitTaskSchedulerWithConfig( void* pETS_, struct enkiTaskSchedulerConfig config_ );

typedef void (* enkiTaskExecuteRange)( uint32_t start_, uint32_t end_, uint32_t threadnum_, void* pArgs_ );
void* enkiCreateTaskSet( void* pETS_, enkiTaskExecuteRange taskFunc_  );

void* malloc(size_t size);
void free(void *ptr);

typedef struct TaskData {
    b2TaskCallback* callback; // ran after box2d cdef
    void* context;
} TaskData;

typedef struct UserContext {
    void* scheduler;
    void* tasks[64];
    TaskData task_data[64];
    int n_tasks;
} UserContext;

void b2ExtensionTest();
void b2InvokeTask(uint32_t start_i, uint32_t end_i, uint32_t worker_i, void* context);

