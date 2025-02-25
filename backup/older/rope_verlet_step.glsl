struct Node {
    vec2 position;
    vec2 old_position;
    float mass;
};

layout(std430) readonly buffer node_buffer_a {
    Node nodes_a[];
}; // size: n_nodes

layout(std430) writeonly buffer node_buffer_b {
    Node nodes_b[];
}; // size: n_nodes

uniform uint n_nodes;
uniform float friction = 0.2;
uniform float gravity_factor = 1000;
uniform float delta;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in; // dispatch with xy = sqrt(n_nodes) / 32
void computemain() {
    uint n_threads_x = gl_NumWorkGroups.x * gl_WorkGroupSize.x;
    uint n_threads_y = gl_NumWorkGroups.y * gl_WorkGroupSize.y;
    uint n_threads = n_threads_x * n_threads_y;

    uint n_nodes_per_thread = (n_nodes + n_threads - 1) / n_threads;

    uint thread_i = gl_GlobalInvocationID.y * n_threads_x + gl_GlobalInvocationID.x;

    uint node_start_i = thread_i * n_nodes_per_thread;
    uint node_end_i = min(node_start_i + n_nodes_per_thread, n_nodes);

    const vec2 gravity = vec2(0, 1) * gravity_factor;

    for (uint node_i = node_start_i; node_i < node_end_i; ++node_i) {
        Node node = nodes_a[node_i];

        node.old_position = node.position;
        node.position += (node.position - node.old_position) * (1.0 - friction) + gravity * node.mass * delta;
        nodes_b[node_i] = node;
    }
}