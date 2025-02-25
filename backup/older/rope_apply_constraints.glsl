struct Node {
    vec2 position;
    vec2 old_position;
    float mass;
};

layout(std430) buffer node_buffer_a {
    Node nodes_a[];
}; // size: n_nodes

layout(std430) buffer node_buffer_b {
    Node nodes_b[];
}; // size: n_nodes

struct NodePair {
    uint a_index;
    uint b_index;
    float target_distance;
};

layout(std430) buffer node_pair_buffer {
    NodePair node_pairs[];
}; // size: n_node_pairs

uniform uint n_node_pairs;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    uint n_threads_x = gl_NumWorkGroups.x * gl_WorkGroupSize.x;
    uint n_threads_y = gl_NumWorkGroups.y * gl_WorkGroupSize.y;
    uint n_threads = n_threads_x * n_threads_y;

    uint n_pairs_per_thread = (n_node_pairs + n_threads - 1) / n_threads;
    uint thread_i = gl_GlobalInvocationID.y * n_threads_x + gl_GlobalInvocationID.x;

    uint pair_start_i = thread_i * n_pairs_per_thread;
    uint pair_end_i = min(pair_start_i + n_pairs_per_thread, n_node_pairs);

    // src: https://github.com/Toqozz/blog-code/blob/master/rope/Assets/Rope.cs
    // src: https://www.owlree.blog/posts/simulating-a-rope.html

    for (uint pair_i = pair_start_i; pair_i < pair_end_i; ++pair_i) {
        NodePair pair = node_pairs[pair_i];
        uint a_i = pair.a_index;
        uint b_i = pair.b_index;

        Node node_a = nodes_b[a_i];
        Node node_b = nodes_b[b_i];

        vec2 difference = node_a.position - node_b.position;
        float distance = length(difference);
        vec2 offset = difference * 0.5 * ((pair.target_distance - distance) / distance);

        node_a.position += offset;
        node_b.position -= offset;

        nodes_a[a_i] = node_a;
        nodes_a[b_i] = node_b;
    }
}