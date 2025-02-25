#ifdef _WIN32
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT
#endif

#include <stdint.h>

extern "C" {
    EXPORT typedef void b2TaskCallback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext );

    EXPORT typedef struct TaskData {
        b2TaskCallback* callback;
        void* context;
    } TaskData;

    EXPORT typedef struct UserContext {
        void* scheduler;
        void* tasks[64];
        TaskData task_data[64];
        int n_tasks;
    } UserContext;

    EXPORT extern void b2InvokeTask(uint32_t start, uint32_t end, uint32_t threadIndex, void* context);
    EXPORT extern void b2ExtensionTest();
}