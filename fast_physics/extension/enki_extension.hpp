extern "C" {
    typedef void b2TaskCallback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext );

    typedef struct b2TaskData {
        b2TaskCallback* callback;
        void* context;
    } TaskData;

    static inline void b2InvokeTask(int32_t start_i, int32_t end_i, int32_t worker_i, TaskData* context) {
        context->callback(start_i, end_i, worker_i, context);
    }
}