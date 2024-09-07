#include "box2d_extension.hpp"
#include <iostream>

void b2InvokeTask(int32_t start_i, int32_t end_i, int32_t worker_i, TaskData* data) {
    data->callback(start_i, end_i, worker_i, data->context);
}

static void test_callback( int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext ) {
    std::cout << "b2 extension working " << startIndex << " " << endIndex << " " << workerIndex << " " << taskContext << std::endl;
}

void b2ExtensionTest() {
    auto* data = new TaskData();
    data->callback = test_callback;
    data->context = nullptr;
    b2InvokeTask(1234, 4567, 0, data);
    delete data;
}
