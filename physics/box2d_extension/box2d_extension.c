#include "box2d_extension.h"
#include <stdio.h>

void b2InvokeTask(uint32_t start, uint32_t end, uint32_t threadIndex, void* context)
{
    TaskData* data = (TaskData*) context;
    data->callback(start, end, threadIndex, data->context );
}

