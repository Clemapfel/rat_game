#include <box2d/box2d.h>

// THREADING

BOX2D_EXPORT typedef struct TaskData {
    b2TaskCallback* callback;
    void* context;
} TaskData;

BOX2D_EXPORT typedef struct UserContext {
    void* scheduler;
    void* tasks[64];
    TaskData task_data[64];
    int n_tasks;
} UserContext;

BOX2D_EXPORT extern void b2InvokeTask(uint32_t start, uint32_t end, uint32_t threadIndex, void* context);
