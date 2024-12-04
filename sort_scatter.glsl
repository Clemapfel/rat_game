layout(local_size_x = 256) in;

layout(std430) buffer InputBuffer {
    uint data[];
};

layout(std430) buffer TempBuffer {
    uint temp[];
};

layout(std430) buffer PredicateBuffer {
    uint predicates[];
};

layout(std430) buffer ScanBuffer {
    uint scan[];
};

uniform uint arrayLength;
uniform uint bitShift;

void computemain() {
    uint gid = gl_GlobalInvocationID.x;

    if (gid < arrayLength) {
        uint value = data[gid];
        uint digit = (value >> bitShift) & uint(0x3);
        uint position = scan[gid];

        // Write to temporary buffer
        temp[position] = value;
    }

    barrier();

    // Copy back to input buffer
    if (gid < arrayLength) {
        data[gid] = temp[gid];
    }
}