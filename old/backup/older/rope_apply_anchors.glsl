struct Node {
    vec2 position;
    vec2 old_position;
    float mass;
};

layout(std430) writeonly buffer node_buffer {
    Node nodes[];
}; // size: n_nodes

struct Anchor {
    uint node_i;
    vec2 position;
};

layout(std430) readonly buffer anchor_buffer {
    Anchor anchors[];
}; // size: n_anchors

uniform uint n_anchors;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with xy = sqrt(n_anchors)
void computemain() {
    uint n_threads_x = gl_NumWorkGroups.x * gl_WorkGroupSize.x;
    uint n_threads_y = gl_NumWorkGroups.y * gl_WorkGroupSize.y;
    uint n_threads = n_threads_x * n_threads_y;

    uint n_per_thread = (n_anchors + n_threads - 1) / n_threads;
    uint thread_i = gl_GlobalInvocationID.y * n_threads_x + gl_GlobalInvocationID.x;

    uint start_i = thread_i * n_per_thread;
    uint end_i = min(start_i + n_per_thread, n_anchors);

    for (uint i = start_i; i < end_i; ++i) {
        Anchor anchor = anchors[i];
        nodes[anchor.node_i].position = anchor.position;
    }
}

