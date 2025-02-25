#include "box2d_extension.hpp"
#include <iostream>

void b2InvokeTask(uint32_t start, uint32_t end, uint32_t threadIndex, void* context)
{
    TaskData* data = (TaskData*) context;
    data->callback(start, end, threadIndex, data->context );
}

static void test_callback(int32_t startIndex, int32_t endIndex, uint32_t workerIndex, void* taskContext ) {
    std::cout << "b2 extension working " << startIndex << " " << endIndex << " " << workerIndex << " " << taskContext << std::endl;
}

void b2ExtensionTest() {
    auto* data = new TaskData();
    data->callback = test_callback;
    data->context = nullptr;
    b2InvokeTask(1234, 4567, 0, data);
    delete data;
}
